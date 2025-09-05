class WebUserModel {
  final int id;
  final String email;
  final String name;
  final String passwordHash;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  WebUserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.passwordHash,
    this.profileImageUrl,
    required this.createdAt,
    this.lastLoginAt,
  });

  factory WebUserModel.fromJson(Map<String, dynamic> json) {
    return WebUserModel(
      id: json['id'] as int,
      email: json['email'] as String,
      name: json['name'] as String,
      passwordHash: json['passwordHash'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'passwordHash': passwordHash,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
    };
  }

  WebUserModel copyWith({
    int? id,
    String? email,
    String? name,
    String? passwordHash,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return WebUserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      passwordHash: passwordHash ?? this.passwordHash,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}

