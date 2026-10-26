/// Photos de la démo : photos libres Unsplash (licence Unsplash), utilisées
/// seulement par le mode démo. Elles sont chargées depuis le réseau : aucun
/// fichier image n'est versionné ni embarqué dans les assets.
abstract final class DemoPhotos {
  static const _women = <String>[
    '1580489944761-15a19d654956',
    '1548382131-e0ebb1f0cdea',
    '1594756154841-ac5d160dbf46',
    '1594318223885-20dc4b889f9e',
    '1662850886700-4ec19bd30d11',
    '1592621385645-e41659e8aabe',
    '1607569708758-0270aa4651bd',
    '1611695434369-a8f5d76ceb7b',
    '1623717217554-72ca676de535',
    '1525186402429-b4ff38bedec6',
    '1581714161666-dade083654ae',
    '1619896382906-4f4681290afc',
    '1562337404-3044c84ac061',
  ];

  static const _men = <String>[
    '1507003211169-0a1dd7228f2d',
    '1528892952291-009c663ce843',
    '1600603406200-5b2a104684ac',
    '1583123810408-23e7b5d1af9f',
    '1583264277168-58ceba4b84e7',
  ];

  /// Rang de chaque profil dans la liste de son genre : un visage par profil.
  /// La seconde photo est prise 7 rangs plus loin (13 femmes) ou 2 rangs plus
  /// loin (5 hommes), donc jamais la photo principale d'un voisin de Découvrir.
  static const _womenRank = <int, int>{
    201: 0,
    202: 1,
    204: 2,
    206: 3,
    207: 4,
    208: 5,
    301: 6,
    302: 7,
    303: 8,
    304: 9,
    305: 10,
    211: 11,
    212: 12,
  };
  static const _menRank = <int, int>{203: 0, 205: 1};

  static String _url(String id, {required int w, required int h}) =>
      'https://images.unsplash.com/photo-$id?w=$w&h=$h&fit=crop&crop=faces&q=80';

  /// Photos d'un profil (principale d'abord) ; vide pour le compte démo.
  static List<String> of(int userId) {
    final woman = _womenRank[userId];
    if (woman != null) {
      // One photo: each stock photo shows a different person.
      return [_url(_women[woman], w: 800, h: 1000)];
    }
    final man = _menRank[userId];
    if (man != null) {
      return [_url(_men[man], w: 800, h: 1000)];
    }
    return const [];
  }

  /// Vignette (avatar des conversations, matchs, likes, couple) : le même
  /// visage que la photo principale.
  static String? avatar(int userId) {
    final woman = _womenRank[userId];
    if (woman != null) return _url(_women[woman], w: 200, h: 200);
    final man = _menRank[userId];
    if (man != null) return _url(_men[man], w: 200, h: 200);
    return null;
  }
}
