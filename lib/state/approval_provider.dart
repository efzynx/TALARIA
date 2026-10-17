import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/json_rpc_message.dart';
import '../core/utils/haptics.dart';
import '../data/models/approval_request.dart';
import 'connection_provider.dart';

class ApprovalState {
  final List<ApprovalRequest> pendingApprovals;
  final bool isLoading;
  final String? lastError;

  const ApprovalState({
    this.pendingApprovals = const [],
    this.isLoading = false,
    this.lastError,
  });

  bool get hasPending => pendingApprovals.isNotEmpty;
  int get count => pendingApprovals.length;

  ApprovalState copyWith({
    List<ApprovalRequest>? pendingApprovals,
    bool? isLoading,
    String? lastError,
  }) {
    return ApprovalState(
      pendingApprovals: pendingApprovals ?? this.pendingApprovals,
      isLoading: isLoading ?? this.isLoading,
      lastError: lastError,
    );
  }
}

class ApprovalNotifier extends StateNotifier<ApprovalState> {
  final Ref _ref;
  StreamSubscription? _notificationSub;

  ApprovalNotifier(this._ref) : super(const ApprovalState()) {
    _listenToApprovals();
  }

  void _listenToApprovals() {
    final client = _ref.read(connectionProvider.notifier).client;
    _notificationSub = client.notificationStream.listen(_onNotificationReceived);
  }

  void _onNotificationReceived(JsonRpcNotification notification) {
    if (notification.method == 'approval.pending') {
      final params = notification.params;
      if (params is Map<String, dynamic>) {
        final request = ApprovalRequest.fromJson(params);
        _addApproval(request);
      }
    } else if (notification.method == 'approval.settled' ||
        notification.method == 'approval.resolved' ||
        notification.method == 'approval.cancelled') {
      final approvalId = notification.params?['approval_id'] as String? ??
          notification.params?['id'] as String?;
      if (approvalId != null) {
        _removeApproval(approvalId);
      }
    }
  }

  void _addApproval(ApprovalRequest request) {
    // Hindari duplikasi
    if (state.pendingApprovals.any((a) => a.id == request.id)) return;

    AppHaptics.warning();
    state = state.copyWith(
      pendingApprovals: [...state.pendingApprovals, request],
    );
  }

  void _removeApproval(String approvalId) {
    state = state.copyWith(
      pendingApprovals: state.pendingApprovals.where((a) => a.id != approvalId).toList(),
    );
  }

  Future<void> respond(String approvalId, String decision) async {
    // decision: 'once', 'session', 'deny'
    try {
      AppHaptics.light();
      final client = _ref.read(connectionProvider.notifier).client;
      await client.call('approval.respond', {
        'approval_id': approvalId,
        'decision': decision,
      });

      _removeApproval(approvalId);
      AppHaptics.success();
    } catch (e) {
      state = state.copyWith(lastError: e.toString());
      // Tetap bersihkan jika error karena id sudah stale
      _removeApproval(approvalId);
    }
  }

  @override
  void dispose() {
    _notificationSub?.cancel();
    super.dispose();
  }
}

final approvalProvider = StateNotifierProvider<ApprovalNotifier, ApprovalState>((ref) {
  return ApprovalNotifier(ref);
});
