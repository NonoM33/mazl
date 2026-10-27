// Textes proposés par thème (français d'abord) : le staff les relit et les modifie avant de programmer.
import type { CampaignTexts, FullTexts, Lang, ThemeId } from "./types";

type Pair = readonly [title: string, subtitle: string];

const PAIRS: Readonly<Record<ThemeId, Readonly<Record<Lang, Pair>>>> = {
  valentine: {
    fr: ["Pour la Saint-Valentin", "Rencontrez quelqu'un qui compte, avec mazl+ à prix doux."],
    en: ["For Valentine's Day", "Meet someone who matters, with mazl+ at a gentler price."],
    he: ["ליום האהבה", "הכירו מישהו שחשוב לכם, עם mazl+ במחיר נעים."],
    es: ["Para San Valentín", "Conoce a alguien que importa, con mazl+ a mejor precio."],
    ru: ["К Дню святого Валентина", "Познакомьтесь с тем, кто важен, с mazl+ по выгодной цене."],
  },
  tu_bav: {
    fr: ["Tou be-Av, la fête de l'amour", "Un jour pour se rencontrer : mazl+ à prix réduit."],
    en: ["Tu B'Av, the day of love", "A day to meet someone: mazl+ at a reduced price."],
    he: ["ט״ו באב, חג האהבה", "יום להכיר מישהו: mazl+ במחיר מוזל."],
    es: ["Tu B'Av, el día del amor", "Un día para conocerse: mazl+ a precio reducido."],
    ru: ["Ту бе-Ав, праздник любви", "День для знакомств: mazl+ со скидкой."],
  },
  rosh_hashana: {
    fr: ["Shana Tova", "Une nouvelle année pour une belle rencontre : mazl+ à prix réduit."],
    en: ["Shana Tova", "A new year for a good match: mazl+ at a reduced price."],
    he: ["שנה טובה", "שנה חדשה להיכרות טובה: mazl+ במחיר מוזל."],
    es: ["Shaná Tová", "Un año nuevo para un buen encuentro: mazl+ a precio reducido."],
    ru: ["Шана Това", "Новый год для хорошего знакомства: mazl+ со скидкой."],
  },
  hanukkah: {
    fr: ["Hanoucca, huit soirs de lumière", "Allumez une rencontre : mazl+ à prix réduit."],
    en: ["Hanukkah, eight nights of light", "Light up a new connection: mazl+ at a reduced price."],
    he: ["חנוכה, שמונה ערבים של אור", "הדליקו היכרות חדשה: mazl+ במחיר מוזל."],
    es: ["Janucá, ocho noches de luz", "Enciende un nuevo encuentro: mazl+ a precio reducido."],
    ru: ["Ханука, восемь вечеров света", "Зажгите новое знакомство: mazl+ со скидкой."],
  },
  christmas: {
    fr: ["Joyeux Noël", "Un cadeau pour vos rencontres : mazl+ à prix réduit."],
    en: ["Merry Christmas", "A gift for your dating life: mazl+ at a reduced price."],
    he: ["חג מולד שמח", "מתנה להיכרויות שלכם: mazl+ במחיר מוזל."],
    es: ["Feliz Navidad", "Un regalo para tus encuentros: mazl+ a precio reducido."],
    ru: ["С Рождеством", "Подарок для ваших знакомств: mazl+ со скидкой."],
  },
  new_year: {
    fr: ["Bonne année", "Commencez l'année en bonne compagnie : mazl+ à prix réduit."],
    en: ["Happy New Year", "Start the year in good company: mazl+ at a reduced price."],
    he: ["שנה אזרחית טובה", "פותחים את השנה בחברה טובה: mazl+ במחיר מוזל."],
    es: ["Feliz año nuevo", "Empieza el año en buena compañía: mazl+ a precio reducido."],
    ru: ["С Новым годом", "Начните год в хорошей компании: mazl+ со скидкой."],
  },
  purim: {
    fr: ["Pourim saméach", "Sortez masqué, rencontrez à visage découvert : mazl+ à prix réduit."],
    en: ["Happy Purim", "Go out masked, meet unmasked: mazl+ at a reduced price."],
    he: ["פורים שמח", "יוצאים במסיכה, נפגשים בפנים גלויות: mazl+ במחיר מוזל."],
    es: ["Purim sameaj", "Sal con máscara, conoce a cara descubierta: mazl+ a precio reducido."],
    ru: ["Пурим самеах", "Выходите в маске, знакомьтесь с открытым лицом: mazl+ со скидкой."],
  },
  passover: {
    fr: ["Pessah saméach", "Une table, une rencontre : mazl+ à prix réduit."],
    en: ["Happy Passover", "One table, one connection: mazl+ at a reduced price."],
    he: ["פסח כשר ושמח", "שולחן אחד, היכרות אחת: mazl+ במחיר מוזל."],
    es: ["Pésaj sameaj", "Una mesa, un encuentro: mazl+ a precio reducido."],
    ru: ["Песах самеах", "Один стол — одно знакомство: mazl+ со скидкой."],
  },
  mothers_day: {
    fr: ["Pour la fête des mères", "Offrez-vous du temps pour vous : mazl+ à prix réduit."],
    en: ["For Mother's Day", "Give yourself some time: mazl+ at a reduced price."],
    he: ["ליום האם", "תנו לעצמכן זמן: mazl+ במחיר מוזל."],
    es: ["Por el Día de la Madre", "Regálate tiempo para ti: mazl+ a precio reducido."],
    ru: ["К Дню матери", "Подарите время себе: mazl+ со скидкой."],
  },
  summer: {
    fr: ["Les soldes d'été", "Un été de rencontres : mazl+ à prix réduit."],
    en: ["Summer sale", "A summer of new connections: mazl+ at a reduced price."],
    he: ["מבצע הקיץ", "קיץ של היכרויות: mazl+ במחיר מוזל."],
    es: ["Rebajas de verano", "Un verano de encuentros: mazl+ a precio reducido."],
    ru: ["Летняя распродажа", "Лето знакомств: mazl+ со скидкой."],
  },
  black_friday: {
    fr: ["Black Friday", "Le prix de l'année pour mazl+, quelques jours seulement."],
    en: ["Black Friday", "The best price of the year for mazl+, for a few days only."],
    he: ["בלאק פריידיי", "המחיר הטוב של השנה ל-mazl+, לכמה ימים בלבד."],
    es: ["Black Friday", "El mejor precio del año para mazl+, solo unos días."],
    ru: ["Чёрная пятница", "Лучшая цена года на mazl+, всего несколько дней."],
  },
};

const CTA: Readonly<Record<Lang, string>> = {
  fr: "J'en profite",
  en: "Get the offer",
  he: "למימוש ההצעה",
  es: "Aprovechar la oferta",
  ru: "Получить предложение",
};

export function defaultTexts(themeId: ThemeId): FullTexts {
  const build = (lang: Lang): CampaignTexts => {
    const [title, subtitle] = PAIRS[themeId][lang];
    return { title, subtitle, cta: CTA[lang] };
  };
  return { fr: build("fr"), en: build("en"), he: build("he"), es: build("es"), ru: build("ru") };
}

/** Remise proposée par défaut : plus forte pour le Black Friday. */
export const defaultDiscount = (themeId: ThemeId): number => (themeId === "black_friday" ? 40 : 30);

export const LANG_LABELS: Readonly<Record<Lang, string>> = { fr: "Français", en: "English", he: "עברית", es: "Español", ru: "Русский" };
export const LANG_NAMES_FR: Readonly<Record<Lang, string>> = { fr: "français", en: "anglais", he: "hébreu", es: "espagnol", ru: "russe" };
export const isRtl = (lang: Lang): boolean => lang === "he";
