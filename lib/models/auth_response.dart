import 'package:flutter_task_of_apicalling_and_data_management/models/user_model.dart';

class AuthResponse {
  final User user;
  final String token;

  AuthResponse({
    required this.user,
    required this.token,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: User.fromJson(json),
      token: json['token'] ?? '',
    );
  }
}
