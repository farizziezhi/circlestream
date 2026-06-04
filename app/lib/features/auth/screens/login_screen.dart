library circlestream.features.auth.screens.login_screen;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_spacing.dart';
import '../../../design/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    bool isValid = true;
    if (email.isEmpty) {
      setState(() => _emailError = 'Email tidak boleh kosong');
      isValid = false;
    }
    if (password.isEmpty) {
      setState(() => _passwordError = 'Password tidak boleh kosong');
      isValid = false;
    }

    if (isValid) {
      context.read<AuthBloc>().add(LoginEvent(email: email, password: password));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => context.go('/auth/welcome'),
        ),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.go('/feed');
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.error,
                  style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w500),
                ),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Selamat datang kembali',
                  style: GoogleFonts.poppins(
                    textStyle: AppTextStyles.h2,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                AppTextField(
                  label: 'Email',
                  hint: 'Masukkan alamat email kamu',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  errorText: _emailError,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Password',
                  hint: 'Masukkan password kamu',
                  controller: _passwordController,
                  obscureText: true,
                  errorText: _passwordError,
                ),
                const SizedBox(height: AppSpacing.xxl),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final isLoading = state is AuthLoading;
                    return AppButton(
                      label: 'Masuk',
                      isLoading: isLoading,
                      onTap: _onSubmit,
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/auth/register'),
                    child: Text(
                      'Belum punya akun? Daftar',
                      style: GoogleFonts.dmSans(
                        textStyle: AppTextStyles.bodyMedium,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
