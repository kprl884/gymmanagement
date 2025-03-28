import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer.dart';
import 'log_service.dart';
import 'dart:async';

class CustomerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LogService _logService = LogService();

  // Tüm müşterileri getir - önbellek kullanarak
  Future<List<Customer>> getAllCustomers() async {
    try {
      // Önce önbellekten veriyi al, sonra sunucudan güncelle
      final snapshot = await _firestore
          .collection('customers')
          .get(const GetOptions(source: Source.serverAndCache));

      return snapshot.docs.map((doc) => Customer.fromFirestore(doc)).toList();
    } catch (e) {
      _logService.logError(
          'CustomerService', 'Müşterileri getirme hatası: $e', null);
      rethrow;
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

  // Müşteri ekle
  Future<void> addCustomer(Customer customer) async {
    try {
      print("CustomerService: addCustomer başladı");

      // Firestore'a ekleme işlemini tamamla ve dönen belge referansını al
      final docRef = await _firestore.collection('customers').add(customer.toFirestore());

      print("CustomerService: addCustomer başarılı, ID: ${docRef.id}");

      return; // Başarılı ise fonksiyondan çık
    } catch (e) {
      print("CustomerService: addCustomer hatası: $e");
      _logService.logError(
          'CustomerService', 'Müşteri ekleme hatası: $e', null);
      rethrow; // Hatayı yeniden fırlat
    }
  }

  // Müşteri güncelle
  Future<void> updateCustomer(Customer customer) async {
    try {
      if (customer.id == null) {
        throw Exception('Müşteri ID boş olamaz');
      }

      await _firestore.collection('customers').doc(customer.id).update(
            customer.toFirestore(),
          );
    } catch (e) {
      _logService.logError(
          'CustomerService', 'Müşteri güncellenirken hata: $e', null);
      rethrow;
    }
  }

  // Müşteri sil
  Future<void> deleteCustomer(String customerId) async {
    try {
      await _firestore.collection('customers').doc(customerId).delete();
    } catch (e) {
      _logService.logError('CustomerService', 'Müşteri silme hatası: $e', null);
      rethrow;
    }
  }

  // Sadece aktif müşterileri getir
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
      rethrow;
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

  // Müşteri durumunu güncelle (aktif/pasif)
  Future<void> updateCustomerStatus(String customerId, bool isActive) async {
    try {
      await _firestore
          .collection('customers')
          .doc(customerId)
          .update({'isActive': isActive});
    } catch (e) {
      _logService.logError(
          'CustomerService', 'Müşteri durumu güncelleme hatası: $e', null);
      rethrow;
    }
  }

  // Ödenen taksit sayısını güncelle
  Future<void> updatePaidInstallments(
      String customerId, int paidInstallments) async {
    try {
      await _firestore.collection('customers').doc(customerId).update({
        'paidInstallments': paidInstallments,
      });
    } catch (e) {
      _logService.logError(
          'CustomerService', 'Taksit güncelleme hatası: $e', null);
      rethrow;
    }
  }

  // Ödenen ayları güncelle
  Future<void> updatePaidMonths(
      String customerId, List<DateTime> paidMonths) async {
    try {
      // DateTime'ları Timestamp'e dönüştür
      List<Timestamp> paidMonthsTimestamps =
          paidMonths.map((date) => Timestamp.fromDate(date)).toList();

      await _firestore.collection('customers').doc(customerId).update({
        'paidMonths': paidMonthsTimestamps,
      });
    } catch (e) {
      _logService.logError(
          'CustomerService', 'Ödenen aylar güncellenirken hata: $e', null);
      rethrow;
    }
  }

  // Sayfalı müşteri getirme
  Future<List<Customer>> getCustomersPaginated(int limit,
      [DocumentSnapshot? lastDocument]) async {
    try {
      Query query = _firestore.collection('customers').limit(limit);

      // Eğer son belge varsa, ondan sonrasını getir
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => Customer.fromFirestore(doc)).toList();
    } catch (e) {
      _logService.logError(
          'CustomerService', 'Sayfalı müşteri getirme hatası: $e', null);
      rethrow;
    }
  }
}
