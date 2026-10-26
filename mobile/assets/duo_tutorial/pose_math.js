/*
 * MAZL — tutoriel iPhone Duo : les calculs de pose, sans three.js ni DOM.
 *
 * Fonctions pures (testées par tool/duo_tutorial/pose_math.test.js, `bun test`).
 * Chargé comme script classique par index.html (window.MazlDuoMath) et comme
 * module CommonJS par le test.
 */
(function (root, factory) {
  'use strict';
  const api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  else root.MazlDuoMath = api;
})(typeof window !== 'undefined' ? window : globalThis, function () {
  'use strict';

  const PI = Math.PI;

  /** Angle de la charnière quand le système n'en donne pas (radians). */
  const DEFAULT_ANGLE = { closed: 0, partiallyOpen: 1.9, fullyOpen: PI, unknown: PI };
  const HINGES = Object.keys(DEFAULT_ANGLE);
  const STEPS = ['welcome', 'open', 'book', 'table', 'tent', 'ready'];

  const clamp = (v, lo, hi) => Math.min(hi, Math.max(lo, v));
  const lerp = (a, b, t) => a + (b - a) * t;
  const smoothstep = (e0, e1, x) => {
    const t = clamp((x - e0) / (e1 - e0), 0, 1);
    return t * t * (3 - 2 * t);
  };
  const easeInOut = (t) => {
    const x = clamp(t, 0, 1);
    return x < 0.5 ? 4 * x * x * x : 1 - Math.pow(-2 * x + 2, 3) / 2;
  };

  /**
   * Approche `target` depuis `current` en `dt` secondes, indépendamment de la
   * cadence : la moitié de l'écart se résorbe toutes les `halfLife` secondes.
   * Le système donne l'angle à son propre rythme ; l'image, elle, tourne à 60 i/s.
   */
  function approach(current, target, dt, halfLife) {
    if (!(halfLife > 0)) return target;
    const step = clamp(dt, 0, 0.25);
    const keep = Math.pow(0.5, step / halfLife);
    const next = target + (current - target) * keep;
    return Math.abs(next - target) < 1e-4 ? target : next;
  }

  /**
   * Lit le message de Dart sans lui faire confiance : charnière connue,
   * angle fini dans [0, pi], axe et étape connus. Tout le reste prend la
   * valeur la plus sobre.
   */
  function normalizePose(raw) {
    const m = raw && typeof raw === 'object' ? raw : {};
    const hinge = HINGES.includes(m.hinge) ? m.hinge : 'unknown';
    const angle =
      typeof m.angle === 'number' && Number.isFinite(m.angle)
        ? clamp(m.angle, 0, PI)
        : DEFAULT_ANGLE[hinge];
    return {
      hinge,
      angle,
      axis: m.axis === 'horizontal' ? 'horizontal' : 'vertical',
      sideways: m.sideways === true,
      verticalBar: m.verticalBar === 'left' || m.verticalBar === 'right' ? m.verticalBar : null,
      step: STEPS.includes(m.step) ? m.step : 'welcome',
      validated: m.validated === true,
      reduceMotion: m.reduceMotion === true,
    };
  }

  /**
   * Comment les deux plaques se placent pour un angle `theta` de la charnière
   * (0 fermé, pi à plat).
   *  - vHalf : de combien chaque plaque tourne autour d'une charnière verticale ;
   *  - yaw   : de combien tout l'appareil se tourne pour présenter sa face
   *            extérieure quand il se ferme ;
   *  - pitch : charnière horizontale, de combien la plaque du bas se couche sur
   *            la table (0 debout, pi/2 à plat) ;
   *  - topTilt : inclinaison de la plaque du haut autour de la charnière.
   */
  function foldAngles(theta) {
    const t = clamp(theta, 0, PI);
    const vHalf = (PI - t) / 2;
    const yaw = (PI / 2) * smoothstep(0.9, 0, t);
    const pitch = (PI / 2) * clamp((PI - t) / (PI - 2.2), 0, 1);
    return { vHalf, yaw, pitch, topTilt: PI - t - pitch };
  }

  /** Ouverture d'une tente : un V inversé de 60 à 75 degrés, posé sur ses deux tranches. */
  const TENT_ANGLE = 1.2;
  const TENT_RANGE = [1.047, 1.309];

  /** L'angle de la tente montrée : celui du système s'il est dans la plage, sinon le typique. */
  function tentAngle(angle) {
    return angle >= TENT_RANGE[0] && angle <= TENT_RANGE[1] ? angle : TENT_ANGLE;
  }

  /**
   * La tente : la charnière en haut, les deux moitiés descendent jusqu'à la
   * table. `front` et `back` sont l'écart de chaque moitié avec la verticale
   * (avant : vers la caméra ; arrière : à l'opposé, négatif = vers la caméra).
   * Fermé (theta 0) l'appareil est posé à plat, les deux moitiés empilées ;
   * en s'ouvrant, la moitié avant se redresse jusqu'au V symétrique.
   */
  function tentAngles(theta) {
    const t = clamp(theta, 0, PI);
    const lay = smoothstep(0, TENT_ANGLE, t);
    const front = lerp(PI / 2, t / 2, lay);
    return { front, back: t - front };
  }

  /**
   * La géométrie de la tente pour des moitiés de longueur `length` : à quelle
   * hauteur est la charnière et où reposent les deux tranches basses (la table
   * est à y = 0).
   */
  function tentGeometry(theta, length) {
    const { front, back } = tentAngles(theta);
    const frontDrop = length * Math.cos(front);
    const backDrop = length * Math.cos(back);
    const hingeHeight = Math.max(frontDrop, backDrop, 0);
    return {
      hingeHeight,
      frontBottomY: hingeHeight - frontDrop,
      backBottomY: hingeHeight - backDrop,
      openingAngle: front + back,
    };
  }

  /** Ce que la scène cherche à atteindre pour un message. */
  function targetFor(pose) {
    const tent = pose.sideways && (pose.hinge === 'closed' || pose.hinge === 'partiallyOpen');
    return {
      theta: tent ? tentAngle(pose.angle) : pose.angle,
      axisT: !tent && pose.axis === 'horizontal' && pose.hinge !== 'closed' ? 1 : 0,
      tentT: tent ? 1 : 0,
    };
  }

  /**
   * Le geste à faire à l'étape, montré par un contour qui le rejoue : de `from`
   * à `to`. `null` quand l'étape n'a pas de geste.
   */
  const GESTURES = {
    open: { from: { theta: 0, axisT: 0, tentT: 0 }, to: { theta: PI, axisT: 0, tentT: 0 } },
    book: { from: { theta: PI, axisT: 0, tentT: 0 }, to: { theta: 1.9, axisT: 0, tentT: 0 } },
    table: { from: { theta: PI, axisT: 1, tentT: 0 }, to: { theta: 1.9, axisT: 1, tentT: 0 } },
    // Posé à plat, fermé ; on l'entrouvre, puis on le dresse en V sur la table.
    tent: { from: { theta: 0, axisT: 0, tentT: 1 }, to: { theta: TENT_ANGLE, axisT: 0, tentT: 1 } },
  };
  const GESTURE_PERIOD = 3.6;

  /**
   * Où en est le contour du geste à l'instant `t` (secondes) : `u` avance de 0
   * à 1 en douceur entre deux pauses, `alpha` l'allume et l'éteint.
   */
  function gestureFrame(t) {
    const p = (((t % GESTURE_PERIOD) + GESTURE_PERIOD) % GESTURE_PERIOD);
    const u = easeInOut((p - 0.6) / 1.7);
    const alpha = smoothstep(0, 0.45, p) * (1 - smoothstep(GESTURE_PERIOD - 0.55, GESTURE_PERIOD, p));
    return { u, alpha };
  }

  function gestureAt(step, t, reduceMotion) {
    const g = GESTURES[step];
    if (!g) return null;
    if (reduceMotion) return { ...g.to, alpha: 0.9, u: 1 };
    const f = gestureFrame(t);
    return {
      theta: lerp(g.from.theta, g.to.theta, f.u),
      axisT: lerp(g.from.axisT, g.to.axisT, f.u),
      tentT: lerp(g.from.tentT, g.to.tentT, f.u),
      alpha: f.alpha,
      u: f.u,
    };
  }

  /** Ce qui s'allume en tekhelet à chaque étape (0 à 1). Jamais le pli : il se lit par la mise en page et l'angle. */
  function highlightsFor(step) {
    const none = { tabs: 0, buttons: 0 };
    switch (step) {
      case 'welcome':
        return { ...none, tabs: 1 };
      case 'table':
        return { ...none, buttons: 1 };
      case 'tent':
        return { ...none, tabs: 1 };
      default:
        return none;
    }
  }

  return {
    DEFAULT_ANGLE,
    STEPS,
    TENT_ANGLE,
    TENT_RANGE,
    approach,
    clamp,
    easeInOut,
    foldAngles,
    gestureAt,
    gestureFrame,
    highlightsFor,
    lerp,
    normalizePose,
    smoothstep,
    targetFor,
    tentAngle,
    tentAngles,
    tentGeometry,
  };
});
