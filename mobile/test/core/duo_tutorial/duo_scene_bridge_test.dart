import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/duo_tutorial/duo_scene_bridge.dart';
import 'package:mazl/core/duo_tutorial/duo_scene_pose.dart';
import 'package:mazl/core/duo_tutorial/duo_tutorial_step.dart';

import '../../helpers/duo_poses.dart';

DuoScenePose _pose(
  DuoPose pose, {
  DuoTutorialStep step = DuoTutorialStep.welcome,
}) => DuoScenePose.from(
  fold: pose.foldState,
  size: pose.size,
  step: step,
  validated: false,
  reduceMotion: false,
);

/// La conversation avec la page 3D, sans WebView : ce que Flutter lui envoie et
/// quand. Les noms (`window.mazlDuo.setPose`, canal `mazlDuoBridge`, « ready ») sont
/// vérifiés contre les fichiers de la page, pas contre le code de Dart.
void main() {
  late List<String> scripts;
  late DuoSceneScriptBridge bridge;

  setUp(() {
    scripts = [];
    bridge = DuoSceneScriptBridge((script) async => scripts.add(script));
  });

  test('avant « prête », rien ne part', () {
    bridge.showPose(_pose(DuoPose.closed));
    expect(scripts, isEmpty);
    expect(bridge.isReady, isFalse);
  });

  test('« prête » envoie la DERNIÈRE pose reçue, pas toutes', () {
    bridge.showPose(_pose(DuoPose.closed));
    bridge.showPose(_pose(DuoPose.halfOpenBook));
    bridge.onChannelMessage('ready');
    expect(scripts, hasLength(1));
    expect(scripts.single, contains('"hinge":"partiallyOpen"'));
  });

  test('« prête » sans pose en attente n\'envoie rien', () {
    bridge.onChannelMessage('ready');
    expect(scripts, isEmpty);
  });

  test('une fois prête, chaque pose part tout de suite', () {
    bridge.onChannelMessage('ready');
    bridge.showPose(_pose(DuoPose.closed));
    bridge.showPose(_pose(DuoPose.openLandscape));
    expect(scripts, hasLength(2));
  });

  test('un autre message du canal ne rend pas la page prête', () {
    bridge.onChannelMessage('hello');
    expect(bridge.isReady, isFalse);
  });

  test('le script appelle window.mazlDuo.setPose avec un JSON valide', () {
    final script = DuoSceneScriptBridge.scriptFor(
      _pose(DuoPose.halfOpenLaptop, step: DuoTutorialStep.table),
    );
    const prefix = 'window.mazlDuo&&window.mazlDuo.setPose(';
    expect(script, startsWith(prefix));
    expect(script, endsWith(');'));
    final json =
        jsonDecode(script.substring(prefix.length, script.length - 2))
            as Map<String, dynamic>;
    expect(json['hinge'], 'partiallyOpen');
    expect(json['axis'], 'horizontal');
    expect(json['step'], 'table');
    expect(json['angle'], 1.9);
  });

  test('une page qui plante ne fait pas planter le tutoriel', () async {
    final failing = DuoSceneScriptBridge((_) async => throw StateError('js'));
    failing.onChannelMessage('ready');
    failing.showPose(_pose(DuoPose.closed));
    await Future<void>.delayed(Duration.zero);
  });

  group('le contrat avec les fichiers de la page', () {
    final js = File('assets/duo_tutorial/tutorial.js').readAsStringSync();
    final html = File('assets/duo_tutorial/index.html').readAsStringSync();
    final math = File('assets/duo_tutorial/pose_math.js').readAsStringSync();

    test(
      'la page définit setPose et répond « ready » sur le canal de Dart',
      () {
        expect(js, contains('window.mazlDuo = {'));
        expect(js, contains('setPose(raw)'));
        expect(js, contains('window.$duoSceneChannelName'));
        expect(js, contains("postMessage('$duoSceneReadyMessage')"));
      },
    );

    test('la page connaît les six étapes dans l\'ordre de Dart', () {
      final steps = RegExp(
        r"const STEPS = \[(.*?)\];",
      ).firstMatch(math)!.group(1)!;
      expect(
        RegExp(r"'(\w+)'").allMatches(steps).map((m) => m.group(1)).toList(),
        [for (final step in DuoTutorialStep.values) step.name],
      );
    });

    test('la page lit les champs que Dart envoie', () {
      for (final key in _pose(DuoPose.closed).toMessage().keys) {
        if (key == 'stepIndex') continue;
        expect(math, contains('m.$key'), reason: 'pose_math.js lit $key');
      }
    });

    test('tout est embarqué : scripts locaux, aucune adresse sur Internet', () {
      for (final script in ['three.min.js', 'pose_math.js', 'tutorial.js']) {
        expect(html, contains('src="$script"'));
        expect(File('assets/duo_tutorial/$script').existsSync(), isTrue);
      }
      for (final file in [html, js, math]) {
        expect(RegExp(r'https?://').hasMatch(file), isFalse);
      }
      expect(html, isNot(contains('type="module"')));
      expect(
        File('assets/duo_tutorial/LICENSE-three.txt').readAsStringSync(),
        contains('MIT'),
      );
    });

    test('la page ne dessine jamais le pli : ni fil, ni couture, ni jour', () {
      expect(js.toLowerCase(), isNot(contains('seam')));
      expect(js, contains('const GAP = 0;'));
    });

    test('le dossier est déclaré dans pubspec.yaml', () {
      expect(
        File('pubspec.yaml').readAsStringSync(),
        contains('- assets/duo_tutorial/'),
      );
    });
  });
}
