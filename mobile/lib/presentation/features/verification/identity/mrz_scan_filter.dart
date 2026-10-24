import '../../../../core/verification/mrz/mrz_data.dart';

/// Accepts an MRZ only after consecutive camera frames agree on it.
///
/// A frame without a valid MRZ (every check digit failing) breaks the streak:
/// two lucky misreads separated by garbage must not add up.
class MrzScanFilter {
  MrzScanFilter({this.framesRequired = 2}) : assert(framesRequired >= 1);

  final int framesRequired;

  MrzData? _candidate;
  int _streak = 0;

  /// [frame] is the parse result of one camera frame (null when none).
  /// Returns the confirmed data, or null while still waiting.
  MrzData? add(MrzData? frame) {
    if (frame == null) {
      reset();
      return null;
    }
    _streak = frame == _candidate ? _streak + 1 : 1;
    _candidate = frame;
    return _streak >= framesRequired ? frame : null;
  }

  void reset() {
    _candidate = null;
    _streak = 0;
  }
}
