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
    final String type;
    final Map<String, dynamic> params;

    if (notification.method == 'event' && notification.params is Map) {
      final p = Map<String, dynamic>.from(notification.params as Map);
      type = p['type']?.toString() ?? '';
      params = p['payload'] is Map ? Map<String, dynamic>.from(p['payload'] as Map) : p;
    } else {
      type = notification.method;
      params = notification.params is Map ? Map<String, dynamic>.from(notification.params as Map) : {};
    }

    if (type == 'approval.pending' || type == 'approval' || type == 'request.opened') {
      final request = ApprovalRequest.fromJson(params);
      _addApproval(request);
    } else if (type == 'approval.settled' ||
        type == 'approval.resolved' ||
        type == 'approval.cancelled' ||
        type == 'request.cancel') {
      final approvalId = params['approval_id']?.toString() ??
          params['id']?.toString();
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
