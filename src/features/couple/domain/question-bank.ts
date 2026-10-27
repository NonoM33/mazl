export const QUESTION_LANGUAGES = ["fr", "en", "he", "es", "ru"] as const;
export type QuestionLanguage = (typeof QUESTION_LANGUAGES)[number];

export type QuestionCategory =
  | "connection"
  | "dreams"
  | "daily"
  | "judaism"
  | "appreciation"
  | "memories"
  | "wellbeing"
  | "values"
  | "future"
  | "family"
  | "fun";

export interface BankQuestion {
  readonly key: string;
  readonly category: QuestionCategory;
  readonly text: Readonly<Record<QuestionLanguage, string>>;
}

type Row = readonly [
  key: string,
  category: QuestionCategory,
  fr: string,
  en: string,
  he: string,
  es: string,
  ru: string,
];

const ROWS: readonly Row[] = [
  ["q001", "connection", "Quel est ton moment préféré de la semaine ensemble ?", "What is your favorite moment of the week together?", "מהו הרגע האהוב עליך בשבוע שלנו יחד?", "¿Cuál es tu momento favorito de la semana juntos?", "Какой момент недели вместе Вам нравится больше всего?"],
  ["q002", "dreams", "Si on pouvait voyager n'importe où, où irais-tu ?", "If we could travel anywhere, where would you go?", "אם אפשר היה לטייל בכל מקום בעולם, מהו היעד שהכי מושך אותך?", "Si pudiéramos viajar a cualquier parte, ¿adónde irías?", "Если бы мы могли поехать куда угодно, куда бы Вы отправились?"],
  ["q003", "daily", "Qu'est-ce qui t'a fait sourire aujourd'hui ?", "What made you smile today?", "מה גרם לך לחייך היום?", "¿Qué te hizo sonreír hoy?", "Что заставило Вас улыбнуться сегодня?"],
  ["q004", "judaism", "Comment aimerais-tu célébrer notre prochain Shabbat ?", "How would you like to celebrate our next Shabbat?", "איך היית רוצה לחגוג את השבת הקרובה שלנו?", "¿Cómo te gustaría celebrar nuestro próximo Shabat?", "Как Вам хотелось бы провести наш ближайший Шаббат?"],
  ["q005", "appreciation", "Quel trait de caractère admires-tu le plus chez l'autre ?", "Which character trait do you admire most in your partner?", "איזו תכונת אופי מעוררת בך הכי הרבה הערכה אצל הצד השני?", "¿Qué rasgo de carácter admiras más de tu pareja?", "Какую черту характера партнёра Вы цените больше всего?"],
  ["q006", "connection", "Qu'est-ce qui te manque le plus quand on n'est pas ensemble ?", "What do you miss the most when we're apart?", "מה הכי חסר לך כשאנחנו לא ביחד?", "¿Qué es lo que más echas de menos cuando no estamos juntos?", "Чего Вам больше всего не хватает, когда мы не вместе?"],
  ["q007", "dreams", "Si tu pouvais apprendre une nouvelle compétence, ce serait quoi ?", "If you could learn a new skill, what would it be?", "איזו מיומנות חדשה הכי היית רוצה ללמוד?", "Si pudieras aprender una nueva habilidad, ¿cuál sería?", "Если бы Вы могли освоить новый навык, какой бы это был?"],
  ["q008", "memories", "Quel est ton souvenir préféré de notre relation ?", "What is your favorite memory of our relationship?", "מהו הזיכרון האהוב עליך מהקשר שלנו?", "¿Cuál es tu recuerdo favorito de nuestra relación?", "Какое Ваше любимое воспоминание о наших отношениях?"],
  ["q009", "wellbeing", "Comment te sens-tu aujourd'hui sur une échelle de 1 à 10 ?", "How are you feeling today on a scale of 1 to 10?", "איך הרגשת היום בסולם של 1 עד 10?", "¿Cómo te sientes hoy en una escala del 1 al 10?", "Как Вы себя чувствуете сегодня по шкале от 1 до 10?"],
  ["q010", "values", "Quelle est la chose la plus importante dans un couple selon toi ?", "What is the most important thing in a relationship, in your view?", "מהו הדבר החשוב ביותר בזוגיות בעיניך?", "¿Cuál es la cosa más importante en una pareja, según tú?", "Что, по Вашему мнению, важнее всего в паре?"],

  ["q011", "connection", "Dans quels moments te sens-tu le plus proche de l'autre ?", "When do you feel closest to your partner?", "באילו רגעים אנחנו מרגישים הכי קרובים זה לזה?", "¿En qué momentos te sientes más cerca de tu pareja?", "В какие моменты Вы чувствуете себя ближе всего к партнёру?"],
  ["q012", "connection", "Quel petit geste entre nous te touche toujours, même s'il est tout simple ?", "What small gesture between us always touches you, even when it's very simple?", "איזו מחווה קטנה בינינו נוגעת תמיד ללב, גם כשהיא הכי פשוטה?", "¿Qué pequeño gesto entre nosotros te emociona siempre, aunque sea muy sencillo?", "Какой небольшой жест между нами всегда трогает Вас, даже самый простой?"],
  ["q013", "connection", "De quoi aimerais-tu qu'on parle plus souvent, rien que tous les deux ?", "What would you like us to talk about more often, just the two of us?", "על מה היית רוצה שנדבר יותר, רק שנינו?", "¿De qué te gustaría que habláramos más a menudo, solo nosotros dos?", "О чём Вам хотелось бы говорить чаще, только нам двоим?"],
  ["q014", "connection", "Quelle activité simple nous rapproche le plus, selon toi ?", "Which simple activity brings us closest together, in your view?", "איזו פעילות פשוטה מקרבת בינינו יותר מכול?", "¿Qué actividad sencilla nos acerca más, según tú?", "Какое простое занятие больше всего сближает нас, по Вашему мнению?"],
  ["q015", "connection", "Comment reconnais-tu chez l'autre le besoin d'un peu de réconfort ?", "How can you tell when your partner needs a little comfort?", "איך אנחנו מזהים אצל האחר צורך בקצת נחמה?", "¿Cómo te das cuenta de que tu pareja necesita un poco de consuelo?", "Как Вы понимаете, что партнёру нужно немного утешения?"],
  ["q016", "connection", "Quel mot ou quelle phrase de l'autre te fait toujours du bien ?", "What word or phrase from your partner always does you good?", "איזו מילה או משפט מהצד השני תמיד עושים לך טוב?", "¿Qué palabra o frase de tu pareja te hace siempre bien?", "Какое слово или фраза партнёра всегда поднимает Вам настроение?"],
  ["q017", "connection", "Que pourrait-on faire chaque semaine pour prendre du temps rien que pour nous deux ?", "What could we do every week to set aside time just for the two of us?", "מה אפשר לעשות כל שבוע כדי לפנות זמן רק לשנינו?", "¿Qué podríamos hacer cada semana para reservar un tiempo solo para nosotros dos?", "Что мы могли бы делать каждую неделю, чтобы выкроить время только для нас двоих?"],
  ["q018", "connection", "Quand l'autre t'écoute vraiment, qu'est-ce que cela change pour toi ?", "When your partner really listens to you, what changes for you?", "כשבאמת מקשיבים לך, מה זה משנה בשבילך?", "Cuando tu pareja te escucha de verdad, ¿qué cambia para ti?", "Когда партнёр по-настоящему Вас слушает, что меняется для Вас?"],

  ["q019", "dreams", "Quel projet un peu fou aimerais-tu qu'on réalise un jour ?", "What slightly crazy project would you love us to do one day?", "איזה פרויקט קצת משוגע היית רוצה שנגשים יום אחד?", "¿Qué proyecto un poco loco te gustaría que hiciéramos algún día?", "Какой чуть безумный проект Вам хотелось бы когда-нибудь воплотить вместе?"],
  ["q020", "dreams", "Si tu avais une journée entière sans aucune obligation, comment la passerais-tu ?", "If you had a whole day with no obligations, how would you spend it?", "אם היה לך יום שלם בלי שום מחויבות, איך היית מבלה אותו?", "Si tuvieras un día entero sin obligaciones, ¿cómo lo pasarías?", "Если бы у Вас был целый день без каких-либо обязанностей, как бы Вы его провели?"],
  ["q021", "dreams", "Dans quel endroit du monde aimerais-tu vivre quelques mois ?", "Where in the world would you like to live for a few months?", "איפה בעולם היה מעניין לגור לכמה חודשים?", "¿En qué lugar del mundo te gustaría vivir unos meses?", "В каком уголке мира Вам хотелось бы пожить несколько месяцев?"],
  ["q022", "dreams", "Quel rêve d'enfance garde encore une place dans ton cœur ?", "Which childhood dream still has a place in your heart?", "איזה חלום מילדות עדיין שומר מקום בלב?", "¿Qué sueño de la infancia sigue ocupando un lugar en tu corazón?", "Какая детская мечта до сих пор живёт в Вашем сердце?"],
  ["q023", "dreams", "Quelle expérience aimerais-tu vivre au moins une fois dans ta vie ?", "What experience would you like to have at least once in your life?", "איזו חוויה היית רוצה לחוות לפחות פעם אחת בחיים?", "¿Qué experiencia te gustaría vivir al menos una vez en la vida?", "Какой опыт Вам хотелось бы пережить хотя бы раз в жизни?"],
  ["q024", "dreams", "Si l'argent n'était pas un sujet, quel cadeau aimerais-tu offrir à l'autre ?", "If money were no object, what would you love to give your partner?", "אם כסף לא היה שיקול, איזו מתנה היית רוצה לתת לצד השני?", "Si el dinero no fuera un tema, ¿qué regalo te gustaría hacerle a tu pareja?", "Если бы деньги не имели значения, какой подарок Вы хотели бы сделать партнёру?"],
  ["q025", "dreams", "Quel défi aimerais-tu relever ensemble, juste pour le plaisir ?", "What challenge would you like us to take on together, just for fun?", "איזה אתגר היית רוצה שנעמוד בו יחד, סתם בשביל הכיף?", "¿Qué reto te gustaría que afrontáramos juntos, solo por diversión?", "Какой вызов Вам хотелось бы принять вместе, просто ради удовольствия?"],
  ["q026", "dreams", "Quelle maison ou quel lieu de vie te fait rêver, même si c'est irréaliste ?", "What kind of home or place to live do you dream of, even if it's unrealistic?", "איזה בית או מקום מגורים מעורר בך חלומות, גם אם זה לא מציאותי?", "¿Qué casa o lugar para vivir te hace soñar, aunque sea poco realista?", "О каком доме или месте для жизни Вы мечтаете, пусть даже нереалистичном?"],

  ["q027", "daily", "Quel petit rituel de notre quotidien te fait du bien sans que l'on s'en rende compte ?", "Which little ritual of our daily life does you good without us noticing?", "איזה טקס קטן בשגרה שלנו עושה לך טוב בלי שנשים לב?", "¿Qué pequeño ritual de nuestro día a día te hace bien sin que nos demos cuenta?", "Какой маленький ритуал нашей повседневности радует Вас, хотя мы его почти не замечаем?"],
  ["q028", "daily", "À quoi ressemble ta matinée idéale, du réveil au premier café ?", "What does your ideal morning look like, from waking up to the first coffee?", "איך נראה הבוקר המושלם, מההתעוררות ועד הקפה הראשון?", "¿Cómo es tu mañana ideal, desde que te despiertas hasta el primer café?", "Каким было бы Ваше идеальное утро, от пробуждения до первой чашки кофе?"],
  ["q029", "daily", "Quelle tâche de la maison aimerais-tu qu'on partage autrement ?", "Which household chore would you like us to share differently?", "איזו משימה בבית היית רוצה שנחלק אחרת?", "¿Qué tarea de la casa te gustaría que repartiéramos de otra manera?", "Какое домашнее дело Вам хотелось бы поделить между нами иначе?"],
  ["q030", "daily", "Quel plat du quotidien te réconforte le plus après une longue journée ?", "What everyday dish comforts you the most after a long day?", "איזו מנה פשוטה מנחמת הכי הרבה אחרי יום ארוך?", "¿Qué plato de diario te reconforta más después de un día largo?", "Какое простое блюдо лучше всего утешает Вас после долгого дня?"],
  ["q031", "daily", "Que pourrait-on faire pour que nos soirées soient encore plus agréables ?", "What could we do to make our evenings even more pleasant?", "מה אפשר לעשות כדי שהערבים שלנו יהיו נעימים עוד יותר?", "¿Qué podríamos hacer para que nuestras noches sean aún más agradables?", "Что мы могли бы сделать, чтобы наши вечера стали ещё приятнее?"],
  ["q032", "daily", "Quelle musique, quel film ou quelle série aimerais-tu partager avec l'autre cette semaine ?", "What music, film or series would you like to share with your partner this week?", "איזו מוזיקה, סרט או סדרה היית רוצה לחלוק עם הצד השני השבוע?", "¿Qué música, película o serie te gustaría compartir con tu pareja esta semana?", "Каким фильмом, сериалом или музыкой Вам хотелось бы поделиться с партнёром на этой неделе?"],
  ["q033", "daily", "Qu'est-ce qui t'aide à décompresser quand la journée a été chargée ?", "What helps you unwind when the day has been busy?", "מה עוזר לך להירגע אחרי יום עמוס?", "¿Qué te ayuda a desconectar cuando el día ha sido intenso?", "Что помогает Вам расслабиться после напряжённого дня?"],
  ["q034", "daily", "Quelle habitude de l'autre te fait sourire, même si elle est un peu étrange ?", "What habit of your partner's makes you smile, even if it's a bit quirky?", "איזה הרגל של הצד השני גורם לך לחייך, גם אם הוא קצת מוזר?", "¿Qué costumbre de tu pareja te hace sonreír, aunque sea un poco peculiar?", "Какая привычка партнёра вызывает у Вас улыбку, даже если она немного странная?"],
  ["q035", "daily", "Si on avait une heure de plus chaque jour, à quoi la consacrerait-on ?", "If we had one more hour every day, what would we do with it?", "אילו הייתה לנו שעה נוספת בכל יום, למה היינו מקדישים אותה?", "Si tuviéramos una hora más cada día, ¿a qué la dedicaríamos?", "Если бы у нас был лишний час каждый день, чему бы мы его посвятили?"],

  ["q036", "judaism", "Quel moment du Shabbat te ressource le plus, quelle que soit notre façon de le vivre ?", "Which moment of Shabbat recharges you the most, however we choose to keep it?", "איזה רגע בשבת מטעין אותך הכי הרבה, בכל דרך שבה אנחנו מקיימים אותה?", "¿Qué momento del Shabat te recarga más, sea cual sea la forma en que lo vivamos?", "Какой момент Шаббата больше всего наполняет Вас силами, как бы мы его ни проводили?"],
  ["q037", "judaism", "Quelle fête juive te rend le plus nostalgique, et pourquoi ?", "Which Jewish holiday makes you the most nostalgic, and why?", "איזה חג יהודי מעורר הכי הרבה נוסטלגיה, ולמה?", "¿Qué fiesta judía te despierta más nostalgia y por qué?", "Какой еврейский праздник вызывает у Вас больше всего ностальгии и почему?"],
  ["q038", "judaism", "Quelle recette de famille aimerais-tu qu'on apprenne à cuisiner ensemble pour une fête ?", "Which family recipe would you like us to learn to cook together for a holiday?", "איזה מתכון משפחתי היית רוצה שנלמד לבשל יחד לקראת חג?", "¿Qué receta familiar te gustaría que aprendiéramos a cocinar juntos para una fiesta?", "Какой семейный рецепт Вам хотелось бы научиться готовить вместе к празднику?"],
  ["q039", "judaism", "Que représente pour toi la cacherout, au quotidien ou dans ton histoire familiale ?", "What does keeping kosher mean to you, in daily life or in your family's story?", "מה מייצגת הכשרות עבורך, בחיי היום-יום או בסיפור המשפחתי?", "¿Qué significa para ti la cashrut, en el día a día o en la historia de tu familia?", "Что для Вас значит кашрут, в повседневной жизни или в истории Вашей семьи?"],
  ["q040", "judaism", "Quelle tradition de ta famille aimerais-tu absolument transmettre un jour ?", "Which tradition from your family would you most like to pass on one day?", "איזו מסורת מהבית שלך היית רוצה להעביר הלאה יום אחד?", "¿Qué tradición de tu familia te gustaría transmitir algún día?", "Какую семейную традицию Вам хотелось бы когда-нибудь передать дальше?"],
  ["q041", "judaism", "Quel souvenir de synagogue ou de communauté t'a marqué dans l'enfance ?", "What memory of synagogue or community life marked you in childhood?", "איזה זיכרון מבית הכנסת או מהקהילה נחרט בילדות?", "¿Qué recuerdo de la sinagoga o de la comunidad te marcó en la infancia?", "Какое воспоминание о синагоге или общине осталось у Вас с детства?"],
  ["q042", "judaism", "Comment aimerais-tu que nous vivions la communauté juive autour de nous ?", "How would you like us to be part of the Jewish community around us?", "איך היית רוצה שנהיה חלק מהקהילה היהודית סביבנו?", "¿Cómo te gustaría que formáramos parte de la comunidad judía que nos rodea?", "Как Вам хотелось бы, чтобы мы участвовали в жизни еврейской общины рядом с нами?"],
  ["q043", "judaism", "Quel est ton plus beau souvenir d'un Séder de Pessah ?", "What is your fondest memory of a Passover Seder?", "מהו הזיכרון היפה ביותר שלך מליל סדר של פסח?", "¿Cuál es tu recuerdo más bonito de un Séder de Pésaj?", "Какое самое тёплое Ваше воспоминание о пасхальном седере?"],
  ["q044", "judaism", "Qu'est-ce que Roch Hachana et Kippour évoquent en toi ?", "What do Rosh Hashanah and Yom Kippur evoke in you?", "מה עולה בך בראש השנה וביום כיפור?", "¿Qué te evocan Rosh Hashaná y Yom Kipur?", "Что вызывают у Вас Рош а-Шана и Йом-Киппур?"],
  ["q045", "judaism", "Quelle bougie, quelle chanson ou quelle odeur te ramène immédiatement à une fête juive ?", "Which candle, song or smell instantly takes you back to a Jewish holiday?", "איזה נר, שיר או ריח מחזירים אותך מיד לחג יהודי?", "¿Qué vela, canción o aroma te devuelve enseguida a una fiesta judía?", "Что сразу возвращает Вас к еврейскому празднику: песня, запах, свечи?"],
  ["q046", "judaism", "Comment aimerais-tu que l'on célèbre Hanoucca, ou la fête de ton choix, chez nous ?", "How would you like us to celebrate Hanukkah, or the holiday of your choice, at home?", "איך היית רוצה שנחגוג חנוכה, או כל חג אחר לבחירתך, אצלנו בבית?", "¿Cómo te gustaría que celebráramos Janucá, o la fiesta que elijas, en casa?", "Как Вам хотелось бы отмечать Хануку или любой другой выбранный Вами праздник у нас дома?"],
  ["q047", "judaism", "Quelle place aimerais-tu donner à la prière, ou à un moment de recueillement, dans notre vie ?", "What role would you like prayer, or a moment of reflection, to have in our life?", "איזה מקום היית רוצה שיהיה לתפילה, או לרגע של התבוננות, בחיינו?", "¿Qué papel te gustaría que tuvieran la oración, o un momento de recogimiento, en nuestra vida?", "Какое место Вам хотелось бы отвести в нашей жизни молитве или минуте тишины?"],
  ["q048", "judaism", "Quelle valeur de la tradition juive te parle le plus aujourd'hui ?", "Which value of Jewish tradition speaks to you the most today?", "איזה ערך מהמסורת היהודית מדבר אליך הכי הרבה היום?", "¿Qué valor de la tradición judía te habla más hoy?", "Какая ценность еврейской традиции сегодня ближе всего Вам?"],
  ["q049", "judaism", "Quel livre, quelle histoire ou quelle parabole de la tradition juive aimes-tu relire ou raconter ?", "What book, story or parable from Jewish tradition do you like to reread or retell?", "איזה ספר, סיפור או משל מהמסורת היהודית תמיד כיף לקרוא שוב או לספר?", "¿Qué libro, historia o parábola de la tradición judía te gusta releer o contar?", "Какую книгу, историю или притчу еврейской традиции Вам нравится перечитывать или рассказывать?"],
  ["q050", "judaism", "Comment célébrait-on, dans ta famille, une naissance, une bar ou bat-mitsva, un mariage ?", "How did your family celebrate a birth, a bar or bat mitzvah, or a wedding?", "איך חגגו במשפחה שלך לידה, בר או בת מצווה, או חתונה?", "¿Cómo celebraba tu familia un nacimiento, un bar o bat mitzvá, o una boda?", "Как в Вашей семье отмечали рождение ребёнка, бар- или бат-мицву, свадьбу?"],
  ["q051", "judaism", "Y a-t-il dans ta famille un prénom hébraïque ou une histoire de prénom qui te tient à cœur ?", "Is there a Hebrew name or a naming story in your family that is dear to you?", "יש במשפחה שלך שם עברי או סיפור על שם שחשוב לך?", "¿Hay en tu familia un nombre hebreo o una historia de nombre que te importe?", "Есть ли в Вашей семье еврейское имя или история имени, которая Вам дорога?"],
  ["q052", "judaism", "Quel plaisir trouves-tu à recevoir des invités à notre table, pour Shabbat ou une fête ?", "What do you enjoy about hosting guests at our table, for Shabbat or a holiday?", "מה כיף באירוח אורחים בשולחן שלנו, בשבת או בחג?", "¿Qué disfrutas de recibir invitados en nuestra mesa, en Shabat o en una fiesta?", "Что Вам нравится в приёме гостей за нашим столом в Шаббат или праздник?"],
  ["q053", "judaism", "Quelle mitsva, grande ou petite, te semble la plus belle à accomplir à deux ?", "Which mitzvah, big or small, seems the most beautiful to do together?", "איזו מצווה, גדולה או קטנה, יפה במיוחד לקיים יחד?", "¿Qué mitzvá, grande o pequeña, te parece más bonita para cumplir juntos?", "Какая заповедь, большая или малая, кажется Вам самой прекрасной для совместного исполнения?"],
  ["q054", "judaism", "Comment vois-tu l'histoire de ta famille à travers les pays et les générations ?", "How do you see your family's story across countries and generations?", "איך נראה סיפור המשפחה שלך לאורך מדינות ודורות?", "¿Cómo ves la historia de tu familia a través de países y generaciones?", "Как Вы видите историю Вашей семьи сквозь страны и поколения?"],
  ["q055", "judaism", "Quelle chanson juive, un niggoun ou un chant de fête, aimerais-tu chanter ensemble ?", "Which Jewish song, a niggun or a holiday melody, would you like us to sing together?", "איזה שיר יהודי, ניגון או שיר חג, היית רוצה שנשיר יחד?", "¿Qué canción judía, un nigún o un canto de fiesta, te gustaría que cantáramos juntos?", "Какую еврейскую песню, нигун или праздничную мелодию, Вам хотелось бы спеть вместе?"],
  ["q056", "judaism", "Quel rituel, juif ou non, aimerais-tu créer rien que pour nous deux ?", "What ritual, Jewish or not, would you like to create just for the two of us?", "איזה טקס, יהודי או לא, היית רוצה ליצור רק לשנינו?", "¿Qué ritual, judío o no, te gustaría crear solo para nosotros dos?", "Какой ритуал, еврейский или нет, Вам хотелось бы создать только для нас двоих?"],

  ["q057", "appreciation", "Pour quoi ressens-tu le plus de gratitude dans notre couple en ce moment ?", "What are you most grateful for in our relationship right now?", "על מה יש לך הכי הרבה הכרת תודה בקשר שלנו כרגע?", "¿Por qué sientes más gratitud en nuestra relación en este momento?", "За что Вы особенно благодарны в наших отношениях сейчас?"],
  ["q058", "appreciation", "Quelle qualité de l'autre aimerais-tu mettre en lumière aujourd'hui ?", "Which quality of your partner would you like to highlight today?", "איזו תכונה טובה של הצד השני היית רוצה להאיר היום?", "¿Qué cualidad de tu pareja te gustaría destacar hoy?", "Какое качество партнёра Вам хотелось бы отметить сегодня?"],
  ["q059", "appreciation", "Quel effort de l'autre as-tu remarqué récemment sans le dire ?", "What effort from your partner have you noticed lately without saying so?", "איזו השקעה של הצד השני שמת לב אליה לאחרונה מבלי לומר?", "¿Qué esfuerzo de tu pareja has notado últimamente sin decirlo?", "Какое усилие партнёра Вы недавно заметили, но не сказали об этом?"],
  ["q060", "appreciation", "Comment la présence de l'autre te fait-elle grandir ?", "How does your partner help you grow?", "איך הנוכחות של הצד השני עוזרת לך לצמוח?", "¿Cómo te ayuda tu pareja a crecer?", "Как присутствие партнёра помогает Вам расти?"],
  ["q061", "appreciation", "Quelle petite chose de l'autre, souvent oubliée, mérite un grand merci ?", "What small thing does your partner do, often overlooked, that deserves a big thank-you?", "איזה דבר קטן שהצד השני עושה, ולרוב לא שמים לב אליו, ראוי לתודה גדולה?", "¿Qué pequeña cosa de tu pareja, a menudo pasada por alto, merece un gran gracias?", "Какая мелочь, которую делает партнёр и которую часто не замечают, заслуживает большой благодарности?"],
  ["q062", "appreciation", "Quel compliment de l'autre t'a le plus touché ?", "Which compliment from your partner touched you the most?", "איזו מחמאה מהצד השני נגעה בך הכי הרבה?", "¿Qué cumplido de tu pareja te ha emocionado más?", "Какой комплимент партнёра тронул Вас больше всего?"],
  ["q063", "appreciation", "Qu'admires-tu dans la façon dont l'autre est avec ses proches ?", "What do you admire in the way your partner treats their loved ones?", "מה מעורר בך הערכה באופן שבו הצד השני מתייחס לאנשים הקרובים?", "¿Qué admiras de cómo trata tu pareja a sus seres queridos?", "Что Вы цените в том, как партнёр относится к близким людям?"],
  ["q064", "appreciation", "Qu'est-ce qui, dans le soutien de l'autre, t'aide le plus dans les moments difficiles ?", "What about your partner's support helps you the most in hard times?", "מה בתמיכה של הצד השני עוזר לך הכי הרבה ברגעים קשים?", "¿Qué del apoyo de tu pareja te ayuda más en los momentos difíciles?", "Что в поддержке партнёра помогает Вам больше всего в трудные минуты?"],
  ["q065", "appreciation", "Si tu écrivais un petit mot à l'autre ce soir, que dirait-il ?", "If you wrote a short note to your partner tonight, what would it say?", "אם הייתה נכתבת הערב הודעה קצרה לצד השני, מה היה כתוב בה?", "Si escribieras una notita a tu pareja esta noche, ¿qué diría?", "Если бы Вы написали сегодня вечером короткую записку партнёру, что в ней было бы?"],

  ["q066", "memories", "Quel moment a été notre plus beau fou rire ensemble ?", "What was our best shared burst of laughter?", "איזה רגע היה הצחוק הגדול ביותר שלנו יחד?", "¿Qué momento fue nuestra mejor carcajada juntos?", "Какой момент был нашим самым заразительным общим смехом?"],
  ["q067", "memories", "Que te rappelles-tu de notre toute première rencontre ?", "What do you remember about the very first time we met?", "מה זכור לך מהפגישה הראשונה שלנו?", "¿Qué recuerdas de la primera vez que nos vimos?", "Что Вы помните о нашей самой первой встрече?"],
  ["q068", "memories", "Quel voyage ensemble garde une place à part dans ta mémoire ?", "Which trip together holds a special place in your memory?", "איזה טיול משותף נשאר לך כזיכרון מיוחד במיוחד?", "¿Qué viaje juntos ocupa un lugar especial en tu memoria?", "Какая совместная поездка занимает особое место в Вашей памяти?"],
  ["q069", "memories", "Quelle chanson te rappelle le début de notre histoire ?", "Which song reminds you of the start of our story?", "איזה שיר מזכיר לך את תחילת הסיפור שלנו?", "¿Qué canción te recuerda el comienzo de nuestra historia?", "Какая песня напоминает Вам о начале нашей истории?"],
  ["q070", "memories", "Quel cadeau, petit ou grand, reçu dans notre couple t'a le plus marqué ?", "Which gift, big or small, received in our relationship meant the most to you?", "איזו מתנה, קטנה או גדולה, שקיבלת בקשר שלנו הייתה הכי משמעותית?", "¿Qué regalo, pequeño o grande, recibido en nuestra relación ha significado más para ti?", "Какой подарок, маленький или большой, полученный в наших отношениях, значит для Вас больше всего?"],
  ["q071", "memories", "Quelle épreuve avons-nous traversée ensemble qui nous a rendus plus forts ?", "What challenge did we go through together that made us stronger?", "איזה אתגר עברנו יחד שהפך אותנו לחזקים יותר?", "¿Qué prueba atravesamos juntos que nos hizo más fuertes?", "Какое испытание мы прошли вместе, и оно сделало нас сильнее?"],
  ["q072", "memories", "Quel endroit a une signification particulière pour nous deux ?", "Which place has a special meaning for the two of us?", "איזה מקום משמעותי במיוחד עבור שנינו?", "¿Qué lugar tiene un significado especial para los dos?", "Какое место имеет особое значение для нас двоих?"],
  ["q073", "memories", "Quel souvenir d'enfance aimerais-tu partager, que tu n'as pas encore raconté ?", "What childhood memory would you like to share that you haven't told yet?", "איזה זיכרון מהילדות היית רוצה לשתף שעוד לא סיפרת?", "¿Qué recuerdo de la infancia te gustaría compartir que aún no hayas contado?", "Каким детским воспоминанием Вам хотелось бы поделиться, которое Вы ещё не рассказывали?"],
  ["q074", "memories", "Quelle photo de nous deux préfères-tu, et que raconte-t-elle ?", "Which photo of the two of us is your favorite, and what story does it tell?", "איזו תמונה שלנו היא האהובה עליך, ומה היא מספרת?", "¿Cuál es tu foto favorita de nosotros dos y qué cuenta?", "Какая наша общая фотография нравится Вам больше всего и о чём она рассказывает?"],

  ["q075", "wellbeing", "Qu'est-ce qui t'aiderait à te sentir bien cette semaine ?", "What would help you feel good this week?", "מה יעזור לך להרגיש טוב השבוע?", "¿Qué te ayudaría a sentirte bien esta semana?", "Что помогло бы Вам хорошо себя чувствовать на этой неделе?"],
  ["q076", "wellbeing", "Quand te sens-tu le plus en paix avec toi-même ?", "When do you feel most at peace with yourself?", "מתי יש לך תחושה של שלווה פנימית הכי גדולה?", "¿Cuándo te sientes más en paz contigo?", "Когда Вы чувствуете наибольшее умиротворение?"],
  ["q077", "wellbeing", "Qu'est-ce qui pèse un peu sur toi en ce moment, et comment pourrait-on l'alléger ensemble ?", "What is weighing on you a little right now, and how could we lighten it together?", "מה מעיק עליך קצת כרגע, ואיך אפשר להקל על זה יחד?", "¿Qué te pesa un poco ahora mismo y cómo podríamos aligerarlo juntos?", "Что сейчас немного тяготит Вас и как мы могли бы облегчить это вместе?"],
  ["q078", "wellbeing", "Comment dors-tu en ce moment, et que pourrait-on faire pour mieux se reposer ?", "How have you been sleeping lately, and what could we do to rest better?", "איך השינה לאחרונה, ומה אפשר לעשות כדי לנוח טוב יותר?", "¿Cómo has dormido últimamente y qué podríamos hacer para descansar mejor?", "Как Вы спите в последнее время и что мы могли бы сделать, чтобы лучше отдыхать?"],
  ["q079", "wellbeing", "Quel petit geste de l'autre t'aiderait le plus un jour de fatigue ?", "What small gesture from your partner would help you most on a tiring day?", "איזו מחווה קטנה מהצד השני תעזור הכי הרבה ביום מתיש?", "¿Qué pequeño gesto de tu pareja te ayudaría más en un día de cansancio?", "Какой небольшой жест партнёра больше всего помог бы Вам в утомительный день?"],
  ["q080", "wellbeing", "Quel moment de la journée te donne le plus d'énergie ?", "Which time of day gives you the most energy?", "איזו שעה ביום נותנת הכי הרבה אנרגיה?", "¿Qué momento del día te da más energía?", "Какое время суток дарит Вам больше всего энергии?"],
  ["q081", "wellbeing", "Qu'aimerais-tu te pardonner, ou te permettre, cette année ?", "What would you like to forgive yourself for, or allow yourself, this year?", "מה היית רוצה לסלוח לעצמך או להרשות לעצמך השנה?", "¿Qué te gustaría perdonarte o permitirte este año?", "Что Вы хотели бы простить себе или позволить себе в этом году?"],

  ["q082", "values", "Quelle valeur voudrais-tu qu'on ne sacrifie jamais, même sous pression ?", "Which value would you never want us to sacrifice, even under pressure?", "איזה ערך לא היית רוצה שנקריב לעולם, גם בלחץ?", "¿Qué valor no te gustaría que sacrificáramos nunca, ni siquiera bajo presión?", "Какой ценностью Вы не хотели бы жертвовать никогда, даже под давлением?"],
  ["q083", "values", "Qu'est-ce que la confiance veut dire pour toi dans un couple ?", "What does trust mean to you in a relationship?", "מה משמעות האמון בעיניך בזוגיות?", "¿Qué significa para ti la confianza en una pareja?", "Что значит для Вас доверие в паре?"],
  ["q084", "values", "Comment aimerais-tu qu'on gère un désaccord pour qu'il nous rapproche ?", "How would you like us to handle a disagreement so that it brings us closer?", "איך היית רוצה שנתמודד עם חילוקי דעות כך שיקרבו אותנו?", "¿Cómo te gustaría que gestionáramos un desacuerdo para que nos acerque?", "Как Вам хотелось бы улаживать разногласия, чтобы они сближали нас?"],
  ["q085", "values", "Quelle place donnes-tu à la générosité, envers les autres et envers nous ?", "What place do you give to generosity, toward others and toward us?", "איזה מקום יש לנדיבות בעיניך, כלפי אחרים וכלפינו?", "¿Qué lugar le das a la generosidad, hacia los demás y hacia nosotros?", "Какое место Вы отводите щедрости, по отношению к другим и к нам?"],
  ["q086", "values", "Comment fais-tu pour demander pardon, et comment aimes-tu qu'on te le demande ?", "How do you say sorry, and how do you like to be told sorry?", "איך מבקשים סליחה אצלך, ואיך נעים לשמוע אותה?", "¿Cómo pides perdón y cómo te gusta que te lo pidan?", "Как Вы просите прощения и как Вам приятнее получать извинения?"],
  ["q087", "values", "Qu'est-ce qui compte le plus pour toi quand on prend une grande décision à deux ?", "What matters most to you when we make a big decision together?", "מה הכי חשוב לך כשמקבלים החלטה גדולה יחד?", "¿Qué es lo que más te importa cuando tomamos juntos una gran decisión?", "Что для Вас важнее всего, когда мы вместе принимаем большое решение?"],
  ["q088", "values", "Quel équilibre voudrais-tu entre le temps à deux, le temps seul et le temps avec les autres ?", "What balance would you like between time together, time alone and time with others?", "איזה איזון היית רוצה בין זמן משותף, זמן לבד וזמן עם אחרים?", "¿Qué equilibrio te gustaría entre el tiempo en pareja, a solas y con otras personas?", "Какого баланса Вам хотелось бы между временем вдвоём, наедине с собой и с другими людьми?"],
  ["q089", "values", "Quelle leçon de vie de tes parents ou grands-parents gardes-tu précieusement ?", "What life lesson from your parents or grandparents do you hold on to?", "איזה לקח חיים מההורים או מהסבים והסבתות נשאר איתך?", "¿Qué lección de vida de tus padres o abuelos conservas?", "Какой жизненный урок от родителей или бабушек и дедушек Вы сохранили?"],
  ["q090", "values", "Quelle qualité souhaites-tu cultiver davantage cette année, pour toi et pour nous ?", "Which quality do you want to cultivate more this year, for yourself and for us?", "איזו תכונה היית רוצה לטפח יותר השנה, בשבילך ובשבילנו?", "¿Qué cualidad quieres cultivar más este año, para ti y para nosotros?", "Какое качество Вы хотели бы развивать в этом году, для себя и для нас?"],

  ["q091", "future", "Où nous vois-tu dans cinq ans ?", "Where do you see us in five years?", "איך נראים החיים שלנו בעוד חמש שנים, לפי דמיונך?", "¿Dónde nos ves dentro de cinco años?", "Где Вы видите нас через пять лет?"],
  ["q092", "future", "Quel projet à deux aimerais-tu lancer cette année ?", "What project for the two of us would you like to start this year?", "איזה פרויקט משותף היית רוצה להתחיל השנה?", "¿Qué proyecto de pareja te gustaría empezar este año?", "Какой совместный проект Вы хотели бы начать в этом году?"],
  ["q093", "future", "Comment imagines-tu notre vie dans dix ans, un mardi ordinaire ?", "How do you imagine our life in ten years, on an ordinary Tuesday?", "איך נראה יום שלישי רגיל בחיינו בעוד עשר שנים?", "¿Cómo imaginas nuestra vida dentro de diez años, un martes cualquiera?", "Как Вы представляете нашу жизнь через десять лет, в самый обычный вторник?"],
  ["q094", "future", "Quel pays ou quelle ville aimerais-tu qu'on découvre ensemble dans l'année qui vient ?", "Which country or city would you like us to discover together in the coming year?", "איזו מדינה או עיר היית רוצה שנגלה יחד בשנה הקרובה?", "¿Qué país o ciudad te gustaría que descubriéramos juntos el próximo año?", "Какую страну или город Вам хотелось бы открыть вместе в ближайший год?"],
  ["q095", "future", "Quelle étape importante de notre vie à deux attends-tu avec le plus d'impatience ?", "Which important step in our life together are you most looking forward to?", "לאיזה שלב חשוב בחיינו המשותפים יש לך הכי הרבה ציפייה?", "¿Qué etapa importante de nuestra vida juntos esperas con más ilusión?", "Какого важного этапа нашей совместной жизни Вы ждёте с наибольшим нетерпением?"],
  ["q096", "future", "Quelle habitude saine aimerais-tu adopter ensemble dans les prochains mois ?", "What healthy habit would you like us to adopt together in the coming months?", "איזה הרגל בריא היית רוצה שנאמץ יחד בחודשים הקרובים?", "¿Qué hábito saludable te gustaría que adoptáramos juntos en los próximos meses?", "Какую полезную привычку Вам хотелось бы перенять вместе в ближайшие месяцы?"],
  ["q097", "future", "Que souhaites-tu construire ensemble que l'on pourra transmettre un jour ?", "What would you like us to build together that we can hand down one day?", "מה היית רוצה שנבנה יחד כדי להעביר הלאה יום אחד?", "¿Qué te gustaría que construyéramos juntos para poder transmitirlo algún día?", "Что Вам хотелось бы построить вместе, чтобы когда-нибудь передать дальше?"],
  ["q098", "future", "De quoi aimerais-tu qu'on s'occupe en priorité pour préparer l'avenir ?", "What would you like us to take care of first to prepare for the future?", "במה היית רוצה שנטפל קודם כדי להתכונן לעתיד?", "¿De qué te gustaría que nos ocupáramos primero para preparar el futuro?", "Чем Вам хотелось бы заняться в первую очередь, чтобы подготовиться к будущему?"],
  ["q099", "future", "Quelle nouvelle tradition à nous aimerais-tu inventer pour les années à venir ?", "What new tradition of our own would you like to invent for the years ahead?", "איזו מסורת חדשה משלנו היית רוצה להמציא לשנים הבאות?", "¿Qué nueva tradición propia te gustaría inventar para los próximos años?", "Какую новую собственную традицию Вам хотелось бы придумать на ближайшие годы?"],
  ["q100", "future", "Dans un an, que voudrais-tu pouvoir dire de l'année que nous venons de vivre ?", "A year from now, what would you like to say about the year we have just lived?", "בעוד שנה, מה היית רוצה לומר על השנה שחלפה עלינו?", "Dentro de un año, ¿qué te gustaría poder decir del año que acabamos de vivir?", "Что Вам хотелось бы сказать через год о только что прожитом нами годе?"],

  ["q101", "family", "Quel souvenir de ta famille te fait toujours sourire ?", "What memory of your family always makes you smile?", "איזה זיכרון מהמשפחה תמיד מעלה חיוך?", "¿Qué recuerdo de tu familia te hace sonreír siempre?", "Какое воспоминание о Вашей семье всегда вызывает улыбку?"],
  ["q102", "family", "Qu'est-ce que tes grands-parents t'ont transmis, sans forcément le dire ?", "What did your grandparents pass on to you, without necessarily saying it?", "מה הסבים והסבתות העבירו אליך, גם בלי לומר זאת?", "¿Qué te transmitieron tus abuelos, sin necesariamente decirlo?", "Что передали Вам бабушки и дедушки, даже не говоря об этом?"],
  ["q103", "family", "Comment ta famille se retrouvait-elle quand il y avait un moment difficile ?", "How did your family come together in a hard moment?", "איך המשפחה שלך התכנסה ברגעים קשים?", "¿Cómo se reunía tu familia en los momentos difíciles?", "Как Ваша семья собиралась вместе в трудные моменты?"],
  ["q104", "family", "Qu'aimerais-tu faire autrement de ce que tu as connu dans ta famille ?", "What would you like to do differently from what you knew in your family?", "מה היית רוצה לעשות אחרת ממה שהכרת בבית?", "¿Qué te gustaría hacer de otra manera respecto a lo que viviste en tu familia?", "Что Вам хотелось бы делать иначе, чем в семье, где Вы выросли?"],
  ["q105", "family", "Qui, dans ta famille, t'a le plus inspiré, et pourquoi ?", "Who in your family has inspired you the most, and why?", "מי במשפחה שלך נתן לך הכי הרבה השראה, ולמה?", "¿Quién de tu familia te ha inspirado más y por qué?", "Кто из Вашей семьи вдохновил Вас больше всего и почему?"],
  ["q106", "family", "Comment aimerais-tu que nos familles se connaissent mieux ?", "How would you like our families to get to know each other better?", "איך היית רוצה שהמשפחות שלנו יכירו זו את זו טוב יותר?", "¿Cómo te gustaría que nuestras familias se conocieran mejor?", "Как Вам хотелось бы, чтобы наши семьи лучше узнали друг друга?"],
  ["q107", "family", "Quelle place veux-tu donner à nos proches dans notre quotidien ?", "What place do you want our loved ones to have in our daily life?", "איזה מקום היית רוצה לתת לקרובינו בחיי היום-יום שלנו?", "¿Qué lugar quieres darles a nuestros seres queridos en el día a día?", "Какое место Вы хотели бы отвести нашим близким в повседневной жизни?"],
  ["q108", "family", "Quelle histoire drôle revient chaque fois que ta famille est réunie ?", "What funny story comes up every time your family is together?", "איזה סיפור מצחיק חוזר בכל פעם שהמשפחה שלך מתכנסת?", "¿Qué historia divertida sale cada vez que tu familia se reúne?", "Какая смешная история всплывает каждый раз, когда собирается Ваша семья?"],
  ["q109", "family", "Quelle image de notre couple aimerais-tu laisser à nos proches ?", "What image of our couple would you like to leave with our loved ones?", "איזו תמונה של הזוגיות שלנו היית רוצה להשאיר אצל הקרובים לנו?", "¿Qué imagen de nuestra pareja te gustaría dejar en nuestros seres queridos?", "Какой образ нашей пары Вам хотелось бы оставить у наших близких?"],
  ["q110", "family", "Quelle réunion de famille attends-tu chaque année avec le plus de joie ?", "Which family gathering do you look forward to most every year?", "לאיזה מפגש משפחתי יש לך הכי הרבה ציפייה בכל שנה?", "¿Qué reunión familiar esperas con más alegría cada año?", "Какой семейный праздник Вы ждёте каждый год с наибольшей радостью?"],

  ["q111", "fun", "Si notre histoire était un film, quel en serait le titre ?", "If our story were a movie, what would its title be?", "אילו הסיפור שלנו היה סרט, איך היה נקרא?", "Si nuestra historia fuera una película, ¿cómo se titularía?", "Если бы наша история была фильмом, как бы он назывался?"],
  ["q112", "fun", "Quel super-pouvoir aimerais-tu avoir pour une journée ?", "What superpower would you like to have for a day?", "איזה כוח-על היית רוצה לקבל ליום אחד?", "¿Qué superpoder te gustaría tener por un día?", "Какую суперспособность Вы хотели бы получить на один день?"],
  ["q113", "fun", "Quel menu de rêve composerais-tu pour un dîner à deux ?", "What dream menu would you put together for a dinner for two?", "איזה תפריט חלומות יהיה מושלם לארוחת ערב לשניים?", "¿Qué menú de ensueño prepararías para una cena de dos?", "Какое меню мечты Вы составили бы для ужина вдвоём?"],
  ["q114", "fun", "Quel talent caché as-tu que presque personne ne connaît ?", "What hidden talent do you have that almost nobody knows about?", "איזה כישרון נסתר יש לך שכמעט אף אחד לא מכיר?", "¿Qué talento oculto tienes que casi nadie conoce?", "Какой скрытый талант есть у Вас, о котором почти никто не знает?"],
  ["q115", "fun", "Si on échangeait nos rôles pendant une journée, quelle serait la plus grande surprise ?", "If we swapped roles for a day, what would be the biggest surprise?", "אילו החלפנו תפקידים ליום אחד, מה היה המפתיע ביותר?", "Si intercambiáramos los roles por un día, ¿cuál sería la mayor sorpresa?", "Если бы мы поменялись ролями на один день, что оказалось бы самым неожиданным?"],
  ["q116", "fun", "Quel surnom ou quelle expression n'appartient qu'à nous deux ?", "What nickname or expression belongs only to the two of us?", "איזה כינוי או ביטוי שייך רק לשנינו?", "¿Qué apodo o expresión es solo nuestro?", "Какое прозвище или выражение принадлежит только нам двоим?"],
  ["q117", "fun", "Quelle serait la bande-son de notre semaine, en trois chansons ?", "What would the soundtrack of our week be, in three songs?", "מהו פס הקול של השבוע שלנו, בשלושה שירים?", "¿Cuál sería la banda sonora de nuestra semana en tres canciones?", "Какой была бы музыкальная дорожка нашей недели из трёх песен?"],
  ["q118", "fun", "Quel jeu de société ou quelle activité un peu absurde aimerais-tu qu'on essaie ?", "Which board game or slightly silly activity would you like us to try?", "איזה משחק קופסה או פעילות קצת מטופשת היית רוצה שננסה?", "¿Qué juego de mesa o actividad un poco absurda te gustaría que probáramos?", "Какую настольную игру или слегка нелепое занятие Вам хотелось бы попробовать вместе?"],
  ["q119", "fun", "Quelle est la chose la plus drôle que l'on ait faite ensemble sans le vouloir ?", "What is the funniest thing we have done together by accident?", "מהו הדבר המצחיק ביותר שעשינו יחד בלי כוונה?", "¿Cuál es lo más gracioso que hemos hecho juntos sin querer?", "Что самое смешное мы сделали вместе нечаянно?"],
  ["q120", "fun", "Si tu pouvais inviter à dîner avec nous une personne, vivante ou non, qui choisirais-tu ?", "If you could invite one person, living or not, to dinner with us, who would it be?", "את מי היינו מזמינים לארוחה, אילו אפשר היה לבחור כל אדם, חי או לא?", "Si pudieras invitar a cenar con nosotros a una persona, viva o no, ¿a quién elegirías?", "Если бы Вы могли пригласить к нам на ужин одного человека, живого или нет, кого бы Вы выбрали?"],
];

export const QUESTION_BANK: readonly BankQuestion[] = ROWS.map(
  ([key, category, fr, en, he, es, ru]): BankQuestion => ({
    key,
    category,
    text: { fr, en, he, es, ru },
  }),
);

const BY_KEY: ReadonlyMap<string, BankQuestion> = new Map(
  QUESTION_BANK.map((question) => [question.key, question]),
);

export function questionByKey(key: string): BankQuestion | undefined {
  return BY_KEY.get(key);
}

export function questionText(question: BankQuestion, language: QuestionLanguage): string {
  return question.text[language];
}

const DEFAULT_LANGUAGE: QuestionLanguage = "fr";

const PRIMARY_TAG_TO_LANGUAGE: Readonly<Record<string, QuestionLanguage>> = {
  fr: "fr",
  en: "en",
  he: "he",
  iw: "he",
  es: "es",
  ru: "ru",
};

interface WeightedTag {
  readonly language: QuestionLanguage | undefined;
  readonly weight: number;
  readonly order: number;
}

function parseEntry(entry: string, order: number): WeightedTag {
  const [rawTag = "", ...params] = entry.split(";");
  const primary = rawTag.trim().toLowerCase().split("-")[0] ?? "";
  let weight = 1;
  for (const param of params) {
    const [name, value] = param.split("=");
    if (name?.trim().toLowerCase() === "q") {
      const parsed = Number.parseFloat(value ?? "");
      weight = Number.isFinite(parsed) ? parsed : 0;
    }
  }
  return { language: PRIMARY_TAG_TO_LANGUAGE[primary], weight, order };
}

export function languageFromAcceptLanguage(header: string | null | undefined): QuestionLanguage {
  if (!header) return DEFAULT_LANGUAGE;
  const candidates = header
    .split(",")
    .map((entry, order) => parseEntry(entry, order))
    .filter((tag) => tag.language !== undefined && tag.weight > 0)
    .sort((a, b) => b.weight - a.weight || a.order - b.order);
  return candidates[0]?.language ?? DEFAULT_LANGUAGE;
}
