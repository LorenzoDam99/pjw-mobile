import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_controller.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/verify_otp_screen.dart';
import '../../features/bookings/booking_detail_screen.dart';
import '../../features/bookings/bookings_list_screen.dart';
import '../../features/new_booking/new_booking_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: _AuthListenable(ref),
    redirect: (ctx, state) {
      final auth = ref.read(authControllerProvider);
      if (auth.booting) return null;
      final loggedIn = auth.isAuthenticated;
      final loc = state.matchedLocation;
      final isAuthRoute =
          loc == '/login' || loc == '/register' || loc == '/verify-otp';
      if (!loggedIn && !isAuthRoute) return '/login';
      if (loggedIn && isAuthRoute) return '/bookings';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/verify-otp',
        builder: (ctx, st) {
          final email = st.extra as String?;
          if (email == null) return const RegisterScreen();
          return VerifyOtpScreen(email: email);
        },
      ),
      GoRoute(
          path: '/bookings', builder: (_, __) => const BookingsListScreen()),
      GoRoute(
        path: '/bookings/new',
        builder: (_, __) => const NewBookingScreen(),
      ),
      GoRoute(
        path: '/bookings/:id',
        builder: (ctx, st) => BookingDetailScreen(id: st.pathParameters['id']!),
      ),
    ],
  );
});

/// Adapter so go_router refreshes when the auth state changes.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(this._ref) {
    _sub = _ref.listen<AuthState>(
      authControllerProvider,
      (_, __) => notifyListeners(),
      fireImmediately: false,
    );
  }
  final Ref _ref;
  late final ProviderSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}
