class User {
  final String? id;
  final String name;
  final String email;
  final String role;
  final String? relation;
  final String? phone;
  final List<String>? patients;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.role,
    this.relation,
    this.phone,
    this.patients,
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
      relation: json['relation'],
      phone: json['phone'],
      patients: json['patients'] != null
          ? List<String>.from(json['patients'].map((p) => p.toString()))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'name': name,
      'email': email,
      'role': role,
      'relation': relation,
      'phone': phone,
      'patients': patients,
    };
  }
}
