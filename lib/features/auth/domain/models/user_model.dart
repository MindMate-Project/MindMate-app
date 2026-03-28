class User {
  final String? id;
  final String name;
  final String email;
  final String role;
  // final String? relation;
  final String? phoneNumber;
  final List<String>? patients;
  final String? gender;
  final DateTime? dateOfBirth;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.role,
    // this.relation,
    this.phoneNumber,
    this.patients,
    this.gender,
    this.dateOfBirth,
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
      dateOfBirth: _parseDate(json['dateOfBirth']),
    );
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
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth!.toIso8601String(),
    };
  }
}
