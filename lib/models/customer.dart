import 'package:cloud_firestore/cloud_firestore.dart';

enum MembershipStatus { active, expired, pending, cancelled }

class Customer {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final DateTime registrationDate;
  final DateTime? membershipStartDate;
  final DateTime? membershipEndDate;
  final MembershipStatus status;
  final String? notes;
  final String? profileImageUrl;
  final List<String>? assignedPlans;
  final Map<String, dynamic>? measurements;
  final String? assignedTrainer;

  Customer({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.registrationDate,
    this.membershipStartDate,
    this.membershipEndDate,
    required this.status,
    this.notes,
    this.profileImageUrl,
    this.assignedPlans,
    this.measurements,
    this.assignedTrainer,
  });

  // Firestore'dan veri oluşturma
  factory Customer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Customer(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      registrationDate: (data['registrationDate'] as Timestamp).toDate(),
      membershipStartDate: data['membershipStartDate'] != null
          ? (data['membershipStartDate'] as Timestamp).toDate()
          : null,
      membershipEndDate: data['membershipEndDate'] != null
          ? (data['membershipEndDate'] as Timestamp).toDate()
          : null,
      status: MembershipStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => MembershipStatus.pending,
      ),
      notes: data['notes'],
      profileImageUrl: data['profileImageUrl'],
      assignedPlans: data['assignedPlans'] != null
          ? List<String>.from(data['assignedPlans'])
          : null,
      measurements: data['measurements'],
      assignedTrainer: data['assignedTrainer'],
    );
  }

  // Firestore'a veri kaydetme
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'registrationDate': Timestamp.fromDate(registrationDate),
      'membershipStartDate': membershipStartDate != null
          ? Timestamp.fromDate(membershipStartDate!)
          : null,
      'membershipEndDate': membershipEndDate != null
          ? Timestamp.fromDate(membershipEndDate!)
          : null,
      'status': status.toString().split('.').last,
      'notes': notes,
      'profileImageUrl': profileImageUrl,
      'assignedPlans': assignedPlans,
      'measurements': measurements,
      'assignedTrainer': assignedTrainer,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  // Müşteri bilgilerini güncelleme
  Customer copyWith({
    String? name,
    String? email,
    String? phone,
    DateTime? membershipStartDate,
    DateTime? membershipEndDate,
    MembershipStatus? status,
    String? notes,
    String? profileImageUrl,
    List<String>? assignedPlans,
    Map<String, dynamic>? measurements,
    String? assignedTrainer,
  }) {
    return Customer(
      id: this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      registrationDate: this.registrationDate,
      membershipStartDate: membershipStartDate ?? this.membershipStartDate,
      membershipEndDate: membershipEndDate ?? this.membershipEndDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      assignedPlans: assignedPlans ?? this.assignedPlans,
      measurements: measurements ?? this.measurements,
      assignedTrainer: assignedTrainer ?? this.assignedTrainer,
    );
  }
}
