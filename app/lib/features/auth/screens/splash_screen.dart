library circlestream.features.auth.screens.splash_screen;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  StreamSubscription? _subscription;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer(const Duration(seconds: 3), () {
      _navigate(context.read<AuthBloc>().state);
    });

    final initialState = context.read<AuthBloc>().state;
    if (initialState is AuthAuthenticated || initialState is AuthUnauthenticated) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) _navigate(initialState);
      });
      return;
    }

    _subscription = context.read<AuthBloc>().stream.listen((state) {
      if (state is AuthAuthenticated || state is AuthUnauthenticated) {
        _navigate(state);
      }
    });
  }

  void _navigate(AuthState state) {
    if (_navigated) return;
    _navigated = true;
    _timer?.cancel();
    _subscription?.cancel();

    if (state is AuthAuthenticated) {
      context.go('/feed');
    } else {
      context.go('/auth/welcome');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text(
          'CircleStream',
          style: GoogleFonts.poppins(
            textStyle: AppTextStyles.displayLarge,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
