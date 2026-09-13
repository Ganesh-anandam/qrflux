import 'package:flutter_test/flutter_test.dart';
import 'package:smart_file_transfer/core/utils/formatters.dart';

void main() {
  group('Filename Sanitizer Tests', () {
    test('sanitizes directory traversal patterns', () {
      final dangerous1 = '../../etc/passwd';
      final clean1 = Formatters.sanitizeFilename(dangerous1);
      expect(clean1.contains('..'), isFalse);
      expect(clean1.contains('/'), isFalse);

      final dangerous2 = r'..\..\Windows\System32\cmd.exe';
      final clean2 = Formatters.sanitizeFilename(dangerous2);
      expect(clean2.contains('..'), isFalse);
      expect(clean2.contains(r'\'), isFalse);
    });

    test('strips illegal filesystem characters', () {
      final input = 'photo:2026*final?.jpg';
      final clean = Formatters.sanitizeFilename(input);
      expect(clean, equals('photo_2026_final_.jpg'));
    });

    test('replaces blank names with timestamp fallback', () {
      final clean = Formatters.sanitizeFilename('   ');
      expect(clean.startsWith('transfer_'), isTrue);
    });
  });
}
