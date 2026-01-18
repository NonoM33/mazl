# PRD - Mode Couple MAZL

## Vision

Quand deux utilisateurs forment un couple sur MAZL, l'application se transforme complètement. Exit le swipe de profils, place à une expérience dédiée pour **nourrir et enrichir la relation**. L'app devient un compagnon de couple juif moderne.

---

## Navigation Mode Couple

| Onglet | Nom | Description |
|--------|-----|-------------|
| 1 | **Activités** | Feed d'activités/expériences à faire en couple |
| 2 | **Calendrier** | Calendrier juif + planning couple |
| 3 | **Événements** | Événements réservés aux couples |
| 4 | **Notre Espace** | Profil couple + paramètres |

---

## Onglet 1: Activités (Feed Principal)

### Concept
Un feed swipable d'**activités et expériences** à faire en couple, présentées sous forme de cartes attractives (comme les profils, mais pour des activités).

### Types d'Activités

| Catégorie | Exemples | Icône |
|-----------|----------|-------|
| **Bien-être** | Spa en duo, massage couple, hammam | 🧖‍♀️ |
| **Gastronomie** | Restaurant romantique, cours de cuisine, dégustation vin | 🍷 |
| **Culture** | Musée, exposition, concert, théâtre | 🎭 |
| **Sport** | Yoga duo, randonnée, danse | 💃 |
| **Voyage** | Week-end getaway, escapade shabbat | ✈️ |
| **Spirituel** | Étude Torah en couple, cours Tanya, prépa Shabbat | 📖 |
| **DIY** | Atelier poterie, peinture, cuisine challah | 🎨 |
| **Romantique** | Pique-nique, coucher soleil, dîner aux chandelles | 💕 |

### Structure d'une Carte Activité

```
┌─────────────────────────────────┐
│  [Photo/Image activité]         │
│                                 │
│  ┌─────────────────────────────┐│
│  │ 🧖‍♀️ Spa Cinq Mondes         ││
│  │ Massage duo 1h30            ││
│  │ 📍 Paris 8ème • 4.8⭐        ││
│  │ 💰 180€/couple              ││
│  │ ⏰ Dispo ce week-end        ││
│  └─────────────────────────────┘│
├─────────────────────────────────┤
│  [❌]     [🔖]     [💝]        │
│  Passer   Sauver   Réserver    │
└─────────────────────────────────┘
```

### Actions sur les Cartes

| Action | Geste | Effet |
|--------|-------|-------|
| **Passer** | Swipe gauche / ❌ | Masquer cette activité |
| **Sauver** | Swipe haut / 🔖 | Ajouter aux favoris |
| **Réserver** | Swipe droit / 💝 | Ouvrir détails + réservation |

### Filtres Activités

- Par catégorie (bien-être, gastro, culture...)
- Par budget (€, €€, €€€)
- Par distance
- Par disponibilité (ce soir, ce week-end, cette semaine)
- Casher only (pour restaurants)

### Sources de Données

1. **Partenaires MAZL** - Offres exclusives négociées
2. **API externes** - TheFork, Treatwell, Eventbrite
3. **Contenu éditorial** - Idées d'activités maison
4. **User Generated** - Suggestions de la communauté

---

## Onglet 2: Calendrier Juif & Couple

### Concept
Un calendrier intelligent qui combine:
- Les fêtes juives et leurs traditions
- Le planning du couple (anniversaires, dates importantes)
- Les activités réservées/sauvegardées

### Fonctionnalités

#### Calendrier Hébraïque
- Affichage date hébraïque / grégorienne
- Horaires Shabbat (entrée/sortie) selon localisation
- Fêtes juives avec explications
- Compte à rebours vers prochaines fêtes

#### Dates Importantes Couple
- Anniversaire de rencontre (auto-détecté: date du match)
- Anniversaire de couple (modifiable)
- Date de fiançailles (si renseigné)
- Date de mariage (si renseigné)
- Rappels personnalisés

#### Planning Activités
- Activités réservées
- Événements auxquels ils participent
- Rappels automatiques

### Vue Mensuelle

```
┌─────────────────────────────────┐
│     ◀  Janvier 2026  ▶         │
│        Tevet - Shevat          │
├─────────────────────────────────┤
│ L   M   M   J   V   S   D      │
│         1   2   3   4   5      │
│                     🕯️  ✡️      │
│ 6   7   8   9  10  11  12     │
│             💝                  │
│ ...                             │
├─────────────────────────────────┤
│ 🕯️ Shabbat Shalom              │
│    Entrée: 17:42 • Sortie: 18:51│
├─────────────────────────────────┤
│ 💝 10 Jan - Notre anniversaire! │
│    1 an ensemble               │
└─────────────────────────────────┘
```

---

## Onglet 3: Événements Couples

### Concept
Des événements **exclusivement pour couples** - pas les mêmes que le mode solo!

### Types d'Événements Couple

| Type | Description | Exemple |
|------|-------------|---------|
| **Dîners couples** | Tables de 4-8 couples | Shabbat dinner couples |
| **Voyages organisés** | Week-ends/séjours groupe | Week-end à Deauville |
| **Ateliers couple** | Activités en groupe | Cours de danse latine |
| **Soirées thématiques** | Events festifs | Soirée années 80 |
| **Retraites spirituelles** | Séminaires Torah | Shabbaton couples |
| **Wine & Dine** | Dégustation | Soirée vins casher |

### Différences avec Events Solo

| Aspect | Mode Solo | Mode Couple |
|--------|-----------|-------------|
| Inscription | Individuelle | Par couple (1 place = 2 personnes) |
| Prix | Par personne | Par couple |
| Ambiance | Networking/rencontres | Partage entre couples |
| Objectif | Trouver quelqu'un | Enrichir sa relation |

### Structure Carte Événement Couple

```
┌─────────────────────────────────┐
│  [Photo événement]              │
│                          👫x12  │
│  ┌─────────────────────────────┐│
│  │ 🍷 Wine & Cheese Couples    ││
│  │ Dégustation vins casher     ││
│  │ 📅 Sam 25 Jan • 20h00       ││
│  │ 📍 Cave du Marais, Paris 4  ││
│  │ 💰 85€/couple               ││
│  │ 👫 12 couples max           ││
│  └─────────────────────────────┘│
├─────────────────────────────────┤
│     [ Réserver pour nous ]      │
└─────────────────────────────────┘
```

---

## Onglet 4: Notre Espace

### Concept
L'espace privé du couple - leur "nid" dans l'app.

### Sections

#### 1. Profil Couple
```
┌─────────────────────────────────┐
│    [Photo lui] 💕 [Photo elle]  │
│                                 │
│      David & Sarah              │
│    Ensemble depuis 1 an         │
│    "On s'est rencontrés sur     │
│     MAZL le 10 janvier 2025"    │
├─────────────────────────────────┤
│  📸 Notre galerie (12 photos)   │
│  ✏️ Modifier notre profil       │
└─────────────────────────────────┘
```

#### 2. Nos Souvenirs
- Galerie photos privée
- Journal de bord (notes, moments)
- Timeline de la relation
- Badges/achievements ("1 an ensemble", "10 events", etc.)

#### 3. Nos Favoris
- Activités sauvegardées
- Lieux préférés
- Liste de souhaits ("bucket list couple")

#### 4. Statistiques Couple
- Nombre d'activités faites ensemble
- Événements auxquels ils ont participé
- Kilomètres parcourus ensemble
- "Compatibilité MAZL" (fun stat)

#### 5. Paramètres
- Notifications couple
- Confidentialité
- Désactiver mode couple (retour au dating)
- Partager notre histoire (success story)

---

## Écran Dashboard Couple (Home)

### Concept
L'écran d'accueil quand on ouvre l'app en mode couple.

```
┌─────────────────────────────────┐
│  Bonjour David & Sarah 💕       │
│  Ensemble depuis 365 jours      │
├─────────────────────────────────┤
│  🕯️ Shabbat dans 2 jours        │
│     Entrée: Ven 17:42           │
├─────────────────────────────────┤
│  💡 Idée du jour                │
│  ┌─────────────────────────────┐│
│  │ [Photo spa]                 ││
│  │ Massage duo au Spa Nuxe    ││
│  │ -20% avec MAZL              ││
│  │      [ Découvrir ]          ││
│  └─────────────────────────────┘│
├─────────────────────────────────┤
│  📅 À venir                     │
│  • Dim 26 - Brunch couples     │
│  • Ven 31 - Shabbat spécial    │
├─────────────────────────────────┤
│  🔥 Streak: 12 jours            │
│  Vous vous êtes connectés       │
│  ensemble 12 jours de suite!    │
└─────────────────────────────────┘
```

---

## Données & API Backend

### Nouvelles Tables

```sql
-- Activités couple
CREATE TABLE couple_activities (
  id SERIAL PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  category VARCHAR(50), -- wellness, gastro, culture, etc.
  image_url TEXT,
  price_cents INTEGER,
  location VARCHAR(255),
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  rating DECIMAL(2, 1),
  is_kosher BOOLEAN DEFAULT false,
  is_partner BOOLEAN DEFAULT false, -- partenaire MAZL
  discount_percent INTEGER,
  booking_url TEXT,
  available_from DATE,
  available_to DATE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Activités sauvegardées par couple
CREATE TABLE couple_saved_activities (
  couple_id INTEGER REFERENCES couples(id),
  activity_id INTEGER REFERENCES couple_activities(id),
  saved_at TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (couple_id, activity_id)
);

-- Activités passées (swipe left)
CREATE TABLE couple_passed_activities (
  couple_id INTEGER REFERENCES couples(id),
  activity_id INTEGER REFERENCES couple_activities(id),
  passed_at TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (couple_id, activity_id)
);

-- Réservations couple
CREATE TABLE couple_bookings (
  id SERIAL PRIMARY KEY,
  couple_id INTEGER REFERENCES couples(id),
  activity_id INTEGER,
  event_id INTEGER,
  booking_date DATE,
  status VARCHAR(20) DEFAULT 'confirmed',
  created_at TIMESTAMP DEFAULT NOW()
);

-- Événements couple (différent de events solo)
CREATE TABLE couple_events (
  id SERIAL PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  image_url TEXT,
  event_date TIMESTAMP,
  location VARCHAR(255),
  price_cents INTEGER, -- prix par couple
  max_couples INTEGER,
  current_couples INTEGER DEFAULT 0,
  category VARCHAR(50),
  created_at TIMESTAMP DEFAULT NOW()
);

-- Inscriptions événements couple
CREATE TABLE couple_event_registrations (
  couple_id INTEGER REFERENCES couples(id),
  event_id INTEGER REFERENCES couple_events(id),
  registered_at TIMESTAMP DEFAULT NOW(),
  status VARCHAR(20) DEFAULT 'registered',
  PRIMARY KEY (couple_id, event_id)
);

-- Souvenirs couple
CREATE TABLE couple_memories (
  id SERIAL PRIMARY KEY,
  couple_id INTEGER REFERENCES couples(id),
  type VARCHAR(20), -- photo, note, milestone
  content TEXT,
  image_url TEXT,
  memory_date DATE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Dates importantes couple
CREATE TABLE couple_dates (
  id SERIAL PRIMARY KEY,
  couple_id INTEGER REFERENCES couples(id),
  title VARCHAR(255),
  date DATE,
  type VARCHAR(50), -- anniversary, engagement, wedding, custom
  remind_before_days INTEGER DEFAULT 7,
  created_at TIMESTAMP DEFAULT NOW()
);
```

### Nouveaux Endpoints API

```
# Activités
GET  /api/couple/activities              # Feed d'activités
POST /api/couple/activities/:id/save     # Sauvegarder
POST /api/couple/activities/:id/pass     # Passer
POST /api/couple/activities/:id/book     # Réserver

# Événements couple
GET  /api/couple/events                  # Liste événements couple
POST /api/couple/events/:id/register     # S'inscrire
DELETE /api/couple/events/:id/register   # Se désinscrire

# Calendrier
GET  /api/couple/calendar                # Données calendrier
GET  /api/couple/calendar/jewish         # Fêtes juives
POST /api/couple/dates                   # Ajouter date importante
PUT  /api/couple/dates/:id               # Modifier
DELETE /api/couple/dates/:id             # Supprimer

# Espace couple
GET  /api/couple/profile                 # Profil couple
PUT  /api/couple/profile                 # Modifier profil
GET  /api/couple/memories                # Souvenirs
POST /api/couple/memories                # Ajouter souvenir
GET  /api/couple/stats                   # Statistiques

# Favoris
GET  /api/couple/favorites               # Activités sauvegardées
DELETE /api/couple/favorites/:id         # Retirer des favoris
```

---

## Écrans Mobile à Créer

| Écran | Chemin | Description |
|-------|--------|-------------|
| `CoupleActivitiesFeedScreen` | `/couple/activities` | Feed swipable d'activités |
| `CoupleActivityDetailScreen` | `/couple/activities/:id` | Détail + réservation |
| `CoupleCalendarScreen` | `/couple/calendar` | Calendrier juif + couple |
| `CoupleEventsScreen` | `/couple/events` | Liste événements couples |
| `CoupleEventDetailScreen` | `/couple/events/:id` | Détail événement |
| `CoupleSpaceScreen` | `/couple/space` | Notre espace (profil couple) |
| `CoupleMemoriesScreen` | `/couple/memories` | Galerie souvenirs |
| `CoupleFavoritesScreen` | `/couple/favorites` | Activités sauvegardées |
| `CoupleSettingsScreen` | `/couple/settings` | Paramètres couple |

---

## Résumé Navigation Finale

```
Mode Couple Navigation:
├── 💝 Activités (Feed swipable)
│   ├── Détail activité
│   └── Réservation
├── 📅 Calendrier
│   ├── Vue mensuelle
│   ├── Fêtes juives
│   └── Dates couple
├── 🎉 Événements
│   ├── Liste événements couples
│   └── Détail + inscription
└── 🏠 Notre Espace
    ├── Profil couple
    ├── Souvenirs
    ├── Favoris
    └── Paramètres
```

---

## Priorités d'Implémentation

### Phase 1 - MVP
1. Navigation 4 onglets
2. Feed activités (données statiques)
3. Détail activité
4. Liste événements couple
5. Profil couple basique

### Phase 2 - Core Features
1. Calendrier juif intégré
2. Système de réservation
3. Favoris/sauvegarde
4. Dates importantes

### Phase 3 - Engagement
1. Souvenirs/galerie
2. Statistiques couple
3. Streak/gamification
4. Notifications intelligentes

### Phase 4 - Monétisation
1. Partenariats activités
2. Offres exclusives MAZL
3. Events premium

---

## KPIs Mode Couple

| Métrique | Description |
|----------|-------------|
| Couples actifs | Couples utilisant l'app/semaine |
| Activités vues | Nombre de cartes swipées |
| Taux de sauvegarde | % activités sauvegardées |
| Taux de réservation | % activités réservées |
| Événements/couple | Moyenne d'events par couple |
| Rétention couple | % couples actifs après 30j |
| NPS couple | Satisfaction mode couple |
