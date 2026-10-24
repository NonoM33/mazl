import 'package:intl/intl.dart';

/// Display helpers of the MRZ review screen. The document number is never
/// shown in full: the last characters are enough to recognise a misread.
String maskDocumentNumber(String number) {
  final visible = number.length >= 6 ? 3 : (number.length > 1 ? 1 : 0);
  final hidden = number.length - visible;
  final masked = '•' * hidden;
  return masked + number.substring(hidden);
}

/// The masked number as displayed: isolated left to right, so the visible
/// characters stay at its end in a right-to-left language too.
String reviewDocumentNumber(String number) => '\u2066${maskDocumentNumber(number)}\u2069';

/// A date of the document in the member's language (`12/08/1974` in French,
/// `8/12/1974` in US English). [locale] is the language code, `l10n.localeName`.
String formatReviewDate(DateTime date, String locale) => DateFormat.yMd(locale).format(date);
