import '../../models/qr_payload.dart';
import '../../models/transfer_progress.dart';

enum ReceiverStatus {
  idle,
  scanning,
  awaitingConfirmation,
  connecting,
  transferring,
  completed,
  error,
  cancelled,
}

class ReceiverState {
  final ReceiverStatus status;
  final QrPayload? payload;
  final TransferProgress progress;
  final String? errorMessage;

  const ReceiverState({
    this.status = ReceiverStatus.idle,
    this.payload,
    this.progress = const TransferProgress(),
    this.errorMessage,
  });

  ReceiverState copyWith({
    ReceiverStatus? status,
    QrPayload? payload,
    TransferProgress? progress,
    String? errorMessage,
  }) {
    return ReceiverState(
      status: status ?? this.status,
      payload: payload ?? this.payload,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
