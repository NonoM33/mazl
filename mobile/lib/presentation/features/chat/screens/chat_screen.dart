import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/services/api_service.dart' hide ProfilePhoto;
import '../../../../core/services/websocket_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../common/widgets/block_report_dialog.dart';
import '../../../common/widgets/mazl_components.dart';

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
  final ImagePicker _imagePicker = ImagePicker();

  List<Message> _messages = [];
  ConversationUser? _otherUser;
  bool _isLoading = true;
  bool _isSending = false;
  bool _isTyping = false;
  bool _hasMore = true;
  bool _isUploadingImage = false;
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

    // Send via WebSocket for real-time
    _wsService.sendMessage(_conversationId, content);

    // Also send via API for persistence
    final response = await _apiService.sendMessage(_conversationId, content);

    if (!mounted) return;

    setState(() => _isSending = false);

    if (response.success && response.data != null) {
      // Clear the field only after a confirmed successful send
      _messageController.clear();
      // Add to messages if not already there from WebSocket
      final exists = _messages.any((m) => m.id == response.data!.id);
      if (!exists) {
        setState(() {
          _messages.insert(0, response.data!);
        });
      }
    } else {
      // Keep the text so the user does not lose their message, and surface the error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.error ?? 'Erreur lors de l\'envoi du message'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _onTyping() {
    _wsService.sendTyping(_conversationId);
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.camera),
              title: const Text('Prendre une photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.image),
              title: const Text('Choisir depuis la galerie'),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );

      if (image == null || !mounted) return;

      setState(() => _isUploadingImage = true);

      // Upload image and send message
      final response = await _apiService.sendImageMessage(
        _conversationId,
        File(image.path),
      );

      if (!mounted) return;
      setState(() => _isUploadingImage = false);

      if (response.success && response.data != null) {
        // Add to messages if not already there from WebSocket
        final exists = _messages.any((m) => m.id == response.data!.id);
        if (!exists) {
          setState(() {
            _messages.insert(0, response.data!);
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.error ?? 'Erreur lors de l\'envoi de l\'image'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showImageFullscreen(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.black87),
            ),
            InteractiveViewer(
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(LucideIcons.x, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
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
  String _dayLabel(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return "Aujourd'hui";
    if (diff == 1) return 'Hier';
    return DateFormat.MMMd().format(dateTime);
  }

  bool _startsNewDay(int index) {
    // La liste est inversée : l'index suivant est le message plus ancien.
    if (index == _messages.length - 1) return !_hasMore;
    final current = _messages[index].createdAt;
    final older = _messages[index + 1].createdAt;
    return current.year != older.year ||
        current.month != older.month ||
        current.day != older.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _ChatHeader(
            user: _otherUser,
            isTyping: _isTyping,
            onBack: () => context.pop(),
            onOpenProfile: _otherUser != null ? _openOtherUserProfile : null,
            onVideoCall: () => context.go('/chat/${widget.conversationId}/video-call'),
            onOptions: () => _showOptionsMenu(context),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isMe = message.senderId == _currentUserId;
                          final bubble = ChatBubble(
                            message: message,
                            isMe: isMe,
                            formattedTime: _formatTime(message.createdAt),
                            onTapImage: _showImageFullscreen,
                          );
                          if (!_startsNewDay(index)) return bubble;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                child: Center(child: SectionLabel(_dayLabel(message.createdAt))),
                              ),
                              bubble,
                            ],
                          );
                        },
                      ),
          ),
          ChatComposer(
            controller: _messageController,
            onSend: (_) => _sendMessage(),
            onChanged: _onTyping,
            onAttach: _showAttachmentOptions,
            isSending: _isSending,
            isUploadingImage: _isUploadingImage,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Nouveau match'),
          const SizedBox(height: 12),
          const Text(
            'Dites bonjour.',
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.w700, letterSpacing: -2, height: 1.05),
          ),
          const SizedBox(height: 12),
          Text(
            'Envoyez le premier message pour briser la glace.',
            style: TextStyle(fontSize: 16, height: 1.45, color: muted),
          ),
        ],
      ),
    );
  }

  void _openOtherUserProfile() {
    final otherUser = _otherUser;
    if (otherUser == null) return;
    context.push(RoutePaths.matchProfilePath(otherUser.userId.toString()));
  }

  void _openBlockReportDialog() {
    final otherUser = _otherUser;
    if (otherUser == null) return;
    BlockReportDialog.show(
      context,
      userId: otherUser.userId,
      userName: otherUser.displayName ?? 'Cet utilisateur',
      onBlocked: () {
        // Leave the conversation once the user is blocked
        if (mounted) context.pop();
      },
    );
  }

  Future<void> _toggleMuteConversation() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'muted_conversation_$_conversationId';
    await prefs.setBool(key, true);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notifications coupées pour cette conversation'),
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
                _openOtherUserProfile();
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.bellOff),
              title: const Text('Couper les notifications'),
              onTap: () {
                Navigator.pop(context);
                _toggleMuteConversation();
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.flag),
              title: const Text('Signaler'),
              onTap: () {
                Navigator.pop(context);
                _openBlockReportDialog();
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.userX, color: AppColors.error),
              title: const Text('Bloquer', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                _openBlockReportDialog();
              },
            ),
          ],
        ),
      ),
    );
  }
}


/// En-tête de la conversation : retour, photo, nom et statut, appel vidéo, options.
class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.user,
    required this.isTyping,
    required this.onBack,
    required this.onOpenProfile,
    required this.onVideoCall,
    required this.onOptions,
  });

  final ConversationUser? user;
  final bool isTyping;
  final VoidCallback onBack;
  final VoidCallback? onOpenProfile;
  final VoidCallback onVideoCall;
  final VoidCallback onOptions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top, left: 4, right: 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(bottom: BorderSide(color: scheme.outline)),
      ),
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            IconButton(
              tooltip: 'Retour',
              constraints: const BoxConstraints.tightFor(width: 44, height: 44),
              icon: const Icon(LucideIcons.chevronLeft, size: 24),
              onPressed: onBack,
            ),
            Expanded(
              child: InkWell(
                onTap: onOpenProfile,
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  children: [
                    SizedBox.square(
                      dimension: 40,
                      child: ProfilePhoto(
                        url: user?.picture,
                        seed: user?.userId ?? 0,
                        radius: 20,
                        iconSize: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? 'Chargement…',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                          ),
                          Text(
                            isTyping ? 'écrit…' : 'En ligne',
                            style: TextStyle(
                              fontSize: 12,
                              color: isTyping ? scheme.primary : scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            RoundIconButton(
              icon: LucideIcons.video,
              tooltip: 'Appel vidéo',
              size: 44,
              onPressed: onVideoCall,
            ),
            IconButton(
              tooltip: 'Options',
              constraints: const BoxConstraints.tightFor(width: 44, height: 44),
              icon: const Icon(LucideIcons.ellipsis, size: 22),
              onPressed: onOptions,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bulle de message : tekhelet à droite pour moi, brume à gauche pour l'autre.
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.formattedTime,
    this.onTapImage,
  });

  /// Clé du conteneur coloré de la bulle.
  static const bubbleKey = ValueKey('chat-bubble');

  final Message message;
  final bool isMe;
  final String formattedTime;
  final void Function(String imageUrl)? onTapImage;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isImage = message.isImage;
    final background = isMe ? scheme.primary : scheme.surfaceContainer;
    final foreground = isMe ? scheme.onPrimary : scheme.onSurface;
    final metaColor = isMe ? scheme.onPrimary.withValues(alpha: 0.78) : scheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            key: bubbleKey,
            constraints: const BoxConstraints(maxWidth: 270),
            padding: isImage
                ? const EdgeInsets.all(4)
                : const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(22),
                topRight: const Radius.circular(22),
                bottomLeft: Radius.circular(isMe ? 22 : 6),
                bottomRight: Radius.circular(isMe ? 6 : 22),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isImage && message.imageUrl != null)
                  GestureDetector(
                    onTap: () => onTapImage?.call(message.imageUrl!),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: CachedNetworkImage(
                        imageUrl: message.imageUrl!,
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => SizedBox.square(
                          dimension: 200,
                          child: ColoredBox(
                            color: scheme.outline,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => SizedBox.square(
                          dimension: 200,
                          child: ColoredBox(
                            color: scheme.outline,
                            child: const Icon(LucideIcons.imageOff),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Text(
                    message.content,
                    style: TextStyle(
                      fontFamily: AppTypography.family,
                      fontSize: 15,
                      height: 1.4,
                      color: foreground,
                    ),
                  ),
                Padding(
                  padding: isImage
                      ? const EdgeInsets.fromLTRB(8, 4, 8, 4)
                      : const EdgeInsets.only(top: 3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formattedTime,
                        style: TextStyle(fontSize: 11, color: metaColor),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? LucideIcons.checkCheck : LucideIcons.check,
                          size: 13,
                          color: metaColor,
                          semanticLabel: message.isRead ? 'Lu' : 'Envoyé',
                        ),
                      ],
                    ],
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

/// Barre de saisie : une capsule brume flottante, jamais collée au bord.
class ChatComposer extends StatelessWidget {
  const ChatComposer({
    super.key,
    required this.controller,
    required this.onSend,
    this.onChanged,
    this.onAttach,
    this.isSending = false,
    this.isUploadingImage = false,
  });

  /// Clé de la capsule (60 de haut), pour mesurer son écart au bas de l'écran.
  static const capsuleKey = ValueKey('chat-composer-capsule');

  /// Écart minimal entre la capsule et la zone sûre / le clavier.
  static const bottomGap = 12.0;

  final TextEditingController controller;

  /// Reçoit le texte saisi, sans espaces autour ; jamais appelé s'il est vide.
  final ValueChanged<String> onSend;
  final VoidCallback? onChanged;
  final VoidCallback? onAttach;
  final bool isSending;
  final bool isUploadingImage;

  void _submit() {
    final text = controller.text.trim();
    if (text.isEmpty || isSending) return;
    onSend(text);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    const noBorder = InputBorder.none;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomGap + safeBottom),
      child: Container(
        key: capsuleKey,
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (isUploadingImage)
              const SizedBox.square(
                dimension: 44,
                child: Padding(
                  padding: EdgeInsets.all(13),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (onAttach != null)
              IconButton(
                tooltip: 'Joindre une photo',
                constraints: const BoxConstraints.tightFor(width: 44, height: 44),
                icon: const Icon(LucideIcons.plus, size: 22),
                onPressed: onAttach,
              ),
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 15, height: 1.4),
                decoration: const InputDecoration(
                  hintText: 'Message',
                  filled: false,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: noBorder,
                  enabledBorder: noBorder,
                  focusedBorder: noBorder,
                  disabledBorder: noBorder,
                ),
                onChanged: (_) => onChanged?.call(),
              ),
            ),
            const SizedBox(width: 6),
            Semantics(
              button: true,
              label: 'Envoyer',
              child: SizedBox.square(
                dimension: 48,
                child: Material(
                  color: scheme.primary,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: isSending ? null : _submit,
                    child: Center(
                      child: isSending
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(LucideIcons.arrowUp, size: 22, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
