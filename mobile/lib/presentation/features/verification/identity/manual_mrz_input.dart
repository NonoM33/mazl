import 'package:flutter/services.dart';

import '../../../../core/verification/mrz/mrz_data.dart';

/// What the user typed when the camera cannot read the MRZ.
class ManualMrzInput {
  const ManualMrzInput({required this.documentNumber, required this.birthDate, required this.expiryDate});

  final String documentNumber;

  /// `JJ/MM/AAAA`, as typed.
  final String birthDate;
  final String expiryDate;
}

/// What is wrong with a field. The form says it in the member's language.
enum ManualMrzError {
  /// The document number does not have 5 to 12 letters or digits.
  documentNumberFormat,

  /// Not a real date, or one that cannot be on this field.
  invalidDate,
}

class ManualMrzErrors {
  const ManualMrzErrors({this.documentNumber, this.birthDate, this.expiryDate});

  final ManualMrzError? documentNumber;
  final ManualMrzError? birthDate;
  final ManualMrzError? expiryDate;

  bool get isEmpty => documentNumber == null && birthDate == null && expiryDate == null;
}

/// Validation of the manual entry. Returns the data, or the errors per field.
({MrzData? data, ManualMrzErrors errors}) validateManualMrz(ManualMrzInput input, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final number = input.documentNumber.toUpperCase().replaceAll(RegExp(r'\s'), '');
  final birth = parseFrenchDate(input.birthDate);
  final expiry = parseFrenchDate(input.expiryDate);

  final errors = ManualMrzErrors(
    documentNumber: RegExp(r'^[A-Z0-9]{5,12}$').hasMatch(number) ? null : ManualMrzError.documentNumberFormat,
    birthDate: birth != null && birth.year >= 1900 && birth.isBefore(today) ? null : ManualMrzError.invalidDate,
    expiryDate: expiry != null && expiry.year >= 2000 && expiry.year <= 2100 ? null : ManualMrzError.invalidDate,
  );
  if (!errors.isEmpty) return (data: null, errors: errors);
  return (data: MrzData.fromDates(documentNumber: number, birthDate: birth!, expiryDate: expiry!), errors: errors);
}

/// Parses `JJ/MM/AAAA` (slashes optional); null unless it is a real date.
DateTime? parseFrenchDate(String text) {
  final digits = text.replaceAll(RegExp(r'\D'), '');
  if (digits.length != 8) return null;
  final day = int.parse(digits.substring(0, 2));
  final month = int.parse(digits.substring(2, 4));
  final year = int.parse(digits.substring(4, 8));
  final date = DateTime(year, month, day);
  // DateTime rolls 31/02 over to March: a real date round-trips.
  return date.year == year && date.month == month && date.day == day ? date : null;
}

/// Types digits only and inserts the slashes: `12081974` shows `12/08/1974`.
class FrenchDateInputFormatter extends TextInputFormatter {
  const FrenchDateInputFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final capped = digits.length > 8 ? digits.substring(0, 8) : digits;
    final out = StringBuffer();
    for (var i = 0; i < capped.length; i++) {
      if (i == 2 || i == 4) out.write('/');
      out.write(capped[i]);
    }
    final text = out.toString();
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}
