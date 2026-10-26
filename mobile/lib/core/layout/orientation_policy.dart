import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'fold_state.dart';

/// The orientations the app accepts on a device.
///
/// An iPhone stays upright (decision of 2026-10-25). The foldable iPhone also
/// turns sideways: Apple asks for landscape so that it can stand on a table
/// like a tent (outer display facing the room), and its inner display ignores
/// the lock anyway. The Info.plist lists every orientation; this narrows it
/// at run time, as soon as the hinge is known.
List<DeviceOrientation> orientationsFor(FoldState fold) => fold.isFoldable
    ? const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]
    : const [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown];

/// Applies [orientationsFor] whenever the device turns out to be foldable (or
/// not). [apply] is `SystemChrome.setPreferredOrientations` in the app.
class OrientationPolicy extends StatefulWidget {
  const OrientationPolicy({
    super.key,
    required this.child,
    this.apply = SystemChrome.setPreferredOrientations,
  });

  final Widget child;
  final Future<void> Function(List<DeviceOrientation>) apply;

  @override
  State<OrientationPolicy> createState() => _OrientationPolicyState();
}

class _OrientationPolicyState extends State<OrientationPolicy> {
  bool? _foldable;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final fold = FoldScope.of(context);
    if (fold.isFoldable == _foldable) return;
    _foldable = fold.isFoldable;
    widget.apply(orientationsFor(fold));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
