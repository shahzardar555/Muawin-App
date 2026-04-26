import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/subscription_purchase_screen.dart';

class GetFeaturedOverlay extends StatefulWidget {
  final String userType;
  final String userName;
  final String userCategory;
  final double userRating;
  final String userId;

  const GetFeaturedOverlay({
    super.key,
    required this.userType,
    required this.userName,
    required this.userCategory,
    required this.userRating,
    required this.userId,
  });

  @override
  State<GetFeaturedOverlay> createState() => _GetFeaturedOverlayState();
}

class _GetFeaturedOverlayState extends State<GetFeaturedOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  String _selectedPlan = 'weekly'; // Default selected plan
  String _tagline = '';
  bool _isTaglineValid = false;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));
    _shimmerController.repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 128),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with gradient and shimmer
                  _buildHeader(),

                  const SizedBox(height: 24),

                  // Tagline section
                  _buildTaglineSection(),

                  const SizedBox(height: 24),

                  // Plan selection section
                  _buildPlanSelectionSection(),

                  const SizedBox(height: 24),

                  // Benefits section
                  _buildBenefitsSection(),

                  const SizedBox(height: 24),

                  // Bottom section
                  _buildBottomSection(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF047A62), Color(0xFF035C4A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 77),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 16),

              // Icon and title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '📢',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Get Featured',
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Reach more customers today!',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaglineSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Your Tagline',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'A short catchy phrase (4-5 words)',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),

          // Text input field
          TextField(
            onChanged: (value) {
              setState(() {
                _tagline = value;
                _isTaglineValid = value.trim().isNotEmpty && value.length <= 40;
              });
            },
            maxLength: 40,
            decoration: InputDecoration(
              hintText: 'e.g. Trusted Expert Near You',
              hintStyle: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade400,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF047A62), width: 2),
              ),
              counterText: '${_tagline.length}/40',
              counterStyle: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 8),

          // Preview
          if (_tagline.isNotEmpty)
            Text(
              'Preview: $_tagline',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlanSelectionSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Your Plan',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),

          // Daily plan
          _buildPlanCard(
            'daily',
            'Daily',
            'Rs. 99',
            '/day',
            'Perfect for trying it out',
            '~50-100 customer views',
            '☀️',
            null,
          ),

          const SizedBox(height: 12),

          // Weekly plan
          _buildPlanCard(
            'weekly',
            'Weekly',
            'Rs. 500',
            '/week',
            'Great for steady bookings',
            '~350-700 customer views',
            '📅',
            'Popular Choice',
          ),

          const SizedBox(height: 12),

          // Monthly plan
          _buildPlanCard(
            'monthly',
            'Monthly',
            'Rs. 1,800',
            '/month',
            'Maximum visibility guaranteed',
            '~1,500-3,000 customer views',
            '🏆',
            'Best Value 🔥',
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
    String planId,
    String planName,
    String price,
    String period,
    String description,
    String reach,
    String icon,
    String? badge,
  ) {
    final isSelected = _selectedPlan == planId;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlan = planId;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        transform: Matrix4.identity()
          ..scaleByDouble(
              isSelected ? 1.02 : 1.0, isSelected ? 1.02 : 1.0, 1.0, 1.0),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF047A62) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF047A62).withValues(alpha: 51)
                  : Colors.black.withValues(alpha: 13),
              blurRadius: isSelected ? 10 : 4,
              offset: Offset(0, isSelected ? 4 : 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge and plan info
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (badge != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: badge == 'Best Value 🔥'
                                      ? Colors.amber
                                      : const Color(0xFF047A62),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  badge,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            Text(
                              icon,
                              style: const TextStyle(fontSize: 24),
                            ),
                            Text(
                              planName,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Price and period
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            price,
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF047A62),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            period,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    reach,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  // Savings for monthly
                  if (planId == 'monthly')
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Save Rs. 180 vs weekly',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF047A62),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Checkmark for selected
            if (isSelected)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFF047A62),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What you get:',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          _buildBenefitTile(
            'Featured in Customer Feed',
            'Your profile shown at top of customer home screen',
          ),
          const SizedBox(height: 12),
          _buildBenefitTile(
            'Your Custom Tagline',
            'Customers see your catchy tagline with your profile',
          ),
          const SizedBox(height: 12),
          _buildBenefitTile(
            'More Bookings',
            'Featured profiles get 3x more booking requests',
          ),
          const SizedBox(height: 12),
          _buildBenefitTile(
            'Priority Visibility',
            'Shown before non-featured profiles in search results',
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitTile(String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Color(0xFF047A62),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            color: Colors.white,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSection() {
    final planPrices = {
      'daily': 99,
      'weekly': 500,
      'monthly': 1800,
    };

    final selectedPrice = planPrices[_selectedPlan] ?? 500;
    final planNames = {
      'daily': 'Daily',
      'weekly': 'Weekly',
      'monthly': 'Monthly',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Selected plan summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${planNames[_selectedPlan]} Plan selected - Rs. $selectedPrice/${_selectedPlan == 'daily' ? 'day' : _selectedPlan == 'weekly' ? 'week' : 'month'}',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Error message if tagline empty
          if (!_isTaglineValid)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: Text(
                'Please add a tagline to continue',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.red,
                ),
              ),
            ),

          const SizedBox(height: 16),

          // CTA button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isTaglineValid
                  ? () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => SubscriptionPurchaseScreen(
                            planName: _selectedPlan,
                            planPrice: selectedPrice,
                            planPeriod: _selectedPlan == 'weekly'
                                ? '1 week'
                                : '1 month',
                            purchaseType: 'featured_ad',
                          ),
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF047A62),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                'Continue to Payment →',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Security text
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '🔒 Secure payment via Safepay',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          Text(
            'Your ad goes live immediately after payment',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
