import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/settings_repository.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._repository) : super(const SettingsState());

  final SettingsRepository _repository;

  Future<void> initialize() async {
    emit(state.copyWith(isLoading: true));
    final values = await _repository.load();
    emit(
      state.copyWith(
        isLoading: false,
        darkMode: values[SettingsRepository.darkModeKey] ?? false,
        notificationsEnabled:
            values[SettingsRepository.notificationsKey] ?? true,
        syncWifiOnly: values[SettingsRepository.syncWifiOnlyKey] ?? true,
      ),
    );
  }

  Future<void> toggleDarkMode(bool enabled) async {
    emit(state.copyWith(darkMode: enabled));
    await _repository.updateDarkMode(enabled);
  }

  Future<void> toggleNotifications(bool enabled) async {
    emit(state.copyWith(notificationsEnabled: enabled));
    await _repository.updateNotifications(enabled);
  }

  Future<void> toggleWifiOnly(bool enabled) async {
    emit(state.copyWith(syncWifiOnly: enabled));
    await _repository.updateWifiOnly(enabled);
  }
}
