import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/subscription_purchase_screen.dart';

class MuawinProOverlay extends StatefulWidget {
  const MuawinProOverlay({super.key});

  @override
  State<MuawinProOverlay> createState() => _MuawinProOverlayState();
}

class _MuawinProOverlayState extends State<MuawinProOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;
  String _selectedPlan = 'monthly'; // Default selected plan

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(_shimmerController);
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
      color: Colors.white.withValues(alpha: 0.5 * 255),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1E293B), // slate-800
                Color(0xFF0F172A), // slate-900
                Color(0xFF1E293B), // slate-800
              ],
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 32),
                      _buildPlanSelection(),
                      const SizedBox(height: 32),
                      _buildFeaturesSection(),
                      const SizedBox(height: 32),
                      _buildBottomSection(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.yellow,
                Colors.yellow,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              // Crown and title
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Text(
                        'Muawin Pro',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        'Unlock best of Muawin',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlanSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Your Plan',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),

        // Weekly Plan
        _buildPlanCard(
          'weekly',
          'Weekly',
          'Rs. 10',
          '/week',
          null,
          const Color(0xFF047A62),
        ),

        // Monthly Plan (Most Popular)
        _buildPlanCard(
          'monthly',
          'Monthly',
          'Rs. 99',
          '/month',
          'Most Popular',
          const Color(0xFF047A62),
        ),

        // Yearly Plan (Best Value)
        _buildPlanCard(
          'yearly',
          'Yearly',
          'Rs. 1,000',
          '/year',
          'Best Value 🔥',
          const Color(0xFFFFA000),
        ),
      ],
    );
  }

  Widget _buildPlanCard(
    String planId,
    String planName,
    String price,
    String period,
    String? badge,
    Color badgeColor,
  ) {
    final isSelected = _selectedPlan == planId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedPlan = planId;
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            transform: Matrix4.identity()
              ..scaleByDouble(
                  isSelected ? 1.02 : 1.0, isSelected ? 1.02 : 1.0, 1.0, 1.0),
            decoration: BoxDecoration(
              color: isSelected ? Colors.yellow : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? Colors.yellow : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? Colors.yellow.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.05),
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
                      // Badge and plan info in a row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Plan name and price
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                  color: Colors.black,
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

                      // Savings text for yearly
                      if (planId == 'yearly')
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Save Rs. 188 vs monthly',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.black,
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
                        color: Color(0xFF367085),
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
        ),
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Everything included in all plans:',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),

        // Feature tiles
        _buildFeatureTile(
          'Pro Badge on Profile',
          'Stand out with an exclusive Muawin Pro badge on your profile',
        ),
        _buildFeatureTile(
          'Reduced Platform Fee',
          'Pay only 5% platform fee instead of standard 10%',
        ),
        _buildFeatureTile(
          'Priority Booking',
          'High rated service providers see Pro accounts on top of all job requests',
        ),
        _buildFeatureTile(
          'Extended Hiring',
          'Hire service providers for extended periods instead of one time visits only',
        ),
        _buildFeatureTile(
          'Full Background Reports',
          'Access complete background check reports of all service providers',
        ),
      ],
    );
  }

  Widget _buildFeatureTile(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Color(0xFF367085),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 12,
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
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Column(
      children: [
        // Selected plan summary
        Text(
          'You selected: ${_selectedPlan == 'weekly' ? 'Weekly' : _selectedPlan == 'monthly' ? 'Monthly' : 'Yearly'} Plan - Rs. ${_selectedPlan == 'weekly' ? '10' : _selectedPlan == 'monthly' ? '99' : '1,000'}/${_selectedPlan == 'weekly' ? 'week' : _selectedPlan == 'monthly' ? 'month' : 'year'}',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.8),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        // Main CTA button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Dismiss overlay
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SubscriptionPurchaseScreen(
                    planName: _selectedPlan,
                    planPrice: _selectedPlan == 'weekly'
                        ? 10
                        : _selectedPlan == 'monthly'
                            ? 99
                            : 1000,
                    planPeriod: _selectedPlan == 'weekly'
                        ? 'week'
                        : _selectedPlan == 'monthly'
                            ? 'month'
                            : 'year',
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Continue to Payment →',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Security and cancellation text
        Text(
          '🔒 Secure payment via Safepay',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'Cancel anytime • No hidden charges',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
