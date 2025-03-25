import 'package:cloud_firestore/cloud_firestore.dart';

class Reminder {
  final String id;
  final String userId;
  final String title;
  final String description;
  final DateTime reminderDate;
  final bool isCompleted;
  final String? relatedEntityId; // Müşteri ID, Plan ID vb.
  final String? relatedEntityType; // 'customer', 'plan', 'equipment' vb.
  final bool isRecurring;
  final String? recurringPattern; // 'daily', 'weekly', 'monthly'

  Reminder({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.reminderDate,
    required this.isCompleted,
    this.relatedEntityId,
    this.relatedEntityType,
    required this.isRecurring,
    this.recurringPattern,
  });

  factory Reminder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Reminder(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      reminderDate: (data['reminderDate'] as Timestamp).toDate(),
      isCompleted: data['isCompleted'] ?? false,
      relatedEntityId: data['relatedEntityId'],
      relatedEntityType: data['relatedEntityType'],
      isRecurring: data['isRecurring'] ?? false,
      recurringPattern: data['recurringPattern'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'reminderDate': Timestamp.fromDate(reminderDate),
      'isCompleted': isCompleted,
      'relatedEntityId': relatedEntityId,
      'relatedEntityType': relatedEntityType,
      'isRecurring': isRecurring,
      'recurringPattern': recurringPattern,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }
}
