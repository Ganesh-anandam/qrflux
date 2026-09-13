import 'dart:convert';
import 'file_item.dart';

class QrPayload {
  final int version;
  final String protocol;
  final String host;
  final int port;
  final String sessionId;
  final String username;
  final String password;
  final String verificationCode;
  final int expiresAtEpochSeconds;
  final List<FileItem> files;
  final int totalBytes;

  const QrPayload({
    required this.version,
    required this.protocol,
    required this.host,
    required this.port,
    required this.sessionId,
    required this.username,
    required this.password,
    required this.verificationCode,
    required this.expiresAtEpochSeconds,
    required this.files,
    required this.totalBytes,
  });

  bool get isExpired {
    if (expiresAtEpochSeconds <= 0) return false;
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return nowSeconds > expiresAtEpochSeconds;
  }

  Map<String, dynamic> toMap() => {
    'v': version,
    'proto': protocol,
    'host': host,
    'port': port,
    'sid': sessionId,
    'user': username,
    'pass': password,
    'code': verificationCode,
    'exp': expiresAtEpochSeconds,
    'files': files.map((f) => f.toJson()).toList(),
    'total': totalBytes,
  };

  String encode() => jsonEncode(toMap());

  factory QrPayload.fromMap(Map<String, dynamic> map) {
    final fileListRaw = map['files'] as List<dynamic>? ?? [];
    final parsedFiles = fileListRaw
        .map((f) => FileItem.fromJson(f as Map<String, dynamic>))
        .toList();

    int parseVersion(dynamic v) {
      if (v is num) return v.toInt();
      if (v is String) {
        final parsed = double.tryParse(v);
        if (parsed != null) return parsed.toInt();
      }
      return 1;
    }

    final totalVal = (map['total'] as num?)?.toInt() ??
        (map['totalSize'] as num?)?.toInt() ??
        parsedFiles.fold<int>(0, (sum, f) => sum + f.size);

    return QrPayload(
      version: parseVersion(map['v'] ?? map['version']),
      protocol: map['proto'] as String? ?? map['protocol'] as String? ?? 'ftp',
      host: map['host'] as String? ?? '',
      port: (map['port'] as num?)?.toInt() ?? 2121,
      sessionId: map['sid'] as String? ??
          map['sessionId'] as String? ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      username: map['user'] as String? ?? map['username'] as String? ?? 'qrflux',
      password: map['pass'] as String? ?? map['password'] as String? ?? 'qrflux',
      verificationCode: map['code'] as String? ??
          map['verificationCode'] as String? ??
          '4829',
      expiresAtEpochSeconds: (map['exp'] as num?)?.toInt() ??
          (map['expiresAt'] as num?)?.toInt() ??
          ((DateTime.now().millisecondsSinceEpoch ~/ 1000) + 3600),
      files: parsedFiles,
      totalBytes: totalVal,
    );
  }

  static QrPayload? tryDecode(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
      // Require at minimum a host address
      if (!decoded.containsKey('host')) {
        return null;
      }
      return QrPayload.fromMap(decoded);
    } catch (_) {
      return null;
    }
  }
}
