library circlestream.features.camera.screens.photo_preview_screen;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_radius.dart';
import '../../../design/app_spacing.dart';
import '../../../shared/widgets/app_button.dart';
import '../bloc/upload_bloc.dart';
import '../bloc/upload_event.dart';
import '../bloc/upload_state.dart';

class PhotoPreviewScreen extends StatelessWidget {
  final File imageFile;
  final int circleId;
  final String circleName;

  const PhotoPreviewScreen({
    super.key,
    required this.imageFile,
    required this.circleId,
    required this.circleName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UploadBloc, UploadState>(
      listener: (context, state) {
        if (state is UploadSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto berhasil diposting!'),
              backgroundColor: AppColors.success,
            ),
          );
          // Clean up state back to idle
          context.read<UploadBloc>().add(const ResetUploadEvent());
          // Redirect to feed
          context.go('/feed');
        } else if (state is UploadError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload gagal: ${state.error}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final bool isUploading = state is UploadCompressing ||
            state is UploadPresigning ||
            state is UploadingToB2 ||
            state is UploadFinalizing;

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Photo view
              Image.file(
                imageFile,
                fit: BoxFit.cover,
              ),

              // Close / Back button (only if not uploading)
              if (!isUploading)
                Positioned(
                  top: MediaQuery.of(context).padding.top + AppSpacing.sm,
                  left: AppSpacing.md,
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withOpacity(0.5),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => context.pop(),
                    ),
                  ),
                ),

              // Bottom Sheet Overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                    top: AppSpacing.lg,
                    bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.85),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Loading Status Widget
                      if (isUploading) ...[
                        _buildUploadProgress(state),
                        const SizedBox(height: AppSpacing.lg),
                      ],

                      // Upload Action Button & Retake Action Button
                      if (!isUploading) ...[
                        if (state is UploadError) ...[
                          AppButton(
                            label: 'Coba Lagi',
                            onTap: () {
                              context.read<UploadBloc>().add(const RetryUploadEvent());
                            },
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ] else ...[
                          AppButton(
                            label: 'Post ke $circleName',
                            onTap: () {
                              context.read<UploadBloc>().add(
                                    StartUploadEvent(
                                      imageFile: imageFile,
                                      circleId: circleId,
                                    ),
                                  );
                            },
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                        AppButton(
                          label: 'Ambil Ulang',
                          isPrimary: false,
                          onTap: () => context.pop(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUploadProgress(UploadState state) {
    String statusText = '';
    double? progress;

    if (state is UploadCompressing) {
      statusText = 'Memproses foto...';
    } else if (state is UploadPresigning) {
      statusText = 'Menyiapkan upload...';
    } else if (state is UploadingToB2) {
      statusText = 'Mengupload foto (${(state.progress * 100).toInt()}%)...';
      progress = state.progress;
    } else if (state is UploadFinalizing) {
      statusText = 'Menyimpan...';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  statusText,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withOpacity(0.2),
                color: AppColors.primary,
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
