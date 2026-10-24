import 'package:flutter/gestures.dart';
import 'package:flutter/painting.dart';

/// A word of a sentence that is a link.
typedef SentenceLink = ({
  String label,
  TextStyle style,
  GestureRecognizer? recognizer,
});

/// Cuts the translated [sentence] into spans, styling each link where it
/// appears: the word order differs from one language to the next, so the
/// sentence is translated whole and the links are found inside it.
List<InlineSpan> spansWithLinks(String sentence, List<SentenceLink> links) {
  final found = <(int, SentenceLink)>[
    for (final link in links)
      if (sentence.contains(link.label)) (sentence.indexOf(link.label), link),
  ]..sort((a, b) => a.$1.compareTo(b.$1));
  final spans = <InlineSpan>[];
  var cursor = 0;
  for (final (start, link) in found) {
    if (start < cursor) continue;
    if (start > cursor) {
      spans.add(TextSpan(text: sentence.substring(cursor, start)));
    }
    spans.add(
      TextSpan(
        text: link.label,
        style: link.style,
        recognizer: link.recognizer,
      ),
    );
    cursor = start + link.label.length;
  }
  if (cursor < sentence.length) {
    spans.add(TextSpan(text: sentence.substring(cursor)));
  }
  return spans;
}
