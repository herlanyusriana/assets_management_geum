import 'package:equatable/equatable.dart';

class SettingsState extends Equatable {
  const SettingsState({
    this.isLoading = true,
    this.darkMode = false,
    this.notificationsEnabled = true,
    this.syncWifiOnly = true,
  });

  final bool isLoading;
  final bool darkMode;
  final bool notificationsEnabled;
  final bool syncWifiOnly;

  SettingsState copyWith({
    bool? isLoading,
    bool? darkMode,
    bool? notificationsEnabled,
    bool? syncWifiOnly,
  }) {
    return SettingsState(
      isLoading: isLoading ?? this.isLoading,
      darkMode: darkMode ?? this.darkMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      syncWifiOnly: syncWifiOnly ?? this.syncWifiOnly,
    );
  }

  @override
  List<Object> get props => [
    isLoading,
    darkMode,
    notificationsEnabled,
    syncWifiOnly,
  ];
}
