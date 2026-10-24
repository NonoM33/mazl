/// Relationship intention
class RelationshipIntention {
  final String id;
  final String label;
  final String icon;
  final String description;

  const RelationshipIntention({
    required this.id,
    required this.label,
    required this.icon,
    required this.description,
  });

  static const List<RelationshipIntention> intentions = [
    RelationshipIntention(
      id: 'marriage',
      label: 'Mariage',
      icon: 'ring',
      description: 'Je cherche mon/ma futur(e) mari/femme',
    ),
    RelationshipIntention(
      id: 'serious',
      label: 'Relation sérieuse',
      icon: 'heart',
      description: 'Je cherche une relation durable',
    ),
    RelationshipIntention(
      id: 'open',
      label: 'Ouvert(e) à tout',
      icon: 'sparkles',
      description: 'On verra où ça nous mène',
    ),
    RelationshipIntention(
      id: 'friends_first',
      label: 'Amitié d\'abord',
      icon: 'users',
      description: 'Commençons par apprendre à se connaître',
    ),
  ];
}
