import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'dart:async'; // TimeoutException için
import 'log_service.dart'; // LogService import

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LogService _logService = LogService(); // LogService instance

  // Mevcut oturum açmış kullanıcıyı al
  User? get currentUser => _auth.currentUser;

  // Kullanıcı oturum açma durumunu izle
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // UserService içindeki registerWithEmailAndPassword metodu düzeltmesi:

  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password, String name,
      [UserRole? providedRole]) async {
    try {
      _logService.logInfo('UserService', 'Kayıt işlemi başlatılıyor: $email');

      // Firebase Auth ile kullanıcı oluştur
      _logService.logInfo(
          'UserService', 'Firebase Auth kullanıcısı oluşturuluyor...');

      final userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email,
            password: password,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException(
                'Firebase Auth işlemi zaman aşımına uğradı'),
          );

      _logService.logInfo('UserService',
          'Firebase Auth kullanıcısı oluşturuldu: ${userCredential.user?.uid}');

      // Kullanıcı bilgilerini Firestore'a kaydet
      if (userCredential.user != null) {
        try {
          _logService.logInfo('UserService', 'Firestore kaydı başlatılıyor...');

          // Rol belirleme
          UserRole role;

          if (providedRole != null) {
            role = providedRole;
          } else {
            // Admin e-posta listesi
            role = UserRole.customer; // Varsayılan rol
            final List<String> adminEmails = ['admin@hotmail.com'];

            // E-posta admin listesinde mi kontrol et
            if (adminEmails.contains(email.toLowerCase())) {
              role = UserRole.admin;
              _logService.logInfo('UserService', 'Admin rolü atandı: $email');
            }
          }

          // Veriyi daha küçük parçalara böl (önce sadece temel bilgiler)
          final basicUserData = {
            'email': email,
            'name': name,
            'role': role.toString().split('.').last,
            'createdAt': Timestamp.now(),
            'isActive': true,
          };

          // Temel kullanıcı verilerini kaydet - Hata olsa bile devam et
          _logService.logInfo(
              'UserService', 'Temel kullanıcı bilgileri kaydediliyor...');

          try {
            await _firestore
                .collection('users')
                .doc(userCredential.user!.uid)
                .set(basicUserData)
                .timeout(
              const Duration(seconds: 15),
              onTimeout: () {
                _logService.logWarning('UserService',
                    'Firestore yazma zaman aşımı - yine de devam ediliyor');
                return;
              },
            );
            _logService.logInfo('UserService', 'Firestore kaydı tamamlandı');
          } catch (firestoreWriteError) {
            // Firestore yazma hatası olsa bile kullanıcı oluşturuldu, devam et
            _logService.logWarning('UserService',
                'Firestore yazma hatası, ancak kullanıcı oluşturuldu: $firestoreWriteError');
          }

          return userCredential;
        } catch (firestoreError) {
          _logService.logError(
              'UserService', 'Firestore kayıt hatası: $firestoreError', null);

          // ÖNEMLİ: Burada kullanıcıyı silme kısmını kaldırdık
          // Firestore hatası olsa bile kullanıcı oluşturulduğu için başarılı sayıyoruz
          _logService.logWarning('UserService',
              'Firestore kaydı başarısız oldu ama kullanıcı oluşturuldu - yine de devam ediliyor');

          return userCredential;
        }
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      _logService.logError('UserService',
          'Firebase Auth hatası: ${e.code} - ${e.message}', null);
      rethrow;
    } catch (e) {
      _logService.logError('UserService', 'Beklenmeyen hata: $e', null);
      rethrow;
    }
  }

  // E-posta ve şifre ile oturum aç
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      _logService.logError('UserService', 'Giriş hatası: $e', null);
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      _logService.logError('UserService', 'Çıkış hatası: $e', null);
      rethrow;
    }
  }

  // Kullanıcı bilgilerini al
  Future<AppUser?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return AppUser.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Mevcut kullanıcının bilgilerini al - timeout ile
  Future<AppUser?> getCurrentUserData() async {
    if (currentUser == null) return null;

    try {
      final doc = await _runWithTimeout(
        _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .get(const GetOptions(source: Source.serverAndCache)),
        timeoutSeconds: 5,
      );

      if (doc.exists) {
        return AppUser.fromFirestore(doc);
      }
      return null;
    } on TimeoutException catch (e) {
      _logService.logWarning(
          'UserService', 'Kullanıcı bilgileri getirme zaman aşımı: $e');

      // Zaman aşımında cache'den okumayı dene
      try {
        final cachedDoc = await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .get(const GetOptions(source: Source.cache));

        if (cachedDoc.exists) {
          return AppUser.fromFirestore(cachedDoc);
        }
      } catch (cacheError) {
        _logService.logError(
            'UserService', 'Cache okuma hatası: $cacheError', null);
      }

      return null;
    } catch (e) {
      _logService.logError(
          'UserService', 'Kullanıcı bilgilerini getirme hatası: $e', null);
      return null;
    }
  }

  // Tüm kullanıcıları getir (sadece admin için)
  Future<List<AppUser>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList();
    } catch (e) {
      _logService.logError(
          'UserService', 'Kullanıcılar getirilirken hata: $e', null);
      rethrow;
    }
  }

  // Kullanıcı rolünü güncelle
  Future<void> updateUserRole(String userId, UserRole role) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': role.toString().split('.').last,
      });
    } catch (e) {
      _logService.logError(
          'UserService', 'Kullanıcı rolü güncellenirken hata: $e', null);
      rethrow;
    }
  }

  // Kullanıcı durumunu güncelle (aktif/pasif)
  Future<void> updateUserStatus(String userId, bool isActive) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': isActive,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Kullanıcı adını güncelle
  Future<bool> updateUserName(String userId, String name) async {
    if (name.trim().isEmpty) {
      return false;
    }

    try {
      await _firestore.collection('users').doc(userId).update({
        'name': name.trim(),
      });
      return true;
    } catch (e) {
      _logService.logError(
          'UserService', 'Kullanıcı adı güncellenirken hata: $e', null);
      return false;
    }
  }

  // Kullanıcı şifresini sıfırla
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      _logService.logError('UserService', 'Şifre sıfırlama hatası: $e', null);
      rethrow;
    }
  }

  // Anonim olarak giriş yap (test için)
  Future<UserCredential> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } catch (e) {
      print('Anonim giriş hatası: $e');
      rethrow;
    }
  }

  // Admin hesabının varlığını kontrol et ve gerekirse oluştur
  Future<void> ensureAdminExists() async {
    const String adminEmail = 'admin@hotmail.com'; // Belirtilen admin e-postası
    const String adminPassword = '123456'; // Belirtilen admin şifresi
    const String adminName = 'Admin Kullanıcı';

    try {
      // Admin e-postası ile kullanıcı var mı kontrol et
      final adminQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: adminEmail)
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get();

      if (adminQuery.docs.isEmpty) {
        _logService.logInfo(
            'UserService', 'Admin hesabı bulunamadı, oluşturuluyor...');

        try {
          // Önce giriş yapmayı dene (hesap varsa)
          await _auth.signInWithEmailAndPassword(
            email: adminEmail,
            password: adminPassword,
          );

          // Hesap var ama admin rolü atanmamış olabilir
          final currentUser = _auth.currentUser;
          if (currentUser != null) {
            await _firestore.collection('users').doc(currentUser.uid).update({
              'role': 'admin',
            });
            _logService.logInfo(
                'UserService', 'Mevcut hesap admin rolüne yükseltildi');
          }
        } catch (e) {
          // Hesap yoksa oluştur
          if (e is FirebaseAuthException && e.code == 'user-not-found') {
            await registerWithEmailAndPassword(
              adminEmail,
              adminPassword,
              adminName,
              UserRole.admin,
            );
            _logService.logInfo('UserService', 'Admin hesabı oluşturuldu');
          } else {
            _logService.logError(
                'UserService', 'Admin hesabı kontrol edilirken hata: $e', null);
          }
        }
      } else {
        _logService.logInfo('UserService', 'Admin hesabı zaten mevcut');
      }
    } catch (e) {
      _logService.logError(
          'UserService', 'Admin hesabı kontrolünde hata: $e', null);
    }
  }

  // Timeout ile Firestore işlemi çalıştırma yardımcı metodu
  Future<T> _runWithTimeout<T>(Future<T> operation,
      {int timeoutSeconds = 10}) async {
    return await operation.timeout(
      Duration(seconds: timeoutSeconds),
      onTimeout: () => throw TimeoutException(
          'İşlem zaman aşımına uğradı. Lütfen internet bağlantınızı kontrol edin.'),
    );
  }

  Future<bool> testFirestoreConnection() async {
    try {
      _logService.logInfo(
          'UserService', 'Firestore bağlantı testi başlatılıyor...');

      // Test verisi
      final testData = {
        'timestamp': FieldValue.serverTimestamp(),
        'test': 'Firestore bağlantı testi',
      };

      // Test koleksiyonu
      final testCollection = _firestore.collection('connection_test');
      final testDoc = testCollection
          .doc('test_doc_${DateTime.now().millisecondsSinceEpoch}');

      // Yazma testi - 8 saniye timeout ile
      await testDoc.set(testData).timeout(
            const Duration(seconds: 8),
            onTimeout: () =>
                throw TimeoutException('Firestore yazma testi zaman aşımı'),
          );

      // Silme testi - 3 saniye timeout ile
      await testDoc.delete().timeout(
            const Duration(seconds: 3),
            onTimeout: () =>
                throw TimeoutException('Firestore silme testi zaman aşımı'),
          );

      _logService.logInfo('UserService', 'Firestore bağlantı testi başarılı');
      return true;
    } catch (e) {
      _logService.logError(
          'UserService', 'Firestore bağlantı testi başarısız: $e', null);
      return false;
    }
  }

  // Kullanıcı silme
  Future<void> deleteUser(String userId) async {
    try {
      // Performans izleme
      final Trace trace = FirebasePerformance.instance.newTrace('deleteUser');
      await trace.start();

      // Firestore'dan kullanıcı verisini sil
      await _firestore.collection('users').doc(userId).delete();

      // Firebase Auth'dan kullanıcıyı sil (admin işlemi)
      // Not: Bu işlem için Firebase Functions kullanılması daha güvenlidir
      // Burada sadece Firestore verisi silinecek

      await trace.stop();
      _logService.logInfo('UserService', 'Kullanıcı silindi: $userId');
    } catch (e) {
      _logService.logError('UserService', 'Kullanıcı silme hatası: $e', null);
      rethrow;
    }
  }
}
