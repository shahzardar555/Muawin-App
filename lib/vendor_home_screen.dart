import 'dart:ui';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_screen.dart';
import 'widgets/get_featured_overlay.dart';
import 'services/service_locator.dart';
import 'services/vendor_data_service.dart';
import 'widgets/bottom_navigation_bar.dart';
import 'widgets/chat_voice_input.dart';
import 'widgets/vendor_notification_bell.dart';
import 'logout_splash_screen.dart';

/// Header bottom radius 2.5rem (40px).
const double _kHeaderBottomRadius = 40;

/// Header padding: pt-12 (3rem).
const double _kHeaderTopPadding = 48;

/// Profile squircle 2.5rem (w-10 h-10).
const double _kProfileSize = 40;

/// Card radius 1.5rem.
const double _kCardRadius = 24;

/// Max width for centered content (max-w-md).
const double _kMaxContentWidth = 448;

Color _statusColorFor(VendorStatus s) {
  switch (s) {
    case VendorStatus.open:
      return const Color(0xFF4ADE80); // green-400
    case VendorStatus.busy:
      return const Color(0xFFFBBF24); // amber-400
    case VendorStatus.break_:
      return const Color(0xFF60A5FA); // blue-400
    case VendorStatus.closed:
      return const Color(0xFF94A3B8); // slate-400
  }
}

/// Primary "command center" for shop owners.
class VendorHomeScreen extends StatefulWidget {
  const VendorHomeScreen({super.key});

  @override
  State<VendorHomeScreen> createState() => _VendorHomeScreenState();
}

class _VendorHomeScreenState extends State<VendorHomeScreen> {
  int _selectedNavIndex = 0;
  VendorStatus _status = VendorStatus.open;
  int? _replyingReviewIndex;
  final Map<int, String> _reviewReplies = {};

  // Chat state
  bool _showChatBot = false;
  final List<Map<String, dynamic>> _chatMessages = [];
  final List<Map<String, dynamic>> _conversationHistory = [];
  static const String _backendUrl = 'http://localhost:3001';
  final TextEditingController _chatController = TextEditingController();

  // Profile picture state for web/mobile compatibility
  File? _vendorProfileImageFile;

  String get _statusLabel {
    switch (_status) {
      case VendorStatus.open:
        return 'Open';
      case VendorStatus.busy:
        return 'Busy';
      case VendorStatus.break_:
        return 'Break';
      case VendorStatus.closed:
        return 'Closed';
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeVendor();
    _loadChats();
  }

  Future<void> _loadChats() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Get vendor's profile id
      final profileResp = await supabase
          .from('profiles')
          .select('id')
          .eq('user_id', user.id)
          .single();

      _currentProfileId = profileResp['id']?.toString() ?? '';
      if (_currentProfileId.isEmpty) return;

      debugPrint('Vendor chat profile ID: $_currentProfileId');

      // Get threads where vendor is participant_1
      final threads1 = await supabase
          .from('message_threads')
          .select(
              'id, participant_1_id, participant_2_id, last_message_at, is_active')
          .eq('participant_1_id', _currentProfileId)
          .order('last_message_at', ascending: false);

      // Get threads where vendor is participant_2
      final threads2 = await supabase
          .from('message_threads')
          .select(
              'id, participant_1_id, participant_2_id, last_message_at, is_active')
          .eq('participant_2_id', _currentProfileId)
          .order('last_message_at', ascending: false);

      // Combine and deduplicate
      final Map<String, dynamic> threadMap = {};
      for (final t in [...threads1, ...threads2]) {
        threadMap[t['id'].toString()] = t;
      }
      final threads = threadMap.values.toList();

      debugPrint('Vendor threads found: ${threads.length}');

      final List<Map<String, dynamic>> chats = [];

      for (final thread in threads) {
        final threadId = thread['id']?.toString() ?? '';

        // Get the other participant (customer)
        final otherParticipantId =
            thread['participant_1_id']?.toString() == _currentProfileId
                ? thread['participant_2_id']?.toString() ?? ''
                : thread['participant_1_id']?.toString() ?? '';

        if (otherParticipantId.isEmpty) continue;

        // Get other participant's profile
        final otherProfile = await supabase
            .from('profiles')
            .select('id, full_name, profile_image_url, phone_number, email')
            .eq('id', otherParticipantId)
            .maybeSingle();

        if (otherProfile == null) continue;

        // Get last message
        final lastMessages = await supabase
            .from('messages')
            .select('content, created_at, is_read, sender_id')
            .eq('thread_id', threadId)
            .order('created_at', ascending: false)
            .limit(1);

        String snippet = 'No messages yet';
        String time = '';
        bool unread = false;

        if (lastMessages.isNotEmpty) {
          final last = lastMessages.first;
          snippet = last['content']?.toString() ?? 'Message';
          unread = last['is_read'] == false &&
              last['sender_id']?.toString() != _currentProfileId;

          final createdAt =
              DateTime.tryParse(last['created_at']?.toString() ?? '');
          if (createdAt != null) {
            final now = DateTime.now();
            final diff = now.difference(createdAt);
            if (diff.inMinutes < 60) {
              time = '${diff.inMinutes} min ago';
            } else if (diff.inHours < 24) {
              time = '${diff.inHours}h ago';
            } else {
              time = '${diff.inDays}d ago';
            }
          }
        }

        chats.add({
          'id': threadId,
          'name': otherProfile['full_name']?.toString() ?? 'Customer',
          'avatar': otherProfile['profile_image_url']?.toString() ?? '',
          'phone': otherProfile['phone_number']?.toString() ?? '',
          'email': otherProfile['email']?.toString() ?? '',
          'snippet': snippet,
          'time': time,
          'unread': unread,
          'isOnline': false,
          'isNewCustomer': false,
          'otherParticipantId': otherParticipantId,
        });
      }

      debugPrint('Vendor chats built: ${chats.length}');

      // chats list is ready but not yet wired to a UI widget
    } catch (e) {
      debugPrint('Error loading vendor chats: $e');
    }
  }

  // Service-based state management
  String _currentProfileId = '';
  String _currentVendorId = '';
  bool _isLoadingVendorData = true;
  Map<String, dynamic>? _vendorData;

  // Featured ad state
  bool _hasActiveFeaturedAd = false;
  String _activeFeaturedEndDate = '';

  Future<void> _initializeVendor() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoadingVendorData = false);
        return;
      }
      debugPrint('Vendor init — user: ${user.id}');

      // Get profile
      final profile = await supabase
          .from('profiles')
          .select('id, full_name, email, phone_number, profile_image_url')
          .eq('user_id', user.id)
          .single();

      _currentProfileId = profile['id'].toString();
      debugPrint('Vendor init — profile id: $_currentProfileId');
      debugPrint('Profile image from DB: ${profile['profile_image_url']}');

      // Get vendor record
      final vendor = await supabase.from('vendors').select('''
            id,
            business_name,
            business_type,
            city,
            area,
            location,
            address,
            rating,
            review_count,
            is_pro,
            years_in_business,
            cover_photo_url,
            status
          ''').eq('profile_id', _currentProfileId).maybeSingle();
      debugPrint('Vendor init — vendor: $vendor');

      if (vendor == null) {
        debugPrint('No vendor record found for profile: $_currentProfileId');
        if (mounted) setState(() => _isLoadingVendorData = false);
        return;
      }

      _currentVendorId = vendor['id'].toString();
      debugPrint('Vendor init — setting state');

      // Load status from Supabase
      final dbStatus = vendor['status']?.toString() ?? 'open';
      VendorStatus loadedStatus;
      if (dbStatus == 'busy') {
        loadedStatus = VendorStatus.busy;
      } else if (dbStatus == 'break') {
        loadedStatus = VendorStatus.break_;
      } else if (dbStatus == 'closed') {
        loadedStatus = VendorStatus.closed;
      } else {
        loadedStatus = VendorStatus.open;
      }

      setState(() {
        _status = loadedStatus;
        _vendorData = {
          'name': vendor['business_name']?.toString() ??
              profile['full_name']?.toString() ??
              '',
          'category': vendor['business_type']?.toString() ?? '',
          'phone': profile['phone_number']?.toString() ?? '',
          'address':
              vendor['address']?.toString() ?? vendor['area']?.toString() ?? '',
          'city': vendor['city']?.toString() ?? '',
          'about': '',
          'rating': vendor['rating']?.toString() ?? '0.0',
          'reviewCount': vendor['review_count']?.toString() ?? '0',
          'profileImageUrl': profile['profile_image_url']?.toString(),
          'mapsLink': vendor['location']?.toString() ?? '',
          'is_pro': vendor['is_pro'] == true,
          'coverPhotoUrl': vendor['cover_photo_url']?.toString(),
          'status': dbStatus,
        };
        _isLoadingVendorData = false;
      });
      _checkActiveFeaturedAd();
      debugPrint('Vendor profileImageUrl: ${_vendorData?['profileImageUrl']}');
    } catch (e) {
      debugPrint('Error initializing vendor: $e');
      debugPrint('Vendor init — caught error: $e');
      setState(() => _isLoadingVendorData = false);
    }
  }

  Future<void> _loadVendorData() async {
    await _initializeVendor();
  }

  Future<void> _refreshVendorData() async {
    await _loadVendorData();
  }

  // Getters for UI
  String get _vendorName => _vendorData?['name'] ?? '';
  String get _vendorCategory => _vendorData?['category'] ?? '';
  String get _vendorPhone => _vendorData?['phone'] ?? '';
  String get _vendorAddress => _vendorData?['address'] ?? '';
  String get _vendorMapsLink => _vendorData?['mapsLink'] ?? '';
  String get _vendorAbout => _vendorData?['about'] ?? '';
  String get _vendorRating => _vendorData?['rating'] ?? '0.0';
  int get _vendorReviewCount =>
      int.tryParse(_vendorData?['reviewCount']?.toString() ?? '') ?? 0;
  String? get _vendorProfileImageUrl => _vendorData?['profileImageUrl'];
  String? get _vendorCoverPhotoUrl => _vendorData?['coverPhotoUrl'];

  void _sendMessage({bool isVoiceMessage = false}) async {
    final userMessage = _chatController.text.trim();
    if (userMessage.isEmpty) return;

    setState(() {
      _chatMessages.add({
        'text': userMessage,
        'isUser': true,
        'isVoiceMessage': isVoiceMessage,
      });
      _chatController.clear();
    });

    _conversationHistory.add({
      'role': 'user',
      'content': userMessage,
    });

    try {
      final response = await http
          .post(
            Uri.parse('$_backendUrl/api/ai/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'message': userMessage,
              'conversationHistory': _conversationHistory,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final botReply = data['response']?.toString() ??
            'Sorry, I could not understand that.';

        _conversationHistory.add({
          'role': 'assistant',
          'content': botReply,
        });

        if (mounted) {
          setState(() {
            _chatMessages.add({
              'text': botReply,
              'isUser': false,
            });
          });
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('AI chat error: $e');
      if (mounted) {
        setState(() {
          _chatMessages.add({
            'text': 'Sorry, I am having trouble connecting. Please try again.',
            'isUser': false,
          });
        });
      }
    }
  }

  Future<void> _checkActiveFeaturedAd() async {
    if (_currentVendorId.isEmpty) {
      setState(() {
        _hasActiveFeaturedAd = false;
        _activeFeaturedEndDate = '';
      });
      return;
    }
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('featured_ads')
          .select('id, end_date')
          .eq('vendor_id', _currentVendorId)
          .eq('is_active', true)
          .gt('end_date', DateTime.now().toIso8601String())
          .limit(1)
          .maybeSingle();

      if (response != null) {
        final endDate =
            DateTime.tryParse(response['end_date']?.toString() ?? '');
        final months = [
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
        if (endDate != null) {
          setState(() {
            _hasActiveFeaturedAd = true;
            _activeFeaturedEndDate =
                '${endDate.day} ${months[endDate.month - 1]} ${endDate.year}';
          });
        } else {
          setState(() {
            _hasActiveFeaturedAd = true;
            _activeFeaturedEndDate = '';
          });
        }
      } else {
        setState(() {
          _hasActiveFeaturedAd = false;
          _activeFeaturedEndDate = '';
        });
      }
    } catch (e) {
      debugPrint('Error checking active featured ad: $e');
      setState(() {
        _hasActiveFeaturedAd = false;
        _activeFeaturedEndDate = '';
      });
    }
  }

  void _navigateBackFromChats() {
    setState(() {
      _selectedNavIndex = 0; // Navigate back to dashboard tab
    });
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;

    // Show loading indicator while vendor data is loading
    if (_isLoadingVendorData) {
      return Scaffold(
        backgroundColor: surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(0xFF047A62),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading vendor data...',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: surface,
      body: Stack(
        children: [
          SafeArea(
            top: false,
            bottom: false,
            child: IndexedStack(
              index: _selectedNavIndex,
              sizing: StackFit.expand,
              children: [
                _DashboardTab(
                  vendorId: _currentVendorId,
                  hasActiveFeaturedAd: _hasActiveFeaturedAd,
                  activeFeaturedEndDate: _activeFeaturedEndDate,
                  vendorName: _vendorName,
                  vendorRating: _vendorRating,
                  vendorReviewCount: _vendorReviewCount,
                  status: _status,
                  statusLabel: _statusLabel,
                  onStatusChanged: (status) async {
                    VendorDataService.updateVendorStatus(status);
                    setState(() {
                      _status = status;
                    });
                    if (_currentVendorId.isNotEmpty) {
                      try {
                        String statusStr = 'open';
                        if (status == VendorStatus.busy) {
                          statusStr = 'busy';
                        } else if (status == VendorStatus.break_) {
                          statusStr = 'break';
                        } else if (status == VendorStatus.closed) {
                          statusStr = 'closed';
                        }

                        await Supabase.instance.client.from('vendors').update(
                            {'status': statusStr}).eq('id', _currentVendorId);
                      } catch (e) {
                        debugPrint('Error updating vendor status: $e');
                      }
                    }
                    await _refreshVendorData();
                  },
                  replyingReviewIndex: _replyingReviewIndex,
                  vendorReplies: _reviewReplies,
                  onReplyTap: (i) => setState(() => _replyingReviewIndex = i),
                  onReplyCancel: () =>
                      setState(() => _replyingReviewIndex = null),
                  onReplySubmit: (i, text) {
                    setState(() {
                      _reviewReplies[i] = text;
                      _replyingReviewIndex = null;
                    });
                  },
                  onReviewCountChanged: (count) async {
                    await vendorService.updateReviewCount(count);
                    await _refreshVendorData();
                  }, // Added callback
                  onRatingChanged: (rating) async {
                    await vendorService.updateRating(rating);
                    await _refreshVendorData();
                  }, // Added rating callback
                  vendorProfileImageFile:
                      _vendorProfileImageFile, // Added profile picture
                  vendorProfileImageUrl:
                      _vendorProfileImageUrl, // Added profile picture URL
                ),
                _VendorChatsTab(onBack: _navigateBackFromChats),
                _VendorProfileTab(
                  currentVendorName: _vendorName,
                  currentVendorCategory: _vendorCategory,
                  currentVendorPhone: _vendorPhone,
                  currentVendorAddress: _vendorAddress,
                  currentVendorMapsLink: _vendorMapsLink,
                  currentVendorAbout: _vendorAbout,
                  currentVendorProfileImageUrl: _vendorProfileImageUrl,
                  currentVendorCoverPhotoUrl: _vendorCoverPhotoUrl,
                  onStoreNameUpdated: (newName) async {
                    await vendorService.updateVendorField('name', newName);
                    await _refreshVendorData();
                  },
                  onCategoryUpdated: (newCategory) async {
                    await vendorService.updateVendorField(
                        'category', newCategory);
                    await _refreshVendorData();
                  },
                  onPhoneUpdated: (newPhone) async {
                    await vendorService.updateVendorField('phone', newPhone);
                    await _refreshVendorData();
                  },
                  onAddressUpdated: (newAddress) async {
                    await vendorService.updateVendorField(
                        'address', newAddress);
                    await _refreshVendorData();
                  },
                  onMapsLinkUpdated: (newMapsLink) async {
                    await vendorService.updateVendorField(
                        'mapsLink', newMapsLink);
                    await _refreshVendorData();
                  },
                  onAboutUpdated: (newAbout) async {
                    await vendorService.updateVendorField('about', newAbout);
                    await _refreshVendorData();
                  },
                  onRatingUpdated: (newRating) async {
                    await vendorService.updateRating(newRating);
                    await _refreshVendorData();
                  },
                  onReviewCountUpdated: (newReviewCount) async {
                    await vendorService.updateReviewCount(newReviewCount);
                    await _refreshVendorData();
                  },
                  onProfilePictureUpdated:
                      (File? imageFile, String? imageUrl) async {
                    setState(() {
                      _vendorProfileImageFile = imageFile;
                    });
                    await vendorService.updateProfilePicture(imageUrl);
                    await _refreshVendorData();
                  },
                ),
              ],
            ),
          ),
          // Chat overlay
          if (_showChatBot)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _showChatBot = false),
                child: Container(color: Colors.black.withValues(alpha: 0.5)),
              ),
            ),
          if (_showChatBot)
            Positioned(
              bottom:
                  120, // Increased from 100 to 120 to avoid navigation bar overlap
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height * 0.7,
              child: _AIChatBottomSheet(
                messages: _chatMessages,
                controller: _chatController,
                onSendMessage: _sendMessage,
                onClose: () => setState(() => _showChatBot = false),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Chat bubble/dialog - hide when chatbot is open
          if (!_showChatBot)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                'Muawin Rehnuma',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF047A62),
                ),
              ),
            ),
          // FAB button
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GestureDetector(
                onTap: () => setState(() => _showChatBot = true),
                child: Image.asset(
                  'imagess/bot.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                ), // AI/Chatbot icon
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: MuawinBottomNavigationBar(
        currentIndex: _selectedNavIndex,
        isVendor: true, // This will use vendor navigation items
        onItemTapped: (index) {
          if (index == 0) {
            setState(() => _selectedNavIndex = 0);
          } else if (index == 1) {
            setState(() => _selectedNavIndex = 1);
          } else if (index == 2) {
            setState(() => _selectedNavIndex = 2);
          }
          // Vendor has 3 items: Home(0), Chats(1), Profile(2)
        },
      ),
    );
  }
}

/// Dashboard tab content (Vendor Hub).
class _DashboardTab extends StatelessWidget {
  const _DashboardTab({
    required this.vendorId,
    required this.hasActiveFeaturedAd,
    required this.activeFeaturedEndDate,
    required this.vendorName,
    required this.vendorRating,
    required this.vendorReviewCount,
    required this.status,
    required this.statusLabel,
    required this.onStatusChanged,
    required this.replyingReviewIndex,
    required this.vendorReplies,
    required this.onReplyTap,
    required this.onReplyCancel,
    required this.onReplySubmit,
    required this.onReviewCountChanged, // Added parameter
    required this.onRatingChanged, // Added rating parameter
    this.vendorProfileImageFile, // Added profile picture parameter
    this.vendorProfileImageUrl, // Added profile picture URL parameter
  });

  final String vendorId;
  final bool hasActiveFeaturedAd;
  final String activeFeaturedEndDate;
  final String vendorName;
  final String vendorRating;
  final int vendorReviewCount;
  final VendorStatus status;
  final String statusLabel;
  final ValueChanged<VendorStatus> onStatusChanged;
  final int? replyingReviewIndex;
  final Map<int, String> vendorReplies;
  final ValueChanged<int> onReplyTap;
  final VoidCallback onReplyCancel;
  final void Function(int index, String text) onReplySubmit;
  final ValueChanged<int> onReviewCountChanged; // Added field
  final ValueChanged<String> onRatingChanged; // Added rating field
  final File? vendorProfileImageFile; // Added profile picture field
  final String? vendorProfileImageUrl; // Added profile picture URL field

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final surface = theme.colorScheme.surface;
    final onPrimary = theme.colorScheme.onPrimary;

    return Container(
      color: surface,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          top: MediaQuery.paddingOf(context).top,
          left: 24,
          right: 24,
          bottom: 100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sleek header (scrolls with content)
            _DashboardHeader(
              vendorName: vendorName,
              vendorRating: vendorRating,
              vendorReviewCount: vendorReviewCount,
              status: status,
              onStatusChanged: onStatusChanged,
              primary: primary,
              onPrimary: onPrimary,
              vendorProfileImageFile:
                  vendorProfileImageFile, // Added profile picture
              vendorProfileImageUrl:
                  vendorProfileImageUrl, // Added profile picture URL
            ),
            const SizedBox(height: 20),
            _ManagementCard(status: statusLabel),
            const SizedBox(height: 20),
            _PremiumBanner(
              hasActive: hasActiveFeaturedAd,
              endDate: activeFeaturedEndDate,
            ),
            const SizedBox(height: 24),
            _ReviewsSection(
              vendorId: vendorId,
              replyingIndex: replyingReviewIndex,
              vendorReplies: vendorReplies,
              onReplyTap: onReplyTap,
              onReplyCancel: onReplyCancel,
              onReplySubmit: onReplySubmit,
              onReviewCountChanged: onReviewCountChanged, // Added callback
              onRatingChanged: onRatingChanged, // Added rating callback
            ),
          ],
        ),
      ),
    );
  }
}

/// Sleek, non-sticky dashboard header.
class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.vendorName,
    required this.vendorRating,
    required this.vendorReviewCount,
    required this.status,
    required this.onStatusChanged,
    required this.primary,
    required this.onPrimary,
    this.vendorProfileImageFile, // Added profile picture parameter
    this.vendorProfileImageUrl, // Added profile picture URL parameter
  });

  final String vendorName;
  final String vendorRating;
  final int vendorReviewCount;
  final VendorStatus status;
  final ValueChanged<VendorStatus> onStatusChanged;
  final Color primary;
  final Color onPrimary;
  final File? vendorProfileImageFile; // Added profile picture field
  final String? vendorProfileImageUrl; // Added profile picture URL field

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary,
            primary.withValues(alpha: 0.92),
          ],
        ),
        borderRadius: BorderRadius.circular(_kHeaderBottomRadius),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    Container(
                      width: _kProfileSize,
                      height: _kProfileSize,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Show profile picture if available, otherwise show default icon
                          vendorProfileImageFile != null ||
                                  vendorProfileImageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: kIsWeb && vendorProfileImageUrl != null
                                      ? Image.network(
                                          vendorProfileImageUrl!,
                                          width: _kProfileSize,
                                          height: _kProfileSize,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return const Icon(
                                              Icons.store_rounded,
                                              size: 26,
                                              color: Colors.black87,
                                            );
                                          },
                                        )
                                      : Image.file(
                                          vendorProfileImageFile!,
                                          width: _kProfileSize,
                                          height: _kProfileSize,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return const Icon(
                                              Icons.store_rounded,
                                              size: 26,
                                              color: Colors.black87,
                                            );
                                          },
                                        ),
                                )
                              : const Icon(
                                  Icons.store_rounded,
                                  size: 26,
                                  color: Colors.black87,
                                ),
                          Positioned(
                            right: 5,
                            bottom: 5,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _statusColorFor(status),
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 1.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Vendor name and ratings/reviews beside avatar
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Vendor name (back to original position)
                          Text(
                            vendorName,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: onPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 4),
                          // Ratings and reviews below name
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  size: 16, color: Color(0xFFEAB308)),
                              const SizedBox(width: 4),
                              Text(
                                vendorRating,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: onPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '($vendorReviewCount reviews)',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: onPrimary.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Notification Bell
              VendorNotificationBell(
                receiverType: 'vendor',
                onPrimary: onPrimary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Status Button moved here
          _StatusDropdownButton(
            value: status,
            onChanged: onStatusChanged,
          ),
        ],
      ),
    );
  }
}

/// Chats tab (Messages) — Customer Chats screen.
class _VendorChatsTab extends StatefulWidget {
  const _VendorChatsTab({required this.onBack});

  final VoidCallback onBack;

  @override
  State<_VendorChatsTab> createState() => _VendorChatsTabState();
}

class _VendorChatsTabState extends State<_VendorChatsTab> {
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? _selectedThread;

  bool _isLoadingChats = false;

  List<Map<String, dynamic>> _threads = [];

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    if (!mounted) return;
    setState(() => _isLoadingChats = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Get vendor's profile_id
      final profileResp = await supabase
          .from('profiles')
          .select('id')
          .eq('user_id', user.id)
          .single();
      final myProfileId = profileResp['id'].toString();

      // Get threads where vendor is participant_1
      final threads1 = await supabase
          .from('message_threads')
          .select(
              'id, participant_1_id, participant_2_id, last_message_at, is_active')
          .eq('participant_1_id', myProfileId)
          .eq('is_active', true)
          .order('last_message_at', ascending: false);

      // Get threads where vendor is participant_2
      final threads2 = await supabase
          .from('message_threads')
          .select(
              'id, participant_1_id, participant_2_id, last_message_at, is_active')
          .eq('participant_2_id', myProfileId)
          .eq('is_active', true)
          .order('last_message_at', ascending: false);

      // Combine and deduplicate
      final allThreads = [...threads1, ...threads2];
      final seen = <String>{};
      final uniqueThreads = allThreads.where((t) {
        final id = t['id'].toString();
        return seen.add(id);
      }).toList();

      // Sort by last_message_at descending
      uniqueThreads.sort((a, b) {
        final aTime =
            DateTime.tryParse(a['last_message_at']?.toString() ?? '') ??
                DateTime(2000);
        final bTime =
            DateTime.tryParse(b['last_message_at']?.toString() ?? '') ??
                DateTime(2000);
        return bTime.compareTo(aTime);
      });

      // For each thread, get other participant info and last message
      final List<Map<String, dynamic>> result = [];

      for (final thread in uniqueThreads) {
        final threadId = thread['id'].toString();
        final otherParticipantId =
            thread['participant_1_id'].toString() == myProfileId
                ? thread['participant_2_id'].toString()
                : thread['participant_1_id'].toString();

        // Get other participant's profile
        final otherProfile = await supabase
            .from('profiles')
            .select('id, full_name, profile_image_url')
            .eq('id', otherParticipantId)
            .maybeSingle();

        // Get last message
        final lastMessages = await supabase
            .from('messages')
            .select('content, created_at, is_read, sender_id')
            .eq('thread_id', threadId)
            .order('created_at', ascending: false)
            .limit(1);

        String snippet = 'Tap to open conversation';
        String time = '';
        bool unread = false;

        if (lastMessages.isNotEmpty) {
          final last = lastMessages[0];
          snippet = last['content']?.toString() ?? '';
          unread = last['is_read'] == false &&
              last['sender_id']?.toString() != myProfileId;

          final msgTime =
              DateTime.tryParse(last['created_at']?.toString() ?? '');
          if (msgTime != null) {
            final now = DateTime.now();
            final diff = now.difference(msgTime);
            if (diff.inMinutes < 60) {
              time = '${diff.inMinutes}m ago';
            } else if (diff.inHours < 24) {
              time = '${diff.inHours}h ago';
            } else {
              time = '${diff.inDays}d ago';
            }
          }
        }

        result.add({
          'id': threadId,
          'name': otherProfile?['full_name']?.toString() ?? 'Customer',
          'avatar': otherProfile?['profile_image_url']?.toString() ?? '',
          'snippet': snippet,
          'time': time,
          'unread': unread,
          'isNewCustomer': false,
          'otherProfileId': otherParticipantId,
        });
      }

      if (mounted) {
        setState(() => _threads = result);
      }
    } catch (e) {
      debugPrint('Error loading vendor chats: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingChats = false);
      }
    }
  }

  void _openConversation(Map<String, dynamic> thread) {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatData: {
            'id': thread['id'],
            'name': thread['name'],
            'avatar': thread['avatar'],
            'isOnline': false,
            'type': 'customer',
          },
        ),
      ),
    )
        .then((_) {
      _loadChats();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Show sort options modal
  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            _buildSortOption('Recent First', Icons.access_time, () {
              Navigator.pop(context);
              _sortChats('recent');
            }),
            _buildSortOption('Oldest First', Icons.history, () {
              Navigator.pop(context);
              _sortChats('oldest');
            }),
            _buildSortOption('Unread First', Icons.mark_email_unread, () {
              Navigator.pop(context);
              _sortChats('unread');
            }),
            _buildSortOption('A to Z', Icons.sort_by_alpha, () {
              Navigator.pop(context);
              _sortChats('alphabetical');
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title,
          style:
              GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }

  void _sortChats(String sortType) {
    setState(() {
      switch (sortType) {
        case 'recent':
          _threads.sort((a, b) {
            try {
              final aTime = DateTime.parse('${a['time']}:00');
              final bTime = DateTime.parse('${b['time']}:00');
              return bTime.compareTo(aTime);
            } catch (e) {
              return b['time'].toString().compareTo(a['time'].toString());
            }
          });
          break;
        case 'oldest':
          _threads.sort((a, b) {
            try {
              final aTime = DateTime.parse('${a['time']}:00');
              final bTime = DateTime.parse('${b['time']}:00');
              return aTime.compareTo(bTime);
            } catch (e) {
              return a['time'].toString().compareTo(b['time'].toString());
            }
          });
          break;
        case 'unread':
          _threads.sort((a, b) {
            final aUnread = a['unread'] as bool;
            final bUnread = b['unread'] as bool;
            if (aUnread && !bUnread) return -1;
            if (!aUnread && bUnread) return 1;
            // For same unread status, sort by time
            try {
              final aTime = DateTime.parse('${a['time']}:00');
              final bTime = DateTime.parse('${b['time']}:00');
              return bTime.compareTo(aTime);
            } catch (e) {
              return b['time'].toString().compareTo(a['time'].toString());
            }
          });
          break;
        case 'alphabetical':
          _threads.sort((a, b) =>
              a['name'].toLowerCase().compareTo(b['name'].toLowerCase()));
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final surface = theme.colorScheme.surface;
    final onPrimary = theme.colorScheme.onPrimary;

    final query = _searchController.text.trim().toLowerCase();
    final filtered = _threads.where((t) {
      final name = (t['name'] as String).toLowerCase();
      final snippet = (t['snippet'] as String).toLowerCase();
      return name.contains(query) || snippet.contains(query) || query.isEmpty;
    }).toList();

    final bool isSearching = query.isNotEmpty;
    final bool hasResults = filtered.isNotEmpty;

    final bool showingConversation = _selectedThread != null;
    final selectedThread = _selectedThread;

    return Container(
      color: surface,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: _kHeaderTopPadding + MediaQuery.paddingOf(context).top,
                  bottom: 24,
                ),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(_kHeaderBottomRadius),
                    bottomRight: Radius.circular(_kHeaderBottomRadius),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (showingConversation) {
                              setState(() => _selectedThread = null);
                            } else {
                              widget.onBack(); // Navigate back to previous tab
                            }
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                showingConversation
                                    ? (selectedThread!['name'] as String)
                                    : 'Customer Chats',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: onPrimary,
                                ),
                              ),
                              if (showingConversation &&
                                  selectedThread != null) ...[
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    if (selectedThread['isOnline'] as bool)
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    const SizedBox(width: 4),
                                    Text(
                                      (selectedThread['isOnline'] as bool)
                                          ? 'Online'
                                          : 'Offline',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color:
                                            Colors.white.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (showingConversation)
                          GestureDetector(
                            onTap: () async {
                              // Call customer functionality
                              final selectedThread = _selectedThread;
                              if (selectedThread != null &&
                                  selectedThread['phone'] != null) {
                                String phoneNumber =
                                    selectedThread['phone'] as String;
                                // Clean phone number - remove spaces and special characters
                                phoneNumber = phoneNumber.replaceAll(
                                    RegExp(r'[^0-9+]'), '');

                                // Request phone call permission
                                final PermissionStatus phonePermission =
                                    await Permission.phone.request();

                                if (phonePermission.isGranted) {
                                  final Uri phoneUri =
                                      Uri(scheme: 'tel', path: phoneNumber);

                                  // Store context before async operations
                                  final context = this.context;

                                  try {
                                    if (await canLaunchUrl(phoneUri)) {
                                      await launchUrl(phoneUri);
                                    } else {
                                      if (mounted && context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Could not launch phone dialer'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    if (mounted && context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content:
                                              Text('Error: ${e.toString()}'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                } else {
                                  if (mounted && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Phone call permission denied'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  }
                                }
                              } else {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('No phone number available'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                              }
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.call_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.group_rounded,
                              color: onPrimary,
                              size: 24,
                            ),
                          ),
                      ],
                    ),
                    if (!showingConversation) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          // Search bar (reduced width)
                          Expanded(
                            flex: 3,
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 16),
                                  Icon(Icons.search_rounded,
                                      size: 20, color: Colors.grey[600]),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      onChanged: (_) => setState(() {}),
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Search customers...',
                                        hintStyle: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.grey[500],
                                        ),
                                        border: InputBorder.none,
                                        isCollapsed: false,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Sort button
                          GestureDetector(
                            onTap: _showSortOptions,
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.sort_rounded,
                                size: 24,
                                color: primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: _isLoadingChats
                    ? const Center(child: CircularProgressIndicator())
                    : hasResults
                        ? RefreshIndicator(
                            onRefresh: _loadChats,
                            child: ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(24, 16, 24, 96),
                              itemBuilder: (context, index) {
                                final t = filtered[index];
                                final bool unread = t['unread'] as bool;
                                final bool isNew = t['isNewCustomer'] as bool;
                                final String name = t['name'] as String;
                                final String? avatar = t['avatar'] as String?;
                                final String snippet = t['snippet'] as String;
                                final String time = t['time'] as String;

                                return GestureDetector(
                                  onTap: () => _openConversation(t),
                                  child: _ChatThreadCard(
                                    name: name,
                                    avatar: avatar,
                                    snippet: snippet,
                                    time: time,
                                    unread: unread,
                                    isNewCustomer: isNew,
                                  ),
                                );
                              },
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemCount: filtered.length,
                            ),
                          )
                        : _ChatsEmptyState(
                            isSearch: isSearching,
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Vendor Profile tab — primary configuration suite.
class _VendorProfileTab extends StatefulWidget {
  const _VendorProfileTab({
    required this.currentVendorName,
    required this.currentVendorCategory,
    required this.currentVendorPhone,
    required this.currentVendorAddress,
    required this.currentVendorMapsLink,
    required this.currentVendorAbout,
    required this.onStoreNameUpdated,
    required this.onCategoryUpdated,
    required this.onPhoneUpdated,
    required this.onAddressUpdated,
    required this.onMapsLinkUpdated,
    required this.onAboutUpdated,
    required this.onRatingUpdated,
    required this.onReviewCountUpdated,
    required this.onProfilePictureUpdated,
    this.currentVendorProfileImageUrl,
    this.currentVendorCoverPhotoUrl,
  });

  final String currentVendorName;
  final String currentVendorCategory;
  final String currentVendorPhone;
  final String currentVendorAddress;
  final String currentVendorMapsLink;
  final String currentVendorAbout;
  final String? currentVendorProfileImageUrl;
  final String? currentVendorCoverPhotoUrl;
  final Function(String) onStoreNameUpdated;
  final Function(String) onCategoryUpdated;
  final Function(String) onPhoneUpdated;
  final Function(String) onAddressUpdated;
  final Function(String) onMapsLinkUpdated;
  final Function(String) onAboutUpdated;
  final Function(String) onRatingUpdated;
  final Function(int) onReviewCountUpdated;
  final Function(File?, String?) onProfilePictureUpdated;

  @override
  State<_VendorProfileTab> createState() => _VendorProfileTabState();
}

class _VendorProfileTabState extends State<_VendorProfileTab> {
  File? _imageFile;
  String? _imageUrl; // For web compatibility
  File? _coverPhotoFile;
  String? _coverPhotoUrl; // For web compatibility

  Future<void> _pickCoverPhoto() async {
    debugPrint('Muawin Debug: _pickCoverPhoto called');
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 400,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        debugPrint('Muawin Debug: Cover photo picked: ${pickedFile.path}');
        setState(() {
          if (kIsWeb) {
            // For web, use the path as URL (blob URL)
            _coverPhotoUrl = pickedFile.path;
            _coverPhotoFile = null;
          } else {
            // For mobile/desktop, use File
            _coverPhotoFile = File(pickedFile.path);
            _coverPhotoUrl = null;
          }
        });

        // Save cover photo to vendor data service
        await _saveCoverPhoto();
        debugPrint('Muawin Debug: Cover photo state updated');
      } else {
        debugPrint('Muawin Debug: No cover photo selected');
      }
    } catch (e) {
      debugPrint('Muawin Debug: Error picking cover photo: $e');
    }
  }

  Future<void> _saveCoverPhoto() async {
    try {
      final vendorService = serviceLocator.vendorService;
      final success =
          await (vendorService as MockVendorService).updateCoverPhoto(
        _coverPhotoUrl,
        _coverPhotoFile?.path,
      );

      if (success) {
        debugPrint('Muawin Debug: Cover photo saved successfully');
      } else {
        debugPrint('Muawin Debug: Failed to save cover photo');
      }
    } catch (e) {
      debugPrint('Muawin Debug: Error saving cover photo: $e');
    }
  }

  Future<void> _pickImage() async {
    debugPrint('Muawin Debug: _pickImage called');
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        debugPrint('Muawin Debug: Image picked: ${pickedFile.path}');
        setState(() {
          if (kIsWeb) {
            // For web, use the path as URL (blob URL)
            _imageUrl = pickedFile.path;
            _imageFile = null;
          } else {
            // For mobile/desktop, use File
            _imageFile = File(pickedFile.path);
            _imageUrl = null;
          }
        });
        // Notify parent of profile picture update
        widget.onProfilePictureUpdated(_imageFile, _imageUrl);
      } else {
        debugPrint('Muawin Debug: No image selected');
      }
    } catch (e) {
      debugPrint('Muawin Debug: Error picking image: $e');
    }
  }

  bool _hasCoverPhotoSource() {
    return _coverPhotoFile != null ||
        _coverPhotoUrl != null ||
        (widget.currentVendorCoverPhotoUrl != null &&
            widget.currentVendorCoverPhotoUrl!.isNotEmpty &&
            widget.currentVendorCoverPhotoUrl!.startsWith('http'));
  }

  ImageProvider _getCoverImageProvider() {
    if (_coverPhotoFile != null) {
      return FileImage(_coverPhotoFile!);
    } else if (_coverPhotoUrl != null) {
      return NetworkImage(_coverPhotoUrl!);
    }

    // Fallback to Supabase-stored cover photo URL from vendor data
    if (widget.currentVendorCoverPhotoUrl != null &&
        widget.currentVendorCoverPhotoUrl!.isNotEmpty &&
        widget.currentVendorCoverPhotoUrl!.startsWith('http')) {
      return NetworkImage(widget.currentVendorCoverPhotoUrl!);
    }

    // Fallback to a solid color background (will be handled by gradient)
    return const AssetImage(''); // Empty asset, will trigger gradient fallback
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final surface = theme.colorScheme.surface;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Container(
      color: surface,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: MediaQuery.paddingOf(context).top + 8,
              bottom: 96,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Branding & Hero Header: primary/20, rounded-b-40
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
                  decoration: BoxDecoration(
                    // Use cover photo as background if available, otherwise use gradient
                    image: _hasCoverPhotoSource()
                        ? DecorationImage(
                            image: _getCoverImageProvider(),
                            fit: BoxFit.cover,
                            onError: (error, stackTrace) {
                              debugPrint('Error loading cover image: $error');
                            },
                          )
                        : null,
                    gradient: !_hasCoverPhotoSource()
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              primary.withValues(alpha: 0.2),
                              primary.withValues(alpha: 0.1),
                            ],
                          )
                        : null,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(_kHeaderBottomRadius),
                      bottomRight: Radius.circular(_kHeaderBottomRadius),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Avatar 6rem, squircle, 4px white border, edit at bottom-right
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: _imageFile != null
                                  ? Image.file(
                                      _imageFile!,
                                      width: 96,
                                      height: 96,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          width: 96,
                                          height: 96,
                                          decoration: BoxDecoration(
                                            color:
                                                primary.withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(24),
                                          ),
                                          child: Icon(
                                            Icons.store_rounded,
                                            size: 44,
                                            color: primary,
                                          ),
                                        );
                                      },
                                    )
                                  : _imageUrl != null && _imageUrl!.isNotEmpty
                                      ? Image.network(
                                          _imageUrl!,
                                          width: 96,
                                          height: 96,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Container(
                                              width: 96,
                                              height: 96,
                                              decoration: BoxDecoration(
                                                color: primary.withValues(
                                                    alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(24),
                                              ),
                                              child: Icon(
                                                Icons.store_rounded,
                                                size: 44,
                                                color: primary,
                                              ),
                                            );
                                          },
                                        )
                                      : widget.currentVendorProfileImageUrl !=
                                                  null &&
                                              widget
                                                  .currentVendorProfileImageUrl!
                                                  .isNotEmpty &&
                                              widget
                                                  .currentVendorProfileImageUrl!
                                                  .startsWith('http')
                                          ? Image.network(
                                              widget
                                                  .currentVendorProfileImageUrl!,
                                              width: 96,
                                              height: 96,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Container(
                                                  width: 96,
                                                  height: 96,
                                                  decoration: BoxDecoration(
                                                    color: primary.withValues(
                                                        alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            24),
                                                  ),
                                                  child: Icon(
                                                    Icons.store_rounded,
                                                    size: 44,
                                                    color: primary,
                                                  ),
                                                );
                                              },
                                            )
                                          : Container(
                                              width: 96,
                                              height: 96,
                                              decoration: BoxDecoration(
                                                color: primary.withValues(
                                                    alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(24),
                                              ),
                                              child: Icon(
                                                Icons.store_rounded,
                                                size: 44,
                                                color: primary,
                                              ),
                                            ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: primary.withValues(alpha: 0.4),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.currentVendorName,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          widget.currentVendorCategory.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.15 * 10,
                            color: primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_on_rounded,
                              size: 14, color: muted),
                          const SizedBox(width: 4),
                          Text(
                            widget.currentVendorAddress,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: muted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const SizedBox(height: 4),
                      Text(
                        widget.currentVendorPhone,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Store Management section
                Text(
                  'Store Management',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.12 * 14,
                    color: muted,
                  ),
                ),
                const SizedBox(height: 12),
                _ProfileMenuItem(
                  icon: Icons.store_rounded,
                  label: 'Store Information',
                  onTap: () => _showStoreInformationSheet(context,
                      onStoreNameUpdated: widget.onStoreNameUpdated,
                      onCategoryUpdated: widget.onCategoryUpdated,
                      onPhoneUpdated: widget.onPhoneUpdated,
                      onAddressUpdated: widget.onAddressUpdated,
                      onMapsLinkUpdated: widget.onMapsLinkUpdated,
                      onAboutUpdated: widget.onAboutUpdated,
                      onRatingUpdated: widget.onRatingUpdated,
                      onReviewCountUpdated: widget.onReviewCountUpdated,
                      initialName: widget.currentVendorName,
                      initialPhone: widget.currentVendorPhone,
                      initialAddress: widget.currentVendorAddress,
                      initialMapsLink: widget.currentVendorMapsLink,
                      initialAbout: widget.currentVendorAbout),
                ),
                const SizedBox(height: 8),
                _ProfileMenuItem(
                  icon: Icons.image_outlined,
                  label: 'Cover Photo',
                  onTap: _pickCoverPhoto,
                ),
                const SizedBox(height: 8),
                _ProfileMenuItem(
                  icon: Icons.security_rounded,
                  label: 'Change Password',
                  onTap: () => _showAccountSecuritySheet(context),
                ),
                const SizedBox(height: 8),
                _ProfileMenuItem(
                  icon: Icons.privacy_tip_rounded,
                  label: 'Privacy Policy',
                  onTap: () => _showPrivacyPolicySheet(context),
                ),
                const SizedBox(height: 8),
                _ProfileMenuItem(
                  icon: Icons.help_outline_rounded,
                  label: 'Help & Support',
                  onTap: () => _showHelpSupportSheet(context),
                ),
                const SizedBox(height: 8),
                _ProfileMenuItem(
                  icon: Icons.settings_rounded,
                  label: 'General Settings',
                  onTap: () => _showGeneralSettingsSheet(context),
                ),
                const SizedBox(height: 32),
                // Logout button
                OutlinedButton(
                  onPressed: () async {
                    try {
                      await Supabase.instance.client.auth.signOut();
                    } catch (e) {
                      debugPrint('Logout error: $e');
                    }
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute<void>(
                          builder: (_) => const LogoutSplashScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFDC2626)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Logout',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Muawin Vendor Hub v1.0.4',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1 * 10,
                    color: muted,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showGeneralSettingsSheet(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    bool isDarkMode = prefs.getBool('dark_mode') ?? false;
    String selectedLanguage = prefs.getString('app_language') ?? 'English';

    // Guard both State.context and BuildContext parameter
    if (!mounted) return;
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (innerContext, setState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(innerContext).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'General Settings',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(innerContext).textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 20),
              _ToggleRow(
                label: 'Dark Mode',
                value: isDarkMode,
                onChanged: (val) async {
                  await prefs.setBool('dark_mode', val);
                  if (innerContext.mounted) {
                    setState(() {}); // Update local state for UI
                  }
                  // Note: In a real app, you'd also update the app theme here
                },
              ),
              const SizedBox(height: 16),
              Text(
                'App Language',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(innerContext).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedLanguage,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'English', child: Text('English')),
                  DropdownMenuItem(value: 'Urdu', child: Text('Urdu')),
                ],
                onChanged: (String? value) async {
                  if (value != null) {
                    // Update local state
                    setState(() {
                      selectedLanguage = value;
                    });

                    // Save preference
                    await prefs.setString('app_language', value);

                    // Show feedback
                    if (innerContext.mounted) {
                      ScaffoldMessenger.of(innerContext).showSnackBar(
                        SnackBar(
                          content: Text('Language changed to $value'),
                          duration: const Duration(seconds: 2),
                          backgroundColor: const Color(0xFF047A62),
                        ),
                      );
                    }
                  }
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

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      shadowColor: Colors.black,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 22, color: primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 24, color: primary.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}

void _showStoreInformationSheet(BuildContext context,
    {Function(String)? onStoreNameUpdated,
    Function(String)? onCategoryUpdated,
    Function(String)? onPhoneUpdated,
    Function(String)? onAddressUpdated,
    Function(String)? onMapsLinkUpdated,
    Function(String)? onAboutUpdated,
    Function(String)? onRatingUpdated,
    Function(int)? onReviewCountUpdated,
    String? initialName,
    String? initialPhone,
    String? initialAddress,
    String? initialMapsLink,
    String? initialAbout}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _StoreInformationSheet(
      onStoreNameUpdated: onStoreNameUpdated,
      onCategoryUpdated: onCategoryUpdated,
      onPhoneUpdated: onPhoneUpdated,
      onAddressUpdated: onAddressUpdated,
      onMapsLinkUpdated: onMapsLinkUpdated,
      onAboutUpdated: onAboutUpdated,
      onRatingUpdated: onRatingUpdated,
      onReviewCountUpdated: onReviewCountUpdated,
      initialName: initialName,
      initialPhone: initialPhone,
      initialAddress: initialAddress,
      initialMapsLink: initialMapsLink,
      initialAbout: initialAbout,
    ),
  );
}

class _StoreInformationSheet extends StatefulWidget {
  const _StoreInformationSheet(
      {this.onStoreNameUpdated,
      this.onCategoryUpdated,
      this.onPhoneUpdated,
      this.onAddressUpdated,
      this.onMapsLinkUpdated,
      this.onAboutUpdated,
      this.onRatingUpdated,
      this.onReviewCountUpdated,
      this.initialName,
      this.initialPhone,
      this.initialAddress,
      this.initialMapsLink,
      this.initialAbout});

  final Function(String)? onStoreNameUpdated;
  final Function(String)? onCategoryUpdated;
  final Function(String)? onPhoneUpdated;
  final Function(String)? onAddressUpdated;
  final Function(String)? onMapsLinkUpdated;
  final Function(String)? onAboutUpdated;
  final Function(String)? onRatingUpdated;
  final Function(int)? onReviewCountUpdated;
  final String? initialName;
  final String? initialPhone;
  final String? initialAddress;
  final String? initialMapsLink;
  final String? initialAbout;

  @override
  State<_StoreInformationSheet> createState() => _StoreInformationSheetState();
}

class _StoreInformationSheetState extends State<_StoreInformationSheet> {
  late final TextEditingController _businessNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _mapsController;
  late final TextEditingController _aboutController;

  @override
  void initState() {
    super.initState();
    _businessNameController =
        TextEditingController(text: widget.initialName ?? '');
    _phoneController = TextEditingController(text: widget.initialPhone ?? '');
    _addressController =
        TextEditingController(text: widget.initialAddress ?? '');
    _mapsController = TextEditingController(text: widget.initialMapsLink ?? '');
    _aboutController = TextEditingController(text: widget.initialAbout ?? '');
  }

  bool _isLoading = false;

  @override
  void dispose() {
    _businessNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _mapsController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  void _saveStoreInformation() async {
    setState(() => _isLoading = true);

    try {
      if (mounted) {
        _showSuccess('Store information updated successfully!');

        // Call the callbacks to update the vendor information in the parent
        if (widget.onStoreNameUpdated != null) {
          widget.onStoreNameUpdated!(_businessNameController.text);
        }
        if (widget.onPhoneUpdated != null) {
          widget.onPhoneUpdated!(_phoneController.text);
        }
        if (widget.onAddressUpdated != null) {
          widget.onAddressUpdated!(_addressController.text);
        }
        if (widget.onMapsLinkUpdated != null) {
          widget.onMapsLinkUpdated!(_mapsController.text);
        }
        if (widget.onAboutUpdated != null) {
          widget.onAboutUpdated!(_aboutController.text);
        }

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to update store information. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Store Information',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Update your business details that will be visible to customers',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _businessNameController,
                decoration: InputDecoration(
                  labelText: 'Business Name',
                  hintText: 'Enter your business name',
                  hintStyle: GoogleFonts.poppins(color: Colors.black45),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                style: GoogleFonts.poppins(fontSize: 15),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Contact Phone',
                  hintText: 'Enter customer contact number',
                  hintStyle: GoogleFonts.poppins(color: Colors.black45),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                style: GoogleFonts.poppins(fontSize: 15),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Location Address',
                  hintText: 'Enter your business address',
                  hintStyle: GoogleFonts.poppins(color: Colors.black45),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                style: GoogleFonts.poppins(fontSize: 15),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _mapsController,
                decoration: InputDecoration(
                  labelText: 'Google Maps Link',
                  hintText: 'Enter or paste Google Maps URL',
                  hintStyle: GoogleFonts.poppins(color: Colors.black45),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                style: GoogleFonts.poppins(fontSize: 15),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _aboutController,
                decoration: InputDecoration(
                  labelText: 'Business Description',
                  hintText: 'Describe your products and services',
                  hintStyle: GoogleFonts.poppins(color: Colors.black45),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                style: GoogleFonts.poppins(fontSize: 15),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isLoading ? null : _saveStoreInformation,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text('Save Information',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showAccountSecuritySheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _AccountSecuritySheet(),
  );
}

void _showPrivacyPolicySheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Privacy Policy',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Muawin values your privacy. We only collect information needed to provide and improve our services, such as account details, profile data, and usage activity. We do not sell your personal information to third parties.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.5,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your data may be used for account security, support, analytics, and feature enhancements. By continuing to use Muawin, you agree to our privacy practices. For questions, contact support@muawin.com.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.5,
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
  );
}

class _AccountSecuritySheet extends StatefulWidget {
  @override
  State<_AccountSecuritySheet> createState() => _AccountSecuritySheetState();
}

class _AccountSecuritySheetState extends State<_AccountSecuritySheet> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isFormValid() {
    return _currentPasswordController.text.isNotEmpty &&
        _newPasswordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _newPasswordController.text == _confirmPasswordController.text &&
        _newPasswordController.text.length >= 6;
  }

  void _updatePassword() async {
    if (!_isFormValid()) {
      _showError(
          'Please fill all fields correctly and ensure passwords match.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      // Step 1: Re-authenticate by signing in with current password
      final user = supabase.auth.currentUser;
      if (user == null || user.email == null) {
        _showError('Session expired. Please log in again.');
        return;
      }

      // Step 2: Verify current password is correct by attempting sign in
      final authResponse = await supabase.auth.signInWithPassword(
        email: user.email!,
        password: _currentPasswordController.text.trim(),
      );

      if (authResponse.user == null) {
        _showError('Current password is incorrect.');
        return;
      }

      // Step 3: Update to new password
      await supabase.auth.updateUser(
        UserAttributes(password: _newPasswordController.text.trim()),
      );

      if (mounted) {
        _showSuccess('Password updated successfully!');
        Navigator.pop(context);
      }
    } on AuthException catch (e) {
      if (mounted) {
        if (e.message.toLowerCase().contains('invalid') ||
            e.message.toLowerCase().contains('wrong') ||
            e.message.toLowerCase().contains('incorrect')) {
          _showError('Current password is incorrect.');
        } else {
          _showError('Failed to update password: ${e.message}');
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to update password. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Change Password',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrent,
                decoration: InputDecoration(
                  hintText: 'Current Password',
                  hintStyle: GoogleFonts.poppins(color: Colors.black45),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureCurrent
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () =>
                        setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                style: GoogleFonts.poppins(fontSize: 15),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                decoration: InputDecoration(
                  hintText: 'New Password',
                  hintStyle: GoogleFonts.poppins(color: Colors.black45),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscureNew ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                style: GoogleFonts.poppins(fontSize: 15),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  hintText: 'Confirm New Password',
                  hintStyle: GoogleFonts.poppins(color: Colors.black45),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                style: GoogleFonts.poppins(fontSize: 15),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isLoading ? null : _updatePassword,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text('Update Password',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _launchWhatsAppSupport() async {
  final whatsappUrl = Uri.parse(
      'https://wa.me/923001234567?text=Hello%2C%20I%20need%20help%20with%20my%20vendor%20account');
  try {
    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl);
    }
  } catch (e) {
    debugPrint('Could not launch WhatsApp: $e');
  }
}

void _launchEmailSupport() async {
  final emailUrl = Uri.parse(
      'mailto:support@muawin.com?subject=Vendor%20Support&body=Hello%2C%20I%20need%20help%20with%20my%20vendor%20account');
  try {
    if (await canLaunchUrl(emailUrl)) {
      await launchUrl(emailUrl);
    }
  } catch (e) {
    debugPrint('Could not launch email: $e');
  }
}

class _FAQItem extends StatelessWidget {
  const _FAQItem({
    required this.question,
    required this.answer,
  });

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          answer,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.color
                ?.withValues(alpha: 0.8),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

void _showHelpSupportSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Help & Support',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _SupportIcon(
                icon: Icons.chat_rounded,
                label: 'WhatsApp Support',
                onTap: () => _launchWhatsAppSupport(),
              ),
              _SupportIcon(
                icon: Icons.email_rounded,
                label: 'Email Support',
                onTap: () => _launchEmailSupport(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ExpansionTile(
            title: Text(
              'Common Questions',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            children: const [
              SizedBox(
                height: 180,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FAQItem(
                        question: 'How do I update my store information?',
                        answer:
                            'Go to Profile → Store Information and update your details. All changes are saved automatically.',
                      ),
                      SizedBox(height: 12),
                      _FAQItem(
                        question: 'How do I contact support?',
                        answer:
                            'Use WhatsApp Support or Email Support in the Help & Support section. We\'re available 24/7.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}

class _SupportIcon extends StatelessWidget {
  const _SupportIcon({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 28, color: primary),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }
}

/// Expanded conversation view with message bubbles.
class _ConversationView extends StatefulWidget {
  const _ConversationView({
    required this.thread,
    required this.primary,
    required this.muted,
  });

  final Map<String, dynamic> thread;
  final Color primary;
  final Color muted;

  @override
  State<_ConversationView> createState() => _ConversationViewState();
}

class _ConversationViewState extends State<_ConversationView> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _messages = List.from(_sampleMessages);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'text': text,
        'isCustomer': false,
        'time': _getCurrentTime(),
      });
    });

    _messageController.clear();
    _focusNode.unfocus();

    // Simulate customer reply after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _messages.add({
            'text': _getCustomerReply(text),
            'isCustomer': true,
            'time': _getCurrentTime(),
          });
        });
      }
    });
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  String _getCustomerReply(String vendorMessage) {
    final lowerMessage = vendorMessage.toLowerCase();
    if (lowerMessage.contains('delivery')) {
      return 'Thank you for the information!';
    } else if (lowerMessage.contains('available')) {
      return 'Great! I\'ll order right away.';
    } else if (lowerMessage.contains('order')) {
      return 'Perfect! Looking forward to it.';
    } else {
      return 'Thanks for your response!';
    }
  }

  static final List<Map<String, dynamic>> _sampleMessages = [
    {
      'text': 'Hi, is same day delivery available?',
      'isCustomer': true,
      'time': '2:15 PM'
    },
    {
      'text': 'Yes! We offer same-day delivery for orders placed before 2 PM.',
      'isCustomer': false,
      'time': '2:18 PM'
    },
    {
      'text': 'Great, thanks! I\'ll place my order now.',
      'isCustomer': true,
      'time': '2:20 PM'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            reverse: true,
            itemCount: _messages.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final i = _messages.length - 1 - index;
              final m = _messages[i];
              final isCustomer = m['isCustomer'] as bool;
              return Align(
                alignment:
                    isCustomer ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isCustomer
                        ? Colors.grey.shade100
                        : widget.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isCustomer ? 4 : 16),
                      bottomRight: Radius.circular(isCustomer ? 16 : 4),
                    ),
                    border: isCustomer
                        ? null
                        : Border.all(
                            color: widget.primary.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        m['text'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        m['time'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: widget.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              12 +
                  MediaQuery.paddingOf(context).bottom +
                  80), // Added 80px for navigation bar
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: _messageController,
                    focusNode: _focusNode,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        color: widget.muted,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 0,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: widget.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Single chat thread card.
class _ChatThreadCard extends StatelessWidget {
  const _ChatThreadCard({
    required this.name,
    this.avatar,
    required this.snippet,
    required this.time,
    required this.unread,
    required this.isNewCustomer,
  });

  final String name;
  final String? avatar;
  final String snippet;
  final String time;
  final bool unread;
  final bool isNewCustomer;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final muted =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    final Color bgColor =
        unread ? Colors.white : Colors.white.withValues(alpha: 0.9);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(_kCardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: unread ? 0.12 : 0.04),
            blurRadius: unread ? 14 : 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: unread
            ? Border.all(color: primary.withValues(alpha: 0.1), width: 1)
            : null,
      ),
      child: Row(
        children: [
          // Avatar with profile picture or fallback to initials
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: _kProfileSize,
              height: _kProfileSize,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.05),
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  // Profile picture or fallback
                  Container(
                    width: _kProfileSize,
                    height: _kProfileSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.05),
                        width: 1,
                      ),
                      image: (avatar != null &&
                              avatar.toString().isNotEmpty &&
                              avatar.toString().startsWith('http'))
                          ? DecorationImage(
                              image: NetworkImage(avatar.toString()),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                  ),
                  (avatar == null ||
                          avatar.toString().isEmpty ||
                          !avatar.toString().startsWith('http'))
                      ? Center(
                          child: Icon(
                            Icons.person_rounded,
                            size: _kProfileSize * 0.5,
                            color: primary,
                          ),
                        )
                      : const SizedBox
                          .shrink(), // Empty box when avatar is valid
                  // Unread indicator
                  if (unread)
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.access_time_rounded,
                        size: 11, color: muted.withValues(alpha: 0.9)),
                    const SizedBox(width: 2),
                    Text(
                      time,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: muted.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (isNewCustomer)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'NEW',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1D4ED8),
                      ),
                    ),
                  ),
                if (isNewCustomer) const SizedBox(height: 4),
                Text(
                  snippet,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: unread ? FontWeight.w700 : FontWeight.w400,
                    color: muted,
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

/// Empty state widget for chats.
class _ChatsEmptyState extends StatelessWidget {
  const _ChatsEmptyState({required this.isSearch});

  final bool isSearch;

  @override
  Widget build(BuildContext context) {
    final muted =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    final icon =
        isSearch ? Icons.search_off_rounded : Icons.chat_bubble_outline_rounded;
    final title = isSearch ? 'No results found' : 'No customer inquiries yet';
    final body = isSearch
        ? 'Try changing your search or filters.'
        : 'When customers message your shop about services or products, they will appear here.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 72,
              color: muted.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: muted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Glass-morphism status dropdown button (shown in header): compact vertical layout.
class _StatusDropdownButton extends StatelessWidget {
  const _StatusDropdownButton({
    required this.value,
    required this.onChanged,
  });

  final VendorStatus value;
  final ValueChanged<VendorStatus> onChanged;

  String get _label {
    switch (value) {
      case VendorStatus.open:
        return 'Open';
      case VendorStatus.busy:
        return 'Busy';
      case VendorStatus.break_:
        return 'Break';
      case VendorStatus.closed:
        return 'Closed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: PopupMenuButton<VendorStatus>(
            offset: const Offset(0, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.white,
            onSelected: onChanged,
            itemBuilder: (context) => [
              _buildMenuItem(VendorStatus.open),
              _buildMenuItem(VendorStatus.busy),
              _buildMenuItem(VendorStatus.break_),
              _buildMenuItem(VendorStatus.closed),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STATUS',
                        style: GoogleFonts.poppins(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1 * 8,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _statusColorFor(value),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _label,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<VendorStatus> _buildMenuItem(VendorStatus s) {
    String label;
    switch (s) {
      case VendorStatus.open:
        label = 'Open';
        break;
      case VendorStatus.busy:
        label = 'Busy';
        break;
      case VendorStatus.break_:
        label = 'Break';
        break;
      case VendorStatus.closed:
        label = 'Closed';
        break;
    }
    return PopupMenuItem<VendorStatus>(
      value: s,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _statusColorFor(s),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(label, style: GoogleFonts.poppins(fontSize: 14)),
        ],
      ),
    );
  }
}

/// Core Management Card: status icon, "Store is [Status]", copy.
class _ManagementCard extends StatelessWidget {
  const _ManagementCard({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final muted =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    IconData icon = Icons.check_circle_rounded;
    Color iconBg = const Color(0xFF22C55E).withValues(alpha: 0.15);
    if (status == 'Busy') {
      icon = Icons.schedule_rounded;
      iconBg = const Color(0xFFEAB308).withValues(alpha: 0.15);
    } else if (status == 'Break') {
      icon = Icons.free_breakfast_rounded;
      iconBg = const Color(0xFFF97316).withValues(alpha: 0.15);
    } else if (status == 'Closed') {
      icon = Icons.cancel_rounded;
      iconBg = const Color(0xFFEF4444).withValues(alpha: 0.15);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kCardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 24, color: primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status == 'Break'
                          ? 'Store is currently on a Break'
                          : 'Store is $status',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Update your status to manage visibility',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Manage your store availability and profile from this central hub. Use navigation bar below to access chats and settings.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: muted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Premium Promotion Banner: gradient, "Boost Your Sales", Rs. 99 / per day.
class _PremiumBanner extends StatefulWidget {
  final bool hasActive;
  final String endDate;

  const _PremiumBanner({
    this.hasActive = false,
    this.endDate = '',
  });

  @override
  State<_PremiumBanner> createState() => _PremiumBannerState();
}

class _PremiumBannerState extends State<_PremiumBanner> {
  // Get current user profile data
  Future<Map<String, dynamic>> _getCurrentUserProfile() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        return {
          'userType': 'vendor',
          'userId': '',
          'userName': '',
          'userCategory': '',
          'userRating': 0.0,
        };
      }

      // Get profile
      final profile = await supabase
          .from('profiles')
          .select('id, full_name, profile_image_url')
          .eq('user_id', user.id)
          .maybeSingle();

      if (profile == null) {
        return {
          'userType': 'vendor',
          'userId': '',
          'userName': '',
          'userCategory': '',
          'userRating': 0.0,
        };
      }

      // Get vendor record
      final vendor = await supabase
          .from('vendors')
          .select('id, business_type, rating')
          .eq('profile_id', profile['id'])
          .maybeSingle();

      if (vendor == null) {
        return {
          'userType': 'vendor',
          'userId': '',
          'userName': profile['full_name']?.toString() ?? '',
          'userCategory': '',
          'userRating': 0.0,
        };
      }

      return {
        'userType': 'vendor',
        'userId': vendor['id'].toString(),
        'userName': profile['full_name']?.toString() ?? '',
        'userCategory': vendor['business_type']?.toString() ?? '',
        'userRating': (vendor['rating'] as num?)?.toDouble() ?? 0.0,
      };
    } catch (e) {
      debugPrint('Error getting current user profile: $e');
      return {
        'userType': 'vendor',
        'userId': '',
        'userName': '',
        'userCategory': '',
        'userRating': 0.0,
      };
    }
  }

  // Show GetFeaturedOverlay with real user data
  void _showGetFeaturedOverlay() async {
    if (!mounted) return;

    final userProfile = await _getCurrentUserProfile();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GetFeaturedOverlay(
        userType: userProfile['userType'] ?? 'vendor',
        userName: userProfile['userName'] ?? 'Vendor Name Here',
        userCategory: userProfile['userCategory'] ?? 'Vendor Category Here',
        userRating: (userProfile['userRating'] as num?)?.toDouble() ?? 4.5,
        userId: userProfile['userId'] ?? 'vendor_id_here',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.hasActive) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF22C55E), // green-500
              Color(0xFF16A34A), // green-600
            ],
          ),
          borderRadius: BorderRadius.circular(_kCardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Featured Ad Active',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.endDate.isNotEmpty
                            ? 'Active until: ${widget.endDate}'
                            : 'Your ad is running',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Your profile is being shown to customers as a featured ad. Customers can see your business at the top of their feed.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.8),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: null,
              icon: const Icon(Icons.check_rounded, size: 16),
              label: Text(
                'Running',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 32,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6366F1), // indigo-500
            Color(0xFF8B5CF6), // indigo-400
          ],
        ),
        borderRadius: BorderRadius.circular(_kCardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Featured Ads',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Boost Your Profile',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: const Icon(
                  Icons.rocket_launch_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Get advanced features, priority support, and increased visibility for just Rs. 99 per day.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _showGetFeaturedOverlay,
            icon: const Icon(Icons.workspace_premium_rounded, size: 16),
            label: Text(
              'Get Featured',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF6366F1),
              padding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reviews Section: list of reviews with reply functionality.
class _ReviewsSection extends StatefulWidget {
  const _ReviewsSection({
    required this.vendorId,
    required this.replyingIndex,
    required this.vendorReplies,
    required this.onReplyTap,
    required this.onReplyCancel,
    required this.onReplySubmit,
    required this.onReviewCountChanged, // Added callback
    required this.onRatingChanged, // Added rating callback
  });

  final String vendorId;
  final int? replyingIndex;
  final Map<int, String> vendorReplies;
  final ValueChanged<int> onReplyTap;
  final VoidCallback onReplyCancel;
  final void Function(int index, String text) onReplySubmit;
  final ValueChanged<int> onReviewCountChanged; // Added field
  final ValueChanged<String> onRatingChanged; // Added rating field

  @override
  State<_ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<_ReviewsSection> {
  // Hardcoded fallback reviews
  final List<Map<String, dynamic>> _fallbackReviews = [
    {
      'customerName': 'Sarah Johnson',
      'avatar': 'https://i.pravatar.cc/150?img=47',
      'rating': 5.0,
      'date': '2 days ago',
      'comment': 'Excellent service! Very professional and quick response.',
      'reply': null,
    },
    {
      'customerName': 'Ahmed Hassan',
      'avatar': 'https://i.pravatar.cc/150?img=11',
      'rating': 4.5,
      'date': '1 week ago',
      'comment': 'Good quality work, but could improve communication.',
      'reply':
          'Thank you for your feedback! We\'ll work on better communication.',
    },
    {
      'customerName': 'Fatima Sheikh',
      'avatar': 'https://i.pravatar.cc/150?img=23',
      'rating': 4.0,
      'date': '2 weeks ago',
      'comment': 'Decent prices, but delivery was slightly delayed.',
      'reply': null,
    },
  ];
  late List<Map<String, dynamic>> _displayedReviews;
  bool _isLoadingReviews = false;

  @override
  void initState() {
    super.initState();
    _displayedReviews = [];
    _fetchVendorReviews();
  }

  Future<void> _fetchVendorReviews() async {
    if (widget.vendorId.isEmpty) {
      setState(() => _displayedReviews = List.from(_fallbackReviews));
      _notifyParent();
      return;
    }

    setState(() => _isLoadingReviews = true);

    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('reviews')
          .select('''
            id,
            rating,
            review,
            created_at,
            customers!inner (
              profile_id,
              profiles!inner (
                full_name,
                profile_image_url
              )
            )
          ''')
          .eq('vendor_id', widget.vendorId)
          .order('created_at', ascending: false)
          .limit(10);

      if (response.isNotEmpty) {
        final reviews = response.map<Map<String, dynamic>>((r) {
          final customer = r['customers'] as Map<String, dynamic>?;
          final profile = customer?['profiles'] as Map<String, dynamic>?;
          final createdAt =
              DateTime.tryParse(r['created_at']?.toString() ?? '');
          final now = DateTime.now();

          String relativeDate = '';
          if (createdAt != null) {
            final diff = now.difference(createdAt);
            if (diff.inMinutes < 60) {
              relativeDate = '${diff.inMinutes} min ago';
            } else if (diff.inHours < 24) {
              relativeDate = '${diff.inHours}h ago';
            } else if (diff.inDays < 7) {
              relativeDate = '${diff.inDays} days ago';
            } else {
              relativeDate = '${(diff.inDays / 7).floor()} weeks ago';
            }
          }

          return {
            'customerName': profile?['full_name']?.toString() ?? 'Customer',
            'avatar': profile?['profile_image_url']?.toString() ??
                'https://i.pravatar.cc/150?img=${r['id']?.toString() ?? '0'}',
            'rating': (r['rating'] as num?)?.toDouble() ?? 0.0,
            'date': relativeDate,
            'comment': r['review']?.toString() ?? '',
            'reply': null,
          };
        }).toList();

        setState(() {
          _displayedReviews = reviews;
          _isLoadingReviews = false;
        });
      } else {
        setState(() {
          _displayedReviews = [];
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching vendor reviews: $e');
      // Fallback to hardcoded reviews on error
      setState(() {
        _displayedReviews = List.from(_fallbackReviews);
        _isLoadingReviews = false;
      });
    }

    _notifyParent();
  }

  void _notifyParent() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onReviewCountChanged(_displayedReviews.length);
      final averageRating = _calculateAverageRating(_displayedReviews);
      widget.onRatingChanged(averageRating);
    });
  }

  // Calculate average rating from reviews
  String _calculateAverageRating(List<Map<String, dynamic>> reviews) {
    if (reviews.isEmpty) return '0.0';

    final totalRating = reviews.fold<double>(
        0.0, (sum, review) => sum + (review['rating'] as double));

    final average = totalRating / reviews.length;
    return average.toStringAsFixed(1);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final muted =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kCardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer Reviews',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoadingReviews)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color(0xFF047A62),
                  ),
                ),
              ),
            )
          else if (_displayedReviews.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.reviews_rounded,
                      size: 64,
                      color: muted,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No reviews yet',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Be the first to receive customer reviews!\nShare excellent service to build your reputation.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: muted,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: primary.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.tips_and_updates_rounded,
                            size: 20,
                            color: primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Provide excellent service\nto earn 5-star reviews',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: primary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: _displayedReviews.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final review = _displayedReviews[index];
                final isReplying = widget.replyingIndex == index;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              review['avatar'] as String,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(
                                    Icons.person_rounded,
                                    size: 20,
                                    color: primary,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        review['customerName'] as String,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFDBE2E)
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.star_rounded,
                                            size: 14,
                                            color: Color(0xFFF59E0B),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            (review['rating'] as double)
                                                .toStringAsFixed(1),
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFFF59E0B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  review['date'] as String,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        review['comment'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                      if (review['reply'] != null)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF0891B2).withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.reply_rounded,
                                size: 16,
                                color: Color(0xFF0891B2),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  review['reply'] as String,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: const Color(0xFF0891B2),
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (!isReplying) const SizedBox(height: 12),
                      if (!isReplying)
                        TextButton.icon(
                          onPressed: () => widget.onReplyTap(index),
                          icon: const Icon(Icons.reply_rounded, size: 16),
                          label: Text(
                            'Reply',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      if (isReplying)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF0891B2).withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF0891B2)
                                  .withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Reply',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0891B2),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                style: GoogleFonts.poppins(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'Type your reply...',
                                  hintStyle: GoogleFonts.poppins(color: muted),
                                  border: InputBorder.none,
                                ),
                                maxLines: 3,
                                onChanged: (text) {
                                  final updatedReviews =
                                      List<Map<String, dynamic>>.from(
                                          _displayedReviews);
                                  updatedReviews[index]['reply'] = text;
                                  setState(() {
                                    _displayedReviews = updatedReviews;
                                  });
                                },
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: widget.onReplyCancel,
                                    child: Text(
                                      'Cancel',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: muted,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton(
                                    onPressed: () {
                                      final reply = _displayedReviews[index]
                                          ['reply'] as String?;
                                      if (reply != null &&
                                          reply.trim().isNotEmpty) {
                                        widget.onReplySubmit(index, reply);
                                      }
                                    },
                                    child: Text(
                                      'Submit',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// AI Chat Bottom Sheet Widget
class _AIChatBottomSheet extends StatefulWidget {
  final List<Map<String, dynamic>> messages;
  final TextEditingController controller;
  final VoidCallback onSendMessage;
  final VoidCallback onClose;

  const _AIChatBottomSheet({
    required this.messages,
    required this.controller,
    required this.onSendMessage,
    required this.onClose,
  });

  @override
  State<_AIChatBottomSheet> createState() => _AIChatBottomSheetState();
}

class _AIChatBottomSheetState extends State<_AIChatBottomSheet> {
  // Chat voice state variables
  bool _isChatListening = false;
  String _chatLocale = 'en_US';
  double _chatSoundLevel = 0.0;

  // Phase 2: Smart language detection
  final String _detectedLanguage = 'unknown';
  final double _languageConfidence = 0.0;

  // Speech recognition instance
  final SpeechToText _speechToText = SpeechToText();

  // Vendor-specific Urdu phrases
  final Map<String, String> _urduChatPhrases = {
    'نئے آرڈر': 'New orders',
    'کتنے آرڈر ہیں': 'How many orders',
    'آج کی سیل': 'Today sales',
    'پیسے کب ملیں گے': 'When will I get paid',
    'پروڈکٹ اپڈیٹ': 'Update product',
    'اشتہار دیکھو': 'Show my ads',
    'گاہک کی شکایت': 'Customer complaint',
    'ڈیلیوری اپڈیٹ': 'Delivery update',
    'مدد چاہیے': 'I need help',
    'انوائس بناؤ': 'Create invoice',
    'فیچرڈ اشتہار': 'Featured ad',
    'نئے گاہک': 'New customers',
    'اسٹاک کم ہے': 'Stock is low',
    'قیمت تبدیل کرو': 'Change price',
  };

  @override
  void initState() {
    super.initState();
    _speechToText.initialize().then((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _speechToText.stop();
    super.dispose();
  }

  // Show full-screen voice overlay
  void _showFullScreenVoiceOverlay() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF047A62).withValues(alpha: 0.9),
                  const Color(0xFF047A62).withValues(alpha: 0.7),
                ],
              ),
            ),
            child: Column(
              children: [
                // Header with close button
                Padding(
                  padding: const EdgeInsets.only(top: 50, left: 20, right: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Voice Input Mode',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                // Voice visualization
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Large mic icon with animation
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5),
                              width: 3,
                            ),
                          ),
                          child: const Icon(
                            Icons.mic_rounded,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Sound waves visualization
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(7, (index) {
                            return AnimatedContainer(
                              duration:
                                  Duration(milliseconds: 300 + (index * 50)),
                              width: 4,
                              height: 20 + (_chatSoundLevel * 40),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 30),

                        // Status text
                        Text(
                          'Listening...',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Language indicator
                        Text(
                          _chatLocale == 'en_US' ? 'English' : 'اردو',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom controls
                Padding(
                  padding: const EdgeInsets.only(bottom: 50),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Language toggle
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _chatLocale =
                                _chatLocale == 'en_US' ? 'ur_PK' : 'en_US';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            _chatLocale == 'en_US' ? '🇺🇸 EN' : '🇵🇰 اردو',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      // Stop button
                      GestureDetector(
                        onTap: () async {
                          Navigator.of(context).pop();
                          await _speechToText.stop();
                          if (mounted) {
                            setState(() => _isChatListening = false);
                          }
                        },
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.stop,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Show voice send options after speech recognition
  void _showVoiceSendOptions() {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mic_rounded,
                        color: Color(0xFF047A62),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Voice Message Ready',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Recognized text
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: Text(
                    widget.controller.text,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.controller.clear();
                          _handleChatVoice(); // Retry voice input
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Color(0xFF047A62)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.refresh,
                                color: Color(0xFF047A62), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Retry',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF047A62),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pop(context);
                          final parentState = context.findAncestorStateOfType<
                              _VendorHomeScreenState>();
                          parentState?._sendMessage(isVoiceMessage: true);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF047A62),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.send, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Send',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Edit option
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Focus on text field for manual editing
                      FocusScope.of(context).requestFocus(FocusNode());
                    },
                    child: Text(
                      'Edit message manually',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF047A62),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleChatVoice() async {
    final micPermission = await Permission.microphone.status;

    if (micPermission.isDenied) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Microphone permission needed',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: const Color(0xFF047A62),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    if (_isChatListening) {
      await _speechToText.stop();
      setState(() => _isChatListening = false);
      return;
    }

    setState(() => _isChatListening = true);

    await _speechToText.listen(
      onResult: (result) {
        String processedText = result.recognizedWords;
        _urduChatPhrases.forEach((urdu, english) {
          if (result.recognizedWords.contains(urdu)) {
            processedText = english;
          }
        });

        setState(() {
          widget.controller.text = processedText;
          widget.controller.selection = TextSelection.fromPosition(
            TextPosition(offset: widget.controller.text.length),
          );
        });

        if (result.finalResult) {
          setState(() => _isChatListening = false);

          // Show voice send options instead of auto-sending
          if (widget.controller.text.trim().isNotEmpty) {
            _showVoiceSendOptions();
          }
        }
      },
      localeId: _chatLocale,
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 3),
      listenOptions: SpeechListenOptions(
        partialResults: true,
      ),
      onSoundLevelChange: (level) {
        setState(() => _chatSoundLevel = level);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildMessageList()),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF047A62),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Text(
            'Muawin Rehnuma',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.messages.length,
      itemBuilder: (context, index) {
        final message = widget.messages[index];
        final isUser = message['isUser'] as bool;
        final isVoiceMessage = message['isVoiceMessage'] as bool? ?? false;

        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isUser ? const Color(0xFF047A62) : Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                Text(
                  message['text'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: isUser ? Colors.white : Colors.black87,
                  ),
                ),
                if (isUser && isVoiceMessage)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Icon(
                      Icons.mic,
                      size: 10,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Voice indicator (shows when listening)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isChatListening ? 80 : 0,
            child: _isChatListening
                ? ChatVoiceIndicator(
                    soundLevel: _chatSoundLevel,
                    locale: _chatLocale,
                    onLanguageChange: (locale) {
                      setState(() => _chatLocale = locale);
                    },
                    onStop: () {
                      _speechToText.stop();
                      setState(() => _isChatListening = false);
                    },
                    onFullScreen: () {
                      // Show full-screen voice overlay
                      _showFullScreenVoiceOverlay();
                    },
                    detectedLanguage: _detectedLanguage,
                    languageConfidence: _languageConfidence,
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  decoration: InputDecoration(
                    hintText: 'Type or tap 🎤 to speak...',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey),
                    prefixIcon: widget.controller.text.isEmpty
                        ? Icon(Icons.mic_none_rounded,
                            color: Colors.grey[400], size: 18)
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: Color(0xFF047A62)),
                    ),
                  ),
                  onSubmitted: (_) => widget.onSendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              ChatMicButton(
                isListening: _isChatListening,
                onTap: _handleChatVoice,
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: const Color(0xFF047A62),
                radius: 24,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                  onPressed: widget.onSendMessage,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
