/// Report categories. The core only knows the stable [id] sent to the API and
/// the [severity]; the words shown to the member live in the presentation
/// layer (`ReportCategoryText`).
class ReportCategory {
  final String id;
  final String severity;

  const ReportCategory({required this.id, required this.severity});

  static const List<ReportCategory> categories = [
    ReportCategory(id: 'fake_profile', severity: 'high'),
    ReportCategory(id: 'inappropriate_photos', severity: 'high'),
    ReportCategory(id: 'harassment', severity: 'critical'),
    ReportCategory(id: 'spam', severity: 'high'),
    ReportCategory(id: 'underage', severity: 'critical'),
    ReportCategory(id: 'offline_behavior', severity: 'medium'),
    ReportCategory(id: 'other', severity: 'low'),
  ];
}
