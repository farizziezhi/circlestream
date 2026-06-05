library circlestream.features.circle.screens.join_circle_screen;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_spacing.dart';
import '../../../design/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../bloc/circle_bloc.dart';
import '../bloc/circle_event.dart';
import '../bloc/circle_state.dart';

class JoinCircleScreen extends StatefulWidget {
  const JoinCircleScreen({super.key});

  @override
  State<JoinCircleScreen> createState() => _JoinCircleScreenState();
}

class _JoinCircleScreenState extends State<JoinCircleScreen> {
  final _codeController = TextEditingController();
  String? _codeError;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    setState(() {
      _codeError = null;
    });

    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _codeError = 'Kode undangan tidak boleh kosong';
      });
      return;
    }
    if (code.length < 8) {
      setState(() {
        _codeError = 'Kode undangan harus 8 karakter';
      });
      return;
    }

    context.read<CircleBloc>().add(
          JoinCircleEvent(
              inviteCode: code.toUpperCase()),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CircleBloc, CircleState>(
      listener: (context, state) {
        if (state is CircleJoined) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Berhasil gabung ke "${state.result.circle.name}"!'),
              backgroundColor: AppColors.success,
            ),
          );
          context.go('/feed');
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
            icon: const Icon(Icons.arrow_back_ios,
                color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Gabung Circle',
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
              Text(
                'Minta kode undangan dari teman yang sudah ada di circle',
                style: GoogleFonts.dmSans(
                  textStyle: AppTextStyles.bodySmall,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Kode Undangan',
                hint: 'Contoh: XK92PLMW',
                controller: _codeController,
                errorText: _codeError,
                onChanged: (val) {
                  if (_codeError != null) {
                    setState(() {
                      _codeError = null;
                    });
                  }
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              BlocBuilder<CircleBloc, CircleState>(
                builder: (context, state) {
                  return AppButton(
                    label: 'Gabung',
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
}
