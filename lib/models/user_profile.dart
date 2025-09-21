class UserProfile {
  final String id;
  final String email;
  final String name;
  final String role;
  final String location;
  final String? phoneNumber;
  final double? latitude;
  final double? longitude;
  final String createdAt;
  final String? orgName;

    UserProfile({
      required this.id,
      required this.email,
      required this.name,
      required this.role,
      required this.location,
      this.phoneNumber,
      this.latitude,
      this.longitude,
      required this.createdAt,
      this.orgName,
    });

    factory UserProfile.fromJson(Map<String, dynamic> json) {
      return UserProfile(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String,
        role: json['role'] as String,
        location: json['location'] as String,
        phoneNumber: json['phone_number'] as String?,
        latitude: json['latitude'] is double
            ? json['latitude'] as double
            : json['latitude'] != null
                ? double.tryParse(json['latitude'].toString())
                : null,
        longitude: json['longitude'] is double
            ? json['longitude'] as double
            : json['longitude'] != null
                ? double.tryParse(json['longitude'].toString())
                : null,
        createdAt: json['created_at'] as String,
        orgName: json['org_name'] as String?,
      );
    }

    Map<String, dynamic> toJson() {
      return {
        'id': id,
        'email': email,
        'name': name,
        'role': role,
        'location': location,
        'phone_number': phoneNumber,
        'latitude': latitude,
        'longitude': longitude,
        'created_at': createdAt,
        'org_name': orgName,
      };
    }

    @override
    String toString() {
      return 'UserProfile(id: $id, email: $email, name: $name, orgName: $orgName, role: $role, location: $location, phoneNumber: $phoneNumber, latitude: $latitude, longitude: $longitude)';
    }
  }
