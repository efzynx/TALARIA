import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/network/connection_status.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../state/connection_provider.dart';

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
      case ConnectionStatus.disconnected:
        statusColor = AppColors.error;
        statusText = 'OFFLINE';
        break;
    }

    return InkWell(
      onTap: () => _showConnectionDialog(context, ref, conn),
      borderRadius: const BorderRadius.all(Radius.circular(9999)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.all(Radius.circular(9999)),
          border: Border.all(
            color: status == ConnectionStatus.connected
                ? AppColors.border
                : statusColor.withAlpha(120),
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
                color: AppColors.textPrimary,
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
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                ref.read(connectionProvider.notifier).reconnect();
              },
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
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
