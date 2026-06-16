import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import '../services/featured_ad_manager.dart';
import '../services/notification_manager.dart' as nm;
import '../services/location_service.dart';
import '../services/pro_status_checker.dart';

class SubscriptionPurchaseScreen extends StatefulWidget {
  const SubscriptionPurchaseScreen({
    super.key,
    required this.planName,
    required this.planPrice,
    required this.planPeriod,
    this.purchaseType = 'pro', // Default to 'pro'
    this.featuredAdUserId,
    this.featuredAdUserType,
    this.featuredAdTagline,
    this.featuredAdPlanType,
  });

  final String planName;
  final int planPrice;
  final String planPeriod;
  final String purchaseType; // 'pro' or 'featured_ad'
  final String? featuredAdUserId;
  final String? featuredAdUserType;
  final String? featuredAdTagline;
  final String? featuredAdPlanType;

  @override
  State<SubscriptionPurchaseScreen> createState() =>
      _SubscriptionPurchaseScreenState();
}

class _SubscriptionPurchaseScreenState extends State<SubscriptionPurchaseScreen>
    with SingleTickerProviderStateMixin {
  String _selectedPaymentMethod = '';
  bool _isLoading = false;
  bool _isSuccess = false;
  bool _hasActivePro = false;
  DateTime? _proExpiryDate;

  // Payment form data
  String _jazzCashNumber = '';
  String _easypaisaNumber = '';
  String _bankTransferScreenshot = ''; // Store uploaded screenshot path

  static const String _backendUrl =
      'https://muawin-nodejs-backend-production.up.railway.app';

  String? _stripeSessionId;

  // Featured ad specific data
  String? _featuredAdTagline;
  String? _featuredAdPlanType;
  String? _featuredAdUserType;
  String? _featuredAdUserId;
  String? _featuredAdUserName;
  String? _featuredAdUserCategory;
  double? _featuredAdUserRating;

  late AnimationController _successController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _checkExistingSubscription();

    // Initialize featured ad data extraction - will be processed in didChangeDependencies
    if (widget.purchaseType == 'featured_ad') {
      _featuredAdPlanType = widget.featuredAdPlanType;
      _featuredAdUserType = widget.featuredAdUserType;
      _featuredAdUserId = widget.featuredAdUserId;
      _featuredAdTagline = widget.featuredAdTagline;
      _featuredAdUserName = null;
      _featuredAdUserCategory = null;
      _featuredAdUserRating = null;
    }

    _successController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    ));
  }

  Future<void> _checkExistingSubscription() async {
    try {
      if (widget.purchaseType == 'pro') {
        final hasActive = await ProStatusChecker.hasActiveSubscription();
        final expiry = await ProStatusChecker.getProExpiryDate();
        setState(() {
          _hasActivePro = hasActive;
          _proExpiryDate = expiry;
        });
      } else {
        // Not a 'pro' purchase type, skip subscription check
      }
    } catch (e) {
      debugPrint('Error checking existing subscription: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Extract featured ad data from arguments if purchaseType is 'featured_ad'
    if (widget.purchaseType == 'featured_ad') {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _featuredAdTagline ??= args['tagline'];
        _featuredAdPlanType ??= args['planType'];
        _featuredAdUserType ??= args['userType'];
        _featuredAdUserId ??= args['userId'];
        _featuredAdUserName ??= args['userName'];
        _featuredAdUserCategory ??= args['userCategory'];
        _featuredAdUserRating ??= args['userRating'];
      }
    }
  }

  @override
  void dispose() {
    _successController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF047A62),
        title: Text(
          'Complete Purchase',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
      ),
      body: _isSuccess ? _buildSuccessScreen() : _buildPurchaseScreen(),
    );
  }

  Widget _buildPurchaseScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Summary Card
          _buildSummaryCard(),
          const SizedBox(height: 24),

          // Payment Method Section
          Text(
            'Select Payment Method',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),

          // Payment method cards
          _buildPaymentMethodCard(
            'jazzcash',
            'JazzCash',
            'Pay via JazzCash mobile wallet',
            const Color(0xFFE31837),
            'J',
            _buildJazzCashField(),
          ),

          _buildPaymentMethodCard(
            'easypaisa',
            'Easypaisa',
            'Pay via Easypaisa mobile wallet',
            const Color(0xFF2DB24A),
            'E',
            _buildEasypaisaField(),
          ),

          _buildPaymentMethodCard(
            'card',
            'Credit / Debit Card',
            'Visa, Mastercard all cards accepted',
            const Color(0xFF1565C0),
            'card_image', // Special indicator for card images
            null, // No inline card form — Stripe checkout opens in browser
          ),

          _buildPaymentMethodCard(
            'bank',
            'Bank Transfer',
            'Direct bank account transfer',
            const Color(0xFF6A1B9A),
            'bank_icon',
            _buildBankTransferField(),
          ),

          const SizedBox(height: 24),

          // Payment Summary
          _buildPaymentSummaryCard(),
          const SizedBox(height: 24),

          // Purchase button
          _buildPurchaseButton(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    if (widget.purchaseType == 'featured_ad') {
      // Featured Ad Summary Card
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Text(
                  '📢',
                  style: TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Featured Ad',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF047A62),
                      ),
                    ),
                    Text(
                      _featuredAdPlanType?.toUpperCase() ?? 'WEEKLY',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    if (_featuredAdTagline != null &&
                        _featuredAdTagline!.isNotEmpty)
                      Text(
                        'Your tagline: $_featuredAdTagline',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Featured ad benefits
            ...[
              'Featured in Customer Feed',
              'Your Custom Tagline Displayed',
              'More Booking Requests',
              'Priority Search Placement',
            ].map((benefit) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_rounded,
                        color: Color(0xFF047A62),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          benefit,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      );
    } else {
      // Original Muawin Pro Summary Card
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Muawin Pro',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF047A62),
                      ),
                    ),
                    Text(
                      '${widget.planName.toUpperCase()} PLAN',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Features list
            ...[
              'Pro Badge on Profile',
              'Reduced Platform Fee',
              'Priority Booking',
              'Extended Hiring',
              'Full Background Reports',
            ].map((feature) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_rounded,
                        color: Color(0xFF047A62),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feature,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      );
    }
  }

  Widget _buildPaymentMethodCard(
    String method,
    String title,
    String subtitle,
    Color accentColor,
    String? initial,
    Widget? expandedContent,
  ) {
    final isSelected = _selectedPaymentMethod == method;

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
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? accentColor.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.2),
              blurRadius: isSelected ? 10 : 4,
              offset: Offset(0, isSelected ? 4 : 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() => _selectedPaymentMethod = method);
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
                        child: initial == 'card_image'
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Visa logo
                                  Container(
                                    width: 18,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'VISA',
                                        style: GoogleFonts.poppins(
                                          fontSize: 5,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF1565C0),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 1),
                                  // Mastercard logo
                                  Container(
                                    width: 18,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: 14,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Colors.red,
                                              Colors.orange,
                                              Colors.yellow
                                            ],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(1),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : initial == 'bank_icon'
                                ? Icon(
                                    Icons.account_balance,
                                    color: accentColor,
                                    size: 20,
                                  )
                                : initial != null && initial.isNotEmpty
                                    ? Icon(
                                        Icons.account_balance_wallet_rounded,
                                        color: accentColor,
                                        size: 20,
                                      )
                                    : Center(
                                        child: Text(
                                          initial ?? '',
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: accentColor,
                                          ),
                                        ),
                                      ),
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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

                  // Expanded content
                  if (isSelected && expandedContent != null) ...[
                    const SizedBox(height: 16),
                    expandedContent,
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
          'JazzCash Mobile Number',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          onChanged: (value) {
            setState(() => _jazzCashNumber = value);
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
          'Easypaisa Mobile Number',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          onChanged: (value) {
            setState(() => _easypaisaNumber = value);
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


  Widget _buildBankTransferField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transfer Rs. ${widget.planPrice} to:',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Bank: Meezan Bank\nAccount: 0123456789\nTitle: Muawin Pvt Ltd',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'After transfer upload payment screenshot below',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          if (_bankTransferScreenshot.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Screenshot uploaded: ${_bankTransferScreenshot.split('/').last}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () async {
              if (!mounted) return;

              final ImagePicker picker = ImagePicker();
              final XFile? image =
                  await picker.pickImage(source: ImageSource.gallery);
              if (image != null && mounted) {
                setState(() {
                  _bankTransferScreenshot = image.path;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Screenshot uploaded successfully',
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            icon: _bankTransferScreenshot.isNotEmpty
                ? const Icon(Icons.check_circle_rounded, color: Colors.green)
                : const Icon(Icons.upload_rounded),
            label: Text(
              _bankTransferScreenshot.isNotEmpty
                  ? 'Screenshot Uploaded'
                  : 'Upload Screenshot',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A1B9A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                'Order Summary',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
              'Muawin Pro ${widget.planName}', 'Rs. ${widget.planPrice}'),
          _buildSummaryRow('Subscription Fee:', 'Rs. ${widget.planPrice}'),
          _buildSummaryRow('Tax (0%):', 'Rs. 0'),
          const Divider(color: Colors.grey),
          _buildSummaryRow('Total:', 'Rs. ${widget.planPrice}',
              isBold: true, color: const Color(0xFF047A62)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF047A62).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_rounded,
                    color: Color(0xFF047A62), size: 16),
                const SizedBox(width: 6),
                Text(
                  'Secured by Stripe',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF047A62),
                  ),
                ),
              ],
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

  Widget _buildPurchaseButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handlePurchase,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF047A62),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                widget.purchaseType == 'featured_ad'
                    ? 'Activate Featured Ad 📢 - Rs. ${widget.planPrice}'
                    : 'Upgrade to Pro - Rs. ${widget.planPrice}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }


  Future<void> _handlePurchase() async {
    try {
      if (!_isPaymentValid()) {
        _showError('Please fill in all required payment details correctly.');
        return;
      }

      // Block if already has active Pro subscription
      if (widget.purchaseType == 'pro' && _hasActivePro) {
        final expiryStr = _proExpiryDate != null
            ? '${_proExpiryDate!.day}/${_proExpiryDate!.month}/${_proExpiryDate!.year}'
            : 'unknown date';
        _showError(
            'You already have an active Muawin Pro subscription valid until $expiryStr. '
            'You can renew after your current plan expires.');
        return;
      }

      debugPrint('Selected payment method: $_selectedPaymentMethod');

      // Use Stripe for card payments
      if (_selectedPaymentMethod == 'card' ||
          _selectedPaymentMethod == 'Card' ||
          _selectedPaymentMethod == 'Credit/Debit Card') {
        setState(() => _isLoading = true);
        await _processWithStripe();
        return;
      }

      setState(() => _isLoading = true);

      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      try {
        final supabase = Supabase.instance.client;
        final user = supabase.auth.currentUser;

        if (user != null) {
          // Get profile
          final profile = await supabase
              .from('profiles')
              .select('id, role')
              .eq('user_id', user.id)
              .single();

          final profileId = profile['id'].toString();
          final role = profile['role'].toString();

          // Calculate plan duration in days
          int durationDays = 30;
          if (widget.planPeriod.toLowerCase().contains('3 month')) {
            durationDays = 90;
          } else if (widget.planPeriod.toLowerCase().contains('year') ||
              widget.planPeriod.toLowerCase().contains('annual')) {
            durationDays = 365;
          }

          final now = DateTime.now();
          final expiryDate = now.add(Duration(days: durationDays));

          if (widget.purchaseType == 'pro') {
            // Save subscription to Supabase
            await supabase.from('subscriptions').insert({
              'plan_name': widget.planName,
              'plan_price': widget.planPrice,
              'plan_period': widget.planPeriod,
              'is_active': true,
              'auto_renew': false,
              'start_date': now.toIso8601String().substring(0, 10),
              'end_date': expiryDate.toIso8601String().substring(0, 10),
              // Set the correct user type column
              'customer_id': role == 'customer'
                  ? await _getEntityId(supabase, profileId, 'customer')
                  : null,
              'provider_id': role == 'provider'
                  ? await _getEntityId(supabase, profileId, 'provider')
                  : null,
              'vendor_id': role == 'vendor'
                  ? await _getEntityId(supabase, profileId, 'vendor')
                  : null,
            });

            // Update is_pro flag based on role
            if (role == 'customer') {
              await supabase.from('customers').update({
                'is_pro': true,
                'pro_expiry_date': expiryDate.toIso8601String(),
              }).eq('profile_id', profileId);
            } else if (role == 'provider') {
              await supabase.from('providers').update({
                'is_pro': true,
                'pro_expiry_date': expiryDate.toIso8601String(),
              }).eq('profile_id', profileId);
            } else if (role == 'vendor') {
              await supabase.from('vendors').update({
                'is_pro': true,
                'pro_expiry_date': expiryDate.toIso8601String(),
              }).eq('profile_id', profileId);
            }
          } else if (widget.purchaseType == 'featured_ad') {
            // Save featured ad to Supabase
            if (_featuredAdUserId != null && _featuredAdUserId!.isNotEmpty) {
              int adDurationDays;
              final planType = _featuredAdPlanType?.toLowerCase() ?? 'weekly';
              if (planType == 'daily') {
                adDurationDays = 1;
              } else if (planType == 'monthly') {
                adDurationDays = 30;
              } else {
                adDurationDays = 7; // weekly default
              }

              final adExpiry = now.add(Duration(days: adDurationDays));

              await supabase.from('featured_ads').insert({
                'provider_id': role == 'provider' ? _featuredAdUserId : null,
                'vendor_id': role == 'vendor' ? _featuredAdUserId : null,
                'ad_type': 'featured',
                'tagline': _featuredAdTagline ?? '',
                'plan_type': _featuredAdPlanType ?? 'basic',
                'plan_price': widget.planPrice,
                'payment_method': _selectedPaymentMethod,
                'payment_status': 'pending',
                'is_active': true,
                'impressions': 0,
                'clicks': 0,
                'user_type': role,
                'start_date': now.toIso8601String(),
                'end_date': adExpiry.toIso8601String(),
              });
            }
          }
        }
      } catch (e) {
        debugPrint('Error saving payment to Supabase: $e');
        // Continue to show success even if DB save fails
        // Payment simulation succeeded
      }

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isSuccess = true;
      });

      _successController.forward();

      // Send notifications (keep existing code)
      try {
        final notificationManager =
            Provider.of<nm.NotificationManager>(context, listen: false);

        if (widget.purchaseType == 'featured_ad') {
          notificationManager.sendNotification(
            receiverId: _featuredAdUserId ?? 'user_123',
            receiverType: _featuredAdUserType ?? 'provider',
            type: nm.NotificationType.proUpgradeSuccess,
            title: '📢 Your Profile is Now Featured!',
            body: 'Your profile is now visible to customers in featured ads!',
            priority: nm.NotificationPriority.high,
          );

          if (_featuredAdUserId != null &&
              _featuredAdUserType != null &&
              _featuredAdUserName != null &&
              _featuredAdUserCategory != null &&
              _featuredAdUserRating != null &&
              _featuredAdPlanType != null &&
              _featuredAdTagline != null) {
            final userLocation = await LocationService.getCurrentLocation();
            FeaturedAdManager().purchaseFeaturedAd(
              userId: _featuredAdUserId!,
              userType: _featuredAdUserType!,
              userName: _featuredAdUserName!,
              userCategory: _featuredAdUserCategory!,
              userRating: _featuredAdUserRating!,
              userDistance: 5.0,
              tagline: _featuredAdTagline!,
              planType: _featuredAdPlanType!,
              planPrice: widget.planPrice,
              userLatitude: userLocation?.latitude,
              userLongitude: userLocation?.longitude,
            );
          }
        } else {
          notificationManager.sendNotification(
            receiverId: 'customer_123',
            receiverType: 'customer',
            type: nm.NotificationType.proUpgradeSuccess,
            title: '👑 Welcome to Muawin Pro!',
            body: 'Your account has been upgraded to Muawin Pro!',
            priority: nm.NotificationPriority.high,
          );
        }
      } catch (e) {
        debugPrint('Error sending notification: $e');
      }
    } catch (e, stackTrace) {
      debugPrint('=== HANDLE PURCHASE ERROR ===');
      debugPrint('Error: $e');
      debugPrint('Stack: $stackTrace');
    }
  }

  Future<String?> _getEntityId(
      SupabaseClient supabase, String profileId, String role) async {
    try {
      final table = role == 'customer'
          ? 'customers'
          : role == 'provider'
              ? 'providers'
              : 'vendors';
      final response = await supabase
          .from(table)
          .select('id')
          .eq('profile_id', profileId)
          .single();
      return response['id']?.toString();
    } catch (e) {
      debugPrint('Error getting entity id: $e');
      return null;
    }
  }

  Future<void> _processWithStripe() async {
    try {
      final orderId =
          'muawin_${DateTime.now().millisecondsSinceEpoch}';

      // Get plan name for display
      final planName = '${widget.planName} - ${widget.purchaseType == 'pro' ? 'Muawin Pro' : 'Featured Ad'}';

      final response = await http.post(
        Uri.parse('$_backendUrl/api/stripe/create-checkout'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'amount': widget.planPrice,
          'currency': 'pkr',
          'orderId': orderId,
          'planName': planName,
        }),
      );

      final data = json.decode(response.body);

      if (data['success'] != true) {
        throw Exception(
            data['message'] ?? 'Payment initialization failed');
      }

      final checkoutUrl = data['checkout_url']?.toString();
      final sessionId = data['session_id']?.toString();

      if (checkoutUrl == null) {
        throw Exception('No checkout URL received');
      }

      _stripeSessionId = sessionId;

      final uri = Uri.parse(checkoutUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (mounted) {
          setState(() => _isLoading = false);
          _showStripeWaitingDialog();
        }
      } else {
        throw Exception('Could not open payment page');
      }

    } catch (e) {
      debugPrint('Stripe error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _showStripeWaitingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.payment, color: Color(0xFF047A62)),
            const SizedBox(width: 8),
            Text(
              'Complete Payment',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.open_in_browser,
                size: 48, color: Colors.blue),
            const SizedBox(height: 16),
            Text(
              'Stripe checkout has opened in your browser.\n\nUse test card:\n4242 4242 4242 4242\nExpiry: 12/26  CVV: 123\n\nOnce payment is done, tap "I have paid".',
              style: GoogleFonts.poppins(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isLoading = false);
            },
            child: Text('Cancel',
                style: GoogleFonts.poppins(
                    color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _verifyStripePayment();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF047A62),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('I have paid',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyStripePayment() async {
    setState(() => _isLoading = true);
    try {
      if (_stripeSessionId == null || _stripeSessionId!.isEmpty) {
        throw Exception('No payment session found');
      }

      final response = await http.post(
        Uri.parse('$_backendUrl/api/stripe/verify'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'session_id': _stripeSessionId}),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Verification timed out'),
      );

      debugPrint('Verify response status: ${response.statusCode}');
      debugPrint('Verify response body: ${response.body}');

      final data = json.decode(response.body);
      debugPrint('Payment status: ${data['payment_status']}');

      if (data['success'] == true) {
        await _savePaymentToSupabase();

        if (mounted) {
          setState(() {
            _isLoading = false;
            _isSuccess = true;
          });
          _successController.forward();
        }
        return;
      } else {
        // If payment_status is 'unpaid', customer hasn't paid yet
        final status = data['payment_status']?.toString() ?? 'unknown';
        if (status == 'unpaid') {
          throw Exception(
            'Payment not completed. Please complete payment on Stripe first.');
        } else {
          throw Exception(data['message'] ?? 'Payment verification failed');
        }
      }
    } on Exception catch (e) {
      debugPrint('Stripe verify error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      debugPrint('Unexpected error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unexpected error. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _savePaymentToSupabase() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final profile = await supabase
          .from('profiles')
          .select('id, role')
          .eq('user_id', user.id)
          .single();

      final profileId = profile['id'].toString();
      final role = profile['role'].toString();

      int durationDays = 30;
      if (widget.planPeriod.toLowerCase().contains('3 month')) {
        durationDays = 90;
      } else if (widget.planPeriod.toLowerCase().contains('year') ||
          widget.planPeriod.toLowerCase().contains('annual')) {
        durationDays = 365;
      }

      final now = DateTime.now();
      final expiryDate = now.add(Duration(days: durationDays));

      await supabase.from('subscriptions').insert({
        'plan_name': widget.planName,
        'plan_price': widget.planPrice,
        'plan_period': widget.planPeriod,
        'is_active': true,
        'auto_renew': false,
        'start_date': now.toIso8601String().substring(0, 10),
        'end_date': expiryDate.toIso8601String().substring(0, 10),
        'customer_id': role == 'customer'
            ? await _getEntityId(supabase, profileId, 'customer')
            : null,
        'provider_id': role == 'provider'
            ? await _getEntityId(supabase, profileId, 'provider')
            : null,
        'vendor_id': role == 'vendor'
            ? await _getEntityId(supabase, profileId, 'vendor')
            : null,
      });

      if (role == 'customer') {
        await supabase.from('customers').update({
          'is_pro': true,
          'pro_expiry_date': expiryDate.toIso8601String(),
        }).eq('profile_id', profileId);
      } else if (role == 'provider') {
        await supabase.from('providers').update({
          'is_pro': true,
          'pro_expiry_date': expiryDate.toIso8601String(),
        }).eq('profile_id', profileId);
      } else if (role == 'vendor') {
        await supabase.from('vendors').update({
          'is_pro': true,
          'pro_expiry_date': expiryDate.toIso8601String(),
        }).eq('profile_id', profileId);
      }
    } catch (e) {
      debugPrint('Error saving payment: $e');
    }
  }

  bool _isPaymentValid() {
    // Card uses Stripe checkout in browser — no inline form validation needed
    if (_selectedPaymentMethod == 'card') return true;
    switch (_selectedPaymentMethod) {
      case 'jazzcash':
        return _jazzCashNumber.length == 11 && _jazzCashNumber.startsWith('03');
      case 'easypaisa':
        return _easypaisaNumber.length == 11 &&
            _easypaisaNumber.startsWith('03');
      case 'bank':
        return true; // Bank transfer always valid (screenshot upload handled separately)
      default:
        return false;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildSuccessScreen() {
    if (widget.purchaseType == 'featured_ad') {
      // Featured Ad Success Screen
      final screenWidth = MediaQuery.of(context).size.width;
      final isSmallScreen = screenWidth < 360;

      return SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: 32,
            horizontal: screenWidth * 0.05,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),

              // Success animation
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Megaphone icon
                        Container(
                          width: isSmallScreen
                              ? screenWidth * 0.25
                              : screenWidth * 0.3,
                          height: isSmallScreen
                              ? screenWidth * 0.25
                              : screenWidth * 0.3,
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '📢',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 48 : 60,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 20 : 32),

                        // Success message
                        Text(
                          "You're Now Featured!",
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 22 : 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your profile is now live in customer feeds',
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 14 : 16,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: isSmallScreen ? 16 : 24),

                        // End date
                        Text(
                          'Your ad is active until ${_getEndDate()}',
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 12 : 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: isSmallScreen ? 20 : 24),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      );
    } else {
      // Original Muawin Pro Success Screen
      return SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),

                // Success animation
                AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Elegant success icon
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: const Color(0xFF047A62),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF047A62)
                                      .withValues(alpha: 0.2),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Success message
                          Text(
                            'Welcome to Muawin Pro',
                            style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF047A62),
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Your account has been successfully upgraded',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                              letterSpacing: 0.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),

                          // Plan details card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  widget.planName.toUpperCase(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Rs. ${widget.planPrice}/${widget.planPeriod}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF047A62),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Start button
                          SizedBox(
                            width: 240,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                // Safely pop back to home screen
                                Navigator.of(context)
                                    .popUntil((route) => route.isFirst);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF047A62),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Continue',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      );
    }
  }

  String _getEndDate() {
    final now = DateTime.now();
    final endDate = now.add(const Duration(days: 7)); // Default to weekly
    return '${endDate.day}/${endDate.month}/${endDate.year}';
  }
}
