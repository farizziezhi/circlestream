library circlestream.core.di.injection;

import 'package:get_it/get_it.dart';
import '../storage/secure_storage.dart';
import '../network/api_client.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/data/auth_repository_impl.dart';
import '../../features/auth/bloc/auth_bloc.dart';

final sl = GetIt.instance;

Future<void> setupDependencies() async {
  // Storage
  sl.registerLazySingleton<SecureStorage>(() => SecureStorage());

  // Network Client
  sl.registerLazySingleton<ApiClient>(() => ApiClient(secureStorage: sl<SecureStorage>()));

  // Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
        apiClient: sl<ApiClient>(),
        storage: sl<SecureStorage>(),
      ));

  // Blocs
  sl.registerFactory(() => AuthBloc(
        authRepository: sl<AuthRepository>(),
        secureStorage: sl<SecureStorage>(),
      ));
}
