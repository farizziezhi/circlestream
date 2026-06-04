# Flutter Folder Structure

## CircleStream — Project Directory Layout

---

## 1. Full Structure

```
circlestream_flutter/
├── android/
├── ios/
├── lib/
│   ├── main.dart
│   ├── app.dart                          ← MaterialApp + GoRouter setup
│   │
│   ├── core/
│   │   ├── config/
│   │   │   ├── app_config.dart           ← env vars, base URLs
│   │   │   └── constants.dart            ← emoji presets, limits
│   │   │
│   │   ├── di/
│   │   │   └── injection.dart            ← get_it dependency setup
│   │   │
│   │   ├── errors/
│   │   │   ├── exceptions.dart
│   │   │   └── failures.dart
│   │   │
│   │   ├── network/
│   │   │   ├── api_client.dart           ← Dio setup + interceptors
│   │   │   ├── auth_interceptor.dart     ← JWT auto-refresh
│   │   │   └── endpoints.dart            ← semua API endpoint constants
│   │   │
│   │   ├── router/
│   │   │   └── app_router.dart           ← GoRouter configuration
│   │   │
│   │   ├── storage/
│   │   │   └── secure_storage.dart       ← flutter_secure_storage wrapper
│   │   │
│   │   └── utils/
│   │       ├── date_formatter.dart
│   │       ├── image_compressor.dart     ← compress + thumbnail generation
│   │       └── validators.dart
│   │
│   ├── design/
│   │   ├── app_colors.dart
│   │   ├── app_text_styles.dart
│   │   ├── app_spacing.dart
│   │   ├── app_radius.dart
│   │   ├── app_shadows.dart
│   │   └── app_theme.dart               ← ThemeData assembly
│   │
│   ├── shared/
│   │   ├── models/
│   │   │   ├── user_model.dart
│   │   │   ├── circle_model.dart
│   │   │   ├── post_model.dart
│   │   │   ├── reaction_model.dart
│   │   │   └── invite_code_model.dart
│   │   │
│   │   └── widgets/
│   │       ├── app_button.dart
│   │       ├── app_card.dart
│   │       ├── app_text_field.dart
│   │       ├── app_bottom_nav.dart
│   │       ├── app_loading_indicator.dart
│   │       ├── app_error_widget.dart
│   │       ├── app_empty_state.dart
│   │       ├── avatar_widget.dart
│   │       └── cached_image.dart
│   │
│   └── features/
│       │
│       ├── auth/
│       │   ├── bloc/
│       │   │   ├── auth_bloc.dart
│       │   │   ├── auth_event.dart
│       │   │   └── auth_state.dart
│       │   ├── data/
│       │   │   ├── auth_repository.dart
│       │   │   └── auth_repository_impl.dart
│       │   └── screens/
│       │       ├── splash_screen.dart
│       │       ├── welcome_screen.dart
│       │       ├── login_screen.dart
│       │       └── register_screen.dart
│       │
│       ├── feed/
│       │   ├── bloc/
│       │   │   ├── feed_bloc.dart
│       │   │   ├── feed_event.dart
│       │   │   └── feed_state.dart
│       │   ├── data/
│       │   │   ├── feed_repository.dart
│       │   │   └── feed_repository_impl.dart
│       │   ├── screens/
│       │   │   ├── feed_screen.dart
│       │   │   └── photo_viewer_screen.dart
│       │   └── widgets/
│       │       ├── photo_card.dart
│       │       ├── circle_selector.dart
│       │       └── new_post_indicator.dart
│       │
│       ├── camera/
│       │   ├── bloc/
│       │   │   ├── upload_bloc.dart
│       │   │   ├── upload_event.dart
│       │   │   └── upload_state.dart
│       │   ├── data/
│       │   │   ├── upload_repository.dart
│       │   │   └── upload_repository_impl.dart
│       │   └── screens/
│       │       ├── camera_capture_screen.dart
│       │       └── photo_preview_screen.dart
│       │
│       ├── circle/
│       │   ├── bloc/
│       │   │   ├── circle_bloc.dart
│       │   │   ├── circle_event.dart
│       │   │   └── circle_state.dart
│       │   ├── data/
│       │   │   ├── circle_repository.dart
│       │   │   └── circle_repository_impl.dart
│       │   └── screens/
│       │       ├── circle_list_screen.dart
│       │       ├── create_circle_screen.dart
│       │       ├── join_circle_screen.dart
│       │       ├── circle_detail_screen.dart
│       │       ├── circle_members_screen.dart
│       │       └── invite_code_screen.dart
│       │
│       ├── reaction/
│       │   ├── bloc/
│       │   │   ├── reaction_bloc.dart
│       │   │   ├── reaction_event.dart
│       │   │   └── reaction_state.dart
│       │   ├── data/
│       │   │   ├── reaction_repository.dart
│       │   │   └── reaction_repository_impl.dart
│       │   └── widgets/
│       │       ├── emoji_reaction_bar.dart
│       │       └── floating_emoji_animation.dart
│       │
│       ├── realtime/
│       │   ├── bloc/
│       │   │   ├── realtime_bloc.dart
│       │   │   ├── realtime_event.dart
│       │   │   └── realtime_state.dart
│       │   └── services/
│       │       └── ably_service.dart
│       │
│       └── profile/
│           ├── bloc/
│           │   ├── profile_bloc.dart
│           │   ├── profile_event.dart
│           │   └── profile_state.dart
│           └── screens/
│               └── profile_screen.dart
│
├── test/
│   ├── features/
│   │   ├── auth/
│   │   ├── feed/
│   │   └── circle/
│   └── shared/
│
├── pubspec.yaml
├── pubspec.lock
├── analysis_options.yaml
└── .env                                  ← JANGAN commit ke git
```

---

## 2. Key File Details

### `lib/core/config/constants.dart`

```dart
class AppConstants {
  // API
  static const String baseUrl = String.fromEnvironment('API_BASE_URL',
    defaultValue: 'http://localhost:8080/v1');

  // Image
  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10MB
  static const int targetFileSizeBytes = 3 * 1024 * 1024; // 3MB
  static const int maxImageDimension = 2048;
  static const int thumbnailDimension = 400;

  // Circle
  static const int maxCircleMembers = 10;

  // Feed
  static const int feedPageSize = 20;

  // Emoji presets
  static const List<String> emojiPresets = [
    '❤️', '😂', '😮', '🔥', '👏', '😢', '🤩', '💀'
  ];

  // Token
  static const String accessTokenKey  = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey       = 'user_id';
}
```

### `lib/core/network/endpoints.dart`

```dart
class Endpoints {
  static const String register      = '/auth/register';
  static const String login         = '/auth/login';
  static const String refresh       = '/auth/refresh';
  static const String logout        = '/auth/logout';
  static const String ablyToken     = '/ably/token';

  static const String circles       = '/circles';
  static const String joinCircle    = '/circles/join';
  static String circleDetail(int id)   => '/circles/$id';
  static String circleMembers(int id)  => '/circles/$id/members';
  static String leaveCircle(int id)    => '/circles/$id/leave';
  static String inviteCodes(int id)    => '/circles/$id/invite-codes';

  static const String presignUpload = '/media/presign-upload';
  static const String finalizeUpload = '/media/finalize';

  static String circlePosts(int id)    => '/circles/$id/posts';
  static String postDetail(int id)     => '/posts/$id';
  static String postReactions(int id)  => '/posts/$id/reactions';
}
```

---

## 3. Naming Conventions

| Type | Convention | Example |
|---|---|---|
| Files | snake_case | `feed_bloc.dart` |
| Classes | PascalCase | `FeedBloc` |
| Variables | camelCase | `circleId` |
| Constants | camelCase | `maxCircleMembers` |
| Routes | kebab-case | `/circles/join` |
| BLoC Events | PascalCase + Event | `LoadFeedEvent` |
| BLoC States | PascalCase + State | `FeedLoaded` |
