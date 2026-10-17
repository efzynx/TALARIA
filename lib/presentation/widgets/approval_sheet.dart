import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/haptics.dart';
import '../../data/models/approval_request.dart';
import '../../state/approval_provider.dart';

class ApprovalSheet extends ConsumerWidget {
  final ApprovalRequest request;

  const ApprovalSheet({
    super.key,
    required this.request,
  });

  static Future<void> show(BuildContext context, ApprovalRequest request) {
    AppHaptics.warning();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ApprovalSheet(request: request),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDanger = request.riskLevel == RiskLevel.danger || request.riskLevel == RiskLevel.high;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
        border: Border(
          top: BorderSide(color: AppColors.error, width: 2),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: const BoxDecoration(
                  color: AppColors.border,
                  borderRadius: AppSpacing.roundedFull,
                ),
              ),
            ),

            // Header Banner
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isDanger ? AppColors.error : AppColors.warn).withAlpha(30),
                    borderRadius: AppSpacing.roundedSm,
                  ),
                  child: Icon(
                    LucideIcons.shieldAlert,
                    color: isDanger ? AppColors.error : AppColors.warn,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GATEKEEPER APPROVAL REQUIRED',
                        style: AppTypography.mono(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDanger ? AppColors.error : AppColors.warn,
                        ),
                      ),
                      Text(
                        'Tool: ${request.tool.toUpperCase()}',
                        style: AppTypography.textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: AppSpacing.roundedSm,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    request.riskLevel.name.toUpperCase(),
                    style: AppTypography.mono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isDanger ? AppColors.error : AppColors.warn,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Command / Action Payload Box
            Text(
              'COMMAND TO EXECUTE:',
              style: AppTypography.mono(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: AppSpacing.roundedSm,
                border: Border.all(color: AppColors.border),
              ),
              child: SelectableText(
                request.command,
                style: AppTypography.mono(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            if (request.description != null && request.description!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                request.description!,
                style: AppTypography.textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],

            const SizedBox(height: 20),

            // 3-Option Instant Action Row (min height 48px each for mobile thumb-touch)
            Row(
              children: [
                // Deny button (Red)
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error, width: 1.5),
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppSpacing.roundedSm,
                        ),
                      ),
                      onPressed: () {
                        ref.read(approvalProvider.notifier).respond(request.id, 'deny');
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Deny',
                        style: AppTypography.textTheme.labelLarge?.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Allow for Session (Surface button)
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.border, width: 1),
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppSpacing.roundedSm,
                        ),
                      ),
                      onPressed: () {
                        ref.read(approvalProvider.notifier).respond(request.id, 'session');
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Session',
                        style: AppTypography.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Allow Once (Electric Cyan button)
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.background,
                        elevation: 0,
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppSpacing.roundedSm,
                        ),
                      ),
                      onPressed: () {
                        ref.read(approvalProvider.notifier).respond(request.id, 'once');
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Allow Once',
                        style: AppTypography.textTheme.labelLarge?.copyWith(
                          color: AppColors.background,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
