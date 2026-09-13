class AppConstants {
  static const String appName = 'QR Transfer';
  static const String appTagline = 'Fast • Private • Offline';
  static const String appVersion = '1.0.0';

  // FTP Configuration
  static const int defaultFtpPort = 2121;
  static const int defaultBufferSize = 64 * 1024; // 64 KB buffer
  static const Duration sessionTimeout = Duration(minutes: 10);
  static const Duration connectionTimeout = Duration(seconds: 15);
  static const Duration socketTimeout = Duration(seconds: 30);

  // Verification Code
  static const int verificationCodeLength = 6;

  // UI Throttle
  static const Duration progressUpdateThrottle = Duration(milliseconds: 100);

  // QR Protocol version
  static const int qrProtocolVersion = 1;
  static const String qrProtocolName = 'ftp';
}
