import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.departmentCode,
  });

  final String id;
  final String name;
  final String email;
  final String departmentCode;

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      departmentCode: (map['department_code'] as String?) ?? '',
    );
  }

  @override
  List<Object?> get props => [id, name, email, departmentCode];
}
