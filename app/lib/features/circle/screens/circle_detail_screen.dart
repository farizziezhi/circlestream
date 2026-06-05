library circlestream.features.circle.screens.circle_detail_screen;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_radius.dart';
import '../../../design/app_spacing.dart';
import '../../../design/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../bloc/circle_bloc.dart';
import '../bloc/circle_event.dart';
import '../bloc/circle_state.dart';

class CircleDetailScreen extends StatefulWidget {
  final String circleId;

  const CircleDetailScreen({super.key, required this.circleId});

  @override
  State<CircleDetailScreen> createState() => _CircleDetailScreenState();
}

class _CircleDetailScreenState extends State<CircleDetailScreen> {
  late final int _parsedCircleId;

  @override
  void initState() {
    super.initState();
    _parsedCircleId = int.parse(widget.circleId);
    _loadDetail();
  }

  void _loadDetail() {
    context.read<CircleBloc>().add(LoadCircleDetailEvent(circleId: _parsedCircleId));
  }

  void _confirmLeaveCircle(BuildContext context, String circleName) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          title: Text(
            'Keluar dari Circle',
            style: GoogleFonts.poppins(textStyle: AppTextStyles.h2),
          ),
          content: Text(
            'Apakah kamu yakin ingin keluar dari circle "$circleName"?',
            style: GoogleFonts.dmSans(textStyle: AppTextStyles.bodyMedium),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Batal',
                style: GoogleFonts.dmSans(
                  textStyle: AppTextStyles.labelMedium,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<CircleBloc>().add(LeaveCircleEvent(circleId: _parsedCircleId));
              },
              child: Text(
                'Keluar',
                style: GoogleFonts.dmSans(
                  textStyle: AppTextStyles.labelMedium,
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final int? currentUserId = authState is AuthAuthenticated ? authState.user.id : null;

    return BlocConsumer<CircleBloc, CircleState>(
      listenWhen: (previous, current) =>
          current is CircleLeft || (current is CircleError && previous is CircleLoading),
      listener: (context, state) {
        if (state is CircleLeft) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Berhasil keluar dari circle'),
              backgroundColor: AppColors.success,
            ),
          );
          context.go('/profile');
        } else if (state is CircleError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is CircleLoading && state is! CircleDetailLoaded) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (state is CircleError && state is! CircleDetailLoaded) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
                onPressed: () => context.pop(),
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      state.error,
                      style: GoogleFonts.dmSans(textStyle: AppTextStyles.bodyLarge),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: 'Coba Lagi',
                      onTap: _loadDetail,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final circle = (state is CircleDetailLoaded) ? state.circle : null;

        if (circle == null) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final isOwner = circle.ownerId == currentUserId;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'Detail Circle',
              style: GoogleFonts.poppins(textStyle: AppTextStyles.h2),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowDark.withOpacity(0.4),
                        offset: const Offset(0, 4),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.primaryLight.withOpacity(0.3),
                        child: Text(
                          circle.name.isNotEmpty ? circle.name.substring(0, 1).toUpperCase() : '',
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        circle.name,
                        style: GoogleFonts.poppins(
                          textStyle: AppTextStyles.h1,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${circle.memberCount} dari 10 anggota',
                        style: GoogleFonts.dmSans(
                          textStyle: AppTextStyles.bodyMedium,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Pengaturan Circle',
                  style: GoogleFonts.poppins(
                    textStyle: AppTextStyles.h3,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowDark.withOpacity(0.2),
                        offset: const Offset(0, 2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        icon: Icons.people_outline_rounded,
                        title: 'Lihat Member',
                        onTap: () => context.push('/circles/${circle.id}/members'),
                      ),
                      if (isOwner) ...[
                        const Divider(height: 1, color: AppColors.surfaceAlt),
                        _buildMenuItem(
                          icon: Icons.qr_code_rounded,
                          title: 'Kode Undangan',
                          onTap: () => context.push('/circles/${circle.id}/invite'),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (!isOwner)
                  AppButton(
                    label: 'Keluar dari Circle',
                    isPrimary: false,
                    onTap: () => _confirmLeaveCircle(context, circle.name),
                  ),
                if (isOwner)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: Text(
                        'Kamu adalah pemilik circle ini. Pemilik circle tidak dapat keluar dari circle.',
                        style: GoogleFonts.dmSans(
                          textStyle: AppTextStyles.caption,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        title,
        style: GoogleFonts.dmSans(
          textStyle: AppTextStyles.bodyLarge,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
    );
  }
}
