import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/transfer_history_item.dart';
import '../../services/storage/file_storage_service.dart';
import '../../state/history/history_notifier.dart';
import '../sender/file_picker_screen.dart';
import '../shared/app_button.dart';
import '../shared/gradient_card.dart';
import 'received_files_screen.dart';

enum HistoryFilter { all, received, sent, failed }

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  HistoryFilter _filter = HistoryFilter.all;
  final FileStorageService _storageService = FileStorageService();

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyProvider);
    final historyNotifier = ref.read(historyProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final receivedCount = history.where((h) => h.direction == TransferDirection.received).length;
    final sentCount = history.where((h) => h.direction == TransferDirection.sent).length;
    final failedCount = history.where((h) => h.status != TransferHistoryStatus.success).length;

    final filtered = history.where((item) {
      switch (_filter) {
        case HistoryFilter.all:
          return true;
        case HistoryFilter.received:
          return item.direction == TransferDirection.received && item.status == TransferHistoryStatus.success;
        case HistoryFilter.sent:
          return item.direction == TransferDirection.sent && item.status == TransferHistoryStatus.success;
        case HistoryFilter.failed:
          return item.status != TransferHistoryStatus.success;
      }
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Transfer History',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open_rounded),
            tooltip: 'Browse Received Files',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ReceivedFilesScreen()),
              );
            },
          ),
          if (history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Clear History',
              onPressed: () => _confirmClear(context, historyNotifier),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('All', HistoryFilter.all, history.length, null),
                const SizedBox(width: 8),
                _buildFilterChip('Received', HistoryFilter.received, receivedCount, AppColors.success),
                const SizedBox(width: 8),
                _buildFilterChip('Sent', HistoryFilter.sent, sentCount, AppColors.primary),
                const SizedBox(width: 8),
                _buildFilterChip('Failed', HistoryFilter.failed, failedCount, AppColors.error),
              ],
            ),
          ),
          const Divider(height: 1),

          // History List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withValues(alpha: 0.08),
                            ),
                            child: Icon(
                              Icons.history_rounded,
                              size: 56,
                              color: AppColors.primary.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _filter == HistoryFilter.all
                                ? 'No transfers yet'
                                : 'No ${_filter.name} transfers found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Transferred files can be viewed and opened directly in this app.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                          if (_filter == HistoryFilter.all) ...[
                            const SizedBox(height: 24),
                            AppButton(
                              text: 'Send Files',
                              icon: Icons.upload_rounded,
                              width: 160,
                              onPressed: () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(builder: (_) => const FilePickerScreen()),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    itemCount: filtered.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final isSent = item.direction == TransferDirection.sent;
                      final isSuccess = item.status == TransferHistoryStatus.success;

                      return GradientCard(
                        onTap: () => _showTransferDetailsSheet(context, item),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: (isSuccess
                                            ? (isSent ? AppColors.primary : AppColors.secondary)
                                            : AppColors.error)
                                        .withValues(alpha: 0.12),
                                  ),
                                  child: Icon(
                                    isSuccess
                                        ? (isSent ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded)
                                        : Icons.error_outline_rounded,
                                    color: isSuccess
                                        ? (isSent ? AppColors.primary : AppColors.secondary)
                                        : AppColors.error,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            isSent ? 'Sent' : 'Received',
                                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: (isSuccess ? AppColors.success : AppColors.error)
                                                  .withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              item.status.name.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: isSuccess ? AppColors.success : AppColors.error,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${item.fileCount} ${item.fileCount == 1 ? 'file' : 'files'} • ${Formatters.formatBytes(item.totalBytes)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      Formatters.formatDate(item.timestamp),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('Details', style: TextStyle(fontSize: 11, color: AppColors.primary)),
                                        Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.primary),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // If failed, show diagnostic banner
                            if (!isSuccess && item.failureReason != null) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline_rounded, color: AppColors.error, size: 14),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        item.failureReason!,
                                        style: const TextStyle(fontSize: 11, color: AppColors.error),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // If received and has saved paths, show in-app location chip
                            if (item.direction == TransferDirection.received && isSuccess && item.savedPaths.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              InkWell(
                                onTap: () => _openFile(item.savedPaths.first),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.folder_open_rounded, color: AppColors.success, size: 15),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item.savedPaths.first,
                                          style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Icon(Icons.open_in_new_rounded, size: 14, color: AppColors.success),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, HistoryFilter filter, int count, Color? countColor) {
    final isSelected = _filter == filter;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: (countColor ?? AppColors.primary).withValues(alpha: isSelected ? 0.3 : 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? const Color(0xFF090D16) : (countColor ?? AppColors.primary),
                ),
              ),
            ),
          ],
        ],
      ),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? const Color(0xFF090D16) : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
      ),
      selectedColor: AppColors.primary,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (_) => setState(() => _filter = filter),
    );
  }

  void _showTransferDetailsSheet(BuildContext context, TransferHistoryItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSuccess = item.status == TransferHistoryStatus.success;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF0B111E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.direction == TransferDirection.received ? 'Received Transfer' : 'Sent Transfer',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (isSuccess ? AppColors.success : AppColors.error).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.status.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSuccess ? AppColors.success : AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${Formatters.formatDate(item.timestamp)} • ${Formatters.formatBytes(item.totalBytes)}',
              style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),

            if (item.senderIp != null && item.senderIp!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Device IP: ${item.senderIp}',
                style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
              ),
            ],

            if (!isSuccess && item.failureReason != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Failure Diagnostic:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.error)),
                    const SizedBox(height: 4),
                    Text(item.failureReason!, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            const Text('Files in Transfer', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 8),

            ...item.sampleFileNames.asMap().entries.map((entry) {
              final idx = entry.key;
              final name = entry.value;
              final path = idx < item.savedPaths.length ? item.savedPaths[idx] : null;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.insert_drive_file_rounded, size: 20, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (path != null && path.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              path,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                fontFamily: 'monospace',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            tooltip: 'Copy path',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: path));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('File location copied!'), duration: Duration(seconds: 1)),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.open_in_new_rounded, size: 16, color: AppColors.primary),
                            tooltip: 'Open file in app',
                            onPressed: () => _openFile(path),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            }),

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.folder_open_rounded),
                label: const Text('Browse All Received Files'),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ReceivedFilesScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openFile(String path) async {
    final success = await _storageService.openFile(path);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open file in app viewer.'), backgroundColor: AppColors.error),
      );
    }
  }

  void _confirmClear(BuildContext context, HistoryNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear History?'),
        content: const Text(
          'All transfer history logs will be removed. Your downloaded files will remain safely stored on your device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              notifier.clearHistory();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
