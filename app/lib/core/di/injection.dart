library circlestream.core.di.injection;

import 'package:get_it/get_it.dart';
import '../storage/secure_storage.dart';
import '../network/api_client.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/data/auth_repository_impl.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/circle/data/circle_repository.dart';
import '../../features/circle/data/circle_repository_impl.dart';
import '../../features/circle/bloc/circle_bloc.dart';
import '../../features/feed/data/feed_repository.dart';
import '../../features/feed/data/feed_repository_impl.dart';
import '../../features/feed/bloc/feed_bloc.dart';
import '../../features/camera/data/upload_repository.dart';
import '../../features/camera/data/upload_repository_impl.dart';
import '../../features/camera/bloc/upload_bloc.dart';
import '../../features/realtime/services/ably_service.dart';
import '../../features/realtime/bloc/realtime_bloc.dart';
import '../../features/reaction/data/reaction_repository.dart';
import '../../features/reaction/data/reaction_repository_impl.dart';
import '../../features/reaction/bloc/reaction_bloc.dart';

final sl = GetIt.instance;

Future<void> setupDependencies() async {
  // Storage
  sl.registerLazySingleton<SecureStorage>(() => SecureStorage());

  // Network Client
  sl.registerLazySingleton<ApiClient>(() => ApiClient(secureStorage: sl<SecureStorage>()));

  // Services
  sl.registerLazySingleton<AblyService>(() => AblyService());

  // Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
        apiClient: sl<ApiClient>(),
        storage: sl<SecureStorage>(),
      ));
  sl.registerLazySingleton<CircleRepository>(() => CircleRepositoryImpl(
        apiClient: sl<ApiClient>(),
      ));
  sl.registerLazySingleton<FeedRepository>(() => FeedRepositoryImpl(
        apiClient: sl<ApiClient>(),
      ));
  sl.registerLazySingleton<UploadRepository>(() => UploadRepositoryImpl(
        apiClient: sl<ApiClient>(),
      ));
  sl.registerLazySingleton<ReactionRepository>(() => ReactionRepositoryImpl(
        apiClient: sl<ApiClient>(),
      ));

  // Blocs
  sl.registerFactory(() => AuthBloc(
        authRepository: sl<AuthRepository>(),
        secureStorage: sl<SecureStorage>(),
      ));
  sl.registerFactory(() => CircleBloc(
        circleRepository: sl<CircleRepository>(),
      ));
  sl.registerLazySingleton(() => FeedBloc(
        feedRepository: sl<FeedRepository>(),
      ));
  sl.registerFactory(() => UploadBloc(
        uploadRepository: sl<UploadRepository>(),
      ));
  sl.registerLazySingleton(() => RealtimeBloc(
        ablyService: sl<AblyService>(),
        feedBloc: sl<FeedBloc>(),
        apiClient: sl<ApiClient>(),
      ));
  sl.registerFactory(() => ReactionBloc(
        reactionRepository: sl<ReactionRepository>(),
        feedBloc: sl<FeedBloc>(),
      ));
}
