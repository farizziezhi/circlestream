# Information Architecture

## CircleStream — App Structure & Navigation

---

## 1. App Structure Overview

```
CircleStream App
├── Auth Flow (unauthenticated)
│   ├── Splash Screen
│   ├── Welcome Screen
│   ├── Login Screen
│   └── Register Screen
│
└── Main App (authenticated)
    ├── Bottom Nav
    │   ├── Tab: Feed
    │   │   ├── Circle Selector (jika multi-circle)
    │   │   └── Feed Screen
    │   ├── Tab: Camera (action)
    │   │   └── Camera Capture → Preview → Upload
    │   └── Tab: Profile
    │       └── Profile Screen
    │
    ├── Circle Screens
    │   ├── Circle List Screen
    │   ├── Create Circle Screen
    │   ├── Join Circle Screen (via invite code)
    │   ├── Circle Detail Screen
    │   ├── Circle Members Screen
    │   └── Invite Code Screen
    │
    └── Post Screens
        └── Photo Fullscreen Viewer
```

---

## 2. Navigation Hierarchy

### Bottom Navigation Tabs

| Tab | Icon | Label | Behavior |
|---|---|---|---|
| Feed | `home_rounded` | Feed | Stack navigasi di dalam tab |
| Camera | `camera_alt` | - | Langsung buka kamera, tidak ada "screen" tetap |
| Profile | `person_rounded` | Profil | Stack navigasi di dalam tab |

Camera tab bukan screen biasa — tap langsung membuka camera flow.

---

## 3. Route Map (go_router)

```dart
final router = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) {
    final isAuth = authBloc.state is AuthAuthenticated;
    final isAuthRoute = state.matchedLocation.startsWith('/auth');
    
    if (!isAuth && !isAuthRoute && state.matchedLocation != '/splash') {
      return '/auth/welcome';
    }
    if (isAuth && isAuthRoute) {
      return '/feed';
    }
    return null;
  },
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => SplashScreen()),
    
    // Auth routes
    ShellRoute(
      builder: (_, __, child) => AuthShell(child: child),
      routes: [
        GoRoute(path: '/auth/welcome',  builder: (_, __) => WelcomeScreen()),
        GoRoute(path: '/auth/login',    builder: (_, __) => LoginScreen()),
        GoRoute(path: '/auth/register', builder: (_, __) => RegisterScreen()),
      ],
    ),
    
    // Main app routes
    StatefulShellRoute.indexedStack(
      builder: (_, __, shell) => MainShell(shell: shell),
      branches: [
        // Feed tab
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/feed',
            builder: (_, __) => FeedScreen(),
            routes: [
              GoRoute(
                path: 'post/:postId',
                builder: (_, state) => PhotoViewerScreen(
                  postId: state.pathParameters['postId']!,
                ),
              ),
            ],
          ),
        ]),
        
        // Camera tab (placeholder)
        StatefulShellBranch(routes: [
          GoRoute(path: '/camera', builder: (_, __) => const SizedBox()),
        ]),
        
        // Profile tab
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/profile',
            builder: (_, __) => ProfileScreen(),
          ),
        ]),
      ],
    ),
    
    // Circle routes (modal/push, bukan tab)
    GoRoute(path: '/circles',            builder: (_, __) => CircleListScreen()),
    GoRoute(path: '/circles/create',     builder: (_, __) => CreateCircleScreen()),
    GoRoute(path: '/circles/join',       builder: (_, __) => JoinCircleScreen()),
    GoRoute(
      path: '/circles/:circleId',
      builder: (_, state) => CircleDetailScreen(
        circleId: state.pathParameters['circleId']!,
      ),
      routes: [
        GoRoute(
          path: 'members',
          builder: (_, state) => CircleMembersScreen(
            circleId: state.pathParameters['circleId']!,
          ),
        ),
        GoRoute(
          path: 'invite',
          builder: (_, state) => InviteCodeScreen(
            circleId: state.pathParameters['circleId']!,
          ),
        ),
      ],
    ),
  ],
);
```

---

## 4. Screen Inventory

| Screen | Route | Auth Required |
|---|---|---|
| Splash | `/splash` | No |
| Welcome | `/auth/welcome` | No |
| Login | `/auth/login` | No |
| Register | `/auth/register` | No |
| Feed | `/feed` | Yes |
| Photo Viewer | `/feed/post/:id` | Yes |
| Camera (flow) | - | Yes |
| Profile | `/profile` | Yes |
| Circle List | `/circles` | Yes |
| Create Circle | `/circles/create` | Yes |
| Join Circle | `/circles/join` | Yes |
| Circle Detail | `/circles/:id` | Yes |
| Circle Members | `/circles/:id/members` | Yes |
| Invite Code | `/circles/:id/invite` | Yes |

---

## 5. Deep Link / State Handling

Saat app pertama kali buka:
1. Show splash screen
2. Check secure storage untuk access token
3. Jika ada → validate → redirect ke `/feed`
4. Jika tidak ada → redirect ke `/auth/welcome`

Saat token expired:
1. Coba refresh menggunakan refresh token
2. Jika berhasil → lanjut request
3. Jika gagal → logout → redirect ke `/auth/welcome`
