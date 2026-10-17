import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/connection_status.dart';
import '../data/models/session.dart';
import 'connection_provider.dart';

class SessionState {
  final List<HermesSession> sessions;
  final String? activeSessionId;
  final bool isLoading;
  final String? error;

  const SessionState({
    this.sessions = const [],
    this.activeSessionId,
    this.isLoading = false,
    this.error,
  });

  SessionState copyWith({
    List<HermesSession>? sessions,
    String? activeSessionId,
    bool? isLoading,
    String? error,
  }) {
    return SessionState(
      sessions: sessions ?? this.sessions,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SessionNotifier extends StateNotifier<SessionState> {
  final Ref _ref;

  SessionNotifier(this._ref) : super(const SessionState()) {
    // Initial fetch jika koneksi sudah aktif
    _init();
  }

  void _init() {
    _ref.listen(connectionProvider, (prev, next) {
      if (next.status.isConnected && (prev == null || !prev.status.isConnected)) {
        fetchSessions();
      }
    });
  }

  Future<void> fetchSessions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = _ref.read(hermesRepositoryProvider);
      final list = await repo.listSessions();
      state = state.copyWith(sessions: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<HermesSession?> createSession({String? title, String? project}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = _ref.read(hermesRepositoryProvider);
      final newSession = await repo.createSession(title: title, project: project);
      state = state.copyWith(
        sessions: [newSession, ...state.sessions],
        activeSessionId: newSession.id,
        isLoading: false,
      );
      return newSession;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<void> resumeSession(String sessionId) async {
    try {
      final repo = _ref.read(hermesRepositoryProvider);
      await repo.resumeSession(sessionId);
      state = state.copyWith(activeSessionId: sessionId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteSession(String sessionId) async {
    try {
      final repo = _ref.read(hermesRepositoryProvider);
      await repo.deleteSession(sessionId);
      state = state.copyWith(
        sessions: state.sessions.where((s) => s.id != sessionId).toList(),
        activeSessionId: state.activeSessionId == sessionId ? null : state.activeSessionId,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void setActiveSession(String sessionId) {
    state = state.copyWith(activeSessionId: sessionId);
  }
}

final sessionProvider = StateNotifierProvider<SessionNotifier, SessionState>((ref) {
  return SessionNotifier(ref);
});
