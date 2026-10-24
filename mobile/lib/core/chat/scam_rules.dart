// Anti-scam detector. CONTRACT: docs/chat/CONTRAT.md §4 "Arnaques".
//
// Pure and local: it reads a RECEIVED message and says whether it looks like
// the usual romance-scam openers. It warns, it never blocks, and nothing it
// reads leaves the phone. French and English, accent- and case-insensitive,
// whole words only ("telegramme" is not Telegram, "argentin" is not money).

/// Moving to another channel is only suspicious early in a conversation.
const scamEarlyMessageCount = 20;

enum ScamKind { money, giftCard, crypto, investment, offPlatform }

/// What was detected. Deliberately carries no part of the message text.
class ScamSignal {
  const ScamSignal(this.kind);

  final ScamKind kind;

  @override
  String toString() => 'ScamSignal($kind)';
}

/// [text] is a message received from the other person; [position] its
/// 0-based rank in the conversation (0 = first message ever).
ScamSignal? detectScam(String text, {required int position}) {
  final normalized = _normalize(text);
  if (normalized.isEmpty) return null;
  final early = position < scamEarlyMessageCount;
  for (final rule in _rules) {
    if (rule.earlyOnly && !early) continue;
    if (rule.pattern.hasMatch(normalized)) return ScamSignal(rule.kind);
  }
  return null;
}

class _Rule {
  _Rule(this.kind, String source, {this.earlyOnly = false}) : pattern = RegExp(source);

  final ScamKind kind;
  final RegExp pattern;
  final bool earlyOnly;
}

// A "word" is a run of [a-z0-9]; these guards give \b semantics on text that
// has already been lower-cased and stripped of accents.
const _s = r'(?<![a-z0-9])';
const _e = r'(?![a-z0-9])';
const _sep = r"[' ]?"; // l'argent, l argent, largent

final List<_Rule> _rules = [
  _Rule(ScamKind.giftCard, '$_s(?:cartes? cadeaux?|gift[ -]?cards?|itunes cards?|google play cards?)$_e'),
  _Rule(
    ScamKind.crypto,
    '$_s(?:crypto(?:monnaies?|currenc(?:y|ies))?s?|bitcoins?|btc|ethereum|usdt|binance|nfts?)$_e',
  ),
  _Rule(
    ScamKind.investment,
    '$_s(?:'
    "opportunites? d'? ?investissements?|investment opportunit(?:y|ies)|investment platform|"
    "plateformes? d'? ?investissements?|rendements? garantis?|gains? garantis?|guaranteed (?:returns?|profits?)|"
    'trading(?! card)|forex|revenus? passifs?|passive income|'
    'doubl(?:er|e|ez) (?:ton|votre|son) argent|double your money'
    ')$_e',
  ),
  _Rule(
    ScamKind.money,
    '$_s(?:'
    'virements?|iban|rib|western union|moneygram|mandat cash|bank transfer|wire transfer|money transfer|'
    "besoin d'? ?argent|(?:envoy|vir|pret|don|transf)\\w*(?:[- ]moi)?(?: de)? l$_sep" 'argent|'
    'need (?:some )?(?:money|cash)|(?:send|wire|transfer|lend|give)(?: me)? (?:some |the )?(?:money|cash)|'
    'lend me'
    ')$_e',
  ),
  _Rule(
    ScamKind.offPlatform,
    '$_s(?:whats ?app|watsap|telegram|viber|wechat)$_e',
    earlyOnly: true,
  ),
  _Rule(
    ScamKind.offPlatform,
    // "signal" is also a plain word: only when it names the app.
    '(?:$_s(?:sur|via|par|on|through|over|to|en|vers) (?:the |l\'?|app )?signal$_e)|'
    '(?:$_s(?:t\'?as|tu as|do you have|you have|have you got) signal$_e)|'
    '(?:${_s}signal (?:app|messenger)$_e)',
    earlyOnly: true,
  ),
  _Rule(
    ScamKind.offPlatform,
    // 9+ digits, optionally grouped: a phone number, not a date or a year.
    '(?<![0-9])(?:\\+|00)?[0-9](?:[ .\\-]?[0-9]){8,}(?![0-9])',
    earlyOnly: true,
  ),
  _Rule(
    ScamKind.offPlatform,
    '$_s(?:donne|passe|envoie|file|give|send|share)\\w*(?:-| )?(?:moi|me)? ?(?:ton|ta|votre|your) '
    '(?:numero|num|tel|telephone|phone|number)$_e',
    earlyOnly: true,
  ),
];

const _accents = {
  'à': 'a', 'â': 'a', 'ä': 'a', 'á': 'a', 'ã': 'a', 'å': 'a',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
  'î': 'i', 'ï': 'i', 'í': 'i', 'ì': 'i',
  'ô': 'o', 'ö': 'o', 'ó': 'o', 'ò': 'o', 'õ': 'o',
  'ù': 'u', 'û': 'u', 'ü': 'u', 'ú': 'u',
  'ç': 'c', 'ñ': 'n', 'ÿ': 'y', 'œ': 'oe', 'æ': 'ae',
  '’': "'", '‘': "'", '`': "'", '´': "'",
};

String _normalize(String text) {
  final buffer = StringBuffer();
  for (final rune in text.toLowerCase().runes) {
    final ch = String.fromCharCode(rune);
    buffer.write(_accents[ch] ?? ch);
  }
  return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}
