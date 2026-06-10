import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../core/providers.dart';
import 'auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  final tokens = ref.watch(tokenStorageProvider);
  return AuthRepository(api, tokens);
});

class AuthState {
  AuthState({this.user, this.booting = true});
  final User? user;
  final bool booting;
  bool get isAuthenticated => user != null;
  AuthState copyWith({User? user, bool? booting, bool clearUser = false}) =>
      AuthState(
        user: clearUser ? null : (user ?? this.user),
        booting: booting ?? this.booting,
      );
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref) : super(AuthState()) {
    _bootstrap();
    _ref.read(apiClientProvider).setOnAuthFailed(() async {
      await logout();
    });
  }
  final Ref _ref;

  Future<void> _bootstrap() async {
    final user = await _ref.read(authRepositoryProvider).bootstrap();
    state = AuthState(user: user, booting: false);
  }

  Future<void> login(String email, String password) async {
    final user = await _ref.read(authRepositoryProvider).login(email, password);
    state = AuthState(user: user, booting: false);
  }

  Future<void> logout() async {
    await _ref.read(authRepositoryProvider).logout();
    state = AuthState(user: null, booting: false);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) => AuthController(ref));
