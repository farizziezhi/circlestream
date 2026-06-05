library circlestream.features.circle.screens.create_circle_screen;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_radius.dart';
import '../../../design/app_spacing.dart';
import '../../../design/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../bloc/circle_bloc.dart';
import '../bloc/circle_event.dart';
import '../bloc/circle_state.dart';

class CreateCircleScreen extends StatefulWidget {
  const CreateCircleScreen({super.key});

  @override
  State<CreateCircleScreen> createState() => _CreateCircleScreenState();
}

class _CreateCircleScreenState extends State<CreateCircleScreen> {
  final _nameController = TextEditingController();
  String? _nameError;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    setState(() {
      _nameError = null;
    });

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _nameError = 'Nama circle tidak boleh kosong';
      });
      return;
    }
    if (name.length < 2) {
      setState(() {
        _nameError = 'Nama circle minimal 2 karakter';
      });
      return;
    }

    context.read<CircleBloc>().add(
          CreateCircleEvent(name: name),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CircleBloc, CircleState>(
      listener: (context, state) {
        if (state is CircleCreated) {
          _showSuccessSheet(context, state);
        } else if (state is CircleError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon:
                const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Buat Circle Baru',
            style: GoogleFonts.poppins(textStyle: AppTextStyles.h2),
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Nama Circle',
                hint: 'Contoh: Bestie Gang',
                controller: _nameController,
                errorText: _nameError,
                onChanged: (val) {
                  if (_nameError != null) {
                    setState(() {
                      _nameError = null;
                    });
                  }
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              BlocBuilder<CircleBloc, CircleState>(
                builder: (context, state) {
                  return AppButton(
                    label: 'Buat Circle',
                    isLoading: state is CircleLoading,
                    onTap: state is CircleLoading ? null : _onSubmit,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessSheet(BuildContext context, CircleCreated state) {
    final inviteCode = state.result.inviteCode.code;
    final circleName = state.result.circle.name;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textHint,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 56,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Circle Berhasil Dibuat!',
                style: GoogleFonts.poppins(textStyle: AppTextStyles.h2),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '"$circleName" siap digunakan',
                style: GoogleFonts.dmSans(
                  textStyle: AppTextStyles.bodyMedium,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Invite code display
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      inviteCode,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Salin Kode',
                      isPrimary: false,
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: inviteCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Kode berhasil disalin!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton(
                      label: 'Bagikan',
                      isPrimary: false,
                      onTap: () {
                        SharePlus.instance.share(
                          ShareParams(
                            text:
                                'Gabung circle "$circleName" di CircleStream! Kode: $inviteCode',
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: 'Buka Feed',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.go('/feed');
                },
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );
  }
}
