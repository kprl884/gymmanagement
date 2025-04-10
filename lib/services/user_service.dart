import 'dart:async'; // TimeoutException için import
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'log_service.dart'; // LogService import
import '../utils/navigation.dart'; // navigatorKey için import

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
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      _logService.logInfo('UserService',
          'Firebase Auth kullanıcısı oluşturuldu: ${userCredential.user?.uid}');

      // Kullanıcı bilgilerini Firestore'a kaydet
      if (userCredential.user != null) {
        try {
          // Rol belirleme
          UserRole role;

          // Eğer rol belirtilmişse onu kullan
          if (providedRole != null) {
            role = providedRole;
            _logService.logInfo('UserService', 'Belirtilen rol atandı: $role');
          } else {
            // Admin e-posta listesi
            final List<String> adminEmails = [
              'admin@hotmail.com',
              'admin_alfa@example.com'
            ];

            // E-posta admin listesinde mi kontrol et (küçük harfe çevirerek)
            if (adminEmails.contains(email.toLowerCase())) {
              role = UserRole.admin;
              _logService.logInfo('UserService',
                  'Admin e-postası tespit edildi, admin rolü atanıyor: $email');
            } else {
              role = UserRole.customer; // Varsayılan rol
              _logService.logInfo('UserService',
                  'Standart e-posta, müşteri rolü atanıyor: $email');
            }
          }

          // Rol değerini string olarak kaydet
          final String roleString = role.toString().split('.').last;
          _logService.logInfo('UserService', 'Kaydedilecek rol: $roleString');

          // Veriyi Firestore'a kaydet
          final userData = {
            'email': email,
            'name': name,
            'surname': '', // Varsayılan boş soyad
            'role': roleString,
            'createdAt': Timestamp.now(),
            'isActive': true,
          };

          // Firestore'a yazma işlemi
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set(userData);

          _logService.logInfo('UserService',
              'Kullanıcı Firestore\'a kaydedildi, rol: $roleString');

          return userCredential;
        } catch (e) {
          _logService.logError(
              'UserService', 'Firestore kayıt hatası: $e', null);
          rethrow;
        }
      }

      return userCredential;
    } catch (e) {
      _logService.logError('UserService', 'Kullanıcı kayıt hatası: $e', null);
      rethrow;
    }
  }

  // E-posta ve şifre ile oturum aç
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      // Firebase Auth ile giriş yap
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Kullanıcı hesabının aktif olup olmadığını kontrol et
      final userData = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (userData.exists) {
        final isActive = userData.data()?['isActive'] ?? true;

        if (!isActive) {
          // Kullanıcı pasif ise, oturumu kapat ve hata fırlat
          await _auth.signOut();
          throw Exception(
              'Hesabınız pasif durumda. Lütfen yönetici ile iletişime geçin.');
        }
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      _logService.logError(
          'UserService', 'Oturum açma hatası: ${e.code} - ${e.message}', null);
      rethrow;
    } catch (e) {
      _logService.logError('UserService', 'Beklenmeyen hata: $e', null);
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      _logService.logInfo('UserService', 'Çıkış işlemi başlatılıyor');

      if (kIsWeb) {
        // Web platformunda daha güvenli çıkış işlemi
        try {
          await _auth.signOut();
          _logService.logInfo('UserService', 'Web platformunda çıkış yapıldı');
        } catch (e) {
          _logService.logError('UserService', 'Web çıkış hatası: $e', null);
          // Web'de çıkış hatası olsa bile devam et
        }
      } else {
        // Mobil platformda çıkış işlemi
        await _auth.signOut();
        _logService.logInfo('UserService', 'Mobil platformda çıkış yapıldı');
      }

      // Navigasyon işlemi
      _logService.logInfo('UserService', 'Login sayfasına yönlendiriliyor');
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      } else {
        _logService.logError(
            'UserService', 'navigatorKey.currentState null', null);
      }
    } catch (e) {
      _logService.logError('UserService', 'Çıkış işlemi genel hata: $e', null);

      // Hata olsa bile yönlendirme yapmaya çalış
      try {
        if (navigatorKey.currentState != null) {
          navigatorKey.currentState!.pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
        }
      } catch (navError) {
        _logService.logError(
            'UserService', 'Navigasyon hatası: $navError', null);
      }
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

  // Mevcut kullanıcının verilerini getir
  Future<AppUser?> getCurrentUserData() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return null;
      }

      final doc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (!doc.exists) {
        _logService.logWarning('UserService',
            'Kullanıcı Firestore\'da bulunamadı: ${currentUser.uid}');
        return null;
      }

      // Kullanıcı verilerini al
      final userData = AppUser.fromFirestore(doc);

      // Rol bilgisini kontrol et ve logla
      _logService.logInfo('UserService',
          'Kullanıcı rolü: ${userData.role}, email: ${userData.email}');

      return userData;
    } catch (e) {
      _logService.logError(
          'UserService', 'Kullanıcı verisi getirme hatası: $e', null);
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
      // Önce mevcut kullanıcının admin olup olmadığını kontrol et
      final currentUserData = await getCurrentUserData();
      if (currentUserData?.role != UserRole.admin) {
        throw Exception('Bu işlemi gerçekleştirmek için yetkiniz yok.');
      }

      await _firestore.collection('users').doc(userId).update({
        'role': role.toString().split('.').last,
      });
    } catch (e) {
      if (e is FirebaseException && e.code == 'permission-denied') {
        _logService.logError('UserService',
            'İzin hatası: Bu işlemi gerçekleştirmek için yetkiniz yok.', null);
        throw Exception('Bu işlemi gerçekleştirmek için yetkiniz yok.');
      } else {
        _logService.logError(
            'UserService', 'Kullanıcı rolü güncellenirken hata: $e', null);
        rethrow;
      }
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
