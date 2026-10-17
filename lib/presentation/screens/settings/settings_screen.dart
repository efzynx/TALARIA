import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/network/connection_status.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../state/chat_provider.dart';
import '../../../state/connection_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    final currentUrl = ref.read(connectionProvider).serverUrl;
    _urlController = TextEditingController(text: currentUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _saveUrl() {
    final url = _urlController.text.trim();
    if (url.isNotEmpty) {
      ref.read(connectionProvider.notifier).updateServerUrl(url);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updated server endpoint to $url', style: AppTypography.textTheme.bodySmall),
          backgroundColor: AppColors.surface,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final conn = ref.watch(connectionProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'DAEMON SETTINGS',
              style: AppTypography.mono(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),

            // Server URL Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.radio, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'WebSocket Endpoint',
                          style: AppTypography.textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Address of the running hermes serve daemon (local or remote tunnel).',
                      style: AppTypography.textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _urlController,
                      style: AppTypography.mono(fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'ws://127.0.0.1:9119',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _saveUrl,
                            icon: const Icon(LucideIcons.refreshCw, size: 16),
                            label: const Text('Save & Reconnect'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Connection Health Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.activity, size: 18, color: AppColors.thinking),
                        const SizedBox(width: 8),
                        Text(
                          'Connection Diagnostics',
                          style: AppTypography.textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildDiagnosticRow('Status', conn.status.label),
                    const Divider(color: AppColors.border, height: 16),
                    _buildDiagnosticRow(
                      'Ping Latency',
                      conn.latencyMs != null ? '${conn.latencyMs} ms' : 'N/A',
                    ),
                    const Divider(color: AppColors.border, height: 16),
                    _buildDiagnosticRow('Heartbeat', 'gateway.ping (30s)'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Session Buffer Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.trash2, size: 18, color: AppColors.error),
                        const SizedBox(width: 8),
                        Text(
                          'Local Buffer',
                          style: AppTypography.textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Clear local message cache and reset view state.',
                      style: AppTypography.textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        ref.read(chatProvider.notifier).clearMessages();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Message buffer cleared', style: AppTypography.textTheme.bodySmall),
                            backgroundColor: AppColors.surface,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.error),
                      label: const Text('Clear Messages', style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // About Talaria Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TALARIA v1.0.0',
                      style: AppTypography.mono(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Wings for your Hermes Agent — Mobile-first & Desktop Client.',
                      style: AppTypography.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Target: Android • Linux • Windows',
                      style: AppTypography.mono(
                        fontSize: 11,
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
    );
  }

  Widget _buildDiagnosticRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTypography.mono(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
