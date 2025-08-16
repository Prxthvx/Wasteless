class UserProfile {
  final String id;
  final String email;
  final String name;
  final String role;
  final String location;
  final String createdAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.location,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      location: json['location'] as String,
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'location': location,
      'created_at': createdAt,
    };
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, email: $email, name: $name, role: $role, location: $location)';
  }
}
