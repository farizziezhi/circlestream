library circlestream.features.profile.screens.profile_screen;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_radius.dart';
import '../../../design/app_spacing.dart';
import '../../../design/app_text_styles.dart';
import '../../../features/auth/bloc/auth_bloc.dart';
import '../../../features/auth/bloc/auth_event.dart';
import '../../../features/auth/bloc/auth_state.dart';
import '../../../features/circle/bloc/circle_bloc.dart';
import '../../../features/circle/bloc/circle_event.dart';
import '../../../features/circle/bloc/circle_state.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_loading_indicator.dart';
import '../../../shared/widgets/avatar_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CircleBloc>().add(LoadCirclesEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppSpacing.lg),
              _buildUserHeader(),
              const SizedBox(height: AppSpacing.xl),
              _buildCircleSection(),
              const SizedBox(height: AppSpacing.lg),
              _buildActionButtons(),
              const SizedBox(height: AppSpacing.xxl),
              _buildAppVersion(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserHeader() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        String username = '';
        String email = '';
        if (state is AuthAuthenticated) {
          username = state.user.username;
          email = state.user.email;
        }

        return Column(
          children: [
            AvatarWidget(username: username, size: 80),
            const SizedBox(height: AppSpacing.md),
            Text(
              username,
              style: GoogleFonts.poppins(
                textStyle: AppTextStyles.h1,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              email,
              style: GoogleFonts.dmSans(
                textStyle: AppTextStyles.bodyMedium,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCircleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Circle Saya',
              style: GoogleFonts.poppins(
                textStyle: AppTextStyles.h2,
              ),
            ),
            TextButton.icon(
              onPressed: () => context.push('/circles'),
              icon: const Icon(Icons.arrow_forward_ios,
                  size: 14, color: AppColors.primary),
              label: Text(
                'Lihat Semua',
                style: GoogleFonts.dmSans(
                  textStyle: AppTextStyles.bodySmall,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        BlocBuilder<CircleBloc, CircleState>(
          builder: (context, state) {
            if (state is CircleLoading) {
              return const SizedBox(
                height: 100,
                child: AppLoadingIndicator(),
              );
            }

            if (state is CircleListLoaded) {
              if (state.circles.isEmpty) {
                return AppCard(
                  child: AppEmptyState(
                    message: 'Belum ada circle',
                    subMessage: 'Buat atau gabung circle untuk mulai berbagi foto',
                    icon: Icons.group_outlined,
                    actionLabel: 'Buat Circle',
                    onAction: () => context.push('/circles/create'),
                  ),
                );
              }

              return Column(
                children: state.circles.take(3).map((circle) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AppCard(
                      child: InkWell(
                        onTap: () =>
                            context.push('/circles/${circle.id}'),
                        borderRadius:
                            BorderRadius.circular(AppRadius.lg),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight
                                    .withValues(alpha: 0.3),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                circle.name.isNotEmpty
                                    ? circle.name[0].toUpperCase()
                                    : '?',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    circle.name,
                                    style: GoogleFonts.poppins(
                                      textStyle:
                                          AppTextStyles.labelMedium,
                                    ),
                                  ),
                                  Text(
                                    '${circle.memberCount} anggota',
                                    style: GoogleFonts.dmSans(
                                      textStyle:
                                          AppTextStyles.caption,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: AppColors.textHint,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            }

            if (state is CircleError) {
              return AppCard(
                child: Center(
                  child: Text(
                    state.error,
                    style: GoogleFonts.dmSans(
                      textStyle: AppTextStyles.bodyMedium,
                      color: AppColors.error,
                    ),
                  ),
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        AppButton(
          label: 'Buat Circle Baru',
          onTap: () => context.push('/circles/create'),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'Gabung Circle',
          isPrimary: false,
          onTap: () => context.push('/circles/join'),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: 'Keluar',
          isPrimary: false,
          onTap: () => _showLogoutConfirmation(),
        ),
      ],
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          'Keluar',
          style: GoogleFonts.poppins(textStyle: AppTextStyles.h2),
        ),
        content: Text(
          'Yakin ingin keluar dari CircleStream?',
          style: GoogleFonts.dmSans(textStyle: AppTextStyles.bodyMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Batal',
              style: GoogleFonts.dmSans(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<AuthBloc>().add(LogoutEvent());
            },
            child: Text(
              'Keluar',
              style: GoogleFonts.dmSans(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppVersion() {
    return Text(
      'CircleStream v1.0.0',
      style: GoogleFonts.dmSans(
        textStyle: AppTextStyles.caption,
        color: AppColors.textHint,
      ),
    );
  }
}
