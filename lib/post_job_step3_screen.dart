import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Step 3 Screen - Confirm Details
class PostJobStep3Screen extends StatelessWidget {
  final Map<String, dynamic>? selectedCategory;
  final String? location;
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final String? price;

  const PostJobStep3Screen({
    super.key,
    this.selectedCategory,
    this.location,
    this.selectedDate,
    this.selectedTime,
    this.price,
  });

  String _formatDateTime(DateTime? date, TimeOfDay? time) {
    if (date == null || time == null) return 'Not scheduled';
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    final month = months[date.month - 1];
    final day = '${date.day}th';
    final year = date.year;
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$month $day, $year at $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
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
                        // Step 2 (Completed)
                        Container(
                          width: 40,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Step 3 (Active)
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
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Headline - "Confirm Details"
                    Text(
                      'Confirm Details',
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
                      'STEP 3 OF 3',
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

              // Main Content Area
              Center(
                child: Container(
                  width: 400,
                  decoration: BoxDecoration(
                    color: const Color(0xFF90EE90).withAlpha(64),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  alignment: Alignment.topLeft,
                  padding: const EdgeInsets.all(40),
                  child: selectedCategory != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category Icon and Name Row
                            Row(
                              children: [
                                Container(
                                  width: 70,
                                  height: 70,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    selectedCategory!['icon'],
                                    size: 50,
                                    color: Colors.green.shade600,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      // Responsive font sizing based on available width
                                      double fontSize =
                                          constraints.maxWidth < 300
                                              ? 20
                                              : constraints.maxWidth < 350
                                                  ? 22
                                                  : 24;

                                      return Text(
                                        selectedCategory!['name'],
                                        style: GoogleFonts.poppins(
                                          fontSize: fontSize,
                                          fontWeight: FontWeight.w700,
                                          height: 1.2,
                                          color: Colors.black,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            // Work Location Section
                            Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: ShaderMask(
                                    shaderCallback: (Rect bounds) {
                                      return LinearGradient(
                                        colors: [
                                          Colors.green.shade300,
                                          Colors.green.shade700
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ).createShader(bounds);
                                    },
                                    child: const Icon(
                                      Icons.location_on,
                                      size: 30,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Work Location',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        location ?? 'No location specified',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            // Scheduled Date & Time Section
                            Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: ShaderMask(
                                    shaderCallback: (Rect bounds) {
                                      return LinearGradient(
                                        colors: [
                                          Colors.green.shade300,
                                          Colors.green.shade700
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ).createShader(bounds);
                                    },
                                    child: const Icon(
                                      Icons.calendar_today,
                                      size: 30,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'SCHEDULED DATE & TIME',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatDateTime(
                                            selectedDate, selectedTime),
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            // Proposed Price Section
                            Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: ShaderMask(
                                    shaderCallback: (Rect bounds) {
                                      return LinearGradient(
                                        colors: [
                                          Colors.green.shade300,
                                          Colors.green.shade700
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ).createShader(bounds);
                                    },
                                    child: const Icon(
                                      Icons.attach_money,
                                      size: 30,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'PROPOSED PRICE',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        price != null
                                            ? 'Rs. $price'
                                            : 'Not specified',
                                        style: GoogleFonts.inter(
                                          fontSize:
                                              18, // Further increased from 16
                                          fontWeight: FontWeight
                                              .w700, // Made bold from w400
                                          color: Colors
                                              .green.shade600, // Diamond green
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : const Text(
                          'Category not selected or data not passed',
                          style: TextStyle(color: Colors.red, fontSize: 16),
                        ),
                ),
              ),
              // Confirm & Post Button
              Container(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Confirm Posting'),
                            content: const Text(
                                'Are you sure, You want to Post this Request'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('No'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Job posted successfully!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                                child: const Text('Yes'),
                              ),
                            ],
                          );
                        },
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
                    child: const Text(
                      'Confirm & Post',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
