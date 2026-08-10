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

import '../features/friends/presentation/screens/friend_list_screen.dart';
import '../features/friends/presentation/screens/friend_requests_screen.dart';
import '../features/friends/presentation/screens/friend_search_screen.dart';

import '../features/home/presentation/home_screen.dart';
import '../features/home/presentation/main_scaffold.dart';

import '../features/map/presentation/map_screen.dart';

import '../features/profile/domain/user_profile.dart';
import '../features/profile/presentation/screens/profile_edit_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';

import '../features/settings/presentation/settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final authNotifier = AuthStateNotifier(authRepository);

  ref.onDispose(authNotifier.dispose);

  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: authNotifier,

    // 認証状態に応じてアクセス先を制御する。
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
        builder: (context, state) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),

      GoRoute(
        path: '/login',
        builder: (context, state) {
          return const LoginScreen();
        },
      ),

      GoRoute(
        path: '/sign-up',
        builder: (context, state) {
          return const SignUpScreen();
        },
      ),

      GoRoute(
        path: '/password-reset',
        builder: (context, state) {
          return const PasswordResetScreen();
        },
      ),

      // ログイン後にプロフィール作成済みか確認する。
      GoRoute(
        path: '/home',
        builder: (context, state) {
          return const HomeScreen();
        },
      ),

      // プロフィール・マップ・設定の3タブ。
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScaffold(
            navigationShell: navigationShell,
          );
        },
        branches: [
          // プロフィール
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) {
                  return const ProfileScreen();
                },
                routes: [
                  GoRoute(
                    path: 'friends',
                    builder: (context, state) {
                      return const FriendListScreen();
                    },
                  ),
                  GoRoute(
                    path: 'friend-search',
                    builder: (context, state) {
                      return const FriendSearchScreen();
                    },
                  ),
                  GoRoute(
                    path: 'friend-requests',
                    builder: (context, state) {
                      return const FriendRequestsScreen();
                    },
                  ),
                ],
              ),
            ],
          ),

          // マップ
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/map',
                builder: (context, state) {
                  return const MapScreen();
                },
              ),
            ],
          ),

          // 設定
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) {
                  return const SettingsScreen();
                },
              ),
            ],
          ),
        ],
      ),

      // プロフィール編集
      GoRoute(
        path: '/profile/edit',
        redirect: (context, state) {
          if (state.extra is! UserProfile) {
            return '/home';
          }

          return null;
        },
        builder: (context, state) {
          final profile = state.extra! as UserProfile;

          return ProfileEditScreen(
            profile: profile,
          );
        },
      ),
    ],
  );

  ref.onDispose(router.dispose);

  return router;
});

/// Firebase Authenticationの状態変化をGoRouterへ通知する。
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