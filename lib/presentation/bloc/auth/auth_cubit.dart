import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(const AuthState());

  final AuthRepository _repository;
  static const _minimumSplashDuration = Duration(milliseconds: 1800);

  Future<void> checkStatus() async {
    emit(state.copyWith(status: AuthStatus.loading));
    final delay = Future.delayed(_minimumSplashDuration);
    final loggedIn = await _repository.isLoggedIn();
    await delay;
    if (!loggedIn) {
      emit(state.copyWith(status: AuthStatus.unauthenticated));
      return;
    }

    final displayName = await _repository.getDisplayName();
    final email = await _repository.getEmail();
    emit(
      state.copyWith(
        status: AuthStatus.authenticated,
        displayName: displayName,
        email: email,
      ),
    );
  }

  Future<void> login({required String email, required String password}) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));
    final delay = Future.delayed(_minimumSplashDuration);
    final success = await _repository.login(email: email, password: password);
    await delay;
    if (!success) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'Email atau password tidak sesuai.',
        ),
      );
      emit(state.copyWith(status: AuthStatus.unauthenticated));
      return;
    }

    final displayName = await _repository.getDisplayName();
    final storedEmail = await _repository.getEmail();
    emit(
      state.copyWith(
        status: AuthStatus.authenticated,
        displayName: displayName,
        email: storedEmail,
        errorMessage: null,
      ),
    );
  }

  Future<void> logout() async {
    await _repository.logout();
    emit(
      state.copyWith(
        status: AuthStatus.unauthenticated,
        displayName: null,
        email: null,
        errorMessage: null,
      ),
    );
  }
}
