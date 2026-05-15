import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:geolocator/geolocator.dart';

import 'package:muawin_app/customer_home_screen.dart';

import 'package:muawin_app/widgets/bottom_navigation_bar.dart';

import 'package:muawin_app/widgets/muawin_pro_badge.dart';

import 'package:muawin_app/services/pro_status_checker.dart';

import 'customer_jobs_screen.dart';

import 'customer_profile_screen.dart';

import 'customer_messages_screen.dart';

import 'post_job_screen.dart';

import 'package:muawin_app/post_job_step3_screen.dart';

class PostJobStep1Screen extends StatefulWidget {
  const PostJobStep1Screen({super.key, this.selectedCategory});

  final String? selectedCategory;

  @override
  State<PostJobStep1Screen> createState() => _PostJobStep1ScreenState();
}

class _PostJobStep1ScreenState extends State<PostJobStep1Screen>
    with TickerProviderStateMixin {
  late AnimationController _slideInController;

  late Animation<Offset> _slideInAnimation;

  Map<String, dynamic>? _selectedCategory;

  final TextEditingController _descriptionController = TextEditingController();

  // PRO status

  bool _isProUser = false;

  // PRO-only job options

  String? _selectedJobType; // 'one_time', 'hire_only'

  bool _isPriorityJob = false;

  DateTime? _hireStartDate;

  DateTime? _hireEndDate;

  TimeOfDay? _hireStartTime;

  TimeOfDay? _hireEndTime;

  // Service categories for selection - matching provider registration format

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Maid', 'icon': Icons.cleaning_services_rounded},
    {'name': 'Driver', 'icon': Icons.drive_eta_rounded},
    {'name': 'Babysitter', 'icon': Icons.child_care_rounded},
    {'name': 'Security Guard', 'icon': Icons.security_rounded},
    {'name': 'Washerman', 'icon': Icons.local_laundry_service_rounded},
    {'name': 'Domestic Helper', 'icon': Icons.home_repair_service_rounded},
    {'name': 'Cook', 'icon': Icons.restaurant_rounded},
    {'name': 'Gardener', 'icon': Icons.yard_rounded},
    {'name': 'Tutor', 'icon': Icons.school_rounded},
  ];

  bool get isButtonEnabled =>
      _selectedCategory != null && _descriptionController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();

    _slideInController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideInAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideInController,
      curve: Curves.easeOut,
    ));

    // Auto-select category if provided

    if (widget.selectedCategory != null) {
      _selectedCategory = _categories.firstWhere(
        (category) =>
            category['name'].toString().toUpperCase() ==
            widget.selectedCategory!.toUpperCase(),
        orElse: () => <String, dynamic>{},
      );

      // Only set if we actually found a category

      if (_selectedCategory!.isEmpty) {
        _selectedCategory = null;
      }
    }

    _slideInController.forward();

    _checkProStatus();
  }

  // Check if user is a PRO user

  Future<void> _checkProStatus() async {
    final isPro = await ProStatusChecker.isProUser();

    if (mounted) {
      setState(() {
        _isProUser = isPro;
      });
    }
  }

  @override
  void dispose() {
    _slideInController.dispose();

    _descriptionController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SlideTransition(
        position: _slideInAnimation,
        child: SafeArea(
          child: Column(
            children: [
              // Header Section

              _buildHeader(primaryColor),

              // Main Content

              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 32), // space-y-8 (2rem)

                        // Category Selection Grid

                        _buildCategorySection(primaryColor),

                        const SizedBox(height: 32), // space-y-8 (2rem)

                        // Task Description Input

                        _buildTaskDescriptionSection(primaryColor),

                        const SizedBox(height: 32), // space-y-8 (2rem)

                        // PRO-Only Options Section

                        if (_isProUser) ...[
                          _buildProOptionsSection(primaryColor),
                          const SizedBox(height: 32),
                        ],

                        // Bottom CTA (moved here to be scrollable)

                        _buildBottomCTA(primaryColor),

                        // Bottom Padding to clear navigation bar

                        const SizedBox(height: 128), // 8rem
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: MuawinBottomNavigationBar(
        currentIndex: 2, // Post Job tab selected

        onItemTapped: (i) {
          if (i == 0) {
            // Navigate to Home screen

            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
            );
          } else if (i == 1) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CustomerJobsScreen()),
            );
          } else if (i == 2) {
            // Current screen, no action needed
          } else if (i == 3) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CustomerMessagesScreen()),
            );
          } else if (i == 4) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CustomerProfileScreen()),
            );
          }
        },
      ),
    );
  }

  Widget _buildHeader(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8), // space-y-2

          // Step Progress Indicator

          Row(
            children: [
              // Step 1 (Active)

              AnimatedContainer(
                duration: const Duration(milliseconds: 500),

                width: 40, // w-10

                height: 8,

                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),

              // Step 2 (Inactive)

              Expanded(
                child: Container(
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              // Step 3 (Inactive)

              AnimatedContainer(
                duration: const Duration(milliseconds: 500),

                width: 16, // w-4

                height: 8,

                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Headline

          Text(
            'Describe your task',
            style: GoogleFonts.poppins(
              fontSize: 30, // text-3xl

              fontWeight: FontWeight.w700, // Bold

              letterSpacing: -0.5, // tracking-tight

              color: Colors.black,
            ),
          ),

          const SizedBox(height: 8),

          // Step Indicator Text

          Text(
            'STEP 1 OF 3',
            style: GoogleFonts.inter(
              fontSize: 10, // text-[10px]

              fontWeight: FontWeight.w900, // Black

              letterSpacing: 0.2, // tracking-[0.2em]

              color: Colors.grey.shade600, // Muted foreground
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Selection Header

        Padding(
          padding: const EdgeInsets.only(left: 4), // ml-1

          child: Text(
            'SELECT CATEGORY',
            style: GoogleFonts.inter(
              fontSize: 12, // text-xs

              fontWeight: FontWeight.w900, // Black

              color: Colors.grey.shade600,

              letterSpacing: 1.2,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Category Grid using provider registration design

        _CategoryGrid(
          selectedCategory: _selectedCategory?['name'],
          onCategoryChanged: (String? categoryName) {
            setState(() {
              if (categoryName != null) {
                _selectedCategory = _categories.firstWhere(
                  (cat) => cat['name'] == categoryName,
                  orElse: () => <String, dynamic>{},
                );
              } else {
                _selectedCategory = null;
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildTaskDescriptionSection(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Label

        Padding(
          padding: const EdgeInsets.only(left: 4), // ml-1

          child: Text(
            'TASK DESCRIPTION',
            style: GoogleFonts.inter(
              fontSize: 12, // text-xs

              fontWeight: FontWeight.w900, // Black

              letterSpacing: 0.2, // tracking-[0.2em]

              color: Colors.grey.shade600, // Muted foreground
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Task Description Textarea

        Container(
          height: 200, // Fixed height to prevent unbounded constraints

          decoration: BoxDecoration(
            color: Colors.white,

            borderRadius: BorderRadius.circular(24), // rounded-[24px]

            border: Border.all(
              color: Colors.grey.shade200,
              width: 1,
            ),

            boxShadow: [
              // Inset shadow effect using multiple shadows

              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),

                blurRadius: 8,

                offset: const Offset(0, 2),

                spreadRadius: -2, // Negative spread to create inset effect
              ),
            ],
          ),

          child: TextField(
            controller: _descriptionController,

            onChanged: (value) =>
                setState(() {}), // Immediately update button state

            maxLines: null, // Allow multiple lines

            textAlignVertical: TextAlignVertical.top,

            style: GoogleFonts.inter(
              fontSize: 14, // text-sm

              fontWeight: FontWeight.w500, // Medium

              height: 1.625, // Relaxed line height

              color: Colors.black,
            ),

            decoration: InputDecoration(
              hintText: 'Describe your task in detail...',

              hintStyle: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade400,
              ),

              border: InputBorder.none,

              contentPadding: const EdgeInsets.all(20), // p-5
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProOptionsSection(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFD700).withValues(alpha: 0.1),
            const Color(0xFF047A62).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PRO Header

          Row(
            children: [
              const MuawinProBadge(size: MuawinProBadgeSize.small),
              const SizedBox(width: 8),
              Text(
                'Additional Requirements',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF047A62),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Job Type Selection

          Text(
            'Job Type',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Colors.grey.shade600,
              letterSpacing: 0.2,
            ),
          ),

          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildProOptionChip(
                label: 'One-time Job',
                value: 'one_time',
                selected: _selectedJobType == 'one_time',
                onTap: () {
                  setState(() {
                    _selectedJobType = 'one_time';
                  });
                },
              ),
              _buildProOptionChip(
                label: 'Hiring',
                value: 'hire_only',
                selected: _selectedJobType == 'hire_only',
                onTap: () {
                  setState(() {
                    _selectedJobType = 'hire_only';
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Duration Type Selection - Only show for Hiring

          if (_selectedJobType == 'hire_only') ...[
            Text(
              'Hire Duration',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.grey.shade600,
                letterSpacing: 0.2,
              ),
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectDate(context, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _hireStartDate != null
                                  ? '${_hireStartDate!.day}/${_hireStartDate!.month}/${_hireStartDate!.year}'
                                  : 'From Date',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _hireStartDate != null
                                    ? Colors.black87
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'to',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectDate(context, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _hireEndDate != null
                                  ? '${_hireEndDate!.day}/${_hireEndDate!.month}/${_hireEndDate!.year}'
                                  : 'To Date',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _hireEndDate != null
                                    ? Colors.black87
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Time Selection for Hiring

            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectTime(context, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _hireStartTime != null
                                  ? _hireStartTime!.format(context)
                                  : 'From Time',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _hireStartTime != null
                                    ? Colors.black87
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'to',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectTime(context, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _hireEndTime != null
                                  ? _hireEndTime!.format(context)
                                  : 'To Time',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _hireEndTime != null
                                    ? Colors.black87
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
          ],

          // Priority Job Toggle

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Row(
              children: [
                Text(
                  'Priority Job',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'PRO',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFFD700),
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Text(
              'Get faster responses from providers',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            value: _isPriorityJob,
            onChanged: (value) {
              setState(() {
                _isPriorityJob = value;
              });
            },
            activeTrackColor: const Color(0xFF047A62),
          ),
        ],
      ),
    );
  }

  Widget _buildProOptionChip({
    required String label,
    required String value,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF047A62) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF047A62) : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  // Select date for Hiring job type

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2027),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        if (isStartDate) {
          _hireStartDate = picked;
        } else {
          _hireEndDate = picked;
        }
      });
    }
  }

  // Select time for Hire Only job type

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        if (isStartTime) {
          _hireStartTime = picked;
        } else {
          _hireEndTime = picked;
        }
      });
    }
  }

  Widget _buildBottomCTA(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32), // rounded-t-[32px]

          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back Button

          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),

                width: double.infinity,

                height: 56, // h-14

                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.arrow_back,

                      color: Colors.black87,

                      size: 20, // 1.25rem
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Back',
                      style: GoogleFonts.inter(
                        fontSize: 18, // text-lg

                        fontWeight: FontWeight.w900, // Black

                        letterSpacing: 0.2, // Widest tracking

                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Next Button

          Expanded(
            child: GestureDetector(
              onTap: isButtonEnabled
                  ? () {
                      // Navigate to Step 3

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PostJobStep2Screen(
                              selectedCategory: _selectedCategory),
                        ),
                      );
                    }
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),

                width: double.infinity,

                height: 56, // h-14

                decoration: BoxDecoration(
                  color: isButtonEnabled ? primaryColor : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(16),
                ),

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Next',
                      style: GoogleFonts.inter(
                        fontSize: 18, // text-lg

                        fontWeight: FontWeight.w900, // Black

                        letterSpacing: 0.2, // Widest tracking

                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward,

                      color: Colors.white,

                      size: 20, // 1.25rem
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom category selection grid - matching provider registration design

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  final String? selectedCategory;

  final Function(String?) onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Optimized responsive grid columns for mobile

    int crossAxisCount;

    double childAspectRatio;

    double crossAxisSpacing;

    double mainAxisSpacing;

    if (screenWidth < 360) {
      // Very small phones - 2 columns with taller cards

      crossAxisCount = 2;

      childAspectRatio = 1.0;

      crossAxisSpacing = 8;

      mainAxisSpacing = 8;
    } else if (screenWidth < 400) {
      // Small phones - 3 columns with optimized spacing

      crossAxisCount = 3;

      childAspectRatio = 1.1;

      crossAxisSpacing = 10;

      mainAxisSpacing = 10;
    } else if (screenWidth < 480) {
      // Medium phones - 3 columns with better proportions

      crossAxisCount = 3;

      childAspectRatio = 1.15;

      crossAxisSpacing = 12;

      mainAxisSpacing = 12;
    } else if (screenWidth > 600) {
      // Tablets and desktop - 4 columns

      crossAxisCount = 4;

      childAspectRatio = 1.2;

      crossAxisSpacing = 12;

      mainAxisSpacing = 12;
    } else {
      // Large phones - 3 columns with optimal spacing

      crossAxisCount = 3;

      childAspectRatio = 1.2;

      crossAxisSpacing = 12;

      mainAxisSpacing = 12;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
      ),
      itemCount: kCategoriesWithIcons.length,
      itemBuilder: (context, index) {
        final category = kCategoriesWithIcons[index];

        final isSelected = selectedCategory == category['name'];

        return _CategoryCard(
          category: category['name'] as String,
          icon: category['icon'] as IconData,
          isSelected: isSelected,
          onTap: () => onCategoryChanged(category['name'] as String),
        );
      },
    );
  }
}

/// Animated category card - matching provider registration design

class _CategoryCard extends StatefulWidget {
  const _CategoryCard({
    required this.category,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String category;

  final IconData icon;

  final bool isSelected;

  final VoidCallback onTap;

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(_CategoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    final screenWidth = MediaQuery.of(context).size.width;

    // Method to get unique color for each category icon

    Color getCategoryIconColor(String categoryName) {
      switch (categoryName.toLowerCase()) {
        case 'maid':
          return Colors.purple.shade600; // Purple for Maid

        case 'driver':
          return Colors.blue.shade600; // Blue for Driver

        case 'babysitter':
          return Colors.pink.shade600; // Pink for Babysitter

        case 'security guard':
          return Colors.indigo.shade600; // Indigo for Security Guard

        case 'washerman':
          return Colors.cyan.shade600; // Cyan for Washerman

        case 'domestic helper':
          return Colors.red.shade600; // Red for Domestic Helper

        case 'cook':
          return Colors.orange.shade600; // Orange for Cook

        case 'gardener':
          return Colors.green.shade600; // Green for Gardener

        case 'tutor':
          return Colors.amber.shade600; // Amber for Tutor

        default:
          return Colors.grey.shade600; // Default grey
      }
    }

    // Responsive sizing for mobile optimization

    double iconSize;

    double fontSize;

    double spacing;

    if (screenWidth < 360) {
      // Very small phones

      iconSize = 28;

      fontSize = 11;

      spacing = 6;
    } else if (screenWidth < 400) {
      // Small phones

      iconSize = 30;

      fontSize = 11.5;

      spacing = 7;
    } else if (screenWidth < 480) {
      // Medium phones

      iconSize = 32;

      fontSize = 12;

      spacing = 8;
    } else {
      // Large phones and tablets

      iconSize = 34;

      fontSize = 12.5;

      spacing = 8;
    }

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();

        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: widget.isSelected ? primary : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.isSelected
                      ? primary
                      : primary.withValues(alpha: 0.2),
                  width: widget.isSelected ? 2.0 : 1.0,
                ),
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(
                    8), // Add padding for better touch targets

                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.icon,
                      size: iconSize,
                      color: widget.isSelected
                          ? Colors.white
                          : getCategoryIconColor(widget.category),
                    ),
                    SizedBox(height: spacing),
                    Text(
                      widget.category,
                      style: GoogleFonts.poppins(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                        color: widget.isSelected
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Service categories for provider registration with icons

const List<Map<String, dynamic>> kCategoriesWithIcons = [
  {'name': 'Maid', 'icon': Icons.cleaning_services_rounded},
  {'name': 'Driver', 'icon': Icons.drive_eta_rounded},
  {'name': 'Babysitter', 'icon': Icons.child_care_rounded},
  {'name': 'Security Guard', 'icon': Icons.security_rounded},
  {'name': 'Washerman', 'icon': Icons.local_laundry_service_rounded},
  {'name': 'Domestic Helper', 'icon': Icons.home_repair_service_rounded},
  {'name': 'Cook', 'icon': Icons.restaurant_rounded},
  {'name': 'Gardener', 'icon': Icons.yard_rounded},
  {'name': 'Tutor', 'icon': Icons.school_rounded},
];

// Step 2 Screen - When and Where

class PostJobStep2Screen extends StatefulWidget {
  final Map<String, dynamic>? selectedCategory;

  final String? location;

  const PostJobStep2Screen({super.key, this.selectedCategory, this.location});

  @override
  State<PostJobStep2Screen> createState() => _PostJobStep2ScreenState();
}

class _PostJobStep2ScreenState extends State<PostJobStep2Screen> {
  final TextEditingController _locationController = TextEditingController();

  final TextEditingController _priceController = TextEditingController();

  DateTime? _selectedDate;

  TimeOfDay? _selectedTime;

  // PRO status
  bool _isProUser = false;

  @override
  void initState() {
    super.initState();
    _checkProStatus();
  }

  // Check if user is a PRO user
  Future<void> _checkProStatus() async {
    final isPro = await ProStatusChecker.isProUser();
    debugPrint('PostJobStep2Screen: PRO status = $isPro');
    if (mounted) {
      setState(() {
        _isProUser = isPro;
      });
    }
  }

  @override
  void dispose() {
    _locationController.dispose();

    _priceController.dispose();

    super.dispose();
  }

  // Method to fetch current location

  Future<void> _getCurrentLocation() async {
    try {
      // Check if location services are enabled

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        // Location services are disabled

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Location services are disabled. Please enable them.'),
              backgroundColor: Colors.red,
            ),
          );
        }

        return;
      }

      // Check location permissions

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permissions are denied.'),
                backgroundColor: Colors.red,
              ),
            );
          }

          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are permanently denied.'),
              backgroundColor: Colors.red,
            ),
          );
        }

        return;
      }

      // Get current position

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Create a formatted address from coordinates

      String address =
          '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';

      // You can use a geocoding service here to convert coordinates to address

      // For now, we'll use coordinates as the location

      if (mounted) {
        _locationController.text = address;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location fetched: $address'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Method to select date

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Method to select time

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section

            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Button

                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Step Progress Indicator

                  Row(
                    children: [
                      // Step 1 (Completed)

                      Container(
                        width: 40,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Step 2 (Active)

                      Expanded(
                        child: Container(
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Step 3 (Inactive)

                      Container(
                        width: 16,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Headline - "When and Where?"

                  Text(
                    'When and Where?',
                    style: GoogleFonts.poppins(
                      fontSize: 30, // text-3xl (same as Step 1)

                      fontWeight: FontWeight.w700, // Bold

                      letterSpacing: -0.5, // tracking-tight

                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Step Indicator Text

                  Text(
                    'STEP 2 OF 3',
                    style: GoogleFonts.inter(
                      fontSize: 10, // text-[10px]

                      fontWeight: FontWeight.w900, // Black

                      letterSpacing: 0.2, // tracking-[0.2em]

                      color: Colors.grey.shade600, // Muted foreground
                    ),
                  ),
                ],
              ),
            ),

            // Main Content Area (Scrollable)

            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                          height: 32), // Vertical space below STEP 2 OF 3

                      // WORK LOCATION Heading

                      Text(
                        'WORK LOCATION',
                        style: GoogleFonts.inter(
                          fontSize: 12, // text-xs

                          fontWeight: FontWeight.w900, // Black

                          letterSpacing: 0.2, // tracking-[0.2em]

                          color: Colors.grey.shade600, // Muted foreground
                        ),
                      ),

                      const SizedBox(height: 12), // Space below heading

                      // Location Input Field

                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: TextField(
                          controller: _locationController,
                          decoration: InputDecoration(
                            hintText:
                                'Street Address, Block, Area (Complete Location)',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.w400,
                            ),
                            prefixIcon: GestureDetector(
                              onTap: _getCurrentLocation,
                              child: Icon(
                                Icons.location_on,
                                color: Colors.green.shade600,
                                size: 24,
                              ),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.black87,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),

                      const SizedBox(
                          height: 32), // Additional space below location field

                      // PREFERRED DATE Heading - Hide for PRO users (handled in Step 1)
                      if (!_isProUser) ...[
                        Text(
                          'PREFERRED DATE',
                          style: GoogleFonts.inter(
                            fontSize: 12, // text-xs

                            fontWeight: FontWeight.w900, // Black

                            letterSpacing: 0.2, // tracking-[0.2em]

                            color: Colors.grey.shade600, // Muted foreground
                          ),
                        ),

                        const SizedBox(height: 12), // Space below heading

                        // Date Selection Field

                        GestureDetector(
                          onTap: _selectDate,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                // Calendar Icon

                                Icon(
                                  Icons.calendar_today,
                                  color: Colors.blue.shade600,
                                  size: 24,
                                ),

                                const SizedBox(width: 12),

                                // Date Text

                                Expanded(
                                  child: Text(
                                    _selectedDate != null
                                        ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                        : 'Select preferred date',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      color: _selectedDate != null
                                          ? Colors.black87
                                          : Colors.grey.shade400,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),

                                // Dropdown Arrow

                                Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.grey.shade600,
                                  size: 24,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(
                            height: 32), // Space between date and time sections

                        // PREFERRED TIME Heading

                        Text(
                          'PREFERRED TIME',
                          style: GoogleFonts.inter(
                            fontSize: 12, // text-xs

                            fontWeight: FontWeight.w900, // Black

                            letterSpacing: 0.2, // tracking-[0.2em]

                            color: Colors.grey.shade600, // Muted foreground
                          ),
                        ),

                        const SizedBox(height: 12), // Space below heading

                        // Time Selection Field

                        GestureDetector(
                          onTap: _selectTime,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                // Clock Icon

                                Icon(
                                  Icons.access_time,
                                  color: Colors.orange.shade600,
                                  size: 24,
                                ),

                                const SizedBox(width: 12),

                                // Time Text

                                Expanded(
                                  child: Text(
                                    _selectedTime != null
                                        ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                                        : 'Select preferred time',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      color: _selectedTime != null
                                          ? Colors.black87
                                          : Colors.grey.shade400,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),

                                // Dropdown Arrow

                                Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.grey.shade600,
                                  size: 24,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32), // Space below time field
                      ],

                      // PROPOSE PRICE Heading

                      Text(
                        'PROPOSE PRICE (RS.)',
                        style: GoogleFonts.inter(
                          fontSize: 12, // text-xs

                          fontWeight: FontWeight.w900, // Black

                          letterSpacing: 0.2, // tracking-[0.2em]

                          color: Colors.grey.shade600, // Muted foreground
                        ),
                      ),

                      const SizedBox(height: 12), // Space below heading

                      // Price Input Field

                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: TextField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Enter your Proposed Budget',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.w400,
                            ),
                            prefixIcon: Icon(
                              Icons.attach_money,
                              color: Colors.green.shade600,
                              size: 24,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.black87,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom CTA Button (Always Visible)

            Container(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PostJobStep3Screen(
                            selectedCategory: widget.selectedCategory,
                            location: _locationController.text,
                            selectedDate: _selectedDate,
                            selectedTime: _selectedTime,
                            price: _priceController.text),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Next',
                        style: GoogleFonts.inter(
                          fontSize: 18, // Changed from 16 to 18 to match Step 1

                          fontWeight: FontWeight.w800, // Extra bold

                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: MuawinBottomNavigationBar(
        currentIndex: 2, // Post Job tab selected

        onItemTapped: (i) {
          if (i == 0) {
            // Navigate to Home screen

            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const CustomerHomeScreen(),
            ));
          } else if (i == 1) {
            // Navigate to My Jobs screen

            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const CustomerJobsScreen(),
            ));
          } else if (i == 2) {
            // Navigate to Post Job screen

            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const PostJobScreen(),
            ));
          } else if (i == 3) {
            // Navigate to Messages screen

            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const CustomerMessagesScreen(),
            ));
          } else if (i == 4) {
            // Navigate to Profile screen

            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const CustomerProfileScreen(),
            ));
          }
        },
      ),
    );
  }
}
