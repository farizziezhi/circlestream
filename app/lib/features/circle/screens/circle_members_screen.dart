library circlestream.features.circle.screens.circle_members_screen;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_radius.dart';
import '../../../design/app_spacing.dart';
import '../../../design/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../bloc/circle_bloc.dart';
import '../bloc/circle_event.dart';
import '../bloc/circle_state.dart';

class CircleMembersScreen extends StatefulWidget {
  final String circleId;

  const CircleMembersScreen({super.key, required this.circleId});

  @override
  State<CircleMembersScreen> createState() => _CircleMembersScreenState();
}

class _CircleMembersScreenState extends State<CircleMembersScreen> {
  late final int _parsedCircleId;

  @override
  void initState() {
    super.initState();
    _parsedCircleId = int.parse(widget.circleId);
    _loadMembers();
  }

  void _loadMembers() {
    context.read<CircleBloc>().add(LoadMembersEvent(circleId: _parsedCircleId));
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return '';
    final local = dateTime.toLocal();
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return 'Bergabung ${local.day} ${months[local.month - 1]} ${local.year}';
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
        title: BlocBuilder<CircleBloc, CircleState>(
          buildWhen: (prev, curr) => curr is CircleMembersLoaded,
          builder: (context, state) {
            final countText = (state is CircleMembersLoaded)
                ? ' (${state.members.length}/10)'
                : '';
            return Text(
              'Anggota$countText',
              style: GoogleFonts.poppins(textStyle: AppTextStyles.h2),
            );
          },
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<CircleBloc, CircleState>(
        builder: (context, state) {
          if (state is CircleLoading && state is! CircleMembersLoaded) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state is CircleError && state is! CircleMembersLoaded) {
            return Center(
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
                      onTap: _loadMembers,
                    ),
                  ],
                ),
              ),
            );
          }

          final members = (state is CircleMembersLoaded) ? state.members : null;

          if (members == null || members.isEmpty) {
            return Center(
              child: Text(
                'Tidak ada anggota ditemukan',
                style: GoogleFonts.dmSans(textStyle: AppTextStyles.bodyLarge),
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              _loadMembers();
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: members.length,
              separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final member = members[index];
                final isOwner = member.role.toLowerCase() == 'owner';

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
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
                  child: Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: isOwner
                            ? AppColors.primaryLight.withOpacity(0.3)
                            : AppColors.surfaceAlt,
                        child: Text(
                          member.username.isNotEmpty
                              ? member.username.substring(0, 1).toUpperCase()
                              : '',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isOwner ? AppColors.primaryDark : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      // Name and Join Date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member.username,
                              style: GoogleFonts.poppins(
                                textStyle: AppTextStyles.bodyLarge,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatDate(member.joinedAt),
                              style: GoogleFonts.dmSans(
                                textStyle: AppTextStyles.caption,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Role Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isOwner
                              ? AppColors.primary.withOpacity(0.15)
                              : AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          isOwner ? 'Owner' : 'Anggota',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isOwner ? AppColors.primaryDark : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
