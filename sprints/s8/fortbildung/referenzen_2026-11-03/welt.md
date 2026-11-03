# Referenzen: Welt, Orte und Look (Stand 2026-11-03)

Marken: [B] belegt, URL genannt; [E] Gedächtnis oder Einzelstimme, ungeprüft; [R] eigene Rechnung. WebFetch-Zusammenfassungen kommen von einem kleinen Modell und sind nicht wörtlich geprüft; den OpenTTD-Quellcode habe ich selbst gelesen (github.com/OpenTTD/OpenTTD, src/town_cmd.cpp, industry_cmd.cpp, map_func.h, table/settings/economy_settings.ini, Master vom 03.11.2026).

## 1. Ortswachstum durch Versorgung (Stadt-Design)

| Spiel | Mechanik | Quelle | |
|---|---|---|---|
| OpenTTD | Tempo hängt nur an der Zahl aktiver Stationen im Ort (Umschlag in ca. 50 Tagen), nicht an Menge oder Art. Intervall-Tabelle 320/420/300/220/160/100 für 0 bis 5+ Stationen, bei Standardtempo halbiert, geteilt durch (Häuser/50 + 1), Städte nochmals halb. Orte schrumpfen nie. Nahrung/Wasser nur in Subarktis/Wüste. Rückmeldung nur dort. | [Wiki Towns](https://wiki.openttd.org/en/Manual/Towns), Code oben | [B] |
| Transport Fever 3 | Lieferungen füllen ein Expansionsziel, dann Stufenaufstieg; Wachstum ohne Güter langsamer; Abriss, Lärm, Staus senken Ruf. Anzeige nur indirekt beschrieben. | [GamingTrend](https://gamingtrend.com/news/transport-fever-3-overhauls-city-growth/) | [B], Vorschau |
| TF2 (Mod Logistic Challenge, nicht Basisspiel) | 7 Stufen, Bedarf nach Warenkomplexität; Wachstum alle ca. 12 min bei Versorgung; Schrumpfen möglich; nach Aufstieg zeitlich begrenzte Umbruchphase ohne Schrumpfen; Knopf "Change goods immediately". | [transportfever.net](https://www.transportfever.net/lexicon/entry/427-logistic-challenge-new-gameplay/) | [B] |
| Anno 1800 | Aufstieg: Haus voll, alle Grundbedürfnisse, Baumaterial. Zufriedenheit ist vom Aufstieg entkoppelt (Devblog). Fortschrittsring am Inselporträt, grüne Aufstiegspfeile. Quelle nennt keinen Abstieg. | [Wiki](https://anno1800.fandom.com/wiki/Population), [Devblog](https://www.anno-union.com/en/devblog-happiness/) | [B] |
| Patrician IV | Ohne Wohnraum kein Wachstum; Lagerstandsanzeige je Ware; Markt zeigt Stadtgröße. Keine Wachstumsraten im Handbuch. | [Handbuch](https://www.rune-soft.com/upload/documents/Manual_PDF_Patrician4%20.pdf) | [B] |
| Cities: Skylines | RCI-Balken; Spieler berichten, sie sagten nicht, was fehlt. | [Steam-Thread](https://steamcommunity.com/app/255710/discussions/0/611701360826190651) | [E], Forum |
| Banished | Wachstum an Wohnraum, Gesundheit, Nahrung gebunden; Wiki ohne Zahlen. Todesspirale im Winter nur aus Gedächtnis. | [Banished-Wiki](https://www.banished-wiki.com/wiki/Banished) | [B]/[E] |

**Heißt für uns:** E7 (stabil ohne Versorgung, Wachstum nur mit) entspricht OpenTTD und vermeidet die Todesspirale. Zwei Fallen: OpenTTD wächst mit Größe schneller (Teiler Häuser/50), also Dauerwachstum; und es sagt dem Spieler nichts. Unser Deckel je Epoche und Versorgungsstufe ist die richtige Gegenmaßnahme. Mein Skill nennt "ab 5 Stationen: 80", der Code ergibt 50, und der Häuserteiler fehlt dort.

**Empfehlung:** Schild um Fortschrittsring zur nächsten Klasse und einen Grund "gebremst durch: X" ergänzen (Anno-Ring plus TF-Bedarf). Umbruchphase nach Klassenwechsel prüfen. Aufwand 1 bis 1,5 PT, Test erst als Papier-Schild.

## 2. Kartengeneratoren (Stadt-Design)

| Spiel | Mechanik | Quelle | |
|---|---|---|---|
| OpenTTD Orte | Zufallsfeld; Rand ≥ 12; Manhattan-Abstand zu anderen Orten ≥ 20 (einstellbar 10 bis 500); Feld flach/frei, mindestens die Hälfte eines 5×5-Umfelds geeignet; 20 Versuche je Ort; jeder vierte Ort Stadt; 5/11/23/46 Orte je 256² (+Zufall bis 7), nach Fläche skaliert. In den gelesenen Funktionen kein Flusskriterium. | Quellcode | [B] |
| OpenTTD Industrien | Zufallsfeld, 10/25/55/80 je 256²; typabhängige Prüfungen; unverträgliche Typen nicht innerhalb 14 Feldern; manche nur nahe Ortsmitte (≤ 9) oder ab 1.200 EW. | Quellcode | [B] |
| OpenTTD Optionen | Karte 64 bis 4096, Orte 1 bis 5000, Industrien 1 bis 9999. | [Wiki New game](https://wiki.openttd.org/en/Manual/New%20game) | [B] |
| TF2, Cities | Keine Generator-Angaben gefunden. | | Lücke |

**Heißt für uns:** OpenTTD ist reines Würfeln mit Mindestabstand, keine Rangordnung, keine Lagegründe; wirkt zufällig, weil es zufällig ist. Skalenfrei [R]: 20 Felder sind 3,9 % einer 512er-Kante, unser Dorf–Dorf-Minimum 1,6 km sind 12,5 %. Unser Weg (Rangordnung, Eignung, best candidate) ist strenger als jedes gefundene Spiel.

**Empfehlung:** Nichts übernehmen außer dem Rückfallprinzip "mehrere Versuche, dann Ort streichen statt Regel biegen". Wichtigster Schritt bleibt der Vollkarten-Lauf (20 Seeds, 2 bis 3 PT).

## 3. Maßstab und Lesbarkeit (Art Director)

| Spiel | Befund | Quelle | |
|---|---|---|---|
| OpenTTD | Kachel nur für Geschwindigkeit definiert (ca. 668 km-ish; 100 km/h = 3,6 Kacheln/Tag); keine Meterangabe. Städte ca. 150 bis 200 Kacheln für eine Million. | [Wiki zh](https://wiki.openttd.org/zh/Manual/%E6%B8%B8%E6%88%8F%E6%9C%BA%E5%88%B6), [Towns](https://wiki.openttd.org/en/Manual/Towns) | [B] |
| Cities: Skylines | Kachel 1,92 km, 5×5, 9 bebaubar (33,18 km²). Zelle 8 m: Forum nennt nur ein Modellierraster, 1,92 km/8 m = 240 Zellen passt [R]. | [PC Gamer](https://pcgamer.com/cities-skylines-2-map-size), [Paradox](https://admin-forum.paradoxplaza.com/forum/threads/first-approach-in-modeling-a-building-further-information-much-appreciated.838026) | [B]/[R] |
| Anno 1800 | Wohnhäuser belegen 3×3 Felder; Look historisch inspiriert, nicht dokumentarisch. | [Wiki](https://anno1800.fandom.com/wiki/Population), [Interview](https://www.altchar.com/game-news/anno-1800-pre-beta-interview-with-bastian-thun-of-blue-byte-auh6P6U0rLSO) | [B] |
| TF2 | Keine Maßangaben gefunden. | | Lücke |

**Heißt für uns:** Cities hält Zelle 8 m nahe 1:1, OpenTTD verzichtet ganz auf Metermaß; wir liegen mit 25 m dazwischen, haben aber Sim und Bild getrennt (Halbfeld 12,5 m, Jitter ±2 m/±8°). Das ist der Trick gegen Rasterkanten; Zusatz aus meinem Skill: Townscaper verschiebt Punkte eines verzogenen Gitters [B über Skill].

**Empfehlung:** Rasterkanten an Fluss und Ort mit Vorher/Nachher-Paar prüfen (G2), Fernlesbarkeit über Zeichen. 0,5 Tag.

## 4. Epochen-Look (Art Director, Artist)

| Spiel | Befund | Quelle | |
|---|---|---|---|
| TF2 | Stadtgebäude passen sich den Epochen an, Start 1850; Zahl der Sets nicht genannt. Ein Spieler sah Bauten von 1960 noch stehen: alte bleiben. | [Dev-Blog](https://www.transportfever.com/category/news/page/11/), [Steam](https://steamcommunity.com/sharedfiles/filedetails/comments/2061877310) | [B]/[E] |
| TF2 Mod | Drei Era-Filter A/B/C. | gleiche Steam-Seite | [E] |
| Anno 1800 | Stufen statt Kalenderepochen: 5 Alte Welt, 2 Neue Welt, je eigenes Haus. | [Wiki](https://anno1800.fandom.com/wiki/Population) | [B] |
| Railway Empire 2 | Stadtstufen mit Fabrikfreischaltung, nichts zum Aussehen. | [MGW](https://guides.magicgameworld.com/?p=51367) | [B] |
| Cities (DLC-Sets) | nicht belegt | | Lücke |

**Asset-Mengen:** Keine belegte Zahl für Epochen-Sets. Meine Rechnung [R]: 5 Wohntypen × 2 Epochen-Module × 3 Varianten ≈ 30 Meshes je Epoche, bei Palettenvarianz (bestehend 20×5×4) ohne neue Meshes für Verwitterung.

**Heißt für uns:** K23 (Ersatzneubau plus Altstadtschutz) deckt sich mit dem TF2-Hinweis, dass Altes stehen bleibt.

**Empfehlung (Art Director):** Mischform: Grundform bleibt, Dach/Fassade/Anbau wechseln; Epoche muss im Graustufen- und Silhouettentest trennen. **Artist:** erst Pack-Check W2/W3, dann Module; 1 Tag.

## 5. Vorindustrielle Wassertransporte (Stadt-Design)

| Spiel | Befund | Quelle | |
|---|---|---|---|
| Timberborn | Stämme flussabwärts flößen nur als Wunsch (126 Stimmen, "under consideration"); Flöße, die treiben und an der Station zerlegt werden, Kähne, Schleusen als Vorschläge; Dürre-Pegel als Problem. | [Log-Wunsch](https://timberborn.featureupvote.com/suggestions/211533/allow-or-require-logs-to-the-floated-down-the-river), [Boote/Flöße](https://timberborn.featureupvote.com/suggestions/215867/comment/319475) | [B] |
| Canal Tycoon (angekündigt 2027, 1750 bis 1899) | Schleusen verbrauchen Wasser, Speicher, Zuleitungen; Mühlenbesitzer und Grundbesitzer reden mit; Boote fahren nach Einrichtung selbst. Richtung/Treideln nicht erwähnt. | [Steam](https://store.steampowered.com/app/4883310) | [B] |
| OpenTTD | Schiffe auf ebenem Wasser, Höhe nur per Schleuse. | Skill S26 | [B über Skill] |
| Anno, Patrician, Port Royale, Railroad Tycoon | Kein Einweg-Fluss belegt. | | Lücke |

**Heißt für uns:** Ich fand kein Spiel mit Einbahn-Floß. Das ist Alleinstellung und Risiko. Mechanisch trägt in der Referenz Wasser als knappe Ressource (Canal Tycoon), nicht die Richtung.

**Empfehlung:** Erst Tabellenmodell: Floß als Ware (wird am Ziel zerlegt), Pegel als Schwelle. 1 PT, ohne Assets.

## 6. Eigene Ideen

| Idee | Zielperson | Kosten | Billigster Test | Risiko |
|---|---|---|---|---|
| Lagegrund je Ort (`lagegrund` plus Schildtext) | Basti ("konstruiert"), Entdecker | 1,5 PT | 20 Seeds: Validator; Basti rät 5 Gründe vom Bild | wirkt als Etikett |
| Wachstumsring plus "gebremst durch X" | Mittelspieler, Aylin | 1 bis 1,5 PT | 3 Schildvarianten als Bilder, 3 Testpersonen | Icon-Optimieren |
| Großdorf 400 bis 700 EW (Kirche, Gasthaus) | Basti, Tobias (K18) | 1 PT | Rang-Größe-Plot 20 Seeds | Klassenflut |
| Floßentscheidung je Floß: zerlegt am Ziel, Pegel entscheidet | Holz-Spieler | 1 PT Tabelle, 3 PT Prototyp | Bot im Tal | Einweg nervt, kein Vorbild |
| Umbruchphase nach Klassenwechsel (aus Logistic Challenge) | Einsteiger | 0,5 PT | 60-Monate-Lauf, 12 Monate ohne Lieferung | Aufstieg billig mitnehmen |

**Art Director, Look-Referenzen (in eigenen Worten, nichts nachbauen):** Anno 1800: übernehme Dächer und Materialstufen als Epochenzeichen, ignoriere Überfüllung [B über Skill]. Dorfromantik: übernehme Wertestruktur in Graustufen, ruhig, eine Sonne [B über Skill]. Banished: übernehme gedämpfte, glaubwürdige Hausproportion zum Gelände, ignoriere Detaildichte [E]. OpenTTD: übernehme Zeichen statt Größe für Fernlesbarkeit [E].

**Artist:** Townscaper: Detail an Fügestellen statt Textur [B über Skill]. Firewatch: wenige Baumformen, viel Instanzen [B über Skill]. Folge: Variation über Palette, Rotation, Skala.

## Neue Lern-Zeilen
- 2026-11-03 | OpenTTD-Wachstum im Skill | Tabelle "ab 5: 80" falsch (Code 50), Häuserteiler fehlt | Skill A6 korrigieren
- 2026-11-03 | Generator-Referenzen | tt-forums gesperrt, Quellcode per curl lesbar | Code als Primärquelle nutzen
- 2026-11-03 | Epochen-Look | keine Asset-Zahlen belegbar | eigene Rechnung [R], Pack-Check vorziehen
- 2026-11-03 | Floß | keine Einweg-Referenz | Tabellenmodell vor Prototyp
- 2026-11-03 | WebFetch | nur URLs aus Suchtreffern erlaubt | erst WebSearch, dann Fetch

## Vorschläge für Skill-Änderungen
- mt-stadtdesign A5/A6: OpenTTD-Platzierung (Abstand 20, Rand 12, halbes 5×5, 14-Feld-Konflikt) und korrigierte Wachstumstabelle samt Teiler Häuser/50 ergänzen.
- mt-stadtdesign A6: Referenzzeile Anno-Ring, TF-Umbruchphase (Mod, nicht Basisspiel).
- mt-artdirection C2: Epochen-Look "TF2 und Anno: Alte bleiben, Stufen statt Kalender"; Asset-Mengen weiter offen.
- Alle: Lern-Routine um "Quellcode via curl lesen, WebFetch nur für Suchtreffer-URLs" ergänzen.

Nicht erreichbar: tt-forums.net (Anubis), Paradox-Forum-Thread zu Demand (Browserprüfung), skylines.paradoxwikis.com und banished.fandom.com (Herkunftsprüfung), gameslearningsociety.org (Fehler). Reddit nicht versucht.
