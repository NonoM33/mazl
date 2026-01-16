import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/services/websocket_service.dart';
import '../../../../core/theme/app_colors.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.conversationId,
  });

  final String conversationId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ApiService _apiService = ApiService();
  final WebSocketService _wsService = WebSocketService();

  List<Message> _messages = [];
  ConversationUser? _otherUser;
  bool _isLoading = true;
  bool _isSending = false;
  bool _isTyping = false;
  bool _hasMore = true;
  int? _currentUserId;
  StreamSubscription<ChatEvent>? _wsSubscription;
  Timer? _typingTimer;

  int get _conversationId => int.tryParse(widget.conversationId) ?? 0;

  @override
  void initState() {
    super.initState();
    _loadConversation();
    _loadMessages();
    _setupWebSocket();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _wsSubscription?.cancel();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _setupWebSocket() {
    _wsService.connect();
    _wsSubscription = _wsService.events.listen((event) {
      if (event is NewMessageEvent && event.conversationId == _conversationId) {
        // Add new message to list
        setState(() {
          _messages.insert(0, Message(
            id: event.messageId,
            senderId: event.senderId,
            content: event.content,
            isRead: false,
            createdAt: event.createdAt,
          ));
        });
        // Mark as read
        _wsService.markAsRead(_conversationId);
        _apiService.markMessagesAsRead(_conversationId);
      } else if (event is TypingEvent && event.conversationId == _conversationId) {
        setState(() {
          _isTyping = event.isTyping;
        });
        // Clear typing after 3 seconds
        _typingTimer?.cancel();
        if (event.isTyping) {
          _typingTimer = Timer(const Duration(seconds: 3), () {
            if (mounted) setState(() => _isTyping = false);
          });
        }
      } else if (event is MessagesReadEvent && event.conversationId == _conversationId) {
        // Mark all my messages as read when the other user reads them
        if (_currentUserId != null && event.userId != _currentUserId) {
          setState(() {
            for (var i = 0; i < _messages.length; i++) {
              if (_messages[i].senderId == _currentUserId && !_messages[i].isRead) {
                _messages[i] = Message(
                  id: _messages[i].id,
                  senderId: _messages[i].senderId,
                  content: _messages[i].content,
                  isRead: true,
                  createdAt: _messages[i].createdAt,
                );
              }
            }
          });
        }
      }
    });
  }

  Future<void> _loadConversation() async {
    // Get current user ID from API service
    final userResponse = await _apiService.getCurrentUser();
    if (userResponse.success && userResponse.data != null) {
      _currentUserId = userResponse.data!.id;
    }

    // Get conversation details
    final response = await _apiService.getConversations();
    if (response.success && response.data != null) {
      final conversation = response.data!.firstWhere(
        (c) => c.id == _conversationId,
        orElse: () => response.data!.first,
      );
      if (mounted) {
        setState(() {
          _otherUser = conversation.otherUser;
        });
      }
    }
  }

  Future<void> _loadMessages({bool loadMore = false}) async {
    if (!_hasMore && loadMore) return;

    if (!loadMore) {
      setState(() => _isLoading = true);
    }

    final offset = loadMore ? _messages.length : 0;
    final response = await _apiService.getMessages(
      _conversationId,
      limit: 50,
      offset: offset,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response.success && response.data != null) {
          if (loadMore) {
            _messages.addAll(response.data!);
          } else {
            _messages = response.data!;
          }
          _hasMore = response.data!.length >= 50;
        }
      });
    }

    // Mark as read on open
    if (!loadMore && _messages.isNotEmpty) {
      _wsService.markAsRead(_conversationId);
      _apiService.markMessagesAsRead(_conversationId);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMessages(loadMore: true);
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    // Send via WebSocket for real-time
    _wsService.sendMessage(_conversationId, content);

    // Also send via API for persistence
    final response = await _apiService.sendMessage(_conversationId, content);

    if (mounted) {
      setState(() => _isSending = false);

      if (response.success && response.data != null) {
        // Add to messages if not already there from WebSocket
        final exists = _messages.any((m) => m.id == response.data!.id);
        if (!exists) {
          setState(() {
            _messages.insert(0, response.data!);
          });
        }
      }
    }
  }

  void _onTyping() {
    _wsService.sendTyping(_conversationId);
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays == 0) {
      return DateFormat.Hm().format(dateTime);
    } else if (diff.inDays == 1) {
      return 'Hier ${DateFormat.Hm().format(dateTime)}';
    } else {
      return DateFormat.MMMd().add_Hm().format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            if (_otherUser?.picture != null)
              CircleAvatar(
                radius: 18,
                backgroundImage: CachedNetworkImageProvider(_otherUser!.picture!),
              )
            else
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary,
                child: Text(
                  (_otherUser?.displayName?.isNotEmpty == true)
                      ? _otherUser!.displayName![0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _otherUser?.displayName ?? 'Chargement...',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                if (_isTyping)
                  Text(
                    'écrit...',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  Text(
                    'En ligne',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.success,
                    ),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.video),
            onPressed: () {
              context.go('/chat/${widget.conversationId}/video-call');
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.moreVertical),
            onPressed: () {
              _showOptionsMenu(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isMe = message.senderId == _currentUserId;
                          return _MessageBubble(
                            message: message,
                            isMe: isMe,
                            formattedTime: _formatTime(message.createdAt),
                          );
                        },
                      ),
          ),

          // Input field
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.plusCircle),
                    color: AppColors.primary,
                    onPressed: () {
                      // TODO: Show attachment options
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Message...',
                        filled: true,
                        fillColor: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      maxLines: null,
                      onChanged: (_) => _onTyping(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: IconButton(
                      icon: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(LucideIcons.send, color: Colors.white),
                      onPressed: _isSending ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.heart,
              size: 48,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Nouveau match !',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Envoyez le premier message\npour briser la glace',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.user),
              title: const Text('Voir le profil'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to profile
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.bellOff),
              title: const Text('Couper les notifications'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(LucideIcons.flag, color: Colors.orange[700]),
              title: Text('Signaler', style: TextStyle(color: Colors.orange[700])),
              onTap: () {
                Navigator.pop(context);
                // Show report dialog
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.userX, color: Colors.red),
              title: const Text('Bloquer', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                // Show block confirmation
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.formattedTime,
  });

  final Message message;
  final bool isMe;
  final String formattedTime;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isMe
                  ? AppColors.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMe ? 20 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  message.content,
                  style: TextStyle(
                    color: isMe
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formattedTime,
                      style: TextStyle(
                        fontSize: 10,
                        color: isMe
                            ? Colors.white.withOpacity(0.7)
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.5),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message.isRead ? LucideIcons.checkCheck : LucideIcons.check,
                        size: 12,
                        color: message.isRead
                            ? Colors.white
                            : Colors.white.withOpacity(0.7),
                      ),
                    ],
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
