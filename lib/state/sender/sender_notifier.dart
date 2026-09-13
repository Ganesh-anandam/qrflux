import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/file_item.dart';
import '../../models/transfer_history_item.dart';
import '../../services/ftp/ftp_server_service.dart';
import '../../services/network/network_service.dart';
import '../../services/qr/qr_service.dart';
import '../../services/storage/file_storage_service.dart';
import '../history/history_notifier.dart';
import 'sender_state.dart';

class SenderNotifier extends Notifier<SenderState> {
  final FileStorageService _storageService = FileStorageService();
  final NetworkService _networkService = NetworkService();
  final QrService _qrService = QrService();
  final FtpServerService _ftpServerService = FtpServerService();
  StreamSubscription<int>? _clientSub;
  StreamSubscription<void>? _transferCompleteSub;

  @override
  SenderState build() {
    ref.onDispose(() {
      _clientSub?.cancel();
      _transferCompleteSub?.cancel();
      _ftpServerService.dispose();
    });
    return const SenderState();
  }

  /// Launch file picker to select files
  Future<void> pickFiles() async {
    final hasPermission = await _storageService.requestStoragePermission();
    if (!hasPermission) {
      state = state.copyWith(
        errorMessage: 'Storage permission is required to select files.',
      );
      return;
    }

    final newFiles = await _storageService.pickFiles();
    if (newFiles.isEmpty) return;

    final existingIds = state.selectedFiles.map((f) => f.path).toSet();
    final combined = List<FileItem>.from(state.selectedFiles);
    for (final f in newFiles) {
      if (!existingIds.contains(f.path)) {
        combined.add(f);
      }
    }

    state = state.copyWith(
      selectedFiles: combined,
      status: SenderStatus.selectingFiles,
      errorMessage: null,
    );
  }

  void addFiles(List<FileItem> files) {
    final combined = List<FileItem>.from(state.selectedFiles)..addAll(files);
    state = state.copyWith(
      selectedFiles: combined,
      status: SenderStatus.selectingFiles,
    );
  }

  void removeFile(String id) {
    final filtered = state.selectedFiles.where((f) => f.id != id).toList();
    state = state.copyWith(
      selectedFiles: filtered,
      status: filtered.isEmpty
          ? SenderStatus.idle
          : SenderStatus.selectingFiles,
    );
  }

  void clearFiles() {
    state = const SenderState();
  }

  /// Start FTP server and generate QR token
  Future<bool> startServer() async {
    if (state.selectedFiles.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Please select at least one file to send.',
      );
      return false;
    }

    state = state.copyWith(
      status: SenderStatus.preparingServer,
      errorMessage: null,
    );

    // 1. Discover local IP
    var ip = await _networkService.getLocalIpAddress();
    if (ip == null || ip.isEmpty) {
      // Fallback: Check if device is in Wi-Fi hotspot mode
      ip = '192.168.43.1';
    }

    // 2. Generate payload with credentials & verification code
    final payload = _qrService.createPayload(
      host: ip,
      files: state.selectedFiles,
    );

    // 3. Start FTP Server with sandboxed files
    final started = await _ftpServerService.startServer(
      files: state.selectedFiles,
      username: payload.username,
      password: payload.password,
      port: payload.port,
      localIp: ip,
    );

    if (!started) {
      state = state.copyWith(
        status: SenderStatus.error,
        errorMessage:
            'Could not start local FTP server. Please check device network permissions.',
      );
      return false;
    }

    _clientSub?.cancel();
    _clientSub = _ftpServerService.clientCountStream.listen((count) {
      state = state.copyWith(
        connectedClients: count,
        status: count > 0
            ? SenderStatus.transferring
            : SenderStatus.waitingForReceiver,
      );
    });

    _transferCompleteSub?.cancel();
    _transferCompleteSub = _ftpServerService.transferCompleteStream.listen((_) {
      state = state.copyWith(status: SenderStatus.completed);
    });

    state = state.copyWith(
      status: SenderStatus.waitingForReceiver,
      qrPayload: payload,
    );
    return true;
  }

  /// Stop server and clean up session
  Future<void> cancelSession() async {
    _clientSub?.cancel();
    _clientSub = null;
    _transferCompleteSub?.cancel();
    _transferCompleteSub = null;
    await _ftpServerService.stopServer();

    if (state.selectedFiles.isNotEmpty &&
        state.status == SenderStatus.transferring) {
      ref
          .read(historyProvider.notifier)
          .addHistoryItem(
            TransferHistoryItem(
              id: state.qrPayload?.sessionId ?? DateTime.now().toString(),
              timestamp: DateTime.now(),
              direction: TransferDirection.sent,
              fileCount: state.fileCount,
              totalBytes: state.totalBytes,
              status: TransferHistoryStatus.cancelled,
              sampleFileNames: state.selectedFiles
                  .map((f) => f.name)
                  .take(3)
                  .toList(),
            ),
          );
    }

    state = state.copyWith(
      status: state.selectedFiles.isEmpty
          ? SenderStatus.idle
          : SenderStatus.selectingFiles,
      connectedClients: 0,
    );
  }

  /// Mark session completed and record history
  void completeSession() {
    _clientSub?.cancel();
    _clientSub = null;
    _ftpServerService.stopServer();

    ref
        .read(historyProvider.notifier)
        .addHistoryItem(
          TransferHistoryItem(
            id: state.qrPayload?.sessionId ?? DateTime.now().toString(),
            timestamp: DateTime.now(),
            direction: TransferDirection.sent,
            fileCount: state.fileCount,
            totalBytes: state.totalBytes,
            status: TransferHistoryStatus.success,
            sampleFileNames: state.selectedFiles
                .map((f) => f.name)
                .take(3)
                .toList(),
          ),
        );

    state = state.copyWith(status: SenderStatus.completed);
  }
}

final senderProvider = NotifierProvider<SenderNotifier, SenderState>(
  SenderNotifier.new,
);
