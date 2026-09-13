import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final ThemeMode themeMode;
  final bool confirmBeforeReceiving;
  final bool autoStartTransfer;

  const SettingsState({
    this.themeMode = ThemeMode.dark,
    this.confirmBeforeReceiving = true,
    this.autoStartTransfer = false,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? confirmBeforeReceiving,
    bool? autoStartTransfer,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      confirmBeforeReceiving:
          confirmBeforeReceiving ?? this.confirmBeforeReceiving,
      autoStartTransfer: autoStartTransfer ?? this.autoStartTransfer,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    _loadSettings();
    return const SettingsState();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt('theme_mode') ?? 0;
      final confirm = prefs.getBool('confirm_before_receiving') ?? true;
      final autoStart = prefs.getBool('auto_start_transfer') ?? false;

      state = SettingsState(
        themeMode:
            ThemeMode.values[themeIndex.clamp(0, ThemeMode.values.length - 1)],
        confirmBeforeReceiving: confirm,
        autoStartTransfer: autoStart,
      );
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('theme_mode', mode.index);
    } catch (_) {}
  }

  Future<void> setConfirmBeforeReceiving(bool value) async {
    state = state.copyWith(confirmBeforeReceiving: value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('confirm_before_receiving', value);
    } catch (_) {}
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);
