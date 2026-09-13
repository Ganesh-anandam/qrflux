import 'dart:async';
import 'dart:io';
import 'package:ftpconnect/ftpconnect.dart';
import '../../core/constants/app_constants.dart';
import '../../models/qr_payload.dart';
import '../../models/transfer_progress.dart';
import '../storage/file_storage_service.dart';

typedef ProgressCallback = void Function(TransferProgress progress);

class FtpClientService {
  final FileStorageService _storageService = FileStorageService();
  FTPConnect? _ftpConnect;
  bool _isCancelled = false;
  final List<String> _lastSavedPaths = [];
  String? _lastErrorMessage;

  List<String> get lastSavedPaths => List.unmodifiable(_lastSavedPaths);
  String? get lastErrorMessage => _lastErrorMessage;

  /// Download all files described in the QrPayload from the sender
  Future<bool> downloadBatch({
    required QrPayload payload,
    required ProgressCallback onProgress,
  }) async {
    _isCancelled = false;
    _lastSavedPaths.clear();
    _lastErrorMessage = null;
    final totalBatchBytes = payload.totalBytes;
    var totalBytesTransferred = 0;
    var currentFileIndex = 0;

    final stopwatch = Stopwatch()..start();
    var lastSampleTime = 0;
    var lastSampleBytes = 0;
    var currentSpeed = 0.0;
    var lastUiUpdateTime = 0;

    try {
      _ftpConnect = FTPConnect(
        payload.host,
        port: payload.port,
        user: payload.username,
        pass: payload.password,
        timeout: 1800, // 30 minutes to support multi-gigabyte files seamlessly
      );

      onProgress(
        TransferProgress(
          totalFiles: payload.files.length,
          totalBatchBytes: totalBatchBytes,
          statusMessage: 'Connecting to sender...',
        ),
      );

      final connected = await _ftpConnect!.connect();
      if (!connected || _isCancelled) {
        throw const SocketException('Could not connect to sender device.');
      }

      for (final fileItem in payload.files) {
        if (_isCancelled) break;
        currentFileIndex++;

        final targetFile = await _storageService.getDestinationFile(
          fileItem.name,
        );
        var fileTransferredBytes = 0;

        onProgress(
          TransferProgress(
            currentFileName: fileItem.name,
            currentFileIndex: currentFileIndex,
            totalFiles: payload.files.length,
            currentFileBytes: 0,
            currentFileTotalBytes: fileItem.size,
            totalBytesTransferred: totalBytesTransferred,
            totalBatchBytes: totalBatchBytes,
            speedBytesPerSecond: currentSpeed,
            estimatedSecondsRemaining: _calculateEta(
              totalBatchBytes - totalBytesTransferred,
              currentSpeed,
            ),
            statusMessage: 'Receiving ${fileItem.name}...',
          ),
        );

        // Download file with progress callback
        await _ftpConnect!.downloadFile(
          fileItem.name,
          targetFile,
          onProgress: (percent, transferred, total) {
            if (_isCancelled) return;
            fileTransferredBytes = transferred;
            final currentTotalTransferred = totalBytesTransferred + transferred;

            final now = stopwatch.elapsedMilliseconds;
            if (now - lastSampleTime >= 500) {
              final bytesDelta = currentTotalTransferred - lastSampleBytes;
              final timeDeltaSec = (now - lastSampleTime) / 1000.0;
              if (timeDeltaSec > 0) {
                currentSpeed = bytesDelta / timeDeltaSec;
              }
              lastSampleTime = now;
              lastSampleBytes = currentTotalTransferred;
            }

            // Throttle UI update to avoid UI lag
            if (now - lastUiUpdateTime >=
                AppConstants.progressUpdateThrottle.inMilliseconds) {
              lastUiUpdateTime = now;
              onProgress(
                TransferProgress(
                  currentFileName: fileItem.name,
                  currentFileIndex: currentFileIndex,
                  totalFiles: payload.files.length,
                  currentFileBytes: fileTransferredBytes,
                  currentFileTotalBytes: fileItem.size > 0
                      ? fileItem.size
                      : total,
                  totalBytesTransferred: currentTotalTransferred,
                  totalBatchBytes: totalBatchBytes,
                  speedBytesPerSecond: currentSpeed,
                  estimatedSecondsRemaining: _calculateEta(
                    totalBatchBytes - currentTotalTransferred,
                    currentSpeed,
                  ),
                  statusMessage: 'Receiving ${fileItem.name}...',
                ),
              );
            }
          },
        );

        _lastSavedPaths.add(targetFile.path);

        totalBytesTransferred += fileItem.size > 0
            ? fileItem.size
            : fileTransferredBytes;
      }

      await _ftpConnect?.disconnect();
      _ftpConnect = null;

      if (_isCancelled) {
        onProgress(
          TransferProgress(
            isCancelled: true,
            statusMessage: 'Transfer cancelled.',
          ),
        );
        return false;
      }

      onProgress(
        TransferProgress(
          currentFileIndex: payload.files.length,
          totalFiles: payload.files.length,
          totalBytesTransferred: totalBatchBytes,
          totalBatchBytes: totalBatchBytes,
          isCompleted: true,
          statusMessage: 'Transfer complete!',
        ),
      );
      return true;
    } catch (e) {
      await _ftpConnect?.disconnect();
      _ftpConnect = null;
      _lastErrorMessage = _friendlyErrorMessage(e);

      if (_isCancelled) {
        onProgress(
          TransferProgress(
            isCancelled: true,
            statusMessage: 'Transfer cancelled.',
          ),
        );
        return false;
      }

      onProgress(
        TransferProgress(
          hasError: true,
          errorMessage: _friendlyErrorMessage(e),
          statusMessage: 'Transfer failed.',
        ),
      );
      return false;
    }
  }

  void cancelTransfer() {
    _isCancelled = true;
    _ftpConnect?.disconnect();
    _ftpConnect = null;
  }

  double _calculateEta(int remainingBytes, double speed) {
    if (speed <= 0 || remainingBytes <= 0) return 0.0;
    return remainingBytes / speed;
  }

  String _friendlyErrorMessage(dynamic error) {
    final str = error.toString().toLowerCase();
    if (str.contains('connection refused') ||
        str.contains('socketexception') ||
        str.contains('timeout')) {
      return 'Could not connect to the other device. Make sure both devices are nearby and connected to the same Wi-Fi or Hotspot.';
    }
    if (str.contains('auth') ||
        str.contains('credential') ||
        str.contains('login')) {
      return 'Connection rejected: Session credentials invalid or expired.';
    }
    if (str.contains('permission') || str.contains('access denied')) {
      return 'Storage permission denied. Please grant storage access to save files.';
    }
    return 'Transfer was interrupted. Please check network connection and try again.';
  }
}
