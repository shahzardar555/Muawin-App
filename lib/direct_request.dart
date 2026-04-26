import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'services/notification_manager.dart' as nm;
import 'services/pro_status_checker.dart';
import 'widgets/muawin_pro_badge.dart';

/// Direct Request Screen - Customer sends job request to provider
/// 5-step flow: Package Selection → Date/Time → Price Negotiation → Payment Method → Review & Send
class DirectRequestScreen extends StatefulWidget {
  const DirectRequestScreen({
    super.key,
    required this.providerData,
  });

  final Map<String, dynamic> providerData;

  @override
  State<DirectRequestScreen> createState() => _DirectRequestScreenState();
}

class _DirectRequestScreenState extends State<DirectRequestScreen>
    with TickerProviderStateMixin {
  // Step management
  int currentStep = 0;
  late AnimationController _pulseController;
  late AnimationController _confettiController;
  late Animation<double> _pulseAnimation;

  // PRO status
  bool _isProUser = false;

  // Form data
  String selectedPackage = 'basic';
  DateTime? selectedDate;
  String selectedTime = '';
  double proposedPrice = 800.0;
  String specialInstructions = '';
  String negotiationNote = '';

  // PRO-only options
  String? _selectedJobType; // 'one_time', 'hire_only'
  String? _selectedDurationType; // 'days', 'weeks', 'months'
  bool _isPriorityResponse = false;
  DateTime? _hireStartDate;
  DateTime? _hireEndDate;
  TimeOfDay? _hireStartTime;
  TimeOfDay? _hireEndTime;

  // Payment method data
  String selectedPaymentMethod = '';
  String jazzCashNumber = '';
  String easypaisaNumber = '';
  String cardNumber = '';
  String cardExpiry = '';
  String cardCVV = '';
  String cardHolderName = '';

  // Loading states
  bool isLoading = false;
  bool isSuccess = false;

  // Package data
  final Map<String, Map<String, dynamic>> packageData = {
    'basic': {
      'name': 'Basic',
      'price': 800.0,
      'color': const Color(0xFFE8F5E9),
      'borderColor': const Color(0xFF4CAF50),
      'description': 'Essential services for your basic needs',
      'duration': '2-3 hours',
      'features': ['Basic cleaning', 'Standard equipment', 'Limited time'],
    },
    'standard': {
      'name': 'Standard',
      'price': 1200.0,
      'color': const Color(0xFFE3F2FD),
      'borderColor': const Color(0xFF2196F3),
      'description': 'Comprehensive services with extra features',
      'duration': '3-4 hours',
      'features': [
        'Deep cleaning',
        'Premium equipment',
        'Extended time',
        'Priority support'
      ],
      'badge': 'Most Popular',
    },
    'premium': {
      'name': 'Premium',
      'price': 1800.0,
      'color': const Color(0xFFFFF8E1),
      'borderColor': const Color(0xFFFF9800),
      'description': 'Complete premium experience with all features',
      'duration': '4-5 hours',
      'features': [
        'Complete service',
        'Premium equipment',
        'Unlimited time',
        '24/7 support',
        'Guaranteed satisfaction'
      ],
      'badge': 'Best Value',
    },
  };

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _confettiController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
    proposedPrice = packageData['basic']!['price'];
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
    _pulseController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  List<DateTime> _getNext14Days() {
    final List<DateTime> days = [];
    final now = DateTime.now();
    for (int i = 0; i < 14; i++) {
      days.add(now.add(Duration(days: i)));
    }
    return days;
  }

  List<String> _getTimeSlots() {
    return [
      '8:00 AM',
      '9:00 AM',
      '10:00 AM',
      '11:00 AM',
      '12:00 PM',
      '1:00 PM',
      '2:00 PM',
      '3:00 PM',
      '4:00 PM',
      '5:00 PM',
      '6:00 PM',
      '7:00 PM',
    ];
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) return 'Today';
    if (checkDate == today.add(const Duration(days: 1))) return 'Tomorrow';

    return '${date.day} ${_getMonthName(date.month)}';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  void _nextStep() {
    if (currentStep < 4) {
      // Skip step 1 (Date/Time) for PRO users by incrementing normally
      setState(() => currentStep++);
    }
  }

  void _previousStep() {
    if (currentStep > 0) {
      // Skip step 1 (Date/Time) for PRO users when going back
      if (_isProUser && currentStep == 1) {
        setState(() => currentStep--); // Go back to step 0 (Package)
      } else {
        setState(() => currentStep--);
      }
    }
  }

  bool _isCurrentStepValid() {
    switch (currentStep) {
      case 0:
        return selectedPackage.isNotEmpty;
      case 1:
        // For PRO users, this is Price step (Date/Time skipped)
        // For basic users, this is Date/Time step
        return _isProUser
            ? proposedPrice >= packageData[selectedPackage]!['price'] * 0.5 &&
                proposedPrice <= packageData[selectedPackage]!['price'] * 1.5
            : selectedDate != null && selectedTime.isNotEmpty;
      case 2:
        // For PRO users, this is Pay step
        // For basic users, this is Price step
        return _isProUser
            ? _isPaymentMethodValid()
            : proposedPrice >= packageData[selectedPackage]!['price'] * 0.5 &&
                proposedPrice <= packageData[selectedPackage]!['price'] * 1.5;
      case 3:
        // For PRO users, this is Review step
        // For basic users, this is Pay step
        return _isProUser ? true : _isPaymentMethodValid();
      case 4:
        // For PRO users, this should never be reached
        // For basic users, this is Review step
        return true;
      default:
        return false;
    }
  }

  bool _isPaymentMethodValid() {
    switch (selectedPaymentMethod) {
      case 'jazzcash':
        return jazzCashNumber.length == 11 && jazzCashNumber.startsWith('03');
      case 'easypaisa':
        return easypaisaNumber.length == 11 && easypaisaNumber.startsWith('03');
      case 'card':
        return cardNumber.length == 16 &&
            cardExpiry.isNotEmpty &&
            cardCVV.length >= 3 &&
            cardHolderName.isNotEmpty;
      case 'cash':
        return true; // Cash payment always valid
      default:
        return false;
    }
  }

  Future<void> _sendRequest() async {
    setState(() => isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 1500));

    // Check if widget is still mounted before using context
    if (!mounted) return;

    // Send notifications
    try {
      final notificationManager =
          Provider.of<nm.NotificationManager>(context, listen: false);

      // Send to provider
      notificationManager.sendNotification(
        receiverId: widget.providerData['id']?.toString() ?? 'provider_123',
        receiverType: 'provider',
        type: nm.NotificationType.jobRequestReceived,
        title: '🎯 New Job Request!',
        body: 'A customer has sent you a direct job request',
        priority: nm.NotificationPriority.high,
      );

      // Send confirmation to customer
      notificationManager.sendNotification(
        receiverId: 'customer_123',
        receiverType: 'customer',
        type: nm.NotificationType.jobRequestSent,
        title: '✅ Request Sent Successfully!',
        body: 'Your job request has been sent to the provider',
        priority: nm.NotificationPriority.medium,
      );
    } catch (e) {
      debugPrint('Error sending notifications: $e');
    }

    // Check if widget is still mounted before updating state
    if (!mounted) return;

    setState(() {
      isLoading = false;
      isSuccess = true;
    });

    _confettiController.forward();
  }

  Widget _buildStepIndicator() {
    // For PRO users, skip Date step, so show 4 steps instead of 5
    final stepLabels = _isProUser
        ? ['Package', 'Price', 'Pay', 'Review']
        : ['Package', 'Date', 'Price', 'Pay', 'Review'];
    final totalSteps = _isProUser ? 4 : 5;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        children: [
          for (int i = 0; i < totalSteps; i++) ...[
            Expanded(
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < currentStep
                          ? const Color(0xFF047A62)
                          : i == currentStep
                              ? const Color(0xFF047A62)
                              : Colors.grey.shade300,
                      border: i == currentStep
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                    ),
                    child: i < currentStep
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : i == currentStep
                            ? AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _pulseAnimation.value,
                                    child: const Icon(
                                      Icons.circle,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  );
                                },
                              )
                            : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    stepLabels[i],
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight:
                          i <= currentStep ? FontWeight.w600 : FontWeight.w400,
                      color: i <= currentStep
                          ? const Color(0xFF047A62)
                          : Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (i < 4)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: i < currentStep
                      ? const Color(0xFF047A62)
                      : Colors.grey.shade300,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Provider info card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF047A62).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Color(0xFF047A62),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.providerData['name']?.toString() ??
                          'Service Provider',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.providerData['category']?.toString() ??
                          'Professional Service',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Package title
        Text(
          'Choose a Package',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select the service package that fits your needs',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 24),

        // Package cards
        ...packageData.entries.map((entry) {
          final package = entry.value;
          final isSelected = selectedPackage == entry.key;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: package['color'],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isSelected ? package['borderColor'] : Colors.transparent,
                  width: 2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: package['borderColor'].withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      selectedPackage = entry.key;
                      proposedPrice = package['price'];
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with badge
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                package['name'],
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            if (package['badge'] != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: package['borderColor'],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  package['badge'],
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Price
                        Text(
                          'Rs. ${package['price'].toStringAsFixed(0)}/visit',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: package['borderColor'],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Description
                        Text(
                          package['description'],
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Duration badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '⏱ ${package['duration']}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Features
                        ...package['features'].map<Widget>((feature) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: package['borderColor'],
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    feature,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 32),

        // PRO-Only Options Section
        if (_isProUser) ...[
          _buildProOptionsSection(),
          const SizedBox(height: 32),
        ],
      ],
    );
  }

  Widget _buildProOptionsSection() {
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

          // Duration Type Selection - Only show for One-time Job
          if (_selectedJobType == 'one_time') ...[
            Text(
              'Duration Type',
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
                _buildDurationOption(
                  label: 'Days',
                  value: 'days',
                  selected: _selectedDurationType == 'days',
                  onTap: () {
                    setState(() {
                      _selectedDurationType = 'days';
                    });
                  },
                ),
                const SizedBox(width: 8),
                _buildDurationOption(
                  label: 'Weeks',
                  value: 'weeks',
                  selected: _selectedDurationType == 'weeks',
                  onTap: () {
                    setState(() {
                      _selectedDurationType = 'weeks';
                    });
                  },
                ),
                const SizedBox(width: 8),
                _buildDurationOption(
                  label: 'Months',
                  value: 'months',
                  selected: _selectedDurationType == 'months',
                  onTap: () {
                    setState(() {
                      _selectedDurationType = 'months';
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Hire Duration - Only show for Hiring
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

          // Priority Response Toggle
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Row(
              children: [
                Text(
                  'Priority Response',
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
              'Get faster response from provider',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            value: _isPriorityResponse,
            onChanged: (value) {
              setState(() {
                _isPriorityResponse = value;
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
            fontSize: 13,
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

  // Select time for Hiring job type
  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
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

  Widget _buildDurationOption({
    required String label,
    required String value,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF047A62) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? const Color(0xFF047A62) : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep2() {
    final dates = _getNext14Days();
    final timeSlots = _getTimeSlots();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'When do you need this?',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Pick your preferred date and time',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 32),

        // Date selection
        Text(
          'Select Date',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: dates.length,
            itemBuilder: (context, index) {
              final date = dates[index];
              final isSelected = selectedDate != null &&
                  selectedDate!.year == date.year &&
                  selectedDate!.month == date.month &&
                  selectedDate!.day == date.day;

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 80,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF047A62) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF047A62)
                          : Colors.grey.shade300,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? const Color(0xFF047A62).withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.05),
                        blurRadius: isSelected ? 8 : 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() => selectedDate = date);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _getDayName(date.weekday),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            date.day.toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 32),

        // Time selection
        Text(
          'Select Time',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
          ),
          itemCount: timeSlots.length,
          itemBuilder: (context, index) {
            final time = timeSlots[index];
            final isSelected = selectedTime == time;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color:
                    isSelected ? const Color(0xFF047A62) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? const Color(0xFF047A62).withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.05),
                    blurRadius: isSelected ? 6 : 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() => selectedTime = time);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Center(
                    child: Text(
                      time,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 32),

        // Special instructions
        Text(
          'Special Instructions',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),

        TextField(
          onChanged: (value) {
            setState(() => specialInstructions = value);
          },
          maxLines: 3,
          maxLength: 200,
          decoration: InputDecoration(
            hintText: 'Any special instructions for the provider?',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF047A62)),
            ),
            counterText: '${specialInstructions.length}/200',
            counterStyle: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
          style: GoogleFonts.poppins(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    final providerPrice = packageData[selectedPackage]!['price'];
    final minPrice = providerPrice * 0.5;
    final maxPrice = providerPrice * 1.5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Price Offer',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Provider\'s price shown, you can negotiate',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 32),

        // Provider's price card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Provider\'s Price',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Rs. ${providerPrice.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'This is the standard rate',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Price input section
        Text(
          'Your Proposed Price',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'Rs.',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF047A62),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      onChanged: (value) {
                        final price = double.tryParse(value);
                        if (price != null) {
                          setState(() => proposedPrice = price);
                        }
                      },
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: proposedPrice.toStringAsFixed(0),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  // Increment/Decrement buttons
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (proposedPrice < maxPrice) {
                            setState(() => proposedPrice += 100);
                          }
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF047A62),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () {
                          if (proposedPrice > minPrice) {
                            setState(() => proposedPrice -= 100);
                          }
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.remove,
                            color: Colors.black87,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Price validation messages
              if (proposedPrice < minPrice)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFC107)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning,
                          color: Color(0xFFFF9800), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '⚠️ Very low offers may be rejected',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFFFF9800),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else if ((proposedPrice - providerPrice).abs() <= 100)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF4CAF50)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: Color(0xFF4CAF50), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Great offer! Service provider likely to accept',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF4CAF50),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Custom bar-style slider
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              // Animated fill bar
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: (proposedPrice / maxPrice) *
                        MediaQuery.of(context).size.width -
                    64,
                decoration: BoxDecoration(
                  color: const Color(0xFF047A62),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              // Price text on the bar
              if ((proposedPrice / maxPrice) *
                      (MediaQuery.of(context).size.width - 64) >
                  60)
                Positioned(
                  left: 12,
                  top: 12,
                  child: Text(
                    'Rs. ${proposedPrice.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              // Draggable thumb
              Positioned(
                left: (proposedPrice / maxPrice) *
                        (MediaQuery.of(context).size.width - 64) -
                    12, // Center thumb on bar
                top: 8,
                child: GestureDetector(
                  onPanStart: (details) {
                    // Start drag
                  },
                  onPanUpdate: (details) {
                    final RenderBox box =
                        context.findRenderObject() as RenderBox;
                    final Offset localPosition =
                        box.globalToLocal(details.globalPosition);
                    final double sliderWidth =
                        MediaQuery.of(context).size.width - 64;
                    final double clampedX =
                        localPosition.dx.clamp(0, sliderWidth);
                    final double newValue = (clampedX / sliderWidth) * maxPrice;
                    final int roundedValue = (newValue / 100).round() * 100;
                    setState(() {
                      proposedPrice =
                          roundedValue.clamp(minPrice, maxPrice).toDouble();
                    });
                  },
                  onPanEnd: (details) {
                    // End drag
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF047A62),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Price text outside bar (when bar is too small)
              if ((proposedPrice / maxPrice) *
                      (MediaQuery.of(context).size.width - 64) <=
                  60)
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF047A62),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Rs. ${proposedPrice.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Min: Rs. ${minPrice.toStringAsFixed(0)}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              'Max: Rs. ${maxPrice.toStringAsFixed(0)}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Negotiation note
        Text(
          'Negotiation Note (Optional)',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),

        TextField(
          onChanged: (value) {
            setState(() => negotiationNote = value);
          },
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Explain why you\'re proposing this price...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF047A62)),
            ),
          ),
          style: GoogleFonts.poppins(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildStep4() {
    final platformFee = proposedPrice * 0.1;
    final totalAmount = proposedPrice + platformFee;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          'How will you pay?',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose your preferred payment method',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 32),

        // SECTION 1 - Payment Method Selection
        ...[
          _buildPaymentCard(
            'jazzcash',
            'JazzCash',
            'Pay via JazzCash mobile wallet',
            const Color(0xFFE31837),
            Icons.account_balance_wallet_rounded,
            'J',
          ),
          _buildPaymentCard(
            'easypaisa',
            'Easypaisa',
            'Pay via Easypaisa mobile wallet',
            const Color(0xFF2DB24A),
            Icons.account_balance_wallet_rounded,
            'E',
          ),
          _buildPaymentCard(
            'card',
            'Credit / Debit Card',
            'Visa, Mastercard, all cards accepted',
            const Color(0xFF1565C0),
            Icons.credit_card_rounded,
            null,
          ),
          _buildPaymentCard(
            'cash',
            'Cash',
            'Pay directly to provider on arrival',
            const Color(0xFF757575),
            Icons.money_rounded,
            null,
          ),
        ],

        const SizedBox(height: 32),

        // SECTION 2 - Payment Summary
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.account_balance_wallet_rounded,
                      color: Color(0xFF047A62)),
                  const SizedBox(width: 8),
                  Text(
                    'Payment Summary',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Summary details
              _buildSummaryRow(
                  'Service Fee:', 'Rs. ${proposedPrice.toStringAsFixed(0)}'),
              _buildSummaryRow(
                  'Platform Fee:', 'Rs. ${platformFee.toStringAsFixed(0)}'),
              const Divider(color: Color(0xFFE0E0E0)),
              _buildSummaryRow(
                'Total Amount:',
                'Rs. ${totalAmount.toStringAsFixed(0)}',
                isBold: true,
                color: const Color(0xFF047A62),
              ),
              const SizedBox(height: 16),

              const SizedBox(height: 24),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPaymentCard(
    String method,
    String title,
    String subtitle,
    Color accentColor,
    IconData icon,
    String? initial,
  ) {
    final isSelected = selectedPaymentMethod == method;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accentColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() => selectedPaymentMethod = method);
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with checkmark
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: initial != null
                            ? Center(
                                child: Text(
                                  initial,
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: accentColor,
                                  ),
                                ),
                              )
                            : Icon(icon, color: accentColor, size: 20),
                      ),
                      const Spacer(),
                      if (isSelected)
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title and subtitle
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  // Expanded form fields
                  if (isSelected) ...[
                    const SizedBox(height: 16),
                    if (method == 'jazzcash') _buildJazzCashField(),
                    if (method == 'easypaisa') _buildEasypaisaField(),
                    if (method == 'card') _buildCardFields(),
                    if (method == 'cash') _buildCashInfo(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJazzCashField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'JazzCash Number',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          onChanged: (value) {
            setState(() => jazzCashNumber = value);
          },
          keyboardType: TextInputType.phone,
          maxLength: 11,
          decoration: InputDecoration(
            hintText: '03XX-XXXXXXX',
            prefixIcon: const Icon(Icons.phone_rounded, color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE31837)),
            ),
          ),
          style: GoogleFonts.poppins(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildEasypaisaField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Easypaisa Number',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          onChanged: (value) {
            setState(() => easypaisaNumber = value);
          },
          keyboardType: TextInputType.phone,
          maxLength: 11,
          decoration: InputDecoration(
            hintText: '03XX-XXXXXXX',
            prefixIcon: const Icon(Icons.phone_rounded, color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2DB24A)),
            ),
          ),
          style: GoogleFonts.poppins(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildCardFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card Number
        Text(
          'Card Number',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          onChanged: (value) {
            // Auto-format with spaces every 4 digits
            String formatted = value.replaceAll(RegExp(r'\s'), '');
            if (formatted.length > 4 && formatted.length <= 8) {
              formatted =
                  '${formatted.substring(0, 4)} ${formatted.substring(4)}';
            } else if (formatted.length > 8 && formatted.length <= 12) {
              formatted =
                  '${formatted.substring(0, 4)} ${formatted.substring(4, 4)} ${formatted.substring(8)}';
            } else if (formatted.length > 12) {
              formatted =
                  '${formatted.substring(0, 4)} ${formatted.substring(4, 4)} ${formatted.substring(8, 4)} ${formatted.substring(12)}';
            }
            setState(() => cardNumber = formatted);
          },
          keyboardType: TextInputType.number,
          maxLength: 19, // 16 digits + 3 spaces
          decoration: InputDecoration(
            hintText: 'XXXX XXXX XXXX XXXX',
            suffixIcon: _getCardTypeIcon(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1565C0)),
            ),
          ),
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        const SizedBox(height: 16),

        // Expiry and CVV row
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expiry Date',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    onChanged: (value) {
                      setState(() => cardExpiry = value);
                    },
                    keyboardType: TextInputType.number,
                    maxLength: 5,
                    decoration: InputDecoration(
                      hintText: 'MM/YY',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF1565C0)),
                      ),
                    ),
                    style: GoogleFonts.poppins(fontSize: 14),
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
                    'CVV',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    onChanged: (value) {
                      setState(() => cardCVV = value);
                    },
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'XXX',
                      suffixIcon: const Icon(Icons.help_outline_rounded,
                          color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF1565C0)),
                      ),
                    ),
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Card Holder Name
        Text(
          'Card Holder Name',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          onChanged: (value) {
            setState(() => cardHolderName = value);
          },
          keyboardType: TextInputType.text,
          decoration: InputDecoration(
            hintText: 'Name as on card',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1565C0)),
            ),
          ),
          style: GoogleFonts.poppins(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildCashInfo() {
    final platformFee = proposedPrice * 0.1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_rounded,
                  color: Color(0xFF757575), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'You will pay Rs. ${proposedPrice.toStringAsFixed(0)} in cash when the provider arrives.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Platform fee of 10% (Rs. ${platformFee.toStringAsFixed(0)}) will be charged separately online.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
              color: color ?? Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _getCardTypeIcon() {
    if (cardNumber.startsWith('4')) {
      return const Icon(Icons.credit_card_rounded,
          color: Colors.grey, size: 20);
    } else if (cardNumber.startsWith('5')) {
      return const Icon(Icons.credit_card_rounded,
          color: Colors.grey, size: 20);
    } else {
      return const Icon(Icons.credit_card_rounded,
          color: Colors.grey, size: 20);
    }
  }

  Widget _buildStep5() {
    final package = packageData[selectedPackage]!;
    final providerPrice = package['price'];
    final priceDifference = proposedPrice - providerPrice;
    final platformFee = proposedPrice * 0.1;
    final totalAmount = proposedPrice + platformFee;
    final paymentMethodText = _getPaymentMethodDisplayText();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review Your Request',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Make sure everything looks right',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 32),

        // Summary card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Provider info
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF047A62).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Color(0xFF047A62),
                        size: 25,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.providerData['name']?.toString() ??
                                'Service Provider',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: Color(0xFFFFD700), size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '4.8 (24 reviews)',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                const Divider(color: Colors.grey, height: 1),
                const SizedBox(height: 20),

                // Package
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: package['color'],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.workspace_premium_rounded,
                        color: package['borderColor'],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            package['name'] + ' Package',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            '⏱ ${package['duration']}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Date and time
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.schedule_rounded,
                        color: Color(0xFF2196F3),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedDate != null
                                ? _formatDate(selectedDate!)
                                : 'Date not selected',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            selectedTime.isNotEmpty
                                ? selectedTime
                                : 'Time not selected',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Payment method - NEW
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Color(0xFFFF9800),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            paymentMethodText,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Total: Rs. ${totalAmount.toStringAsFixed(0)} (inc. fee)',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xFFFF9800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Price comparison
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.attach_money_rounded,
                        color: Color(0xFFFF9800),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rs. ${proposedPrice.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            priceDifference >= 0
                                ? 'Rs. ${priceDifference.toStringAsFixed(0)} above standard'
                                : 'Rs. ${priceDifference.abs().toStringAsFixed(0)} below standard',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: priceDifference >= 0
                                  ? const Color(0xFFFF9800)
                                  : const Color(0xFF4CAF50),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Special instructions
                if (specialInstructions.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Divider(color: Colors.grey, height: 1),
                  const SizedBox(height: 16),
                  Text(
                    'Special Instructions',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    specialInstructions,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],

                // PRO Options Summary
                if (_isProUser) ...[
                  const SizedBox(height: 20),
                  const Divider(color: Colors.grey, height: 1),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const MuawinProBadge(size: MuawinProBadgeSize.small),
                      const SizedBox(width: 8),
                      Text(
                        'PRO Options',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF047A62),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_selectedJobType != null) ...[
                    Text(
                      'Job Type: ${_selectedJobType == 'one_time' ? 'One-time Job' : 'Hiring'}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (_selectedDurationType != null) ...[
                    Text(
                      'Duration Type: ${_selectedDurationType!.toUpperCase()}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (_selectedJobType == 'hire_only' &&
                      _hireStartDate != null &&
                      _hireEndDate != null) ...[
                    Text(
                      'Hire Duration: ${_hireStartDate!.day}/${_hireStartDate!.month}/${_hireStartDate!.year} to ${_hireEndDate!.day}/${_hireEndDate!.month}/${_hireEndDate!.year}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (_selectedJobType == 'hire_only' &&
                      _hireStartTime != null &&
                      _hireEndTime != null) ...[
                    Text(
                      'Hire Time: ${_hireStartTime!.format(context)} to ${_hireEndTime!.format(context)}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (_isPriorityResponse) ...[
                    Row(
                      children: [
                        const Icon(Icons.flash_on_rounded,
                            color: Color(0xFFFFD700), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Priority Response Enabled',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ],

                // Special instructions
                if (specialInstructions.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Divider(color: Colors.grey, height: 1),
                  const SizedBox(height: 16),
                  Text(
                    'Special Instructions',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    specialInstructions,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],

                // Negotiation note
                if (negotiationNote.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Negotiation Note',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    negotiationNote,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Terms reminder
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F9FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF0EA5E9)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_rounded,
                      color: Color(0xFF0EA5E9), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Important Information',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0EA5E9),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Service Provider has 24 hours to respond to your request\nService Provider will accept or negotiate\nPayment will be processed after acceptance',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getPaymentMethodDisplayText() {
    switch (selectedPaymentMethod) {
      case 'jazzcash':
        return '💳 JazzCash - ${jazzCashNumber.isNotEmpty ? jazzCashNumber.replaceRange(3, 8, 'XXXXX') : 'Not entered'}';
      case 'easypaisa':
        return '💳 Easypaisa - ${easypaisaNumber.isNotEmpty ? easypaisaNumber.replaceRange(3, 8, 'XXXXX') : 'Not entered'}';
      case 'card':
        return '💳 Card - ${cardNumber.isNotEmpty ? '**** **** **** ${cardNumber.substring(cardNumber.length - 4)}' : 'Not entered'}';
      case 'cash':
        return 'Cash - Pay on arrival';
      default:
        return '💳 Payment method not selected';
    }
  }

  Widget _buildSuccessState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Success animation
        AnimatedBuilder(
          animation: _confettiController,
          builder: (context, child) {
            return Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: Color(0xFF047A62),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 60,
              ),
            );
          },
        ),
        const SizedBox(height: 32),

        Text(
          'Request Sent!',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF047A62),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        Text(
          '${widget.providerData['name']?.toString() ?? 'Provider'} will respond within 24 hours',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF047A62),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Back to Profile',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: isSuccess
              ? () {
                  setState(() {
                    isSuccess = false;
                    currentStep = 4; // Go back to review step
                  });
                }
              : _previousStep,
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Color(0xFF047A62),
          ),
        ),
        title: Text(
          isSuccess ? 'Success!' : 'Send Job Request',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        actions: [
          if (!isSuccess)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF047A62),
                ),
              ),
            ),
        ],
      ),
      body: isSuccess
          ? _buildSuccessState()
          : Column(
              children: [
                _buildStepIndicator(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _isProUser
                          ? [
                              _buildStep1(),
                              _buildStep3(),
                              _buildStep4(),
                              _buildStep5(),
                            ][currentStep]
                          : [
                              _buildStep1(),
                              _buildStep2(),
                              _buildStep3(),
                              _buildStep4(),
                              _buildStep5(),
                            ][currentStep],
                    ),
                  ),
                ),
                // Bottom navigation buttons
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (currentStep > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _previousStep,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: const BorderSide(color: Color(0xFF047A62)),
                            ),
                            child: Text(
                              'Edit Request',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF047A62),
                              ),
                            ),
                          ),
                        ),
                      if (currentStep > 0) const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isCurrentStepValid()
                              ? (currentStep == 4 ? _sendRequest : _nextStep)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF047A62),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            disabledBackgroundColor: Colors.grey.shade300,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Text(
                                  [
                                    'Choose Package →',
                                    'Select Time →',
                                    'Review Offer →',
                                    'Select Payment →',
                                    'Send Request 🚀'
                                  ][currentStep],
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
