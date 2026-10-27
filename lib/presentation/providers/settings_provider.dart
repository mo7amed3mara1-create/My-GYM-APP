import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/app_settings_model.dart';
import '../../data/repositories/backup_repository.dart';
import '../../data/repositories/settings_repository.dart';
import 'auth_provider.dart';

class SettingsNotifier extends StateNotifier<AsyncValue<AppSettingsModel>> {
  final SettingsRepository _settingsRepo;

  SettingsNotifier(this._settingsRepo) : super(const AsyncValue.loading()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    state = const AsyncValue.loading();
    try {
      final s = await _settingsRepo.getSettings();
      state = AsyncValue.data(s);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateSettings(AppSettingsModel updated) async {
    try {
      await _settingsRepo.saveSettings(updated);
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> recordBackupDone() async {
    await _settingsRepo.recordBackupDone();
    await loadSettings();
  }
}

final settingsNotifierProvider = StateNotifierProvider<SettingsNotifier, AsyncValue<AppSettingsModel>>((ref) {
  final repo = ref.watch(settingsRepoProvider);
  return SettingsNotifier(repo);
});

final backupRepoProvider = Provider<BackupRepository>((ref) {
  return BackupRepository();
});

final backupDueProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(backupRepoProvider);
  return await repo.isBackupReminderDue();
});
