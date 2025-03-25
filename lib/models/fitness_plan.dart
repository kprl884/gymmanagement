import 'package:cloud_firestore/cloud_firestore.dart';

class Exercise {
  final String name;
  final String? description;
  final int sets;
  final int reps;
  final String? imageUrl;
  final String? videoUrl;
  final Map<String, dynamic>? additionalInfo;

  Exercise({
    required this.name,
    this.description,
    required this.sets,
    required this.reps,
    this.imageUrl,
    this.videoUrl,
    this.additionalInfo,
  });

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      name: map['name'] ?? '',
      description: map['description'],
      sets: map['sets'] ?? 0,
      reps: map['reps'] ?? 0,
      imageUrl: map['imageUrl'],
      videoUrl: map['videoUrl'],
      additionalInfo: map['additionalInfo'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'sets': sets,
      'reps': reps,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'additionalInfo': additionalInfo,
    };
  }
}

class FitnessPlan {
  final String id;
  final String name;
  final String description;
  final String createdBy;
  final DateTime createdAt;
  final String? imageUrl;
  final String difficulty; // 'beginner', 'intermediate', 'advanced'
  final int durationWeeks;
  final Map<String, List<Exercise>>
      exercises; // 'day1': [exercises], 'day2': [exercises]
  final List<String>? tags;
  final bool isPublic;

  FitnessPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.createdBy,
    required this.createdAt,
    this.imageUrl,
    required this.difficulty,
    required this.durationWeeks,
    required this.exercises,
    this.tags,
    required this.isPublic,
  });

  factory FitnessPlan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Egzersizleri dönüştür
    Map<String, List<Exercise>> exercisesMap = {};
    if (data['exercises'] != null) {
      final exercises = data['exercises'] as Map<String, dynamic>;
      exercises.forEach((day, exerciseList) {
        exercisesMap[day] = (exerciseList as List)
            .map((e) => Exercise.fromMap(e as Map<String, dynamic>))
            .toList();
      });
    }

    return FitnessPlan(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      imageUrl: data['imageUrl'],
      difficulty: data['difficulty'] ?? 'beginner',
      durationWeeks: data['durationWeeks'] ?? 4,
      exercises: exercisesMap,
      tags: data['tags'] != null ? List<String>.from(data['tags']) : null,
      isPublic: data['isPublic'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    // Egzersizleri dönüştür
    Map<String, List<Map<String, dynamic>>> exercisesMap = {};
    exercises.forEach((day, exerciseList) {
      exercisesMap[day] = exerciseList.map((e) => e.toMap()).toList();
    });

    return {
      'name': name,
      'description': description,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'imageUrl': imageUrl,
      'difficulty': difficulty,
      'durationWeeks': durationWeeks,
      'exercises': exercisesMap,
      'tags': tags,
      'isPublic': isPublic,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }
}
