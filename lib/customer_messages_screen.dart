import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/bottom_navigation_bar.dart';
import 'customer_home_screen.dart';
import 'customer_jobs_screen.dart';
import 'customer_profile_screen.dart';
import 'post_job_screen.dart';
import 'chat_screen.dart';

/// Customer Messages Screen (/customer/messages)
/// Premium, structured inbox experience using depth, squircle iconography,
/// and clear status indicators.
class CustomerMessagesScreen extends StatefulWidget {
  const CustomerMessagesScreen({super.key, this.providerName});

  final String? providerName;

  @override
  State<CustomerMessagesScreen> createState() => _CustomerMessagesScreenState();
}

class _CustomerMessagesScreenState extends State<CustomerMessagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allChats = [];
  List<Map<String, dynamic>> _filteredChats = [];
  bool _isLoadingChats = false;
  String _currentProfileId = '';

  @override
  void initState() {
    super.initState();
    _initializeChats();
    _searchController.addListener(_filterChats);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterChats);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeChats() async {
    if (mounted) setState(() => _isLoadingChats = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Get current user's profile id
      final profileResp = await supabase
          .from('profiles')
          .select('id')
          .eq('user_id', user.id)
          .single();

      _currentProfileId = profileResp['id']?.toString() ?? '';
      debugPrint('Current profile ID: $_currentProfileId');
      if (_currentProfileId.isEmpty) return;

      // Query threads where user is participant_1
      final threads1 = await supabase
          .from('message_threads')
          .select(
              'id, participant_1_id, participant_2_id, last_message_at, is_active')
          .eq('participant_1_id', _currentProfileId)
          .order('last_message_at', ascending: false);

      // Query threads where user is participant_2
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

      debugPrint(
          'Threads1: ${threads1.length}, Threads2: ${threads2.length}, Combined: ${threads.length}');

      final List<Map<String, dynamic>> chats = [];

      for (final thread in threads) {
        final threadId = thread['id']?.toString() ?? '';

        // Get the other participant's ID
        final otherParticipantId =
            thread['participant_1_id']?.toString() == _currentProfileId
                ? thread['participant_2_id']?.toString() ?? ''
                : thread['participant_1_id']?.toString() ?? '';

        if (otherParticipantId.isEmpty) continue;

        // Get other participant's profile
        final otherProfile = await supabase
            .from('profiles')
            .select('id, full_name, profile_image_url, role')
            .eq('id', otherParticipantId)
            .maybeSingle();

        if (otherProfile == null) continue;

        // Get last message for this thread
        final lastMessages = await supabase
            .from('messages')
            .select('content, created_at, is_read, sender_id')
            .eq('thread_id', threadId)
            .order('created_at', ascending: false)
            .limit(1);

        String lastMessage = 'No messages yet';
        String timestamp = '';
        bool isUnread = false;

        if (lastMessages.isNotEmpty) {
          final last = lastMessages.first;
          lastMessage = last['content']?.toString() ?? 'Message';
          isUnread = last['is_read'] == false &&
              last['sender_id']?.toString() != _currentProfileId;

          final createdAt =
              DateTime.tryParse(last['created_at']?.toString() ?? '');
          if (createdAt != null) {
            final now = DateTime.now();
            final diff = now.difference(createdAt);
            if (diff.inMinutes < 60) {
              timestamp = '${diff.inMinutes} min ago';
            } else if (diff.inHours < 24) {
              timestamp = '${diff.inHours}h ago';
            } else {
              timestamp = '${diff.inDays}d ago';
            }
          }
        }

        // Determine type and category from role
        final role = otherProfile['role']?.toString() ?? 'provider';
        String type = 'provider';
        String category = 'Service Provider';

        if (role == 'vendor') {
          type = 'vendor';
          category = 'Vendor';
        } else if (role == 'provider') {
          type = 'provider';
          category = 'Service Provider';
        }

        // Get more specific category if provider
        if (role == 'provider') {
          final providerData = await supabase
              .from('providers')
              .select('service_category')
              .eq('profile_id', otherParticipantId)
              .maybeSingle();
          if (providerData != null) {
            category = providerData['service_category']?.toString() ??
                'Service Provider';
          }
        } else if (role == 'vendor') {
          final vendorData = await supabase
              .from('vendors')
              .select('business_type')
              .eq('profile_id', otherParticipantId)
              .maybeSingle();
          if (vendorData != null) {
            category = vendorData['business_type']?.toString() ?? 'Vendor';
          }
        }

        chats.add({
          'id': threadId,
          'name': otherProfile['full_name']?.toString() ?? 'Unknown',
          'avatar': otherProfile['profile_image_url']?.toString() ?? '',
          'lastMessage': lastMessage,
          'timestamp': timestamp,
          'isUnread': isUnread,
          'isOnline': false,
          'type': type,
          'category': category,
          'otherParticipantId': otherParticipantId,
        });
      }

      debugPrint('Chats built: ${chats.length}');

      if (mounted) {
        setState(() {
          _allChats = chats;
          _filteredChats = List.from(chats);
          _isLoadingChats = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading chats: $e');
      debugPrint('Error stack: ${StackTrace.current}');
      if (mounted) setState(() => _isLoadingChats = false);
    }
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Sort options title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Text(
                    'Sort Messages',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Sort options
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
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF088771)),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      onTap: onTap,
    );
  }

  void _openChat(Map<String, dynamic> chat) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(chatData: chat),
      ),
    );
  }

  void _sortChats(String sortType) {
    setState(() {
      switch (sortType) {
        case 'recent':
          // Sort by timestamp (most recent first)
          _filteredChats.sort((a, b) {
            // Simple timestamp comparison - in real app, parse actual dates
            final aTime = a['timestamp'] as String;
            final bTime = b['timestamp'] as String;
            return aTime
                .compareTo(bTime); // This will sort with most recent last
          });
          _filteredChats = _filteredChats.reversed.toList();
          break;

        case 'oldest':
          // Sort by timestamp (oldest first)
          _filteredChats.sort((a, b) {
            final aTime = a['timestamp'] as String;
            final bTime = b['timestamp'] as String;
            return aTime.compareTo(bTime);
          });
          break;

        case 'unread':
          // Sort by unread status first, then by timestamp
          _filteredChats.sort((a, b) {
            final aUnread = a['isUnread'] as bool;
            final bUnread = b['isUnread'] as bool;

            // Unread chats come first
            if (aUnread && !bUnread) return -1;
            if (!aUnread && bUnread) return 1;

            // If both have same unread status, sort by timestamp
            final aTime = a['timestamp'] as String;
            final bTime = b['timestamp'] as String;
            return aTime.compareTo(bTime);
          });
          _filteredChats = _filteredChats.reversed.toList();
          break;

        case 'alphabetical':
          // Sort by name alphabetically
          _filteredChats.sort((a, b) {
            final aName = a['name'] as String;
            final bName = b['name'] as String;
            return aName.toLowerCase().compareTo(bName.toLowerCase());
          });
          break;
      }
    });
  }

  void _filterChats() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredChats = query.isEmpty
          ? List.from(_allChats)
          : _allChats.where((chat) {
              final name = chat['name'].toString().toLowerCase();
              final lastMessage = chat['lastMessage'].toString().toLowerCase();
              final category = chat['category'].toString().toLowerCase();
              return name.contains(query) ||
                  lastMessage.contains(query) ||
                  category.contains(query);
            }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoadingChats
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF088771),
              ),
            )
          : _filteredChats.isEmpty
              ? const Center(
                  child: Text(
                    'No chats yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: _filteredChats.length + 1, // +1 for header
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // Header item
                      return Container(
                        width: double.infinity, // Full width
                        padding: const EdgeInsets.only(
                          top:
                              64, // pt-16 (4rem / 64px) for status bar clearance
                          left: 24,
                          right: 24,
                          bottom:
                              40, // pb-10 (2.5rem / 40px) to balance rounded curve
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF088771), // Muawin Primary Teal
                              Color(0xFF064e3b), // Tailwind Emerald 900
                            ],
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(40), // rounded-b-[40px]
                            bottomRight:
                                Radius.circular(40), // rounded-b-[40px]
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                  alpha: 0.25), // Large shadow (shadow-lg)
                              blurRadius:
                                  20, // Increased blur for large shadow effect
                              spreadRadius:
                                  5, // Added spread for floating effect
                              offset:
                                  const Offset(0, 8), // More pronounced offset
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Header content
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Column(
                                children: [
                                  // Title row
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Chats',
                                              style: GoogleFonts.poppins(
                                                fontSize: 48,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Stay connected with your Helpers',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w400,
                                                color: Colors.white
                                                    .withValues(alpha: 0.7),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Search bar and sort button row
                                  Row(
                                    children: [
                                      // Search bar
                                      Expanded(
                                        child: Container(
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.2),
                                            borderRadius:
                                                BorderRadius.circular(24),
                                          ),
                                          child: TextField(
                                            controller: _searchController,
                                            decoration: InputDecoration(
                                              hintText:
                                                  'Search names or messages...',
                                              hintStyle: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: Colors.black54,
                                              ),
                                              prefixIcon: const Icon(
                                                Icons.search,
                                                color: Colors.black54,
                                                size: 20,
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(24),
                                                borderSide: BorderSide.none,
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(24),
                                                borderSide: BorderSide.none,
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(24),
                                                borderSide: BorderSide.none,
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 12,
                                              ),
                                            ),
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Sort button
                                      GestureDetector(
                                        onTap: _showSortOptions,
                                        child: Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.2),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.sort,
                                            color: Colors.white,
                                            size: 20,
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
                    } else {
                      // Chat items (index - 1 to account for header)
                      final chat = _filteredChats[index - 1];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: GestureDetector(
                          onTap: () => _openChat(chat),
                          child: _chatCard(chat: chat, primary: primary),
                        ),
                      );
                    }
                  },
                ),
      bottomNavigationBar: MuawinBottomNavigationBar(
        currentIndex: 3, // Messages is index 3
        onItemTapped: (index) {
          if (index == 0) {
            // Navigate to Home
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
              (route) => false,
            );
          } else if (index == 1) {
            // Navigate to Jobs
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CustomerJobsScreen()),
            );
          } else if (index == 2) {
            // Navigate to Post Job
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PostJobScreen()),
            );
          } else if (index == 4) {
            // Navigate to Profile
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CustomerProfileScreen()),
            );
          }
          // Messages (index 3) is current screen, no navigation needed
        },
      ),
    );
  }

  Widget _chatCard(
      {required Map<String, dynamic> chat, required Color primary}) {
    final name = chat['name'] as String;
    final lastMessage = chat['lastMessage'] as String;
    final timestamp = chat['timestamp'] as String;
    final isUnread = chat['isUnread'] as bool;
    final isOnline = chat['isOnline'] as bool;
    final type = chat['type'] as String;
    final avatar = chat['avatar'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar and status dot column
          Column(
            children: [
              // Avatar with status dot overlay
              SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  children: [
                    // Avatar
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius:
                            BorderRadius.circular(12), // Squircle shape
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: (avatar != null &&
                              avatar.isNotEmpty &&
                              avatar.startsWith('http'))
                          ? Image.network(
                              avatar,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.person,
                                  size: 28,
                                  color: Colors.grey[400],
                                );
                              },
                            )
                          : Icon(
                              type == 'provider'
                                  ? Icons.cleaning_services
                                  : Icons.store,
                              size: 28,
                              color: Colors.grey[600],
                            ),
                    ),
                    // Online/Offline status dot at bottom right
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color:
                                isOnline ? const Color(0xFF4CAF50) : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(width: 16),

          // Chat info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and category row (no status dot here anymore)
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: type == 'provider'
                                  ? const Color(
                                      0xFFE8F5E8) // Very light green background for providers
                                  : const Color(
                                      0xFFD97706), // Golden for vendors
                              border: type == 'provider'
                                  ? Border.all(
                                      color: const Color(
                                          0xFF4CAF50), // Light green outline for providers
                                      width: 1,
                                    )
                                  : null, // No border for vendors
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              chat['category'] as String,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: type == 'provider'
                                    ? const Color(
                                        0xFF66BB6A) // Pastel green text for providers
                                    : Colors.white, // White for vendors
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Last message and timestamp row
                Row(
                  children: [
                    // Last message
                    Expanded(
                      child: Text(
                        lastMessage,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight:
                              isUnread ? FontWeight.bold : FontWeight.normal,
                          color: isUnread ? Colors.black87 : Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Timestamp at bottom right
                    Text(
                      timestamp,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[500],
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
  }
}
