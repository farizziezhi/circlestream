library circlestream.main;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app.dart';
import 'core/di/injection.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Setup dependency injection locator
  await setupDependencies();

  runApp(
    BlocProvider<AuthBloc>(
      create: (context) => sl<AuthBloc>()..add(CheckAuthEvent()),
      child: const CircleStreamApp(),
    ),
  );
}
