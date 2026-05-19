class AuthUser {
  final String id;
  final String email;
  final String? name;

  const AuthUser({required this.id, required this.email, this.name});

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
    );
  }
}

class AuthSession {
  final String token;
  final AuthUser user;

  const AuthSession({required this.token, required this.user});
}
