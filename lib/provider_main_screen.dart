import 'package:flutter/material.dart';
import 'widgets/bottom_navigation_bar.dart';
import 'service_provider_feed_screen.dart';
// Import other screens as needed
// import 'provider_service_screen.dart';

/// Main navigation container for provider/vendor context.
/// This screen manages the bottom navigation bar and switches between different screens.
class ProviderMainScreen extends StatefulWidget {
  const ProviderMainScreen({super.key});

  @override
  State<ProviderMainScreen> createState() => _ProviderMainScreenState();
}

class _ProviderMainScreenState extends State<ProviderMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    // 0: Feed - Home screen
    const ServiceProviderFeedScreen(),
    // 1: My Jobs - Jobs list screen
    const Scaffold(
      body: Center(
        child: Text('My Jobs Screen - Coming Soon'),
      ),
    ),
    // 2: Chats - Messages screen
    const Scaffold(
      body: Center(
        child: Text('Chats Screen - Coming Soon'),
      ),
    ),
    // 3: Profile - User profile screen
    const Scaffold(
      body: Center(
        child: Text('Profile Screen - Coming Soon'),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main screen content with padding for nav bar
          Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: _screens[_currentIndex],
          ),
          // Sticky bottom navigation bar
          MuawinBottomNavigationBar(
            currentIndex: _currentIndex,
            onItemTapped: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ],
      ),
    );
  }
}
