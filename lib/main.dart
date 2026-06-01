import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'splash_screen.dart';
import 'customer_home_screen.dart';
import 'theme_provider.dart';
import 'language_provider.dart';
import 'services/notification_manager.dart';
import 'services/featured_ad_manager.dart';
import 'screens/notification_screen.dart';
import 'config/supabase_config.dart';
import 'update_password_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

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

class MuawinApp extends StatefulWidget {
  const MuawinApp({super.key});

  @override
  State<MuawinApp> createState() => _MuawinAppState();
}

class _MuawinAppState extends State<MuawinApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();
    _appLinks.uriLinkStream.listen((uri) {
      if (uri.scheme == 'muawin' && uri.host == 'reset-password') {
        _navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const UpdatePasswordScreen(),
          ),
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          navigatorKey: _navigatorKey,
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
