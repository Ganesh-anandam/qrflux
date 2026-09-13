import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../state/sender/sender_notifier.dart';
import '../shared/app_button.dart';
import '../shared/gradient_card.dart';
import 'sender_qr_screen.dart';

class ConnectionGuideScreen extends ConsumerStatefulWidget {
  const ConnectionGuideScreen({super.key});

  @override
  ConsumerState<ConnectionGuideScreen> createState() =>
      _ConnectionGuideScreenState();
}

class _ConnectionGuideScreenState extends ConsumerState<ConnectionGuideScreen> {
  bool _isLoading = false;

  Future<void> _startSharing() async {
    setState(() => _isLoading = true);
    final success = await ref.read(senderProvider.notifier).startServer();
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SenderQrScreen()),
        );
      } else {
        final error =
            ref.read(senderProvider).errorMessage ??
            'Could not start transfer session.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Connect Devices',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '3 Easy Steps to Connect',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No mobile data or internet connection needed.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 28),

              // Step 1
              _buildStepCard(
                stepNumber: '1',
                title: 'Keep devices nearby',
                description:
                    'Ensure the receiving phone is close by for maximum direct Wi-Fi speed.',
                icon: Icons.near_me_rounded,
                isDark: isDark,
              ),
              const SizedBox(height: 16),

              // Step 2
              _buildStepCard(
                stepNumber: '2',
                title: 'Connect Wi-Fi or Hotspot',
                description:
                    'Connect both phones to the same Wi-Fi router or turn on your phone\'s Personal Hotspot.',
                icon: Icons.wifi_tethering_rounded,
                isDark: isDark,
              ),
              const SizedBox(height: 16),

              // Step 3
              _buildStepCard(
                stepNumber: '3',
                title: 'Scan QR Code',
                description:
                    'Tap below to show your pairing code. The receiver scans it with their camera.',
                icon: Icons.qr_code_2_rounded,
                isDark: isDark,
              ),

              const Spacer(),

              AppButton(
                text: 'Show QR Code',
                icon: Icons.qr_code_rounded,
                isLoading: _isLoading,
                onPressed: _startSharing,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required String stepNumber,
    required String title,
    required String description,
    required IconData icon,
    required bool isDark,
  }) {
    return GradientCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              stepNumber,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const Spacer(),
                    Icon(icon, size: 20, color: AppColors.primary),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.3,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
