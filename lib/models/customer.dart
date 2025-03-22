import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  final String? id;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final int age;
  final DateTime registrationDate;
  final int membershipDuration; // ay cinsinden
  final bool isInstallment; // true: taksitli, false: peşin
  final Map<String, bool> installments; // <ay, ödemeDurumu>

  Customer({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.age,
    required this.registrationDate,
    required this.membershipDuration,
    required this.isInstallment,
    required this.installments,
  });

  // JSON'dan Customer nesnesine dönüştürme
  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      phoneNumber: json['phoneNumber'],
      age: json['age'],
      registrationDate: (json['registrationDate'] as Timestamp).toDate(),
      membershipDuration: json['membershipDuration'],
      isInstallment: json['isInstallment'],
      installments: Map<String, bool>.from(json['installments']),
    );
  }

  // Customer nesnesinden JSON'a dönüştürme
  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'age': age,
      'registrationDate': Timestamp.fromDate(registrationDate),
      'membershipDuration': membershipDuration,
      'isInstallment': isInstallment,
      'installments': installments,
    };
  }

  // Firestore'dan Customer nesnesine dönüştürme
  factory Customer.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    return Customer(
      id: snapshot.id,
      firstName: data['firstName'],
      lastName: data['lastName'],
      phoneNumber: data['phoneNumber'],
      age: data['age'],
      registrationDate: (data['registrationDate'] as Timestamp).toDate(),
      membershipDuration: data['membershipDuration'],
      isInstallment: data['isInstallment'],
      installments: Map<String, bool>.from(data['installments']),
    );
  }

  // Customer nesnesinden Firestore'a dönüştürme
  Map<String, dynamic> toFirestore() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'age': age,
      'registrationDate': Timestamp.fromDate(registrationDate),
      'membershipDuration': membershipDuration,
      'isInstallment': isInstallment,
      'installments': installments,
    };
  }
}
