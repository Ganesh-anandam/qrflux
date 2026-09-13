import 'package:flutter_test/flutter_test.dart';
import 'package:smart_file_transfer/models/file_item.dart';
import 'package:smart_file_transfer/models/qr_payload.dart';
import 'package:smart_file_transfer/services/qr/qr_service.dart';

void main() {
  group('QrService and QrPayload Tests', () {
    final qrService = QrService();

    test('generateVerificationCode produces 6 digits separated by space', () {
      final code = qrService.generateVerificationCode();
      expect(code.length, equals(7)); // 3 digits + 1 space + 3 digits
      expect(code, matches(RegExp(r'^\d{3} \d{3}$')));
    });

    test('createPayload generates valid QrPayload and encodes to JSON', () {
      final files = [
        const FileItem(
          id: '1',
          name: 'vacation.jpg',
          path: '/dummy/vacation.jpg',
          size: 2048000,
          category: FileCategory.image,
        ),
        const FileItem(
          id: '2',
          name: 'notes.pdf',
          path: '/dummy/notes.pdf',
          size: 102400,
          category: FileCategory.document,
        ),
      ];

      final payload = qrService.createPayload(
        host: '192.168.43.1',
        files: files,
      );

      expect(payload.host, equals('192.168.43.1'));
      expect(payload.port, equals(2121));
      expect(payload.files.length, equals(2));
      expect(payload.totalBytes, equals(2048000 + 102400));
      expect(payload.isExpired, isFalse);

      final encoded = payload.encode();
      final decoded = QrPayload.tryDecode(encoded);

      expect(decoded, isNotNull);
      expect(decoded!.host, equals(payload.host));
      expect(decoded.verificationCode, equals(payload.verificationCode));
      expect(decoded.files.length, equals(2));
      expect(decoded.totalBytes, equals(payload.totalBytes));
    });

    test('validatePayload detects malformed and expired payload', () {
      expect(qrService.validatePayload(null), contains('Invalid QR code'));

      final expiredPayload = QrPayload(
        version: 1,
        protocol: 'ftp',
        host: '192.168.1.10',
        port: 2121,
        sessionId: 'test',
        username: 'u',
        password: 'p',
        verificationCode: '123 456',
        expiresAtEpochSeconds:
            (DateTime.now().millisecondsSinceEpoch ~/ 1000) - 60, // 1 min ago
        files: [
          const FileItem(
            id: '1',
            name: 'doc.txt',
            path: '',
            size: 100,
            category: FileCategory.document,
          ),
        ],
        totalBytes: 100,
      );

      expect(qrService.validatePayload(expiredPayload), contains('expired'));
    });

    test('tryDecode handles web payload formats gracefully', () {
      const webJson =
          '{"app":"QRFlux","version":"1.0","host":"172.16.237.178","port":2121,"files":[{"name":"test.pdf","size":5000}],"totalSize":5000}';
      final decoded = QrPayload.tryDecode(webJson);
      expect(decoded, isNotNull);
      expect(decoded!.host, equals('172.16.237.178'));
      expect(decoded.port, equals(2121));
      expect(decoded.files.length, equals(1));
      expect(decoded.files.first.name, equals('test.pdf'));
      expect(decoded.files.first.category, equals(FileCategory.document));
      expect(decoded.totalBytes, equals(5000));
      expect(decoded.verificationCode, isNotEmpty);
      expect(qrService.validatePayload(decoded), isNull);
    });
  });
}
