import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  static const darkModeKey = 'settings_dark_mode';
  static const notificationsKey = 'settings_notifications';
  static const syncWifiOnlyKey = 'settings_sync_wifi_only';

  Future<Map<String, bool>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      darkModeKey: prefs.getBool(darkModeKey) ?? false,
      notificationsKey: prefs.getBool(notificationsKey) ?? true,
      syncWifiOnlyKey: prefs.getBool(syncWifiOnlyKey) ?? true,
    };
  }

  Future<void> updateDarkMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(darkModeKey, enabled);
  }

  Future<void> updateNotifications(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(notificationsKey, enabled);
  }

  Future<void> updateWifiOnly(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(syncWifiOnlyKey, enabled);
  }
}
