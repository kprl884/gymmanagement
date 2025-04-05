import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'services/notification_service.dart';
import 'services/user_service.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:provider/provider.dart';
import 'services/theme_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/setup_screen.dart';
import 'services/scheduled_task_service.dart';
import 'screens/splash_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase başlat
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Firestore ayarlarını yapılandır
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true, // Çevrimdışı önbelleğe alma
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED, // Sınırsız önbellek
  );

  // Uygulama ilk kez çalıştırılıyor mu kontrol et
  final prefs = await SharedPreferences.getInstance();
  final isFirstRun = prefs.getBool('first_run') ?? true;

  if (isFirstRun) {
    // İlk çalıştırmada admin hesabı oluştur
    final userService = UserService();
    await userService.ensureAdminExists();

    // İlk çalıştırma bayrağını güncelle
    await prefs.setBool('first_run', false);
  }

  // Firebase Performance'ı başlat
  FirebasePerformance.instance.setPerformanceCollectionEnabled(true);

  // Bildirim servisini başlat
  final notificationService = NotificationService();
  await notificationService.init();

  // Tarih formatlamasını başlat
  await initializeDateFormatting('tr_TR', null);

  // Scheduled task servisini başlat
  final scheduledTaskService = ScheduledTaskService();
  scheduledTaskService.startScheduledTasks();

  // Uygulama başladığında anlık kontrol yap
  scheduledTaskService.runImmediateChecks();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeService(),
        ),
        // Diğer provider'ları buraya ekleyebilirsiniz
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Gym Management',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const SplashScreen(),
        routes: {
          '/dashboard': (context) => DashboardScreen(),
          '/homeScreen': (context) => const HomeScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final UserService userService = UserService();

    return StreamBuilder<User?>(
      stream: userService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
