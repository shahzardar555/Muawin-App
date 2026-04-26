import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/bottom_navigation_bar.dart';
import 'customer_home_screen.dart';
import 'customer_jobs_screen.dart';
import 'customer_messages_screen.dart';
import 'customer_profile_screen.dart';
import 'services/pro_status_checker.dart';

/// Post Job Screen (/customer/post-job)
/// Progressive Disclosure Form with multi-step flow for posting jobs.
class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  int _currentStep =
      1; // 1: Task Definition, 2: Logistics & Budget, 3: Verification

  // PRO status
  bool _isProUser = false;

  // Step 1: Task Definition
  String? _selectedCategory;
  final TextEditingController _descriptionController = TextEditingController();

  // Job posting state
  bool _isJobPosted = false;

  // Step 2: Logistics & Budget
  final TextEditingController _locationController =
      TextEditingController(text: 'Gulberg III, Lahore');
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final TextEditingController _budgetController = TextEditingController();

  final List<Map<String, dynamic>> _categories = [
    {'label': 'Maid', 'icon': Icons.cleaning_services},
    {'label': 'Driver', 'icon': Icons.directions_car},
    {'label': 'Cook', 'icon': Icons.restaurant},
    {'label': 'Tutor', 'icon': Icons.school},
    {'label': 'Electrician', 'icon': Icons.electrical_services},
    {'label': 'Plumber', 'icon': Icons.plumbing},
  ];

  @override
  void initState() {
    super.initState();
    _checkProStatus();
  }

  // Check if user is a PRO user
  Future<void> _checkProStatus() async {
    final isPro = await ProStatusChecker.isProUser();
    debugPrint('PostJobScreen: PRO status = $isPro');
    if (mounted) {
      setState(() {
        _isProUser = isPro;
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          // HEADER PROGRESS SYSTEM
          _buildProgressIndicator(primary),

          // STEP CONTENT
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: _buildCurrentStepContent(primary),
            ),
          ),
        ],
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
            // Already on Post Job screen, do nothing
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

  // HEADER PROGRESS SYSTEM
  Widget _buildProgressIndicator(Color primary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Ghost-style ArrowLeft button for backwards traversal
              if (_currentStep > 1)
                GestureDetector(
                  onTap: () => setState(() => _currentStep--),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.arrow_back,
                      color: primary,
                      size: 20,
                    ),
                  ),
                )
              else
                const SizedBox(width: 36),

              // Segmented Indicator: Horizontal row of three capsules
              Row(
                children: [
                  _buildProgressStep(1, 'Task', primary),
                  const SizedBox(width: 8),
                  _buildProgressStep(2, 'Details', primary),
                  const SizedBox(width: 8),
                  _buildProgressStep(3, 'Review', primary),
                ],
              ),

              const SizedBox(width: 36), // Balance for back button
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStep(int step, String label, Color primary) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;

    return Container(
      // Active step expands to 2rem, inactive remain at 1rem
      width: isActive ? 32 : 16, // w-8 vs w-4
      height: 32,
      decoration: BoxDecoration(
        color: isActive
            ? primary
            : (isCompleted ? Colors.green[400] : Colors.grey[300]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent(Color primary) {
    switch (_currentStep) {
      case 1:
        return _buildStep1TaskDefinition(primary);
      case 2:
        return _buildStep2LogisticsAndBudget(primary);
      case 3:
        return _buildStep3Verification(primary);
      default:
        return Container();
    }
  }

  // STEP 1: TASK DEFINITION
  Widget _buildStep1TaskDefinition(Color primary) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Headline: "Describe your task"
          Text(
            'Describe your task',
            style: GoogleFonts.poppins(
              fontSize: 30, // 1.875rem
              fontWeight: FontWeight.w800, // Extra-Bold
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),

          // Category Grid: 2-column grid of outlined squircles
          Text(
            'Select a category',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio:
                  1.2, // Increased from 1.0 to 1.2 for better text visibility on mobile
            ),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = _selectedCategory == category['label'];

              return GestureDetector(
                onTap: () =>
                    setState(() => _selectedCategory = category['label']),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primary.withValues(alpha: 0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? primary : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        category['icon'],
                        size: 32,
                        color: isSelected ? primary : Colors.grey[600],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category['label'],
                        style: GoogleFonts.poppins(
                          fontSize: 12, // Reduced from 14 to 12 for better fit
                          fontWeight: FontWeight.bold,
                          color: isSelected ? primary : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2, // Allow up to 2 lines for long text
                        overflow: TextOverflow
                            .ellipsis, // Show ellipsis if still too long
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Description Area
          Text(
            'Describe what you need done',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText:
                    'e.g., I need help with deep cleaning my 3-bedroom apartment...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16), // 1rem padding
              ),
              style: GoogleFonts.poppins(
                fontSize: 15,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Continue Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: _selectedCategory != null &&
                      _descriptionController.text.isNotEmpty
                  ? () => setState(() => _currentStep = 2)
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Continue to Details',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // STEP 2: LOGISTICS & BUDGET
  Widget _buildStep2LogisticsAndBudget(Color primary) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Logistics & Budget',
            style: GoogleFonts.poppins(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),

          // Location Entry
          Text(
            'Location',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: TextField(
              controller: _locationController,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.location_on, color: primary),
                hintText: 'Enter service location',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
              style: GoogleFonts.poppins(fontSize: 15),
            ),
          ),

          const SizedBox(height: 20),

          // Date/Time Selectors - Hide for PRO users (handled in Step 1)
          if (!_isProUser) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => _selectDate(context, primary),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, color: primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedDate != null
                                      ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                      : 'Select date',
                                  style: GoogleFonts.poppins(fontSize: 15),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Time',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => _selectTime(context, primary),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.access_time, color: primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedTime != null
                                      ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                                      : 'Select time',
                                  style: GoogleFonts.poppins(fontSize: 15),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],

          // Budgeting
          Text(
            'Proposed Price',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'Providing a budget helps in faster acceptance.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontStyle: FontStyle.italic, // italicized micro-copy
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: TextField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.attach_money, color: primary),
                hintText: 'Enter proposed amount (PKR)',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
              style: GoogleFonts.poppins(fontSize: 15),
            ),
          ),

          const SizedBox(height: 32),

          // Navigation Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep = 1),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Back',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: _locationController.text.isNotEmpty &&
                          _selectedDate != null &&
                          _selectedTime != null &&
                          _budgetController.text.isNotEmpty
                      ? () => setState(() => _currentStep = 3)
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Continue to Review',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // STEP 3: VERIFICATION (REVIEW CARD)
  Widget _buildStep3Verification(Color primary) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Review & Confirm',
                style: GoogleFonts.poppins(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              if (_isJobPosted) ...[
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Posted',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),

          // Card Design: muawin-card with subtle Teal tint
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.05), // bg-primary/5
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: primary.withValues(alpha: 0.2), // border-primary/20
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Data: Vertical list with 5px thick vertical dash
                _buildSummaryItem(
                    'Category',
                    _selectedCategory ?? 'Not selected',
                    Icons.category,
                    primary),
                const SizedBox(height: 16),
                _buildSummaryItem('Description', _descriptionController.text,
                    Icons.description, primary),
                const SizedBox(height: 16),
                _buildSummaryItem('Location', _locationController.text,
                    Icons.location_on, primary),
                const SizedBox(height: 16),
                _buildSummaryItem(
                    'Date & Time',
                    '${_selectedDate?.day}/${_selectedDate?.month}/${_selectedDate?.year} at ${_selectedTime?.hour.toString().padLeft(2, '0')}:${_selectedTime?.minute.toString().padLeft(2, '0')}',
                    Icons.schedule,
                    primary),
                const SizedBox(height: 16),
                _buildSummaryItem('Budget', 'PKR ${_budgetController.text}',
                    Icons.attach_money, primary),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Action Buttons
          Column(
            children: [
              if (!_isJobPosted) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _currentStep = 2),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Back',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => _confirmAndPostJob(primary),
                        style: FilledButton.styleFrom(
                          backgroundColor: primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Confirm & Post',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              // Go to Home button (always visible)
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const CustomerHomeScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Go to Home',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
              if (_isJobPosted) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const CustomerHomeScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Go to Homepage',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(
              height: 50), // Extra bottom padding to ensure button visibility
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
      String label, String value, IconData icon, Color primary) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 5-pixel thick vertical dash representing connection
        Container(
          width: 5,
          height: 24,
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(2.5),
          ),
        ),
        const SizedBox(width: 16),
        Icon(icon, color: primary, size: 18), // Reduced from 20 to 18
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11, // Reduced from 12 to 11
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 12, // Reduced from 13 to 12 for better fit
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 2, // Allow up to 2 lines for long text
                overflow:
                    TextOverflow.ellipsis, // Show ellipsis if still too long
                softWrap: true, // Ensure text wraps properly
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _selectDate(BuildContext context, Color primary) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  void _selectTime(BuildContext context, Color primary) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  void _confirmAndPostJob(Color primary) {
    // Generate job ID
    final jobId =
        '#MUA-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    // Show success confirmation
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SuccessConfirmationDialog(
        jobId: jobId,
        primary: primary,
        onTrackJob: () {
          Navigator.of(context).pop(); // Close dialog
          Navigator.of(context).pop(); // Go back to home
        },
        onBackToHome: () {
          Navigator.of(context).pop(); // Close dialog
          Navigator.of(context).pop(); // Go back to home
        },
      ),
    );

    // Set job as posted
    setState(() {
      _isJobPosted = true;
    });
  }
}

// 4. THE SUCCESS CONFIRMATION (THE "Pop-Up" Result)
class _SuccessConfirmationDialog extends StatelessWidget {
  final String jobId;
  final Color primary;
  final VoidCallback onTrackJob;
  final VoidCallback onBackToHome;

  const _SuccessConfirmationDialog({
    required this.jobId,
    required this.primary,
    required this.onTrackJob,
    required this.onBackToHome,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The Success Anchor: Large centered 6rem Primary Teal circle
            Container(
              width: 96, // 6rem
              height: 96,
              decoration: BoxDecoration(
                color: primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 48,
              ),
            ),

            const SizedBox(height: 24),

            // Headline: "Job Posted Successfully!"
            Text(
              'Job Posted Successfully!',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 20),

            // Job ID Capsule
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100], // bg-secondary/20
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Top Row: "Job ID" + "#MUA-48291"
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Job ID',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600], // Muted gray
                        ),
                      ),
                      Text(
                        jobId,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold, // Bold
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Clean horizontal divide
                  Container(
                    height: 1,
                    color: Colors.grey[300]!,
                  ),
                  const SizedBox(height: 8),
                  // Bottom Row: "Estimated Match Time" + "~5 mins"
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Estimated Match Time',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: primary, // High-contrast Primary Teal
                          borderRadius: BorderRadius.circular(8), // pill
                        ),
                        child: Text(
                          '~5 mins',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Call to Action buttons
            Column(
              children: [
                // Primary: "Track Job Status"
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: onTrackJob,
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          primary, // Full-width, solid Primary Teal
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8, // heavy shadow
                    ),
                    child: Text(
                      'Track Job Status',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Secondary: "Back to Home"
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: onBackToHome,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Back to Home',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
