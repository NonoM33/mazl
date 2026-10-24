/// Display helpers of the MRZ review screen. The document number is never
/// shown in full: the last characters are enough to recognise a misread.
String maskDocumentNumber(String number) {
  final visible = number.length >= 6 ? 3 : (number.length > 1 ? 1 : 0);
  final hidden = number.length - visible;
  return '${'•' * hidden}${number.substring(hidden)}';
}

String formatReviewDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
