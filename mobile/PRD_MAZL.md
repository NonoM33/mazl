# MAZL - Product Requirements Document (PRD)

> **Version**: 1.0
> **Date**: 2026-01-17
> **Statut**: Draft - En cours de revue

---

## 1. Vision Produit

### 1.1 Mission
MAZL est une application de rencontre premium conçue exclusivement pour la communauté juive, combinant des algorithmes de matching intelligents avec des fonctionnalités culturelles juives uniques.

### 1.2 Proposition de Valeur
- **Pour les célibataires juifs** : Trouver un partenaire partageant les mêmes valeurs religieuses et culturelles
- **Pour les couples** : Maintenir et célébrer leur relation avec des outils dédiés
- **Différenciateur** : Mode Shabbat, calendrier juif, compatibilité religieuse, AI Shadchan

### 1.3 Public Cible
| Segment | Description | % Estimé |
|---------|-------------|----------|
| Traditionalistes | Juifs observants cherchant mariage | 35% |
| Modernes | Juifs culturels, moins pratiquants | 40% |
| Curieux | Intéressés par la culture juive | 15% |
| Couples | Déjà en relation, mode couple | 10% |

---

## 2. Fonctionnalités Existantes

### 2.1 Authentification & Onboarding
| Fonctionnalité | Statut | Notes |
|----------------|--------|-------|
| Google Sign-In | ✅ | Implémenté |
| Apple Sign-In | ✅ | Implémenté |
| Onboarding carousel | ✅ | 5 pages |
| Profile setup wizard | ✅ | Multi-étapes |

### 2.2 Découverte & Matching
| Fonctionnalité | Statut | Notes |
|----------------|--------|-------|
| Swipe cards | ✅ | flutter_card_swiper |
| Like/Pass/Super Like | ✅ | Actions de base |
| Filtres (âge, distance) | ✅ | Dans Discover |
| Score de compatibilité | ✅ | 0-100%, multi-facteurs |
| Icebreakers suggérés | ✅ | Basés sur profil |
| AI Shadchan | ✅ | Suggestions quotidiennes |

### 2.3 Profil
| Fonctionnalité | Statut | Notes |
|----------------|--------|-------|
| Photos multiples | ✅ | Réordonnables |
| Bio | ✅ | Texte libre |
| Dénomination juive | ✅ | Orthodox, Reform, etc. |
| Niveau Kashrout | ✅ | Multiple niveaux |
| Observance Shabbat | ✅ | Multiple niveaux |
| Intention relationnelle | ✅ | 4 options |
| Prompts de profil | ✅ | Max 3, 150 chars |
| Badge vérifié | ✅ | Après vérification selfie |

### 2.4 Communication
| Fonctionnalité | Statut | Notes |
|----------------|--------|-------|
| Chat temps réel | ✅ | WebSocket |
| Liste conversations | ✅ | Avec aperçu |
| Indicateur de frappe | ✅ | Temps réel |
| Statut lu/non-lu | ✅ | |
| Appel vidéo | ✅ | Agora RTC |

### 2.5 Trust & Safety
| Fonctionnalité | Statut | Notes |
|----------------|--------|-------|
| Blocage utilisateur | ✅ | Silencieux, mutuel |
| Signalement | ✅ | 7 catégories |
| Vérification photo | ✅ | Geste aléatoire |
| Liste utilisateurs bloqués | ✅ | Déblocage possible |

### 2.6 Premium
| Fonctionnalité | Statut | Notes |
|----------------|--------|-------|
| Abonnement (RevenueCat) | ✅ | Monthly/6mo/Yearly |
| Likes floutés | ✅ | Clear pour premium |
| Qui a visité mon profil | ✅ | Premium only |
| Boost profil | ✅ | 30 min, stats |

### 2.7 Mode Couple
| Fonctionnalité | Statut | Notes |
|----------------|--------|-------|
| Dashboard couple | ✅ | Activités, milestones |
| Demande de couple | ✅ | Envoi/acceptation |
| Anniversaire MAZL | ✅ | Notifications, cartes |
| Success stories | ✅ | Soumission, affichage |
| Calendrier juif | ✅ | Fêtes, Shabbat |
| Mode Shabbat | ✅ | Pause automatique |

### 2.8 Événements
| Fonctionnalité | Statut | Notes |
|----------------|--------|-------|
| Liste événements | ✅ | Browse |
| Détail événement | ✅ | Infos complètes |

---

## 3. ANALYSE DES LACUNES (GAPS)

### 🔴 3.1 Lacunes Critiques (Bloquantes pour le lancement)

#### GAP-01: Pas d'inscription par email/téléphone
**Problème**: Seuls Google/Apple Sign-In disponibles
**Impact**: Exclut les utilisateurs sans compte Google/Apple ou qui préfèrent email
**Recommandation**: Ajouter email/password + vérification téléphone (SMS OTP)

#### GAP-02: Pas de gestion des photos (upload)
**Problème**: L'UI existe mais pas de vrai upload vers backend
**Impact**: Les utilisateurs ne peuvent pas vraiment ajouter des photos
**Recommandation**: Intégrer Cloudinary ou AWS S3 pour le stockage

#### GAP-03: Pas de notifications push
**Problème**: Service OneSignal déclaré mais pas implémenté côté mobile
**Impact**: Pas de notifications pour matches, messages, likes
**Recommandation**: Implémenter OneSignal SDK complet

#### GAP-04: Pas de récupération de mot de passe
**Problème**: Flow "forgot password" inexistant
**Impact**: Utilisateurs bloqués si problème de connexion
**Recommandation**: Implémenter reset par email

#### GAP-05: Pas de suppression de compte (RGPD)
**Problème**: Impossible de supprimer son compte
**Impact**: Non-conformité RGPD, App Store rejet possible
**Recommandation**: Ajouter "Supprimer mon compte" dans Settings

### 🟠 3.2 Lacunes Importantes (Impact UX significatif)

#### GAP-06: Pas de système de "Super Like"
**Problème**: Le Super Like est mentionné mais pas implémenté
**Impact**: Fonctionnalité premium attendue manquante
**Recommandation**: Implémenter Super Like avec limite quotidienne

#### GAP-07: Pas de "Rewind" (annuler swipe)
**Problème**: Impossible d'annuler un swipe accidentel
**Impact**: Frustration utilisateur si swipe gauche par erreur
**Recommandation**: Ajouter Rewind (premium ou limite gratuite)

#### GAP-08: Pas de lecture des messages (seen/delivered)
**Problème**: Statut lu affiché mais pas de "vu à [heure]"
**Impact**: Incertitude sur la lecture des messages
**Recommandation**: Ajouter timestamps de lecture

#### GAP-09: Pas d'envoi de photos/médias dans le chat
**Problème**: Uniquement texte dans les messages
**Impact**: Communication limitée
**Recommandation**: Ajouter envoi photos/GIFs/emojis

#### GAP-10: Pas de recherche de conversations
**Problème**: Pas de search dans les chats
**Impact**: Difficile de retrouver des messages
**Recommandation**: Ajouter barre de recherche

#### GAP-11: Pas de filtres avancés de découverte
**Problème**: Seulement âge et distance
**Impact**: Matching moins précis
**Recommandation**: Filtres par religion, kashrout, intention, vérifié

#### GAP-12: Pas d'incognito/mode invisible
**Problème**: Pas de mode pour cacher son profil temporairement
**Impact**: Pas de contrôle de visibilité
**Recommandation**: Ajouter "Pause mon profil" ou mode invisible premium

#### GAP-13: Pas de "Match Queue" ou Daily Picks
**Problème**: AI Shadchan existe mais pas de vraie queue quotidienne
**Impact**: Moins d'engagement quotidien
**Recommandation**: X suggestions gratuites/jour, plus pour premium

### 🟡 3.3 Lacunes Mineures (Nice to have)

#### GAP-14: Pas de réactions aux messages
**Problème**: Impossible de réagir (❤️, 😂, etc.)
**Impact**: Interaction limitée
**Recommandation**: Ajouter réactions style iMessage

#### GAP-15: Pas de messages vocaux
**Problème**: Pas d'audio dans le chat
**Impact**: Communication moins riche
**Recommandation**: Ajouter notes vocales

#### GAP-16: Pas de partage de localisation
**Problème**: Pas de partage live location pour date
**Impact**: Organisation de rendez-vous moins fluide
**Recommandation**: Partage de lieu temporaire

#### GAP-17: Pas de mode "Spotlight" ou "Top Picks"
**Problème**: Pas de section profils populaires
**Impact**: Moins de découverte
**Recommandation**: Section "Populaires cette semaine"

#### GAP-18: Pas de badges/achievements
**Problème**: Pas de gamification
**Impact**: Engagement moindre
**Recommandation**: Badges pour profil complet, vérifié, réponses rapides

#### GAP-19: Pas de "Undo" pour blocage
**Problème**: Blocage définitif sans délai de réflexion
**Impact**: Erreurs de blocage
**Recommandation**: "Annuler" pendant 5 secondes après blocage

#### GAP-20: Pas de statistiques de profil
**Problème**: L'utilisateur ne voit pas ses stats
**Impact**: Pas de feedback sur performance profil
**Recommandation**: Dashboard: vues, likes reçus, taux de match

### 🔵 3.4 Lacunes Spécifiques au Marché Juif

#### GAP-21: Pas de vérification communautaire
**Problème**: Pas de validation par rabbin ou communauté
**Impact**: Moins de confiance
**Recommandation**: Badge "Vérifié par [communauté]"

#### GAP-22: Pas de matchmaking assisté
**Problème**: AI Shadchan automatique seulement
**Impact**: Certains préfèrent un vrai shadchan
**Recommandation**: Option de mise en relation par des matchmakers humains

#### GAP-23: Pas d'intégration avec événements communautaires
**Problème**: Événements génériques, pas liés aux synagogues
**Impact**: Moins de valeur pour la communauté
**Recommandation**: Partenariats avec communautés locales

#### GAP-24: Pas de preference d'origine (Ashkenaze/Sépharade)
**Problème**: Pas de filtre origine
**Impact**: Important pour certains utilisateurs
**Recommandation**: Ajouter champ origine avec filtre optionnel

#### GAP-25: Pas de compatibilité alimentaire détaillée
**Problème**: Kashrout basique (oui/non)
**Impact**: Nuances importantes ignorées
**Recommandation**: Niveaux: Glatt, Mehadrin, Beth Din, Traditionnel, Non

---

## 4. USER STORIES MANQUANTES PROPOSÉES

### Phase 1 - Critiques (Sprint 1-2)

```
US-AUTH-01: Inscription Email/Password
En tant qu'utilisateur, je veux pouvoir m'inscrire avec mon email et un mot de passe
pour ne pas dépendre de Google/Apple.

Critères d'acceptation:
- Formulaire email + password (min 8 chars, 1 majuscule, 1 chiffre)
- Vérification email (code à 6 chiffres)
- Password strength indicator
- Terms & Conditions checkbox

US-AUTH-02: Vérification Téléphone
En tant qu'utilisateur, je veux vérifier mon numéro de téléphone
pour prouver que je suis une vraie personne.

Critères d'acceptation:
- Input numéro avec indicatif pays
- SMS OTP (6 chiffres, expire 5 min)
- Rate limiting (3 essais/heure)
- Badge "Téléphone vérifié"

US-AUTH-03: Récupération Mot de Passe
En tant qu'utilisateur, je veux pouvoir réinitialiser mon mot de passe
si je l'oublie.

Critères d'acceptation:
- "Mot de passe oublié" sur écran login
- Email avec lien/code de reset
- Nouveau mot de passe avec confirmation
- Expiration du lien (24h)

US-RGPD-01: Suppression de Compte
En tant qu'utilisateur, je veux pouvoir supprimer définitivement mon compte
pour exercer mon droit à l'oubli (RGPD).

Critères d'acceptation:
- Option dans Settings > Compte > Supprimer
- Confirmation avec password
- Délai de grâce de 30 jours (réactivation possible)
- Suppression complète après 30 jours
- Email de confirmation

US-NOTIF-01: Notifications Push
En tant qu'utilisateur, je veux recevoir des notifications
pour ne pas manquer les matches et messages.

Critères d'acceptation:
- Notification nouveau match
- Notification nouveau message
- Notification nouveau like (premium)
- Notification événement proche
- Settings pour activer/désactiver chaque type
- Deep linking vers l'écran concerné

US-PHOTO-01: Upload de Photos
En tant qu'utilisateur, je veux pouvoir uploader mes photos de profil
pour montrer qui je suis.

Critères d'acceptation:
- Upload depuis galerie ou appareil photo
- Crop/resize automatique
- Compression pour performance
- Max 6 photos
- Réordonner par drag & drop
- Supprimer une photo
```

### Phase 2 - Importantes (Sprint 3-4)

```
US-MATCH-03: Super Like
En tant qu'utilisateur, je veux envoyer un Super Like
pour montrer un intérêt fort à quelqu'un.

Critères d'acceptation:
- Bouton Super Like (étoile) sur profil
- 1 gratuit/jour, illimité premium
- Notification spéciale au destinataire
- Badge "Super Like" visible
- Animation distinctive

US-MATCH-04: Rewind (Annuler Swipe)
En tant qu'utilisateur, je veux pouvoir annuler mon dernier swipe
si j'ai fait une erreur.

Critères d'acceptation:
- Bouton Rewind dans Discover
- Gratuit: 1/jour, Premium: illimité
- Revient au profil précédent
- Ne fonctionne pas si l'autre a déjà swipé

US-DISC-01: Filtres Avancés
En tant qu'utilisateur, je veux des filtres détaillés
pour trouver des profils qui me correspondent vraiment.

Critères d'acceptation:
- Filtre par dénomination juive
- Filtre par niveau kashrout
- Filtre par observance Shabbat
- Filtre par intention relationnelle
- Filtre "Vérifié uniquement"
- Filtre par origine (Ashkenaze/Sépharade)
- Sauvegarde des préférences

US-DISC-02: Mode Incognito
En tant qu'utilisateur premium, je veux pouvoir naviguer en mode invisible
pour voir les profils sans être vu.

Critères d'acceptation:
- Toggle dans settings (Premium only)
- Profil masqué de Discover
- Peut toujours voir les autres
- Peut toujours matcher si like mutuel
- Badge "invisible" dans l'app

US-CHAT-01: Envoi de Photos
En tant qu'utilisateur, je veux envoyer des photos dans le chat
pour partager des moments.

Critères d'acceptation:
- Bouton photo dans input
- Galerie ou appareil photo
- Preview avant envoi
- Compression automatique
- Affichage inline dans la conversation

US-CHAT-02: Réactions aux Messages
En tant qu'utilisateur, je veux réagir aux messages
pour interagir rapidement.

Critères d'acceptation:
- Long press sur message
- Palette de réactions (❤️ 😂 😮 😢 👍)
- Réaction visible sous le message
- Notification de réaction
- Une seule réaction par message

US-CHAT-03: Messages Vocaux
En tant qu'utilisateur, je veux envoyer des messages vocaux
pour communiquer plus naturellement.

Critères d'acceptation:
- Bouton micro dans input
- Hold to record
- Preview avec lecture
- Max 60 secondes
- Waveform visualization
```

### Phase 3 - Engagement (Sprint 5-6)

```
US-ENGAGE-01: Daily Picks
En tant qu'utilisateur, je veux recevoir des suggestions quotidiennes
pour avoir des matches de qualité.

Critères d'acceptation:
- 5 profils/jour (gratuit), 15 (premium)
- Basés sur compatibilité
- Refresh à minuit
- Notification "Vos picks du jour"
- Section dédiée dans l'app

US-ENGAGE-02: Statistiques de Profil
En tant qu'utilisateur, je veux voir les stats de mon profil
pour comprendre ma performance.

Critères d'acceptation:
- Vues du profil (7 derniers jours)
- Likes reçus
- Taux de match
- Photo la plus likée
- Suggestions d'amélioration

US-ENGAGE-03: Badges & Achievements
En tant qu'utilisateur, je veux gagner des badges
pour montrer mon engagement.

Critères d'acceptation:
- Badge "Profil complet"
- Badge "Photo vérifiée"
- Badge "Réponse rapide" (< 1h)
- Badge "Membre actif"
- Badge "Success Story"
- Affichage sur profil

US-ENGAGE-04: Spotlight Hebdomadaire
En tant qu'utilisateur, je veux voir les profils populaires
pour découvrir qui est tendance.

Critères d'acceptation:
- Section "Populaires cette semaine"
- Basé sur likes reçus
- 10 profils max
- Refresh hebdomadaire
- Premium: voir le classement complet
```

### Phase 4 - Différenciation Juive (Sprint 7-8)

```
US-JEW-01: Origine Culturelle
En tant qu'utilisateur juif, je veux indiquer mon origine
pour matcher avec des personnes compatibles culturellement.

Critères d'acceptation:
- Champ: Ashkenaze, Sépharade, Mizrahi, Mixed, Other
- Filtre optionnel (peut être désactivé)
- Affichage sur profil
- Pas de discrimination, juste préférence

US-JEW-02: Kashrout Détaillé
En tant qu'utilisateur observant, je veux préciser mon niveau de kashrout
pour trouver quelqu'un compatible.

Critères d'acceptation:
- Niveaux: Non-observant, Traditionnel, Casher Beth Din, Mehadrin, Glatt
- Explications pour chaque niveau
- Filtre dans Discover
- Compatibilité dans score

US-JEW-03: Événements Communautaires
En tant qu'utilisateur, je veux voir les événements de ma communauté
pour rencontrer des gens en personne.

Critères d'acceptation:
- Événements liés à ma synagogue/communauté
- Filtrer par ville/communauté
- RSVP intégré
- Voir qui y va (matchs)
- Notifications rappels

US-JEW-04: Matchmaker Humain (Premium+)
En tant qu'utilisateur sérieux, je veux être mis en relation par un vrai shadchan
pour avoir un accompagnement personnalisé.

Critères d'acceptation:
- Tier premium supérieur
- Questionnaire détaillé
- 1 mise en relation/mois
- Feedback après chaque rencontre
- Ajustement basé sur retours
```

---

## 5. PRIORISATION RECOMMANDÉE

### 🔴 Must Have (MVP)
1. **US-AUTH-01**: Inscription email - BLOQUANT
2. **US-AUTH-03**: Reset password - BLOQUANT
3. **US-RGPD-01**: Suppression compte - LÉGAL
4. **US-NOTIF-01**: Push notifications - RÉTENTION
5. **US-PHOTO-01**: Upload photos - CORE FEATURE

### 🟠 Should Have (v1.1)
6. **US-AUTH-02**: Vérification téléphone
7. **US-MATCH-03**: Super Like
8. **US-DISC-01**: Filtres avancés
9. **US-CHAT-01**: Envoi photos
10. **US-ENGAGE-01**: Daily Picks

### 🟡 Could Have (v1.2)
11. **US-MATCH-04**: Rewind
12. **US-DISC-02**: Mode Incognito
13. **US-CHAT-02**: Réactions messages
14. **US-CHAT-03**: Messages vocaux
15. **US-ENGAGE-02**: Stats profil

### 🔵 Won't Have Now (v2.0)
16. **US-ENGAGE-03**: Badges
17. **US-ENGAGE-04**: Spotlight
18. **US-JEW-01 à 04**: Features juives avancées

---

## 6. MÉTRIQUES DE SUCCÈS

### Acquisition
| Métrique | Objectif |
|----------|----------|
| Downloads/mois | 5,000 |
| Coût acquisition (CAC) | < €5 |
| Conversion onboarding | > 70% |

### Engagement
| Métrique | Objectif |
|----------|----------|
| DAU/MAU ratio | > 25% |
| Sessions/jour/user | > 3 |
| Temps moyen session | > 8 min |
| Messages envoyés/match | > 10 |

### Rétention
| Métrique | Objectif |
|----------|----------|
| D1 rétention | > 40% |
| D7 rétention | > 25% |
| D30 rétention | > 15% |

### Monétisation
| Métrique | Objectif |
|----------|----------|
| Conversion free→premium | > 5% |
| ARPU | > €3 |
| LTV | > €50 |
| Churn mensuel | < 8% |

### Qualité
| Métrique | Objectif |
|----------|----------|
| Match rate | > 5% |
| Conversations démarrées | > 60% des matches |
| Report rate | < 1% |
| App Store rating | > 4.5 |

---

## 7. RISQUES & MITIGATIONS

| Risque | Probabilité | Impact | Mitigation |
|--------|-------------|--------|------------|
| Rejet App Store (RGPD) | Haute | Critique | Implémenter suppression compte ASAP |
| Faible adoption | Moyenne | Haute | Marketing communautaire ciblé |
| Spam/fake profiles | Moyenne | Haute | Vérification obligatoire |
| Concurrence (JDate, JSwipe) | Haute | Moyenne | Différenciation mode couple |
| Problèmes techniques scaling | Moyenne | Haute | Architecture cloud scalable |

---

## 8. ROADMAP PROPOSÉE

### Q1 2026 - Fondations
- ✅ 12 User Stories existantes
- 🔄 US-AUTH-01, 02, 03 (Authentification complète)
- 🔄 US-RGPD-01 (Conformité légale)
- 🔄 US-NOTIF-01 (Notifications)
- 🔄 US-PHOTO-01 (Upload photos)

### Q2 2026 - Engagement
- US-MATCH-03, 04 (Super Like, Rewind)
- US-DISC-01, 02 (Filtres, Incognito)
- US-CHAT-01, 02, 03 (Media dans chat)

### Q3 2026 - Growth
- US-ENGAGE-01 à 04 (Gamification)
- Marketing communautaire
- Partenariats synagogues

### Q4 2026 - Différenciation
- US-JEW-01 à 04 (Features juives)
- Expansion internationale
- Programme matchmakers

---

## 9. QUESTIONS OUVERTES POUR DISCUSSION

1. **Priorité photo upload vs notifications** - Lequel est plus urgent ?

2. **Super Like gratuit ou premium only ?** - Impact sur conversion vs engagement

3. **Mode couple obligatoire après X mois ?** - Transition dating→couple

4. **Vérification téléphone obligatoire ?** - Plus de confiance vs friction

5. **Origine culturelle sensible ?** - Important pour communauté mais risque discrimination

6. **Matchmaker humain viable économiquement ?** - Tier premium à quel prix ?

7. **Partenariats communautaires** - Quelles synagogues cibler en premier ?

8. **Marché cible initial** - France, Israël, USA, ou global ?

---

## 10. ANNEXES

### A. Competitors Analysis
| App | Points Forts | Points Faibles |
|-----|--------------|----------------|
| JDate | Brand awareness, large base | Vieillissant, UX datée |
| JSwipe | UX moderne, jeune audience | Superficiel, peu de filtres juifs |
| Hinge | Prompts créatifs | Pas juif-focused |
| Bumble | Female-first | Généraliste |
| **MAZL** | Mode couple, Shabbat mode, AI Shadchan | Nouveau, base à construire |

### B. Tech Stack
- **Frontend**: Flutter (iOS + Android)
- **Backend**: Bun + TypeScript
- **Database**: PostgreSQL
- **Real-time**: WebSocket
- **Auth**: Google, Apple, (à ajouter: Email)
- **Payments**: RevenueCat
- **Analytics**: (à définir)
- **Push**: OneSignal (à implémenter)
- **Storage**: (à définir: Cloudinary/S3)

---

> **Document rédigé par**: Claude (AI Assistant)
> **À valider par**: Product Owner
> **Prochaine revue**: [À définir]
