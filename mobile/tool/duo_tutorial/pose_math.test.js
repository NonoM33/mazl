// Les calculs de pose de la scène du tutoriel iPhone Duo.
//   cd mobile && bun test tool/duo_tutorial
// Chaque attendu vient de la géométrie (un angle de charnière en radians, une
// demi-vie), pas d'une relecture du code testé.
const { describe, expect, test } = require('bun:test');
const M = require('../../assets/duo_tutorial/pose_math.js');

describe('approach (interpolation vers l\'angle réel)', () => {
  test('ne bouge pas sans temps écoulé', () => {
    expect(M.approach(1, 3, 0, 0.1)).toBe(1);
  });

  test('résorbe la moitié de l\'écart en une demi-vie', () => {
    expect(M.approach(0, 2, 0.1, 0.1)).toBeCloseTo(1, 6);
  });

  test('donne le même résultat en une grande image ou en deux petites', () => {
    const once = M.approach(0, 4, 0.1, 0.1);
    const twice = M.approach(M.approach(0, 4, 0.05, 0.1), 4, 0.05, 0.1);
    expect(twice).toBeCloseTo(once, 9);
  });

  test('atteint la cible et s\'y arrête, sans la dépasser', () => {
    let v = 0;
    for (let i = 0; i < 600; i++) {
      v = M.approach(v, 2, 1 / 60, 0.1);
      expect(v).toBeLessThanOrEqual(2);
    }
    expect(v).toBe(2);
  });

  test('une demi-vie nulle saute à la cible (animations réduites)', () => {
    expect(M.approach(0, 2.5, 0.016, 0)).toBe(2.5);
  });

  test('une pause de l\'application (grosse image) n\'envoie pas la scène ailleurs', () => {
    expect(M.approach(0, 2, 30, 0.1)).toBeLessThanOrEqual(2);
    expect(M.approach(0, 2, -5, 0.1)).toBe(0);
  });
});

describe('normalizePose (le message de Dart n\'est pas cru sur parole)', () => {
  test('prend l\'angle donné', () => {
    expect(M.normalizePose({ hinge: 'partiallyOpen', angle: 1.9 }).angle).toBe(1.9);
  });

  test('sans angle, déduit celui de la charnière', () => {
    expect(M.normalizePose({ hinge: 'closed' }).angle).toBe(0);
    expect(M.normalizePose({ hinge: 'fullyOpen', angle: null }).angle).toBeCloseTo(Math.PI, 9);
    expect(M.normalizePose({ hinge: 'partiallyOpen' }).angle).toBe(1.9);
  });

  test('refuse un angle absurde', () => {
    expect(M.normalizePose({ hinge: 'closed', angle: NaN }).angle).toBe(0);
    expect(M.normalizePose({ hinge: 'closed', angle: 'ouvert' }).angle).toBe(0);
    expect(M.normalizePose({ hinge: 'fullyOpen', angle: 99 }).angle).toBeCloseTo(Math.PI, 9);
    expect(M.normalizePose({ hinge: 'fullyOpen', angle: -1 }).angle).toBe(0);
  });

  test('une charnière ou une étape inconnue prend la valeur sobre', () => {
    const p = M.normalizePose({ hinge: 'cassée', step: 'inconnue', axis: 'oblique' });
    expect(p.hinge).toBe('unknown');
    expect(p.step).toBe('welcome');
    expect(p.axis).toBe('vertical');
    expect(p.verticalBar).toBeNull();
  });

  test('un message vide ou absurde ne plante pas', () => {
    expect(M.normalizePose(null).hinge).toBe('unknown');
    expect(M.normalizePose('x').step).toBe('welcome');
    expect(M.normalizePose(undefined).validated).toBe(false);
  });
});

describe('foldAngles (la géométrie du pli)', () => {
  test('à plat, les plaques sont alignées et l\'appareil de face', () => {
    const a = M.foldAngles(Math.PI);
    expect(a.vHalf).toBeCloseTo(0, 9);
    expect(a.yaw).toBe(0);
    expect(a.pitch).toBeCloseTo(0, 9);
  });

  test('fermé, chaque plaque s\'est repliée d\'un quart de tour et l\'appareil présente sa face extérieure', () => {
    const a = M.foldAngles(0);
    expect(a.vHalf).toBeCloseTo(Math.PI / 2, 9);
    expect(a.yaw).toBeCloseTo(Math.PI / 2, 9);
  });

  test('en livre à 109 degrés, l\'appareil ne se tourne pas : on voit les deux écrans', () => {
    expect(M.foldAngles(1.9).yaw).toBe(0);
  });

  test('en portable à 109 degrés, la plaque du bas est couchée sur la table et celle du haut penche vers l\'arrière', () => {
    const a = M.foldAngles(1.9);
    expect(a.pitch).toBeCloseTo(Math.PI / 2, 9);
    // 180 - 109 - 90 degrés : la plaque du haut penche d'environ 19 degrés vers l'arrière.
    expect(a.topTilt).toBeCloseTo(Math.PI - 1.9 - Math.PI / 2, 9);
    expect(a.topTilt).toBeLessThan(0);
  });

  test('l\'angle entre les deux plaques est toujours celui de la charnière', () => {
    // Direction de la plaque du bas (depuis la charnière) et de celle du haut,
    // dans le plan vertical : bas = (-cos b, sin b), haut = (cos a, sin a) avec a = topTilt.
    for (const theta of [0.3, 1, 1.9, 2.5, 3]) {
      const { pitch: b, topTilt: a } = M.foldAngles(theta);
      const dot = -Math.cos(b) * Math.cos(a) + Math.sin(b) * Math.sin(a);
      expect(Math.acos(Math.max(-1, Math.min(1, dot)))).toBeCloseTo(theta, 6);
    }
  });

  test('un angle hors bornes est ramené dans [0, pi]', () => {
    expect(M.foldAngles(-2).vHalf).toBeCloseTo(Math.PI / 2, 9);
    expect(M.foldAngles(9).vHalf).toBeCloseTo(0, 9);
  });
});

describe('targetFor', () => {
  test('fermé et en tente (valeur mesurée) : un V inversé, pas un téléphone fermé', () => {
    const t = M.targetFor(M.normalizePose({ hinge: 'closed', angle: 0, sideways: true }));
    expect(t).toEqual({ theta: M.TENT_ANGLE, axisT: 0, tentT: 1 });
  });

  test('entrouvert en tente (écran extérieur actif) : même V', () => {
    const t = M.targetFor(M.normalizePose({ hinge: 'partiallyOpen', angle: 1.15, sideways: true }));
    expect(t.tentT).toBe(1);
    expect(t.theta).toBe(1.15);
  });

  test('un angle système absurde pour une tente retombe sur l\'angle typique', () => {
    const t = M.targetFor(M.normalizePose({ hinge: 'partiallyOpen', angle: 2.4, sideways: true }));
    expect(t.theta).toBe(M.TENT_ANGLE);
  });

  test('fermé et debout : pas de rotation', () => {
    expect(M.targetFor(M.normalizePose({ hinge: 'closed' })).tentT).toBe(0);
  });

  test('ouvert en portrait : charnière horizontale', () => {
    const t = M.targetFor(M.normalizePose({ hinge: 'fullyOpen', axis: 'horizontal' }));
    expect(t.axisT).toBe(1);
    expect(t.tentT).toBe(0);
  });

  test('de côté mais ouvert : pas de tente', () => {
    expect(M.targetFor(M.normalizePose({ hinge: 'fullyOpen', sideways: true })).tentT).toBe(0);
  });
});

describe('gestureAt (le geste rejoué par le contour)', () => {
  test('les étapes sans geste n\'ont pas de contour', () => {
    expect(M.gestureAt('welcome', 1, false)).toBeNull();
    expect(M.gestureAt('ready', 1, false)).toBeNull();
  });

  test('« Ouvrez-le » part de fermé et arrive à plat', () => {
    const start = M.gestureAt('open', 0.3, false);
    const end = M.gestureAt('open', 2.6, false);
    expect(start.theta).toBeCloseTo(0, 9);
    expect(end.theta).toBeCloseTo(Math.PI, 9);
  });

  test('« Pliez-le comme un livre » finit à 109 degrés, charnière verticale', () => {
    const end = M.gestureAt('book', 2.6, false);
    expect(end.theta).toBeCloseTo(1.9, 9);
    expect(end.axisT).toBe(0);
  });

  test('« Posez-le sur la table » finit à 109 degrés, charnière horizontale', () => {
    const end = M.gestureAt('table', 2.6, false);
    expect(end.theta).toBeCloseTo(1.9, 9);
    expect(end.axisT).toBe(1);
  });

  test('« Debout, comme une tente » part de l\'appareil fermé à plat et finit en V', () => {
    const start = M.gestureAt('tent', 0.3, false);
    const end = M.gestureAt('tent', 2.6, false);
    expect(start.theta).toBeCloseTo(0, 9);
    expect(end.theta).toBeCloseTo(M.TENT_ANGLE, 9);
    expect(end.tentT).toBe(1);
  });

  test('le mouvement est monotone entre le départ et l\'arrivée', () => {
    let last = -1;
    for (let t = 0.6; t <= 2.3; t += 0.05) {
      const u = M.gestureAt('open', t, false).u;
      expect(u).toBeGreaterThanOrEqual(last);
      last = u;
    }
  });

  test('le contour apparaît et disparaît en douceur, jamais d\'un coup', () => {
    expect(M.gestureAt('open', 0, false).alpha).toBe(0);
    expect(M.gestureAt('open', 1.5, false).alpha).toBe(1);
    expect(M.gestureAt('open', 3.59, false).alpha).toBeLessThan(0.05);
  });

  test('animations réduites : le contour est fixe, sur la pose à atteindre', () => {
    const a = M.gestureAt('book', 0.1, true);
    const b = M.gestureAt('book', 2.9, true);
    expect(a).toEqual(b);
    expect(a.theta).toBeCloseTo(1.9, 9);
    expect(a.alpha).toBeGreaterThan(0);
  });

  test('la période se répète', () => {
    expect(M.gestureAt('open', 1.2, false).theta).toBeCloseTo(M.gestureAt('open', 1.2 + 3.6, false).theta, 9);
  });
});

describe('highlightsFor', () => {
  test('chaque étape allume ce qu\'elle montre', () => {
    expect(M.highlightsFor('welcome').tabs).toBe(1);
    expect(M.highlightsFor('table').buttons).toBe(1);
    expect(M.highlightsFor('tent').tabs).toBe(1);
  });

  test('le pli ne s\'allume jamais : aucune étape n\'a de fil de couture', () => {
    for (const step of M.STEPS) expect(M.highlightsFor(step).seam).toBeUndefined();
  });

  test('« C\'est parti » n\'allume rien', () => {
    expect(Object.values(M.highlightsFor('ready')).every((v) => v === 0)).toBe(true);
  });
});

describe('la tente : un V inversé posé sur la table', () => {
  const HALF = 4.75;

  test('l\'angle d\'ouverture est de 60 à 75 degrés', () => {
    const g = M.tentGeometry(M.TENT_ANGLE, HALF);
    const degrees = (g.openingAngle * 180) / Math.PI;
    expect(degrees).toBeGreaterThanOrEqual(60);
    expect(degrees).toBeLessThanOrEqual(75);
    for (const r of M.TENT_RANGE) {
      expect((r * 180) / Math.PI).toBeGreaterThanOrEqual(59.9);
      expect((r * 180) / Math.PI).toBeLessThanOrEqual(75.1);
    }
  });

  test('la charnière est en haut, au-dessus des deux tranches', () => {
    const g = M.tentGeometry(M.TENT_ANGLE, HALF);
    expect(g.hingeHeight).toBeGreaterThan(HALF * Math.cos(Math.PI / 2 - 0.0) + 1);
    // Hauteur d'un V de 69 degrés avec des moitiés de 4,75 : 4,75 x cos(34,4 degrés).
    expect(g.hingeHeight).toBeCloseTo(HALF * Math.cos(M.TENT_ANGLE / 2), 9);
  });

  test('les deux tranches basses reposent sur la table (y = 0)', () => {
    const g = M.tentGeometry(M.TENT_ANGLE, HALF);
    expect(g.frontBottomY).toBeCloseTo(0, 9);
    expect(g.backBottomY).toBeCloseTo(0, 9);
  });

  test('chaque moitié penche de la moitié de l\'angle, de part et d\'autre', () => {
    const a = M.tentAngles(M.TENT_ANGLE);
    expect(a.front).toBeCloseTo(M.TENT_ANGLE / 2, 9);
    expect(a.back).toBeCloseTo(M.TENT_ANGLE / 2, 9);
  });

  test('fermé, l\'appareil est posé à plat : les deux moitiés vont du même côté', () => {
    const a = M.tentAngles(0);
    expect(a.front).toBeCloseTo(Math.PI / 2, 9);
    expect(a.back).toBeCloseTo(-Math.PI / 2, 9);
    expect(M.tentGeometry(0, HALF).openingAngle).toBeCloseTo(0, 9);
  });

  test('en s\'ouvrant, l\'angle entre les moitiés est toujours celui de la charnière', () => {
    for (let t = 0; t <= M.TENT_ANGLE + 1e-9; t += 0.1) {
      expect(M.tentGeometry(t, HALF).openingAngle).toBeCloseTo(t, 9);
    }
  });

  test('la moitié avant se redresse de l\'à-plat vers le V, sans jamais passer sous la verticale', () => {
    for (let t = 0; t <= M.TENT_ANGLE; t += 0.05) {
      const f = M.tentAngles(t).front;
      expect(f).toBeLessThanOrEqual(Math.PI / 2 + 1e-9);
      expect(f).toBeGreaterThanOrEqual(t / 2 - 0.05);
      expect(f).toBeGreaterThan(0);
    }
  });
});
