import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/connection_status.dart';
import '../data/models/config_item.dart';
import 'connection_provider.dart';

class ModelConfigState {
  final HermesConfig config;
  final bool isLoading;
  final String? error;

  const ModelConfigState({
    this.config = const HermesConfig(),
    this.isLoading = false,
    this.error,
  });

  ModelConfigState copyWith({
    HermesConfig? config,
    bool? isLoading,
    String? error,
  }) {
    return ModelConfigState(
      config: config ?? this.config,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ModelConfigNotifier extends StateNotifier<ModelConfigState> {
  final Ref _ref;

  ModelConfigNotifier(this._ref) : super(const ModelConfigState()) {
    _init();
  }

  void _init() {
    _ref.listen(connectionProvider, (prev, next) {
      if (next.status.isConnected && (prev == null || !prev.status.isConnected)) {
        fetchModelOptions();
      }
    });
  }

  Future<void> fetchModelOptions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = _ref.read(hermesRepositoryProvider);
      final config = await repo.getModelOptions();
      state = state.copyWith(config: config, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> setModel(String model, {String? reasoningEffort}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = _ref.read(hermesRepositoryProvider);
      await repo.setModel(model, reasoningEffort: reasoningEffort);
      final updated = state.config.copyWith(
        activeModel: model,
        reasoningEffort: reasoningEffort ?? state.config.reasoningEffort,
      );
      state = state.copyWith(config: updated, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

final modelConfigProvider =
    StateNotifierProvider<ModelConfigNotifier, ModelConfigState>((ref) {
  return ModelConfigNotifier(ref);
});
