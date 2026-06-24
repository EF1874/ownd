class AuthUser {
  final String id;
  final String email;
  final String? name;
  final int notificationLeadDays;
  final String notificationTime;

  const AuthUser({
    required this.id,
    required this.email,
    this.name,
    this.notificationLeadDays = 3,
    this.notificationTime = '08:00',
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      notificationLeadDays: json['notificationLeadDays'] as int? ?? 3,
      notificationTime: json['notificationTime'] as String? ?? '08:00',
    );
  }
}

class AuthSession {
  final String token;
  final AuthUser user;

  const AuthSession({required this.token, required this.user});
}
