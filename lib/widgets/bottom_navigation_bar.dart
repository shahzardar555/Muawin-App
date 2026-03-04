import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MuawinBottomNavigationBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onItemTapped;

  const MuawinBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onItemTapped,
  });

  @override
  State<MuawinBottomNavigationBar> createState() =>
      _MuawinBottomNavigationBarState();
}

class _MuawinBottomNavigationBarState extends State<MuawinBottomNavigationBar>
    with TickerProviderStateMixin {
  late List<AnimationController> _itemAnimationControllers;
  late List<AnimationController> _pressControllers;

  // Note: third item is a special center action button
  final List<Map<String, dynamic>> navItems = [
    {
      'label': 'Home',
      'icon': Icons.home,
    },
    {
      'label': 'My Jobs',
      'icon': Icons.assignment,
    },
    {
      'label': 'Post a Job',
      'icon': Icons.add,
      'center': true, // will render as elevated circle
    },
    {
      'label': 'Chats',
      'icon': Icons.message,
    },
    {
      'label': 'Profile',
      'icon': Icons.person,
    },
  ];

  @override
  void initState() {
    super.initState();

    _itemAnimationControllers = List.generate(
      navItems.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      ),
    );

    _pressControllers = List.generate(
      navItems.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 150),
        vsync: this,
      ),
    );

    // Animate the initially active item
    _itemAnimationControllers[widget.currentIndex].forward();
  }

  @override
  void didUpdateWidget(MuawinBottomNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      // Reset previous item animation
      _itemAnimationControllers[oldWidget.currentIndex].reverse();
      // Start new item animation
      _itemAnimationControllers[widget.currentIndex].forward();
    }
  }

  @override
  void dispose() {
    for (var controller in _itemAnimationControllers) {
      controller.dispose();
    }
    for (var controller in _pressControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleTap(int index) {
    if (widget.currentIndex != index) {
      widget.onItemTapped(index);
    }
    // Trigger press animation
    _pressControllers[index].forward().then((_) {
      _pressControllers[index].reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final mutedForeground = Colors.grey[600] ?? Colors.grey;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.grey.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
        ),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 30,
                    offset: const Offset(0, -8),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(
                    navItems.length,
                    (index) {
                      final item = navItems[index];
                      if (item.containsKey('center') &&
                          item['center'] == true) {
                        // reserve space for center action button
                        return _buildCenterAction(
                            context, index, item, primaryColor);
                      }
                      return _buildNavItem(
                        context,
                        index,
                        item,
                        primaryColor,
                        mutedForeground,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    Map<String, dynamic> item,
    Color primaryColor,
    Color mutedForeground,
  ) {
    final isActive = widget.currentIndex == index;
    final animationController = _itemAnimationControllers[index];
    final pressController = _pressControllers[index];

    return GestureDetector(
      onTap: () => _handleTap(index),
      child: AnimatedBuilder(
        animation: Listenable.merge([animationController, pressController]),
        builder: (context, child) {
          // Calculate scales from both animations
          final zoomScale = 0.9 + (animationController.value * 0.1);
          final pressScale = 1.0 - (pressController.value * 0.05);
          final combinedScale = zoomScale * pressScale;

          return Transform.scale(
            scale: combinedScale,
            child: Container(
              constraints: const BoxConstraints(minWidth: 64),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Icon(
                          item['icon'],
                          size: 24,
                          color: isActive
                              ? primaryColor
                              : mutedForeground.withValues(alpha: 0.7),
                          semanticLabel: item['label'],
                        ),
                      ),
                      // Active indicator dot
                      if (isActive)
                        Positioned(
                          bottom: 0,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0, end: 1).animate(
                              CurvedAnimation(
                                parent: animationController,
                                curve: Curves.elasticOut,
                              ),
                            ),
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['label'],
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isActive
                          ? primaryColor
                          : mutedForeground.withValues(alpha: 0.7),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCenterAction(
    BuildContext context,
    int index,
    Map<String, dynamic> item,
    Color primaryColor,
  ) {
    // Elevated circular button that sits above the bar
    return GestureDetector(
      onTap: () => _handleTap(index),
      child: Container(
        width: 60,
        height: 60,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: primaryColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          item['icon'],
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
