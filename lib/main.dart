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
import 'utils/navigation.dart';
import 'services/session_timeout_service.dart';
import 'widgets/activity_detector.dart';
import 'utils/activity_route_observer.dart';
import 'widgets/auth_guard.dart';

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

  // Oturum zaman aşımı servisini başlat
  final sessionTimeoutService = SessionTimeoutService();
  await sessionTimeoutService.init();

  // Route observer'ı oluştur
  final routeObserver = ActivityRouteObserver(sessionTimeoutService);

  runApp(MyApp(routeObserver: routeObserver));
}

class MyApp extends StatelessWidget {
  final RouteObserver<ModalRoute<dynamic>> routeObserver;

  const MyApp({
    Key? key,
    required this.routeObserver,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeService(),
        ),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return ActivityDetector(
            child: MaterialApp(
              navigatorKey: navigatorKey,
              navigatorObservers: [routeObserver],
              debugShowCheckedModeBanner: false,
              title: 'Gym Management',
              theme: ThemeData(
                primarySwatch: Colors.blue,
                brightness: Brightness.light,
                visualDensity: VisualDensity.adaptivePlatformDensity,
              ),
              darkTheme: ThemeData(
                primarySwatch: Colors.blue,
                brightness: Brightness.dark,
                visualDensity: VisualDensity.adaptivePlatformDensity,
              ),
              themeMode:
                  themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
              home: const SplashScreen(),
              routes: {
                '/dashboard': (context) => AuthGuard(child: DashboardScreen()),
                '/login': (context) => AuthGuard(
                      child: LoginScreen(),
                      requireAuth: false,
                    ),
                '/home_screen': (context) =>
                    AuthGuard(child: const HomeScreen()),
              },
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('tr', 'TR'),
              ],
            ),
          );
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
