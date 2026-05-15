import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/featured_ad_manager.dart';
import '../services/notification_manager.dart' as nm;
import '../services/location_service.dart';

class SubscriptionPurchaseScreen extends StatefulWidget {
  const SubscriptionPurchaseScreen({
    super.key,
    required this.planName,
    required this.planPrice,
    required this.planPeriod,
    this.purchaseType = 'pro', // Default to 'pro'
  });

  final String planName;
  final int planPrice;
  final String planPeriod;
  final String purchaseType; // 'pro' or 'featured_ad'

  @override
  State<SubscriptionPurchaseScreen> createState() =>
      _SubscriptionPurchaseScreenState();
}

class _SubscriptionPurchaseScreenState extends State<SubscriptionPurchaseScreen>
    with SingleTickerProviderStateMixin {
  String _selectedPaymentMethod = '';
  bool _isLoading = false;
  bool _isSuccess = false;

  // Payment form data
  String _jazzCashNumber = '';
  String _easypaisaNumber = '';
  String _cardNumber = '';
  String _cardExpiry = '';
  String _cardCVV = '';
  String _cardHolderName = '';
  String _bankTransferScreenshot = ''; // Store uploaded screenshot path

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

    // Initialize featured ad data extraction - will be processed in didChangeDependencies
    if (widget.purchaseType == 'featured_ad') {
      _featuredAdPlanType = null;
      _featuredAdUserType = null;
      _featuredAdUserId = null;
      _featuredAdUserName = null;
      _featuredAdUserCategory = null;
      _featuredAdTagline = null;
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Extract featured ad data from arguments if purchaseType is 'featured_ad'
    if (widget.purchaseType == 'featured_ad') {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _featuredAdTagline = args['tagline'];
        _featuredAdPlanType = args['planType'];
        _featuredAdUserType = args['userType'];
        _featuredAdUserId = args['userId'];
        _featuredAdUserName = args['userName'];
        _featuredAdUserCategory = args['userCategory'];
        _featuredAdUserRating = args['userRating'];
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
            _buildCardFields(),
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
            setState(() => _cardNumber = formatted);
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
                      setState(() => _cardExpiry = value);
                    },
                    keyboardType: TextInputType.number,
                    maxLength: 5,
                    decoration: InputDecoration(
                      hintText: 'MM/YY',
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
                      setState(() => _cardCVV = value);
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
            setState(() => _cardHolderName = value);
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
                  'Secured by Safepay',
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

  Widget _getCardTypeIcon() {
    if (_cardNumber.startsWith('4')) {
      return const Icon(Icons.credit_card_rounded,
          color: Colors.grey, size: 20);
    } else if (_cardNumber.startsWith('5')) {
      return const Icon(Icons.credit_card_rounded,
          color: Colors.grey, size: 20);
    } else {
      return const Icon(Icons.credit_card_rounded,
          color: Colors.grey, size: 20);
    }
  }

  Future<void> _handlePurchase() async {
    // Validate payment fields
    if (!_isPaymentValid()) {
      _showError('Please fill in all required payment details correctly.');
      return;
    }

    setState(() => _isLoading = true);

    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _isSuccess = true;
    });

    // Trigger success animation
    _successController.forward();

    // Send notification and create featured ad
    try {
      final notificationManager =
          Provider.of<nm.NotificationManager>(context, listen: false);

      if (widget.purchaseType == 'featured_ad') {
        // Send featured ad activation notification
        notificationManager.sendNotification(
          receiverId: _featuredAdUserId ?? 'user_123',
          receiverType: _featuredAdUserType ?? 'provider',
          type: nm.NotificationType
              .proUpgradeSuccess, // Using existing enum for now
          title: '📢 Your Profile is Now Featured!',
          body:
              'Your profile is now visible to customers in featured ads. Get ready for more bookings!',
          priority: nm.NotificationPriority.high,
        );

        // Create featured ad with location data
        if (_featuredAdUserId != null &&
            _featuredAdUserType != null &&
            _featuredAdUserName != null &&
            _featuredAdUserCategory != null &&
            _featuredAdUserRating != null &&
            _featuredAdPlanType != null &&
            _featuredAdTagline != null) {
          // Get user location for featured ad
          final userLocation = await LocationService.getCurrentLocation();

          FeaturedAdManager().purchaseFeaturedAd(
            userId: _featuredAdUserId!,
            userType: _featuredAdUserType!,
            userName: _featuredAdUserName!,
            userCategory: _featuredAdUserCategory!,
            userRating: _featuredAdUserRating!,
            userDistance: 5.0, // Default distance
            tagline: _featuredAdTagline!,
            planType: _featuredAdPlanType!,
            planPrice: widget.planPrice,
            userLatitude: userLocation?.latitude,
            userLongitude: userLocation?.longitude,
          );
        }
      } else {
        // Original Muawin Pro notification
        notificationManager.sendNotification(
          receiverId: 'customer_123', // Placeholder user ID
          receiverType: 'customer',
          type: nm.NotificationType.proUpgradeSuccess,
          title: '👑 Welcome to Muawin Pro!',
          body:
              'Your account has been successfully upgraded to Muawin Pro. Enjoy all premium features!',
          priority: nm.NotificationPriority.high,
        );
      }
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  bool _isPaymentValid() {
    switch (_selectedPaymentMethod) {
      case 'jazzcash':
        return _jazzCashNumber.length == 11 && _jazzCashNumber.startsWith('03');
      case 'easypaisa':
        return _easypaisaNumber.length == 11 &&
            _easypaisaNumber.startsWith('03');
      case 'card':
        return _cardNumber.replaceAll(' ', '').length == 16 &&
            _cardExpiry.isNotEmpty &&
            _cardCVV.length >= 3 &&
            _cardHolderName.isNotEmpty;
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
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),

          // Success animation
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
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
                            color:
                                const Color(0xFF047A62).withValues(alpha: 0.2),
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
                          Navigator.of(context).pop(); // Pop success screen
                          Navigator.of(context).pop(); // Pop purchase screen
                          Navigator.of(context)
                              .pop(); // Pop get featured overlay
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
          const Spacer(),
        ],
      );
    }
  }

  String _getEndDate() {
    final now = DateTime.now();
    final endDate = now.add(const Duration(days: 7)); // Default to weekly
    return '${endDate.day}/${endDate.month}/${endDate.year}';
  }
}
