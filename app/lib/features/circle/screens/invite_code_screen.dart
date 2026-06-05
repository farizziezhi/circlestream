library circlestream.features.circle.screens.invite_code_screen;

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
import '../bloc/circle_bloc.dart';
import '../bloc/circle_event.dart';
import '../bloc/circle_state.dart';
import '../../../shared/models/invite_code_model.dart';

class InviteCodeScreen extends StatefulWidget {
  final String circleId;

  const InviteCodeScreen({super.key, required this.circleId});

  @override
  State<InviteCodeScreen> createState() => _InviteCodeScreenState();
}

class _InviteCodeScreenState extends State<InviteCodeScreen> {
  late final int _parsedCircleId;
  bool _isSingleUse = false;
  List<InviteCodeModel> _inviteCodes = [];

  @override
  void initState() {
    super.initState();
    _parsedCircleId = int.parse(widget.circleId);
    _loadInviteCodes();
  }

  void _loadInviteCodes() {
    context.read<CircleBloc>().add(LoadInviteCodesEvent(circleId: _parsedCircleId));
  }

  void _generateNewCode() {
    context.read<CircleBloc>().add(
          GenerateInviteCodeEvent(
            circleId: _parsedCircleId,
            maxUses: _isSingleUse ? 1 : null,
          ),
        );
  }

  String _formatExpiry(DateTime? expiresAt) {
    if (expiresAt == null) return 'Selamanya';
    final local = expiresAt.toLocal();
    final now = DateTime.now();
    if (local.isBefore(now)) {
      return 'Kadaluarsa';
    }
    final difference = local.difference(now);
    if (difference.inHours < 24) {
      return 'Kadaluarsa dalam ${difference.inHours} jam';
    }
    return 'Kadaluarsa dalam ${difference.inDays} hari';
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
          'Kode Undangan',
          style: GoogleFonts.poppins(textStyle: AppTextStyles.h2),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<CircleBloc, CircleState>(
        listener: (context, state) {
          if (state is CircleInviteCodeGenerated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Kode undangan baru berhasil dibuat!'),
                backgroundColor: AppColors.success,
              ),
            );
            _loadInviteCodes();
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
          if (state is CircleInviteCodesLoaded) {
            _inviteCodes = state.inviteCodes;
          }

          if (state is CircleLoading && _inviteCodes.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final activeCodes = _inviteCodes.where((c) => c.isActive).toList();
          final inactiveCodes = _inviteCodes.where((c) => !c.isActive).toList();

          final InviteCodeModel? primaryActiveCode =
              activeCodes.isNotEmpty ? activeCodes.first : null;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display primary active code card
                if (primaryActiveCode != null) ...[
                  Text(
                    'Kode Undangan Aktif',
                    style: GoogleFonts.poppins(
                      textStyle: AppTextStyles.h3,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
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
                        Text(
                          primaryActiveCode.code,
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              primaryActiveCode.isSingleUse
                                  ? Icons.person_outline_rounded
                                  : Icons.people_outline_rounded,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              primaryActiveCode.isSingleUse
                                  ? 'Sekali Pakai'
                                  : 'Multi-Pakai (${primaryActiveCode.usedCount}x digunakan)',
                              style: GoogleFonts.dmSans(
                                textStyle: AppTextStyles.bodySmall,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatExpiry(primaryActiveCode.expiresAt),
                          style: GoogleFonts.dmSans(
                            textStyle: AppTextStyles.caption,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                label: 'Salin',
                                isPrimary: false,
                                onTap: () {
                                  Clipboard.setData(
                                      ClipboardData(text: primaryActiveCode.code));
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
                                    'Gabung ke circle saya di CircleStream! Gunakan kode undangan ini: ${primaryActiveCode.code}',
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
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
                        const Icon(
                          Icons.qr_code_2_rounded,
                          size: 48,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Belum Ada Kode Aktif',
                          style: GoogleFonts.poppins(textStyle: AppTextStyles.h3),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Buat kode baru agar temanmu bisa bergabung',
                          style: GoogleFonts.dmSans(
                            textStyle: AppTextStyles.bodySmall,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                // Code Generator Control
                Text(
                  'Buat Kode Baru',
                  style: GoogleFonts.poppins(
                    textStyle: AppTextStyles.h3,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
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
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Sekali Pakai (Single-use)',
                          style: GoogleFonts.dmSans(
                            textStyle: AppTextStyles.bodyMedium,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          'Kode akan langsung tidak aktif setelah sekali digunakan',
                          style: GoogleFonts.dmSans(
                            textStyle: AppTextStyles.caption,
                          ),
                        ),
                        value: _isSingleUse,
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          setState(() {
                            _isSingleUse = val;
                          });
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppButton(
                        label: 'Buat Kode Baru',
                        isLoading: state is CircleLoading,
                        onTap: state is CircleLoading ? null : _generateNewCode,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                // Inactive codes history
                if (inactiveCodes.isNotEmpty) ...[
                  Text(
                    'Riwayat Kode Non-aktif',
                    style: GoogleFonts.poppins(
                      textStyle: AppTextStyles.h3,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: inactiveCodes.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final code = inactiveCodes[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.between,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  code.code,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textSecondary,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  code.isSingleUse
                                      ? 'Sekali Pakai'
                                      : 'Multi-Pakai (${code.usedCount}x digunakan)',
                                  style: GoogleFonts.dmSans(
                                    textStyle: AppTextStyles.caption,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceAlt,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Text(
                                'Non-aktif',
                                style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
