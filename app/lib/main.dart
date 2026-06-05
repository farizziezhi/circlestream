library circlestream.main;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app.dart';
import 'core/di/injection.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/circle/bloc/circle_bloc.dart';
import 'features/feed/bloc/feed_bloc.dart';
import 'features/camera/bloc/upload_bloc.dart';
import 'features/realtime/bloc/realtime_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Setup dependency injection locator
  await setupDependencies();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => sl<AuthBloc>()..add(CheckAuthEvent()),
        ),
        BlocProvider<CircleBloc>(
          create: (context) => sl<CircleBloc>(),
        ),
        BlocProvider<FeedBloc>(
          create: (context) => sl<FeedBloc>(),
        ),
        BlocProvider<UploadBloc>(
          create: (context) => sl<UploadBloc>(),
        ),
        BlocProvider<RealtimeBloc>(
          create: (context) => sl<RealtimeBloc>(),
        ),
      ],
      child: const CircleStreamApp(),
    ),
  );
}
