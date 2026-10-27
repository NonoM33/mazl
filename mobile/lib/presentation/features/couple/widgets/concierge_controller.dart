import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../../core/models/couple_daily.dart';
import '../../../../core/services/couple_api_service.dart';
import '../../../../core/services/couple_daily_api.dart';

/// How often the open conversation is read again while the screen is in
/// front, to see the answer of the team or of the other member.
const Duration kConciergePollEvery = Duration(seconds: 15);

/// Everything one concierge conversation holds: the request and its messages,
/// the idea ticked, the draft being typed, the scroll position.
///
/// It lives above the widgets that draw it, so that folding or unfolding the
/// device (which moves the conversation from one page to another) never loses
/// a draft, a ticked idea or a place in the thread.
class ConciergeController extends ChangeNotifier {
  ConciergeController({
    required this.api,
    this.pollEvery = kConciergePollEvery,
  });

  final CoupleDailyApi api;
  final Duration pollEvery;

  final TextEditingController text = TextEditingController();
  final FocusNode focus = FocusNode();
  final ScrollController scroll = ScrollController();

  /// A failed action, to say in the member's language. Set by the screen.
  void Function(CoupleFailure failure)? onFailure;

  /// The first message created a request (its id).
  void Function(int id)? onCreated;

  /// The request changed (a choice, a cancellation, a new reply): the list of
  /// requests is stale.
  VoidCallback? onChanged;

  int? _requestId;
  ConciergeThread? _thread;
  bool _loading = false;
  CoupleFailure? _failure;
  ConciergeMessage? _pending;
  bool _waiting = false;
  bool _acting = false;
  ConciergeKind? _kind;
  final Map<int, int> _picked = {};
  Timer? _timer;
  bool _disposed = false;
  int _sequence = 0;

  /// Bumped by everything that changes the thread, so that a slower read
  /// never overwrites a newer answer.
  int _version = 0;

  /// The request open, `null` while the next message creates one.
  int? get requestId => _requestId;
  ConciergeThread? get thread => _thread;
  bool get loading => _loading;
  CoupleFailure? get failure => _failure;

  /// A message is on its way (the assistant may be answering).
  bool get waiting => _waiting;

  /// A choice or a cancellation is on its way.
  bool get acting => _acting;
  ConciergeKind? get kind => _kind;

  /// The thread, then the message being sent (shown at once, before the
  /// server has answered).
  List<ConciergeMessage> get messages => [...?_thread?.messages, ?_pending];

  /// The idea ticked on the open request, `null` when none is (or when the
  /// request can no longer be chosen from).
  int? get picked {
    final id = _requestId;
    final request = _thread?.request;
    if (id == null || request == null || !request.canChoose) return null;
    final index = _picked[id];
    return index != null && index < request.options.length ? index : null;
  }

  bool get canSend => !_waiting && !_acting && text.text.trim().isNotEmpty;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  // ------------------------------------------------------------------ open

  /// Opens request [id] (`null`: a new request), reading its thread.
  Future<void> open(int? id) async {
    if (id == _requestId && (id == null || _thread != null)) return;
    _version++;
    _requestId = id;
    _thread = null;
    _failure = null;
    _pending = null;
    _loading = id != null;
    _notify();
    if (id != null) await _read(quiet: false);
  }

  /// Reads the open thread again (the retry of a failed load).
  Future<void> reload() => _read(quiet: false);

  Future<void> _read({required bool quiet}) async {
    final id = _requestId;
    if (id == null) return;
    final version = quiet ? _version : ++_version;
    if (!quiet) {
      _loading = true;
      _failure = null;
      _notify();
    }
    final result = await api.getConciergeThread(id);
    if (_disposed || version != _version || id != _requestId) return;
    _loading = false;
    switch (result) {
      case CoupleOk(:final value):
        final before = _thread;
        _thread = value;
        _failure = null;
        _notify();
        if (quiet && before != null && _differs(before, value)) {
          _scrollToEnd();
          onChanged?.call();
        }
      case CoupleFailed(:final failure):
        if (!quiet) _failure = failure;
        _notify();
    }
  }

  static bool _differs(ConciergeThread a, ConciergeThread b) =>
      a.messages.length != b.messages.length ||
      a.request.status != b.request.status ||
      a.request.chosenIndex != b.request.chosenIndex;

  /// Starts the periodic read of the open conversation.
  void start() {
    _timer ??= Timer.periodic(pollEvery, (_) => refreshQuietly());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// A read that changes nothing on failure and never interrupts a send.
  Future<void> refreshQuietly() async {
    if (_requestId == null || _waiting || _acting || _loading) return;
    await _read(quiet: true);
  }

  // ------------------------------------------------------------- composer

  /// A quick ask: the composer gets the start of a sentence and the focus,
  /// and the request that follows carries [kind].
  void prepare(ConciergeKind kind, String start) {
    _kind = kind;
    final value = '$start ';
    text.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    focus.requestFocus();
    _notify();
  }

  /// Sends what is in the field.
  Future<void> send() => _post(text.text, fromField: true);

  /// Asks the assistant for another idea with [message].
  Future<void> askOtherIdea(String message) => _post(message, fromField: false);

  Future<void> _post(String raw, {required bool fromField}) async {
    final body = raw.trim();
    if (body.isEmpty || _waiting || _acting) return;
    final id = _requestId;
    _version++;
    _pending = ConciergeMessage(
      id: -(++_sequence),
      role: ConciergeRole.member,
      text: body,
      createdAt: DateTime.now(),
      mine: true,
    );
    _waiting = true;
    if (fromField) text.clear();
    _notify();
    _scrollToEnd();

    final result = id == null
        ? await api.createConcierge(text: body, kind: _kind)
        : await api.sendConciergeMessage(id, body);
    if (_disposed) return;
    _waiting = false;
    _pending = null;
    switch (result) {
      case CoupleOk(:final value):
        _thread = value;
        _requestId = value.request.id;
        _failure = null;
        _version++;
        if (id == null) _kind = null;
        _notify();
        _scrollToEnd();
        if (id == null) onCreated?.call(value.request.id);
        onChanged?.call();
      case CoupleFailed(:final failure):
        if (fromField) {
          final typed = text.text;
          final restored = typed.isEmpty ? body : '$body\n$typed';
          text.value = TextEditingValue(
            text: restored,
            selection: TextSelection.collapsed(offset: restored.length),
          );
        }
        _notify();
        onFailure?.call(failure);
    }
  }

  // --------------------------------------------------------------- ideas

  /// Ticks idea [index] of the open request.
  void select(int index) {
    final id = _requestId;
    final request = _thread?.request;
    if (id == null || request == null || !request.canChoose || _acting) return;
    if (index < 0 || index >= request.options.length) return;
    _picked[id] = index;
    _notify();
  }

  /// Confirms the idea ticked: the team is told and books it.
  Future<void> choose() async {
    final id = _requestId;
    final index = picked;
    if (id == null || index == null || _acting || _waiting) return;
    await _act(id, () => api.chooseConciergeOption(id, index), clearPick: true);
  }

  /// Cancels the open request.
  Future<void> cancel() async {
    final id = _requestId;
    if (id == null || _acting || _waiting) return;
    await _act(id, () => api.cancelConcierge(id), clearPick: false);
  }

  Future<void> _act(
    int id,
    Future<CoupleResult<ConciergeThread>> Function() call, {
    required bool clearPick,
  }) async {
    _version++;
    _acting = true;
    _notify();
    final result = await call();
    if (_disposed) return;
    _acting = false;
    switch (result) {
      case CoupleOk(:final value):
        if (clearPick) _picked.remove(id);
        if (id == _requestId) _thread = value;
        _version++;
        _notify();
        _scrollToEnd();
        onChanged?.call();
      case CoupleFailed(:final failure):
        _notify();
        onFailure?.call(failure);
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed || !scroll.hasClients) return;
      scroll.jumpTo(scroll.position.maxScrollExtent);
    });
  }

  @override
  void dispose() {
    _disposed = true;
    stop();
    text.dispose();
    focus.dispose();
    scroll.dispose();
    super.dispose();
  }
}
