import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/services/api_service.dart' hide ProfilePhoto;
import '../../../../core/services/data_prefetch_service.dart';
import '../../../../core/services/websocket_service.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/mazl_components.dart';
import '../../../widgets/skeletons.dart';
import '../conversation_lookup.dart';
import '../conversation_time.dart';
import '../l10n/chat_preview_text.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen>
    with AutomaticKeepAliveClientMixin {
  final DataPrefetchService _prefetchService = DataPrefetchService();
  final ApiService _apiService = ApiService();
  final WebSocketService _wsService = WebSocketService();
  final TextEditingController _searchController = TextEditingController();

  List<Conversation> _conversations = [];
  String _query = '';
  bool _isLoading = true;
  bool _hasError = false;
  StreamSubscription<ChatEvent>? _wsSubscription;
  ValueListenable<RouteInformation>? _routeInformation;
  String? _lastPath;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _connectWebSocket();
  }

  Future<void> _initializeData() async {
    // Try to use prefetched data first
    final cachedConversations = _prefetchService.conversations;
    if (cachedConversations != null && cachedConversations.isNotEmpty) {
      setState(() {
        _conversations = cachedConversations;
        _isLoading = false;
      });
    } else {
      // Load from API if no cached data
      await _loadConversations();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeInformation != null) return;
    final provider = GoRouter.of(context).routeInformationProvider;
    _routeInformation = provider;
    _lastPath = provider.value.uri.path;
    provider.addListener(_onRouteChanged);
  }

  void _onRouteChanged() {
    final path = _routeInformation!.value.uri.path;
    final becameVisible = conversationListBecameVisible(_lastPath, path);
    _lastPath = path;
    if (becameVisible && mounted) _loadConversations(isRefresh: true);
  }

  @override
  void dispose() {
    _routeInformation?.removeListener(_onRouteChanged);
    _wsSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _connectWebSocket() {
    _wsService.connect();
    _wsSubscription = _wsService.events.listen((event) {
      if (event is NewMessageEvent) {
        // Update conversation with new message
        setState(() {
          final index = _conversations.indexWhere(
            (c) => c.id == event.conversationId,
          );
          if (index != -1) {
            final conv = _conversations[index];
            _conversations[index] = Conversation(
              id: conv.id,
              matchId: conv.matchId,
              otherUser: conv.otherUser,
              lastMessage: event.content,
              lastMessageAt: event.createdAt,
              unreadCount: conv.unreadCount + 1,
            );
            // Move to top
            final updated = _conversations.removeAt(index);
            _conversations.insert(0, updated);
          }
        });
      } else if (event is NewMatchEvent) {
        // Reload conversations to show new match
        _loadConversations();
      }
    });
  }

  Future<void> _loadConversations({bool isRefresh = false}) async {
    if (!isRefresh && _conversations.isEmpty) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    final response = await _apiService.getConversations();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response.success && response.data != null) {
          _conversations = response.data!;
        } else if (_conversations.isEmpty) {
          _hasError = true;
        }
      });
    }
  }

  String _formatTime(DateTime? dateTime) => dateTime == null
      ? ''
      : formatConversationTime(context.l10n, dateTime.toLocal(), DateTime.now());

  void _open(Conversation conversation) {
    setState(() => _conversations = markConversationRead(_conversations, conversation.id));
    context.go('/chat/${conversation.id}');
  }

  /// Filtre local par nom : aucun appel réseau.
  List<Conversation> get _visibleConversations {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _conversations;
    return _conversations
        .where((c) => (c.otherUser?.displayName ?? '').toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.only(top: top + 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                context.l10n.chatListTitle,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -2,
                  height: 1.05,
                ),
              ),
            ),
            if (_conversations.isNotEmpty) ...[
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _SearchField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final scheme = Theme.of(context).colorScheme;
    if (_isLoading) {
      return const ChatListSkeleton();
    }

    if (_hasError) {
      return _CenteredMessage(
        title: context.l10n.chatListLoadErrorTitle,
        subtitle: context.l10n.chatListLoadErrorBody,
        action: FilledButton(
          onPressed: _loadConversations,
          child: Text(context.l10n.commonRetry),
        ),
      );
    }

    if (_conversations.isEmpty) {
      return _CenteredMessage(
        title: context.l10n.chatListEmptyTitle,
        subtitle: context.l10n.chatListEmptyBody,
        action: FilledButton(
          onPressed: () => context.go('/discover'),
          child: Text(context.l10n.chatListEmptyAction),
        ),
      );
    }

    final visible = _visibleConversations;
    // Le Scaffold parent est en extendBody : la capsule d'onglets est comptée
    // dans ce padding, la liste reste donc libre au-dessus d'elle.
    final bottom = MediaQuery.paddingOf(context).bottom;
    return RefreshIndicator(
      color: scheme.primary,
      onRefresh: () => _loadConversations(isRefresh: true),
      child: visible.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(24, 24, 24, bottom + 16),
              children: [
                Text(
                  context.l10n.chatListNoResults(_query.trim()),
                  style: TextStyle(fontSize: 15, color: scheme.onSurfaceVariant),
                ),
              ],
            )
          : ListView.builder(
              padding: EdgeInsets.only(bottom: bottom + 16),
              itemCount: visible.length,
              itemBuilder: (context, index) {
                final conversation = visible[index];
                return ConversationRow(
                  conversation: conversation,
                  formattedTime: _formatTime(conversation.lastMessageAt),
                  onTap: () => _open(conversation),
                );
              },
            ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  static final _noBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(24),
    borderSide: BorderSide.none,
  );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: context.l10n.chatListSearchHint,
          prefixIcon: Icon(LucideIcons.search, size: 18, color: scheme.onSurfaceVariant),
          contentPadding: EdgeInsets.zero,
          border: _noBorder,
          enabledBorder: _noBorder,
          focusedBorder: _noBorder,
        ),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.title, required this.subtitle, this.action});

  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, bottom + 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.6,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: TextStyle(fontSize: 16, height: 1.45, color: scheme.onSurfaceVariant),
          ),
          if (action != null) ...[
            const SizedBox(height: 28),
            action!,
          ],
        ],
      ),
    );
  }
}

/// Une conversation : photo, nom, heure, dernier message et pastille de non-lu.
class ConversationRow extends StatelessWidget {
  const ConversationRow({
    super.key,
    required this.conversation,
    required this.formattedTime,
    required this.onTap,
  });

  /// Clé de la pastille de non-lu, présente seulement si des messages attendent.
  static const unreadDotKey = ValueKey('conversation-unread-dot');

  /// Clé du texte du dernier message.
  static const previewKey = ValueKey('conversation-preview');

  final Conversation conversation;
  final String formattedTime;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasUnread = conversation.unreadCount > 0;
    final user = conversation.otherUser;
    final l10n = context.l10n;
    final name = user?.displayName ?? l10n.chatListUnknownMember;
    final lastMessage = conversation.lastMessage;
    final preview = lastMessage == null
        ? l10n.chatNewMatch
        : chatPreviewLabel(l10n, lastMessage);

    return Semantics(
      button: true,
      label: hasUnread ? l10n.chatListUnreadLabel(name) : name,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 56,
                child: ProfilePhoto(
                  url: user?.picture,
                  seed: conversation.id,
                  radius: 28,
                  iconSize: 24,
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formattedTime,
                          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      preview,
                      key: previewKey,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
                        color: hasUnread ? scheme.onSurface : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasUnread) ...[
                const SizedBox(width: 12),
                Container(
                  key: unreadDotKey,
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
