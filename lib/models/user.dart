import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  admin,
  staff,
  customer,
}

class AppUser {
  final String? id;
  final String email;
  final String name;
  final UserRole role;
  final DateTime createdAt;
  final bool isActive;

  AppUser({
    this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.createdAt,
    this.isActive = true,
  });

  // JSON'dan AppUser nesnesine dönüştürme
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${json['role']}',
        orElse: () => UserRole.customer,
      ),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      isActive: json['isActive'] ?? true,
    );
  }

  // AppUser nesnesinden JSON'a dönüştürme
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
      'role': role.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }

  // Firestore'dan AppUser nesnesine dönüştürme
  factory AppUser.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    return AppUser(
      id: snapshot.id,
      email: data['email'],
      name: data['name'],
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${data['role']}',
        orElse: () => UserRole.customer,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  // AppUser nesnesinden Firestore'a dönüştürme
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'role': role.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }

  // Kullanıcının admin olup olmadığını kontrol et
  bool get isAdmin => role == UserRole.admin;

  // Kullanıcının personel olup olmadığını kontrol et
  bool get isStaff => role == UserRole.staff;

  // Kullanıcının müşteri olup olmadığını kontrol et
  bool get isCustomer => role == UserRole.customer;

  // Kullanıcının yönetici yetkilerine sahip olup olmadığını kontrol et
  bool get hasManagementAccess => isAdmin || isStaff;
}
