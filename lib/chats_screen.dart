import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  List<Map<String, dynamic>> _threads = [];
  bool _isLoadingChats = false;
  String _currentProfileId = '';

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    if (_query.trim().isEmpty) return _threads;
    return _threads
        .where((t) =>
            t['name'].toString().toLowerCase().contains(_query.toLowerCase()) ||
            t['snippet']
                .toString()
                .toLowerCase()
                .contains(_query.toLowerCase()))
        .toList();
  }

  Future<void> _loadChats() async {
    if (mounted) setState(() => _isLoadingChats = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Get current provider's profile id
      final profileResp = await supabase
          .from('profiles')
          .select('id')
          .eq('user_id', user.id)
          .single();

      _currentProfileId = profileResp['id']?.toString() ?? '';
      if (_currentProfileId.isEmpty) return;

      debugPrint('Provider chat profile ID: $_currentProfileId');

      // Get threads where provider is participant_1
      final threads1 = await supabase
          .from('message_threads')
          .select(
              'id, participant_1_id, participant_2_id, last_message_at, is_active')
          .eq('participant_1_id', _currentProfileId)
          .order('last_message_at', ascending: false);

      // Get threads where provider is participant_2
      final threads2 = await supabase
          .from('message_threads')
          .select(
              'id, participant_1_id, participant_2_id, last_message_at, is_active')
          .eq('participant_2_id', _currentProfileId)
          .order('last_message_at', ascending: false);

      // Combine and deduplicate
      final Map<String, dynamic> threadMap = {};
      for (final t in [...threads1, ...threads2]) {
        threadMap[t['id']?.toString() ?? ''] = t;
      }
      final threads = threadMap.values.toList();

      debugPrint('Provider threads found: ${threads.length}');

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
            .select('id, full_name, profile_image_url, role')
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

        // Use provider-specific map keys
        chats.add({
          'id': threadId,
          'name': otherProfile['full_name']?.toString() ?? 'Customer',
          'role': 'CUSTOMER',
          'snippet': snippet,
          'time': time,
          'unread': unread,
          'profilePicture': otherProfile['profile_image_url']?.toString() ?? '',
          'isOnline': false,
          'otherParticipantId': otherParticipantId,
        });
      }

      debugPrint('Provider chats built: ${chats.length}');

      if (mounted) {
        setState(() {
          _threads = chats;
          _isLoadingChats = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading provider chats: $e');
      if (mounted) setState(() => _isLoadingChats = false);
    }
  }

  void _openChat(Map<String, dynamic> chat) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => ChatScreen(chatData: chat)));
  }

  String _formatTimestamp(String timestamp) {
    if (timestamp.isEmpty) return '';

    // If already formatted (contains 'ago', ':', etc.) return as-is
    if (timestamp.contains('ago') || timestamp.contains(':')) {
      return timestamp;
    }

    // Try to parse as DateTime
    final date = DateTime.tryParse(timestamp);
    if (date == null) return timestamp;

    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
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
              // Fallback to string comparison if DateTime parsing fails
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
              // Fallback to string comparison if DateTime parsing fails
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
              // Fallback to string comparison if DateTime parsing fails
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

  void _resetSort() {
    _loadChats();
  }

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
            _buildSortOption('Reset to Default', Icons.refresh, _resetSort),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                  top: MediaQuery.paddingOf(context).top + 48,
                  left: 20,
                  right: 20,
                  bottom: 36),
              decoration: BoxDecoration(
                color: primary,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(40)),
              ),
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Positioned(
                    right: -24,
                    top: -20,
                    child: Transform.rotate(
                      angle: 12 * (3.14159 / 180),
                      child: const Opacity(
                        opacity: 0.1,
                        child: Icon(
                          Icons.message_rounded,
                          size: 128,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Chats',
                                style: GoogleFonts.poppins(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                    color:
                                        Colors.white.withValues(alpha: 0.95))),
                            const SizedBox(height: 6),
                            Text('Stay in touch with your customers',
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        Colors.white.withValues(alpha: 0.95))),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _showSortOptions,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.sort_rounded,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    const Icon(Icons.search, color: Colors.black45),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _query = v),
                        decoration: const InputDecoration(
                          hintText: 'Search customer conversations...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    if (_query.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(Icons.close, color: Colors.black45),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: _isLoadingChats
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF088771),
                        ),
                      )
                    : _filtered.isEmpty
                        ? const Center(child: Text('No conversations found'))
                        : ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, i) {
                              final t = _filtered[i];
                              return _ThreadCard(
                                name: t['name'],
                                role: t['role'],
                                snippet: t['snippet'],
                                time: t['time'].toString().isNotEmpty
                                    ? _formatTimestamp(t['time'])
                                    : '',
                                unread: t['unread'],
                                profilePicture: t['profilePicture'],
                                primary: primary,
                                isOnline: t['isOnline'],
                                onTap: () => _openChat(t),
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThreadCard extends StatelessWidget {
  const _ThreadCard({
    required this.name,
    required this.role,
    required this.snippet,
    required this.time,
    required this.unread,
    required this.profilePicture,
    required this.primary,
    required this.isOnline,
    required this.onTap,
  });

  final String name;
  final String role;
  final String snippet;
  final String time;
  final bool unread;
  final String profilePicture;
  final Color primary;
  final bool isOnline;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: unread ? Colors.white : Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    profilePicture,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          size: 32,
                          color: Colors.grey.shade600,
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.grey.shade400),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(name,
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                      ),
                      Text(time,
                          style: GoogleFonts.poppins(
                              fontSize: 10, color: Colors.black45)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(role,
                            style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: primary)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(snippet,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                color:
                                    unread ? Colors.black87 : Colors.black54)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            unread
                ? Container(
                    width: 10,
                    height: 10,
                    decoration:
                        BoxDecoration(color: primary, shape: BoxShape.circle))
                : const Icon(Icons.done_all, size: 16, color: Colors.black45),
          ],
        ),
      ),
    );
  }
}
