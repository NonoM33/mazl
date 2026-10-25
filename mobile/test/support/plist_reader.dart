/// Lecteur minimal de property list XML (`dict`, `array`, `string`, `true`,
/// `false`, `integer`), pour lire `Info.plist` et `PrivacyInfo.xcprivacy` dans
/// les tests sans dépendre d'un outil macOS.
Object? parsePlist(String xml) {
  final body = RegExp(
    r'<plist[^>]*>(.*)</plist>',
    dotAll: true,
  ).firstMatch(xml)?.group(1);
  if (body == null) throw const FormatException('pas de <plist>');
  final tokens = RegExp(
    r'<(/?)(\w+)\s*(/?)>|([^<]+)',
  ).allMatches(body).toList();
  final reader = _Reader(tokens);
  final value = reader.value();
  return value;
}

class _Reader {
  _Reader(this.tokens);

  final List<RegExpMatch> tokens;
  int position = 0;

  RegExpMatch _next() => tokens[position++];

  Object? value() {
    while (tokens[position].group(4)?.trim().isEmpty ?? false) {
      position++;
    }
    final token = _next();
    final name = token.group(2)!;
    final selfClosing = token.group(3) == '/';
    switch (name) {
      case 'true':
        return true;
      case 'false':
        return false;
      case 'dict':
        return selfClosing ? <String, Object?>{} : _dict();
      case 'array':
        return selfClosing ? <Object?>[] : _array();
      case 'string':
        return selfClosing ? '' : _text();
      case 'integer':
        return int.parse(_text());
      default:
        throw FormatException('balise inconnue <$name>');
    }
  }

  String _text() {
    final buffer = StringBuffer();
    while (true) {
      final token = _next();
      if (token.group(4) != null) {
        buffer.write(token.group(4));
      } else {
        return _unescape(buffer.toString());
      }
    }
  }

  Map<String, Object?> _dict() {
    final result = <String, Object?>{};
    while (true) {
      final token = tokens[position];
      if (token.group(4) != null) {
        position++;
        continue;
      }
      if (token.group(1) == '/') {
        position++;
        return result;
      }
      position++; // <key>
      final key = _text();
      result[key] = value();
    }
  }

  List<Object?> _array() {
    final result = <Object?>[];
    while (true) {
      final token = tokens[position];
      if (token.group(4) != null) {
        position++;
        continue;
      }
      if (token.group(1) == '/') {
        position++;
        return result;
      }
      result.add(value());
    }
  }
}

String _unescape(String text) => text
    .replaceAll('&apos;', "'")
    .replaceAll('&quot;', '"')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&amp;', '&');
