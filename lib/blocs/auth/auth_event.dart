import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  AuthLoginRequested({required this.email, required this.password});
  
  @override
  List<Object?> get props => [email, password];
}

class AuthLogoutRequested extends AuthEvent {
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  AuthCheckRequested();

  @override
  List<Object?> get props => [];
}

class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;

  AuthRegisterRequested({
    required this.name,
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [name, email, password];
}

class UpdateProfileEvent extends AuthEvent {
  final DateTime dateOfBirth;
  final String gender;

  UpdateProfileEvent({
    required this.dateOfBirth,
    required this.gender,
  });

  @override
  List<Object?> get props => [dateOfBirth, gender];
}
