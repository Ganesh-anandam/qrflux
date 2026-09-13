import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/utils/formatters.dart';
import '../../models/file_item.dart';

class FileStorageService {
  /// Request appropriate storage/media permissions
  Future<bool> requestStoragePermission() async {
    if (kIsWeb) return true;
    if (Platform.isAndroid) {
      if (await Permission.photos.request().isGranted ||
          await Permission.storage.request().isGranted ||
          await Permission.manageExternalStorage.request().isGranted) {
        return true;
      }
      return true; // FilePicker handles SAF on modern Android
    }
    return true;
  }

  /// Request camera permission
  Future<bool> requestCameraPermission() async {
    if (kIsWeb) return true;
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Pick multiple files of any type
  Future<List<FileItem>> pickFiles() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.any,
        withData: kIsWeb,
      );

      if (files.isEmpty) {
        return [];
      }

      final items = <FileItem>[];
      for (final file in files) {
        if (kIsWeb) {
          final fileSize = file.lengthSync() ?? await file.length();
          items.add(
            FileItem.fromNameAndSize(
              name: file.name,
              size: fileSize,
            ),
          );
        } else if (file.path != null && file.path!.isNotEmpty) {
          final ioFile = File(file.path!);
          final exists = await ioFile.exists();
          if (exists) {
            final size = await ioFile.length();
            items.add(FileItem.fromPath(file.path!, fileSize: size));
          }
        }
      }
      return items;
    } catch (_) {
      return [];
    }
  }

  /// Resolve standard destination download directory
  Future<Directory> getDownloadDirectory() async {
    if (!kIsWeb && Platform.isAndroid) {
      final dir = Directory('/storage/emulated/0/Download/QRTransfer');
      if (await dir.exists()) return dir;
      try {
        await dir.create(recursive: true);
        return dir;
      } catch (_) {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) return extDir;
      }
    }

    try {
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null) {
        final qrDir = Directory(p.join(downloadsDir.path, 'QRTransfer'));
        if (!await qrDir.exists()) {
          await qrDir.create(recursive: true);
        }
        return qrDir;
      }
    } catch (_) {}

    final appDocDir = await getApplicationDocumentsDirectory();
    final qrDir = Directory(p.join(appDocDir.path, 'QRTransfer'));
    if (!await qrDir.exists()) {
      await qrDir.create(recursive: true);
    }
    return qrDir;
  }

  /// Generate a safe, non-colliding destination path for an incoming file
  Future<File> getDestinationFile(String originalFilename) async {
    final saveDir = await getDownloadDirectory();
    final safeName = Formatters.sanitizeFilename(originalFilename);
    var targetFile = File(p.join(saveDir.path, safeName));

    if (!await targetFile.exists()) {
      return targetFile;
    }

    final ext = p.extension(safeName);
    final base = p.basenameWithoutExtension(safeName);
    var counter = 1;

    while (await targetFile.exists()) {
      final newName = '$base ($counter)$ext';
      targetFile = File(p.join(saveDir.path, newName));
      counter++;
    }

    return targetFile;
  }

  /// List all received files in the QRTransfer download directory
  Future<List<FileItem>> listReceivedFiles() async {
    if (kIsWeb) return [];
    try {
      final dir = await getDownloadDirectory();
      if (!await dir.exists()) return [];

      final entities = dir.listSync();
      final items = <FileItem>[];

      for (final entity in entities) {
        if (entity is File) {
          final size = await entity.length();
          items.add(FileItem.fromPath(entity.path, fileSize: size));
        }
      }

      // Sort newest files first
      items.sort((a, b) => b.name.compareTo(a.name));
      return items;
    } catch (_) {
      return [];
    }
  }

  /// Open file directly from within the app using open_filex with explicit MIME type resolution
  Future<bool> openFile(String filePath, {String? explicitMimeType}) async {
    if (kIsWeb) return false;
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;

      final ext = p.extension(filePath).toLowerCase().replaceFirst('.', '');
      String? mimeType = explicitMimeType;

      if (mimeType == null || mimeType.isEmpty) {
        switch (ext) {
          case 'jpg':
          case 'jpeg':
            mimeType = 'image/jpeg';
            break;
          case 'png':
            mimeType = 'image/png';
            break;
          case 'webp':
            mimeType = 'image/webp';
            break;
          case 'gif':
            mimeType = 'image/gif';
            break;
          case 'bmp':
            mimeType = 'image/bmp';
            break;
          case 'svg':
            mimeType = 'image/svg+xml';
            break;
          case 'heic':
          case 'heif':
            mimeType = 'image/heif';
            break;
          case 'mp4':
            mimeType = 'video/mp4';
            break;
          case 'mkv':
            mimeType = 'video/x-matroska';
            break;
          case 'mp3':
            mimeType = 'audio/mpeg';
            break;
          case 'pdf':
            mimeType = 'application/pdf';
            break;
          case 'apk':
            mimeType = 'application/vnd.android.package-archive';
            break;
          case 'txt':
            mimeType = 'text/plain';
            break;
          case 'zip':
            mimeType = 'application/zip';
            break;
        }
      }

      final result = await OpenFilex.open(filePath, type: mimeType);
      return result.type == ResultType.done;
    } catch (_) {
      return false;
    }
  }

  /// Delete a received file from within the app
  Future<bool> deleteReceivedFile(String filePath) async {
    if (kIsWeb) return false;
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
