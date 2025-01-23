part of 'auth_cubit.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final String? token;

  const AuthSuccess({this.token});

  @override
  List<Object> get props => [token ?? ''];
}

class AuthFailure extends AuthState {
  final String error;

  const AuthFailure({required this.error});

  @override
  List<Object> get props => [error];
}