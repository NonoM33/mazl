import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../chat_providers.dart';
import '../logic/chat_dates.dart';
import '../logic/chat_items.dart';
import '../state/chat_controller.dart';
import 'chat_scope.dart';
import 'date_separator.dart';
import 'list_states.dart';
import 'message_row.dart';
import 'new_messages_pill.dart';
import 'typing_indicator.dart';

/// The thread: a reversed list (newest at the bottom, anchored there), sticky
/// date label, « N nouveaux messages » pill, loading of older pages, and
/// scroll-to-quoted-message with a highlight.
class ChatMessageList extends ConsumerStatefulWidget {
  const ChatMessageList({
    super.key,
    required this.conversationId,
    required this.state,
    required this.otherName,
    required this.otherUserId,
    required this.onReply,
    this.otherPicture,
    this.isScamFlagged,
  });

  final int conversationId;
  final ChatState state;
  final String otherName;
  final int otherUserId;
  final String? otherPicture;
  final void Function(ChatMessage message) onReply;

  /// Set by the scam rules once they exist; nothing is flagged until then.
  final bool Function(ChatMessage message)? isScamFlagged;

  @override
  ConsumerState<ChatMessageList> createState() => _ChatMessageListState();
}

class _ChatMessageListState extends ConsumerState<ChatMessageList> {
  static const _bottomTolerance = 48.0;

  final _scroll = ScrollController();
  final _listKey = GlobalKey();
  final _rowKeys = <String, GlobalKey>{};
  final _appearing = <String>{};
  List<ChatItem> _items = const [];

  bool _atBottom = true;
  int _unseen = 0;
  String? _stickyLabel;
  int? _highlighted;
  int _olderRequestedFor = -1;
  int _markedUpTo = 0;
  String? _newestKey;
  Timer? _highlightTimer;

  ChatActions get _actions => ref.read(chatActionsProvider(widget.conversationId));

  @override
  void initState() {
    super.initState();
    _items = buildChatItems(widget.state);
    _newestKey = _lastMessageKey(widget.state);
    _scroll.addListener(_onScroll);
    SchedulerBinding.instance.addPostFrameCallback((_) => _afterLayout());
  }

  @override
  void didUpdateWidget(ChatMessageList old) {
    super.didUpdateWidget(old);
    final before = _newestKey;
    final messages = widget.state.messages;
    _items = buildChatItems(widget.state);
    _newestKey = _lastMessageKey(widget.state);

    if (before != null && _newestKey != before) {
      final from = messages.indexWhere((m) => messageKey(m) == before);
      final arrived = from < 0 ? const <ChatMessage>[] : messages.sublist(from + 1);
      final mineSent = arrived.any((m) => m.senderId == widget.state.myUserId);
      final fromOther = arrived.where((m) => m.senderId != widget.state.myUserId).length;
      for (final m in arrived) {
        _appearing.add(messageKey(m));
        Timer(const Duration(milliseconds: 400), () => _appearing.remove(messageKey(m)));
      }
      if (mineSent || _atBottom) {
        SchedulerBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      } else {
        _unseen += fromOther;
        _keepPlaceWhileGrowing();
      }
    }
    SchedulerBinding.instance.addPostFrameCallback((_) => _afterLayout());
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  String? _lastMessageKey(ChatState s) => s.messages.isEmpty ? null : messageKey(s.messages.last);

  GlobalKey _keyFor(ChatItem item) => _rowKeys.putIfAbsent(item.key, GlobalKey.new);

  void _onScroll() {
    final position = _scroll.position;
    final atBottom = position.pixels <= _bottomTolerance;
    if (atBottom != _atBottom || (atBottom && _unseen > 0)) {
      setState(() {
        _atBottom = atBottom;
        if (atBottom) _unseen = 0;
      });
      if (atBottom) _markRead();
    }
    if (position.pixels >= position.maxScrollExtent - 300) _loadOlder();
    _updateSticky();
  }

  void _afterLayout() {
    if (!mounted || !_scroll.hasClients) return;
    final position = _scroll.position;
    if (position.maxScrollExtent <= 0 || position.pixels >= position.maxScrollExtent - 300) _loadOlder();
    _markRead();
    _updateSticky();
  }

  void _loadOlder() {
    final s = widget.state;
    if (!s.hasMore || s.loadingOlder || s.messages.isEmpty || _olderRequestedFor == s.messages.length) return;
    _olderRequestedFor = s.messages.length;
    _actions.loadOlder();
  }

  void _markRead() {
    if (!_atBottom) return;
    for (final m in widget.state.messages.reversed) {
      if (m.senderId != widget.state.myUserId && !m.isLocal) {
        if (m.id > _markedUpTo) {
          _markedUpTo = m.id;
          _actions.markReadUpTo(m.id);
        }
        return;
      }
    }
  }

  void _scrollToBottom() {
    if (!_scroll.hasClients) return;
    final motion = !MediaQuery.disableAnimationsOf(context);
    if (motion) {
      _scroll.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOutCubic);
    } else {
      _scroll.jumpTo(0);
    }
  }

  /// A reversed list measures from the bottom: when a message lands there
  /// while the reader is higher up, shift the offset by its height.
  void _keepPlaceWhileGrowing() {
    if (!_scroll.hasClients) return;
    final before = _scroll.position.maxScrollExtent;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients || _atBottom) return;
      final grew = _scroll.position.maxScrollExtent - before;
      if (grew > 0) _scroll.jumpTo(_scroll.position.pixels + grew);
    });
  }

  /// The day shown at the top when its own label has scrolled off.
  void _updateSticky() {
    final box = _listKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached) return;
    final top = box.localToGlobal(Offset.zero).dy;
    var best = double.infinity;
    ChatItem? topmost;
    for (final item in _items) {
      final context = _rowKeys[item.key]?.currentContext;
      final render = context?.findRenderObject();
      if (render is! RenderBox || !render.attached || !render.hasSize) continue;
      final y = render.localToGlobal(Offset.zero).dy;
      if (y + render.size.height <= top || y >= best) continue;
      if (dayOfItem(item) == null) continue;
      best = y;
      topmost = item;
    }
    final label = topmost is MessageItem ? dayLabel(dayOfItem(topmost)!, DateTime.now()) : null;
    if (label != _stickyLabel) setState(() => _stickyLabel = label);
  }

  Future<void> _scrollToMessage(int id) async {
    final index = _items.indexWhere((i) => i is MessageItem && i.message.id == id);
    if (index < 0) return;
    for (var attempt = 0; attempt < 8 && mounted; attempt++) {
      final rowContext = _rowKeys[_items[index].key]?.currentContext;
      if (rowContext != null && rowContext.mounted) {
        await Scrollable.ensureVisible(rowContext, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic, alignment: 0.4);
        _highlight(id);
        return;
      }
      if (!_scroll.hasClients) return;
      final position = _scroll.position;
      final average = (position.maxScrollExtent + position.viewportDimension) / _items.length;
      final target = ((_items.length - 1 - index) * average - position.viewportDimension / 2).clamp(0.0, position.maxScrollExtent);
      _scroll.jumpTo(target);
      await SchedulerBinding.instance.endOfFrame;
    }
  }

  void _highlight(int id) {
    if (!mounted) return;
    setState(() => _highlighted = id);
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) setState(() => _highlighted = null);
    });
  }

  Widget _build(ChatItem item) {
    final child = switch (item) {
      LoadingOlderItem() => const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))),
        ),
      StartItem(:final day) => DateSeparator('Match · ${shortDate(day)}'),
      DateItem(:final day) => DateSeparator(dayLabel(day, DateTime.now())),
      TypingItem() => const Padding(
          padding: EdgeInsets.fromLTRB(16 + 36, 12, 16, 0),
          child: Align(alignment: Alignment.centerLeft, child: TypingIndicator()),
        ),
      MessageItem() => MessageRow(item: item, appear: _appearing.contains(item.key)),
    };
    return KeyedSubtree(key: _keyFor(item), child: child);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    if (s.messages.isEmpty) {
      if (s.loading) return const ListSkeleton();
      if (s.error != null) return ListError(message: s.error!, onRetry: _actions.load);
      return const EmptyConversation();
    }
    final items = _items;
    return ChatScope(
      conversationId: widget.conversationId,
      myUserId: s.myUserId,
      otherName: widget.otherName,
      otherUserId: widget.otherUserId,
      otherPicture: widget.otherPicture,
      onReply: widget.onReply,
      scrollToMessage: _scrollToMessage,
      isScamFlagged: widget.isScamFlagged ?? (_) => false,
      highlightedMessageId: _highlighted,
      child: Stack(
        children: [
          ListView.builder(
            key: _listKey,
            controller: _scroll,
            reverse: true,
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            itemCount: items.length,
            findChildIndexCallback: (key) {
              final index = items.indexWhere((i) => _rowKeys[i.key] == key);
              return index < 0 ? null : items.length - 1 - index;
            },
            itemBuilder: (context, index) => _build(items[items.length - 1 - index]),
          ),
          if (_stickyLabel != null) Positioned(top: 0, left: 0, right: 0, child: StickyDateLabel(_stickyLabel!)),
          Positioned(
            left: 0,
            right: 0,
            bottom: 4,
            child: Center(child: NewMessagesPill(count: _unseen, onTap: _scrollToBottom)),
          ),
        ],
      ),
    );
  }
}
