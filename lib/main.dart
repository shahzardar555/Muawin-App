import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'splash_screen.dart';
import 'customer_home_screen.dart';
import 'service_provider_feed_screen.dart';
import 'vendor_home_screen.dart';
import 'provider_document_verification_screen.dart';
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

  // Check if user is already logged in
  final session = Supabase.instance.client.auth.currentSession;
  final user = Supabase.instance.client.auth.currentUser;

  Widget homeScreen = const SplashScreen();

  if (session != null && user != null) {
    try {
      // Get user role from profiles table
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('id, role')
          .eq('user_id', user.id)
          .single();

      final role = profile['role']?.toString() ?? '';
      final profileId = profile['id']?.toString() ?? '';

      if (role == 'customer') {
        homeScreen = const CustomerHomeScreen();
      } else if (role == 'provider') {
        // Check verification status
        final provider = await Supabase.instance.client
            .from('providers')
            .select('is_verified')
            .eq('profile_id', profileId)
            .single();

        final isVerified = provider['is_verified'] == true;
        if (isVerified) {
          homeScreen = const ServiceProviderFeedScreen();
        } else {
          homeScreen = const ProviderDocumentVerificationScreen();
        }
      } else if (role == 'vendor') {
        homeScreen = const VendorHomeScreen();
      } else {
        homeScreen = const SplashScreen();
      }
    } catch (e) {
      debugPrint('Session restore error: $e');
      homeScreen = const SplashScreen();
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => LanguageProvider()),
        ChangeNotifierProvider(create: (context) => NotificationManager()),
        ChangeNotifierProvider(create: (context) => FeaturedAdManager()),
      ],
      child: MuawinApp(homeScreen: homeScreen),
    ),
  );
}

class MuawinApp extends StatefulWidget {
  final Widget homeScreen;
  const MuawinApp({super.key, required this.homeScreen});

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
    try {
      _appLinks = AppLinks();

      // Handle deep link when app is already open
      _appLinks.uriLinkStream.listen((uri) {
        try {
          if (uri.scheme == 'muawin' && uri.host == 'reset-password') {
            _navigatorKey.currentState?.pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => const UpdatePasswordScreen(),
              ),
              (route) => false,
            );
          }
        } catch (e) {
          debugPrint('Deep link navigation error: $e');
        }
      });

      // Handle deep link when app is launched from cold start
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null &&
          initialUri.scheme == 'muawin' &&
          initialUri.host == 'reset-password') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => const UpdatePasswordScreen(),
            ),
            (route) => false,
          );
        });
      }
    } catch (e) {
      debugPrint('Deep link init error: $e');
    }
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
          home: widget.homeScreen,
          routes: {
            '/customer/home': (context) => const CustomerHomeScreen(),
            '/notifications': (context) => const NotificationScreen(),
          },
        );
      },
    );
  }
}
