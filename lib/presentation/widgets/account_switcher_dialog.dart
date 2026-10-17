import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/network/connection_status.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/haptics.dart';
import '../../data/models/hermes_account.dart';
import '../../state/account_provider.dart';
import '../../state/connection_provider.dart';
import 'login_dialog.dart';

class AccountSwitcherDialog extends ConsumerStatefulWidget {
  const AccountSwitcherDialog({super.key});

  static Future<void> show(BuildContext context) {
    AppHaptics.light();
    final isDesktop = MediaQuery.of(context).size.width >= 720;

    if (isDesktop) {
      return showDialog(
        context: context,
        builder: (ctx) => const AccountSwitcherDialog(),
      );
    } else {
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
        ),
        builder: (ctx) => const AccountSwitcherDialog(),
      );
    }
  }

  @override
  ConsumerState<AccountSwitcherDialog> createState() => _AccountSwitcherDialogState();
}

class _AccountSwitcherDialogState extends ConsumerState<AccountSwitcherDialog> {
  void _openAddAccountDialog() {
    AppHaptics.light();
    showDialog(
      context: context,
      builder: (ctx) => const _AccountFormDialog(),
    );
  }

  void _openEditAccountDialog(HermesAccount account) {
    AppHaptics.light();
    showDialog(
      context: context,
      builder: (ctx) => _AccountFormDialog(initialAccount: account),
    );
  }

  void _openLoginForAccount(HermesAccount account) {
    AppHaptics.light();
    LoginDialog.show(
      context,
      initialServerUrl: account.serverUrl,
      initialUsername: account.username,
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountState = ref.watch(accountProvider);
    final conn = ref.watch(connectionProvider);
    final accounts = accountState.accounts;
    final activeId = accountState.activeAccountId;
    final isDesktop = MediaQuery.of(context).size.width >= 720;

    final content = Container(
      constraints: BoxConstraints(
        maxWidth: isDesktop ? 480 : double.infinity,
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      padding: const EdgeInsets.all(18),
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
                margin: const EdgeInsets.only(bottom: 12),
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(30),
                  borderRadius: AppSpacing.roundedSm,
                  border: Border.all(color: AppColors.primary.withAlpha(120)),
                ),
                child: const Icon(LucideIcons.users, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hermes Accounts',
                      style: AppTypography.textTheme.titleMedium,
                    ),
                    Text(
                      'Manage and switch server endpoints and credentials',
                      style: AppTypography.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.plus, size: 18),
                color: AppColors.primary,
                tooltip: 'Add Account',
                onPressed: _openAddAccountDialog,
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 10),

          // Accounts list
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: accounts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final acc = accounts[index];
                final isActive = acc.id == activeId;
                final isAuthRequired = isActive && conn.status == ConnectionStatus.unauthorized;

                return Container(
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.surfaceHover : AppColors.background,
                    borderRadius: AppSpacing.roundedSm,
                    border: Border.all(
                      color: isActive
                          ? (isAuthRequired ? AppColors.warning : AppColors.primary)
                          : AppColors.border,
                      width: isActive ? 1.5 : 1,
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      AppHaptics.light();
                      if (!isActive) {
                        ref.read(accountProvider.notifier).switchAccount(acc.id);
                      }
                    },
                    borderRadius: AppSpacing.roundedSm,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isActive
                                      ? (isAuthRequired
                                          ? AppColors.warning
                                          : (conn.status.isConnected
                                              ? AppColors.ok
                                              : AppColors.textMuted))
                                      : AppColors.border,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  acc.name,
                                  style: AppTypography.mono(
                                    fontSize: 13,
                                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                                    color: isActive ? AppColors.primary : AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isActive)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    color: (isAuthRequired ? AppColors.warning : AppColors.primary)
                                        .withAlpha(30),
                                    borderRadius: AppSpacing.roundedSm,
                                    border: Border.all(
                                      color: isAuthRequired ? AppColors.warning : AppColors.primary,
                                    ),
                                  ),
                                  child: Text(
                                    isAuthRequired ? 'AUTH REQUIRED' : 'ACTIVE',
                                    style: AppTypography.mono(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: isAuthRequired ? AppColors.warning : AppColors.primary,
                                    ),
                                  ),
                                ),
                              PopupMenuButton<String>(
                                icon: const Icon(LucideIcons.moreVertical, size: 16, color: AppColors.textMuted),
                                padding: EdgeInsets.zero,
                                color: AppColors.surface,
                                onSelected: (action) {
                                  if (action == 'edit') {
                                    _openEditAccountDialog(acc);
                                  } else if (action == 'login') {
                                    _openLoginForAccount(acc);
                                  } else if (action == 'delete') {
                                    AppHaptics.warning();
                                    ref.read(accountProvider.notifier).deleteAccount(acc.id);
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  PopupMenuItem(
                                    value: 'login',
                                    child: Row(
                                      children: [
                                        const Icon(LucideIcons.keyRound, size: 14, color: AppColors.primary),
                                        const SizedBox(width: 8),
                                        Text('Sign In', style: AppTypography.mono(fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        const Icon(LucideIcons.edit2, size: 14, color: AppColors.textSecondary),
                                        const SizedBox(width: 8),
                                        Text('Edit', style: AppTypography.mono(fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  if (accounts.length > 1)
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          const Icon(LucideIcons.trash2, size: 14, color: AppColors.error),
                                          const SizedBox(width: 8),
                                          Text('Delete', style: AppTypography.mono(fontSize: 12, color: AppColors.error)),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Text(
                              acc.serverUrl,
                              style: AppTypography.mono(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Row(
                              children: [
                                Icon(
                                  acc.hasCredentials ? LucideIcons.userCheck : LucideIcons.userX,
                                  size: 12,
                                  color: acc.hasCredentials ? AppColors.ok : AppColors.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  acc.username != null && acc.username!.isNotEmpty
                                      ? acc.username!
                                      : 'No credentials stored',
                                  style: AppTypography.mono(
                                    fontSize: 10,
                                    color: acc.hasCredentials ? AppColors.textSecondary : AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                if (acc.hasToken)
                                  Row(
                                    children: [
                                      const Icon(LucideIcons.shieldCheck, size: 12, color: AppColors.ok),
                                      const SizedBox(width: 3),
                                      Text(
                                        'Token active',
                                        style: AppTypography.mono(fontSize: 10, color: AppColors.ok),
                                      ),
                                    ],
                                  )
                                else
                                  InkWell(
                                    onTap: () => _openLoginForAccount(acc),
                                    child: Row(
                                      children: [
                                        const Icon(LucideIcons.keyRound, size: 12, color: AppColors.primary),
                                        const SizedBox(width: 3),
                                        Text(
                                          'Sign In',
                                          style: AppTypography.mono(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Bottom Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: _openAddAccountDialog,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  shape: const RoundedRectangleBorder(borderRadius: AppSpacing.roundedSm),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                icon: const Icon(LucideIcons.plus, size: 14, color: AppColors.primary),
                label: Text(
                  'Add Server',
                  style: AppTypography.mono(fontSize: 12, color: AppColors.primary),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Done', style: AppTypography.mono(fontSize: 12, color: AppColors.textMuted)),
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

// ─────────────────────────────────────────────────────────────
// ACCOUNT FORM DIALOG (Add / Edit)
// ─────────────────────────────────────────────────────────────
class _AccountFormDialog extends ConsumerStatefulWidget {
  final HermesAccount? initialAccount;

  const _AccountFormDialog({this.initialAccount});

  @override
  ConsumerState<_AccountFormDialog> createState() => _AccountFormDialogState();
}

class _AccountFormDialogState extends ConsumerState<_AccountFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _urlController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    final acc = widget.initialAccount;
    _nameController = TextEditingController(text: acc?.name ?? 'Hermes LAN');
    _urlController = TextEditingController(text: acc?.serverUrl ?? 'ws://0.0.0.0:9119');
    _usernameController = TextEditingController(text: acc?.username ?? '');
    _passwordController = TextEditingController(text: acc?.password ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    final url = _urlController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and Server URL are required.')),
      );
      return;
    }

    AppHaptics.light();

    if (widget.initialAccount != null) {
      // Edit existing
      final updated = widget.initialAccount!.copyWith(
        name: name,
        serverUrl: url,
        username: username.isNotEmpty ? username : null,
        password: password.isNotEmpty ? password : null,
      );
      await ref.read(accountProvider.notifier).updateAccount(updated);
    } else {
      // Add new
      final newAcc = HermesAccount(
        id: 'acc_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        serverUrl: url,
        username: username.isNotEmpty ? username : null,
        password: password.isNotEmpty ? password : null,
        createdAt: DateTime.now(),
      );
      await ref.read(accountProvider.notifier).addAccount(newAcc, activate: true);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialAccount != null;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: AppSpacing.roundedMd,
        side: BorderSide(color: AppColors.border),
      ),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(isEdit ? LucideIcons.edit2 : LucideIcons.server, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  isEdit ? 'Edit Hermes Server' : 'Add Hermes Server',
                  style: AppTypography.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Name
            Text('ACCOUNT NAME', style: AppTypography.mono(fontSize: 10, color: AppColors.textMuted)),
            const SizedBox(height: 4),
            TextField(
              controller: _nameController,
              style: AppTypography.mono(fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'e.g. Server 0.0.0.0 or VPS Remote',
                filled: true,
                fillColor: AppColors.background,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
            const SizedBox(height: 12),

            // Server URL
            Text('WEBSOCKET / HTTP ENDPOINT', style: AppTypography.mono(fontSize: 10, color: AppColors.textMuted)),
            const SizedBox(height: 4),
            TextField(
              controller: _urlController,
              style: AppTypography.mono(fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'ws://0.0.0.0:9119 or http://192.168.1.50:9119',
                filled: true,
                fillColor: AppColors.background,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
            const SizedBox(height: 12),

            // Username
            Text('USERNAME (OPTIONAL)', style: AppTypography.mono(fontSize: 10, color: AppColors.textMuted)),
            const SizedBox(height: 4),
            TextField(
              controller: _usernameController,
              style: AppTypography.mono(fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'e.g. efzyn',
                filled: true,
                fillColor: AppColors.background,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
            const SizedBox(height: 12),

            // Password
            Text('PASSWORD (OPTIONAL)', style: AppTypography.mono(fontSize: 10, color: AppColors.textMuted)),
            const SizedBox(height: 4),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: AppTypography.mono(fontSize: 13),
              decoration: InputDecoration(
                hintText: '••••••••••••',
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),

            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel', style: AppTypography.mono(fontSize: 12, color: AppColors.textMuted)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    shape: const RoundedRectangleBorder(borderRadius: AppSpacing.roundedSm),
                  ),
                  child: Text(
                    isEdit ? 'Save Changes' : 'Add Server',
                    style: AppTypography.mono(fontSize: 12, fontWeight: FontWeight.w700),
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
