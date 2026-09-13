import 'dart:math';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../models/file_item.dart';
import '../../models/qr_payload.dart';

class QrService {
  final _uuid = const Uuid();
  final _random = Random.secure();

  /// Generate a 6-digit verification code with formatted space: "482 913"
  String generateVerificationCode() {
    final codeInt = 100000 + _random.nextInt(900000);
    final str = codeInt.toString();
    return '${str.substring(0, 3)} ${str.substring(3)}';
  }

  /// Generate temporary single-use random credentials
  Map<String, String> generateCredentials() {
    const chars = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final user = 'user_${_random.nextInt(9999)}';
    final pass = List.generate(
      16,
      (_) => chars[_random.nextInt(chars.length)],
    ).join();
    return {'user': user, 'pass': pass};
  }

  /// Create a fresh session payload
  QrPayload createPayload({
    required String host,
    required List<FileItem> files,
    int port = AppConstants.defaultFtpPort,
  }) {
    final creds = generateCredentials();
    final code = generateVerificationCode();
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final expSeconds = nowSeconds + AppConstants.sessionTimeout.inSeconds;
    final totalBytes = files.fold<int>(0, (sum, item) => sum + item.size);

    return QrPayload(
      version: AppConstants.qrProtocolVersion,
      protocol: AppConstants.qrProtocolName,
      host: host,
      port: port,
      sessionId: _uuid.v4(),
      username: creds['user']!,
      password: creds['pass']!,
      verificationCode: code,
      expiresAtEpochSeconds: expSeconds,
      files: files,
      totalBytes: totalBytes,
    );
  }

  /// Validate scanned QR payload
  String? validatePayload(QrPayload? payload) {
    if (payload == null) {
      return 'Invalid QR code format. Please scan a QR Transfer code.';
    }
    if (payload.version != AppConstants.qrProtocolVersion) {
      return 'Incompatible protocol version. Please update the app on both devices.';
    }
    if (payload.host.isEmpty) {
      return 'Invalid connection details in QR code.';
    }
    if (payload.isExpired) {
      return 'The QR code session has expired. Please ask the sender to generate a new QR code.';
    }
    if (payload.files.isEmpty) {
      return 'No files found in the transfer session.';
    }
    return null;
  }
}
