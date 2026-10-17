import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/network/hermes_auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/haptics.dart';
import '../../data/models/hermes_account.dart';
import '../../state/account_provider.dart';

class OnboardingWelcomeDialog extends ConsumerStatefulWidget {
  const OnboardingWelcomeDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const OnboardingWelcomeDialog(),
    );
  }

  @override
  ConsumerState<OnboardingWelcomeDialog> createState() => _OnboardingWelcomeDialogState();
}

class _OnboardingWelcomeDialogState extends ConsumerState<OnboardingWelcomeDialog> {
  final TextEditingController _nameController =
      TextEditingController(text: 'Primary Hermes');
  final TextEditingController _urlController =
      TextEditingController(text: 'ws://127.0.0.1:9119');
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleConnect() async {
    final name = _nameController.text.trim();
    final url = _urlController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (url.isEmpty) {
      setState(() => _errorMessage = 'Server URL is required.');
      AppHaptics.warning();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? token;
      String? refreshToken;

      // If credentials provided, attempt authentication
      if (username.isNotEmpty && password.isNotEmpty) {
        final authResult = await HermesAuthService.login(
          serverUrl: url,
          username: username,
          password: password,
        );

        if (!authResult.success) {
          setState(() {
            _isLoading = false;
            _errorMessage = authResult.errorMessage ?? 'Authentication failed.';
          });
          AppHaptics.warning();
          return;
        }

        token = authResult.token;
        refreshToken = authResult.refreshToken;
      }

      final newAcc = HermesAccount(
        id: 'acc_${DateTime.now().millisecondsSinceEpoch}',
        name: name.isNotEmpty ? name : 'Hermes Server',
        serverUrl: url,
        username: username.isNotEmpty ? username : null,
        password: password.isNotEmpty ? password : null,
        token: token,
        refreshToken: refreshToken,
        isActive: true,
        createdAt: DateTime.now(),
        lastUsedAt: DateTime.now(),
      );

      await ref.read(accountProvider.notifier).addAccount(newAcc, activate: true);

      AppHaptics.success();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Connection error: $e';
      });
      AppHaptics.warning();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: const RoundedRectangleBorder(
        borderRadius: AppSpacing.roundedMd,
        side: BorderSide(color: AppColors.border),
      ),
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo & Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      borderRadius: AppSpacing.roundedSm,
                      border: Border.all(color: AppColors.primary.withAlpha(120)),
                    ),
                    child: const Icon(LucideIcons.zap, size: 22, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome to Talaria', style: AppTypography.textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          'Remote Client for Hermes Agent',
                          style: AppTypography.mono(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: AppSpacing.roundedSm,
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'No active Hermes daemon was found. Connect your first server profile to begin managing sessions, tools, and autonomous tasks.',
                  style: AppTypography.textTheme.bodySmall?.copyWith(fontSize: 11, color: AppColors.textSecondary),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withAlpha(25),
                    borderRadius: AppSpacing.roundedSm,
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.alertCircle, size: 16, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.error, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Server Endpoint
              Text('SERVER WEBSOCKET URL', style: AppTypography.mono(fontSize: 10, color: AppColors.textMuted)),
              const SizedBox(height: 4),
              TextField(
                controller: _urlController,
                style: AppTypography.mono(fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'ws://127.0.0.1:9119 or ws://0.0.0.0:9119',
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),

              const SizedBox(height: 6),
              // Preset chips
              Row(
                children: [
                  _presetChip('127.0.0.1:9119', () {
                    _urlController.text = 'ws://127.0.0.1:9119';
                  }),
                  const SizedBox(width: 6),
                  _presetChip('0.0.0.0:9119', () {
                    _urlController.text = 'ws://0.0.0.0:9119';
                  }),
                ],
              ),

              const SizedBox(height: 14),

              // Account / Profile Label
              Text('PROFILE / SERVER NAME', style: AppTypography.mono(fontSize: 10, color: AppColors.textMuted)),
              const SizedBox(height: 4),
              TextField(
                controller: _nameController,
                style: AppTypography.mono(fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'e.g. Local Daemon or Home Server',
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),

              const SizedBox(height: 14),

              // Credentials Note
              Row(
                children: [
                  const Icon(LucideIcons.lock, size: 12, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'AUTHENTICATION (OPTIONAL FOR NON-LOOPBACK)',
                    style: AppTypography.mono(fontSize: 10, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _usernameController,
                style: AppTypography.mono(fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Username (e.g. efzyn)',
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: AppTypography.mono(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Password',
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye, size: 14),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: Text('Skip for now', style: AppTypography.mono(fontSize: 12, color: AppColors.textMuted)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleConnect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.background,
                      shape: const RoundedRectangleBorder(borderRadius: AppSpacing.roundedSm),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(AppColors.background)),
                          )
                        : const Icon(LucideIcons.plug, size: 14),
                    label: Text(
                      _isLoading ? 'Connecting...' : 'Connect Server',
                      style: AppTypography.mono(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _presetChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.roundedSm,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: AppSpacing.roundedSm,
          border: Border.all(color: AppColors.border),
        ),
        child: Text(label, style: AppTypography.mono(fontSize: 10, color: AppColors.textSecondary)),
      ),
    );
  }
}
