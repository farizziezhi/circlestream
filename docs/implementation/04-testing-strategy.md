# Testing Strategy

## CircleStream — Backend & Frontend Testing Guide

---

## 1. Testing Philosophy

- **Backend:** Unit tests untuk service layer, integration tests untuk handlers
- **Frontend:** Widget tests untuk komponen kritis, BLoC tests untuk state
- **Coverage target:** 70% minimum untuk MVP
- **Priority:** Test happy path + critical error paths

---

## 2. Backend Testing (Golang)

### Test Stack
- `testing` — standard library
- `github.com/stretchr/testify` — assertions
- `github.com/DATA-DOG/go-sqlmock` — mock database
- `net/http/httptest` — HTTP handler testing

### Folder Structure

```
circlestream-backend/
├── internal/
│   ├── service/
│   │   ├── auth_service.go
│   │   └── auth_service_test.go      ← unit test service
│   ├── handler/
│   │   ├── auth_handler.go
│   │   └── auth_handler_test.go      ← integration test handler
│   └── repository/
│       ├── user_repository.go
│       └── user_repository_test.go   ← DB test with sqlmock
└── test/
    └── integration/
        └── auth_test.go              ← end-to-end integration
```

---

### 2.1 Service Unit Tests

```go
// internal/service/auth_service_test.go

package service_test

import (
    "testing"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/mock"
    "circlestream/internal/service"
    "circlestream/internal/model"
)

// Mock repository
type MockUserRepository struct {
    mock.Mock
}

func (m *MockUserRepository) FindByEmail(email string) (*model.User, error) {
    args := m.Called(email)
    if args.Get(0) == nil {
        return nil, args.Error(1)
    }
    return args.Get(0).(*model.User), args.Error(1)
}

func (m *MockUserRepository) CreateUser(u *model.User) (*model.User, error) {
    args := m.Called(u)
    return args.Get(0).(*model.User), args.Error(1)
}

// Tests

func TestLogin_Success(t *testing.T) {
    mockRepo := new(MockUserRepository)
    svc := service.NewAuthService(mockRepo, testConfig())

    hashedPwd, _ := password.Hash("password123")
    mockRepo.On("FindByEmail", "john@example.com").Return(&model.User{
        ID:           1,
        Email:        "john@example.com",
        Username:     "johndoe",
        PasswordHash: hashedPwd,
    }, nil)

    result, err := svc.Login("john@example.com", "password123")

    assert.NoError(t, err)
    assert.NotEmpty(t, result.AccessToken)
    assert.NotEmpty(t, result.RefreshToken)
    mockRepo.AssertExpectations(t)
}

func TestLogin_WrongPassword(t *testing.T) {
    mockRepo := new(MockUserRepository)
    svc := service.NewAuthService(mockRepo, testConfig())

    hashedPwd, _ := password.Hash("correctpassword")
    mockRepo.On("FindByEmail", "john@example.com").Return(&model.User{
        PasswordHash: hashedPwd,
    }, nil)

    _, err := svc.Login("john@example.com", "wrongpassword")

    assert.Error(t, err)
    assert.Equal(t, "invalid_credentials", err.Error())
}

func TestLogin_UserNotFound(t *testing.T) {
    mockRepo := new(MockUserRepository)
    svc := service.NewAuthService(mockRepo, testConfig())

    mockRepo.On("FindByEmail", "notfound@example.com").Return(nil, sql.ErrNoRows)

    _, err := svc.Login("notfound@example.com", "password123")

    assert.Error(t, err)
    assert.Equal(t, "invalid_credentials", err.Error())
}

func TestRegister_DuplicateEmail(t *testing.T) {
    mockRepo := new(MockUserRepository)
    svc := service.NewAuthService(mockRepo, testConfig())

    mockRepo.On("FindByEmail", "taken@example.com").Return(&model.User{}, nil)

    _, err := svc.Register("newuser", "taken@example.com", "password123")

    assert.Error(t, err)
    assert.Equal(t, "email_taken", err.Error())
}
```

---

### 2.2 Handler Integration Tests

```go
// internal/handler/auth_handler_test.go

package handler_test

import (
    "bytes"
    "encoding/json"
    "net/http/httptest"
    "testing"

    "github.com/gofiber/fiber/v2"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/mock"
    "circlestream/internal/handler"
)

func setupTestApp(svc service.AuthService) *fiber.App {
    app := fiber.New()
    h := handler.NewAuthHandler(svc)
    app.Post("/auth/register", h.Register)
    app.Post("/auth/login", h.Login)
    return app
}

func TestRegisterHandler_Success(t *testing.T) {
    mockSvc := new(MockAuthService)
    mockSvc.On("Register", "johndoe", "john@example.com", "password123").
        Return(&service.AuthResult{
            User:         model.User{ID: 1, Username: "johndoe"},
            AccessToken:  "access_token_here",
            RefreshToken: "refresh_token_here",
        }, nil)

    app := setupTestApp(mockSvc)

    body, _ := json.Marshal(map[string]string{
        "username": "johndoe",
        "email":    "john@example.com",
        "password": "password123",
    })

    req := httptest.NewRequest("POST", "/auth/register", bytes.NewBuffer(body))
    req.Header.Set("Content-Type", "application/json")

    resp, err := app.Test(req)

    assert.NoError(t, err)
    assert.Equal(t, 201, resp.StatusCode)

    var result map[string]interface{}
    json.NewDecoder(resp.Body).Decode(&result)
    assert.NotNil(t, result["user"])
    assert.NotNil(t, result["tokens"])
}

func TestRegisterHandler_InvalidInput(t *testing.T) {
    app := setupTestApp(new(MockAuthService))

    body, _ := json.Marshal(map[string]string{
        "email":    "not-an-email",
        "password": "short",
    })

    req := httptest.NewRequest("POST", "/auth/register", bytes.NewBuffer(body))
    req.Header.Set("Content-Type", "application/json")

    resp, _ := app.Test(req)
    assert.Equal(t, 400, resp.StatusCode)
}
```

---

### 2.3 Circle Service Tests

```go
// internal/service/circle_service_test.go

func TestJoinCircle_Success(t *testing.T) { ... }

func TestJoinCircle_CircleFull(t *testing.T) {
    // Setup: circle sudah ada 10 member
    // Expected: error "circle_full"
}

func TestJoinCircle_AlreadyMember(t *testing.T) {
    // Setup: user sudah di circle
    // Expected: error "already_member"
}

func TestJoinCircle_ExpiredCode(t *testing.T) {
    // Setup: code dengan expires_at di masa lalu
    // Expected: error "invite_code_expired"
}

func TestJoinCircle_ExhaustedCode(t *testing.T) {
    // Setup: max_uses = 1, used_count = 1
    // Expected: error "invite_code_exhausted"
}

func TestLeaveCircle_Owner(t *testing.T) {
    // Setup: user adalah owner
    // Expected: error "owner_cannot_leave"
}

func TestLeaveCircle_Member(t *testing.T) {
    // Setup: user adalah member biasa
    // Expected: success
}
```

---

### 2.4 Reaction Tests

```go
// internal/service/reaction_service_test.go

func TestAddReaction_ValidEmoji(t *testing.T) {
    // Expected: Redis counter increment, Turso insert, Ably publish
}

func TestAddReaction_InvalidEmoji(t *testing.T) {
    // Input: emoji "🎈" (not in preset)
    // Expected: error "invalid_emoji"
}

func TestAddReaction_NotMember(t *testing.T) {
    // Expected: 403 not_member
}
```

---

### 2.5 Run Tests

```bash
# Run all tests
go test ./...

# Run with coverage
go test ./... -cover

# Run specific package
go test ./internal/service/...

# Run with verbose output
go test ./... -v

# Generate coverage report
go test ./... -coverprofile=coverage.out
go tool cover -html=coverage.out
```

---

## 3. Frontend Testing (Flutter)

### Test Stack
- `flutter_test` — built-in
- `bloc_test` — BLoC testing
- `mocktail` — mocking
- `network_image_mock` — mock network images

### Folder Structure

```
test/
├── features/
│   ├── auth/
│   │   ├── auth_bloc_test.dart
│   │   └── login_screen_test.dart
│   ├── feed/
│   │   ├── feed_bloc_test.dart
│   │   └── photo_card_test.dart
│   ├── circle/
│   │   └── circle_bloc_test.dart
│   └── reaction/
│       └── reaction_bloc_test.dart
├── shared/
│   └── widgets/
│       ├── app_button_test.dart
│       └── emoji_reaction_bar_test.dart
└── helpers/
    ├── mock_repositories.dart
    └── test_data.dart
```

---

### 3.1 BLoC Tests

```dart
// test/features/auth/auth_bloc_test.dart

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:circlestream/features/auth/bloc/auth_bloc.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepo;
  late AuthBloc authBloc;

  setUp(() {
    mockRepo = MockAuthRepository();
    authBloc = AuthBloc(authRepository: mockRepo);
  });

  tearDown(() => authBloc.close());

  group('LoginEvent', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] on successful login',
      build: () {
        when(() => mockRepo.login(
          email: 'john@example.com',
          password: 'password123',
        )).thenAnswer((_) async => AuthResult(
          user: UserModel(id: 1, username: 'johndoe', email: 'john@example.com'),
          accessToken: 'token',
        ));
        return authBloc;
      },
      act: (bloc) => bloc.add(LoginEvent(
        email: 'john@example.com',
        password: 'password123',
      )),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] on invalid credentials',
      build: () {
        when(() => mockRepo.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(ApiException(code: 'invalid_credentials', message: '...', statusCode: 401));
        return authBloc;
      },
      act: (bloc) => bloc.add(LoginEvent(
        email: 'wrong@example.com',
        password: 'wrongpass',
      )),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>(),
      ],
    );
  });
}
```

---

### 3.2 Feed BLoC Tests

```dart
// test/features/feed/feed_bloc_test.dart

void main() {
  group('FeedBloc', () {
    blocTest<FeedBloc, FeedState>(
      'emits [FeedLoading, FeedLoaded] on LoadFeedEvent',
      // ...
    );

    blocTest<FeedBloc, FeedState>(
      'prepends new post on NewPostReceivedEvent',
      build: () => feedBloc,
      seed: () => FeedLoaded(
        posts: [mockPost(id: 1)],
        hasMore: false,
        nextCursor: null,
      ),
      act: (bloc) => bloc.add(NewPostReceivedEvent(post: mockPost(id: 2))),
      expect: () => [
        isA<FeedLoaded>().having(
          (s) => s.posts.first.id, 'first post id', 2,
        ),
      ],
    );

    blocTest<FeedBloc, FeedState>(
      'updates reaction count on ReactionUpdateReceivedEvent',
      build: () => feedBloc,
      seed: () => FeedLoaded(
        posts: [mockPost(id: 42, reactionCounts: {'❤️': 5})],
        hasMore: false,
        nextCursor: null,
      ),
      act: (bloc) => bloc.add(ReactionUpdateReceivedEvent(
        postId: 42,
        emoji: '❤️',
        count: 6,
      )),
      expect: () => [
        isA<FeedLoaded>().having(
          (s) => s.posts.first.reactionCounts['❤️'], 'reaction count', 6,
        ),
      ],
    );
  });
}
```

---

### 3.3 Widget Tests

```dart
// test/shared/widgets/emoji_reaction_bar_test.dart

void main() {
  testWidgets('EmojiReactionBar shows all preset emojis', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: EmojiReactionBar(
        counts: {'❤️': 5, '🔥': 2},
        onReact: (_) {},
      ),
    ));

    expect(find.text('❤️'), findsOneWidget);
    expect(find.text('🔥'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('EmojiReactionBar calls onReact on tap', (tester) async {
    String? tappedEmoji;

    await tester.pumpWidget(MaterialApp(
      home: EmojiReactionBar(
        counts: {},
        onReact: (emoji) => tappedEmoji = emoji,
      ),
    ));

    await tester.tap(find.text('❤️').first);
    expect(tappedEmoji, '❤️');
  });
}
```

---

### 3.4 Run Flutter Tests

```bash
# Run all tests
flutter test

# Run specific file
flutter test test/features/auth/auth_bloc_test.dart

# Run with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

---

## 4. Manual Testing Checklist

### Auth Flow
- [ ] Register user baru berhasil
- [ ] Register email duplikat menampilkan error
- [ ] Login berhasil, token tersimpan
- [ ] Login salah password menampilkan error
- [ ] Logout menghapus token
- [ ] Token expired → auto refresh
- [ ] Refresh token habis → logout otomatis

### Circle Flow
- [ ] Create circle berhasil, invite code muncul
- [ ] Join circle dengan kode valid
- [ ] Join circle dengan kode tidak ada → error
- [ ] Join circle sudah penuh → error
- [ ] Leave circle (member) berhasil
- [ ] Leave circle (owner) → error

### Upload Flow
- [ ] Foto dari kamera berhasil dicompress
- [ ] Upload ke R2 berhasil
- [ ] Post muncul di feed setelah upload
- [ ] File > 10MB ditolak

### Real-time
- [ ] Post baru muncul di semua device tanpa refresh
- [ ] Reaction count update real-time
- [ ] Emoji floating animation muncul
- [ ] Offline indicator saat disconnect
- [ ] Data sync saat reconnect
