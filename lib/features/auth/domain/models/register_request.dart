/// Payload for POST `/api/auth/register`.
class RegisterRequest {
  final String name;
  final String email;
  final String password;
  final String role;
  final String gender;
  final String address;
  final String phoneNumber;
  final DateTime? dateOfBirth;

  const RegisterRequest({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    required this.gender,
    required this.address,
    required this.phoneNumber,
    this.dateOfBirth,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'gender': gender.toLowerCase(),
      'address': address,
      'phoneNumber': phoneNumber,
      if (dateOfBirth != null) 'dateOfBirth': _formatDate(dateOfBirth!),
    };
  }

  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
