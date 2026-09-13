import '../../models/file_item.dart';
import '../../models/qr_payload.dart';

enum SenderStatus {
  idle,
  selectingFiles,
  preparingServer,
  waitingForReceiver,
  transferring,
  completed,
  error,
}

class SenderState {
  final SenderStatus status;
  final List<FileItem> selectedFiles;
  final QrPayload? qrPayload;
  final int connectedClients;
  final String? errorMessage;

  const SenderState({
    this.status = SenderStatus.idle,
    this.selectedFiles = const [],
    this.qrPayload,
    this.connectedClients = 0,
    this.errorMessage,
  });

  int get totalBytes => selectedFiles.fold(0, (sum, f) => sum + f.size);
  int get fileCount => selectedFiles.length;

  SenderState copyWith({
    SenderStatus? status,
    List<FileItem>? selectedFiles,
    QrPayload? qrPayload,
    int? connectedClients,
    String? errorMessage,
  }) {
    return SenderState(
      status: status ?? this.status,
      selectedFiles: selectedFiles ?? this.selectedFiles,
      qrPayload: qrPayload ?? this.qrPayload,
      connectedClients: connectedClients ?? this.connectedClients,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
