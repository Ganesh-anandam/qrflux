import 'dart:async';
import 'package:path/path.dart' as p;
import '../../core/constants/app_constants.dart';
import '../../models/file_item.dart';
import 'stream_ftp_server.dart';

class FtpServerService {
  StreamFtpServer? _server;
  bool _isRunning = false;
  final _clientCountController = StreamController<int>.broadcast();
  final _transferCompleteController = StreamController<void>.broadcast();

  bool get isRunning => _isRunning;
  Stream<int> get clientCountStream => _clientCountController.stream;
  Stream<void> get transferCompleteStream => _transferCompleteController.stream;
  int get activeClientsCount => _server?.activeClients ?? 0;

  /// Start the local high-performance streaming FTP server
  Future<bool> startServer({
    required List<FileItem> files,
    required String username,
    required String password,
    String localIp = '127.0.0.1',
    int port = AppConstants.defaultFtpPort,
  }) async {
    try {
      await stopServer();

      final ftpTransferFiles = files.map((item) {
        return FtpTransferFile(
          name: item.name.isNotEmpty ? item.name : p.basename(item.path),
          path: item.path,
          size: item.size,
        );
      }).toList();

      _server = StreamFtpServer(
        port: port,
        username: username,
        password: password,
        localIp: localIp,
        files: ftpTransferFiles,
        onClientsChanged: (count) {
          _clientCountController.add(count);
        },
        onTransferComplete: () {
          _transferCompleteController.add(null);
        },
      );

      await _server!.start();
      _isRunning = true;
      _clientCountController.add(0);
      return true;
    } catch (_) {
      _isRunning = false;
      return false;
    }
  }

  /// Stop the FTP server and tear down all active sessions
  Future<void> stopServer() async {
    if (_server != null) {
      try {
        await _server!.stop();
      } catch (_) {}
      _server = null;
    }
    _isRunning = false;
    _clientCountController.add(0);
  }

  void dispose() {
    stopServer();
    _clientCountController.close();
    _transferCompleteController.close();
  }
}
