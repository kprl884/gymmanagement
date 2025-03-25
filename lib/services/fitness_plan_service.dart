import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/fitness_plan.dart';
import 'log_service.dart';

class FitnessPlanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LogService _logService = LogService();

  // Tüm planları getir
  Future<List<FitnessPlan>> getAllPlans() async {
    try {
      final snapshot =
          await _firestore.collection('fitness_plans').orderBy('name').get();

      return snapshot.docs
          .map((doc) => FitnessPlan.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logService.logError(
          'FitnessPlanService', 'Planları getirme hatası: $e', null);
      return [];
    }
  }

  // Belirli bir planı getir
  Future<FitnessPlan?> getPlanById(String planId) async {
    try {
      final doc =
          await _firestore.collection('fitness_plans').doc(planId).get();

      if (doc.exists) {
        return FitnessPlan.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      _logService.logError(
          'FitnessPlanService', 'Plan detayı getirme hatası: $e', null);
      return null;
    }
  }

  // Yeni plan ekle
  Future<String?> addPlan(FitnessPlan plan) async {
    try {
      final docRef =
          await _firestore.collection('fitness_plans').add(plan.toFirestore());

      return docRef.id;
    } catch (e) {
      _logService.logError(
          'FitnessPlanService', 'Plan ekleme hatası: $e', null);
      return null;
    }
  }

  // Plan güncelle
  Future<bool> updatePlan(FitnessPlan plan) async {
    try {
      await _firestore
          .collection('fitness_plans')
          .doc(plan.id)
          .update(plan.toFirestore());

      return true;
    } catch (e) {
      _logService.logError(
          'FitnessPlanService', 'Plan güncelleme hatası: $e', null);
      return false;
    }
  }

  // Plan sil
  Future<bool> deletePlan(String planId) async {
    try {
      await _firestore.collection('fitness_plans').doc(planId).delete();

      return true;
    } catch (e) {
      _logService.logError('FitnessPlanService', 'Plan silme hatası: $e', null);
      return false;
    }
  }

  // Kullanıcının oluşturduğu planları getir
  Future<List<FitnessPlan>> getUserPlans(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('fitness_plans')
          .where('createdBy', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => FitnessPlan.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logService.logError('FitnessPlanService',
          'Kullanıcı planlarını getirme hatası: $e', null);
      return [];
    }
  }

  // Herkese açık planları getir
  Future<List<FitnessPlan>> getPublicPlans() async {
    try {
      final snapshot = await _firestore
          .collection('fitness_plans')
          .where('isPublic', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => FitnessPlan.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logService.logError('FitnessPlanService',
          'Herkese açık planları getirme hatası: $e', null);
      return [];
    }
  }
}
