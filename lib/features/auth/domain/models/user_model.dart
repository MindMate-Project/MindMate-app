class User {
  final String? id;
  final String name;
  final String email;
  final String role;
  bool get isCaregiver => role == 'caregiver';
  bool get isPatient => role == 'patient';
  final String? phoneNumber;
  final List<String>? patients;
  final String? gender;
  final String? address;
  final DateTime? dateOfBirth;
  final String? photoUrl;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phoneNumber,
    this.patients,
    this.gender,
    this.address,
    this.dateOfBirth,
    this.photoUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Handle both _id (MongoDB) and id formats
    String? userId;
    if (json['_id'] != null) {
      userId = json['_id'].toString();
    } else if (json['id'] != null) {
      userId = json['id'].toString();
    }

    return User(
      id: userId,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      // relation: json['relation'],
      phoneNumber: (json['phoneNumber']),
      patients: json['patients'] != null
          ? List<String>.from(json['patients'].map((p) => p.toString()))
          : null,
      gender: json['gender'],
      address: json['address']?.toString(),
      dateOfBirth: _parseDate(json['dateOfBirth']),
      photoUrl: _firstNonEmpty(json, const [
        'photoUrl',
        'photo',
        'avatar',
        'avatarUrl',
        'profileImage',
        'profilePicture',
        'image',
        'picture',
      ]),
    );
  }

  /// First non-empty string value among [keys] (backends name this field
  /// inconsistently), or null when none is present.
  static String? _firstNonEmpty(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null) {
        final s = value.toString().trim();
        if (s.isNotEmpty) return s;
      }
    }
    return null;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final s = value.toString().trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'name': name,
      'email': email,
      'role': role,
      'phoneNumber': phoneNumber,
      'patients': patients,
      'gender': gender,
      if (address != null) 'address': address,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth!.toIso8601String(),
      if (photoUrl != null) 'photoUrl': photoUrl,
    };
  }

  /// Returns a copy with the given fields replaced. Pass [clearPhotoUrl] to set
  /// the photo back to null (since a null [photoUrl] argument keeps the current
  /// value).
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? phoneNumber,
    List<String>? patients,
    String? gender,
    String? address,
    DateTime? dateOfBirth,
    String? photoUrl,
    bool clearPhotoUrl = false,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      patients: patients ?? this.patients,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      photoUrl: clearPhotoUrl ? null : (photoUrl ?? this.photoUrl),
    );
  }
}
