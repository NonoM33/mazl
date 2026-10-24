/// Ce que le serveur peut débiter : un Super Like ou un Boost.
enum CreditKind {
  superLike('super_like'),
  boost('boost');

  const CreditKind(this.wire);

  /// Le nom du type dans les réponses et les contrats du serveur.
  final String wire;
}

/// Le solde d'un type, tel que le serveur le décrit (`KindCredits`).
///
/// `available = daily_remaining + max(purchased_balance, 0)` : l'app affiche
/// ce que le serveur lui dit et n'accorde jamais rien d'elle-même.
class KindCredits {
  const KindCredits({
    required this.dailyAllowance,
    required this.dailyRemaining,
    required this.purchasedBalance,
    required this.available,
  });

  factory KindCredits.fromJson(Object? raw, String name) {
    if (raw is! Map<String, Object?>) {
      throw FormatException('credits.$name: objet attendu');
    }
    return KindCredits(
      dailyAllowance: _count(raw, name, 'daily_allowance'),
      dailyRemaining: _count(raw, name, 'daily_remaining'),
      purchasedBalance: _count(raw, name, 'purchased_balance'),
      available: _count(raw, name, 'available'),
    );
  }

  /// Inclus par jour pour ce statut (gratuit ou mazl+).
  final int dailyAllowance;

  /// Ce qu'il reste de l'inclus du jour.
  final int dailyRemaining;

  /// Crédits achetés ; peut être négatif après un remboursement.
  final int purchasedBalance;

  /// Ce qu'on peut dépenser maintenant.
  final int available;

  static int _count(Map<String, Object?> map, String kind, String key) {
    final value = map[key];
    if (value is int) return value;
    throw FormatException('credits.$kind.$key: entier attendu');
  }
}

/// Le `credits` renvoyé par `GET /api/credits`, un swipe, un boost ou une
/// vérification d'achat.
class CreditBalance {
  const CreditBalance({
    required this.superLike,
    required this.boost,
    required this.resetsAt,
  });

  /// Lève [FormatException] si la forme n'est pas celle du serveur : on ne
  /// devine jamais un solde.
  factory CreditBalance.fromJson(Object? raw) {
    if (raw is! Map<String, Object?>) {
      throw const FormatException('credits: objet attendu');
    }
    final resets = raw['resets_at'];
    if (resets is! String) {
      throw const FormatException('credits.resets_at: texte attendu');
    }
    return CreditBalance(
      superLike: KindCredits.fromJson(raw['super_like'], 'super_like'),
      boost: KindCredits.fromJson(raw['boost'], 'boost'),
      resetsAt: DateTime.parse(resets).toUtc(),
    );
  }

  /// Comme [CreditBalance.fromJson], mais rend null quand la forme est
  /// illisible.
  static CreditBalance? tryParse(Object? raw) {
    try {
      return CreditBalance.fromJson(raw);
    } on FormatException {
      return null;
    }
  }

  final KindCredits superLike;
  final KindCredits boost;

  /// Prochaine remise à zéro de l'inclus du jour (UTC).
  final DateTime resetsAt;

  KindCredits of(CreditKind kind) => switch (kind) {
    CreditKind.superLike => superLike,
    CreditKind.boost => boost,
  };
}
