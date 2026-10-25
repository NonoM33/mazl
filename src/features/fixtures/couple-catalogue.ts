// Fictitious catalogue of the couple space (activities and events): sample data
// for development and tests ONLY. initDb seeds it when NODE_ENV is development
// or test, never in production, and scripts/purge-seed-data.ts removes what an
// older release left in a real database.

export interface CoupleActivitySeed {
  readonly title: string;
  readonly description: string;
  readonly category: string;
  readonly subcategory?: string;
  readonly image_url: string;
  readonly price_cents: number;
  readonly location: string;
  readonly address?: string;
  readonly city: string;
  readonly rating: number;
  readonly review_count: number;
  readonly duration_minutes: number;
  readonly is_partner?: boolean;
  readonly is_kosher?: boolean;
  readonly discount_percent?: number;
  readonly tags: readonly string[];
}

export interface CoupleEventSeed {
  readonly title: string;
  readonly description: string;
  readonly category: string;
  readonly image_url: string;
  readonly event_date: string;
  readonly event_time: string;
  readonly end_time?: string;
  readonly location: string;
  readonly address?: string;
  readonly city: string;
  readonly price_cents: number;
  readonly max_couples: number;
  readonly is_kosher?: boolean;
  readonly dress_code?: string;
  readonly what_included?: string;
  readonly is_featured?: boolean;
}

export const COUPLE_ACTIVITY_SEEDS: readonly CoupleActivitySeed[] = [
  // Bien-être
  { title: "Spa Cinq Mondes - Duo", description: "Massage relaxant en duo dans un cadre zen inspiré des rituels du monde. Hammam, sauna et espace détente inclus.", category: "wellness", subcategory: "spa", image_url: "https://images.unsplash.com/photo-1544161515-4ab6ce6db874?w=800", price_cents: 18000, location: "Spa Cinq Mondes", address: "6 Square de l'Opéra Louis Jouvet, 75009 Paris", city: "Paris", rating: 4.8, review_count: 324, duration_minutes: 90, is_partner: true, discount_percent: 15, tags: ["massage", "duo", "détente", "hammam"] },
  { title: "Massage aux Pierres Chaudes", description: "Un moment de pure relaxation à deux avec un massage aux pierres volcaniques chaudes.", category: "wellness", subcategory: "massage", image_url: "https://images.unsplash.com/photo-1600334089648-b0d9d3028eb2?w=800", price_cents: 15000, location: "Spa Nuxe", address: "32 Rue Montorgueil, 75001 Paris", city: "Paris", rating: 4.7, review_count: 189, duration_minutes: 60, tags: ["massage", "pierres chaudes", "relaxation"] },
  { title: "Yoga en Duo", description: "Séance de yoga spécialement conçue pour les couples. Renforcez votre connexion à travers des postures synchronisées.", category: "wellness", subcategory: "yoga", image_url: "https://images.unsplash.com/photo-1599901860904-17e6ed7083a0?w=800", price_cents: 6000, location: "Yoga Village", address: "13 Rue de la Paix, 75002 Paris", city: "Paris", rating: 4.9, review_count: 156, duration_minutes: 75, tags: ["yoga", "duo", "méditation", "bien-être"] },
  { title: "Bains Nordiques", description: "Expérience thermale inspirée des traditions scandinaves. Alternez entre bains chauds, froids et repos.", category: "wellness", subcategory: "bains", image_url: "https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800", price_cents: 8500, location: "Les Bains du Marais", address: "31 Rue des Blancs Manteaux, 75004 Paris", city: "Paris", rating: 4.6, review_count: 278, duration_minutes: 120, tags: ["bains", "nordique", "sauna", "détente"] },

  // Gastronomie
  { title: "Cours de Cuisine en Amoureux", description: "Apprenez à préparer un menu gastronomique à 4 mains avec un chef étoilé.", category: "gastronomy", subcategory: "cooking", image_url: "https://images.unsplash.com/photo-1556910103-1c02745aae4d?w=800", price_cents: 14000, location: "L'atelier des Chefs", address: "10 Rue de Penthièvre, 75008 Paris", city: "Paris", rating: 4.8, review_count: 412, duration_minutes: 180, is_partner: true, discount_percent: 10, tags: ["cuisine", "chef", "gastronomie", "cours"] },
  { title: "Dégustation de Vins Casher", description: "Découvrez les meilleurs vins casher d'Israël et de France lors d'une dégustation guidée par un sommelier.", category: "gastronomy", subcategory: "wine", image_url: "https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?w=800", price_cents: 7500, location: "Cave Casher", address: "42 Rue Richer, 75009 Paris", city: "Paris", rating: 4.7, review_count: 98, duration_minutes: 90, is_kosher: true, tags: ["vin", "casher", "dégustation", "sommelier"] },
  { title: "Dîner aux Chandelles", description: "Restaurant gastronomique avec vue sur la Tour Eiffel. Menu dégustation 7 services.", category: "gastronomy", subcategory: "restaurant", image_url: "https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800", price_cents: 25000, location: "Le Jules Verne", address: "Tour Eiffel, 75007 Paris", city: "Paris", rating: 4.9, review_count: 567, duration_minutes: 150, tags: ["gastronomie", "romantique", "vue", "étoilé"] },
  { title: "Pâtisserie Française", description: "Cours de pâtisserie pour apprendre les classiques français : macarons, éclairs, tarte au citron.", category: "gastronomy", subcategory: "pastry", image_url: "https://images.unsplash.com/photo-1612203985729-70726954388c?w=800", price_cents: 9500, location: "École Ducasse", address: "64 Rue du Ranelagh, 75016 Paris", city: "Paris", rating: 4.8, review_count: 234, duration_minutes: 180, tags: ["pâtisserie", "macarons", "cours", "sucré"] },

  // Culture
  { title: "Visite Privée du Louvre", description: "Découvrez les chefs-d'œuvre du Louvre avec un guide privé, hors des heures d'affluence.", category: "culture", subcategory: "museum", image_url: "https://images.unsplash.com/photo-1499426600726-ac541d8a0aee?w=800", price_cents: 22000, location: "Musée du Louvre", address: "Rue de Rivoli, 75001 Paris", city: "Paris", rating: 4.9, review_count: 189, duration_minutes: 150, tags: ["musée", "art", "visite privée", "culture"] },
  { title: "Opéra Garnier - Soirée Ballet", description: "Assistez à un ballet classique dans le cadre somptueux de l'Opéra Garnier.", category: "culture", subcategory: "show", image_url: "https://images.unsplash.com/photo-1507676184212-d03ab07a01bf?w=800", price_cents: 18000, location: "Opéra Garnier", address: "Place de l'Opéra, 75009 Paris", city: "Paris", rating: 4.9, review_count: 445, duration_minutes: 180, tags: ["opéra", "ballet", "danse", "classique"] },
  { title: "Concert Jazz Intime", description: "Soirée jazz dans un club mythique parisien. Cocktails et musique live.", category: "culture", subcategory: "concert", image_url: "https://images.unsplash.com/photo-1415201364774-f6f0bb35f28f?w=800", price_cents: 6500, location: "Duc des Lombards", address: "42 Rue des Lombards, 75001 Paris", city: "Paris", rating: 4.7, review_count: 312, duration_minutes: 120, tags: ["jazz", "musique live", "cocktails", "intime"] },
  { title: "Escape Game Romantique", description: "Escape game spécialement conçu pour les couples. Résolvez les énigmes ensemble!", category: "culture", subcategory: "game", image_url: "https://images.unsplash.com/photo-1587825140708-dfaf72ae4b04?w=800", price_cents: 5000, location: "Lock Academy", address: "26 Rue Coquillière, 75001 Paris", city: "Paris", rating: 4.6, review_count: 567, duration_minutes: 60, tags: ["escape game", "énigmes", "fun", "duo"] },

  // Sport & Aventure
  { title: "Cours de Danse Latine", description: "Apprenez la salsa, bachata ou kizomba à deux. Tous niveaux acceptés.", category: "sport", subcategory: "dance", image_url: "https://images.unsplash.com/photo-1504609813442-a8924e83f76e?w=800", price_cents: 4500, location: "Studio Bleu", address: "10 Rue de la Gaîté, 75014 Paris", city: "Paris", rating: 4.8, review_count: 234, duration_minutes: 90, tags: ["danse", "salsa", "bachata", "latino"] },
  { title: "Balade à Cheval en Forêt", description: "Promenade romantique à cheval à travers la forêt de Fontainebleau.", category: "sport", subcategory: "horse", image_url: "https://images.unsplash.com/photo-1553284965-83fd3e82fa5a?w=800", price_cents: 12000, location: "Centre Équestre", address: "Route de la Reine, 77300 Fontainebleau", city: "Fontainebleau", rating: 4.7, review_count: 89, duration_minutes: 120, tags: ["cheval", "nature", "balade", "forêt"] },
  { title: "Vol en Montgolfière", description: "Survolez les châteaux de la Loire au lever du soleil. Champagne inclus!", category: "sport", subcategory: "flying", image_url: "https://images.unsplash.com/photo-1507608616759-54f48f0af0ee?w=800", price_cents: 35000, location: "France Montgolfières", address: "Loire Valley", city: "Tours", rating: 4.9, review_count: 156, duration_minutes: 180, tags: ["montgolfière", "vol", "champagne", "châteaux"] },
  { title: "Kayak au Coucher du Soleil", description: "Balade en kayak biplace sur la Seine au coucher du soleil.", category: "sport", subcategory: "kayak", image_url: "https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=800", price_cents: 5500, location: "Kayak Paris", address: "Port de Javel, 75015 Paris", city: "Paris", rating: 4.6, review_count: 178, duration_minutes: 90, tags: ["kayak", "seine", "coucher de soleil", "eau"] },

  // Romantique
  { title: "Croisière Champagne sur la Seine", description: "Croisière privative avec champagne et petit fours, vue sur Paris illuminé.", category: "romantic", subcategory: "cruise", image_url: "https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=800", price_cents: 16000, location: "Bateaux Parisiens", address: "Port de la Bourdonnais, 75007 Paris", city: "Paris", rating: 4.8, review_count: 345, duration_minutes: 90, is_partner: true, discount_percent: 20, tags: ["croisière", "champagne", "seine", "romantique"] },
  { title: "Pique-nique Gastronomique", description: "Panier gourmet livré au parc de votre choix. Produits frais et vin inclus.", category: "romantic", subcategory: "picnic", image_url: "https://images.unsplash.com/photo-1526662092594-e98c1e356d6a?w=800", price_cents: 8500, location: "Jardin du Luxembourg", address: "Jardin du Luxembourg, 75006 Paris", city: "Paris", rating: 4.7, review_count: 123, duration_minutes: 120, tags: ["pique-nique", "gourmet", "parc", "romantique"] },
  { title: "Séance Photo Couple", description: "Shooting photo professionnel dans les plus beaux quartiers de Paris.", category: "romantic", subcategory: "photo", image_url: "https://images.unsplash.com/photo-1529634597503-139d3726fed5?w=800", price_cents: 25000, location: "Paris", address: "Montmartre, 75018 Paris", city: "Paris", rating: 4.9, review_count: 267, duration_minutes: 120, tags: ["photo", "shooting", "souvenir", "professionnel"] },
  { title: "Soirée Cabaret au Moulin Rouge", description: "Le célèbre show du Moulin Rouge avec dîner et champagne.", category: "romantic", subcategory: "show", image_url: "https://images.unsplash.com/photo-1550411294-875f8f4c9d4f?w=800", price_cents: 35000, location: "Moulin Rouge", address: "82 Boulevard de Clichy, 75018 Paris", city: "Paris", rating: 4.8, review_count: 789, duration_minutes: 240, tags: ["cabaret", "show", "champagne", "dîner"] },

  // Voyage
  { title: "Week-end à Deauville", description: "2 jours/1 nuit dans un hôtel de charme avec spa. Petit-déjeuner inclus.", category: "travel", subcategory: "weekend", image_url: "https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=800", price_cents: 45000, location: "Hôtel Normandy Barrière", address: "38 Rue Jean Mermoz, 14800 Deauville", city: "Deauville", rating: 4.7, review_count: 234, duration_minutes: 2880, tags: ["week-end", "plage", "spa", "normandie"] },
  { title: "Escapade Romantique à Bruges", description: "2 jours dans la Venise du Nord. Balades, chocolat et bière belge.", category: "travel", subcategory: "city", image_url: "https://images.unsplash.com/photo-1491557345352-5929e343eb89?w=800", price_cents: 38000, location: "Bruges", address: "Bruges, Belgique", city: "Bruges", rating: 4.8, review_count: 156, duration_minutes: 2880, tags: ["bruges", "belgique", "romantique", "chocolat"] },
  { title: "Shabbaton à la Montagne", description: "Week-end shabbat dans un chalet à la montagne. Repas casher et ambiance chaleureuse.", category: "travel", subcategory: "spiritual", image_url: "https://images.unsplash.com/photo-1520984032042-162d526883e0?w=800", price_cents: 55000, location: "Chalet Alpin", address: "Megève, 74120", city: "Megève", rating: 4.9, review_count: 67, duration_minutes: 4320, is_kosher: true, tags: ["shabbat", "montagne", "casher", "spirituel"] },

  // Spirituel
  { title: "Cours de Torah en Couple", description: "Étude de textes sur le couple dans la tradition juive avec un rabbin.", category: "spiritual", subcategory: "study", image_url: "https://images.unsplash.com/photo-1457369804613-52c61a468e7d?w=800", price_cents: 0, location: "Centre Communautaire", address: "17 Rue des Rosiers, 75004 Paris", city: "Paris", rating: 4.9, review_count: 45, duration_minutes: 90, is_kosher: true, tags: ["torah", "étude", "couple", "spiritualité"] },
  { title: "Préparation Shabbat", description: "Atelier de préparation du Shabbat en couple : challah, kiddoush, bénédictions.", category: "spiritual", subcategory: "cooking", image_url: "https://images.unsplash.com/photo-1509440159596-0249088772ff?w=800", price_cents: 4500, location: "Beth Loubavitch", address: "8 Rue Lamartine, 75009 Paris", city: "Paris", rating: 4.8, review_count: 78, duration_minutes: 120, is_kosher: true, tags: ["shabbat", "challah", "préparation", "tradition"] },

  // DIY
  { title: "Atelier Poterie en Duo", description: "Créez vos propres pièces en céramique. Tournage, modelage et émaillage.", category: "diy", subcategory: "pottery", image_url: "https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=800", price_cents: 8500, location: "L'Atelier Céramique", address: "23 Rue de la Folie Méricourt, 75011 Paris", city: "Paris", rating: 4.7, review_count: 189, duration_minutes: 180, tags: ["poterie", "céramique", "création", "artisanat"] },
  { title: "Peinture sur Toile", description: "Soirée peinture avec un verre de vin. Guidé par un artiste, repartez avec votre création.", category: "diy", subcategory: "painting", image_url: "https://images.unsplash.com/photo-1460661419201-fd4cecdf8a8b?w=800", price_cents: 6500, location: "Art & Vin", address: "15 Rue du Faubourg Saint-Antoine, 75011 Paris", city: "Paris", rating: 4.6, review_count: 234, duration_minutes: 150, tags: ["peinture", "art", "vin", "création"] },
  { title: "Fabrication de Bougies", description: "Créez vos propres bougies parfumées. Parfait pour les bougies de Shabbat!", category: "diy", subcategory: "candles", image_url: "https://images.unsplash.com/photo-1602607015644-e2b8b213a0f8?w=800", price_cents: 5500, location: "La Maison des Bougies", address: "45 Rue de Turenne, 75003 Paris", city: "Paris", rating: 4.7, review_count: 156, duration_minutes: 120, is_kosher: true, tags: ["bougies", "DIY", "shabbat", "parfum"] }
];

export const COUPLE_EVENT_SEEDS: readonly CoupleEventSeed[] = [
  { title: "Shabbat Dinner Couples", description: "Soirée Shabbat exclusive pour couples. Dîner casher gastronomique, chants et ambiance chaleureuse.", category: "dinner", image_url: "https://images.unsplash.com/photo-1529543544277-c91e2e51c71a?w=800", event_date: "2026-01-24", event_time: "19:00", end_time: "23:00", location: "Le Marais", address: "24 Rue des Écouffes, 75004 Paris", city: "Paris", price_cents: 12000, max_couples: 15, is_kosher: true, dress_code: "Élégant décontracté", what_included: "Dîner 4 services, vin, dessert", is_featured: true },
  { title: "Wine & Cheese Couples", description: "Dégustation de vins casher et fromages dans une cave historique du Marais.", category: "tasting", image_url: "https://images.unsplash.com/photo-1506377247377-2a5b3b417ebb?w=800", event_date: "2026-01-31", event_time: "20:00", end_time: "22:30", location: "Cave du Marais", address: "42 Rue de Bretagne, 75003 Paris", city: "Paris", price_cents: 8500, max_couples: 12, is_kosher: true, what_included: "5 vins, plateau de fromages, pain", is_featured: true },
  { title: "Soirée Dansante Années 80", description: "Retrouvez les tubes des années 80! DJ, buffet et open bar.", category: "party", image_url: "https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=800", event_date: "2026-02-08", event_time: "21:00", end_time: "02:00", location: "Salle des Fêtes", address: "156 Rue de Rivoli, 75001 Paris", city: "Paris", price_cents: 9000, max_couples: 50, dress_code: "Tenue années 80", what_included: "Buffet, open bar soft, DJ" },
  { title: "Week-end Couples à Deauville", description: "Escapade de 2 jours en Normandie. Hôtel 4*, spa, repas et activités.", category: "travel", image_url: "https://images.unsplash.com/photo-1571003123894-1f0594d2b5d9?w=800", event_date: "2026-02-14", event_time: "10:00", end_time: "18:00", location: "Deauville", address: "Hôtel Royal Barrière, Deauville", city: "Deauville", price_cents: 65000, max_couples: 10, dress_code: "Décontracté chic", what_included: "2 nuits, petits-déjeuners, 1 dîner, accès spa", is_featured: true },
  { title: "Cours de Salsa Couples", description: "Apprenez la salsa cubaine en groupe de couples. Tous niveaux!", category: "workshop", image_url: "https://images.unsplash.com/photo-1545128485-c400e7702796?w=800", event_date: "2026-02-01", event_time: "19:30", end_time: "21:30", location: "Studio Latino", address: "78 Rue de la Roquette, 75011 Paris", city: "Paris", price_cents: 4000, max_couples: 15, what_included: "2h de cours, rafraîchissements" },
  { title: "Brunch Couples du Dimanche", description: "Brunch gastronomique pour couples dans un lieu d'exception.", category: "brunch", image_url: "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800", event_date: "2026-01-26", event_time: "11:00", end_time: "14:00", location: "Hôtel Plaza Athénée", address: "25 Avenue Montaigne, 75008 Paris", city: "Paris", price_cents: 15000, max_couples: 20, dress_code: "Smart casual", what_included: "Buffet à volonté, champagne, jus frais" },
  { title: "Retraite Spirituelle Couples", description: "Week-end de ressourcement spirituel. Étude, méditation et repas casher.", category: "spiritual", image_url: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800", event_date: "2026-03-07", event_time: "09:00", end_time: "18:00", location: "Centre Beth Yossef", address: "Fontainebleau", city: "Fontainebleau", price_cents: 35000, max_couples: 8, is_kosher: true, what_included: "Hébergement, repas casher, cours", is_featured: true },
  { title: "Atelier Cocktails en Couple", description: "Apprenez à créer des cocktails avec un mixologue professionnel.", category: "workshop", image_url: "https://images.unsplash.com/photo-1551024709-8f23befc6f87?w=800", event_date: "2026-02-15", event_time: "18:00", end_time: "20:30", location: "Bar Le Syndicat", address: "51 Rue du Faubourg Saint-Denis, 75010 Paris", city: "Paris", price_cents: 7500, max_couples: 10, what_included: "3 cocktails par personne, recettes" },
  { title: "Escape Game Team Couples", description: "Compétition d'escape game entre couples! Qui résoudra les énigmes le plus vite?", category: "game", image_url: "https://images.unsplash.com/photo-1587825140708-dfaf72ae4b04?w=800", event_date: "2026-02-22", event_time: "14:00", end_time: "17:00", location: "Lock Academy", address: "26 Rue Coquillière, 75001 Paris", city: "Paris", price_cents: 5000, max_couples: 8, what_included: "2 parties, goûter, prix pour les gagnants" },
  { title: "Concert Privé Jazz", description: "Concert de jazz intimiste réservé aux couples MAZL.", category: "concert", image_url: "https://images.unsplash.com/photo-1511192336575-5a79af67a629?w=800", event_date: "2026-02-28", event_time: "20:30", end_time: "23:00", location: "Sunset Jazz Club", address: "60 Rue des Lombards, 75001 Paris", city: "Paris", price_cents: 6500, max_couples: 25, what_included: "Concert, 1 cocktail par personne" }
];
