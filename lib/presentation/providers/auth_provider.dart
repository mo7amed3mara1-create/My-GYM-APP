import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/biometric_service.dart';
import '../../data/models/owner_model.dart';
import '../../data/repositories/settings_repository.dart';

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final bool hasOwnerAccount;
  final OwnerModel? owner;
  final String? errorMessage;

  AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.hasOwnerAccount = false,
    this.owner,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    bool? hasOwnerAccount,
    OwnerModel? owner,
    String? errorMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      hasOwnerAccount: hasOwnerAccount ?? this.hasOwnerAccount,
      owner: owner ?? this.owner,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final SettingsRepository _settingsRepo;
  late final Future<void> initializationFuture;

  AuthNotifier(this._settingsRepo) : super(AuthState(isLoading: true)) {
    initializationFuture = checkInitialState();
  }

  Future<void> checkInitialState() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final hasOwner = await _settingsRepo.hasOwnerAccount();
      if (!hasOwner) {
        state = state.copyWith(
          isLoading: false,
          hasOwnerAccount: false,
          isAuthenticated: false,
          owner: null,
        );
        return;
      }

      final isLogged = await _settingsRepo.isLoggedIn();
      final username = await _settingsRepo.getLoggedInUsername();

      OwnerModel? owner;
      if (username != null && username.isNotEmpty) {
        owner = await _settingsRepo.getAdminByUsername(username);
      }
      owner ??= await _settingsRepo.getOwner();

      // If user has created an account and session is active:
      // Auto authenticate to keep owner logged in!
      final shouldBeAuthenticated = isLogged && owner != null;

      state = state.copyWith(
        isLoading: false,
        hasOwnerAccount: true,
        isAuthenticated: shouldBeAuthenticated,
        owner: owner,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> login(String username, String password) async {
    final cleanUser = username.trim();
    final cleanPass = password.trim();

    if (cleanUser.isEmpty || cleanPass.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'يرجى إدخال اسم المستخدم وكلمة المرور',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final hasOwner = await _settingsRepo.hasOwnerAccount();

      // If no owner account exists yet on first run: auto-create and log in!
      if (!hasOwner) {
        await _settingsRepo.createOwnerAccount(cleanUser, cleanPass);
        await _settingsRepo.saveSession(isLoggedIn: true, username: cleanUser);
        final owner = await _settingsRepo.getAdminByUsername(cleanUser);
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          hasOwnerAccount: true,
          owner: owner,
          errorMessage: null,
        );
        return true;
      }

      // Check credentials across all registered admins
      final valid = await _settingsRepo.verifyCredentials(cleanUser, cleanPass);
      if (valid) {
        await _settingsRepo.saveSession(isLoggedIn: true, username: cleanUser);
        final owner = await _settingsRepo.getAdminByUsername(cleanUser);
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          owner: owner,
          errorMessage: null,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: false,
          errorMessage: 'اسم المستخدم أو كلمة المرور غير صحيحة',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'خطأ: $e');
      return false;
    }
  }

  /// Real physical biometric verification
  Future<BiometricAuthResult> loginWithBiometrics() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final bioResult = await BiometricService.instance.authenticate();
      if (!bioResult.isSuccess) {
        state = state.copyWith(isLoading: false, errorMessage: bioResult.message);
        return bioResult;
      }

      final owner = await _settingsRepo.getOwner();
      if (owner != null) {
        await _settingsRepo.saveSession(isLoggedIn: true, username: owner.username);
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          owner: owner,
          errorMessage: null,
        );
        return const BiometricAuthResult(isSuccess: true, message: 'تم الدخول بالبصمة بنجاح');
      } else {
        state = state.copyWith(isLoading: false, errorMessage: 'لا يوجد حساب مسؤول مسجل بعد');
        return const BiometricAuthResult(isSuccess: false, message: 'لا يوجد حساب مسؤول مسجل بعد');
      }
    } catch (e) {
      final err = 'فشل الدخول بالبصمة: $e';
      state = state.copyWith(isLoading: false, errorMessage: err);
      return BiometricAuthResult(isSuccess: false, message: err);
    }
  }

  Future<bool> createOwner(String username, String password, {String? displayName}) async {
    final cleanUser = username.trim();
    final cleanPass = password.trim();

    if (cleanUser.isEmpty || cleanPass.isEmpty) {
      state = state.copyWith(errorMessage: 'يرجى إدخال اسم المستخدم وكلمة المرور');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _settingsRepo.createOwnerAccount(cleanUser, cleanPass, displayName: displayName);
      await _settingsRepo.saveSession(isLoggedIn: true, username: cleanUser);
      final owner = await _settingsRepo.getAdminByUsername(cleanUser);
      state = state.copyWith(
        isLoading: false,
        hasOwnerAccount: true,
        isAuthenticated: true,
        owner: owner,
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> resetCredentials(String newUsername, String newPassword) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _settingsRepo.resetOwnerAccount(newUsername, newPassword);
      await _settingsRepo.saveSession(isLoggedIn: true, username: newUsername);
      final owner = await _settingsRepo.getAdminByUsername(newUsername);
      state = state.copyWith(
        isLoading: false,
        hasOwnerAccount: true,
        isAuthenticated: true,
        owner: owner,
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _settingsRepo.clearSession();
    state = state.copyWith(isAuthenticated: false);
  }
}

final settingsRepoProvider = Provider<SettingsRepository>((ref) => SettingsRepository());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(settingsRepoProvider);
  return AuthNotifier(repo);
});
