/// Which quarter turn makes a camera frame upright for face detection.
///
/// The sensor orientation alone is right for a phone held upright in portrait.
/// The foldable iPhone, opened flat and turned sideways or beside another app,
/// hands frames a quarter turn away from that, and a face lying on its side is
/// not detected at all. So every turn is tried until one finds a face; that one
/// is kept, and searched again only after [missesBeforeSearch] frames in a row
/// without a face (the device was turned, or the member stepped away).
class RotationSearch {
  RotationSearch(this.sensorDegrees, {this.missesBeforeSearch = 15});

  /// The camera's sensor orientation, tried first.
  final int sensorDegrees;
  final int missesBeforeSearch;

  int? _found;
  int _misses = 0;

  /// The turn that found a face last, `null` while searching.
  int? get found => _found;

  /// The turns to try on the next frame, in order.
  List<int> candidates() {
    final kept = _found;
    if (kept != null) return [kept];
    final first = sensorDegrees % 360;
    return [for (var i = 0; i < 4; i++) (first + 90 * i) % 360];
  }

  /// Records the outcome of a frame: the turn that found a face, or `null`.
  void record(int? degrees) {
    if (degrees != null) {
      _found = degrees;
      _misses = 0;
      return;
    }
    if (_found == null) return;
    _misses++;
    if (_misses >= missesBeforeSearch) {
      _found = null;
      _misses = 0;
    }
  }
}
