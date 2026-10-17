import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class ApprovalsScreen extends StatelessWidget {
  const ApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SECURITY GATEKEEPER',
                style: AppTypography.mono(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Center(
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
