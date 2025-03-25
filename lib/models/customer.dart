import 'package:cloud_firestore/cloud_firestore.dart';

enum MembershipStatus { active, expired, pending, cancelled }

enum PaymentType { cash, installment }

class Customer {
  final String? id;
  final String name;
  final String phone;
  final String email;
  final DateTime registrationDate;
  final DateTime? lastVisitDate;
  final int subscriptionMonths; // Abonelik süresi (ay)
  final PaymentType paymentType; // Ödeme tipi (peşin/taksitli)
  final int paidInstallments; // Ödenen taksit sayısı
  final int totalInstallments; // Toplam taksit sayısı
  final bool isActive;
  final DateTime? membershipStartDate;
  final DateTime? membershipEndDate;
  final MembershipStatus status;
  final String? notes;
  final String? profileImageUrl;
  final List<String>? assignedPlans;
  final Map<String, dynamic>? measurements;
  final String? assignedTrainer;

  Customer({
    this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.registrationDate,
    this.lastVisitDate,
    required this.subscriptionMonths,
    required this.paymentType,
    required this.paidInstallments,
    required this.totalInstallments,
    this.isActive = true,
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
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      registrationDate: (data['registrationDate'] as Timestamp).toDate(),
      lastVisitDate: data['lastVisitDate'] != null
          ? (data['lastVisitDate'] as Timestamp).toDate()
          : null,
      subscriptionMonths: data['subscriptionMonths'] ?? 1,
      paymentType: data['paymentType'] == 'installment'
          ? PaymentType.installment
          : PaymentType.cash,
      paidInstallments: data['paidInstallments'] ?? 0,
      totalInstallments: data['totalInstallments'] ?? 1,
      isActive: data['isActive'] ?? true,
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
      'phone': phone,
      'email': email,
      'registrationDate': Timestamp.fromDate(registrationDate),
      'lastVisitDate':
          lastVisitDate != null ? Timestamp.fromDate(lastVisitDate!) : null,
      'subscriptionMonths': subscriptionMonths,
      'paymentType':
          paymentType == PaymentType.installment ? 'installment' : 'cash',
      'paidInstallments': paidInstallments,
      'totalInstallments': totalInstallments,
      'isActive': isActive,
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
    String? phone,
    String? email,
    DateTime? registrationDate,
    DateTime? lastVisitDate,
    int? subscriptionMonths,
    PaymentType? paymentType,
    int? paidInstallments,
    int? totalInstallments,
    bool? isActive,
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
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      registrationDate: registrationDate ?? this.registrationDate,
      lastVisitDate: lastVisitDate ?? this.lastVisitDate,
      subscriptionMonths: subscriptionMonths ?? this.subscriptionMonths,
      paymentType: paymentType ?? this.paymentType,
      paidInstallments: paidInstallments ?? this.paidInstallments,
      totalInstallments: totalInstallments ?? this.totalInstallments,
      isActive: isActive ?? this.isActive,
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
