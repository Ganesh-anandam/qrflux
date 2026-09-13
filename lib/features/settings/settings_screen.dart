import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../state/settings/settings_notifier.dart';
import '../shared/gradient_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Section: Appearance
          _buildSectionHeader('APPEARANCE', isDark),
          const SizedBox(height: 8),
          GradientCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _buildThemeRadio(
                  title: 'Dark Mode (Recommended)',
                  subtitle: 'Sleek high-contrast dark palette',
                  mode: ThemeMode.dark,
                  currentMode: settings.themeMode,
                  onChanged: settingsNotifier.setThemeMode,
                ),
                const Divider(height: 1),
                _buildThemeRadio(
                  title: 'Light Mode',
                  subtitle: 'Clean high-readability daylight palette',
                  mode: ThemeMode.light,
                  currentMode: settings.themeMode,
                  onChanged: settingsNotifier.setThemeMode,
                ),
                const Divider(height: 1),
                _buildThemeRadio(
                  title: 'System Default',
                  subtitle: 'Follow device system theme',
                  mode: ThemeMode.system,
                  currentMode: settings.themeMode,
                  onChanged: settingsNotifier.setThemeMode,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section: Transfer
          _buildSectionHeader('TRANSFER & STORAGE', isDark),
          const SizedBox(height: 8),
          GradientCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Confirm Before Receiving',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  subtitle: const Text(
                    'Always show incoming files and verification code before downloading',
                    style: TextStyle(fontSize: 13),
                  ),
                  value: settings.confirmBeforeReceiving,
                  activeThumbColor: AppColors.primary,
                  onChanged: settingsNotifier.setConfirmBeforeReceiving,
                ),
                const Divider(height: 20),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.folder_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text(
                    'Download Location',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  subtitle: const Text(
                    'Downloads / QRTransfer',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section: Privacy & Security
          _buildSectionHeader('PRIVACY & SECURITY', isDark),
          const SizedBox(height: 8),
          GradientCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.verified_user_outlined,
                      color: AppColors.success,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Session Isolation',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'The sender\'s FTP server only exposes the specific files selected for that session. Files outside the selection cannot be accessed.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    const Icon(
                      Icons.cloud_off_outlined,
                      color: AppColors.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '100% Offline',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'No internet connection is required. No telemetry, user tracking, or cloud uploads occur. Your data stays strictly on your local network.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section: About
          _buildSectionHeader('ABOUT', isDark),
          const SizedBox(height: 8),
          GradientCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Application', style: TextStyle(fontSize: 14)),
                    Text(
                      AppConstants.appName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Version', style: TextStyle(fontSize: 14)),
                    Text(
                      AppConstants.appVersion,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Courier',
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
        ),
      ),
    );
  }

  Widget _buildThemeRadio({
    required String title,
    required String subtitle,
    required ThemeMode mode,
    required ThemeMode currentMode,
    required ValueChanged<ThemeMode> onChanged,
  }) {
    return RadioListTile<ThemeMode>(
      value: mode,
      groupValue: currentMode,
      onChanged: (val) {
        if (val != null) onChanged(val);
      },
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      activeColor: AppColors.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
