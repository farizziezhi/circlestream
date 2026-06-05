library circlestream.features.circle.screens.circle_list_screen;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_radius.dart';
import '../../../design/app_spacing.dart';
import '../../../design/app_text_styles.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_widget.dart';
import '../../../shared/widgets/app_loading_indicator.dart';
import '../bloc/circle_bloc.dart';
import '../bloc/circle_event.dart';
import '../bloc/circle_state.dart';

class CircleListScreen extends StatefulWidget {
  const CircleListScreen({super.key});

  @override
  State<CircleListScreen> createState() => _CircleListScreenState();
}

class _CircleListScreenState extends State<CircleListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CircleBloc>().add(LoadCirclesEvent());
  }

  @override
  Widget build(BuildContext context) {
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
          'Circle Saya',
          style: GoogleFonts.poppins(textStyle: AppTextStyles.h2),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<CircleBloc, CircleState>(
        builder: (context, state) {
          if (state is CircleLoading) {
            return const AppLoadingIndicator();
          }

          if (state is CircleError) {
            return AppErrorWidget(
              message: state.error,
              onRetry: () =>
                  context.read<CircleBloc>().add(LoadCirclesEvent()),
            );
          }

          if (state is CircleListLoaded) {
            if (state.circles.isEmpty) {
              return AppEmptyState(
                message: 'Belum ada circle',
                subMessage:
                    'Buat circle baru atau gabung menggunakan kode undangan',
                icon: Icons.group_outlined,
                actionLabel: 'Buat Circle Baru',
                onAction: () => context.push('/circles/create'),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: state.circles.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final circle = state.circles[index];
                return AppCard(
                  child: InkWell(
                    onTap: () => context.push('/circles/${circle.id}'),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color:
                                AppColors.primaryLight.withValues(alpha: 0.3),
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            circle.name.isNotEmpty
                                ? circle.name[0].toUpperCase()
                                : '?',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                circle.name,
                                style: GoogleFonts.poppins(
                                  textStyle: AppTextStyles.h3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${circle.memberCount}/10 anggota',
                                style: GoogleFonts.dmSans(
                                  textStyle: AppTextStyles.bodySmall,
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
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'fab_join',
            onPressed: () => context.push('/circles/join'),
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.primary,
            icon: const Icon(Icons.link),
            label: Text(
              'Gabung',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          FloatingActionButton.extended(
            heroTag: 'fab_create',
            onPressed: () => context.push('/circles/create'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: Text(
              'Buat Circle',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
