library circlestream.features.auth.screens.register_screen;

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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _usernameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    setState(() {
      _usernameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
    });

    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    bool isValid = true;

    if (username.isEmpty) {
      setState(() => _usernameError = 'Username tidak boleh kosong');
      isValid = false;
    } else if (username.length < 3) {
      setState(() => _usernameError = 'Username minimal 3 karakter');
      isValid = false;
    }

    if (email.isEmpty) {
      setState(() => _emailError = 'Email tidak boleh kosong');
      isValid = false;
    }

    if (password.isEmpty) {
      setState(() => _passwordError = 'Password tidak boleh kosong');
      isValid = false;
    } else if (password.length < 8) {
      setState(() => _passwordError = 'Password minimal harus 8 karakter');
      isValid = false;
    }

    if (confirmPassword.isEmpty) {
      setState(() => _confirmPasswordError = 'Konfirmasi password tidak boleh kosong');
      isValid = false;
    } else if (password != confirmPassword) {
      setState(() => _confirmPasswordError = 'Konfirmasi password tidak cocok');
      isValid = false;
    }

    if (isValid) {
      context.read<AuthBloc>().add(RegisterEvent(
            username: username,
            email: email,
            password: password,
          ));
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
                  'Buat akun baru',
                  style: GoogleFonts.poppins(
                    textStyle: AppTextStyles.h2,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                AppTextField(
                  label: 'Username',
                  hint: 'Masukkan username kamu',
                  controller: _usernameController,
                  errorText: _usernameError,
                ),
                const SizedBox(height: AppSpacing.lg),
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
                  hint: 'Masukkan password (min 8 karakter)',
                  controller: _passwordController,
                  obscureText: true,
                  errorText: _passwordError,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Konfirmasi Password',
                  hint: 'Ketik ulang password kamu',
                  controller: _confirmPasswordController,
                  obscureText: true,
                  errorText: _confirmPasswordError,
                ),
                const SizedBox(height: AppSpacing.xxl),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final isLoading = state is AuthLoading;
                    return AppButton(
                      label: 'Daftar',
                      isLoading: isLoading,
                      onTap: _onSubmit,
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/auth/login'),
                    child: Text(
                      'Sudah punya akun? Masuk',
                      style: GoogleFonts.dmSans(
                        textStyle: AppTextStyles.bodyMedium,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
