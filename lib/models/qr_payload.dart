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

    return QrPayload(
      version: (map['v'] as num?)?.toInt() ?? 1,
      protocol: map['proto'] as String? ?? 'ftp',
      host: map['host'] as String? ?? '',
      port: (map['port'] as num?)?.toInt() ?? 2121,
      sessionId: map['sid'] as String? ?? '',
      username: map['user'] as String? ?? '',
      password: map['pass'] as String? ?? '',
      verificationCode: map['code'] as String? ?? '',
      expiresAtEpochSeconds: (map['exp'] as num?)?.toInt() ?? 0,
      files: parsedFiles,
      totalBytes: (map['total'] as num?)?.toInt() ?? 0,
    );
  }

  static QrPayload? tryDecode(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
      if (!decoded.containsKey('host') || !decoded.containsKey('code')) {
        return null;
      }
      return QrPayload.fromMap(decoded);
    } catch (_) {
      return null;
    }
  }
}
