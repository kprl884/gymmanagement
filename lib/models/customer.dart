import 'package:cloud_firestore/cloud_firestore.dart';

enum MembershipStatus { active, expired, pending, cancelled }

enum PaymentType { cash, installment }

class Customer {
  final String? id;
  final String name;
  final String surname;
  final String phone;
  final String email;
  final int age;
  final DateTime registrationDate;
  final DateTime? lastVisitDate;
  final int subscriptionMonths; // Abonelik süresi (ay)
  final PaymentType paymentType; // Ödeme tipi (peşin/taksitli)
  final List<DateTime> paidMonths; // Ödenen aylar (tarihler)
  final bool isActive;
  final MembershipStatus status;
  final String? notes;
  final String? profileImageUrl;
  final List<String>? assignedPlans;
  final Map<String, dynamic>? measurements;
  final String? assignedTrainer;

  Customer({
    this.id,
    required this.name,
    required this.surname,
    required this.phone,
    required this.email,
    required this.age,
    required this.registrationDate,
    this.lastVisitDate,
    required this.subscriptionMonths,
    required this.paymentType,
    required this.paidMonths,
    this.isActive = true,
    required this.status,
    this.notes,
    this.profileImageUrl,
    this.assignedPlans,
    this.measurements,
    this.assignedTrainer,
  });

  // Firestore'dan Customer oluştur
  factory Customer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Ödenen ayları Timestamp'ten DateTime'a dönüştür
    List<DateTime> paidMonths = [];
    if (data['paidMonths'] != null) {
      paidMonths = (data['paidMonths'] as List)
          .map((item) => (item as Timestamp).toDate())
          .toList();
    }

    return Customer(
      id: doc.id,
      name: data['name'] ?? '',
      surname: data['surname'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      age: data['age'] ?? 0,
      registrationDate: (data['registrationDate'] as Timestamp).toDate(),
      lastVisitDate: data['lastVisitDate'] != null
          ? (data['lastVisitDate'] as Timestamp).toDate()
          : null,
      subscriptionMonths: data['subscriptionMonths'] ?? 1,
      paymentType: data['paymentType'] == 'installment'
          ? PaymentType.installment
          : PaymentType.cash,
      paidMonths: paidMonths,
      isActive: data['isActive'] ?? true,
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

  // Customer'ı Firestore formatına dönüştür
  Map<String, dynamic> toFirestore() {
    // Ödenen ayları Timestamp'e dönüştür
    List<Timestamp> paidMonthsTimestamps =
        paidMonths.map((date) => Timestamp.fromDate(date)).toList();

    return {
      'name': name,
      'surname': surname,
      'phone': phone,
      'email': email,
      'age': age,
      'registrationDate': Timestamp.fromDate(registrationDate),
      'lastVisitDate':
          lastVisitDate != null ? Timestamp.fromDate(lastVisitDate!) : null,
      'subscriptionMonths': subscriptionMonths,
      'paymentType':
          paymentType == PaymentType.installment ? 'installment' : 'cash',
      'paidMonths': paidMonthsTimestamps,
      'isActive': isActive,
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
    String? surname,
    String? phone,
    String? email,
    int? age,
    DateTime? registrationDate,
    DateTime? lastVisitDate,
    int? subscriptionMonths,
    PaymentType? paymentType,
    List<DateTime>? paidMonths,
    bool? isActive,
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
      surname: surname ?? this.surname,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      age: age ?? this.age,
      registrationDate: registrationDate ?? this.registrationDate,
      lastVisitDate: lastVisitDate ?? this.lastVisitDate,
      subscriptionMonths: subscriptionMonths ?? this.subscriptionMonths,
      paymentType: paymentType ?? this.paymentType,
      paidMonths: paidMonths ?? this.paidMonths,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      assignedPlans: assignedPlans ?? this.assignedPlans,
      measurements: measurements ?? this.measurements,
      assignedTrainer: assignedTrainer ?? this.assignedTrainer,
    );
  }
}
