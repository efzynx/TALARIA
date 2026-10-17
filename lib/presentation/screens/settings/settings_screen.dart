import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/network/connection_status.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics.dart';
import '../../../state/chat_provider.dart';
import '../../../state/connection_provider.dart';
import '../../../state/model_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _urlController;
  late final TextEditingController _customModelController;
  String _selectedReasoning = 'high';
  String? _selectedModel;

  static const List<String> _reasoningOptions = [
    'none',
    'low',
    'medium',
    'high',
    'ultra',
  ];

  @override
  void initState() {
    super.initState();
    final currentUrl = ref.read(connectionProvider).serverUrl;
    _urlController = TextEditingController(text: currentUrl);
    _customModelController = TextEditingController();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _customModelController.dispose();
    super.dispose();
  }

  void _saveUrl() {
    final url = _urlController.text.trim();
    if (url.isNotEmpty) {
      AppHaptics.light();
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

  Future<void> _updateModelConfig(String modelToSet) async {
    final model = modelToSet.trim();
    if (model.isEmpty) return;

    AppHaptics.light();
    try {
      await ref.read(modelConfigProvider.notifier).setModel(
            model,
            reasoningEffort: _selectedReasoning,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Model configured: $model ($_selectedReasoning)',
              style: AppTypography.textTheme.bodySmall,
            ),
            backgroundColor: AppColors.surface,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to set model: $e', style: AppTypography.textTheme.bodySmall),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final conn = ref.watch(connectionProvider);
    final modelState = ref.watch(modelConfigProvider);
    final availableModels = modelState.config.allAvailableModels;

    final currentActiveModel = modelState.config.activeModel;
    final selectedModel = _selectedModel ?? (availableModels.contains(currentActiveModel) ? currentActiveModel : (availableModels.isNotEmpty ? availableModels.first : currentActiveModel));

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

            // Real Model & Reasoning Configuration Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.cpu, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'LLM & Reasoning Engine',
                            style: AppTypography.textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.refreshCw, size: 16),
                          tooltip: 'Sync Models from Hermes',
                          onPressed: conn.status.isConnected
                              ? () {
                                  AppHaptics.light();
                                  ref.read(modelConfigProvider.notifier).fetchModelOptions();
                                }
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Live active models provided by Hermes Agent daemon.',
                      style: AppTypography.textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          'CURRENT ACTIVE: ',
                          style: AppTypography.mono(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        Text(
                          currentActiveModel,
                          style: AppTypography.mono(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    if (modelState.config.activeProvider.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'PROVIDER: ',
                            style: AppTypography.mono(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          Text(
                            modelState.config.activeProvider,
                            style: AppTypography.mono(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.thinking,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      'SELECT MODEL',
                      style: AppTypography.mono(fontSize: 10, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: availableModels.contains(selectedModel) ? selectedModel : null,
                      dropdownColor: AppColors.surface,
                      style: AppTypography.mono(fontSize: 12, color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      hint: Text(
                        availableModels.isEmpty ? 'No models loaded' : 'Choose model',
                        style: AppTypography.mono(fontSize: 12, color: AppColors.textMuted),
                      ),
                      items: availableModels.map((m) {
                        return DropdownMenuItem(
                          value: m,
                          child: Text(
                            m,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedModel = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'OR CUSTOM MODEL NAME',
                      style: AppTypography.mono(fontSize: 10, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _customModelController,
                      style: AppTypography.mono(fontSize: 12),
                      decoration: const InputDecoration(
                        hintText: 'e.g. AG-gemini, claude-3-7-sonnet',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'REASONING EFFORT',
                      style: AppTypography.mono(fontSize: 10, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    SegmentedButton<String>(
                      style: SegmentedButton.styleFrom(
                        backgroundColor: AppColors.background,
                        selectedBackgroundColor: AppColors.primary,
                        selectedForegroundColor: AppColors.background,
                      ),
                      segments: _reasoningOptions.map((opt) {
                        return ButtonSegment(
                          value: opt,
                          label: Text(opt.toUpperCase(), style: const TextStyle(fontSize: 10)),
                        );
                      }).toList(),
                      selected: {_selectedReasoning},
                      onSelectionChanged: (set) {
                        setState(() => _selectedReasoning = set.first);
                      },
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(LucideIcons.save, size: 16),
                        label: const Text('Apply Model Settings'),
                        onPressed: conn.status.isConnected
                            ? () {
                                final custom = _customModelController.text.trim();
                                final target = custom.isNotEmpty ? custom : selectedModel;
                                _updateModelConfig(target);
                              }
                            : null,
                      ),
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
                    if (conn.resolvedUrl != null) ...[
                      const Divider(color: AppColors.border, height: 16),
                      _buildDiagnosticRow('Resolved Route', conn.resolvedUrl!),
                    ],
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
                        AppHaptics.light();
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
                    const SizedBox(height: 4),
                    Text(
                      'Author: Ahmad Fauzan Adiman (Efzyn) • MIT License',
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
