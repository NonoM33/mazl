import 'package:flutter/widgets.dart';
import 'package:mazl/core/duo_tutorial/duo_scene_pose.dart';
import 'package:mazl/core/duo_tutorial/duo_scene_renderer.dart';

/// Un faux rendu : il note chaque pose reçue au lieu de dessiner de la 3D.
class FakeDuoSceneRenderer implements DuoSceneRenderer {
  final List<DuoScenePose> poses = [];
  bool disposed = false;

  @override
  Widget build(BuildContext context) =>
      const SizedBox.expand(key: ValueKey('fake-duo-scene'));

  @override
  void showPose(DuoScenePose pose) => poses.add(pose);

  @override
  void dispose() => disposed = true;
}
