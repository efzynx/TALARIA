import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/network/connection_status.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/haptics.dart';
import '../../state/account_provider.dart';
import '../../state/connection_provider.dart';
import 'account_switcher_dialog.dart';
import 'login_dialog.dart';

class ConnectionPill extends ConsumerWidget {
  const ConnectionPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conn = ref.watch(connectionProvider);
    final status = conn.status;
    final latency = conn.latencyMs;

    Color statusColor;
    String statusText;

    switch (status) {
      case ConnectionStatus.connected:
        statusColor = AppColors.ok;
        statusText = latency != null ? 'ONLINE (${latency}ms)' : 'ONLINE';
        break;
      case ConnectionStatus.connecting:
        statusColor = AppColors.primary;
        statusText = 'CONNECTING';
        break;
      case ConnectionStatus.reconnecting:
        statusColor = AppColors.warn;
        statusText = 'RECONNECTING';
        break;
      case ConnectionStatus.unauthorized:
        statusColor = AppColors.warn;
        statusText = 'AUTH REQUIRED';
        break;
      case ConnectionStatus.disconnected:
        statusColor = AppColors.error;
        statusText = 'OFFLINE';
        break;
    }

    return InkWell(
      onTap: () {
        AppHaptics.light();
        if (status == ConnectionStatus.unauthorized) {
          LoginDialog.show(context, initialServerUrl: conn.serverUrl);
        } else {
          _showConnectionDialog(context, ref, conn);
        }
      },
      borderRadius: const BorderRadius.all(Radius.circular(9999)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.all(Radius.circular(9999)),
          border: Border.all(
            color: status == ConnectionStatus.connected
                ? AppColors.border
                : statusColor.withAlpha(140),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withAlpha(140),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              statusText,
              style: AppTypography.mono(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: status == ConnectionStatus.unauthorized ? AppColors.warn : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConnectionDialog(
    BuildContext context,
    WidgetRef ref,
    ConnectionStateData conn,
  ) {
    final activeAccount = ref.read(accountProvider).activeAccount;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: AppSpacing.roundedMd,
            side: BorderSide(color: AppColors.border),
          ),
          title: Row(
            children: [
              const Icon(LucideIcons.radio, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Daemon Connection',
                style: AppTypography.textTheme.titleMedium,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (activeAccount != null) ...[
                _buildInfoRow('Active Account', activeAccount.name),
                const SizedBox(height: 8),
              ],
              _buildInfoRow('Endpoint', conn.serverUrl),
              if (conn.resolvedUrl != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow('WebSocket Route', conn.resolvedUrl!),
              ],
              const SizedBox(height: 8),
              _buildInfoRow('Status', conn.status.label),
              if (conn.latencyMs != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow('Latency', '${conn.latencyMs} ms'),
              ],
              if (conn.status == ConnectionStatus.unauthorized) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warn.withAlpha(25),
                    borderRadius: AppSpacing.roundedSm,
                    border: Border.all(color: AppColors.warn),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.lock, size: 16, color: AppColors.warn),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Authentication required for this server endpoint.',
                          style: AppTypography.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: AppColors.warn,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                AccountSwitcherDialog.show(context);
              },
              child: Text(
                'Switch Account',
                style: AppTypography.mono(fontSize: 12, color: AppColors.primary),
              ),
            ),
            if (conn.status == ConnectionStatus.unauthorized)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  LoginDialog.show(context, initialServerUrl: conn.serverUrl);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                ),
                icon: const Icon(LucideIcons.keyRound, size: 16),
                label: const Text('Sign In'),
              )
            else
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  ref.read(connectionProvider.notifier).reconnect();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceHover,
                  foregroundColor: AppColors.textPrimary,
                ),
                icon: const Icon(LucideIcons.refreshCw, size: 16),
                label: const Text('Reconnect'),
              ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.textTheme.labelSmall?.copyWith(
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.mono(
            fontSize: 12,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
