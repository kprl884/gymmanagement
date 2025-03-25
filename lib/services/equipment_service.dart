import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/equipment.dart';
import 'log_service.dart';

class EquipmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LogService _logService = LogService();

  // Tüm ekipmanları getir
  Future<List<Equipment>> getAllEquipment() async {
    try {
      final snapshot =
          await _firestore.collection('equipment').orderBy('name').get();

      return snapshot.docs.map((doc) => Equipment.fromFirestore(doc)).toList();
    } catch (e) {
      _logService.logError(
          'EquipmentService', 'Ekipmanları getirme hatası: $e', null);
      return [];
    }
  }

  // Belirli bir ekipmanı getir
  Future<Equipment?> getEquipmentById(String equipmentId) async {
    try {
      final doc =
          await _firestore.collection('equipment').doc(equipmentId).get();

      if (doc.exists) {
        return Equipment.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      _logService.logError(
          'EquipmentService', 'Ekipman detayı getirme hatası: $e', null);
      return null;
    }
  }

  // Yeni ekipman ekle
  Future<String?> addEquipment(Equipment equipment) async {
    try {
      final docRef =
          await _firestore.collection('equipment').add(equipment.toFirestore());

      return docRef.id;
    } catch (e) {
      _logService.logError(
          'EquipmentService', 'Ekipman ekleme hatası: $e', null);
      return null;
    }
  }

  // Ekipman güncelle
  Future<bool> updateEquipment(Equipment equipment) async {
    try {
      await _firestore
          .collection('equipment')
          .doc(equipment.id)
          .update(equipment.toFirestore());

      return true;
    } catch (e) {
      _logService.logError(
          'EquipmentService', 'Ekipman güncelleme hatası: $e', null);
      return false;
    }
  }

  // Ekipman sil
  Future<bool> deleteEquipment(String equipmentId) async {
    try {
      await _firestore.collection('equipment').doc(equipmentId).delete();

      return true;
    } catch (e) {
      _logService.logError(
          'EquipmentService', 'Ekipman silme hatası: $e', null);
      return false;
    }
  }

  // Kategoriye göre ekipmanları getir
  Future<List<Equipment>> getEquipmentByCategory(String category) async {
    try {
      final snapshot = await _firestore
          .collection('equipment')
          .where('category', isEqualTo: category)
          .get();

      return snapshot.docs.map((doc) => Equipment.fromFirestore(doc)).toList();
    } catch (e) {
      _logService.logError('EquipmentService',
          'Kategoriye göre ekipman getirme hatası: $e', null);
      return [];
    }
  }

  // Kullanılabilir ekipmanları getir
  Future<List<Equipment>> getAvailableEquipment() async {
    try {
      final snapshot = await _firestore
          .collection('equipment')
          .where('isAvailable', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) => Equipment.fromFirestore(doc)).toList();
    } catch (e) {
      _logService.logError('EquipmentService',
          'Kullanılabilir ekipmanları getirme hatası: $e', null);
      return [];
    }
  }
}
