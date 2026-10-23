/// ICAO 9303 part 3, 4.9: check digit over a field.
/// Weights 7-3-1 repeating, digits keep their value, A-Z are 10-35, `<` is 0.
/// Returns null when [field] holds a character outside that alphabet.
int? mrzCheckDigit(String field) {
  const weights = [7, 3, 1];
  var sum = 0;
  for (var i = 0; i < field.length; i++) {
    final value = _charValue(field.codeUnitAt(i));
    if (value == null) return null;
    sum += value * weights[i % 3];
  }
  return sum % 10;
}

int? _charValue(int unit) {
  if (unit >= 0x30 && unit <= 0x39) return unit - 0x30; // 0-9
  if (unit >= 0x41 && unit <= 0x5A) return unit - 0x41 + 10; // A-Z
  if (unit == 0x3C) return 0; // <
  return null;
}
