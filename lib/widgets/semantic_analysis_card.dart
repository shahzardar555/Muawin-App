import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SemanticAnalysisCard extends StatefulWidget {
  final String providerName;
  final double overallRating;
  final int totalReviews;
  final int totalJobs;
  final String category;
  final List<String> recentReviews;
  final bool isVendor;

  const SemanticAnalysisCard({
    super.key,
    required this.providerName,
    required this.overallRating,
    required this.totalReviews,
    required this.totalJobs,
    required this.category,
    required this.recentReviews,
    this.isVendor = false,
  });

  @override
  State<SemanticAnalysisCard> createState() => _SemanticAnalysisCardState();
}

class _SemanticAnalysisCardState extends State<SemanticAnalysisCard>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _shimmerController;
  late AnimationController _confidenceController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _confidenceAnimation;

  bool _showShimmer = true;
  String _analysisText = '';

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _confidenceController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );
    _confidenceAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _confidenceController, curve: Curves.easeOut),
    );

    _entranceController.forward();

    // Start shimmer and show analysis after delay
    if (widget.totalReviews > 0) {
      _shimmerController.repeat();
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _showShimmer = false;
            _analysisText = _generateMockAnalysis();
          });
          _confidenceController.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _shimmerController.dispose();
    _confidenceController.dispose();
    super.dispose();
  }

  String _generateMockAnalysis() {
    final name = widget.providerName;
    final rating = widget.overallRating;
    final reviews = widget.totalReviews;
    final jobs = widget.totalJobs;
    final category = widget.category;
    final professional = widget.isVendor ? 'vendor' : 'professional';
    final jobText = widget.isVendor ? 'orders' : 'jobs';

    if (rating >= 4.5 && reviews >= 20) {
      return '$name stands out as one of the most trusted $category $professional on Muawin, maintaining an exceptional $rating-star rating across $jobs completed $jobText. Customer reviews consistently highlight their reliability, professional conduct, and high quality of work. Their strong track record suggests a low-risk booking with high satisfaction likelihood. Muawin AI confidently recommends this $professional.';
    } else if (rating >= 4.5 && reviews < 20) {
      return '$name is a promising $category $professional with an impressive $rating-star rating in their early Muawin journey. While their review count is still growing, existing customers speak highly of their work quality and punctuality. Their strong start suggests a reliable choice for customers willing to support emerging talent. Early indicators are very positive.';
    } else if (rating >= 3.5) {
      return '$name is a capable $category $professional with a solid $rating-star rating from $reviews customer reviews. Analysis of their feedback reveals consistent performance with occasional areas for improvement. Most customers report satisfactory experiences with their service. A reasonable choice with generally positive customer sentiment.';
    } else {
      return '$name\'s current $rating-star rating from $reviews reviews suggests mixed customer experiences. While some customers report satisfactory service, others have noted areas needing improvement. Muawin AI recommends reviewing individual feedback carefully before booking. Consider reaching out to the $professional directly to discuss your specific requirements.';
    }
  }

  String _getSentimentLabel() {
    if (widget.overallRating >= 4.5) return 'Highly Positive';
    if (widget.overallRating >= 3.5) return 'Positive';
    if (widget.overallRating >= 2.5) return 'Mixed';
    return 'Concerning';
  }

  String _getSentimentEmoji() {
    if (widget.overallRating >= 4.5) return '😊';
    if (widget.overallRating >= 3.5) return '🙂';
    if (widget.overallRating >= 2.5) return '😐';
    return '😟';
  }

  Color _getSentimentColor() {
    if (widget.overallRating >= 4.5) return Colors.green;
    if (widget.overallRating >= 3.5) return Colors.blue;
    if (widget.overallRating >= 2.5) return Colors.orange;
    return Colors.red;
  }

  String _getReliabilityLabel() {
    if (widget.totalJobs > 50) return '✅ Highly Reliable';
    if (widget.totalJobs > 20) return '✅ Reliable';
    if (widget.totalJobs > 5) return '⚡ Growing';
    return '🆕 New';
  }

  String _getExperienceLabel() {
    if (widget.totalJobs > 50 && widget.overallRating >= 4.5) {
      return '🏆 Expert';
    }
    if (widget.totalJobs > 20 && widget.overallRating >= 4.0) {
      return '⭐ Experienced';
    }
    if (widget.totalJobs > 5) return '📈 Developing';
    return '🌱 Beginner';
  }

  double _getConfidenceValue() {
    if (widget.totalReviews >= 20) return 0.92;
    if (widget.totalReviews >= 10) return 0.78;
    if (widget.totalReviews >= 5) return 0.65;
    return 0.45;
  }

  String _getConfidenceText() {
    if (widget.totalReviews >= 20) return '92% confidence';
    if (widget.totalReviews >= 10) return '78% confidence';
    if (widget.totalReviews >= 5) return '65% confidence';
    return '45% confidence';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Semantics(
              label: 'AI Analysis for ${widget.providerName}',
              child: GestureDetector(
                onLongPress: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'This analysis is generated by Muawin AI based on verified customer reviews and ratings',
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                      backgroundColor: const Color(0xFF047A62),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF047A62).withValues(alpha: 0.08),
                        const Color(0xFF047A62).withValues(alpha: 0.03),
                      ],
                    ),
                    border: Border.all(
                      color: const Color(0xFF047A62).withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF047A62).withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: widget.totalReviews == 0
                        ? _buildNoDataState()
                        : _buildContent(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoDataState() {
    return Column(
      children: [
        const Icon(
          Icons.hourglass_empty,
          size: 48,
          color: Color(0xFF047A62),
        ),
        const SizedBox(height: 12),
        Text(
          'Not enough data yet',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF047A62),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Analysis will be available after first few reviews',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 12),
        _buildDivider(),
        const SizedBox(height: 12),
        _buildSentimentIndicators(),
        const SizedBox(height: 16),
        _buildAnalysisSection(),
        const SizedBox(height: 16),
        _buildConfidenceMeter(),
        const SizedBox(height: 12),
        _buildFooter(),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF047A62),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analysis by Muawin AI',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF047A62),
                ),
              ),
              Text(
                'Semantic Review Analysis',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: const Color(0xFF047A62).withValues(alpha: 0.15),
    );
  }

  Widget _buildSentimentIndicators() {
    final sentimentColor = _getSentimentColor();
    final sentimentBg = sentimentColor.withValues(alpha: 0.1);
    final sentimentTextColor = sentimentColor.withValues(alpha: 0.8);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildPill(
            '${_getSentimentEmoji()} ${_getSentimentLabel()}',
            sentimentBg,
            sentimentTextColor,
          ),
          const SizedBox(width: 8),
          _buildPill(
            _getReliabilityLabel(),
            Colors.blue.withValues(alpha: 0.1),
            Colors.blue.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 8),
          _buildPill(
            _getExperienceLabel(),
            Colors.purple.withValues(alpha: 0.1),
            Colors.purple.withValues(alpha: 0.8),
          ),
        ],
      ),
    );
  }

  Widget _buildPill(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildAnalysisSection() {
    if (_showShimmer) {
      return _buildShimmerEffect();
    }

    return AnimatedOpacity(
      opacity: _showShimmer ? 0 : 1,
      duration: const Duration(milliseconds: 500),
      child: Text(
        _analysisText,
        style: GoogleFonts.poppins(
          fontSize: 13,
          height: 1.6,
          color: Colors.black87,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ShimmerLine(
              width: 1.0,
              controller: _shimmerController,
            ),
            const SizedBox(height: 8),
            _ShimmerLine(
              width: 0.85,
              controller: _shimmerController,
            ),
            const SizedBox(height: 8),
            _ShimmerLine(
              width: 0.70,
              controller: _shimmerController,
            ),
          ],
        );
      },
    );
  }

  Widget _buildConfidenceMeter() {
    final confidenceValue = _getConfidenceValue();
    final confidenceText = _getConfidenceText();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI Confidence:',
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: AnimatedBuilder(
                  animation: _confidenceAnimation,
                  builder: (context, child) {
                    return FractionallySizedBox(
                      widthFactor: _confidenceAnimation.value * confidenceValue,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              confidenceText,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Text(
      '🤖 Generated by Muawin AI • Based on ${widget.totalReviews} verified reviews',
      style: GoogleFonts.poppins(
        fontSize: 10,
        color: Colors.grey,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}

class _ShimmerLine extends StatelessWidget {
  final double width;
  final AnimationController controller;

  const _ShimmerLine({
    required this.width,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Container(
          height: 12,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(6),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: FractionallySizedBox(
              widthFactor: width,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.grey.shade300,
                      Colors.grey.shade100,
                      Colors.grey.shade300,
                    ],
                    stops: [
                      controller.value - 0.3,
                      controller.value,
                      controller.value + 0.3,
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
