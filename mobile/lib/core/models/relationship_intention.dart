/// Ce que le membre cherche. Le cœur ne porte que l'identifiant et le nom de
/// l'icône ; le libellé et la description sont traduits par l'écran.
enum RelationshipIntention {
  marriage('marriage', 'ring'),
  serious('serious', 'heart'),
  open('open', 'sparkles'),
  friendsFirst('friends_first', 'users'),

  /// Choix « Je ne sais pas » de l'inscription ; absent du sélecteur du profil.
  /// Le serveur n'a pas de valeur pour lui : l'app n'envoie alors rien.
  undecided('undecided', 'heart');

  const RelationshipIntention(this.id, this.icon);

  /// L'identifiant de l'app. Pour les quatre vraies intentions, c'est aussi
  /// la valeur que le serveur enregistre (`relationshipIntention` de
  /// `PUT /api/profile`).
  final String id;
  final String icon;

  /// Ce qu'on envoie au serveur, ou `null` quand il n'y a rien à envoyer
  /// (« Je ne sais pas »).
  String? get apiValue => this == undecided ? null : id;

  /// Les intentions que le sélecteur propose, dans l'ordre d'affichage.
  static const selectable = [marriage, serious, open, friendsFirst];

  /// Les choix de l'inscription, dans l'ordre d'affichage.
  static const setupChoices = [marriage, serious, undecided];

  /// Les mots français que l'inscription a écrits avant la v1 : des profils
  /// les portent encore.
  static const _legacyWords = {
    'mariage': marriage,
    'relation_serieuse': serious,
    'je_ne_sais_pas': undecided,
  };

  /// L'intention d'une valeur enregistrée : celle du serveur, ou un ancien
  /// mot français. `null` pour une valeur vide ou inconnue.
  static RelationshipIntention? fromStored(String? stored) {
    final value = stored?.trim().toLowerCase();
    if (value == null || value.isEmpty) return null;
    for (final intention in values) {
      if (intention.id == value) return intention;
    }
    final word = value
        .replaceAll('é', 'e')
        .replaceAll(RegExp(r'[\s\-]+'), '_');
    return _legacyWords[word];
  }

  /// Comme [fromStored], mais seulement parmi les intentions du sélecteur.
  static RelationshipIntention? fromId(String? id) {
    final intention = fromStored(id);
    return selectable.contains(intention) ? intention : null;
  }
}
