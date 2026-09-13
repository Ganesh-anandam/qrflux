import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/file_item.dart';
import '../../state/receiver/receiver_notifier.dart';
import '../shared/app_button.dart';
import '../shared/gradient_card.dart';
import '../transfer/transfer_progress_screen.dart';

class TransferConfirmationScreen extends ConsumerWidget {
  const TransferConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiverState = ref.watch(receiverProvider);
    final receiverNotifier = ref.read(receiverProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final payload = receiverState.payload;
    if (payload == null) {
      return Scaffold(
        body: Center(
          child: AppButton(
            text: 'Return Home',
            width: 160,
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
          ),
        ),
      );
    }

    // Group files by category
    final categoryCounts = <FileCategory, int>{};
    for (final f in payload.files) {
      categoryCounts[f.category] = (categoryCounts[f.category] ?? 0) + 1;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Incoming Transfer',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            receiverNotifier.declineTransfer();
            Navigator.of(context).popUntil((r) => r.isFirst);
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Device Connected Header
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.success.withValues(alpha: 0.12),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.phonelink_ring_rounded,
                    size: 40,
                    color: AppColors.success,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Device Connected',
                textAlign: TextAlign.center,
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
                'Someone nearby wants to send files to you:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 24),

              // Breakdown Card
              GradientCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    ...categoryCounts.entries.map((entry) {
                      final cat = entry.key;
                      final count = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: cat.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(cat.icon, size: 20, color: cat.color),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              '$count ${cat.name}${count > 1 ? 's' : ''}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Transfer Size',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        Text(
                          Formatters.formatBytes(payload.totalBytes),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

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
                      'CONFIRM VERIFICATION CODE',
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
                      payload.verificationCode,
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ensure this code matches the sender\'s screen',
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

              const Spacer(),

              // Accept / Decline Buttons
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'Decline',
                      variant: AppButtonVariant.secondary,
                      onPressed: () {
                        receiverNotifier.declineTransfer();
                        Navigator.of(context).popUntil((r) => r.isFirst);
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 2,
                    child: AppButton(
                      text: 'Accept & Download',
                      icon: Icons.download_rounded,
                      onPressed: () {
                        receiverNotifier.acceptTransfer();
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const TransferProgressScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
