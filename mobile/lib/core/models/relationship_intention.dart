/// Ce que le membre cherche. Le cœur ne porte que l'identifiant et le nom de
/// l'icône ; le libellé et la description sont traduits par l'écran.
enum RelationshipIntention {
  marriage('marriage', 'ring'),
  serious('serious', 'heart'),
  open('open', 'sparkles'),
  friendsFirst('friends_first', 'users'),

  /// Choix « Je ne sais pas » de l'inscription ; absent du sélecteur du profil.
  undecided('undecided', 'heart');

  const RelationshipIntention(this.id, this.icon);

  /// La valeur enregistrée par le sélecteur du profil.
  final String id;
  final String icon;

  /// Les intentions que le sélecteur propose, dans l'ordre d'affichage.
  static const selectable = [marriage, serious, open, friendsFirst];

  /// Les choix de l'inscription, dans l'ordre d'affichage.
  static const setupChoices = [marriage, serious, undecided];

  static RelationshipIntention? fromId(String? id) {
    for (final intention in selectable) {
      if (intention.id == id) return intention;
    }
    return null;
  }
}
