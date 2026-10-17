import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/haptics.dart';
import '../../state/account_provider.dart';

class LoginDialog extends ConsumerStatefulWidget {
  final String? initialServerUrl;
  final String? initialUsername;

  const LoginDialog({
    super.key,
    this.initialServerUrl,
    this.initialUsername,
  });

  /// Static helper to display as Dialog on desktop or BottomSheet on mobile
  static Future<bool?> show(
    BuildContext context, {
    String? initialServerUrl,
    String? initialUsername,
  }) {
    AppHaptics.light();
    final isDesktop = MediaQuery.of(context).size.width >= 720;

    if (isDesktop) {
      return showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => LoginDialog(
          initialServerUrl: initialServerUrl,
          initialUsername: initialUsername,
        ),
      );
    } else {
      return showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
        ),
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: LoginDialog(
            initialServerUrl: initialServerUrl,
            initialUsername: initialUsername,
          ),
        ),
      );
    }
  }

  @override
  ConsumerState<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends ConsumerState<LoginDialog> {
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  bool _obscurePassword = true;
  bool _rememberPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final activeAccount = ref.read(accountProvider).activeAccount;
    _usernameController = TextEditingController(
      text: widget.initialUsername ?? activeAccount?.username ?? '',
    );
    _passwordController = TextEditingController(
      text: activeAccount?.password ?? '',
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty) {
      setState(() => _errorMessage = 'Username cannot be empty.');
      AppHaptics.warning();
      return;
    }
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Password cannot be empty.');
      AppHaptics.warning();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ref.read(accountProvider.notifier).loginActiveAccount(
            username: username,
            password: password,
            rememberPassword: _rememberPassword,
          );

      if (!mounted) return;

      if (res.success) {
        AppHaptics.success();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully authenticated as $username',
              style: AppTypography.textTheme.bodySmall,
            ),
            backgroundColor: AppColors.ok,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        AppHaptics.warning();
        setState(() {
          _isLoading = false;
          _errorMessage = res.errorMessage ?? 'Authentication failed.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      AppHaptics.warning();
      setState(() {
        _isLoading = false;
        _errorMessage = 'Login error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 720;
    final activeAccount = ref.watch(accountProvider).activeAccount;
    final serverUrl = widget.initialServerUrl ?? activeAccount?.serverUrl ?? '127.0.0.1:9119';

    final content = Container(
      constraints: BoxConstraints(
        maxWidth: isDesktop ? 440 : double.infinity,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: isDesktop ? AppSpacing.roundedMd : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isDesktop)
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: const BoxDecoration(
                  color: AppColors.border,
                  borderRadius: AppSpacing.roundedFull,
                ),
              ),
            ),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(30),
                  borderRadius: AppSpacing.roundedSm,
                  border: Border.all(color: AppColors.primary.withAlpha(120)),
                ),
                child: const Icon(LucideIcons.lock, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hermes Sign In',
                      style: AppTypography.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Target: $serverUrl',
                      style: AppTypography.mono(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isDesktop)
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 18),
                  color: AppColors.textMuted,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Description info banner
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: AppSpacing.roundedSm,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(LucideIcons.shieldCheck, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Dashboard authentication configured under dashboard.basic_auth. Enter your Hermes server credentials to establish a secure session.',
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(30),
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
                      style: AppTypography.textTheme.bodySmall?.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Username Field
          Text(
            'USERNAME',
            style: AppTypography.mono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _usernameController,
            style: AppTypography.mono(fontSize: 13),
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              prefixIcon: const Icon(LucideIcons.user, size: 16, color: AppColors.textMuted),
              hintText: 'e.g. efzyn',
              hintStyle: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),

          const SizedBox(height: 14),

          // Password Field
          Text(
            'PASSWORD',
            style: AppTypography.mono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: AppTypography.mono(fontSize: 13),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleLogin(),
            decoration: InputDecoration(
              prefixIcon: const Icon(LucideIcons.keyRound, size: 16, color: AppColors.textMuted),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                  size: 16,
                  color: AppColors.textMuted,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              hintText: '••••••••••••',
              hintStyle: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),

          const SizedBox(height: 10),

          // Remember Credentials Switch
          Row(
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: _rememberPassword,
                  activeColor: AppColors.primary,
                  checkColor: AppColors.background,
                  onChanged: (val) => setState(() => _rememberPassword = val ?? true),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => setState(() => _rememberPassword = !_rememberPassword),
                child: Text(
                  'Save credentials for this account profile',
                  style: AppTypography.textTheme.bodySmall?.copyWith(fontSize: 12),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: AppTypography.mono(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: const RoundedRectangleBorder(borderRadius: AppSpacing.roundedSm),
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.background),
                        ),
                      )
                    : const Icon(LucideIcons.logIn, size: 16),
                label: Text(
                  _isLoading ? 'Signing In...' : 'Sign In',
                  style: AppTypography.mono(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (isDesktop) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: content,
      );
    }

    return content;
  }
}
