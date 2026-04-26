import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
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

  @override
  void initState() {
    super.initState();
    _initializeMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeMessages() {
    final chatData = widget.chatData;
    final type = chatData['type'] as String? ?? 'vendor';

    if (type == 'customer') {
      _messages = [
        {
          'id': '1',
          'text': 'Hello! I need your services.',
          'sender': 'other',
          'timestamp': '10:30 AM',
          'isRead': true,
        },
        {
          'id': '2',
          'text': 'Hi! I\'d be happy to help. What service do you need?',
          'sender': 'me',
          'timestamp': '10:32 AM',
          'isRead': true,
        },
        {
          'id': '3',
          'text': 'I need a driver for airport transfer tomorrow.',
          'sender': 'other',
          'timestamp': '10:35 AM',
          'isRead': true,
        },
        {
          'id': '4',
          'text': 'Perfect! What time is your flight?',
          'sender': 'me',
          'timestamp': '10:36 AM',
          'isRead': true,
        },
      ];
    } else {
      _messages = [
        {
          'id': '1',
          'text': 'Hello! I\'m available for the job you posted.',
          'sender': 'other',
          'timestamp': '10:30 AM',
          'isRead': true,
        },
        {
          'id': '2',
          'text': 'Great! When can you start?',
          'sender': 'me',
          'timestamp': '10:32 AM',
          'isRead': true,
        },
        {
          'id': '3',
          'text': 'I can start tomorrow morning. Is that okay?',
          'sender': 'other',
          'timestamp': '10:35 AM',
          'isRead': true,
        },
        {
          'id': '4',
          'text': 'Perfect! See you tomorrow at 9 AM.',
          'sender': 'me',
          'timestamp': '10:36 AM',
          'isRead': true,
        },
      ];
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'id': (_messages.length + 1).toString(),
        'text': text,
        'sender': 'me',
        'timestamp': _getCurrentTime(),
        'isRead': true,
      });
    });

    _messageController.clear();
    _scrollToBottom();

    // Send notification to the receiver
    _sendNotificationToReceiver(text);

    _simulateOtherPersonResponse();
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

  void _simulateOtherPersonResponse() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _messages.add({
            'id': (_messages.length + 1).toString(),
            'text': 'Thank you for your message! I\'ll respond soon.',
            'sender': 'other',
            'timestamp': _getCurrentTime(),
            'isRead': false,
          });
        });
        _scrollToBottom();
      }
    });
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
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
            child: ListView.builder(
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
