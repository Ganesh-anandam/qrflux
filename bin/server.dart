import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:path/path.dart' as p;
import 'package:smart_file_transfer/services/ftp/stream_ftp_server.dart';

class TransferHostServer {
  static const int httpPort = 8080;
  static const int ftpPort = 2121;

  HttpServer? _httpServer;
  StreamFtpServer? _ftpServer;
  String? _localIp;

  final _eventController = StreamController<String>.broadcast();
  final Directory _stagingBaseDir = Directory(p.join(Directory.current.path, '.tmp_transfers'));

  String? _currentCode;
  int _activeClients = 0;

  Future<void> start() async {
    // 1. Resolve Best Local IPv4 Address
    _localIp = await _findBestLocalIp();
    print('\n==================================================');
    print('  QR Transfer — PC to Android Direct Host Server  ');
    print('==================================================');
    print('Local Wi-Fi / Hotspot IPv4: $_localIp');
    print('Web Sender Interface     : http://localhost:$httpPort (or http://$_localIp:$httpPort)');
    print('Streaming FTP Service     : ftp://$_localIp:$ftpPort');
    print('==================================================\n');

    // Ensure clean staging directory
    if (!await _stagingBaseDir.exists()) {
      await _stagingBaseDir.create(recursive: true);
    }

    // 2. Start HTTP Server for Chrome Web UI & REST endpoints
    _httpServer = await HttpServer.bind(InternetAddress.anyIPv4, httpPort);
    _httpServer!.listen(_handleHttpRequest);

    // 3. Open Chrome automatically
    _launchChrome();
  }

  Future<void> _handleHttpRequest(HttpRequest req) async {
    // Set CORS headers
    req.response.headers.add('Access-Control-Allow-Origin', '*');
    req.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    req.response.headers.add('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method == 'OPTIONS') {
      req.response.statusCode = HttpStatus.ok;
      await req.response.close();
      return;
    }

    final path = req.uri.path;

    if (path == '/' || path == '/index.html') {
      await _serveWebAsset(req, 'bin/web/index.html', 'text/html');
    } else if (path == '/api/info') {
      await _serveJson(req, {
        'ip': _localIp,
        'httpPort': httpPort,
        'ftpPort': ftpPort,
      });
    } else if (path == '/api/upload' && req.method == 'POST') {
      await _handleFileUpload(req);
    } else if (path == '/api/start-session' && req.method == 'POST') {
      await _handleStartSession(req);
    } else if (path == '/api/events') {
      await _handleEventStream(req);
    } else if (path == '/api/cancel' && req.method == 'POST') {
      await _handleCancel(req);
    } else {
      req.response.statusCode = HttpStatus.notFound;
      req.response.write('Not Found');
      await req.response.close();
    }
  }

  Future<void> _serveWebAsset(HttpRequest req, String assetPath, String contentType) async {
    final file = File(p.join(Directory.current.path, assetPath));
    if (await file.exists()) {
      req.response.headers.contentType = ContentType.parse(contentType);
      await req.response.addStream(file.openRead());
      await req.response.close();
    } else {
      req.response.statusCode = HttpStatus.notFound;
      req.response.write('Asset not found');
      await req.response.close();
    }
  }

  Future<void> _handleFileUpload(HttpRequest req) async {
    final sid = req.uri.queryParameters['sid'] ?? 'default';
    final originalName = req.uri.queryParameters['name'] ?? 'file_${DateTime.now().millisecondsSinceEpoch}';

    final sessionDir = Directory(p.join(_stagingBaseDir.path, sid));
    if (!await sessionDir.exists()) {
      await sessionDir.create(recursive: true);
    }

    final sanitizedName = p.basename(originalName).replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final targetFile = File(p.join(sessionDir.path, sanitizedName));

    final sink = targetFile.openWrite();
    await sink.addStream(req);
    await sink.flush();
    await sink.close();

    print('Staged file for transfer: ${targetFile.path} (${await targetFile.length()} bytes)');

    await _serveJson(req, {
      'status': 'uploaded',
      'name': sanitizedName,
      'size': await targetFile.length(),
      'sid': sid,
    });
  }

  Future<void> _handleStartSession(HttpRequest req) async {
    final sid = req.uri.queryParameters['sid'] ?? 'default';
    final sessionDir = Directory(p.join(_stagingBaseDir.path, sid));

    if (!await sessionDir.exists()) {
      req.response.statusCode = HttpStatus.badRequest;
      await _serveJson(req, {'error': 'No files uploaded for session'});
      return;
    }

    final stagedFiles = await sessionDir.list().where((e) => e is File).cast<File>().toList();
    if (stagedFiles.isEmpty) {
      req.response.statusCode = HttpStatus.badRequest;
      await _serveJson(req, {'error': 'No staged files found'});
      return;
    }

    // Stop any existing FTP session
    await _stopFtpServer();

    // Generate pairing credentials
    final rng = Random();
    _currentCode = (1000 + rng.nextInt(9000)).toString();
    final username = 'u_${rng.nextInt(900000) + 100000}';
    final password = 'p_${rng.nextInt(900000) + 100000}';

    int totalBytes = 0;
    final fileItemList = <Map<String, dynamic>>[];
    final ftpTransferFiles = <FtpTransferFile>[];

    for (final f in stagedFiles) {
      final size = await f.length();
      totalBytes += size;
      final name = p.basename(f.path);
      fileItemList.add({
        'name': name,
        'size': size,
        'type': _detectCategory(name),
      });
      ftpTransferFiles.add(FtpTransferFile(
        name: name,
        path: f.path,
        size: size,
      ));
    }

    // Standard QrPayload JSON format
    final qrPayloadMap = {
      'v': 1,
      'proto': 'ftp',
      'host': _localIp,
      'port': ftpPort,
      'user': username,
      'pass': password,
      'code': _currentCode,
      'exp': (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 1800, // 30 min expiry
      'files': fileItemList,
      'total': totalBytes,
    };

    final qrRaw = jsonEncode(qrPayloadMap);

    // Start robust Streaming FTP server
    _ftpServer = StreamFtpServer(
      port: ftpPort,
      username: username,
      password: password,
      localIp: _localIp ?? '127.0.0.1',
      files: ftpTransferFiles,
      onLog: (msg) => print(msg),
      onClientsChanged: (count) {
        _activeClients = count;
        _eventController.add(jsonEncode({
          'type': 'client_count',
          'count': _activeClients,
        }));
        if (_activeClients > 0) {
          _eventController.add(jsonEncode({
            'type': 'connected',
            'count': _activeClients,
          }));
        }
      },
      onProgress: ({
        required String filename,
        required int bytesTransferred,
        required int totalBytes,
        required double speedBytesPerSec,
      }) {
        _eventController.add(jsonEncode({
          'type': 'progress',
          'file': filename,
          'transferred': bytesTransferred,
          'total': totalBytes,
          'speed': speedBytesPerSec,
        }));
      },
      onTransferComplete: () {
        _eventController.add(jsonEncode({
          'type': 'complete',
          'total': totalBytes,
        }));
      },
    );

    await _ftpServer!.start();
    print('Streaming FTP Server started on port $ftpPort for session $sid (Verification Code: $_currentCode)');

    await _serveJson(req, {
      'sid': sid,
      'code': _currentCode,
      'qrRaw': qrRaw,
      'files': fileItemList,
      'total': totalBytes,
    });
  }

  Future<void> _handleEventStream(HttpRequest req) async {
    req.response.headers.contentType = ContentType('text', 'event-stream', charset: 'utf-8');
    req.response.headers.add('Cache-Control', 'no-cache');
    req.response.headers.add('Connection', 'keep-alive');

    // Initial event
    req.response.write('data: ${jsonEncode({'type': 'init', 'clients': _activeClients})}\n\n');
    await req.response.flush();

    final sub = _eventController.stream.listen((eventData) {
      try {
        req.response.write('data: $eventData\n\n');
        req.response.flush();
      } catch (_) {}
    });

    req.response.done.then((_) => sub.cancel());
  }

  Future<void> _handleCancel(HttpRequest req) async {
    await _stopFtpServer();
    _currentCode = null;
    _activeClients = 0;
    _eventController.add(jsonEncode({'type': 'cancelled'}));

    await _serveJson(req, {'status': 'cancelled'});
  }

  Future<void> _stopFtpServer() async {
    if (_ftpServer != null) {
      try {
        await _ftpServer!.stop();
      } catch (_) {}
      _ftpServer = null;
    }
  }

  Future<void> _serveJson(HttpRequest req, Map<String, dynamic> data) async {
    final bytes = utf8.encode(jsonEncode(data));
    req.response.headers.contentType = ContentType.json;
    req.response.headers.contentLength = bytes.length;
    req.response.add(bytes);
    await req.response.flush();
    await req.response.close();
  }

  Future<String> _findBestLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );

      // Prioritize Wi-Fi / Hotspot subnets
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          final ip = addr.address;
          if (ip.startsWith('192.168.43.')) return ip; // Hotspot
          if (ip.startsWith('172.16.') || ip.startsWith('192.168.') || ip.startsWith('10.')) {
            return ip;
          }
        }
      }

      if (interfaces.isNotEmpty && interfaces.first.addresses.isNotEmpty) {
        return interfaces.first.addresses.first.address;
      }
    } catch (_) {}
    return '127.0.0.1';
  }

  String _detectCategory(String filename) {
    final ext = p.extension(filename).toLowerCase().replaceFirst('.', '');
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'bmp', 'svg'].contains(ext)) return 'image';
    if (['mp4', 'mkv', 'mov', 'avi', 'wmv', 'flv', 'webm', '3gp'].contains(ext)) return 'video';
    if (['mp3', 'wav', 'aac', 'flac', 'm4a', 'ogg'].contains(ext)) return 'audio';
    if (['pdf', 'doc', 'docx', 'txt', 'rtf', 'xls', 'xlsx', 'ppt', 'pptx'].contains(ext)) return 'document';
    if (['zip', 'rar', '7z', 'tar', 'gz'].contains(ext)) return 'archive';
    return 'other';
  }

  void _launchChrome() {
    try {
      if (Platform.isWindows) {
        Process.run('cmd', ['/c', 'start', 'chrome', 'http://localhost:$httpPort']);
      } else if (Platform.isMacOS) {
        Process.run('open', ['-a', 'Google Chrome', 'http://localhost:$httpPort']);
      } else if (Platform.isLinux) {
        Process.run('google-chrome', ['http://localhost:$httpPort']);
      }
    } catch (_) {}
  }
}

void main() async {
  final server = TransferHostServer();
  await server.start();
}
