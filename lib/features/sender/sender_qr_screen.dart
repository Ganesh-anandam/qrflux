import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../state/sender/sender_notifier.dart';
import '../../state/sender/sender_state.dart';
import '../shared/app_button.dart';
import '../shared/gradient_card.dart';
import '../shared/status_pill.dart';
import '../transfer/transfer_complete_screen.dart';

class SenderQrScreen extends ConsumerStatefulWidget {
  const SenderQrScreen({super.key});

  @override
  ConsumerState<SenderQrScreen> createState() => _SenderQrScreenState();
}

class _SenderQrScreenState extends ConsumerState<SenderQrScreen> {
  bool _showAdvancedDetails = false;

  @override
  Widget build(BuildContext context) {
    final senderState = ref.watch(senderProvider);
    final senderNotifier = ref.read(senderProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final payload = senderState.qrPayload;
    final qrData = payload?.encode() ?? '';

    // Listen for transfer completion
    ref.listen<SenderState>(senderProvider, (previous, next) {
      if (next.status == SenderStatus.completed) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => TransferCompleteScreen(
              fileCount: next.fileCount,
              totalBytes: next.totalBytes,
              isSender: true,
            ),
          ),
        );
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _confirmCancel(context, senderNotifier);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Connect Device',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => _confirmCancel(context, senderNotifier),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (senderState.connectedClients > 0 ||
                    senderState.status == SenderStatus.transferring) ...[
                  // Transfer Active State — QR Code is HIDDEN
                  Text(
                    'Receiver Connected!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Transferring files over private offline network',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Animated Transfer Pulse Card
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 36,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.send_rounded,
                          size: 48,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  StatusPill(
                    text: 'Transferring • Keep devices nearby',
                    icon: Icons.sync_rounded,
                    color: AppColors.primary,
                    isGlowing: true,
                  ),
                  const SizedBox(height: 28),
                ] else ...[
                  // Waiting for Scan State — QR Code is visible
                  Text(
                    'Scan this QR code',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'from the receiving device\'s camera',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Responsive QR Code Container with subtle glow
                  Builder(
                    builder: (ctx) {
                      final screenW = MediaQuery.sizeOf(ctx).width;
                      final qrSize = math.min(240.0, math.max(160.0, screenW - 96));
                      return Center(
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.25),
                                blurRadius: 28,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: qrData.isNotEmpty
                              ? QrImageView(
                                  data: qrData,
                                  version: QrVersions.auto,
                                  size: qrSize,
                                  eyeStyle: const QrEyeStyle(
                                    eyeShape: QrEyeShape.square,
                                    color: Color(0xFF090D16),
                                  ),
                                  dataModuleStyle: const QrDataModuleStyle(
                                    dataModuleShape: QrDataModuleShape.square,
                                    color: Color(0xFF090D16),
                                  ),
                                )
                              : SizedBox(
                                  width: qrSize,
                                  height: qrSize,
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Verification Code Box
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface
                          : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'VERIFICATION CODE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          payload?.verificationCode ?? '------',
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ask the receiver to confirm this code matches',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Connection Status Pill
                  StatusPill(
                    text: 'Waiting for connection • Scan QR',
                    icon: Icons.hourglass_top_rounded,
                    color: AppColors.accentCyan,
                    isGlowing: true,
                  ),
                  const SizedBox(height: 24),
                ],

                // Files Summary Bar
                GradientCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.inventory_2_outlined,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${senderState.fileCount} files ready',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Text(
                        Formatters.formatBytes(senderState.totalBytes),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Advanced Details Accordion
                Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: Text(
                      'Connection details',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    trailing: Icon(
                      _showAdvancedDetails
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    onExpansionChanged: (val) =>
                        setState(() => _showAdvancedDetails = val),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurface
                              : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow('Host IP', payload?.host ?? '-'),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              'FTP Port',
                              '${payload?.port ?? 2121}',
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              'Session ID',
                              payload?.sessionId.substring(0, 8) ?? '-',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Cancel Button
                AppButton(
                  text: 'Cancel Transfer',
                  variant: AppButtonVariant.outline,
                  onPressed: () => _confirmCancel(context, senderNotifier),
                ),
                const SizedBox(height: 12),
                if (senderState.connectedClients > 0)
                  AppButton(
                    text: 'Finish Transfer',
                    icon: Icons.check_circle_outline_rounded,
                    onPressed: () => senderNotifier.completeSession(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: 'Courier',
          ),
        ),
      ],
    );
  }

  void _confirmCancel(BuildContext context, SenderNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Transfer?'),
        content: const Text(
          'The temporary connection and QR code will be terminated.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep Waiting'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              notifier.cancelSession();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cancel Transfer'),
          ),
        ],
      ),
    );
  }
}
