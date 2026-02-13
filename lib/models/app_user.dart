class AppUser {
  final String uid;
  final String email;
  final String fullName;
  final String role;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLoginAt;

  AppUser({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
    this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      email: data['email']?.toString() ?? '',
      fullName: data['fullName']?.toString() ?? '',
      role: data['role']?.toString() ?? '',
      createdAt: (data['createdAt'] as dynamic)?.toDate(),
      updatedAt: (data['updatedAt'] as dynamic)?.toDate(),
      lastLoginAt: (data['lastLoginAt'] as dynamic)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fullName': fullName,
      'role': role,
    };
  }
}
