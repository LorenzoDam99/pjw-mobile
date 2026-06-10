import 'dart:async';

import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);
  final int? statusCode;
  final String message;
  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Single Dio instance + auth/refresh interceptor with a guard so concurrent
/// 401s share a single refresh request.
class ApiClient {
  ApiClient(this._tokens) {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      headers: const {'Content-Type': 'application/json'},
      // Don't throw on 4xx/5xx — we want to inspect them in our wrappers.
      validateStatus: (s) => s != null && s < 500,
    ));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (req, handler) async {
        if (req.extra['auth'] != false) {
          final token = await _tokens.access;
          if (token != null) req.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(req);
      },
      onResponse: (res, handler) async {
        if (res.statusCode == 401 && res.requestOptions.extra['retried'] != true) {
          final newToken = await _attemptRefresh();
          if (newToken != null) {
            final reqOpts = res.requestOptions
              ..headers['Authorization'] = 'Bearer $newToken'
              ..extra['retried'] = true;
            try {
              final retry = await dio.fetch(reqOpts);
              return handler.resolve(retry);
            } catch (_) {
              // fall through
            }
          }
          await _onAuthFailed?.call();
        }
        handler.next(res);
      },
    ));
  }

  static const baseUrl = 'https://project-work-template-be.onrender.com/api';

  late final Dio dio;
  final TokenStorage _tokens;
  Completer<String?>? _refreshing;
  Future<void> Function()? _onAuthFailed;

  void setOnAuthFailed(Future<void> Function() cb) => _onAuthFailed = cb;

  Future<String?> _attemptRefresh() async {
    final running = _refreshing;
    if (running != null) return running.future;
    final c = Completer<String?>();
    _refreshing = c;
    try {
      final refresh = await _tokens.refresh;
      if (refresh == null) {
        await _tokens.clear();
        c.complete(null);
        return null;
      }
      final fresh = Dio(BaseOptions(
        baseUrl: baseUrl,
        headers: const {'Content-Type': 'application/json'},
      ));
      final res = await fresh.post('/refresh', data: {'refreshToken': refresh});
      if (res.statusCode != null && res.statusCode! >= 200 && res.statusCode! < 300) {
        final data = res.data as Map<String, dynamic>;
        final newAccess = data['token'] as String?;
        final newRefresh = data['refreshToken'] as String?;
        if (newAccess != null) await _tokens.setAccess(newAccess);
        if (newRefresh != null) await _tokens.setRefresh(newRefresh);
        c.complete(newAccess);
        return newAccess;
      }
      await _tokens.clear();
      c.complete(null);
      return null;
    } catch (_) {
      await _tokens.clear();
      c.complete(null);
      return null;
    } finally {
      _refreshing = null;
    }
  }
}
