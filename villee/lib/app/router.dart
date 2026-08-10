import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/password_reset_screen.dart';
import '../features/auth/presentation/screens/sign_up_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/profile/domain/user_profile.dart';
import '../features/profile/presentation/screens/profile_edit_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final authNotifier = AuthStateNotifier(authRepository);

  ref.onDispose(authNotifier.dispose);

  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final path = state.matchedLocation;

      if (!authNotifier.initialized) {
        return path == '/splash' ? null : '/splash';
      }

      final isLoggedIn = authNotifier.user != null;
      final isAuthPage = {
        '/login',
        '/sign-up',
        '/password-reset',
      }.contains(path);

      if (!isLoggedIn) {
        return isAuthPage ? null : '/login';
      }

      if (isAuthPage || path == '/splash') {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/sign-up',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/password-reset',
        builder: (context, state) => const PasswordResetScreen(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/profile/edit',

        // extraがない状態で直接アクセスされた場合はホームへ戻す。
        redirect: (context, state) {
          return state.extra is UserProfile ? null : '/home';
        },

        builder: (context, state) {
          return ProfileEditScreen(profile: state.extra! as UserProfile);
        },
      ),
    ],
  );

  ref.onDispose(router.dispose);

  return router;
});

class AuthStateNotifier extends ChangeNotifier {
  AuthStateNotifier(AuthRepository authRepository) {
    _subscription = authRepository.authStateChanges().listen((user) {
      this.user = user;
      initialized = true;
      notifyListeners();
    });
  }

  User? user;
  bool initialized = false;

  late final StreamSubscription<User?> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
