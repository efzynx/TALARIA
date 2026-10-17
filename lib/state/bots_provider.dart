import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/bot_profile.dart';
import 'connection_provider.dart';

class BotsState {
  final List<BotProfile> bots;
  final String activeBotName;
  final bool isLoading;
  final String? error;

  const BotsState({
    this.bots = const [],
    this.activeBotName = 'default',
    this.isLoading = false,
    this.error,
  });

  BotProfile? get activeBot {
    if (bots.isEmpty) return null;
    return bots.firstWhere(
      (b) => b.name == activeBotName,
      orElse: () => bots.first,
    );
  }

  BotsState copyWith({
    List<BotProfile>? bots,
    String? activeBotName,
    bool? isLoading,
    String? error,
  }) {
    return BotsState(
      bots: bots ?? this.bots,
      activeBotName: activeBotName ?? this.activeBotName,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class BotsNotifier extends StateNotifier<BotsState> {
  final Ref _ref;

  BotsNotifier(this._ref)
      : super(BotsState(bots: BotProfile.defaultFallbackBots())) {
    _init();
  }

  void _init() {
    _ref.listen(connectionProvider, (prev, next) {
      if (next.isConnected && (prev == null || !prev.isConnected)) {
        fetchBots();
      }
    });
    fetchBots();
  }

  Future<void> fetchBots() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = _ref.read(hermesRepositoryProvider);
      final rawList = await repo.listProfiles();

      if (rawList.isNotEmpty) {
        final parsed = rawList.map((row) => BotProfile.fromRow(row)).toList();
        state = state.copyWith(
          bots: parsed,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          bots: BotProfile.defaultFallbackBots(),
          isLoading: false,
        );
      }
    } catch (e) {
      debugPrint('[BotsNotifier] Could not fetch profiles.list, using presets: $e');
      state = state.copyWith(
        bots: BotProfile.defaultFallbackBots(),
        isLoading: false,
      );
    }
  }

  void selectBot(String name) {
    state = state.copyWith(activeBotName: name);
  }
}

final botsProvider = StateNotifierProvider<BotsNotifier, BotsState>((ref) {
  return BotsNotifier(ref);
});
