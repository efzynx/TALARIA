import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/network/hermes_auth_service.dart';
import '../data/models/hermes_account.dart';
import 'connection_provider.dart';

class AccountState {
  final List<HermesAccount> accounts;
  final String? activeAccountId;
  final bool isLoading;
  final String? error;

  const AccountState({
    this.accounts = const [],
    this.activeAccountId,
    this.isLoading = false,
    this.error,
  });

  HermesAccount? get activeAccount {
    if (accounts.isEmpty) return null;
    if (activeAccountId == null) return accounts.first;
    return accounts.firstWhere(
      (a) => a.id == activeAccountId,
      orElse: () => accounts.first,
    );
  }

  AccountState copyWith({
    List<HermesAccount>? accounts,
    String? activeAccountId,
    bool? isLoading,
    String? error,
  }) {
    return AccountState(
      accounts: accounts ?? this.accounts,
      activeAccountId: activeAccountId ?? this.activeAccountId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AccountNotifier extends StateNotifier<AccountState> {
  static const String _accountsKey = 'talaria_saved_accounts';
  static const String _activeAccountKey = 'talaria_active_account_id';

  final Ref _ref;

  AccountNotifier(this._ref) : super(const AccountState()) {
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_accountsKey);
      final savedActiveId = prefs.getString(_activeAccountKey);

      List<HermesAccount> loaded = [];
      if (savedJson != null && savedJson.isNotEmpty) {
        loaded = HermesAccount.listFromJson(savedJson);
      }

      // If no accounts exist yet, seed a default local instance
      if (loaded.isEmpty) {
        final legacyServerUrl = prefs.getString('talaria_server_url') ?? 'ws://127.0.0.1:9119';
        final defaultAcc = HermesAccount(
          id: 'acc_default',
          name: 'Default Localhost',
          serverUrl: legacyServerUrl,
          isActive: true,
          createdAt: DateTime.now(),
        );
        loaded = [defaultAcc];
        await _saveAccountsToPrefs(loaded, defaultAcc.id);
      }

      String? activeId = savedActiveId;
      if (activeId == null || !loaded.any((a) => a.id == activeId)) {
        activeId = loaded.firstWhere((a) => a.isActive, orElse: () => loaded.first).id;
      }

      state = state.copyWith(
        accounts: loaded,
        activeAccountId: activeId,
      );

      final active = state.activeAccount;
      if (active != null) {
        _ref.read(connectionProvider.notifier).updateConnection(
              url: active.serverUrl,
              token: active.token,
            );
      }
    } catch (e) {
      debugPrint('[AccountNotifier] Failed to load accounts: $e');
    }
  }

  Future<void> _saveAccountsToPrefs(List<HermesAccount> accounts, String? activeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accountsKey, HermesAccount.listToJson(accounts));
    if (activeId != null) {
      await prefs.setString(_activeAccountKey, activeId);
    }
  }

  /// Switch the active Hermes connection to a different saved account.
  Future<void> switchAccount(String accountId) async {
    final index = state.accounts.indexWhere((a) => a.id == accountId);
    if (index == -1) return;

    final updated = state.accounts.map((acc) {
      final isNowActive = acc.id == accountId;
      return acc.copyWith(
        isActive: isNowActive,
        lastUsedAt: isNowActive ? DateTime.now() : acc.lastUsedAt,
      );
    }).toList();

    state = state.copyWith(
      accounts: updated,
      activeAccountId: accountId,
    );

    await _saveAccountsToPrefs(updated, accountId);

    final active = state.activeAccount;
    if (active != null) {
      debugPrint('[AccountNotifier] Switched to account "${active.name}" (${active.serverUrl})');
      _ref.read(connectionProvider.notifier).updateConnection(
            url: active.serverUrl,
            token: active.token,
          );
    }
  }

  /// Add a new account to the list and optionally switch to it immediately.
  Future<void> addAccount(HermesAccount account, {bool activate = true}) async {
    final updated = state.accounts.map((a) {
      if (activate) return a.copyWith(isActive: false);
      return a;
    }).toList();

    final newAcc = account.copyWith(
      isActive: activate,
      createdAt: DateTime.now(),
      lastUsedAt: activate ? DateTime.now() : null,
    );
    updated.add(newAcc);

    final newActiveId = activate ? newAcc.id : state.activeAccountId;
    state = state.copyWith(
      accounts: updated,
      activeAccountId: newActiveId,
    );

    await _saveAccountsToPrefs(updated, newActiveId);

    if (activate) {
      _ref.read(connectionProvider.notifier).updateConnection(
            url: newAcc.serverUrl,
            token: newAcc.token,
          );
    }
  }

  /// Update an existing account's details (URL, name, credentials, token).
  Future<void> updateAccount(HermesAccount account) async {
    final updated = state.accounts.map((a) {
      if (a.id == account.id) {
        return account;
      }
      return a;
    }).toList();

    state = state.copyWith(accounts: updated);
    await _saveAccountsToPrefs(updated, state.activeAccountId);

    if (account.id == state.activeAccountId) {
      _ref.read(connectionProvider.notifier).updateConnection(
            url: account.serverUrl,
            token: account.token,
          );
    }
  }

  /// Delete an account. If the active account is deleted, switch to the first remaining one.
  Future<void> deleteAccount(String accountId) async {
    if (state.accounts.length <= 1) {
      // Keep at least one account in storage
      return;
    }

    final updated = state.accounts.where((a) => a.id != accountId).toList();
    String? newActiveId = state.activeAccountId;

    if (accountId == state.activeAccountId) {
      final first = updated.first.copyWith(isActive: true, lastUsedAt: DateTime.now());
      updated[0] = first;
      newActiveId = first.id;
    }

    state = state.copyWith(
      accounts: updated,
      activeAccountId: newActiveId,
    );

    await _saveAccountsToPrefs(updated, newActiveId);

    final active = state.activeAccount;
    if (active != null) {
      _ref.read(connectionProvider.notifier).updateConnection(
            url: active.serverUrl,
            token: active.token,
          );
    }
  }

  /// Authenticate the active account with username & password via HermesAuthService.
  Future<AuthLoginResult> loginActiveAccount({
    required String username,
    required String password,
    bool rememberPassword = true,
  }) async {
    final active = state.activeAccount;
    if (active == null) {
      return AuthLoginResult.failure('No active account selected.');
    }

    state = state.copyWith(isLoading: true, error: null);

    final result = await HermesAuthService.login(
      serverUrl: active.serverUrl,
      username: username,
      password: password,
      provider: active.authProvider,
    );

    state = state.copyWith(isLoading: false);

    if (result.success && result.token != null) {
      final updatedAccount = active.copyWith(
        username: username,
        password: rememberPassword ? password : null,
        token: result.token,
        refreshToken: result.refreshToken,
        lastUsedAt: DateTime.now(),
      );

      await updateAccount(updatedAccount);
      return result;
    } else {
      state = state.copyWith(error: result.errorMessage);
      return result;
    }
  }

  /// Log out active account (clears tokens).
  Future<void> logoutActiveAccount() async {
    final active = state.activeAccount;
    if (active == null) return;

    final updated = active.copyWith(
      token: null,
      refreshToken: null,
      password: null,
    );

    await updateAccount(updated);
  }
}

final accountProvider = StateNotifierProvider<AccountNotifier, AccountState>((ref) {
  return AccountNotifier(ref);
});
