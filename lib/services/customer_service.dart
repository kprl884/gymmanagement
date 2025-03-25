import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer.dart';
import 'log_service.dart';
import 'dart:async';

class CustomerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LogService _logService = LogService();

  // Tüm müşterileri getir
  Future<List<Customer>> getAllCustomers() async {
    try {
      final snapshot =
          await _firestore.collection('customers').orderBy('name').get();

      return snapshot.docs.map((doc) => Customer.fromFirestore(doc)).toList();
    } catch (e) {
      _logService.logError(
          'CustomerService', 'Müşterileri getirme hatası: $e', null);
      return [];
    }
  }

  // Müşteri detaylarını getir
  Future<Customer?> getCustomerById(String customerId) async {
    try {
      final doc =
          await _firestore.collection('customers').doc(customerId).get();

      if (doc.exists) {
        return Customer.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      _logService.logError(
          'CustomerService', 'Müşteri detayı getirme hatası: $e', null);
      return null;
    }
  }

  // Yeni müşteri ekle
  Future<String?> addCustomer(Customer customer) async {
    try {
      final docRef =
          await _firestore.collection('customers').add(customer.toFirestore());

      return docRef.id;
    } catch (e) {
      _logService.logError(
          'CustomerService', 'Müşteri ekleme hatası: $e', null);
      return null;
    }
  }

  // Müşteri bilgilerini güncelle
  Future<bool> updateCustomer(Customer customer) async {
    try {
      await _firestore
          .collection('customers')
          .doc(customer.id)
          .update(customer.toFirestore());

      return true;
    } catch (e) {
      _logService.logError(
          'CustomerService', 'Müşteri güncelleme hatası: $e', null);
      return false;
    }
  }

  // Müşteri sil
  Future<bool> deleteCustomer(String customerId) async {
    try {
      await _firestore.collection('customers').doc(customerId).delete();

      return true;
    } catch (e) {
      _logService.logError('CustomerService', 'Müşteri silme hatası: $e', null);
      return false;
    }
  }

  // Aktif üyelikleri getir
  Future<List<Customer>> getActiveCustomers() async {
    try {
      final snapshot = await _firestore
          .collection('customers')
          .where('status', isEqualTo: 'active')
          .get();

      return snapshot.docs.map((doc) => Customer.fromFirestore(doc)).toList();
    } catch (e) {
      _logService.logError(
          'CustomerService', 'Aktif müşterileri getirme hatası: $e', null);
      return [];
    }
  }

  // Süresi yakında dolacak üyelikleri getir
  Future<List<Customer>> getExpiringMemberships() async {
    final now = DateTime.now();
    final oneWeekLater = now.add(const Duration(days: 7));

    try {
      final snapshot = await _firestore
          .collection('customers')
          .where('status', isEqualTo: 'active')
          .where('membershipEndDate',
              isLessThanOrEqualTo: Timestamp.fromDate(oneWeekLater))
          .where('membershipEndDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .get();

      return snapshot.docs.map((doc) => Customer.fromFirestore(doc)).toList();
    } catch (e) {
      _logService.logError('CustomerService',
          'Süresi dolacak üyelikleri getirme hatası: $e', null);
      return [];
    }
  }
}
