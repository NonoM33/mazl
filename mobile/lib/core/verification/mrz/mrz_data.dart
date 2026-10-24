/// Physical layout of a machine readable zone (ICAO 9303 parts 4 to 6).
enum MrzFormat {
  /// ID cards, 3 lines of 30 characters (French CNI since 2021).
  td1(lines: 3, width: 30),

  /// Older ID cards and residence permits, 2 lines of 36 characters.
  td2(lines: 2, width: 36),

  /// Passports, 2 lines of 44 characters.
  td3(lines: 2, width: 44);

  const MrzFormat({required this.lines, required this.width});

  final int lines;
  final int width;
}

/// What the chip access key is derived from. Lives in memory only.
///
/// Dates keep the exact `YYMMDD` form printed in the MRZ: the century is
/// not part of the key.
class MrzData {
  const MrzData({
    this.format,
    required this.documentNumber,
    required this.birthYymmdd,
    required this.expiryYymmdd,
  });

  /// Layout the data was read from; null when typed by hand.
  final MrzFormat? format;

  /// Document number without trailing `<` fillers (may exceed 9 characters).
  final String documentNumber;
  final String birthYymmdd;
  final String expiryYymmdd;

  /// Birth dates in the future are impossible: two-digit years above the
  /// current one belong to the previous century.
  DateTime birthDate({DateTime? now}) {
    final today = now ?? DateTime.now();
    final yy = int.parse(birthYymmdd.substring(0, 2));
    final century = yy > today.year % 100 ? (today.year ~/ 100 - 1) : today.year ~/ 100;
    return DateTime(century * 100 + yy, int.parse(birthYymmdd.substring(2, 4)), int.parse(birthYymmdd.substring(4, 6)));
  }

  /// Documents are valid for at most 15 years: expiry is always in the
  /// current century, or the next one.
  DateTime expiryDate() {
    final yy = int.parse(expiryYymmdd.substring(0, 2));
    return DateTime(2000 + yy, int.parse(expiryYymmdd.substring(2, 4)), int.parse(expiryYymmdd.substring(4, 6)));
  }

  /// Builds the key data from calendar dates (manual entry).
  factory MrzData.fromDates({
    required String documentNumber,
    required DateTime birthDate,
    required DateTime expiryDate,
  }) =>
      MrzData(
        documentNumber: documentNumber,
        birthYymmdd: yymmdd(birthDate),
        expiryYymmdd: yymmdd(expiryDate),
      );

  static String yymmdd(DateTime date) =>
      '${(date.year % 100).toString().padLeft(2, '0')}'
      '${date.month.toString().padLeft(2, '0')}'
      '${date.day.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is MrzData &&
      other.format == format &&
      other.documentNumber == documentNumber &&
      other.birthYymmdd == birthYymmdd &&
      other.expiryYymmdd == expiryYymmdd;

  @override
  int get hashCode => Object.hash(format, documentNumber, birthYymmdd, expiryYymmdd);

  /// Never prints the data: it identifies a person.
  @override
  String toString() => 'MrzData(${format?.name ?? 'manual'})';
}
