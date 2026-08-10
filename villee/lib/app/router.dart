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
import '../features/home/presentation/main_scaffold.dart';
import '../features/map/presentation/map_screen.dart';
import '../features/profile/domain/user_profile.dart';
import '../features/profile/presentation/screens/profile_edit_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/settings/presentation/settings_screen.dart';

/// アプリ全体のルーティングを管理するProvider。
///
/// Firebase Authenticationの認証状態を監視し、
/// 未ログイン・ログイン済みに応じて適切な画面へリダイレクトする。
final routerProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);

  // Firebase Authenticationの状態変化をGoRouterへ通知する。
  final authNotifier = AuthStateNotifier(authRepository);

  ref.onDispose(authNotifier.dispose);

  final router = GoRouter(
    // アプリ起動直後はFirebaseの認証状態が確定するまで
    // スプラッシュ画面を表示する。
    initialLocation: '/splash',

    // ログイン・ログアウトが発生するとredirectを再評価する。
    refreshListenable: authNotifier,

    /// 認証状態によるアクセス制御。
    redirect: (context, state) {
      final path = state.matchedLocation;

      // Firebaseが端末に保存された認証情報を
      // 復元している間はスプラッシュ画面を表示する。
      if (!authNotifier.initialized) {
        return path == '/splash' ? null : '/splash';
      }

      final isLoggedIn = authNotifier.user != null;

      // 未ログインでもアクセスできる認証関連画面。
      final isAuthPage = {
        '/login',
        '/sign-up',
        '/password-reset',
      }.contains(path);

      // 未ログインユーザーが認証画面以外へ
      // アクセスしようとした場合はログイン画面へ戻す。
      if (!isLoggedIn) {
        return isAuthPage ? null : '/login';
      }

      // ログイン済みユーザーがログイン画面などへ
      // アクセスした場合は、ログイン後の入口へ移動する。
      if (isAuthPage || path == '/splash') {
        return '/home';
      }

      return null;
    },

    routes: [
      // --------------------------------------------------
      // 起動・認証
      // --------------------------------------------------
      GoRoute(
        path: '/splash',
        builder: (context, state) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
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

      // --------------------------------------------------
      // ログイン後の入口
      // --------------------------------------------------

      // HomeScreenではプロフィールが作成済みか確認する。
      //
      // 未作成
      //   → ProfileSetupScreen
      //
      // 作成済み
      //   → /profile
      GoRoute(
        path: '/home',
        builder: (context, state) {
          return const HomeScreen();
        },
      ),

      // --------------------------------------------------
      // メイン画面
      // --------------------------------------------------

      // StatefulShellRouteを使うことで、
      // プロフィール・マップ・設定の3タブそれぞれに
      // 独立したNavigatorを持たせる。
      //
      // タブを切り替えても各画面の状態を保持しやすくなる。
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScaffold(navigationShell: navigationShell);
        },
        branches: [
          // ------------------------------
          // プロフィールタブ
          // ------------------------------
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) {
                  return const ProfileScreen();
                },
              ),
            ],
          ),

          // ------------------------------
          // マップタブ
          // ------------------------------
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

          // ------------------------------
          // 設定タブ
          // ------------------------------
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

      // --------------------------------------------------
      // プロフィール編集
      // --------------------------------------------------
      GoRoute(
        path: '/profile/edit',

        // UserProfileを渡さず直接このURLへアクセスした場合は、
        // 編集対象が分からないため/homeへ戻す。
        redirect: (context, state) {
          if (state.extra is! UserProfile) {
            return '/home';
          }

          return null;
        },

        builder: (context, state) {
          final profile = state.extra! as UserProfile;

          return ProfileEditScreen(profile: profile);
        },
      ),
    ],
  );

  // routerProviderが破棄されたとき、
  // GoRouter自身も破棄する。
  ref.onDispose(router.dispose);

  return router;
});

/// Firebase Authenticationの認証状態を監視し、
/// GoRouterへ状態変化を通知するクラス。
///
/// ChangeNotifierを使うことで、
/// ログイン・ログアウト時にGoRouterのredirectを再実行できる。
class AuthStateNotifier extends ChangeNotifier {
  AuthStateNotifier(AuthRepository authRepository) {
    _subscription = authRepository.authStateChanges().listen((user) {
      // ログイン済みならUser、未ログインならnullが渡される。
      this.user = user;

      // 最初の認証状態を取得できた時点で初期化完了とする。
      initialized = true;

      // GoRouterへ状態が変化したことを通知する。
      notifyListeners();
    });
  }

  /// 現在ログインしているFirebaseユーザー。
  ///
  /// 未ログインの場合はnull。
  User? user;

  /// Firebaseの初回認証状態確認が完了したか。
  bool initialized = false;

  late final StreamSubscription<User?> _subscription;

  @override
  void dispose() {
    // Firebase Authenticationの監視を終了する。
    _subscription.cancel();

    super.dispose();
  }
}
