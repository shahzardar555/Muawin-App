import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:muawin_app/widgets/bottom_navigation_bar.dart'; // adjust package name if needed

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key, required this.userName});

  final String userName;

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildHeader(primary),
              SliverToBoxAdapter(child: _buildBodyContent(primary)),
            ],
          ),
          // persistent bottom nav sits on top of content
          MuawinBottomNavigationBar(
            currentIndex: _currentNavIndex,
            onItemTapped: (i) {
              setState(() => _currentNavIndex = i);
              // handle navigation of main sections if needed
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color primary) {
    return SliverToBoxAdapter(
      child: Container(
        height: 320,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primary,
              primary,
              primary.withValues(alpha: 0.9),
            ],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(40),
            bottomRight: Radius.circular(40),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // decorative icon
            Positioned(
              top: -40,
              right: -40,
              child: Transform.rotate(
                angle: -0.20944, // -12 degrees
                child: Opacity(
                  opacity: 0.1,
                  child: Image.asset(
                    'assets/muawin_icon.png',
                    width: 256,
                    height: 256,
                    color: Colors.white,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _LocationSelector(),
                      _NotificationIcon(primary: primary),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome, ${widget.userName}!',
                    style: GoogleFonts.poppins(
                      fontSize: 30, // 1.875rem
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Aapki Muaawinat kesay karain?',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _PrimarySearchField(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyContent(Color primary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const _FeaturedPartnersCarousel(),
        const SizedBox(height: 24),
        const _ServiceCategoryGrid(),
        const SizedBox(height: 24),
        const _LocalVendorCarousel(),
        const SizedBox(height: 24),
        _MuawinProAd(primary: primary),
        const SizedBox(height: 24),
        const _DynamicSection(title: 'Top Rated', icon: Icons.emoji_events),
        const SizedBox(height: 16),
        const _DynamicSection(title: 'Nearby Vendors', icon: Icons.store),
        const SizedBox(
            height: 80), // bottom padding so content isn't hidden by nav
      ],
    );
  }
}

class _LocationSelector extends StatelessWidget {
  const _LocationSelector();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Location',
          style: GoogleFonts.poppins(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: Colors.white70,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(width: 4),
        Row(
          children: [
            const Icon(Icons.place, size: 16, color: Colors.yellow),
            const SizedBox(width: 2),
            Text(
              'Gulberg III, Lahore',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down,
                size: 20, color: Colors.white),
          ],
        ),
      ],
    );
  }
}

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon({required this.primary});

  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 48,
              height: 48,
              color: Colors.white.withValues(alpha: 0.1),
              alignment: Alignment.center,
              child: const Icon(Icons.notifications, color: Colors.white),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.yellow,
              border: Border.all(color: primary, width: 1.5),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimarySearchField extends StatelessWidget {
  const _PrimarySearchField();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Text(
        'Search services or vendors...',
        style: GoogleFonts.poppins(
          fontSize: 15,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}

class _FeaturedPartnersCarousel extends StatefulWidget {
  const _FeaturedPartnersCarousel();
  @override
  State<_FeaturedPartnersCarousel> createState() =>
      _FeaturedPartnersCarouselState();
}

class _FeaturedPartnersCarouselState extends State<_FeaturedPartnersCarousel> {
  final PageController _controller = PageController(viewportFraction: 0.9);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 192, // 12rem = 192px
      child: PageView.builder(
        controller: _controller,
        itemCount: 5,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _FeaturedCard(index: index),
          );
        },
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    // Use a placeholder shaded background instead of missing assets
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: Colors.grey.shade800,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.grey.shade700, Colors.grey.shade900],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.yellow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'FEATURED',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Partner ${index + 1}',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Category',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.star, size: 14, color: Colors.yellow.shade700),
                    const SizedBox(width: 4),
                    Text('4.5',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                        )),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('2 km',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.white,
                          )),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCategoryGrid extends StatelessWidget {
  const _ServiceCategoryGrid();
  static const List<Map<String, dynamic>> categories = [
    {'label': 'Maid', 'icon': Icons.person},
    {'label': 'Driver', 'icon': Icons.directions_car},
    {'label': 'Babysitter', 'icon': Icons.child_care},
    {'label': 'Security Guard', 'icon': Icons.security},
    {'label': 'Washerman', 'icon': Icons.local_laundry_service},
    {'label': 'Domestic Helper', 'icon': Icons.group},
    {'label': 'Cook', 'icon': Icons.restaurant},
    {'label': 'Gardener', 'icon': Icons.local_florist},
    {'label': 'Tutor', 'icon': Icons.book},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Service Providers',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary,
                const Color(0xFF064E3B), // emerald-900
              ],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 32,
            crossAxisSpacing: 16,
            childAspectRatio: 1.6,
            children: categories.map((cat) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(cat['icon'],
                        size: 32, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cat['label'].toString().toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _LocalVendorCarousel extends StatelessWidget {
  const _LocalVendorCarousel();
  @override
  Widget build(BuildContext context) {
    final vendors = [
      'Supermarket',
      'Butcher',
      'Bakery',
      'Pharmacy',
    ];
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: vendors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          return Container(
            width: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.grey.shade700,
            ),
            child: Stack(
              children: [
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Row(
                    children: [
                      const Icon(Icons.store, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        vendors[i],
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MuawinProAd extends StatelessWidget {
  const _MuawinProAd({required this.primary});
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E293B),
            Color(0xFF0F172A),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.yellow.shade700,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'PREMIUM UPGRADE',
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              children: [
                const TextSpan(text: 'Muawin '),
                TextSpan(
                  text: 'PRO',
                  style: TextStyle(color: Colors.yellow.shade400),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProItem(text: 'Priority Matching (~2 mins)'),
              _ProItem(text: 'Zero Platform Service Fees'),
              _ProItem(text: 'Premium Insurance Cover'),
              _ProItem(text: 'Exclusive Expert Access'),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow.shade700,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {},
              child: Text(
                'Upgrade Now',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProItem extends StatelessWidget {
  const _ProItem({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.yellow),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _DynamicSection extends StatelessWidget {
  const _DynamicSection({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Icon(icon,
                  size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              return const _SectionCard();
            },
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard();
  @override
  Widget build(BuildContext context) {
    // Constrain and compact the card so it fits tight layouts without overflow
    return Container(
      width: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Vendor',
            style:
                GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, size: 12, color: Colors.yellow[700]),
              const SizedBox(width: 4),
              Text('4.9', style: GoogleFonts.poppins(fontSize: 10)),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('Verified',
                style: GoogleFonts.poppins(fontSize: 8, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
