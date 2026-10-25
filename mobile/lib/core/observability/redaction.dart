/// Retire d'un texte ce qui identifie un membre ou ouvre sa session : adresses
/// e-mail et jetons. Appliqué à tout ce qui quitte le téléphone dans un
/// rapport de plantage, et à ce qu'on écrit dans le journal.
String redactSensitive(String text) {
  var out = text;
  for (final rule in _rules) {
    out = out.replaceAllMapped(rule.pattern, rule.replace);
  }
  return out;
}

String? redactSensitiveOrNull(String? text) =>
    text == null ? null : redactSensitive(text);

class _Rule {
  const _Rule(this.pattern, this.replace);

  final RegExp pattern;
  final String Function(Match match) replace;
}

final List<_Rule> _rules = <_Rule>[
  _Rule(
    RegExp(r'[A-Za-z0-9._%+\-]+@[A-Za-z0-9\-]+(?:\.[A-Za-z0-9\-]+)+'),
    (_) => '[e-mail]',
  ),
  _Rule(
    RegExp(r'eyJ[A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]*'),
    (_) => '[token]',
  ),
  _Rule(
    RegExp(r'(Bearer\s+)[^\s"\x27,;]+', caseSensitive: false),
    (m) => '${m[1]}[token]',
  ),
  _Rule(
    RegExp(
      r'''((?:access_|id_|refresh_)?token|secret|password|passwd|authorization|api[_\-]?key|jwt)(["']?\s*[:=]\s*["']?)[^\s"',;&}]+''',
      caseSensitive: false,
    ),
    (m) => '${m[1]}${m[2]}[redacted]',
  ),
  _Rule(RegExp(r'[A-Za-z0-9_\-]{40,}'), (_) => '[token]'),
];
