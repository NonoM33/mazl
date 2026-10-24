/// Report categories
class ReportCategory {
  final String id;
  final String label;
  final String description;
  final String severity;

  const ReportCategory({
    required this.id,
    required this.label,
    required this.description,
    required this.severity,
  });

  static const List<ReportCategory> categories = [
    ReportCategory(
      id: 'fake_profile',
      label: 'Faux profil',
      description: 'Photos volées, identité fausse',
      severity: 'high',
    ),
    ReportCategory(
      id: 'inappropriate_photos',
      label: 'Photos inappropriées',
      description: 'Contenu sexuel, violent ou choquant',
      severity: 'high',
    ),
    ReportCategory(
      id: 'harassment',
      label: 'Harcèlement',
      description: 'Messages insistants, menaces, insultes',
      severity: 'critical',
    ),
    ReportCategory(
      id: 'spam',
      label: 'Spam / Arnaque',
      description: 'Publicité, demande d\'argent, liens suspects',
      severity: 'high',
    ),
    ReportCategory(
      id: 'underage',
      label: 'Mineur',
      description: 'La personne semble avoir moins de 18 ans',
      severity: 'critical',
    ),
    ReportCategory(
      id: 'offline_behavior',
      label: 'Comportement hors app',
      description: 'Comportement inapproprié lors d\'une rencontre',
      severity: 'medium',
    ),
    ReportCategory(
      id: 'other',
      label: 'Autre',
      description: 'Autre raison (précisez)',
      severity: 'low',
    ),
  ];
}
