import 'package:cloud_firestore/cloud_firestore.dart';

class Equipment {
  final String id;
  final String name;
  final String description;
  final String category; // 'cardio', 'strength', 'flexibility', etc.
  final String? imageUrl;
  final String? videoUrl;
  final String? instructions;
  final List<String>? targetMuscles;
  final bool isAvailable;
  final String? location; // Salon içindeki konumu
  final DateTime? lastMaintenanceDate;
  final String? maintenanceNotes;

  Equipment({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.imageUrl,
    this.videoUrl,
    this.instructions,
    this.targetMuscles,
    required this.isAvailable,
    this.location,
    this.lastMaintenanceDate,
    this.maintenanceNotes,
  });

  factory Equipment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Equipment(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      imageUrl: data['imageUrl'],
      videoUrl: data['videoUrl'],
      instructions: data['instructions'],
      targetMuscles: data['targetMuscles'] != null
          ? List<String>.from(data['targetMuscles'])
          : null,
      isAvailable: data['isAvailable'] ?? true,
      location: data['location'],
      lastMaintenanceDate: data['lastMaintenanceDate'] != null
          ? (data['lastMaintenanceDate'] as Timestamp).toDate()
          : null,
      maintenanceNotes: data['maintenanceNotes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'instructions': instructions,
      'targetMuscles': targetMuscles,
      'isAvailable': isAvailable,
      'location': location,
      'lastMaintenanceDate': lastMaintenanceDate != null
          ? Timestamp.fromDate(lastMaintenanceDate!)
          : null,
      'maintenanceNotes': maintenanceNotes,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }
}
