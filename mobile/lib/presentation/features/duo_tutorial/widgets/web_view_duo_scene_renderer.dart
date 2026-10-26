import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/duo_tutorial/duo_scene_bridge.dart';
import '../../../../core/duo_tutorial/duo_scene_pose.dart';
import '../../../../core/duo_tutorial/duo_scene_renderer.dart';

/// La scène 3D de l'app : une page locale (`assets/duo_tutorial/index.html`)
/// qui dessine l'iPhone Duo avec three.js, embarqué lui aussi. Rien n'est
/// chargé depuis Internet : toute navigation hors des fichiers de l'app est
/// refusée.
///
/// La vue est un décor : ni touche ni VoiceOver ne la voient (les titres et
/// les boutons sont des widgets Flutter autour d'elle).
class WebViewDuoSceneRenderer implements DuoSceneRenderer {
  WebViewDuoSceneRenderer() {
    _bridge = DuoSceneScriptBridge(_run);
    _controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(onNavigationRequest: _allowLocalOnly),
      )
      ..addJavaScriptChannel(
        duoSceneChannelName,
        onMessageReceived: (message) =>
            _bridge.onChannelMessage(message.message),
      );
    unawaited(_controller.loadFlutterAsset(_page));
  }

  static const _page = 'assets/duo_tutorial/index.html';

  final WebViewController _controller = WebViewController();
  late final DuoSceneScriptBridge _bridge;

  Future<void> _run(String script) => _controller.runJavaScript(script);

  NavigationDecision _allowLocalOnly(NavigationRequest request) =>
      request.url.startsWith('file:') || request.url == 'about:blank'
      ? NavigationDecision.navigate
      : NavigationDecision.prevent;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: IgnorePointer(child: WebViewWidget(controller: _controller)),
  );

  @override
  void showPose(DuoScenePose pose) => _bridge.showPose(pose);

  @override
  void dispose() {}
}
