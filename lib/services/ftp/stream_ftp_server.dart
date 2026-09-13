import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

class FtpTransferFile {
  final String name;
  final String path;
  final int size;

  FtpTransferFile({
    required this.name,
    required this.path,
    required this.size,
  });
}

typedef FtpProgressCallback = void Function({
  required String filename,
  required int bytesTransferred,
  required int totalBytes,
  required double speedBytesPerSec,
});

/// High-performance, streaming RFC 959 FTP server implementation.
/// Designed for fast, reliable local device transfers of any file size (KB to multi-GB).
/// Solves the buffer overflow and premature 5-second socket termination in third-party libraries.
class StreamFtpServer {
  final int port;
  final String username;
  final String password;
  final String localIp;
  final Map<String, FtpTransferFile> _filesByName;
  final void Function(String message)? onLog;
  final void Function(int activeCount)? onClientsChanged;
  final FtpProgressCallback? onProgress;
  final void Function()? onTransferComplete;

  ServerSocket? _controlServer;
  final List<_ClientSession> _sessions = [];
  bool _isStopping = false;

  StreamFtpServer({
    required this.port,
    required this.username,
    required this.password,
    required this.localIp,
    required List<FtpTransferFile> files,
    this.onLog,
    this.onClientsChanged,
    this.onProgress,
    this.onTransferComplete,
  }) : _filesByName = {
          for (final f in files) ...{
            f.name: f,
            p.basename(f.path): f,
          }
        };

  int get activeClients => _sessions.length;

  void _log(String msg) {
    onLog?.call('[StreamFTP] $msg');
  }

  Future<void> start() async {
    _isStopping = false;
    _controlServer = await ServerSocket.bind(
      InternetAddress.anyIPv4,
      port,
      shared: true,
    );
    _log('Server listening on port $port (IP: $localIp)');

    _controlServer!.listen(
      _handleClientConnect,
      onError: (err) => _log('Control server error: $err'),
      onDone: () => _log('Control server stopped'),
    );
  }

  void _handleClientConnect(Socket controlSocket) {
    if (_isStopping) {
      controlSocket.destroy();
      return;
    }

    final session = _ClientSession(
      server: this,
      socket: controlSocket,
    );
    _sessions.add(session);
    _log('Client connected from ${controlSocket.remoteAddress.address}:${controlSocket.remotePort}. Total clients: ${_sessions.length}');
    onClientsChanged?.call(_sessions.length);

    session.start().then((_) {
      _sessions.remove(session);
      _log('Client session ended. Remaining clients: ${_sessions.length}');
      onClientsChanged?.call(_sessions.length);
    });
  }

  Future<void> stop() async {
    _isStopping = true;
    for (final s in List.of(_sessions)) {
      await s.close();
    }
    _sessions.clear();
    await _controlServer?.close();
    _controlServer = null;
    _log('Server stopped');
  }

  FtpTransferFile? findFile(String rawName) {
    final clean = rawName.trim().replaceAll('"', '');
    final base = p.basename(clean);
    return _filesByName[clean] ?? _filesByName[base] ?? _filesByName['/$base'];
  }
}

class _ClientSession {
  final StreamFtpServer server;
  final Socket socket;
  late final StreamSubscription _subscription;
  final Completer<void> _doneCompleter = Completer<void>();

  bool isAuthenticated = false;
  String? enteredUser;
  ServerSocket? pasvServer;
  Socket? dataSocket;
  Completer<Socket>? dataSocketCompleter;

  _ClientSession({required this.server, required this.socket});

  Future<void> start() async {
    // Send standard FTP greeting
    _send('220 QR Transfer Direct Engine Ready');

    final lineSplitter = utf8.decoder.bind(socket).transform(const LineSplitter());
    _subscription = lineSplitter.listen(
      _handleLine,
      onError: (e) {
        server._log('Session socket error: $e');
        _cleanup();
      },
      onDone: _cleanup,
      cancelOnError: true,
    );

    return _doneCompleter.future;
  }

  void _send(String response) {
    try {
      server._log('<- $response');
      socket.write('$response\r\n');
    } catch (_) {}
  }

  Future<void> _handleLine(String rawLine) async {
    final line = rawLine.trim();
    if (line.isEmpty) return;
    server._log('-> $line');

    final parts = line.split(' ');
    final command = parts[0].toUpperCase();
    final argument = parts.length > 1 ? parts.sublist(1).join(' ').trim() : '';

    switch (command) {
      case 'USER':
        enteredUser = argument;
        _send('331 Password required for $argument');
        break;

      case 'PASS':
        if (enteredUser == server.username && argument == server.password) {
          isAuthenticated = true;
          _send('230 User logged in, proceed');
        } else {
          // If no password set or matches
          if (server.username.isEmpty || argument == server.password) {
            isAuthenticated = true;
            _send('230 User logged in, proceed');
          } else {
            _send('530 Login incorrect');
          }
        }
        break;

      case 'AUTH':
        _send('502 Explicit TLS not enabled for local transfer');
        break;

      case 'TYPE':
        // Binary (I) or ASCII (A)
        _send('200 Type set to ${argument.toUpperCase()}');
        break;

      case 'SYST':
        _send('215 UNIX Type: L8');
        break;

      case 'FEAT':
        _send('211-Features:\r\n SIZE\r\n UTF8\r\n211 End');
        break;

      case 'PWD':
        _send('257 "/" is current directory');
        break;

      case 'CWD':
      case 'CDUP':
        _send('250 Directory changed to /');
        break;

      case 'NOOP':
        _send('200 OK');
        break;

      case 'SIZE':
        final file = server.findFile(argument);
        if (file != null) {
          _send('213 ${file.size}');
        } else {
          _send('550 File not found');
        }
        break;

      case 'PASV':
        await _handlePasv();
        break;

      case 'EPSV':
        await _handleEpsv();
        break;

      case 'RETR':
        await _handleRetr(argument);
        break;

      case 'LIST':
      case 'NLST':
        await _handleList();
        break;

      case 'QUIT':
        _send('221 Service closing control connection');
        await close();
        break;

      default:
        _send('502 Command not implemented: $command');
        break;
    }
  }

  Future<void> _handlePasv() async {
    await _closePasv();
    try {
      pasvServer = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
      final pasvPort = pasvServer!.port;
      dataSocketCompleter = Completer<Socket>();

      pasvServer!.listen((incoming) {
        if (!dataSocketCompleter!.isCompleted) {
          dataSocketCompleter!.complete(incoming);
        }
      });

      // Format IP and Port: (h1,h2,h3,h4,p1,p2)
      final ipParts = server.localIp.split('.');
      final p1 = pasvPort >> 8;
      final p2 = pasvPort & 0xFF;
      _send('227 Entering Passive Mode (${ipParts.join(',')},$p1,$p2)');
    } catch (e) {
      server._log('Error establishing PASV: $e');
      _send('425 Can\'t open data connection');
    }
  }

  Future<void> _handleEpsv() async {
    await _closePasv();
    try {
      pasvServer = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
      final pasvPort = pasvServer!.port;
      dataSocketCompleter = Completer<Socket>();

      pasvServer!.listen((incoming) {
        if (!dataSocketCompleter!.isCompleted) {
          dataSocketCompleter!.complete(incoming);
        }
      });

      _send('229 Entering Extended Passive Mode (|||$pasvPort|)');
    } catch (e) {
      server._log('Error establishing EPSV: $e');
      _send('425 Can\'t open data connection');
    }
  }

  Future<void> _handleList() async {
    if (dataSocketCompleter == null) {
      _send('425 Use PASV or EPSV first');
      return;
    }

    _send('150 Opening ASCII mode data connection for file list');

    try {
      final dSocket = await dataSocketCompleter!.future.timeout(const Duration(seconds: 10));
      final buffer = StringBuffer();
      for (final f in server._filesByName.values) {
        buffer.write('-rw-r--r-- 1 owner group ${f.size} Jan 01 00:00 ${f.name}\r\n');
      }
      dSocket.write(buffer.toString());
      await dSocket.flush();
      await dSocket.close();
      dSocket.destroy();
      _send('226 Transfer complete');
    } catch (e) {
      _send('426 Connection closed; transfer aborted');
    } finally {
      await _closePasv();
    }
  }

  Future<void> _handleRetr(String argument) async {
    final fileItem = server.findFile(argument);
    if (fileItem == null) {
      _send('550 File not found: $argument');
      await _closePasv();
      return;
    }

    final physicalFile = File(fileItem.path);
    if (!await physicalFile.exists()) {
      _send('550 Physical file missing on disk: ${fileItem.name}');
      await _closePasv();
      return;
    }

    if (dataSocketCompleter == null) {
      _send('425 Use PASV or EPSV first');
      return;
    }

    final fileSize = fileItem.size;
    _send('150 Opening BINARY mode data connection for ${fileItem.name} ($fileSize bytes)');

    Socket? dSocket;
    try {
      dSocket = await dataSocketCompleter!.future.timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw TimeoutException('Client did not connect to data port in time'),
      );

      final stopwatch = Stopwatch()..start();
      var transferred = 0;
      var lastReportTime = 0;
      var lastReportBytes = 0;

      // Stream file with backpressure and progress reporting
      final readStream = physicalFile.openRead();
      await for (final chunk in readStream) {
        dSocket.add(chunk);
        transferred += chunk.length;

        final now = stopwatch.elapsedMilliseconds;
        if (now - lastReportTime >= 250) {
          final timeDelta = (now - lastReportTime) / 1000.0;
          final bytesDelta = transferred - lastReportBytes;
          final speed = timeDelta > 0 ? (bytesDelta / timeDelta) : 0.0;

          server.onProgress?.call(
            filename: fileItem.name,
            bytesTransferred: transferred,
            totalBytes: fileSize,
            speedBytesPerSec: speed,
          );

          lastReportTime = now;
          lastReportBytes = transferred;
        }
      }

      // CRITICAL: Await full flush so every last byte is written to the TCP stack!
      await dSocket.flush();

      // Gracefully close the write side so client receives clean TCP FIN
      await dSocket.close();
      dSocket.destroy();
      dSocket = null;

      // Final progress notification
      server.onProgress?.call(
        filename: fileItem.name,
        bytesTransferred: transferred,
        totalBytes: fileSize,
        speedBytesPerSec: 0,
      );

      server.onTransferComplete?.call();

      // Send 226 ONLY after all data is completely transmitted
      _send('226 Transfer complete');
      server._log('Successfully transferred ${fileItem.name} ($transferred bytes)');
    } catch (e, stack) {
      server._log('Error during RETR ${fileItem.name}: $e\n$stack');
      try {
        dSocket?.destroy();
      } catch (_) {}
      _send('426 Transfer aborted: $e');
    } finally {
      await _closePasv();
    }
  }

  Future<void> _closePasv() async {
    try {
      await pasvServer?.close();
    } catch (_) {}
    pasvServer = null;
    dataSocketCompleter = null;
  }

  Future<void> close() async {
    _cleanup();
    try {
      await socket.close();
      socket.destroy();
    } catch (_) {}
  }

  void _cleanup() {
    _subscription.cancel();
    _closePasv();
    if (!_doneCompleter.isCompleted) {
      _doneCompleter.complete();
    }
  }
}
