import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/notification_manager.dart' as nm;
import 'services/pro_status_checker.dart';
import 'services/job_request_limiter.dart';
import 'services/database_service.dart';
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
  int _selectedHour = 8;
  int _selectedMinute = 0;
  double proposedPrice = 800;
  String specialInstructions = '';
  String negotiationNote = '';
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  String _selectedLocation = '';

  // PRO-only options
  String? _selectedDurationType; // 'days', 'weeks', 'months'
  String? _selectedJobType; // 'one_time' or 'hiring'

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

  // Scroll controller for auto-scrolling to top on step change
  final ScrollController _scrollController = ScrollController();

  // Fetched packages loaded from Supabase
  List<Map<String, dynamic>> fetchedPackages = [];
  bool _isLoadingPackages = true;
  String? _packagesError;

  // Package styling per type (colors and badges only)
  final Map<String, Map<String, dynamic>> packageStyles = {
    'basic': {
      'color': const Color(0xFFE8F5E9),
      'borderColor': const Color(0xFF4CAF50),
    },
    'standard': {
      'color': const Color(0xFFE3F2FD),
      'borderColor': const Color(0xFF2196F3),
      'badge': 'Most Popular',
    },
    'premium': {
      'color': const Color(0xFFFFF8E1),
      'borderColor': const Color(0xFFFF9800),
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
    _checkProStatus();
    _loadPackages();
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

  // Load real packages from Supabase service_pricing_packages table
  Future<void> _loadPackages() async {
    setState(() {
      _isLoadingPackages = true;
      _packagesError = null;
    });
    try {
      final providerId = widget.providerData['id']?.toString() ?? '';
      if (providerId.isEmpty) {
        setState(() {
          _packagesError = 'Provider ID not found';
          _isLoadingPackages = false;
        });
        return;
      }
      final packages =
          await DatabaseService().getProviderPricingPackages(providerId);
      if (mounted) {
        setState(() {
          fetchedPackages = packages;
          _isLoadingPackages = false;
          // Auto-select first package
          if (packages.isNotEmpty) {
            selectedPackage =
                packages.first['package_type']?.toString() ?? 'basic';
            proposedPrice =
                double.tryParse(packages.first['price']?.toString() ?? '800') ??
                    800;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading packages: $e');
      if (mounted) {
        setState(() {
          _packagesError = 'Failed to load packages';
          _isLoadingPackages = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _confettiController.dispose();
    _scrollController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  /// Get the currently selected package map from fetchedPackages
  Map<String, dynamic>? get _selectedPackageMap {
    try {
      return fetchedPackages
          .firstWhere((p) => p['package_type']?.toString() == selectedPackage);
    } catch (_) {
      return null;
    }
  }

  /// Get the provider's price for the selected package
  double get _selectedPackagePrice {
    final pkg = _selectedPackageMap;
    if (pkg != null) {
      return double.tryParse(pkg['price']?.toString() ?? '0') ?? 0;
    }
    return proposedPrice;
  }

  /// Get style map for a package type
  Map<String, dynamic> _getPackageStyle(String packageType) {
    return packageStyles[packageType] ??
        {
          'color': Colors.grey.shade100,
          'borderColor': Colors.grey,
        };
  }

  List<DateTime> _getNext14Days() {
    final List<DateTime> days = [];
    final now = DateTime.now();
    for (int i = 0; i < 14; i++) {
      days.add(now.add(Duration(days: i)));
    }
    return days;
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

  /// Converts 12-hour time format (e.g. "2:00 PM") to 24-hour PostgreSQL TIME format (e.g. "14:00:00")
  String _convertTo24Hour(String time12h) {
    try {
      final parts = time12h.trim().split(' ');
      if (parts.length != 2) return time12h;
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      final minute = timeParts.length > 1 ? timeParts[1] : '00';
      final period = parts[1].toUpperCase();
      if (period == 'PM' && hour != 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;
      return '${hour.toString().padLeft(2, '0')}:$minute:00';
    } catch (e) {
      return time12h;
    }
  }

  void _nextStep() {
    if (currentStep < 4) {
      setState(() => currentStep++);
      _scrollToTop();
    }
  }

  void _previousStep() {
    if (currentStep > 0) {
      setState(() => currentStep--);
      _scrollToTop();
    }
  }

  void _scrollToTop() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  bool _isCurrentStepValid() {
    switch (currentStep) {
      case 0:
        return selectedPackage.isNotEmpty;
      case 1:
        return selectedDate != null && selectedTime.isNotEmpty;
      case 2:
        {
          final providerPrice = _selectedPackagePrice;
          if (providerPrice <= 0) return false;
          return proposedPrice >= providerPrice * 0.5 &&
              proposedPrice <= providerPrice * 1.5;
        }
      case 3:
        return _isPaymentMethodValid();
      case 4:
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

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      // Get current customer's profile and customer record
      final profile = await supabase
          .from('profiles')
          .select('id')
          .eq('user_id', user.id)
          .single();

      final customerRecord = await supabase
          .from('customers')
          .select('id')
          .eq('profile_id', profile['id'])
          .single();

      // Get provider ID from passed data
      final providerId = widget.providerData['id']?.toString();
      if (providerId == null) throw Exception('Provider ID not found');

      // Build the direct request data
      final requestData = {
        'customer_id': customerRecord['id'],
        'provider_id': providerId,
        'service_category':
            widget.providerData['service_category']?.toString() ?? '',
        'title':
            'Direct Request - ${widget.providerData['service_category']?.toString() ?? 'Service'}',
        'description':
            '${widget.providerData['service_category']?.toString() ?? 'Service'} request - $selectedPackage package',
        'package_type': selectedPackage,
        'proposed_price': proposedPrice,
        'scheduled_date': selectedDate != null
            ? '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}'
            : null,
        'scheduled_time':
            selectedTime.isNotEmpty ? _convertTo24Hour(selectedTime) : null,
        'special_instructions':
            specialInstructions.isNotEmpty ? specialInstructions : null,
        'negotiation_notes':
            negotiationNote.isNotEmpty ? negotiationNote : null,
        'duration_type': _selectedDurationType,
        'city': _cityController.text.trim().isNotEmpty
            ? _cityController.text.trim()
            : null,
        'area': _areaController.text.trim().isNotEmpty
            ? _areaController.text.trim()
            : null,
        'location': _selectedLocation.isNotEmpty ? _selectedLocation : null,
        'customer_is_pro': _isProUser,
        'status': 'pending',
      };

      // Check daily limit for non-PRO users
      if (!_isProUser) {
        final canSend = await JobRequestLimiter.canSendDirectRequest();
        if (!canSend) {
          final remaining =
              await JobRequestLimiter.getRemainingDirectRequests();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Daily limit reached ($remaining requests remaining). Non-PRO accounts can send 10 direct requests per day. Upgrade to Muawin PRO for unlimited requests.',
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
                backgroundColor: Colors.red.shade700,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          return;
        }
      }

      // Insert into direct_job_requests table
      await supabase.from('direct_job_requests').insert(requestData);

      if (!_isProUser) {
        await JobRequestLimiter.incrementDirectRequestCount();
      }

      if (!mounted) return;

      // Send notifications (keep exactly as before)
      try {
        final notificationManager =
            Provider.of<nm.NotificationManager>(context, listen: false);

        notificationManager.sendNotification(
          receiverId: providerId,
          receiverType: 'provider',
          type: nm.NotificationType.jobRequestReceived,
          title: '🎯 New Job Request!',
          body: 'A customer has sent you a direct job request',
          priority: nm.NotificationPriority.high,
          receiverProfileId: widget.providerData['profile_id']?.toString(),
        );

        notificationManager.sendNotification(
          receiverId: customerRecord['id'],
          receiverType: 'customer',
          type: nm.NotificationType.jobRequestSent,
          title: '✅ Request Sent Successfully!',
          body: 'Your job request has been sent to the provider',
          priority: nm.NotificationPriority.medium,
          receiverProfileId: profile['id']?.toString(),
        );
      } catch (e) {
        debugPrint('Error sending notifications: $e');
      }

      if (!mounted) return;
      setState(() {
        isLoading = false;
        isSuccess = true;
      });
      _confettiController.forward();
    } catch (e) {
      debugPrint('Error sending direct request: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send request: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        children: [
          for (int i = 0; i < 5; i++) ...[
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
                    ['Package', 'Date', 'Price', 'Pay', 'Review'][i],
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
        if (_isLoadingPackages)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: CircularProgressIndicator(
                color: Color(0xFF047A62),
              ),
            ),
          )
        else if (_packagesError != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 12),
                  Text(
                    _packagesError!,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.red[400],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadPackages,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF047A62),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          )
        else if (fetchedPackages.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    "This provider hasn't set up pricing packages yet",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ...fetchedPackages.map((pkg) {
            final packageType = pkg['package_type']?.toString() ?? '';
            final style = _getPackageStyle(packageType);
            final isSelected = selectedPackage == packageType;
            final pkgPrice =
                double.tryParse(pkg['price']?.toString() ?? '0') ?? 0;
            final pkgName =
                pkg['package_name']?.toString() ?? packageType.toUpperCase();
            final pkgDescription = pkg['description']?.toString() ?? '';
            final pkgDuration = pkg['duration']?.toString() ?? '';
            final pkgIncludes = pkg['includes'];
            final List<String> features = [];
            if (pkgIncludes is List) {
              for (final item in pkgIncludes) {
                features.add(item.toString());
              }
            } else if (pkgIncludes is String) {
              try {
                final parsed = jsonDecode(pkgIncludes);
                if (parsed is List) {
                  for (final item in parsed) {
                    features.add(item.toString());
                  }
                }
              } catch (_) {
                features.add(pkgIncludes);
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: style['color'],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        isSelected ? style['borderColor'] : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: style['borderColor'].withValues(alpha: 0.3),
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
                        selectedPackage = packageType;
                        proposedPrice = pkgPrice;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  pkgName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              if (style['badge'] != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: style['borderColor'],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    style['badge'],
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
                          Text(
                            'Rs. ${pkgPrice.toStringAsFixed(0)}/visit',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: style['borderColor'],
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (pkgDescription.isNotEmpty)
                            Text(
                              pkgDescription,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          if (pkgDescription.isNotEmpty)
                            const SizedBox(height: 12),
                          if (pkgDuration.isNotEmpty)
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
                                '⏱ $pkgDuration',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          if (pkgDuration.isNotEmpty)
                            const SizedBox(height: 12),
                          ...features.map<Widget>((feature) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: style['borderColor'],
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
          Row(
            children: [
              _buildDurationOption(
                label: 'One-time Job',
                value: 'one_time',
                selected: _selectedJobType == 'one_time',
                onTap: () {
                  setState(() {
                    _selectedJobType = 'one_time';
                  });
                },
              ),
              const SizedBox(width: 8),
              _buildDurationOption(
                label: 'Hiring',
                value: 'hiring',
                selected: _selectedJobType == 'hiring',
                onTap: () {
                  setState(() {
                    _selectedJobType = 'hiring';
                  });
                },
              ),
            ],
          ),
          if (_selectedJobType == 'hiring') ...[
            const SizedBox(height: 16),
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
          ],
        ],
      ),
    );
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
        Text(
          'Select Time',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildCustomTimePicker(),
        const SizedBox(height: 24),
        Text(
          'Your Location',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Let the provider know where to come',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _cityController,
          decoration: InputDecoration(
            labelText: 'City',
            hintText: 'e.g. Karachi',
            prefixIcon:
                const Icon(Icons.location_city, color: Color(0xFF047A62)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF047A62), width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _areaController,
          decoration: InputDecoration(
            labelText: 'Area / Neighbourhood',
            hintText: 'e.g. DHA Phase 5, Gulshan-e-Iqbal',
            prefixIcon: const Icon(Icons.map, color: Color(0xFF047A62)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF047A62), width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          onChanged: (value) => setState(() => _selectedLocation = value),
          decoration: InputDecoration(
            labelText: 'Full Address / Landmark (optional)',
            hintText: 'e.g. House 5, Street 3, near XYZ mosque',
            prefixIcon: const Icon(Icons.home, color: Color(0xFF047A62)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF047A62), width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        const SizedBox(height: 32),
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

  Widget _buildCustomTimePicker() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF047A62).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF047A62).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => _showHourPicker(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color:
                                const Color(0xFF047A62).withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _selectedHour.toString().padLeft(2, '0'),
                        style: GoogleFonts.poppins(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF047A62),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      ':',
                      style: GoogleFonts.poppins(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF047A62),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showMinutePicker(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color:
                                const Color(0xFF047A62).withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _selectedMinute.toString().padLeft(2, '0'),
                        style: GoogleFonts.poppins(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF047A62),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _selectedHour >= 12 ? 'PM' : 'AM',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF047A62),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                '6:00 AM',
                '7:00 AM',
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
                '8:00 PM',
              ].map((time) {
                final isSelected = selectedTime == time;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedTime = time;
                      _updateHourMinute(time);
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF047A62)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF047A62)
                            : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      time,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showCustomTimePicker,
                icon: const Icon(Icons.access_time_rounded, size: 18),
                label: Text(
                  'Choose Custom Time',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF047A62),
                  side: const BorderSide(color: Color(0xFF047A62)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateHourMinute(String time) {
    try {
      final parts = time.trim().split(' ');
      if (parts.length == 2) {
        final timeParts = parts[0].split(':');
        int hour = int.parse(timeParts[0]);
        final minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;
        final period = parts[1].toUpperCase();
        if (period == 'PM' && hour != 12) hour += 12;
        if (period == 'AM' && hour == 12) hour = 0;
        _selectedHour = hour;
        _selectedMinute = minute;
      }
    } catch (_) {}
  }

  void _showHourPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildScrollPicker(
        title: 'Select Hour',
        min: 1,
        max: 12,
        initial: _selectedHour > 12
            ? _selectedHour - 12
            : (_selectedHour == 0 ? 12 : _selectedHour),
        onSelected: (value) {
          final isPM = _selectedHour >= 12;
          setState(() {
            _selectedHour = isPM ? value + 12 : (value == 12 ? 0 : value);
            _updateSelectedTime();
          });
          Navigator.pop(context);
        },
        suffix: _selectedHour >= 12 ? 'PM' : 'AM',
      ),
    );
  }

  void _showMinutePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildScrollPicker(
        title: 'Select Minute',
        min: 0,
        max: 59,
        initial: _selectedMinute,
        step: 5,
        onSelected: (value) {
          setState(() {
            _selectedMinute = value;
            _updateSelectedTime();
          });
          Navigator.pop(context);
        },
        suffix: 'min',
      ),
    );
  }

  Widget _buildScrollPicker({
    required String title,
    required int min,
    required int max,
    required int initial,
    required Function(int) onSelected,
    int step = 1,
    String? suffix,
  }) {
    final items = <int>[];
    for (int i = min; i <= max; i += step) {
      items.add(i);
    }

    final initialIndex = items.indexOf(initial);
    final controller = FixedExtentScrollController(
        initialItem: initialIndex > 0 ? initialIndex : 0);

    return Container(
      height: 280,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    onSelected(items[controller.selectedItem]);
                  },
                  child: Text(
                    'Done',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF047A62),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListWheelScrollView.useDelegate(
              controller: controller,
              itemExtent: 44,
              perspective: 0.005,
              diameterRatio: 1.5,
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: items.length,
                builder: (context, index) {
                  final value = items[index];
                  final isSelected = value == items[controller.selectedItem];
                  return Center(
                    child: Text(
                      value.toString().padLeft(2, '0'),
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w400,
                        color: isSelected
                            ? const Color(0xFF047A62)
                            : Colors.grey.shade500,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCustomTimePicker() async {
    final initialTime = TimeOfDay(
      hour: _selectedHour,
      minute: _selectedMinute,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF047A62),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedHour = picked.hour;
        _selectedMinute = picked.minute;
        _updateSelectedTime();
      });
    }
  }

  void _updateSelectedTime() {
    final hour = _selectedHour;
    final minute = _selectedMinute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    selectedTime = '$hour12:${minute.toString().padLeft(2, '0')} $period';
  }

  Widget _buildStep3() {
    final providerPrice = _selectedPackagePrice;
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
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: max(
                  0.0,
                  (proposedPrice / maxPrice) *
                          MediaQuery.of(context).size.width -
                      64,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF047A62),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
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
              Positioned(
                left: (proposedPrice / maxPrice) *
                        (MediaQuery.of(context).size.width - 64) -
                    12,
                top: 8,
                child: GestureDetector(
                  onPanStart: (details) {},
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
                  onPanEnd: (details) {},
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
          maxLength: 19,
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
    final pkg = _selectedPackageMap;
    final pkgName =
        pkg?['package_name']?.toString() ?? selectedPackage.toUpperCase();
    _getPackageStyle(selectedPackage);
    final providerPrice = _selectedPackagePrice;
    final priceDifference = proposedPrice - providerPrice;
    final platformFee = proposedPrice * 0.1;
    final totalAmount = proposedPrice + platformFee;
    final paymentMethodText = _getPaymentMethodDisplayText();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // Two-column layout: icons column (fixed) + details column
                Center(
                  child: IntrinsicHeight(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icons column (fixed width)
                        Column(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF047A62)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.workspace_premium_rounded,
                                color: Color(0xFF047A62),
                                size: 20,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF047A62)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.schedule_rounded,
                                color: Color(0xFF047A62),
                                size: 20,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF047A62)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_rounded,
                                color: Color(0xFF047A62),
                                size: 20,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF047A62)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.attach_money_rounded,
                                color: Color(0xFF047A62),
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        // Details column
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Package details
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pkgName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  '⏱ ${pkg?['duration'] ?? ''}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Date and time details
                            Column(
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
                            const SizedBox(height: 16),
                            // Payment method details
                            Column(
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
                            const SizedBox(height: 16),
                            // Price comparison details
                            Column(
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
                          ],
                        ),
                      ],
                    ),
                  ),
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

                // Special instructions (duplicate)
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
        return '💳 JazzCash - ${jazzCashNumber.length >= 8 ? jazzCashNumber.replaceRange(3, 8, 'XXXXX') : '*****'}';
      case 'easypaisa':
        return '💳 Easypaisa - ${easypaisaNumber.length >= 8 ? easypaisaNumber.replaceRange(3, 8, 'XXXXX') : '*****'}';
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
                    currentStep = 4;
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
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: [
                      _buildStep1(),
                      _buildStep2(),
                      _buildStep3(),
                      _buildStep4(),
                      _buildStep5(),
                    ][currentStep],
                  ),
                ),
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
                              'Previous Step',
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
                                    'Send Request'
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
