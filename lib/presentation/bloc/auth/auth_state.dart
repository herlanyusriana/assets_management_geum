import 'package:equatable/equatable.dart';

enum AuthStatus { unknown, loading, authenticated, unauthenticated, failure }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.displayName,
    this.email,
    this.errorMessage,
  });

  final AuthStatus status;
  final String? displayName;
  final String? email;
  final String? errorMessage;

  AuthState copyWith({
    AuthStatus? status,
    String? displayName,
    String? email,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, displayName, email, errorMessage];
}
