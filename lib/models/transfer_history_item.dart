enum TransferDirection { sent, received }

enum TransferHistoryStatus { success, failed, cancelled }

class TransferHistoryItem {
  final String id;
  final DateTime timestamp;
  final TransferDirection direction;
  final int fileCount;
  final int totalBytes;
  final TransferHistoryStatus status;
  final List<String> sampleFileNames;
  final List<String> savedPaths;
  final String? failureReason;
  final String? senderIp;

  const TransferHistoryItem({
    required this.id,
    required this.timestamp,
    required this.direction,
    required this.fileCount,
    required this.totalBytes,
    required this.status,
    required this.sampleFileNames,
    this.savedPaths = const [],
    this.failureReason,
    this.senderIp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'direction': direction.name,
    'fileCount': fileCount,
    'totalBytes': totalBytes,
    'status': status.name,
    'sampleFileNames': sampleFileNames,
    'savedPaths': savedPaths,
    'failureReason': failureReason,
    'senderIp': senderIp,
  };

  factory TransferHistoryItem.fromJson(Map<String, dynamic> json) =>
      TransferHistoryItem(
        id: json['id'] as String? ?? '',
        timestamp:
            DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.now(),
        direction: TransferDirection.values.firstWhere(
          (d) => d.name == json['direction'],
          orElse: () => TransferDirection.received,
        ),
        fileCount: (json['fileCount'] as num?)?.toInt() ?? 0,
        totalBytes: (json['totalBytes'] as num?)?.toInt() ?? 0,
        status: TransferHistoryStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => TransferHistoryStatus.success,
        ),
        sampleFileNames:
            (json['sampleFileNames'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        savedPaths:
            (json['savedPaths'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        failureReason: json['failureReason'] as String?,
        senderIp: json['senderIp'] as String?,
      );
}
