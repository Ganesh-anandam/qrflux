import 'package:intl/intl.dart';

class Formatters {
  /// Format raw bytes into human readable string (e.g. "14.2 MB")
  static String formatBytes(int bytes, {int decimals = 1}) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double count = bytes.toDouble();
    while (count >= 1024 && i < suffixes.length - 1) {
      count /= 1024;
      i++;
    }
    return '${count.toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  /// Format transfer speed (e.g. "24.5 MB/s")
  static String formatSpeed(double bytesPerSecond) {
    if (bytesPerSecond <= 0) return '0.0 KB/s';
    if (bytesPerSecond < 1024 * 1024) {
      final kb = bytesPerSecond / 1024;
      return '${kb.toStringAsFixed(1)} KB/s';
    }
    final mb = bytesPerSecond / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB/s';
  }

  /// Format duration into MM:SS (e.g. "01:24")
  static String formatDuration(Duration duration) {
    if (duration.isNegative) return '00:00';
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (duration.inHours > 0) {
      final hours = duration.inHours.toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  /// Format ETA in seconds to readable string
  static String formatEta(double secondsRemaining) {
    if (secondsRemaining <= 0 ||
        secondsRemaining.isInfinite ||
        secondsRemaining.isNaN) {
      return '--:--';
    }
    return formatDuration(Duration(seconds: secondsRemaining.round()));
  }

  /// Format timestamp for transfer history
  static String formatDate(DateTime dateTime) {
    return DateFormat('MMM d, y • h:mm a').format(dateTime);
  }

  /// Sanitize filename to prevent directory traversal and illegal characters
  static String sanitizeFilename(String filename) {
    var clean = filename.replaceAll(RegExp(r'[\\/:\*\?"<>\|\x00-\x1F]'), '_');
    // Prevent path traversal like ../ or ..\
    clean = clean.replaceAll('..', '_');
    clean = clean.trim();
    if (clean.isEmpty) {
      clean = 'transfer_${DateTime.now().millisecondsSinceEpoch}';
    }
    return clean;
  }
}
