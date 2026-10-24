import '../state/chat_controller.dart';

/// True when [failure], returned by a send action, means nobody can write
/// here any more (403: the pair is blocked; 404: the conversation is gone).
bool isBlockedFailure(ChatFailure? failure) => failure?.closesComposer ?? false;
