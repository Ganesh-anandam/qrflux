import 'package:flutter_test/flutter_test.dart';
import 'package:smart_file_transfer/core/utils/formatters.dart';

void main() {
  group('Transfer Calculations and Formatters', () {
    test('formatBytes formats various units correctly', () {
      expect(Formatters.formatBytes(0), equals('0 B'));
      expect(Formatters.formatBytes(512), equals('512.0 B'));
      expect(Formatters.formatBytes(1024), equals('1.0 KB'));
      expect(Formatters.formatBytes(1024 * 1024), equals('1.0 MB'));
      expect(Formatters.formatBytes(1536 * 1024), equals('1.5 MB'));
      expect(Formatters.formatBytes(1024 * 1024 * 1024 * 2), equals('2.0 GB'));
    });

    test('formatSpeed formats throughput', () {
      expect(Formatters.formatSpeed(0), equals('0.0 KB/s'));
      expect(Formatters.formatSpeed(500 * 1024), equals('500.0 KB/s'));
      expect(Formatters.formatSpeed(25 * 1024 * 1024), equals('25.0 MB/s'));
    });

    test('formatEta formats seconds into MM:SS', () {
      expect(Formatters.formatEta(0), equals('--:--'));
      expect(Formatters.formatEta(-5), equals('--:--'));
      expect(Formatters.formatEta(15), equals('00:15'));
      expect(Formatters.formatEta(75), equals('01:15'));
      expect(Formatters.formatEta(3665), equals('01:01:05'));
    });
  });
}
