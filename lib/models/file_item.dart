import 'package:flutter/material.dart';

enum FileCategory {
  image,
  video,
  audio,
  document,
  archive,
  other;

  IconData get icon {
    switch (this) {
      case FileCategory.image:
        return Icons.image_rounded;
      case FileCategory.video:
        return Icons.videocam_rounded;
      case FileCategory.audio:
        return Icons.audiotrack_rounded;
      case FileCategory.document:
        return Icons.description_rounded;
      case FileCategory.archive:
        return Icons.folder_zip_rounded;
      case FileCategory.other:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color get color {
    switch (this) {
      case FileCategory.image:
        return const Color(0xFF38BDF8);
      case FileCategory.video:
        return const Color(0xFFF43F5E);
      case FileCategory.audio:
        return const Color(0xFFA855F7);
      case FileCategory.document:
        return const Color(0xFF3B82F6);
      case FileCategory.archive:
        return const Color(0xFFF59E0B);
      case FileCategory.other:
        return const Color(0xFF94A3B8);
    }
  }
}

class FileItem {
  final String id;
  final String name;
  final String path;
  final int size;
  final FileCategory category;
  final String? mimeType;

  const FileItem({
    required this.id,
    required this.name,
    required this.path,
    required this.size,
    required this.category,
    this.mimeType,
  });

  factory FileItem.fromPath(String filePath, {int? fileSize, String? fileId}) {
    final fileName = filePath.split(RegExp(r'[\\/]')).last;
    final ext = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : '';
    final cat = _categoryFromExtension(ext);

    return FileItem(
      id: fileId ?? '${fileName}_${DateTime.now().microsecondsSinceEpoch}',
      name: fileName,
      path: filePath,
      size: fileSize ?? 0,
      category: cat,
    );
  }

  factory FileItem.fromNameAndSize({
    required String name,
    required int size,
    String? path,
    String? fileId,
  }) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    final cat = _categoryFromExtension(ext);

    return FileItem(
      id: fileId ?? '${name}_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      path: path ?? '',
      size: size,
      category: cat,
    );
  }

  static FileCategory _categoryFromExtension(String ext) {
    if ([
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
      'bmp',
      'svg',
      'heic',
    ].contains(ext)) {
      return FileCategory.image;
    }
    if ([
      'mp4',
      'mkv',
      'mov',
      'avi',
      'wmv',
      'flv',
      'webm',
      '3gp',
    ].contains(ext)) {
      return FileCategory.video;
    }
    if (['mp3', 'wav', 'aac', 'flac', 'm4a', 'ogg', 'opus'].contains(ext)) {
      return FileCategory.audio;
    }
    if ([
      'pdf',
      'doc',
      'docx',
      'txt',
      'rtf',
      'xls',
      'xlsx',
      'ppt',
      'pptx',
      'csv',
    ].contains(ext)) {
      return FileCategory.document;
    }
    if (['zip', 'rar', '7z', 'tar', 'gz', 'bz2'].contains(ext)) {
      return FileCategory.archive;
    }
    return FileCategory.other;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'size': size,
    'category': category.name,
    'mimeType': mimeType,
  };

  factory FileItem.fromJson(Map<String, dynamic> json) => FileItem(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? 'unknown',
    path: '',
    size: (json['size'] as num?)?.toInt() ?? 0,
    category: FileCategory.values.firstWhere(
      (c) => c.name == (json['category'] ?? json['type']),
      orElse: () => _categoryFromExtension(
        (json['name'] as String? ?? '').contains('.')
            ? (json['name'] as String).split('.').last.toLowerCase()
            : '',
      ),
    ),
    mimeType: json['mimeType'] as String?,
  );
}
