import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/qr_payload.dart';
import '../../models/transfer_history_item.dart';
import '../../models/transfer_progress.dart';
import '../../services/ftp/ftp_client_service.dart';
import '../../services/qr/qr_service.dart';
import '../history/history_notifier.dart';
import 'receiver_state.dart';

class ReceiverNotifier extends Notifier<ReceiverState> {
  final QrService _qrService = QrService();
  final FtpClientService _clientService = FtpClientService();

  @override
  ReceiverState build() {
    ref.onDispose(() {
      _clientService.cancelTransfer();
    });
    return const ReceiverState();
  }

  /// Called when a QR code has been scanned from camera or manual entry
  bool onQrScanned(String rawData) {
    final payload = QrPayload.tryDecode(rawData);
    final error = _qrService.validatePayload(payload);

    if (error != null) {
      state = state.copyWith(status: ReceiverStatus.error, errorMessage: error);
      return false;
    }

    state = state.copyWith(
      status: ReceiverStatus.awaitingConfirmation,
      payload: payload,
      errorMessage: null,
    );
    return true;
  }

  /// Accept incoming transfer and start FTP client download
  Future<void> acceptTransfer() async {
    final payload = state.payload;
    if (payload == null) return;

    state = state.copyWith(
      status: ReceiverStatus.connecting,
      progress: TransferProgress(
        totalFiles: payload.files.length,
        totalBatchBytes: payload.totalBytes,
        statusMessage: 'Connecting to sender...',
      ),
    );

    final success = await _clientService.downloadBatch(
      payload: payload,
      onProgress: (progress) {
        state = state.copyWith(
          status: progress.isCancelled
              ? ReceiverStatus.cancelled
              : progress.hasError
              ? ReceiverStatus.error
              : progress.isCompleted
              ? ReceiverStatus.completed
              : ReceiverStatus.transferring,
          progress: progress,
          errorMessage: progress.errorMessage,
        );
      },
    );

    // Record into history
    final historyStatus = success
        ? TransferHistoryStatus.success
        : state.status == ReceiverStatus.cancelled
        ? TransferHistoryStatus.cancelled
        : TransferHistoryStatus.failed;

    ref
        .read(historyProvider.notifier)
        .addHistoryItem(
          TransferHistoryItem(
            id: payload.sessionId,
            timestamp: DateTime.now(),
            direction: TransferDirection.received,
            fileCount: payload.files.length,
            totalBytes: payload.totalBytes,
            status: historyStatus,
            sampleFileNames: payload.files.map((f) => f.name).toList(),
            savedPaths: _clientService.lastSavedPaths,
            failureReason: !success ? (_clientService.lastErrorMessage ?? state.errorMessage ?? 'Transfer failed') : null,
            senderIp: payload.host,
          ),
        );
  }

  /// User rejects the transfer
  void declineTransfer() {
    _clientService.cancelTransfer();
    state = const ReceiverState();
  }

  /// Cancel transfer in progress
  void cancelTransfer() {
    _clientService.cancelTransfer();
    state = state.copyWith(
      status: ReceiverStatus.cancelled,
      progress: state.progress.copyWith(
        isCancelled: true,
        statusMessage: 'Transfer cancelled by user.',
      ),
    );
  }

  /// Reset to idle
  void reset() {
    _clientService.cancelTransfer();
    state = const ReceiverState();
  }
}

final receiverProvider = NotifierProvider<ReceiverNotifier, ReceiverState>(
  ReceiverNotifier.new,
);
