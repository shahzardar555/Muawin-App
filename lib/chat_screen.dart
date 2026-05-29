import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/notification_manager.dart' as nm;

/// Chat Screen for individual conversations
/// Full chat interface with message bubbles, input field, and real-time messaging
class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> chatData;

  const ChatScreen({super.key, required this.chatData});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  String _currentProfileId = '';
  bool _isLoadingMessages = true;
  RealtimeChannel? _messagesChannel;

  @override
  void initState() {
    super.initState();
    _initializeMessages();
  }

  @override
  void dispose() {
    _messagesChannel?.unsubscribe();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeMessages() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Get current user profile id
      final profileResp = await supabase
          .from('profiles')
          .select('id')
          .eq('user_id', user.id)
          .single();

      _currentProfileId = profileResp['id']?.toString() ?? '';

      final threadId = widget.chatData['id']?.toString() ?? '';
      if (threadId.isEmpty) return;

      // Load existing messages
      await _loadMessages(threadId);

      // Subscribe to real-time new messages
      _messagesChannel = supabase
          .channel('messages:$threadId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'messages',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'thread_id',
              value: threadId,
            ),
            callback: (payload) {
              final newMsg = payload.newRecord;
              final newMsgId = newMsg['id']?.toString() ?? '';
              // Prevent duplicate: skip if message already exists in list
              if (_messages.any((m) => m['id'] == newMsgId)) return;
              final isMe = newMsg['sender_id']?.toString() == _currentProfileId;

              // Format timestamp as HH:mm
              final createdAt =
                  DateTime.tryParse(newMsg['created_at']?.toString() ?? '');
              String formattedTime = '';
              if (createdAt != null) {
                final hour = createdAt.hour.toString().padLeft(2, '0');
                final minute = createdAt.minute.toString().padLeft(2, '0');
                formattedTime = '$hour:$minute';
              }

              final msgMap = {
                'id': newMsgId,
                'content': newMsg['content']?.toString() ?? '',
                'sender_id': newMsg['sender_id']?.toString() ?? '',
                'isMe': isMe,
                'sender': isMe ? 'me' : 'other',
                'text': newMsg['content']?.toString() ?? '',
                'timestamp': formattedTime,
                'isRead': newMsg['is_read'] ?? false,
              };
              if (mounted) {
                setState(() => _messages.add(msgMap));
                _scrollToBottom();
              }
            },
          )
          .subscribe();

      debugPrint('Chat initialized for thread: $threadId');
    } catch (e) {
      debugPrint('Error initializing chat: $e');
    } finally {
      if (mounted) setState(() => _isLoadingMessages = false);
    }
  }

  Future<void> _loadMessages(String threadId) async {
    try {
      final supabase = Supabase.instance.client;

      final response = await supabase
          .from('messages')
          .select('id, content, sender_id, is_read, created_at')
          .eq('thread_id', threadId)
          .order('created_at', ascending: true);

      final List<Map<String, dynamic>> loaded = (response as List).map((m) {
        final isMe = m['sender_id']?.toString() == _currentProfileId;

        // Format timestamp as HH:mm
        final createdAt = DateTime.tryParse(m['created_at']?.toString() ?? '');
        String formattedTime = '';
        if (createdAt != null) {
          final hour = createdAt.hour.toString().padLeft(2, '0');
          final minute = createdAt.minute.toString().padLeft(2, '0');
          formattedTime = '$hour:$minute';
        }

        return {
          'id': m['id']?.toString() ?? '',
          'content': m['content']?.toString() ?? '',
          'sender_id': m['sender_id']?.toString() ?? '',
          'isMe': isMe,
          'sender': isMe ? 'me' : 'other',
          'text': m['content']?.toString() ?? '',
          'timestamp': formattedTime,
          'isRead': m['is_read'] ?? false,
        };
      }).toList();

      if (mounted) {
        setState(() => _messages = loaded);
      }

      debugPrint('Messages loaded: ${loaded.length}');
    } catch (e) {
      debugPrint('Error loading messages: $e');
    }
  }

  Future<void> _sendMessage() async {
    debugPrint(
        'Send tapped — content: ${_messageController.text}, threadId: ${widget.chatData['id']}, profileId: $_currentProfileId');
    final content = _messageController.text.trim();
    if (content.isEmpty) return;
    if (_currentProfileId.isEmpty) return;

    final threadId = widget.chatData['id']?.toString() ?? '';
    if (threadId.isEmpty) return;

    _messageController.clear();

    // Add to local list immediately for instant UI update
    final tempMessage = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'content': content,
      'sender_id': _currentProfileId,
      'isMe': true,
      'sender': 'me',
      'timestamp': () {
        final now = DateTime.now();
        final hour = now.hour.toString().padLeft(2, '0');
        final minute = now.minute.toString().padLeft(2, '0');
        return '$hour:$minute';
      }(),
      'isRead': false,
      'text': content,
    };

    if (mounted) {
      setState(() {
        _messages.add(tempMessage);
      });
    }

    // Scroll to bottom after adding message
    _scrollToBottom();

    try {
      final supabase = Supabase.instance.client;

      await supabase.from('messages').insert({
        'thread_id': threadId,
        'sender_id': _currentProfileId,
        'content': content,
        'is_read': false,
      });

      // Update thread last_message_at
      await supabase
          .from('message_threads')
          .update({'last_message_at': DateTime.now().toIso8601String()}).eq(
              'id', threadId);

      // Send notification to the other party
      _sendNotificationToReceiver(content);

      debugPrint('Message sent: $content');
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  void _sendNotificationToReceiver(String messageText) {
    // Determine receiver type and ID based on chat data
    String receiverType = 'vendor'; // Default to vendor
    String receiverId = 'vendor_123'; // This should come from chatData

    // Check if this is a customer chatting with vendor
    if (widget.chatData.containsKey('type')) {
      if (widget.chatData['type'] == 'vendor') {
        receiverType = 'vendor';
        receiverId = widget.chatData['id']?.toString() ?? 'vendor_123';
      } else if (widget.chatData['type'] == 'provider') {
        receiverType = 'provider';
        receiverId = widget.chatData['id']?.toString() ?? 'provider_123';
      } else if (widget.chatData['type'] == 'customer') {
        receiverType = 'customer';
        receiverId = widget.chatData['id']?.toString() ?? 'customer_123';
      }
    }

    // Get sender name from chat data
    String senderName = 'You';
    if (widget.chatData.containsKey('name')) {
      senderName = widget.chatData['name']?.toString() ?? 'Customer';
    }

    // Send notification using NotificationManager
    final notificationManager =
        Provider.of<nm.NotificationManager>(context, listen: false);
    notificationManager.sendNotification(
      receiverId: receiverId,
      receiverType: receiverType,
      type: nm.NotificationType.chatMessageReceived,
      title: 'New Message from $senderName',
      body: messageText,
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatData = widget.chatData;
    final name = chatData['name'] as String;
    final isOnline = chatData['isOnline'] as bool;
    final avatar = chatData['avatar'] as String? ?? '';
    final type = chatData['type'] as String? ?? 'vendor';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF088771),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                avatar,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    type == 'provider'
                        ? Icons.cleaning_services
                        : type == 'customer'
                            ? Icons.person
                            : Icons.store,
                    size: 20,
                    color: Colors.grey[400],
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    children: [
                      if (isOnline)
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
                        isOnline ? 'Online' : 'Offline',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
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
      body: Column(
        children: [
          Expanded(
            child: _isLoadingMessages
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF088771),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMe = message['sender'] == 'me';
                      return _messageBubble(message: message, isMe: isMe);
                    },
                  ),
          ),

          // Updated message input container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      style: GoogleFonts.poppins(fontSize: 14),
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
                      color: const Color(0xFF088771),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageBubble(
      {required Map<String, dynamic> message, required bool isMe}) {
    final text = message['text'] as String;
    final timestamp = message['timestamp'] as String;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                widget.chatData['type'] == 'provider'
                    ? Icons.cleaning_services
                    : widget.chatData['type'] == 'customer'
                        ? Icons.person
                        : Icons.store,
                size: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isMe ? const Color(0xFF088771) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: !isMe ? Border.all(color: Colors.grey[200]!) : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    text,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: isMe ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timestamp,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFF088771),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                size: 16,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
