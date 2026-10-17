import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/approval_request.dart';
import '../../../state/approval_provider.dart';

class ApprovalsScreen extends ConsumerWidget {
  const ApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approvalState = ref.watch(approvalProvider);
    final pending = approvalState.pendingApprovals;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SECURITY GATEKEEPER',
                    style: AppTypography.mono(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (pending.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error.withAlpha(30),
                        borderRadius: AppSpacing.roundedSm,
                        border: Border.all(color: AppColors.error.withAlpha(120), width: 0.5),
                      ),
                      child: Text(
                        '${pending.length} PENDING',
                        style: AppTypography.mono(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: pending.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: pending.length,
                        itemBuilder: (context, index) {
                          return _buildApprovalCard(context, ref, pending[index]);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppSpacing.roundedMd,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              LucideIcons.shieldCheck,
              size: 36,
              color: AppColors.ok,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Approvals Pending',
            style: AppTypography.textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Dangerous terminal or tool approvals will appear here for one-tap authorization.',
            textAlign: TextAlign.center,
            style: AppTypography.textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalCard(BuildContext context, WidgetRef ref, ApprovalRequest req) {
    final isDanger = req.riskLevel == RiskLevel.danger || req.riskLevel == RiskLevel.high;
    final timeStr = DateFormat.Hms().format(req.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(
          color: isDanger ? AppColors.error.withAlpha(150) : AppColors.warn.withAlpha(150),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                LucideIcons.shieldAlert,
                size: 16,
                color: isDanger ? AppColors.error : AppColors.warn,
              ),
              const SizedBox(width: 8),
              Text(
                req.tool.toUpperCase(),
                style: AppTypography.mono(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                timeStr,
                style: AppTypography.mono(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Command Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: AppSpacing.roundedSm,
              border: Border.all(color: AppColors.border),
            ),
            child: SelectableText(
              req.command,
              style: AppTypography.mono(
                fontSize: 11,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          if (req.description != null && req.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              req.description!,
              style: AppTypography.textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Actions
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppSpacing.roundedSm,
                      ),
                    ),
                    onPressed: () {
                      ref.read(approvalProvider.notifier).respond(req.id, 'deny');
                    },
                    child: const Text('Deny'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppSpacing.roundedSm,
                      ),
                    ),
                    onPressed: () {
                      ref.read(approvalProvider.notifier).respond(req.id, 'session');
                    },
                    child: const Text('Session'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.background,
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppSpacing.roundedSm,
                      ),
                    ),
                    onPressed: () {
                      ref.read(approvalProvider.notifier).respond(req.id, 'once');
                    },
                    child: const Text('Allow'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
