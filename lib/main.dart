import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'splash_screen.dart';
import 'customer_home_screen.dart';
import 'theme_provider.dart';
import 'language_provider.dart';
import 'services/notification_manager.dart';
import 'services/featured_ad_manager.dart';
import 'screens/notification_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  // Handle async errors not caught by Flutter
  List<String> errorLog = [];

  void logError(String error) async {
    final prefs = await SharedPreferences.getInstance();
    errorLog.add(error);
    await prefs.setStringList('error_log', errorLog);
  }

  // Load previous error log
  final prefs = await SharedPreferences.getInstance();
  errorLog = prefs.getStringList('error_log') ?? [];

  // Add global error handling to prevent crashes
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
    // Log error but don't crash the app
    final errorStr = 'Flutter Error: ${details.exception}\n${details.stack}';
    debugPrint(errorStr);
    logError(errorStr);
  };

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => LanguageProvider()),
        ChangeNotifierProvider(create: (context) => NotificationManager()),
        ChangeNotifierProvider(create: (context) => FeaturedAdManager()),
      ],
      child: const MuawinApp(),
    ),
  );
}

class MuawinApp extends StatelessWidget {
  const MuawinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Muawin',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.currentTheme,
          home: const SplashScreen(),
          routes: {
            '/customer/home': (context) => const CustomerHomeScreen(),
            '/notifications': (context) => const NotificationScreen(),
          },
        );
      },
    );
  }
}
