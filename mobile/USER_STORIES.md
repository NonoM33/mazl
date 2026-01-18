# MAZL - User Stories & Specifications

> Ce fichier est la source de vérité pour l'implémentation de toutes les features.
> Chaque US doit être implémentée avec TOUS les tests qui passent.

---

## Statut d'Implémentation

| US | Nom | Statut | Date | Fichiers |
|----|-----|--------|------|----------|
| US-TS-01 | Blocage Utilisateur | ✅ Implémenté | 2026-01-16 | `api_service.dart`, `block_report_dialog.dart`, `blocked_users_screen.dart`, `profile_view_screen.dart`, `settings_screen.dart` |
| US-TS-02 | Signalement Utilisateur | ✅ Implémenté | 2026-01-16 | `api_service.dart`, `block_report_dialog.dart`, `profile_view_screen.dart` |
| US-TS-03 | Vérification Photo | ✅ Implémenté | 2026-01-16 | `api_service.dart`, `verification_screen.dart` |
| US-PREM-01 | Aperçu Likes Floutés | ✅ Implémenté | 2026-01-16 | `api_service.dart`, `likes_screen.dart`, `matches_screen.dart` |
| US-PROF-01 | Prompts de Profil | ✅ Implémenté | 2026-01-16 | `api_service.dart`, `profile_prompts_section.dart`, `profile_prompts_display.dart`, `edit_profile_screen.dart` |
| US-PROF-02 | Intentions de Relation | ✅ Implémenté | 2026-01-16 | `api_service.dart`, `relationship_intention_selector.dart`, `edit_profile_screen.dart` |
| US-MATCH-01 | Score de Compatibilité | ✅ Implémenté | 2026-01-17 | `api_service.dart`, `compatibility_score_widget.dart` |
| US-MATCH-02 | Icebreakers Suggérés | ✅ Implémenté | 2026-01-17 | `icebreaker_service.dart`, `icebreakers_widget.dart` |
| US-PREM-02 | Boost | ✅ Implémenté | 2026-01-17 | `api_service.dart`, `boost_screen.dart`, `app_router.dart`, `route_names.dart` |
| US-PREM-03 | Qui a Visité Mon Profil | ✅ Implémenté | 2026-01-17 | `api_service.dart`, `visitors_screen.dart`, `app_router.dart`, `route_names.dart` |
| US-COUPLE-01 | Anniversaire MAZL | ✅ Implémenté | 2026-01-17 | `api_service.dart`, `anniversary_widget.dart`, `couple_dashboard_screen.dart` |
| US-COUPLE-02 | Success Story | ✅ Implémenté | 2026-01-17 | `api_service.dart`, `success_stories_screen.dart`, `couple_dashboard_screen.dart`, `app_router.dart` |

---

## Table des Matières

1. [Phase 1 - Trust & Safety](#phase-1---trust--safety)
2. [Phase 1 - Conversion Premium](#phase-1---conversion-premium)
3. [Phase 1 - Profil & Engagement](#phase-1---profil--engagement)
4. [Phase 2 - Matching Intelligence](#phase-2---matching-intelligence)
5. [Phase 2 - Communication](#phase-2---communication)
6. [Phase 3 - Couple Mode Enhanced](#phase-3---couple-mode-enhanced)
7. [Phase 3 - Premium Features](#phase-3---premium-features)

---

# Phase 1 - Trust & Safety

## US-TS-01: Blocage Utilisateur

### Description
> En tant qu'utilisateur, je veux bloquer un profil pour ne plus jamais le voir et qu'il ne puisse plus me contacter.

### Critères d'Acceptation

| # | Critère | Obligatoire |
|---|---------|-------------|
| 1 | Un bouton "Bloquer" est accessible depuis le profil d'un autre utilisateur | ✅ |
| 2 | Un bouton "Bloquer" est accessible depuis une conversation | ✅ |
| 3 | Avant de bloquer, une confirmation est demandée | ✅ |
| 4 | Après blocage, l'utilisateur bloqué disparaît immédiatement de toutes les vues | ✅ |
| 5 | L'utilisateur bloqué ne peut plus voir mon profil dans Discover | ✅ |
| 6 | L'utilisateur bloqué ne peut plus m'envoyer de message | ✅ |
| 7 | Si une conversation existait, elle est archivée/masquée des deux côtés | ✅ |
| 8 | Je peux voir la liste des utilisateurs que j'ai bloqués dans les Settings | ✅ |
| 9 | Je peux débloquer un utilisateur depuis cette liste | ✅ |
| 10 | Après déblocage, l'utilisateur réapparaît dans Discover (s'il correspond à mes critères) | ✅ |

### Règles Métier

```
RULE-BLK-01: Le blocage est MUTUEL et SILENCIEUX
  - L'utilisateur bloqué ne reçoit PAS de notification
  - L'utilisateur bloqué ne sait PAS qu'il a été bloqué
  - Du point de vue du bloqué, c'est comme si mon profil n'existait plus

RULE-BLK-02: Persistance du blocage
  - Le blocage persiste même si l'un des deux supprime son compte et le recrée
  - Basé sur un identifiant unique (device ID + email hash)

RULE-BLK-03: Impact sur les matches existants
  - Si on était matchés, le match est supprimé
  - Si on avait une conversation, elle disparaît des deux côtés
  - Les messages ne sont PAS supprimés de la DB (pour modération)

RULE-BLK-04: Limite de blocages
  - Pas de limite de blocages (pour la sécurité des utilisateurs)
```

### Tests - DOIT Passer ✅

```
TEST-BLK-001: Bloquer depuis profil
  GIVEN: Je suis sur le profil de "David"
  WHEN: Je clique sur "..." puis "Bloquer"
  AND: Je confirme le blocage
  THEN: Je suis redirigé vers Discover
  AND: "David" n'apparaît plus jamais dans mes résultats

TEST-BLK-002: Bloquer depuis conversation
  GIVEN: Je suis dans une conversation avec "Sarah"
  WHEN: Je clique sur "..." puis "Bloquer"
  AND: Je confirme le blocage
  THEN: Je suis redirigé vers la liste des conversations
  AND: La conversation avec "Sarah" a disparu

TEST-BLK-003: Utilisateur bloqué ne me voit plus
  GIVEN: J'ai bloqué "David"
  WHEN: "David" utilise Discover
  THEN: Mon profil n'apparaît JAMAIS dans ses résultats

TEST-BLK-004: Utilisateur bloqué ne peut plus m'écrire
  GIVEN: J'ai bloqué "David" avec qui j'avais une conversation
  WHEN: "David" essaie d'accéder à notre conversation
  THEN: La conversation n'existe plus pour lui

TEST-BLK-005: Liste des bloqués
  GIVEN: J'ai bloqué "David" et "Sarah"
  WHEN: Je vais dans Settings > Utilisateurs bloqués
  THEN: Je vois la liste avec "David" et "Sarah"
  AND: Je peux les débloquer individuellement

TEST-BLK-006: Déblocage
  GIVEN: J'ai bloqué "David"
  WHEN: Je le débloque depuis les Settings
  THEN: "David" peut réapparaître dans mon Discover
  AND: "David" peut me voir à nouveau
  BUT: Notre ancienne conversation n'est PAS restaurée

TEST-BLK-007: Annulation blocage
  GIVEN: Je suis sur la popup de confirmation de blocage
  WHEN: Je clique sur "Annuler"
  THEN: Rien ne se passe, je reste sur le profil
```

### Tests - NE DOIT PAS Arriver ❌

```
TEST-BLK-ERR-001: Notification de blocage
  GIVEN: "David" m'a bloqué
  THEN: Je ne reçois AUCUNE notification
  AND: Je ne vois AUCUN message "Vous avez été bloqué"

TEST-BLK-ERR-002: Bloquer sans confirmation
  GIVEN: Je clique sur "Bloquer"
  THEN: Le blocage ne s'exécute PAS sans ma confirmation explicite

TEST-BLK-ERR-003: Se bloquer soi-même
  GIVEN: Je suis sur mon propre profil
  THEN: L'option "Bloquer" n'est PAS disponible

TEST-BLK-ERR-004: Bloquer un utilisateur déjà bloqué
  GIVEN: J'ai déjà bloqué "David"
  THEN: Je ne peux PAS le bloquer une seconde fois
  AND: L'option affiche "Débloquer" si accessible
```

### Modèle de Données

```sql
CREATE TABLE blocked_users (
  id SERIAL PRIMARY KEY,
  blocker_id INTEGER NOT NULL REFERENCES users(id),
  blocked_id INTEGER NOT NULL REFERENCES users(id),
  blocked_at TIMESTAMP DEFAULT NOW(),
  reason TEXT, -- optionnel, pour analytics
  UNIQUE(blocker_id, blocked_id)
);

CREATE INDEX idx_blocked_users_blocker ON blocked_users(blocker_id);
CREATE INDEX idx_blocked_users_blocked ON blocked_users(blocked_id);
```

### API Endpoints

```
POST   /api/users/{userId}/block     - Bloquer un utilisateur
DELETE /api/users/{userId}/block     - Débloquer un utilisateur
GET    /api/users/blocked            - Liste mes utilisateurs bloqués
```

---

## US-TS-02: Signalement Utilisateur

### Description
> En tant qu'utilisateur, je veux signaler un comportement inapproprié avec des catégories prédéfinies pour protéger la communauté.

### Critères d'Acceptation

| # | Critère | Obligatoire |
|---|---------|-------------|
| 1 | Un bouton "Signaler" est accessible depuis le profil d'un autre utilisateur | ✅ |
| 2 | Un bouton "Signaler" est accessible depuis une conversation | ✅ |
| 3 | Je dois choisir une raison parmi une liste prédéfinie | ✅ |
| 4 | Je peux ajouter un commentaire optionnel | ✅ |
| 5 | Après signalement, une confirmation s'affiche | ✅ |
| 6 | Je peux choisir de bloquer l'utilisateur en même temps | ✅ |
| 7 | Je ne peux pas signaler le même utilisateur 2x pour la même raison | ✅ |
| 8 | Les signalements sont visibles dans le back-office admin | ✅ |

### Catégories de Signalement

```
REPORT_CATEGORIES = [
  {
    id: "fake_profile",
    label: "Faux profil",
    description: "Photos volées, identité fausse",
    severity: "high"
  },
  {
    id: "inappropriate_photos",
    label: "Photos inappropriées",
    description: "Contenu sexuel, violent ou choquant",
    severity: "high"
  },
  {
    id: "harassment",
    label: "Harcèlement",
    description: "Messages insistants, menaces, insultes",
    severity: "critical"
  },
  {
    id: "spam",
    label: "Spam / Arnaque",
    description: "Publicité, demande d'argent, liens suspects",
    severity: "high"
  },
  {
    id: "underage",
    label: "Mineur",
    description: "La personne semble avoir moins de 18 ans",
    severity: "critical"
  },
  {
    id: "offline_behavior",
    label: "Comportement hors app",
    description: "Comportement inapproprié lors d'une rencontre",
    severity: "medium"
  },
  {
    id: "other",
    label: "Autre",
    description: "Autre raison (précisez)",
    severity: "low"
  }
]
```

### Règles Métier

```
RULE-RPT-01: Signalements critiques
  - "harassment" et "underage" déclenchent une alerte admin immédiate
  - L'utilisateur signalé est temporairement masqué en attendant review

RULE-RPT-02: Accumulation de signalements
  - 3 signalements "high" = suspension automatique + review
  - 1 signalement "critical" = suspension immédiate + review

RULE-RPT-03: Anti-abus
  - Un utilisateur ne peut pas signaler + de 10 personnes/jour
  - Signalements abusifs répétés = avertissement puis suspension

RULE-RPT-04: Confidentialité
  - L'utilisateur signalé ne sait JAMAIS qui l'a signalé
  - Les détails du signalement ne sont visibles que par les admins
```

### Tests - DOIT Passer ✅

```
TEST-RPT-001: Signaler depuis profil
  GIVEN: Je suis sur le profil de "David"
  WHEN: Je clique sur "..." puis "Signaler"
  THEN: Une modal s'ouvre avec les catégories
  WHEN: Je sélectionne "Faux profil"
  AND: J'ajoute un commentaire "Photos de célébrité"
  AND: Je valide
  THEN: Message de confirmation "Merci pour votre signalement"

TEST-RPT-002: Signaler avec blocage simultané
  GIVEN: Je signale "David"
  WHEN: Je coche "Bloquer également cet utilisateur"
  AND: Je valide
  THEN: Le signalement est envoyé
  AND: "David" est bloqué

TEST-RPT-003: Signalement critique - suspension auto
  GIVEN: Je signale "David" pour "Mineur"
  WHEN: Le signalement est envoyé
  THEN: Le profil de "David" est immédiatement masqué de Discover
  AND: Une alerte admin est créée

TEST-RPT-004: Accumulation signalements
  GIVEN: "David" a reçu 2 signalements "high" (fake_profile, spam)
  WHEN: Un 3ème signalement "high" arrive
  THEN: Le compte de "David" est suspendu automatiquement
  AND: "David" reçoit un email de notification

TEST-RPT-005: Pas de double signalement même raison
  GIVEN: J'ai déjà signalé "David" pour "spam"
  WHEN: J'essaie de le signaler à nouveau pour "spam"
  THEN: Message "Vous avez déjà signalé cet utilisateur pour cette raison"
  BUT: Je peux le signaler pour une autre raison
```

### Tests - NE DOIT PAS Arriver ❌

```
TEST-RPT-ERR-001: Signaler sans raison
  GIVEN: Je clique sur "Signaler"
  WHEN: Je valide sans sélectionner de catégorie
  THEN: Le bouton "Valider" est désactivé / Message d'erreur

TEST-RPT-ERR-002: Signaler soi-même
  GIVEN: Je suis sur mon propre profil
  THEN: L'option "Signaler" n'existe PAS

TEST-RPT-ERR-003: Abus de signalement
  GIVEN: J'ai signalé 10 personnes aujourd'hui
  WHEN: J'essaie de signaler une 11ème
  THEN: Message "Limite quotidienne atteinte"

TEST-RPT-ERR-004: Notification au signalé
  GIVEN: "David" a été signalé (sans suspension)
  THEN: "David" ne reçoit AUCUNE notification
  AND: "David" ne sait PAS qu'il a été signalé
```

### Modèle de Données

```sql
CREATE TABLE reports (
  id SERIAL PRIMARY KEY,
  reporter_id INTEGER NOT NULL REFERENCES users(id),
  reported_id INTEGER NOT NULL REFERENCES users(id),
  category VARCHAR(50) NOT NULL,
  comment TEXT,
  severity VARCHAR(20) NOT NULL, -- low, medium, high, critical
  status VARCHAR(20) DEFAULT 'pending', -- pending, reviewed, dismissed, actioned
  created_at TIMESTAMP DEFAULT NOW(),
  reviewed_at TIMESTAMP,
  reviewed_by INTEGER REFERENCES admin_users(id),
  action_taken TEXT,
  UNIQUE(reporter_id, reported_id, category)
);

CREATE INDEX idx_reports_status ON reports(status);
CREATE INDEX idx_reports_reported ON reports(reported_id);
CREATE INDEX idx_reports_severity ON reports(severity, status);
```

### API Endpoints

```
POST /api/users/{userId}/report   - Signaler un utilisateur
GET  /api/admin/reports           - [ADMIN] Liste des signalements
PUT  /api/admin/reports/{id}      - [ADMIN] Traiter un signalement
```

---

## US-TS-03: Vérification Photo (Selfie)

### Description
> En tant qu'utilisateur, je veux vérifier mon profil avec un selfie pour gagner un badge "Vérifié" et inspirer confiance.

### Critères d'Acceptation

| # | Critère | Obligatoire |
|---|---------|-------------|
| 1 | Un bouton "Vérifier mon profil" est accessible depuis mon profil | ✅ |
| 2 | Le process demande un selfie avec un geste aléatoire | ✅ |
| 3 | Le geste est choisi parmi: lever la main, sourire, pouce en l'air | ✅ |
| 4 | Le selfie est comparé à mes photos de profil | ✅ |
| 5 | En cas de succès, un badge "Vérifié" apparaît sur mon profil | ✅ |
| 6 | En cas d'échec, je peux réessayer (max 3 tentatives/jour) | ✅ |
| 7 | Le badge est visible sur toutes les vues (Discover, Match, Chat) | ✅ |
| 8 | Le selfie de vérification n'est PAS ajouté à mes photos publiques | ✅ |

### Gestes de Vérification

```
VERIFICATION_GESTURES = [
  {
    id: "hand_up",
    instruction: "Levez votre main droite",
    icon: "hand-raised"
  },
  {
    id: "smile",
    instruction: "Souriez naturellement",
    icon: "smile"
  },
  {
    id: "thumbs_up",
    instruction: "Faites un pouce en l'air",
    icon: "thumbs-up"
  },
  {
    id: "peace",
    instruction: "Faites le signe de paix",
    icon: "peace-sign"
  }
]
```

### Règles Métier

```
RULE-VRF-01: Processus de vérification
  1. Utilisateur clique sur "Vérifier"
  2. Instruction avec geste aléatoire affiché
  3. Caméra frontale activée
  4. Utilisateur prend le selfie
  5. Envoi au backend pour analyse
  6. Résultat en < 30 secondes

RULE-VRF-02: Critères de validation
  - Visage détecté: OUI
  - Geste correct: OUI (confidence > 80%)
  - Match avec photos profil: OUI (confidence > 70%)
  - Pas de photo d'écran: OUI

RULE-VRF-03: Limitations
  - Max 3 tentatives par jour
  - Délai 24h après 3 échecs
  - Vérification expire après 6 mois (re-vérification demandée)

RULE-VRF-04: Badge
  - Badge bleu avec checkmark
  - Tooltip "Photo vérifiée le {date}"
  - Visible partout où le profil apparaît
```

### Tests - DOIT Passer ✅

```
TEST-VRF-001: Vérification réussie
  GIVEN: J'ai des photos de profil uploadées
  WHEN: Je clique sur "Vérifier mon profil"
  AND: Je vois l'instruction "Levez votre main droite"
  AND: Je prends un selfie avec la main levée
  THEN: Analyse en cours (loading)
  AND: Message "Vérification réussie !"
  AND: Badge vérifié visible sur mon profil

TEST-VRF-002: Geste incorrect
  GIVEN: L'instruction est "Souriez"
  WHEN: Je prends un selfie sans sourire
  THEN: Message "Le geste n'a pas été détecté. Réessayez."
  AND: Je peux réessayer (tentative 2/3)

TEST-VRF-003: Visage ne correspond pas
  GIVEN: Mes photos montrent une personne A
  WHEN: Je prends un selfie d'une personne B
  THEN: Message "Le visage ne correspond pas à vos photos"
  AND: Tentative comptée

TEST-VRF-004: Limite tentatives
  GIVEN: J'ai échoué 3 fois aujourd'hui
  WHEN: J'essaie de vérifier à nouveau
  THEN: Message "Limite atteinte. Réessayez dans 24h."
  AND: Bouton désactivé avec countdown

TEST-VRF-005: Badge visible partout
  GIVEN: Mon profil est vérifié
  WHEN: Un autre utilisateur me voit dans Discover
  THEN: Le badge vérifié est visible sur ma photo
  WHEN: On est matchés et il voit notre conversation
  THEN: Le badge est visible à côté de mon nom
```

### Tests - NE DOIT PAS Arriver ❌

```
TEST-VRF-ERR-001: Selfie ajouté aux photos publiques
  GIVEN: Ma vérification a réussi
  THEN: Le selfie de vérification n'apparaît PAS dans mes photos de profil
  AND: N'est PAS visible par les autres utilisateurs

TEST-VRF-ERR-002: Vérifier sans photos de profil
  GIVEN: Je n'ai aucune photo de profil
  WHEN: Je clique sur "Vérifier"
  THEN: Message "Ajoutez d'abord des photos à votre profil"

TEST-VRF-ERR-003: Photo d'écran/screenshot
  GIVEN: Je montre une photo sur un autre écran à la caméra
  THEN: Message "Photo d'écran détectée. Utilisez votre visage réel."

TEST-VRF-ERR-004: Badge sans vérification
  GIVEN: Je n'ai pas fait la vérification
  THEN: Mon profil n'affiche PAS de badge vérifié
  AND: Impossible de forcer un badge via l'API
```

### Modèle de Données

```sql
ALTER TABLE users ADD COLUMN is_photo_verified BOOLEAN DEFAULT FALSE;
ALTER TABLE users ADD COLUMN photo_verified_at TIMESTAMP;
ALTER TABLE users ADD COLUMN verification_expires_at TIMESTAMP;

CREATE TABLE verification_attempts (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id),
  gesture_required VARCHAR(50) NOT NULL,
  selfie_url TEXT NOT NULL, -- stocké en privé, non accessible
  gesture_detected BOOLEAN,
  face_match_score DECIMAL(5,2),
  success BOOLEAN NOT NULL,
  failure_reason TEXT,
  attempted_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_verification_user_date ON verification_attempts(user_id, attempted_at);
```

### API Endpoints

```
POST /api/verification/start      - Démarrer vérification (retourne geste)
POST /api/verification/submit     - Soumettre selfie (multipart)
GET  /api/verification/status     - Status de ma vérification
```

---

# Phase 1 - Conversion Premium

## US-PREM-01: Aperçu Likes Floutés

### Description
> En tant qu'utilisateur free, je veux voir un aperçu flouté des personnes qui m'ont liké pour être incité à m'abonner.

### Critères d'Acceptation

| # | Critère | Obligatoire |
|---|---------|-------------|
| 1 | Un onglet/section "Qui t'a liké" est visible dans l'app | ✅ |
| 2 | Les utilisateurs free voient les photos floutées | ✅ |
| 3 | Le nombre de likes en attente est affiché | ✅ |
| 4 | Un bouton "Voir qui" mène vers l'upgrade premium | ✅ |
| 5 | Les utilisateurs premium voient les photos non floutées | ✅ |
| 6 | Les utilisateurs premium peuvent liker/passer directement | ✅ |
| 7 | Une notification est envoyée quand quelqu'un me like | ✅ |

### Règles Métier

```
RULE-LIKE-01: Affichage flouté
  - Blur gaussien level 20 sur les photos
  - Silhouette reconnaissable mais visage non identifiable
  - Prénom affiché mais pas l'âge ni la distance

RULE-LIKE-02: Compteur de likes
  - Affiche le nombre exact jusqu'à 10
  - Au-delà: "10+" puis "25+" puis "50+" puis "99+"

RULE-LIKE-03: Notification
  - Push notification: "Quelqu'un t'a liké ! Découvre qui."
  - Max 3 notifications de ce type par jour
  - Pas de notification si l'app est ouverte

RULE-LIKE-04: Ordre d'affichage
  - Plus récents en premier
  - Premium: peuvent filtrer par vérifiés/tous
```

### Tests - DOIT Passer ✅

```
TEST-LIKE-001: Vue free - photos floutées
  GIVEN: Je suis un utilisateur FREE
  AND: 5 personnes m'ont liké
  WHEN: Je vais dans "Qui t'a liké"
  THEN: Je vois 5 photos floutées
  AND: Je vois les prénoms
  AND: Je vois "5 personnes t'ont liké"
  AND: Bouton "Voir qui - Passer Premium"

TEST-LIKE-002: Vue premium - photos claires
  GIVEN: Je suis un utilisateur PREMIUM
  AND: 5 personnes m'ont liké
  WHEN: Je vais dans "Qui t'a liké"
  THEN: Je vois 5 photos CLAIRES
  AND: Je vois prénom, âge, distance
  AND: Je peux liker ou passer chaque profil

TEST-LIKE-003: Action premium sur like
  GIVEN: Je suis PREMIUM dans "Qui t'a liké"
  WHEN: Je like "Sarah" depuis cette vue
  THEN: C'est un match immédiat
  AND: "Sarah" disparaît de la liste des likes

TEST-LIKE-004: Notification de like
  GIVEN: Je suis offline
  WHEN: "David" me like
  THEN: Je reçois une push notification "Quelqu'un t'a liké !"
  AND: Le badge sur l'app affiche "1"

TEST-LIKE-005: Compteur 99+
  GIVEN: 150 personnes m'ont liké
  WHEN: Je vois le compteur
  THEN: Il affiche "99+"
```

### Tests - NE DOIT PAS Arriver ❌

```
TEST-LIKE-ERR-001: Free voit les photos
  GIVEN: Je suis FREE
  THEN: Je ne peux JAMAIS voir les photos non floutées de mes likes

TEST-LIKE-ERR-002: Spam notifications
  GIVEN: J'ai reçu 3 notifications de likes aujourd'hui
  WHEN: Une 4ème personne me like
  THEN: PAS de push notification
  BUT: Le compteur in-app augmente

TEST-LIKE-ERR-003: Like soi-même visible
  GIVEN: J'ai liké "Sarah"
  WHEN: "Sarah" regarde ses likes
  THEN: Ma photo apparaît dans ses likes
  BUT: Je ne vois PAS mon propre like dans ma liste
```

### Modèle de Données

```sql
-- La table swipes existe déjà
-- On ajoute un index pour les likes reçus
CREATE INDEX idx_swipes_target_likes ON swipes(target_user_id, action, created_at)
  WHERE action = 'like';

-- Vue pour les likes en attente (pas encore vus/matchés)
CREATE VIEW pending_likes AS
SELECT
  s.target_user_id as user_id,
  s.user_id as liker_id,
  s.created_at as liked_at,
  u.display_name,
  u.photos,
  u.is_photo_verified
FROM swipes s
JOIN profiles u ON s.user_id = u.user_id
LEFT JOIN swipes s2 ON s.target_user_id = s2.user_id
  AND s.user_id = s2.target_user_id
WHERE s.action = 'like'
  AND s2.id IS NULL; -- pas encore de swipe retour
```

### API Endpoints

```
GET /api/likes/received          - Liste mes likes reçus (flouté si free)
GET /api/likes/received/count    - Nombre de likes en attente
```

---

# Phase 1 - Profil & Engagement

## US-PROF-01: Prompts de Profil

### Description
> En tant qu'utilisateur, je veux ajouter des "prompts" (questions/réponses) à mon profil pour montrer ma personnalité et faciliter les conversations.

### Critères d'Acceptation

| # | Critère | Obligatoire |
|---|---------|-------------|
| 1 | Je peux choisir jusqu'à 3 prompts parmi une liste | ✅ |
| 2 | Chaque prompt a une question et ma réponse personnalisée | ✅ |
| 3 | Les prompts sont visibles sur mon profil public | ✅ |
| 4 | Je peux modifier/supprimer mes prompts à tout moment | ✅ |
| 5 | Certains prompts sont spécifiques à la culture juive | ✅ |
| 6 | Les prompts ont une limite de caractères (150) | ✅ |
| 7 | Un autre utilisateur peut "liker" un prompt spécifique | ✅ |

### Liste des Prompts

```
PROMPTS = [
  // Personnalité
  { id: "perfect_sunday", text: "Mon dimanche parfait..." },
  { id: "fun_fact", text: "Un fait surprenant sur moi..." },
  { id: "life_goal", text: "Un de mes objectifs dans la vie..." },
  { id: "pet_peeve", text: "Ce qui m'énerve le plus..." },
  { id: "proud_of", text: "Je suis fier(e) de..." },
  { id: "looking_for", text: "Je cherche quelqu'un qui..." },

  // Lifestyle
  { id: "ideal_vacation", text: "Mes vacances idéales..." },
  { id: "favorite_food", text: "Mon plat préféré..." },
  { id: "hidden_talent", text: "Mon talent caché..." },
  { id: "binge_watching", text: "En ce moment je regarde..." },

  // Judaïsme (différenciateur)
  { id: "shabbat_ideal", text: "Mon Shabbat idéal..." },
  { id: "family_tradition", text: "Une tradition familiale que j'adore..." },
  { id: "favorite_holiday", text: "Ma fête juive préférée..." },
  { id: "friday_night", text: "Le vendredi soir chez moi..." },
  { id: "israel_memory", text: "Mon meilleur souvenir en Israël..." },
  { id: "jewish_value", text: "Une valeur juive qui me guide..." },

  // Conversation starters
  { id: "debate_me", text: "Débats moi sur..." },
  { id: "teach_me", text: "Apprends-moi quelque chose sur..." },
  { id: "together_we_could", text: "Ensemble on pourrait..." },
  { id: "first_date", text: "Premier date idéal..." }
]
```

### Règles Métier

```
RULE-PRM-01: Limites
  - Maximum 3 prompts par profil
  - Minimum 0 (optionnel mais recommandé)
  - Réponse: 10-150 caractères

RULE-PRM-02: Affichage
  - Prompts affichés après les photos, avant les infos
  - Design: carte avec question en gris, réponse en noir
  - Icône "coeur" pour liker un prompt spécifique

RULE-PRM-03: Like sur prompt
  - Like un prompt = like le profil + message pré-rempli
  - Message: "J'adore ta réponse à '{prompt}' !"
  - Crée une conversation si match
```

### Tests - DOIT Passer ✅

```
TEST-PRM-001: Ajouter un prompt
  GIVEN: Je suis sur "Modifier mon profil"
  WHEN: Je clique sur "Ajouter un prompt"
  THEN: Je vois la liste des prompts disponibles
  WHEN: Je sélectionne "Mon Shabbat idéal..."
  AND: J'écris "En famille avec un bon repas et des chants"
  AND: Je sauvegarde
  THEN: Le prompt apparaît sur mon profil

TEST-PRM-002: Maximum 3 prompts
  GIVEN: J'ai déjà 3 prompts
  WHEN: J'essaie d'en ajouter un 4ème
  THEN: Message "Maximum 3 prompts. Supprimez-en un d'abord."

TEST-PRM-003: Like un prompt
  GIVEN: Je vois le profil de "Sarah" avec le prompt "Mon plat préféré: Le couscous de ma grand-mère"
  WHEN: Je clique sur le coeur du prompt
  THEN: Je like "Sarah"
  AND: Si c'est un match, le message initial est "J'adore ta réponse à 'Mon plat préféré' !"

TEST-PRM-004: Limite caractères
  GIVEN: J'écris une réponse de prompt
  WHEN: J'atteins 150 caractères
  THEN: Je ne peux plus écrire
  AND: Un compteur affiche "150/150"

TEST-PRM-005: Modifier prompt existant
  GIVEN: J'ai le prompt "Mon dimanche parfait: Brunch et balade"
  WHEN: Je clique sur modifier
  AND: Je change en "Brunch, balade et Netflix"
  AND: Je sauvegarde
  THEN: Le prompt est mis à jour
```

### Tests - NE DOIT PAS Arriver ❌

```
TEST-PRM-ERR-001: Réponse trop courte
  GIVEN: J'ajoute un prompt
  WHEN: J'écris seulement "Ok"
  THEN: Erreur "Minimum 10 caractères"

TEST-PRM-ERR-002: Prompt dupliqué
  GIVEN: J'ai déjà le prompt "Mon Shabbat idéal"
  WHEN: J'essaie de l'ajouter à nouveau
  THEN: Ce prompt n'apparaît pas dans la liste des disponibles

TEST-PRM-ERR-003: Prompt vide sauvegardé
  GIVEN: Je sélectionne un prompt
  WHEN: Je laisse la réponse vide et sauvegarde
  THEN: Erreur "Écrivez votre réponse"
```

### Modèle de Données

```sql
CREATE TABLE profile_prompts (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id),
  prompt_id VARCHAR(50) NOT NULL,
  answer TEXT NOT NULL CHECK (char_length(answer) BETWEEN 10 AND 150),
  position INTEGER NOT NULL CHECK (position BETWEEN 1 AND 3),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, prompt_id),
  UNIQUE(user_id, position)
);

CREATE INDEX idx_profile_prompts_user ON profile_prompts(user_id);
```

### API Endpoints

```
GET    /api/prompts                    - Liste tous les prompts disponibles
GET    /api/profile/prompts            - Mes prompts
POST   /api/profile/prompts            - Ajouter un prompt
PUT    /api/profile/prompts/{id}       - Modifier un prompt
DELETE /api/profile/prompts/{id}       - Supprimer un prompt
POST   /api/swipes/like-prompt         - Liker via un prompt
```

---

## US-PROF-02: Intentions de Relation

### Description
> En tant qu'utilisateur, je veux indiquer ce que je recherche (relation sérieuse, mariage, etc.) pour matcher avec des personnes aux mêmes intentions.

### Critères d'Acceptation

| # | Critère | Obligatoire |
|---|---------|-------------|
| 1 | Je peux sélectionner mon intention parmi une liste | ✅ |
| 2 | L'intention est visible sur mon profil | ✅ |
| 3 | Je peux filtrer par intention dans Discover | ✅ |
| 4 | L'intention est demandée pendant l'onboarding | ✅ |
| 5 | Je peux modifier mon intention à tout moment | ✅ |

### Options d'Intentions

```
RELATIONSHIP_INTENTIONS = [
  {
    id: "marriage",
    label: "Mariage",
    icon: "ring",
    description: "Je cherche mon/ma futur(e) mari/femme"
  },
  {
    id: "serious",
    label: "Relation sérieuse",
    icon: "heart",
    description: "Je cherche une relation durable"
  },
  {
    id: "open",
    label: "Ouvert(e) à tout",
    icon: "sparkles",
    description: "On verra où ça nous mène"
  },
  {
    id: "friends_first",
    label: "Amitié d'abord",
    icon: "users",
    description: "Commençons par apprendre à se connaître"
  }
]
```

### Règles Métier

```
RULE-INT-01: Affichage
  - Badge coloré sur le profil avec l'icône
  - Couleurs: marriage=gold, serious=pink, open=blue, friends=green

RULE-INT-02: Matching
  - Suggestion prioritaire si mêmes intentions
  - Pas de blocage si intentions différentes (c'est un filtre soft)

RULE-INT-03: Statistiques
  - Afficher dans les analytics admin la répartition
```

### Tests - DOIT Passer ✅

```
TEST-INT-001: Sélectionner intention onboarding
  GIVEN: Je suis dans le flow d'onboarding
  WHEN: J'arrive à l'étape "Que recherches-tu ?"
  THEN: Je vois les 4 options
  WHEN: Je sélectionne "Relation sérieuse"
  AND: Je continue
  THEN: Mon profil affiche "Relation sérieuse"

TEST-INT-002: Filtrer par intention
  GIVEN: Je suis dans Discover
  WHEN: J'ouvre les filtres
  AND: Je sélectionne "Mariage uniquement"
  THEN: Je ne vois que les profils avec intention "Mariage"

TEST-INT-003: Modifier intention
  GIVEN: Mon intention est "Ouvert(e) à tout"
  WHEN: Je vais dans "Modifier profil"
  AND: Je change pour "Relation sérieuse"
  THEN: Mon profil est mis à jour immédiatement
```

### Modèle de Données

```sql
ALTER TABLE profiles ADD COLUMN relationship_intention VARCHAR(50);
```

---

# Phase 2 - Matching Intelligence

## US-MATCH-01: Score de Compatibilité

### Description
> En tant qu'utilisateur, je veux voir un score de compatibilité avec chaque profil pour savoir à quel point nous sommes compatibles.

### Critères d'Acceptation

| # | Critère | Obligatoire |
|---|---------|-------------|
| 1 | Un pourcentage de compatibilité est affiché sur chaque profil | ✅ |
| 2 | Le score est basé sur des critères objectifs et pondérés | ✅ |
| 3 | Les critères pris en compte sont transparents | ✅ |
| 4 | Le score va de 0% à 100% | ✅ |
| 5 | Un score > 80% affiche un badge "Très compatible" | ✅ |

### Algorithme de Score

```
COMPATIBILITY_WEIGHTS = {
  // Valeurs religieuses (40%)
  denomination_match: 15,        // Même courant religieux
  kashrut_compatibility: 10,     // Niveau kashrout compatible
  shabbat_compatibility: 10,     // Observance Shabbat compatible
  intention_match: 5,            // Mêmes intentions

  // Lifestyle (30%)
  age_preference: 10,            // Dans la tranche d'âge souhaitée
  distance: 10,                  // Proximité géographique
  verified_bonus: 5,             // Bonus si vérifié
  profile_completeness: 5,       // Profil complet

  // Engagement (30%)
  response_rate: 10,             // Taux de réponse aux messages
  activity_level: 10,            // Activité récente sur l'app
  bio_similarity: 10,            // Similarité des bios (embeddings)
}

TOTAL = 100%
```

### Règles de Calcul

```
RULE-SCORE-01: Calcul denomination_match (15 pts)
  - Identique: 15 pts
  - Compatible (Orthodox + Modern Orthodox): 10 pts
  - Différent mais même branche: 5 pts
  - Très différent: 0 pts

RULE-SCORE-02: Calcul kashrut_compatibility (10 pts)
  - Identique: 10 pts
  - Différence de 1 niveau: 7 pts
  - Différence de 2 niveaux: 3 pts
  - Très différent: 0 pts

RULE-SCORE-03: Calcul distance (10 pts)
  - < 10 km: 10 pts
  - 10-25 km: 8 pts
  - 25-50 km: 5 pts
  - 50-100 km: 2 pts
  - > 100 km: 0 pts

RULE-SCORE-04: Badge "Très compatible"
  - Score >= 80%: Badge gold "Très compatible ⭐"
  - Score >= 60%: Badge silver "Compatible"
  - Score < 60%: Pas de badge
```

### Tests - DOIT Passer ✅

```
TEST-SCORE-001: Affichage score
  GIVEN: Je vois le profil de "Sarah"
  AND: Notre score de compatibilité est 85%
  THEN: Je vois "85% compatible" sur son profil
  AND: Un badge "Très compatible ⭐"

TEST-SCORE-002: Score même religion
  GIVEN: Je suis "Modern Orthodox"
  AND: "David" est "Modern Orthodox"
  AND: Mêmes préférences kashrout et Shabbat
  THEN: Le score religion est au maximum

TEST-SCORE-003: Score distance
  GIVEN: Je suis à Paris
  AND: "Sarah" est à 8 km
  THEN: Le score distance est 10/10

TEST-SCORE-004: Pas de badge faible score
  GIVEN: Notre score est 45%
  THEN: Aucun badge n'est affiché
  BUT: Le pourcentage "45%" est visible
```

### Tests - NE DOIT PAS Arriver ❌

```
TEST-SCORE-ERR-001: Score > 100%
  GIVEN: Tous les critères sont parfaits
  THEN: Le score ne dépasse JAMAIS 100%

TEST-SCORE-ERR-002: Score négatif
  GIVEN: Aucun critère ne matche
  THEN: Le score est 0%, pas négatif

TEST-SCORE-ERR-003: Score sans données
  GIVEN: "Sarah" n'a pas rempli ses préférences religieuses
  THEN: Ces critères sont ignorés (pas pénalisés)
  AND: Le score est calculé sur les critères disponibles
```

---

## US-MATCH-02: Icebreakers Suggérés

### Description
> En tant qu'utilisateur, je veux recevoir des suggestions d'icebreakers quand je ne sais pas quoi écrire à un nouveau match.

### Critères d'Acceptation

| # | Critère | Obligatoire |
|---|---------|-------------|
| 1 | Quand j'ouvre une nouvelle conversation, des suggestions apparaissent | ✅ |
| 2 | Les suggestions sont personnalisées selon le profil de l'autre | ✅ |
| 3 | Je peux cliquer sur une suggestion pour l'utiliser | ✅ |
| 4 | Les suggestions disparaissent après le premier message | ✅ |
| 5 | Je peux rafraîchir pour avoir d'autres suggestions | ✅ |

### Types d'Icebreakers

```
ICEBREAKER_TEMPLATES = {
  // Basés sur les prompts
  prompt_based: [
    "J'ai adoré ta réponse sur {prompt_topic} ! {follow_up_question}",
    "Ton {prompt_topic} m'a fait sourire, tu peux m'en dire plus ?",
  ],

  // Basés sur les photos
  photo_based: [
    "Cette photo à {location} a l'air incroyable ! C'était quand ?",
    "J'adore ton style sur ta {n}ème photo !",
  ],

  // Basés sur les points communs
  common_ground: [
    "On dirait qu'on est tous les deux {common_interest} !",
    "Je vois qu'on a le même niveau de {religious_practice} !",
  ],

  // Génériques engageants
  generic: [
    "Si tu devais choisir un seul plat pour le reste de ta vie, ce serait quoi ?",
    "Café ou thé ? C'est important pour la suite 😄",
    "Quelle est la dernière chose qui t'a fait rire aux éclats ?",
    "Si tu pouvais dîner avec une personne, vivante ou morte, qui choisirais-tu ?",
  ],

  // Spécifiques judaïsme
  jewish_themed: [
    "C'est quoi ton meilleur souvenir de Shabbat en famille ?",
    "Quelle fête juive tu attends avec le plus d'impatience ?",
    "Tu préfères les latkes ou les sufganiyot à Hanouka ?",
  ]
}
```

### Règles Métier

```
RULE-ICE-01: Génération des suggestions
  1. D'abord chercher les prompts -> suggestion basée prompt
  2. Ensuite points communs -> suggestion basée commun
  3. Ensuite générique avec thème juif
  4. Fallback: génériques engageants

RULE-ICE-02: Affichage
  - 3 suggestions maximum
  - Affichées comme "chips" cliquables
  - Au-dessus du champ de saisie

RULE-ICE-03: Utilisation
  - Clic = texte copié dans le champ (modifiable)
  - Envoi = suggestions masquées définitivement
  - L'autre personne ne sait PAS que c'est une suggestion
```

### Tests - DOIT Passer ✅

```
TEST-ICE-001: Suggestions affichées
  GIVEN: Je viens de matcher avec "Sarah"
  WHEN: J'ouvre notre conversation
  THEN: Je vois 3 suggestions d'icebreakers
  AND: Le champ de message affiche "Écris ton message ou choisis une suggestion"

TEST-ICE-002: Suggestion basée sur prompt
  GIVEN: "Sarah" a le prompt "Mon Shabbat idéal: En famille avec chants"
  WHEN: Je vois les suggestions
  THEN: Une suggestion mentionne son Shabbat

TEST-ICE-003: Clic sur suggestion
  GIVEN: Je vois la suggestion "Café ou thé ?"
  WHEN: Je clique dessus
  THEN: Le texte est ajouté au champ de message
  AND: Je peux le modifier avant d'envoyer

TEST-ICE-004: Suggestions disparaissent
  GIVEN: J'ai envoyé mon premier message
  WHEN: Je reviens sur la conversation
  THEN: Les suggestions ne sont plus visibles

TEST-ICE-005: Rafraîchir suggestions
  GIVEN: Je vois 3 suggestions
  WHEN: Je clique sur "Autres idées"
  THEN: 3 nouvelles suggestions apparaissent
```

### Tests - NE DOIT PAS Arriver ❌

```
TEST-ICE-ERR-001: Suggestion révélée au match
  GIVEN: J'utilise une suggestion
  WHEN: "Sarah" reçoit mon message
  THEN: Elle ne voit PAS "Message suggéré" ou équivalent

TEST-ICE-ERR-002: Suggestions après conversation commencée
  GIVEN: On a déjà échangé 5 messages
  WHEN: J'ouvre la conversation
  THEN: Aucune suggestion n'apparaît

TEST-ICE-ERR-003: Mêmes suggestions tout le temps
  GIVEN: J'ouvre plusieurs nouvelles conversations
  THEN: Les suggestions varient d'une personne à l'autre
```

---

# Phase 3 - Couple Mode Enhanced

## US-COUPLE-01: Anniversaire MAZL

### Description
> En tant que couple, je veux recevoir une notification et célébration pour notre "anniversaire MAZL" (jour où on s'est matchés).

### Critères d'Acceptation

| # | Critère | Obligatoire |
|---|---------|-------------|
| 1 | La date du match est enregistrée automatiquement | ✅ |
| 2 | Une notification push est envoyée chaque anniversaire | ✅ |
| 3 | L'app affiche une animation spéciale ce jour-là | ✅ |
| 4 | Le couple peut partager leur "anniversary card" | ✅ |
| 5 | Les milestones sont célébrées (1 mois, 6 mois, 1 an...) | ✅ |

### Milestones

```
COUPLE_MILESTONES = [
  { days: 7, label: "1 semaine", icon: "seedling" },
  { days: 30, label: "1 mois", icon: "heart" },
  { days: 90, label: "3 mois", icon: "star" },
  { days: 180, label: "6 mois", icon: "fire" },
  { days: 365, label: "1 an", icon: "crown", special: true },
  { days: 730, label: "2 ans", icon: "diamond", special: true },
]
```

### Tests - DOIT Passer ✅

```
TEST-ANNIV-001: Notification anniversaire
  GIVEN: On s'est matchés le 15 janvier 2025
  WHEN: C'est le 15 janvier 2026
  THEN: Les deux partenaires reçoivent une notification
  AND: "1 an ensemble sur MAZL ! 🎉"

TEST-ANNIV-002: Animation spéciale
  GIVEN: C'est notre anniversaire MAZL
  WHEN: J'ouvre l'app
  THEN: Une animation de confettis/coeurs apparaît
  AND: Un message "Joyeux anniversaire MAZL !"

TEST-ANNIV-003: Card partageable
  GIVEN: C'est notre anniversaire
  WHEN: Je clique sur "Partager"
  THEN: Une image est générée avec nos photos et "X jours ensemble"
  AND: Je peux la partager sur Instagram/WhatsApp
```

---

## US-COUPLE-02: Success Story

### Description
> En tant que couple, je veux partager notre success story pour inspirer la communauté MAZL.

### Critères d'Acceptation

| # | Critère | Obligatoire |
|---|---------|-------------|
| 1 | Je peux soumettre notre histoire depuis les paramètres couple | ✅ |
| 2 | Je peux ajouter des photos de couple | ✅ |
| 3 | L'histoire est modérée avant publication | ✅ |
| 4 | Les success stories sont visibles sur l'app (section dédiée) | ✅ |
| 5 | Je peux indiquer si on est fiancés/mariés | ✅ |

### Tests - DOIT Passer ✅

```
TEST-SUCCESS-001: Soumettre histoire
  GIVEN: Je suis en couple mode
  WHEN: Je vais dans "Partager notre histoire"
  AND: J'écris notre histoire (min 100 caractères)
  AND: J'ajoute 1-3 photos
  AND: Je soumets
  THEN: Message "Merci ! Votre histoire sera publiée après validation."

TEST-SUCCESS-002: Statut fiancés/mariés
  GIVEN: Je soumets notre histoire
  WHEN: J'indique "Mariés" et la date
  THEN: L'histoire affichera "Mariés depuis {date}"
  AND: Badge spécial "💍 Mariés grâce à MAZL"

TEST-SUCCESS-003: Voir les success stories
  GIVEN: Je suis sur l'écran d'accueil ou profil
  WHEN: Je clique sur "Success Stories"
  THEN: Je vois les histoires de couples approuvées
  AND: Je peux les liker et partager
```

---

# Phase 3 - Premium Features

## US-PREM-02: Boost

### Description
> En tant qu'utilisateur premium, je veux "booster" mon profil pour être vu par plus de personnes pendant une durée limitée.

### Critères d'Acceptation

| # | Critère | Obligatoire |
|---|---------|-------------|
| 1 | Un bouton "Boost" est accessible depuis mon profil | ✅ |
| 2 | Le boost dure 30 minutes | ✅ |
| 3 | Pendant le boost, mon profil apparaît en priorité dans Discover | ✅ |
| 4 | Je reçois des stats après le boost (vues, likes reçus) | ✅ |
| 5 | Premium: 1 boost gratuit par semaine | ✅ |
| 6 | Free: peut acheter des boosts (achat in-app) | ✅ |
| 7 | Un indicateur visuel montre le boost en cours | ✅ |

### Règles Métier

```
RULE-BOOST-01: Priorité affichage
  - Profils boostés apparaissent dans les 10 premiers de Discover
  - Si plusieurs boosts actifs: rotation aléatoire
  - Pas de boost visible si déjà passé/liké

RULE-BOOST-02: Fréquence
  - Premium: 1 gratuit / 7 jours
  - Achat: packs de 3, 5, 10 boosts
  - Max 1 boost actif à la fois

RULE-BOOST-03: Stats
  - Compteur temps restant visible
  - Notification fin de boost avec stats
  - Stats: vues profil, likes reçus, taux vs normal
```

### Tests - DOIT Passer ✅

```
TEST-BOOST-001: Activer boost
  GIVEN: Je suis premium avec 1 boost disponible
  WHEN: Je clique sur "Boost mon profil"
  AND: Je confirme
  THEN: Timer "29:59" apparaît
  AND: Mon profil a un indicateur "Boosté ⚡"

TEST-BOOST-002: Priorité Discover
  GIVEN: Mon profil est boosté
  WHEN: D'autres utilisateurs ouvrent Discover
  THEN: Je suis parmi les 10 premiers profils montrés
  (si je corresponds à leurs critères)

TEST-BOOST-003: Stats fin de boost
  GIVEN: Mon boost vient de se terminer
  THEN: Je reçois une notification
  AND: "Boost terminé ! 45 personnes ont vu ton profil, 5 likes reçus."

TEST-BOOST-004: Boost hebdo reset
  GIVEN: J'ai utilisé mon boost gratuit lundi
  WHEN: C'est le lundi suivant
  THEN: J'ai à nouveau 1 boost gratuit disponible
```

### Tests - NE DOIT PAS Arriver ❌

```
TEST-BOOST-ERR-001: Double boost
  GIVEN: J'ai un boost actif
  WHEN: J'essaie d'en activer un autre
  THEN: Message "Tu as déjà un boost en cours"

TEST-BOOST-ERR-002: Boost sans disponible
  GIVEN: Je suis premium sans boost disponible cette semaine
  WHEN: Je clique sur Boost
  THEN: "Boost utilisé. Prochain gratuit dans X jours" ou option d'achat
```

---

## US-PREM-03: Qui a Visité Mon Profil

### Description
> En tant qu'utilisateur premium, je veux voir qui a visité mon profil.

### Critères d'Acceptation

| # | Critère | Obligatoire |
|---|---------|-------------|
| 1 | Une section "Visiteurs" montre qui a vu mon profil | ✅ |
| 2 | Premium voit la liste complète avec photos | ✅ |
| 3 | Free voit le nombre mais pas les détails | ✅ |
| 4 | Les visiteurs sont triés par date (plus récent d'abord) | ✅ |
| 5 | Je peux liker directement depuis la liste des visiteurs | ✅ |
| 6 | Les visites expirent après 7 jours | ✅ |

### Règles Métier

```
RULE-VISIT-01: Comptage visite
  - Une visite = rester plus de 3 secondes sur un profil
  - Max 1 visite comptée par personne par 24h

RULE-VISIT-02: Confidentialité
  - L'utilisateur visité ne sait pas QUAND exactement
  - Juste "a visité récemment"

RULE-VISIT-03: Expiration
  - Les visites sont supprimées après 7 jours
  - Historique non conservé (RGPD)
```

### Tests - DOIT Passer ✅

```
TEST-VISIT-001: Voir mes visiteurs (premium)
  GIVEN: Je suis premium
  AND: 5 personnes ont visité mon profil
  WHEN: Je vais dans "Visiteurs"
  THEN: Je vois 5 profils avec photos et prénoms

TEST-VISIT-002: Vue free
  GIVEN: Je suis free
  AND: 5 personnes ont visité
  WHEN: Je vais dans "Visiteurs"
  THEN: Je vois "5 personnes ont visité ton profil"
  AND: Bouton "Voir qui - Passer Premium"

TEST-VISIT-003: Liker depuis visiteurs
  GIVEN: Je suis premium dans la liste visiteurs
  WHEN: Je like "Sarah" depuis cette vue
  THEN: C'est un swipe like normal
  AND: Si elle m'avait liké, c'est un match
```

---

# Annexes

## A. Modèle de Données Complet

```sql
-- Voir chaque US pour les tables spécifiques

-- Index de performance recommandés
CREATE INDEX idx_swipes_composite ON swipes(user_id, target_user_id, action);
CREATE INDEX idx_matches_users ON matches(user1_id, user2_id);
CREATE INDEX idx_messages_conversation ON messages(conversation_id, created_at);
CREATE INDEX idx_profile_prompts_user ON profile_prompts(user_id);
CREATE INDEX idx_blocked_users_both ON blocked_users(blocker_id, blocked_id);
CREATE INDEX idx_reports_status_severity ON reports(status, severity);
CREATE INDEX idx_profile_visits_target ON profile_visits(visited_user_id, visited_at);
CREATE INDEX idx_boosts_active ON profile_boosts(user_id, ends_at) WHERE ends_at > NOW();
```

## B. Checklist Avant Déploiement

Pour chaque User Story, vérifier :

- [ ] Tous les tests "DOIT Passer" passent
- [ ] Tous les tests "NE DOIT PAS" sont couverts
- [ ] Les règles métier sont implémentées
- [ ] Les endpoints API sont documentés
- [ ] Les migrations DB sont prêtes
- [ ] La feature est testée sur iOS ET Android
- [ ] Les textes sont en français correct
- [ ] Les erreurs ont des messages user-friendly
- [ ] Analytics/tracking en place
- [ ] Performance acceptable (< 500ms)

## C. Priorité d'Implémentation

### Sprint 1 (Trust & Safety + Core)
1. US-TS-01: Blocage ⭐
2. US-TS-02: Signalement ⭐
3. US-TS-03: Vérification Photo
4. US-PREM-01: Likes Floutés ⭐

### Sprint 2 (Engagement)
5. US-PROF-01: Prompts de Profil ⭐
6. US-PROF-02: Intentions
7. US-MATCH-02: Icebreakers

### Sprint 3 (Intelligence)
8. US-MATCH-01: Score Compatibilité
9. US-PREM-02: Boost
10. US-PREM-03: Visiteurs

### Sprint 4 (Couple)
11. US-COUPLE-01: Anniversaire MAZL
12. US-COUPLE-02: Success Stories

---

> **Note**: Ce document est vivant. Mettre à jour après chaque implémentation.
> Dernière mise à jour: 2026-01-17
> ✅ **TOUTES LES USER STORIES SONT IMPLÉMENTÉES !**
