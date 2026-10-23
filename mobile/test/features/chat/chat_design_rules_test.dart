import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// docs/design/CHAT.md §1 and §14: no hard-coded colour, no gradient, no
// shadow, no emoji outside the reactions, in the files of the conversation.

final _files = [
  ...Directory('lib/presentation/features/chat/widgets').listSync().whereType<File>().where((f) => !f.path.endsWith('icebreakers_widget.dart')),
  ...Directory('lib/presentation/features/chat/logic').listSync().whereType<File>(),
  File('lib/presentation/features/chat/screens/chat_conversation_screen.dart'),
  File('lib/presentation/features/chat/screens/chat_screen.dart'),
  File('lib/presentation/features/chat/chat_providers.dart'),
].where((f) => f.path.endsWith('.dart')).toList();

String _code(File f) => f.readAsStringSync().split('\n').where((l) => !l.trimLeft().startsWith('//')).join('\n');

void main() {
  test('the rule covers the conversation files', () => expect(_files.length, greaterThan(25)));

  test('no Color(0x…) literal: colours come from the colour scheme', () {
    final offenders = [for (final f in _files) if (RegExp(r'Color\(\s*0x').hasMatch(_code(f))) f.path];
    expect(offenders, isEmpty);
  });

  test('only Colors.white, black and transparent are used', () {
    final other = RegExp(r'(?<![A-Za-z])Colors\.(?!white\b|black\b|transparent\b)\w+');
    final offenders = [for (final f in _files) if (other.hasMatch(_code(f))) f.path];
    expect(offenders, isEmpty);
  });

  test('no gradient, no shadow, no elevation', () {
    final banned = RegExp(r'Gradient\(|BoxShadow|boxShadow|elevation:|shadowColor|AppColors\.\w*[gG]radient');
    final offenders = [for (final f in _files) if (banned.hasMatch(_code(f))) f.path];
    expect(offenders, isEmpty);
  });

  test('no emoji in the sources: reactions come from allowedReactions', () {
    final emoji = RegExp(r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{2764}\u{FE0F}]', unicode: true);
    final offenders = [for (final f in _files) if (emoji.hasMatch(_code(f))) f.path];
    expect(offenders, isEmpty);
  });

  test('app colours used are the named, semantic ones', () {
    final used = <String>{};
    for (final f in _files) {
      for (final m in RegExp(r'AppColors\.(\w+)').allMatches(_code(f))) {
        used.add(m.group(1)!);
      }
    }
    expect(used.difference({'error', 'warning', 'hairline', 'dividerDark', 'photoTints', 'monoFamily'}), isEmpty);
  });
}
