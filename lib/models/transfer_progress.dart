class TransferProgress {
  final String currentFileName;
  final int currentFileIndex;
  final int totalFiles;
  final int currentFileBytes;
  final int currentFileTotalBytes;
  final int totalBytesTransferred;
  final int totalBatchBytes;
  final double speedBytesPerSecond;
  final double estimatedSecondsRemaining;
  final String statusMessage;
  final bool isCompleted;
  final bool isCancelled;
  final bool hasError;
  final String? errorMessage;

  const TransferProgress({
    this.currentFileName = '',
    this.currentFileIndex = 0,
    this.totalFiles = 0,
    this.currentFileBytes = 0,
    this.currentFileTotalBytes = 0,
    this.totalBytesTransferred = 0,
    this.totalBatchBytes = 0,
    this.speedBytesPerSecond = 0.0,
    this.estimatedSecondsRemaining = 0.0,
    this.statusMessage = 'Preparing transfer...',
    this.isCompleted = false,
    this.isCancelled = false,
    this.hasError = false,
    this.errorMessage,
  });

  double get currentFileFraction {
    if (currentFileTotalBytes <= 0) return 0.0;
    return (currentFileBytes / currentFileTotalBytes).clamp(0.0, 1.0);
  }

  double get batchFraction {
    if (totalBatchBytes <= 0) return 0.0;
    return (totalBytesTransferred / totalBatchBytes).clamp(0.0, 1.0);
  }

  TransferProgress copyWith({
    String? currentFileName,
    int? currentFileIndex,
    int? totalFiles,
    int? currentFileBytes,
    int? currentFileTotalBytes,
    int? totalBytesTransferred,
    int? totalBatchBytes,
    double? speedBytesPerSecond,
    double? estimatedSecondsRemaining,
    String? statusMessage,
    bool? isCompleted,
    bool? isCancelled,
    bool? hasError,
    String? errorMessage,
  }) {
    return TransferProgress(
      currentFileName: currentFileName ?? this.currentFileName,
      currentFileIndex: currentFileIndex ?? this.currentFileIndex,
      totalFiles: totalFiles ?? this.totalFiles,
      currentFileBytes: currentFileBytes ?? this.currentFileBytes,
      currentFileTotalBytes:
          currentFileTotalBytes ?? this.currentFileTotalBytes,
      totalBytesTransferred:
          totalBytesTransferred ?? this.totalBytesTransferred,
      totalBatchBytes: totalBatchBytes ?? this.totalBatchBytes,
      speedBytesPerSecond: speedBytesPerSecond ?? this.speedBytesPerSecond,
      estimatedSecondsRemaining:
          estimatedSecondsRemaining ?? this.estimatedSecondsRemaining,
      statusMessage: statusMessage ?? this.statusMessage,
      isCompleted: isCompleted ?? this.isCompleted,
      isCancelled: isCancelled ?? this.isCancelled,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
