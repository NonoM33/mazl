/*
 * MAZL — la scène 3D du tutoriel iPhone Duo.
 *
 * Un iPhone Duo stylisé (deux plaques, une charnière, un écran extérieur et un
 * écran intérieur) qui SUIT EN DIRECT l'angle réel de la charnière : Flutter
 * envoie `window.mazlDuo.setPose({...})` à chaque changement, la scène
 * s'approche de l'angle reçu à 60 images par seconde. Un contour tekhelet rejoue
 * le geste de l'étape en cours.
 *
 * three.js r170 (MIT, three.min.js, voir LICENSE-three.txt). Aucun réseau,
 * aucune ressource externe : tout est dans l'application.
 * Les calculs sans dessin sont dans pose_math.js (testés par `bun test`).
 */
(function () {
  'use strict';

  const T = window.THREE;
  const M = window.MazlDuoMath;
  const PI = Math.PI;

  // --- Palette « Encre & Tekhelet » (lib/core/theme/app_colors.dart) ---------
  const C = {
    ink: 0x0b0b0f,
    paper: 0xffffff,
    tek: 0x2747f5,
    tekLight: 0x5b78ff,
    mist: 0xf3f3f5,
    hair: 0xe2e2e6,
    muted: 0x6b6b76,
    body: 0x15151a,
    hinge: 0x2b2b33,
    tints: [0xe7e4df, 0xe1e5ea, 0xe8e2e5, 0xe1e8e4, 0xe3e1ea],
    bust: 0xcdd2da,
  };

  // --- Dimensions (1 unité = 100 points d'écran) ----------------------------
  const W = 4.75; // largeur d'une plaque
  const H = 6.69; // hauteur d'une plaque
  const TH = 0.26; // épaisseur d'une plaque
  const GAP = 0; // les deux moitiés se touchent : pas de jour, pas de fil
  const RADIUS = 0.66; // coins extérieurs
  const HINGE_RADIUS = 0.001; // côté charnière, les coins sont vifs : les moitiés se rejoignent sans encoche
  const INSET = 0.1; // cadre noir autour de l'écran
  const BEVEL = 0.035;
  const SCREEN_Z = 0.006;
  const COLUMN = 0.84; // colonne de la barre verticale (84 pt)

  // --- Formes ----------------------------------------------------------------

  /** Rectangle aux coins arrondis ; r = [haut-gauche, haut-droite, bas-droite, bas-gauche]. */
  function roundedShape(x0, y0, x1, y1, r) {
    const [tl, tr, br, bl] = r.map((v) => Math.max(v, 0.001));
    const s = new T.Shape();
    s.moveTo(x0 + tl, y1);
    s.lineTo(x1 - tr, y1);
    s.absarc(x1 - tr, y1 - tr, tr, PI / 2, 0, true);
    s.lineTo(x1, y0 + br);
    s.absarc(x1 - br, y0 + br, br, 0, -PI / 2, true);
    s.lineTo(x0 + bl, y0);
    s.absarc(x0 + bl, y0 + bl, bl, -PI / 2, -PI, true);
    s.lineTo(x0, y1 - tl);
    s.absarc(x0 + tl, y1 - tl, tl, PI, PI / 2, true);
    return s;
  }

  function rectShape(w, h, r) {
    const k = Math.min(r, w / 2, h / 2);
    return roundedShape(-w / 2, -h / 2, w / 2, h / 2, [k, k, k, k]);
  }

  /** Contour d'une pastille : un anneau de largeur `t` autour de w x h. */
  function outlineShape(w, h, t, r = Math.min(w, h) / 2) {
    const outer = rectShape(w + 2 * t, h + 2 * t, r + t);
    const hole = rectShape(w, h, r);
    outer.holes.push(new T.Path(hole.getPoints(24).reverse()));
    return outer;
  }

  /** Buste : une tête et des épaules, posés sur y = 0. */
  function bustShape(width, height) {
    const s = new T.Shape();
    s.moveTo(-width / 2, 0);
    s.bezierCurveTo(-width / 2, height * 0.62, -width * 0.3, height * 0.72, -width * 0.12, height * 0.78);
    s.lineTo(width * 0.12, height * 0.78);
    s.bezierCurveTo(width * 0.3, height * 0.72, width / 2, height * 0.62, width / 2, 0);
    s.closePath();
    return s;
  }

  function heartShape(k) {
    const s = new T.Shape();
    s.moveTo(0, -0.9 * k);
    s.bezierCurveTo(-1.6 * k, -0.1 * k, -0.95 * k, 0.95 * k, 0, 0.35 * k);
    s.bezierCurveTo(0.95 * k, 0.95 * k, 1.6 * k, -0.1 * k, 0, -0.9 * k);
    return s;
  }

  // --- Calques : un jeu de formes plates qui s'allume ou s'éteint d'un bloc --

  class Layer {
    constructor(z) {
      this.group = new T.Group();
      this.group.position.z = z;
      this.mats = [];
      this.alpha = 1;
      this.order = 10;
    }

    material(color, opacity) {
      const m = new T.MeshBasicMaterial({
        color,
        transparent: true,
        opacity,
        depthWrite: false,
        side: T.DoubleSide,
      });
      m.userData.base = opacity;
      this.mats.push(m);
      return m;
    }

    add(geometry, x, y, color, opacity = 1) {
      const m = this.material(color, opacity);
      const mesh = new T.Mesh(geometry, m);
      mesh.position.set(x, y, 0);
      mesh.renderOrder = this.order++;
      this.group.add(mesh);
      this.last = mesh;
      return m;
    }

    shape(shape, x, y, color, opacity = 1) {
      return this.add(new T.ShapeGeometry(shape, 24), x, y, color, opacity);
    }

    rect(x, y, w, h, color, opacity = 1, r = Math.min(w, h) / 2) {
      return this.shape(rectShape(w, h, r), x, y, color, opacity);
    }

    /** Barre posée par son bord gauche (une ligne de texte suggérée). */
    bar(left, y, w, h, color, opacity = 1) {
      return this.rect(left + w / 2, y, w, h, color, opacity);
    }

    circle(x, y, r, color, opacity = 1) {
      return this.add(new T.CircleGeometry(r, 40), x, y, color, opacity);
    }

    ring(x, y, r, t, color, opacity = 1) {
      return this.add(new T.RingGeometry(r - t, r, 56), x, y, color, opacity);
    }

    /** Fixe l'opacité du calque ; `base` de chaque matière garde sa propre intensité. */
    setAlpha(a) {
      this.alpha = a;
      this.group.visible = a > 0.004;
      this.refresh();
    }

    refresh() {
      for (const m of this.mats) m.opacity = m.userData.base * this.alpha;
    }
  }

  /** Les éléments qui s'allument en tekhelet : une liste de matières par groupe. */
  function highlightSet() {
    return { tabs: [], buttons: [] };
  }

  function tint(i) {
    return C.tints[i % C.tints.length];
  }

  /** Une photo de profil minimaliste : un aplat, un buste, deux traits de nom. */
  function drawPhoto(layer, cx, cy, w, h, tintColor, hl) {
    layer.rect(cx, cy, w, h, tintColor, 1, 0.34);
    const bw = Math.min(w * 0.62, 2.7);
    const bh = Math.min(h * 0.5, 2.4);
    layer.shape(bustShape(bw, bh), cx, cy - h / 2 + 0.002, C.bust, 1);
    layer.circle(cx, cy - h / 2 + bh * 0.78 + Math.min(w, h) * 0.12, Math.min(w, h) * 0.12 + 0.06, C.bust, 1);
    layer.bar(cx - w / 2 + 0.3, cy - h / 2 + 0.58, Math.min(1.5, w * 0.34), 0.13, C.paper, 0.92);
    layer.bar(cx - w / 2 + 0.3, cy - h / 2 + 0.32, Math.min(1.0, w * 0.22), 0.085, C.paper, 0.7);
  }

  /** La capsule d'onglets de la colonne verticale : cinq points, le premier actif. */
  function drawCapsule(layer, x, yTop, height, hl) {
    const w = 0.52;
    layer.rect(x, yTop - height / 2, w, height, C.ink, 1, w / 2);
    const n = 4;
    for (let i = 0; i < n; i++) {
      const y = yTop - 0.52 - i * ((height - 1.04) / (n - 1));
      if (i === 0) layer.circle(x, y, 0.11, C.tekLight, 1);
      else layer.circle(x, y, 0.07, 0x9a9aa5, 1);
    }
    hl.push(layer.add(new T.ShapeGeometry(outlineShape(w + 0.1, height + 0.1, 0.045), 24), x, yTop - height / 2, C.tek, 0));
  }

  /** L'îlot et la barre d'état, dans l'angle de la colonne. */
  function drawStatus(layer, x, y) {
    layer.rect(x, y, 0.4, 0.15, C.ink, 1);
    for (let i = 0; i < 3; i++) layer.circle(x - 0.15 + i * 0.15, y - 0.34, 0.032, C.muted, 0.55);
  }

  // --- Les contenus des écrans ---------------------------------------------

  /** Écran intérieur gauche, charnière verticale : la liste des conversations. */
  function buildList(layer, w, h, hl) {
    const left = -w / 2 + 0.34;
    layer.bar(left, h / 2 - 0.62, 1.1, 0.2, C.ink, 1);
    for (let i = 0; i < 5; i++) {
      const y = h / 2 - 1.5 - i * 0.98;
      if (i === 1) layer.rect(0, y, w - 0.3, 0.84, C.mist, 1, 0.3);
      layer.circle(left + 0.28, y, 0.29, tint(i), 1);
      layer.bar(left + 0.8, y + 0.13, 1.7 - (i % 3) * 0.28, 0.12, C.ink, 1);
      layer.bar(left + 0.8, y - 0.15, 2.3 - (i % 2) * 0.5, 0.085, C.muted, 0.45);
      if (i === 0 || i === 2) layer.circle(w / 2 - 0.42, y + 0.1, 0.075, C.tek, 1);
    }
  }

  /** Écran intérieur droit, charnière verticale : la conversation ouverte. */
  function buildChat(layer, w, h, hl) {
    const left = -w / 2 + 0.34;
    layer.circle(left + 0.26, h / 2 - 0.6, 0.26, tint(1), 1);
    layer.bar(left + 0.7, h / 2 - 0.52, 1.3, 0.14, C.ink, 1);
    layer.bar(left + 0.7, h / 2 - 0.78, 0.8, 0.085, C.muted, 0.45);
    const bubbles = [
      { side: -1, y: h / 2 - 1.85, bw: 2.5 },
      { side: 1, y: h / 2 - 2.8, bw: 2.9 },
      { side: -1, y: h / 2 - 3.75, bw: 1.7 },
      { side: 1, y: h / 2 - 4.7, bw: 2.1 },
    ];
    for (const b of bubbles) {
      const x = b.side < 0 ? -w / 2 + 0.3 + b.bw / 2 : w / 2 - 0.3 - b.bw / 2;
      layer.rect(x, b.y, b.bw, 0.74, b.side < 0 ? C.mist : C.tek, 1, 0.34);
      const lineLeft = x - b.bw / 2 + 0.28;
      layer.bar(lineLeft, b.y + 0.08, b.bw - 0.56, 0.095, b.side < 0 ? C.muted : C.paper, b.side < 0 ? 0.5 : 0.85);
      layer.bar(lineLeft, b.y - 0.14, (b.bw - 0.56) * 0.55, 0.075, b.side < 0 ? C.muted : C.paper, b.side < 0 ? 0.35 : 0.6);
    }
    layer.rect(-0.25, -h / 2 + 0.62, w - 1.1, 0.62, C.mist, 1, 0.31);
    layer.circle(w / 2 - 0.5, -h / 2 + 0.62, 0.25, C.tek, 1);
  }

  /** Charnière horizontale, plaque du haut : la photo (Découvrir). */
  function buildPhotoPane(layer, w, h, hl) {
    drawPhoto(layer, 0, 0, w - 0.55, h - 0.5, tint(1), null);
  }

  /** Charnière horizontale, plaque du bas : les trois boutons, à portée de pouce. */
  function buildButtonsPane(layer, w, h, hl) {
    const y = 0.15;
    layer.ring(-1.75, y, 0.56, 0.05, C.hair, 1);
    layer.rect(-1.75, y, 0.34, 0.06, C.ink, 1, 0.03);
    layer.last.rotation.z = PI / 4;
    layer.rect(-1.75, y, 0.34, 0.06, C.ink, 1, 0.03);
    layer.last.rotation.z = -PI / 4;
    layer.circle(0, y, 0.72, C.tek, 1);
    layer.shape(heartShape(0.3), 0, y + 0.02, C.paper, 1);
    layer.ring(1.75, y, 0.56, 0.05, C.hair, 1);
    layer.circle(1.75, y, 0.12, C.tek, 1);
    hl.buttons.push(layer.add(new T.RingGeometry(0.82, 0.88, 64), 0, y, C.tek, 0));
  }

  /** Écran extérieur, debout : une carte et la capsule d'onglets dans la colonne de droite. */
  function buildCoverPortrait(layer, w, h, hl) {
    const colX = w / 2 - COLUMN / 2;
    drawStatus(layer, colX, h / 2 - 0.4);
    drawCapsule(layer, colX, h / 2 - 1.1, 3.4, hl.tabs);
    const pw = w - 0.18 - COLUMN - 0.1;
    drawPhoto(layer, -w / 2 + 0.18 + pw / 2, 0.38, pw, h - 1.7, tint(0), null);
    const y = -h / 2 + 0.6;
    layer.ring(-w / 2 + 0.18 + pw / 2 - 0.85, y, 0.3, 0.04, C.hair, 1);
    layer.circle(-w / 2 + 0.18 + pw / 2 + 0.7, y, 0.38, C.tek, 1);
    layer.shape(heartShape(0.16), -w / 2 + 0.18 + pw / 2 + 0.7, y + 0.01, C.paper, 1);
  }

  // --- L'appareil --------------------------------------------------------------

  const geometryCache = {};

  /** Les arêtes d'une plaque sans celles du bord charnière : le contour se lit d'un seul tenant, sans trait au pli. */
  function silhouetteEdges(geo) {
    const edges = new T.EdgesGeometry(geo, 28);
    const attr = edges.getAttribute('position');
    const src = attr.array;
    const keep = [];
    const near = (x) => Math.abs(x) <= 2 * BEVEL + GAP + 1e-3;
    for (let i = 0; i < src.length; i += 6) {
      if (near(src[i]) && near(src[i + 3])) continue;
      for (let k = 0; k < 6; k++) keep.push(src[i + k]);
    }
    // Le bundle allégé n'exporte pas les classes d'attributs : on reprend celle de l'attribut lu.
    edges.setAttribute('position', new attr.constructor(new Float32Array(keep), 3));
    return edges;
  }

  function plateGeometry(side) {
    const key = 'plate' + side;
    if (geometryCache[key]) return geometryCache[key];
    const x0 = side > 0 ? GAP : -W;
    const x1 = side > 0 ? W : -GAP;
    const r = side > 0
      ? [HINGE_RADIUS, RADIUS, RADIUS, HINGE_RADIUS]
      : [RADIUS, HINGE_RADIUS, HINGE_RADIUS, RADIUS];
    // Côté charnière la plaque déborde du biseau : les deux moitiés se recouvrent, aucun creux ne marque le pli.
    const shape = side > 0
      ? roundedShape(x0 - BEVEL, -H / 2 + BEVEL, x1 - BEVEL, H / 2 - BEVEL, r)
      : roundedShape(x0 + BEVEL, -H / 2 + BEVEL, x1 + BEVEL, H / 2 - BEVEL, r);
    const geo = new T.ExtrudeGeometry(shape, {
      depth: TH - 2 * BEVEL,
      bevelEnabled: true,
      bevelThickness: BEVEL,
      bevelSize: BEVEL,
      bevelSegments: 3,
      curveSegments: 20,
    });
    geo.translate(0, 0, -(TH - BEVEL));
    geometryCache[key] = geo;
    return geo;
  }

  function screenGeometry(side) {
    const key = 'screen' + side;
    if (geometryCache[key]) return geometryCache[key];
    const x0 = side > 0 ? GAP : -W + INSET;
    const x1 = side > 0 ? W - INSET : -GAP;
    const inner = 0.001;
    const outer = RADIUS - INSET;
    const r = side > 0 ? [inner, outer, outer, inner] : [outer, inner, inner, outer];
    const geo = new T.ShapeGeometry(roundedShape(x0, -H / 2 + INSET, x1, H / 2 - INSET, r), 24);
    geometryCache[key] = geo;
    return geo;
  }

  const LIGHT_DIR = new T.Vector3(-5, 9, 7).normalize();
  const AXIS_X = new T.Vector3(1, 0, 0);
  const AXIS_Y = new T.Vector3(0, 1, 0);
  const AXIS_Z = new T.Vector3(0, 0, 1);

  function buildDevice(ghost) {
    const rig = new T.Group();
    rig.rotation.order = 'ZYX';
    const pivots = { left: new T.Group(), right: new T.Group() };
    rig.add(pivots.left, pivots.right);

    const hl = highlightSet();
    const shaded = [];
    const layers = { listV: null, chatV: null, photoH: null, buttonsH: null, coverP: null };
    const all = [];

    const bodyMat = ghost
      ? null
      : new T.MeshStandardMaterial({ color: C.body, metalness: 0.38, roughness: 0.4 });
    const ghostMat = ghost
      ? new T.LineBasicMaterial({ color: C.tek, transparent: true, opacity: 0, depthTest: false })
      : null;

    for (const side of [-1, 1]) {
      const pivot = side < 0 ? pivots.left : pivots.right;
      pivot.userData.side = side;
      const geo = plateGeometry(side);
      if (ghost) {
        const lines = new T.LineSegments(silhouetteEdges(geo), ghostMat);
        lines.renderOrder = 100;
        pivot.add(lines);
        continue;
      }
      pivot.add(new T.Mesh(geo, bodyMat));

      const screenMat = new T.MeshBasicMaterial({ color: C.paper });
      shaded.push({ mat: screenMat, pivot });
      const screen = new T.Mesh(screenGeometry(side), screenMat);
      screen.position.z = SCREEN_Z;
      pivot.add(screen);

      // L'écran va jusqu'à la charnière : une seule image, sans bande au centre.
      const sw = W - GAP - INSET;
      const sh = H - 2 * INSET;
      const center = side > 0 ? (GAP + W - INSET) / 2 : (-W + INSET - GAP) / 2;

      const v = new Layer(SCREEN_Z * 2);
      v.group.position.x = center;
      (side < 0 ? buildList : buildChat)(v, sw, sh, null);
      pivot.add(v.group);
      layers[side < 0 ? 'listV' : 'chatV'] = v;

      // Charnière horizontale : le contenu, redressé pour qui regarde (la plaque est couchée d'un quart de tour).
      const hLayer = new Layer(SCREEN_Z * 2.5);
      hLayer.group.position.x = center;
      hLayer.group.rotation.z = -PI / 2;
      if (side > 0) buildPhotoPane(hLayer, sh, sw, hl);
      else buildButtonsPane(hLayer, sh, sw, hl);
      pivot.add(hLayer.group);
      layers[side > 0 ? 'photoH' : 'buttonsH'] = hLayer;

      if (side < 0) {
        // L'écran extérieur est au dos de la plaque de gauche.
        const cover = new T.Group();
        cover.rotation.y = PI;
        cover.position.set(-W / 2 - GAP / 2, 0, -TH - SCREEN_Z);
        const coverMat = new T.MeshBasicMaterial({ color: C.paper });
        shaded.push({ mat: coverMat, pivot, back: true });
        const coverScreen = new T.Mesh(new T.ShapeGeometry(rectShape(sw, sh, RADIUS - INSET), 24), coverMat);
        cover.add(coverScreen);
        const cp = new Layer(SCREEN_Z);
        buildCoverPortrait(cp, sw, sh, hl);
        cover.add(cp.group);
        pivot.add(cover);
        layers.coverP = cp;
      }
    }

    // La charnière : un cylindre fin, à plat comme debout.
    const hingeGroup = new T.Group();
    if (!ghost) {
      const cyl = new T.Mesh(
        new T.CylinderGeometry(TH / 2, TH / 2, H - 0.8, 40),
        new T.MeshStandardMaterial({ color: C.hinge, metalness: 0.5, roughness: 0.35 }),
      );
      cyl.position.z = -TH / 2;
      hingeGroup.add(cyl);
      rig.add(hingeGroup);
    }

    for (const l of Object.values(layers)) if (l) all.push(l);

    const qa = new T.Quaternion();
    const qb = new T.Quaternion();
    const qz = new T.Quaternion().setFromAxisAngle(AXIS_Z, PI / 2);
    const tmp = new T.Quaternion();
    const qw = new T.Quaternion();
    const normal = new T.Vector3();

    const device = {
      rig,
      layers,
      hl,
      allLayers: all,
      ghostMat,
      /** Place les plaques pour un angle de charnière, un axe (0 vertical, 1 horizontal) */
      pose(theta, axisT) {
        const f = M.foldAngles(theta);
        // Charnière verticale : chaque plaque tourne d'autant, de part et d'autre.
        qa.setFromAxisAngle(AXIS_Y, f.vHalf);
        qb.setFromAxisAngle(AXIS_Y, -f.vHalf);
        // Charnière horizontale : le bas se couche sur la table, le haut penche.
        tmp.setFromAxisAngle(AXIS_X, -f.pitch).multiply(qz);
        pivots.left.quaternion.slerpQuaternions(qa, tmp, axisT);
        tmp.setFromAxisAngle(AXIS_X, f.topTilt).multiply(qz);
        pivots.right.quaternion.slerpQuaternions(qb, tmp, axisT);
        rig.rotation.set(0, f.yaw * (1 - axisT), 0, 'ZYX');
        hingeGroup.rotation.z = axisT * (PI / 2);
        rig.position.set(0, 0, 0);
        rig.updateMatrixWorld(true);
        const box = measure(rig);
        // Centré, posé sur la table.
        rig.position.set(-(box.min.x + box.max.x) / 2, -box.min.y, -(box.min.z + box.max.z) / 2);
        box.translate(rig.position);
        rig.updateMatrixWorld(true);
        // La lumière sur chaque face : une moitié un peu plus éclairée que l'autre.
        for (const { mat, pivot, back } of shaded) {
          pivot.getWorldQuaternion(qw);
          normal.set(0, 0, back ? -1 : 1).applyQuaternion(qw);
          const lit = M.clamp(normal.dot(LIGHT_DIR) * 1.15, 0, 1);
          mat.color.setScalar(0.9 + 0.1 * lit);
        }
        return box;
      },
    };
    return device;
  }

  const _corner = new T.Vector3();

  /** L'enveloppe réelle des deux plaques, sommets de leur boîte transformés. */
  function measure(rig) {
    const box = new T.Box3();
    box.makeEmpty();
    for (const pivot of rig.children) {
      const side = pivot.userData.side;
      if (side === undefined) continue;
      pivot.updateWorldMatrix(true, false);
      const x0 = side > 0 ? GAP : -W;
      const x1 = side > 0 ? W : -GAP;
      for (const x of [x0, x1]) {
        for (const y of [-H / 2, H / 2]) {
          for (const z of [-TH, 0]) {
            box.expandByPoint(_corner.set(x, y, z).applyMatrix4(pivot.matrixWorld));
          }
        }
      }
    }
    return box;
  }

  // --- La scène ---------------------------------------------------------------

  const canvasHost = document.getElementById('stage');
  const renderer = new T.WebGLRenderer({ antialias: true, alpha: true, powerPreference: 'high-performance' });
  renderer.setClearColor(0x000000, 0);
  renderer.toneMapping = T.NoToneMapping;
  canvasHost.appendChild(renderer.domElement);

  const scene = new T.Scene();
  const camera = new T.PerspectiveCamera(26, 1, 1, 120);

  scene.add(new T.HemisphereLight(0xffffff, 0xc9ccd6, 1.15));
  const key = new T.DirectionalLight(0xffffff, 2.1);
  key.position.set(-5, 9, 7);
  scene.add(key);
  const fill = new T.DirectionalLight(0xd9e1ff, 0.7);
  fill.position.set(7, 3, -2);
  scene.add(fill);

  const real = buildDevice(false);
  const ghost = buildDevice(true);
  scene.add(real.rig);
  scene.add(ghost.rig);

  // L'ombre de contact : un dégradé radial posé sur la table, sans carte d'ombres.
  const shadow = (() => {
    const size = 256;
    const cv = document.createElement('canvas');
    cv.width = cv.height = size;
    const g = cv.getContext('2d');
    const grad = g.createRadialGradient(size / 2, size / 2, 0, size / 2, size / 2, size / 2);
    grad.addColorStop(0, 'rgba(11,11,15,0.34)');
    grad.addColorStop(0.5, 'rgba(11,11,15,0.14)');
    grad.addColorStop(1, 'rgba(11,11,15,0)');
    g.fillStyle = grad;
    g.fillRect(0, 0, size, size);
    const mesh = new T.Mesh(
      new T.PlaneGeometry(1, 1),
      new T.MeshBasicMaterial({ map: new T.CanvasTexture(cv), transparent: true, depthWrite: false }),
    );
    mesh.rotation.x = -PI / 2;
    mesh.position.y = 0.002;
    mesh.renderOrder = 1;
    return mesh;
  })();
  scene.add(shadow);

  // Le trait tekhelet qui se trace sous l'appareil quand le geste est fait.
  const TRACE_THICKNESS = 0.07;
  const trace = new T.Mesh(
    new T.ShapeGeometry(rectShape(0.2, TRACE_THICKNESS, TRACE_THICKNESS / 2), 12),
    new T.MeshBasicMaterial({ color: C.tek, transparent: true, depthWrite: false }),
  );
  let traceLength = 0;
  trace.rotation.x = -PI / 2;
  trace.position.y = 0.004;
  trace.renderOrder = 2;
  scene.add(trace);

  // --- État ----------------------------------------------------------------------

  const reducedQuery = window.matchMedia ? window.matchMedia('(prefers-reduced-motion: reduce)') : null;
  // Avant le premier message de Flutter : l'appareil fermé, comme à l'étape 1.
  let pose = M.normalizePose({ hinge: 'closed' });
  let target = M.targetFor(pose);
  const cur = { theta: target.theta, axisT: target.axisT, trace: 0, ghostAlpha: 0, dist: 14, ty: 3 };
  const hlCur = { tabs: 0, buttons: 0 };
  let width = 1;
  let height = 1;
  let frameId = 0;
  let readySent = false;
  let started = false;
  let framed = false;
  let last = performance.now();
  const t0 = last;

  const reduced = () => pose.reduceMotion || (reducedQuery !== null && reducedQuery.matches);

  function resize() {
    width = Math.max(1, window.innerWidth);
    height = Math.max(1, window.innerHeight);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2.5));
    renderer.setSize(width, height, false);
    renderer.domElement.style.width = width + 'px';
    renderer.domElement.style.height = height + 'px';
    camera.aspect = width / height;
    camera.updateProjectionMatrix();
    requestRender();
  }

  function setBase(mats, value) {
    for (const m of mats) m.userData.base = value;
  }

  function applyHighlights() {
    for (const dev of [real]) {
      for (const k of Object.keys(hlCur)) setBase(dev.hl[k], hlCur[k]);
      for (const l of dev.allLayers) l.refresh();
    }
  }

  function update(dt, time) {
    const snap = reduced();
    const half = snap ? 0 : 0.1;
    cur.theta = M.approach(cur.theta, target.theta, dt, half);
    cur.axisT = M.approach(cur.axisT, target.axisT, dt, snap ? 0 : 0.2);

    const box = real.pose(cur.theta, cur.axisT);

    // Les calques d'écran se fondent selon l'orientation de l'appareil.
    const aH = M.smoothstep(0.35, 0.65, cur.axisT);
    real.layers.listV.setAlpha(1 - aH);
    real.layers.chatV.setAlpha(1 - aH);
    real.layers.photoH.setAlpha(aH);
    real.layers.buttonsH.setAlpha(aH);
    real.layers.coverP.setAlpha(1);

    // Les éclats : l'étape allume, le geste réussi les tient allumés.
    const want = M.highlightsFor(pose.step);
    const pulse = snap ? 0.85 : 0.62 + 0.38 * (0.5 + 0.5 * Math.sin(time * 2.6));
    for (const k of Object.keys(hlCur)) {
      const goal = pose.validated && want[k] > 0 ? 1 : want[k] * pulse;
      hlCur[k] = M.approach(hlCur[k], goal, dt, snap ? 0 : 0.14);
    }
    applyHighlights();

    // Le contour du geste, rejoué en boucle tant qu'il n'est pas fait.
    const g = pose.validated ? null : M.gestureAt(pose.step, time, snap);
    const goalAlpha = g ? g.alpha : 0;
    cur.ghostAlpha = M.approach(cur.ghostAlpha, goalAlpha, dt, snap ? 0 : 0.08);
    if (g && cur.ghostAlpha > 0.01) {
      ghost.rig.visible = true;
      ghost.pose(g.theta, g.axisT);
      ghost.ghostMat.opacity = cur.ghostAlpha * 0.9;
    } else {
      ghost.rig.visible = false;
    }

    // Le trait de réussite.
    cur.trace = M.approach(cur.trace, pose.validated ? 1 : 0, dt, snap ? 0 : 0.16);
    const bw = Math.max(box.max.x - box.min.x, 2.2) * 0.6;
    const length = Math.max(bw * M.easeInOut(cur.trace), 0);
    if (Math.abs(length - traceLength) > 0.004) {
      // Un trait à bouts ronds qui s'allonge depuis le centre : on refait sa forme.
      traceLength = length;
      trace.geometry.dispose();
      trace.geometry = new T.ShapeGeometry(rectShape(Math.max(length, TRACE_THICKNESS), TRACE_THICKNESS, TRACE_THICKNESS / 2), 12);
    }
    trace.visible = cur.trace > 0.002;
    trace.position.x = (box.min.x + box.max.x) / 2;
    trace.position.z = box.max.z + 0.6;

    // L'ombre de contact suit l'empreinte réelle.
    shadow.scale.set(Math.max(box.max.x - box.min.x, 1.6) * 1.35 + 1.2, Math.max(box.max.z - box.min.z, 0.9) * 1.7 + 1.1, 1);
    shadow.position.x = (box.min.x + box.max.x) / 2;
    shadow.position.z = (box.min.z + box.max.z) / 2;

    // La caméra cadre l'ensemble, contour compris, et se rapproche en douceur.
    const union = box.clone();
    if (!pose.validated) {
      const range = gestureBounds(pose.step);
      if (range) union.union(range);
    }
    const bwid = union.max.x - union.min.x;
    const bhei = union.max.y - union.min.y;
    const fov = (camera.fov * PI) / 180;
    const needV = (bhei * 1.35) / (2 * Math.tan(fov / 2));
    const needH = (bwid * 1.3) / camera.aspect / (2 * Math.tan(fov / 2));
    const need = Math.max(needV, needH, 9) + (union.max.z - union.min.z) / 2;
    const centerY = (union.min.y + union.max.y) / 2;
    if (!framed) {
      // La première image est déjà cadrée : pas de zoom d'entrée.
      framed = true;
      cur.dist = need;
      cur.ty = centerY;
    }
    cur.dist = M.approach(cur.dist, need, dt, snap ? 0 : 0.35);
    cur.ty = M.approach(cur.ty, centerY, dt, snap ? 0 : 0.35);
    const flat = M.clamp((box.max.z - box.min.z) / 5.5, 0, 1) * cur.axisT;
    const elevation = M.lerp(0.2, 0.52, flat);
    const sway = snap ? 0 : Math.sin(time * 0.42) * 0.09;
    const azimuth = 0.2 + sway;
    camera.position.set(
      Math.sin(azimuth) * Math.cos(elevation) * cur.dist,
      cur.ty + Math.sin(elevation) * cur.dist,
      Math.cos(azimuth) * Math.cos(elevation) * cur.dist,
    );
    camera.lookAt(0, cur.ty, 0);
    // Un plan proche serré garde la précision de profondeur : les formes d'écran
    // ne sont qu'à quelques millièmes d'unité de la vitre.
    camera.near = Math.max(1, cur.dist - 10);
    camera.far = cur.dist + 25;
    camera.updateProjectionMatrix();
  }

  const boundsCache = {};

  /** L'enveloppe du départ et de l'arrivée du geste, pour que le cadrage ne respire pas avec le contour. */
  function gestureBounds(step) {
    if (boundsCache[step] !== undefined) return boundsCache[step];
    const from = M.gestureAt(step, 0.6, false);
    const to = M.gestureAt(step, 2.4, false);
    if (!from || !to) return (boundsCache[step] = null);
    const box = ghost.pose(from.theta, from.axisT).clone();
    box.union(ghost.pose(to.theta, to.axisT));
    return (boundsCache[step] = box);
  }

  function frame(now) {
    frameId = 0;
    const dt = Math.min((now - last) / 1000, 0.25);
    last = now;
    update(dt, (now - t0) / 1000);
    renderer.render(scene, camera);
    if (!readySent) {
      readySent = true;
      renderer.domElement.classList.add('on');
      if (window.mazlDuoBridge && typeof window.mazlDuoBridge.postMessage === 'function') window.mazlDuoBridge.postMessage('ready');
    }
    if (started && !reduced() && !document.hidden) frameId = requestAnimationFrame(frame);
  }

  function requestRender() {
    if (frameId === 0) frameId = requestAnimationFrame(frame);
  }

  /** Lance la boucle à 60 i/s, ou rend une image fixe sous « Réduire les animations ». */
  function start() {
    started = true;
    last = performance.now();
    requestRender();
  }

  window.addEventListener('resize', resize);
  document.addEventListener('visibilitychange', () => {
    last = performance.now();
    requestRender();
  });
  if (reducedQuery && reducedQuery.addEventListener) reducedQuery.addEventListener('change', requestRender);

  window.mazlDuo = {
    /** Reçoit la pose réelle de Flutter ; l'angle est suivi en douceur. */
    setPose(raw) {
      pose = M.normalizePose(raw);
      target = M.targetFor(pose);
      // Sous « Réduire les animations », on saute à la pose sans la parcourir.
      requestRender();
    },
    /** Pour la mise au point : l'état courant de la scène. */
    state() {
      return { pose, target, cur: { ...cur }, highlights: { ...hlCur } };
    },
  };

  resize();
  start();
})();
