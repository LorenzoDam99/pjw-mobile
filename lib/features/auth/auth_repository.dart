import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../core/models/models.dart';
import '../../core/storage/token_storage.dart';
import '../../core/utils/jwt.dart';

class AuthRepository {
  AuthRepository(this._api, this._tokens);
  final ApiClient _api;
  final TokenStorage _tokens;

  Future<User> login(String email, String password) async {
    final res = await _api.dio.post(
      '/login',
      data: {'email': email, 'password': password},
      options: Options(extra: const {'auth': false}),
    );
    if (res.statusCode != 200) {
      throw ApiException(res.statusCode, 'Credenziali non valide');
    }
    final data = res.data as Map<String, dynamic>;
    final token = data['token'] as String;
    final refresh = data['refreshToken'] as String?;
    await _tokens.setAccess(token);
    if (refresh != null) await _tokens.setRefresh(refresh);
    final payload = decodeJwt(token);
    if (payload == null) throw ApiException(0, 'Token non valido');
    return User.fromJson(payload);
  }

  Future<void> register({
    required String email,
    required String username,
    required String firstName,
    required String lastName,
    required String password,
    required String confirmPassword,
  }) async {
    final res = await _api.dio.post(
      '/register',
      data: {
        'email': email,
        'username': username,
        'firstName': firstName,
        'lastName': lastName,
        'password': password,
        'confirmPassword': confirmPassword,
      },
      options: Options(extra: const {'auth': false}),
    );
    if (res.statusCode != null && res.statusCode! >= 400) {
      final msg = (res.data is Map && res.data['message'] is String)
          ? res.data['message'] as String
          : 'Registrazione fallita (${res.statusCode})';
      throw ApiException(res.statusCode, msg);
    }
  }

  Future<void> verifyOtp({required String email, required String otpCode}) async {
    final res = await _api.dio.post(
      '/authorize',
      data: {'email': email, 'otpCode': otpCode},
      options: Options(extra: const {'auth': false}),
    );
    if (res.statusCode == 400) {
      throw ApiException(400, 'Codice OTP non valido');
    }
    if (res.statusCode != null && res.statusCode! >= 400) {
      throw ApiException(res.statusCode, 'Verifica fallita');
    }
  }

  Future<User?> bootstrap() async {
    final token = await _tokens.access;
    if (token == null) return null;
    final payload = decodeJwt(token);
    if (payload == null) return null;
    return User.fromJson(payload);
  }

  Future<void> logout() async => _tokens.clear();
}
