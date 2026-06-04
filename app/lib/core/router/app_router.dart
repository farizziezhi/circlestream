library circlestream.core.router.app_router;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/bloc/auth_state.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/welcome_screen.dart';
import '../../features/circle/screens/circle_detail_screen.dart';
import '../../features/circle/screens/circle_list_screen.dart';
import '../../features/circle/screens/circle_members_screen.dart';
import '../../features/circle/screens/create_circle_screen.dart';
import '../../features/circle/screens/invite_code_screen.dart';
import '../../features/circle/screens/join_circle_screen.dart';
import '../../features/feed/screens/feed_screen.dart';
import '../../features/feed/screens/photo_viewer_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../shared/widgets/app_bottom_nav.dart';
import '../di/injection.dart';

// Helper class to convert a Stream (AuthBloc state stream) into a Listenable for GoRouter
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription _subscription;

  GoRouterRefreshStream(Stream stream) {
    notifyListeners();
    _subscription = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class AuthShell extends StatelessWidget {
  final Widget child;
  const AuthShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: child);
  }
}

class MainShell extends StatelessWidget {
  final StatefulNavigationShell shell;
  const MainShell({super.key, required this.shell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: AppBottomNav(
        currentIndex: shell.currentIndex,
        onTap: (index) {
          shell.goBranch(index);
        },
      ),
    );
  }
}

final appRouter = GoRouter(
  initialLocation: '/splash',
  refreshListenable: GoRouterRefreshStream(sl<AuthBloc>().stream),
  redirect: (context, state) {
    final authBloc = sl<AuthBloc>();
    final bool isAuth = authBloc.state is AuthAuthenticated;
    
    // Check if the target route is under /auth/
    final bool isAuthRoute = state.matchedLocation.startsWith('/auth');

    // If not authenticated and not currently going to splash or auth flow, redirect to welcome
    if (!isAuth && !isAuthRoute && state.matchedLocation != '/splash') {
      return '/auth/welcome';
    }
    
    // If already authenticated and trying to access login/register/welcome, redirect to feed
    if (isAuth && isAuthRoute) {
      return '/feed';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    
    // Auth flow routes wrapped in AuthShell
    ShellRoute(
      builder: (context, state, child) => AuthShell(child: child),
      routes: [
        GoRoute(
          path: '/auth/welcome',
          builder: (context, state) => const WelcomeScreen(),
        ),
        GoRoute(
          path: '/auth/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/auth/register',
          builder: (context, state) => const RegisterScreen(),
        ),
      ],
    ),
    
    // Main App Tab Shell Routes
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => MainShell(shell: navigationShell),
      branches: [
        // Tab 1: Feed
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/feed',
              builder: (context, state) => const FeedScreen(),
              routes: [
                GoRoute(
                  path: 'post/:postId',
                  builder: (context, state) {
                    final postId = state.pathParameters['postId']!;
                    return PhotoViewerScreen(postId: postId);
                  },
                ),
              ],
            ),
          ],
        ),
        // Tab 2: Camera Capture (Interactive view, returns empty wrapper on tab branch)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/camera',
              builder: (context, state) => const SizedBox.shrink(),
            ),
          ],
        ),
        // Tab 3: Profile
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),

    // Circle management routes (modal-style overlay / push routes)
    GoRoute(
      path: '/circles',
      builder: (context, state) => const CircleListScreen(),
    ),
    GoRoute(
      path: '/circles/create',
      builder: (context, state) => const CreateCircleScreen(),
    ),
    GoRoute(
      path: '/circles/join',
      builder: (context, state) => const JoinCircleScreen(),
    ),
    GoRoute(
      path: '/circles/:circleId',
      builder: (context, state) {
        final circleId = state.pathParameters['circleId']!;
        return CircleDetailScreen(circleId: circleId);
      },
      routes: [
        GoRoute(
          path: 'members',
          builder: (context, state) {
            final circleId = state.pathParameters['circleId']!;
            return CircleMembersScreen(circleId: circleId);
          },
        ),
        GoRoute(
          path: 'invite',
          builder: (context, state) {
            final circleId = state.pathParameters['circleId']!;
            return InviteCodeScreen(circleId: circleId);
          },
        ),
      ],
    ),
  ],
);
