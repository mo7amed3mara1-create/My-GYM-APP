class OwnerModel {
  final String username;
  final String passwordHash;
  final String salt;
  final String displayName;
  final DateTime createdAt;

  OwnerModel({
    required this.username,
    required this.passwordHash,
    required this.salt,
    String? displayName,
    required this.createdAt,
  }) : displayName = displayName ?? username;

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password_hash': passwordHash,
      'salt': salt,
      'display_name': displayName,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory OwnerModel.fromMap(Map<String, dynamic> map) {
    return OwnerModel(
      username: map['username'] as String,
      passwordHash: map['password_hash'] as String,
      salt: map['salt'] as String,
      displayName: (map['display_name'] as String?) ?? (map['username'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
