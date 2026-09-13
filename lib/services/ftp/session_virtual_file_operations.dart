import 'dart:io';
import 'package:ftp_server/file_operations/file_operations.dart';
import 'package:path/path.dart' as p;
import '../../models/file_item.dart';

/// Virtual File Operations that maps exclusively to the user-selected files.
/// Strictly enforces read-only access and completely prevents directory traversal.
class SessionVirtualFileOperations extends FileOperations {
  final Map<String, FileItem> _filesByName;

  SessionVirtualFileOperations(List<FileItem> items)
    : _filesByName = _buildMap(items),
      super('/');

  SessionVirtualFileOperations._fromMap(this._filesByName, String currentDir)
    : super('/') {
    currentDirectory = currentDir;
  }

  static Map<String, FileItem> _buildMap(List<FileItem> items) {
    final map = <String, FileItem>{};
    for (final item in items) {
      final safeName = p.basename(item.path);
      map[safeName] = item;
      if (item.name.isNotEmpty && item.name != safeName) {
        map[item.name] = item;
      }
    }
    return map;
  }

  @override
  String resolvePath(String path) {
    if (path.isEmpty || path == '.' || path == '/') {
      return '/';
    }
    final clean = p.normalize(path);
    final filename = p.basename(clean).replaceAll('/', '').replaceAll('\\', '');
    final item = _filesByName[filename] ?? _filesByName[path];
    if (item != null) {
      return item.path;
    }
    return '/$filename';
  }

  @override
  void changeDirectory(String path) {
    // Only root directory exists
    currentDirectory = '/';
  }

  @override
  void changeToParentDirectory() {
    currentDirectory = '/';
  }

  @override
  Future<List<FileSystemEntity>> listDirectory(String path) async {
    final entities = <FileSystemEntity>[];
    for (final item in _filesByName.values) {
      final file = File(item.path);
      if (await file.exists()) {
        entities.add(file);
      }
    }
    return entities;
  }

  @override
  Future<File> getFile(String path) async {
    final filename = p.basename(p.normalize(path));
    final item = _filesByName[filename];
    if (item == null) {
      throw FileSystemException('File not found in session: $filename', path);
    }
    final file = File(item.path);
    if (!await file.exists()) {
      throw FileSystemException(
        'Physical file not found on disk: ${item.path}',
        path,
      );
    }
    return file;
  }

  @override
  Future<List<int>> readFile(String path) async {
    final file = await getFile(path);
    return file.readAsBytes();
  }

  @override
  Future<int> fileSize(String path) async {
    final filename = p.basename(p.normalize(path));
    final item = _filesByName[filename];
    if (item != null && item.size > 0) {
      return item.size;
    }
    final file = await getFile(path);
    return await file.length();
  }

  @override
  bool exists(String path) {
    if (path.isEmpty || path == '/' || path == '.') return true;
    final filename = p.basename(p.normalize(path));
    return _filesByName.containsKey(filename);
  }

  @override
  Future<void> writeFile(String path, List<int> data) async {
    throw const FileSystemException(
      'Write operations not permitted in read-only session',
    );
  }

  @override
  Future<void> createDirectory(String path) async {
    throw const FileSystemException(
      'Create directory not permitted in read-only session',
    );
  }

  @override
  Future<void> deleteFile(String path) async {
    throw const FileSystemException(
      'Delete operations not permitted in read-only session',
    );
  }

  @override
  Future<void> deleteDirectory(String path) async {
    throw const FileSystemException(
      'Delete directory not permitted in read-only session',
    );
  }

  @override
  Future<void> renameFileOrDirectory(String oldPath, String newPath) async {
    throw const FileSystemException(
      'Rename not permitted in read-only session',
    );
  }

  @override
  SessionVirtualFileOperations copy() {
    return SessionVirtualFileOperations._fromMap(
      _filesByName,
      currentDirectory,
    );
  }
}
