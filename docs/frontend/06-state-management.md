# State Management

## CircleStream — Flutter BLoC Architecture

---

## 1. Overview

CircleStream menggunakan **flutter_bloc** (BLoC pattern) untuk semua state management.

**Prinsip:**
- Setiap feature punya BLoC sendiri
- UI hanya emit events dan render states
- Logic bisnis ada di BLoC
- Side effects (API, Ably) ditangani di BLoC

---

## 2. BLoC List

| BLoC | Tanggung Jawab |
|---|---|
| `AuthBloc` | Login, register, logout, token refresh |
| `FeedBloc` | Load feed, real-time post baru, pagination |
| `CircleBloc` | Create, join, leave, detail circle |
| `UploadBloc` | Camera, compress, upload, finalize |
| `ReactionBloc` | Add reaction, live count updates |
| `RealtimeBloc` | Manage Ably connection dan event routing |

---

## 3. AuthBloc

```dart
// Events
abstract class AuthEvent {}
class LoginEvent extends AuthEvent {
  final String email, password;
}
class RegisterEvent extends AuthEvent {
  final String username, email, password;
}
class LogoutEvent extends AuthEvent {}
class RefreshTokenEvent extends AuthEvent {}
class CheckAuthEvent extends AuthEvent {}

// States
abstract class AuthState {}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {
  final UserModel user;
}
class AuthUnauthenticated extends AuthState {}
class AuthError extends AuthState {
  final String error;
}
```

---

## 4. FeedBloc

```dart
// Events
abstract class FeedEvent {}
class LoadFeedEvent extends FeedEvent {
  final int circleId;
}
class LoadMoreFeedEvent extends FeedEvent {}
class RefreshFeedEvent extends FeedEvent {
  final int circleId;
}
class NewPostReceivedEvent extends FeedEvent {
  final PostModel post; // dari Ably
}
class ReactionUpdateReceivedEvent extends FeedEvent {
  final int postId;
  final String emoji;
  final int count;
}

// States
abstract class FeedState {}
class FeedInitial extends FeedState {}
class FeedLoading extends FeedState {}
class FeedLoaded extends FeedState {
  final List<PostModel> posts;
  final bool hasMore;
  final String? nextCursor;
}
class FeedError extends FeedState {
  final String error;
}
```

**BLoC Logic:**

```dart
class FeedBloc extends Bloc<FeedEvent, FeedState> {
  final FeedRepository feedRepository;
  
  FeedBloc({required this.feedRepository}) : super(FeedInitial()) {
    on<LoadFeedEvent>(_onLoadFeed);
    on<LoadMoreFeedEvent>(_onLoadMore);
    on<NewPostReceivedEvent>(_onNewPost);
    on<ReactionUpdateReceivedEvent>(_onReactionUpdate);
  }

  Future<void> _onLoadFeed(LoadFeedEvent event, Emitter<FeedState> emit) async {
    emit(FeedLoading());
    try {
      final result = await feedRepository.getFeed(circleId: event.circleId);
      emit(FeedLoaded(
        posts: result.posts,
        hasMore: result.hasMore,
        nextCursor: result.nextCursor,
      ));
    } catch (e) {
      emit(FeedError(error: e.toString()));
    }
  }

  void _onNewPost(NewPostReceivedEvent event, Emitter<FeedState> emit) {
    if (state is FeedLoaded) {
      final current = (state as FeedLoaded);
      // Tambah post baru di atas list
      emit(FeedLoaded(
        posts: [event.post, ...current.posts],
        hasMore: current.hasMore,
        nextCursor: current.nextCursor,
      ));
    }
  }

  void _onReactionUpdate(ReactionUpdateReceivedEvent event, Emitter<FeedState> emit) {
    if (state is FeedLoaded) {
      final current = (state as FeedLoaded);
      final updatedPosts = current.posts.map((post) {
        if (post.id == event.postId) {
          return post.copyWith(
            reactionCounts: {
              ...post.reactionCounts,
              event.emoji: event.count,
            },
          );
        }
        return post;
      }).toList();
      
      emit(FeedLoaded(
        posts: updatedPosts,
        hasMore: current.hasMore,
        nextCursor: current.nextCursor,
      ));
    }
  }
}
```

---

## 5. UploadBloc

```dart
// Events
abstract class UploadEvent {}
class StartUploadEvent extends UploadEvent {
  final File imageFile;
  final int circleId;
}
class RetryUploadEvent extends UploadEvent {}
class CancelUploadEvent extends UploadEvent {}

// States
abstract class UploadState {}
class UploadIdle extends UploadState {}
class UploadCompressing extends UploadState {}
class UploadPresigning extends UploadState {}
class UploadingToR2 extends UploadState {
  final double progress; // 0.0 - 1.0
}
class UploadFinalizing extends UploadState {}
class UploadSuccess extends UploadState {
  final PostModel post;
}
class UploadError extends UploadState {
  final String error;
  final UploadStep failedStep;
}

enum UploadStep { compress, presign, upload, finalize }
```

---

## 6. RealtimeBloc

```dart
// Events
abstract class RealtimeEvent {}
class ConnectRealtimeEvent extends RealtimeEvent {
  final int circleId;
}
class DisconnectRealtimeEvent extends RealtimeEvent {}
class AblyMessageReceivedEvent extends RealtimeEvent {
  final Map<String, dynamic> data;
}

// States
abstract class RealtimeState {}
class RealtimeDisconnected extends RealtimeState {}
class RealtimeConnecting extends RealtimeState {}
class RealtimeConnected extends RealtimeState {
  final int circleId;
}
class RealtimeError extends RealtimeState {}
```

**RealtimeBloc me-route event Ably ke BLoC lain:**

```dart
void _onAblyMessage(AblyMessageReceivedEvent event, Emitter<RealtimeState> emit) {
  final type = event.data['type'];
  
  switch (type) {
    case 'post_created':
      final post = PostModel.fromJson(event.data['post']);
      feedBloc.add(NewPostReceivedEvent(post: post));
      break;
    case 'reaction_added':
      feedBloc.add(ReactionUpdateReceivedEvent(
        postId: event.data['post_id'],
        emoji: event.data['emoji'],
        count: event.data['count'],
      ));
      // Trigger floating animation
      reactionAnimationController.triggerAnimation(event.data['emoji']);
      break;
    case 'member_joined':
    case 'member_left':
      circleBloc.add(MemberUpdateEvent(data: event.data));
      break;
  }
}
```

---

## 7. Repository Pattern

Setiap BLoC menggunakan repository untuk akses data:

```dart
abstract class FeedRepository {
  Future<FeedResult> getFeed({required int circleId, String? cursor, int limit = 20});
}

class FeedRepositoryImpl implements FeedRepository {
  final ApiClient apiClient;
  
  @override
  Future<FeedResult> getFeed({required int circleId, String? cursor, int limit = 20}) async {
    final response = await apiClient.get(
      '/circles/$circleId/posts',
      queryParameters: {
        'limit': limit,
        if (cursor != null) 'cursor': cursor,
      },
    );
    return FeedResult.fromJson(response.data);
  }
}
```

---

## 8. Dependency Injection

Gunakan `get_it` atau `provider` untuk dependency injection:

```dart
// di main.dart
void setupDependencies() {
  // Clients
  sl.registerLazySingleton(() => ApiClient());
  sl.registerLazySingleton(() => AblyService());
  
  // Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton<FeedRepository>(() => FeedRepositoryImpl(sl()));
  sl.registerLazySingleton<CircleRepository>(() => CircleRepositoryImpl(sl()));
  
  // BLoCs
  sl.registerFactory(() => AuthBloc(authRepository: sl()));
  sl.registerFactory(() => FeedBloc(feedRepository: sl()));
  sl.registerFactory(() => UploadBloc(uploadRepository: sl()));
  sl.registerFactory(() => RealtimeBloc(ablyService: sl(), feedBloc: sl()));
}
```

---

## 9. Optimistic Updates

Untuk reaction, gunakan optimistic update:

```dart
void _onAddReaction(AddReactionEvent event, Emitter<ReactionState> emit) async {
  // 1. Update UI langsung (optimistic)
  final optimisticCount = currentCount + 1;
  emit(ReactionUpdated(emoji: event.emoji, count: optimisticCount));
  
  try {
    // 2. Kirim ke server
    final result = await reactionRepository.addReaction(
      postId: event.postId,
      emoji: event.emoji,
    );
    // 3. Gunakan count dari server (bisa saja berbeda karena concurrent)
    emit(ReactionUpdated(emoji: event.emoji, count: result.count));
  } catch (e) {
    // 4. Revert jika gagal
    emit(ReactionUpdated(emoji: event.emoji, count: currentCount));
    emit(ReactionError(error: e.toString()));
  }
}
```
