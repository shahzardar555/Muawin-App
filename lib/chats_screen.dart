import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'chat_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  late List<Map<String, dynamic>> _threads;

  @override
  void initState() {
    super.initState();
    _threads = List.from(_originalThreads);
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

  List<Map<String, dynamic>> get _originalThreads => [
        {
          'id': 't1',
          'name': 'Ahmed Khan',
          'role': 'CUSTOMER',
          'snippet': 'Thanks for the prompt service!',
          'time': '2026-03-14 14:14',
          'unread': true,
          'profilePicture':
              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
          'isOnline': true,
        },
        {
          'id': 't2',
          'name': 'Nadia Ali',
          'role': 'CUSTOMER',
          'snippet': 'Can you come at 4 instead?',
          'time': '2026-03-13 16:00',
          'unread': false,
          'profilePicture':
              'https://images.unsplash.com/photo-1494760105753-6511b94c32af?w=150&h=150&fit=crop&crop=face',
          'isOnline': false,
        },
        {
          'id': 't3',
          'name': 'Sarah Johnson',
          'role': 'CUSTOMER',
          'snippet': 'The service was excellent!',
          'time': '2026-03-12 11:20',
          'unread': false,
          'profilePicture':
              'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face',
          'isOnline': true,
        },
        {
          'id': 't4',
          'name': 'Muhammad Hassan',
          'role': 'CUSTOMER',
          'snippet': 'When can you start?',
          'time': '2026-03-11 09:15',
          'unread': true,
          'profilePicture':
              'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&h=150&fit=crop&crop=face',
          'isOnline': false,
        },
        {
          'id': 't5',
          'name': 'Fatima Sheikh',
          'role': 'CUSTOMER',
          'snippet': 'Your service was amazing!',
          'time': '2026-03-07 18:30',
          'unread': false,
          'profilePicture':
              'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face',
          'isOnline': true,
        },
      ];

  void _openChat(Map<String, dynamic> chat) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => ChatScreen(chatData: chat)));
  }

  String _formatTimestamp(String timestamp) {
    final dt = DateTime.parse(timestamp);
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return DateFormat.jm().format(dt); // Today: show time
    } else if (dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day - 1) {
      return 'Yesterday';
    } else {
      return DateFormat.MMMd().format(dt); // Older: show date
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

  void _resetSort() => setState(() => _threads = List.from(_originalThreads));

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
                child: _filtered.isEmpty
                    ? const Center(child: Text('No conversations found'))
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final t = _filtered[i];
                          return _ThreadCard(
                            name: t['name'],
                            role: t['role'],
                            snippet: t['snippet'],
                            time: _formatTimestamp(t['time']),
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
