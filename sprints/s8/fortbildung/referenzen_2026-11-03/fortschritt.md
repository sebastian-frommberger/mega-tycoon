# Fortschritt, Zeit und Spielschleife: Referenzen (2026-11-03)

Marken: [B] Quelle geöffnet (WebFetch-Zusammenfassung eines kleinen Modells, nicht wörtlich geprüft), [E] Gedächtnis, [R] meine Rechnung oder Folgerung. Spieleraussagen aus Steam-Threads sind schwächer als Doku. Nicht lesbar: tt-forums.net (Anubis), wiki.openttd.org (Seite Fahrzeugeinführung), Reddit (nicht versucht).

## 1. Zeitskala

**Lena.**

| Spiel | Zahl / Mechanik | Quelle | |
|---|---|---|---|
| OpenTTD | Tag 74 Ticks ≈ 2 s, Monat ≈ 1 min, Jahr ≈ 12 min; Wallclock-Modus mit einstellbaren "Minuten je Jahr" (Standard 12) | openttd.org/news/2024/03/23/timekeeping.html | [B] |
| OpenTTD | Kalenderzeit (Fahrzeuge, Häuser, Optik) getrennt von Wirtschaftszeit (Geld, Wachstum, Kosten); nur die Kalenderrate ist verstellbar | github.com/OpenTTD/OpenTTD/pull/10322 | [B] |
| OpenTTD | Standardstart 1950, Spiel endet nicht 2050 | wiki.openttd.org/en/Manual/FAQ%20general%20questions | [B] |
| Transport Fever 1/2 | TF1 gestoppt ≈ 756 s je Jahr; TF2 "12 min bei Standard-Datumstempo" (zwei Posts desselben Spielers) | steamcommunity.com/app/446800/discussions/0/154642447922562523, .../app/1066780/discussions/0/2639605437882762512 | [B] schwach |
| TF2 | 1850 bis heute, "über 150 Jahre"; Rezensent ca. 25 h Gesamtspielzeit, Kampagne 18 Missionen | gamepressure.com/editorials/transport-fever-2-preview-hope-for-the-railroad/z1197, .../reviews/transport-fever-2-review-good-sim-poor-tycoon/z520c | [B] |
| Railway Empire | Ära = 20 Jahre; Partie endet meist mit der Ära, danach keine Forschungspunkte mehr; Szenarien mit Zeitlimit | download.kalypsomedia.com/railwayempire/PC/US/docs/Railway-Empire_Manual_PC_USA_ONLINE_02.pdf, gigazine.net/gsc_news/en/20200223-railway-empire-review | [B] |
| Railroad Tycoon 3 | 16 Szenarien in 4 Kampagnen (USA 1840–1941, Europa 1840–1914, Welt 1880–1985, Zukunft 2025–2080); Jahrestempo nicht gefunden | en.wikipedia.org/wiki/Railroad_Tycoon_3 | [B] |
| RT1/RT2, Sid Meier's Railroads | Jahrestempo nicht gefunden | – | Lücke |
| Cities: Skylines | Zeit ist Kulisse; CS2-Guide nennt Monat ≈ 72 min, rechnet aber widersprüchlich | gamenguides.com/time-scales-in-cities-skylines-ii | [B] schwach |
| Victoria 3 | 1836–1936; Partie "mehrere bis mehrere Dutzend Stunden" | ggrecon.com/guides/victoria-3-timespan/, gamepressure.com/victoria-3/game-length/zc10560 | [B] schwach |
| Civilization | Jahre je Zug ändern sich mit dem Zeitalter | – | [E] |

**Was heißt das.** Die Echtzeit-Tycoons liegen bei ≈ 12 min je Jahr, wir sind also im Standard. Keiner verlangt aber 200 Jahre am Stück: OpenTTD gibt ein Fenster von etwa 100 Jahren (≈ 20 h [R]), Railway Empire 20-Jahre-Ären, Victoria 3 100 Jahre. Unsere 41 h sind der Ausreißer. Das Konzept (4–10 h) braucht 1,2–2,9 min je Jahr [R]. Der wichtigste Fund: OpenTTD hat Kalender und Wirtschaft entkoppelt, genau unser Konflikt "Ziele in Minuten gegen Epochen in Jahren".

**Empfehlung.** Zwei Uhren: Wirtschaft bleibt 1 min = 1 Monat, nur der Kalender (Epoche, Fahrzeuge, Bild) ist wählbar (E12). Aufwand ≈ 1 PT plus ein Bot-Lauf.

**Jonas.** Entscheiden in S8, weil es G-01 und Skilltree entkoppelt.

## 2. Epochensteuerung

**Lena.**

| Spiel | Mechanik / Befund | Quelle | |
|---|---|---|---|
| OpenTTD | Kalender; Einführungsdatum + 0–511 Tage Zufall, Modelllaufzeit +31 Monate bis 17 Jahre; in den ersten 2 Jahren keine Streuung | newgrf-specs.tt-wiki.net/wiki/Action0General | [B] |
| TF2 | Kalender; Spieler: 1850 sei "langsam und schwach", "alles dauert länger", Rat: 1900 starten oder Geld sparen bis schnellere Loks kommen | steamcommunity.com/app/1066780/discussions/0/599640609289982249 | [B] |
| TF2 | Rezensent: Preise und Rentabilität bleiben über Jahrhunderte gleich, Produktion passt sich Epochen kaum an | gamepressure.com (Review, s. o.) | [B] |
| TF2-Mod | Autor hielt 1850 für "willkürlich", Frühstart ab 1800 möglich; frühe Pferde/Dampf kaum rentabel | transportfever.net/thread/17581-1800-an-early-start-beta-testing-and-complaints-thread/ | [B] |
| Anno 1800 | Meilenstein: Haus voll, Grundbedarf gedeckt, Baumaterial da; Inselstufen z. B. 100 Bauern, 150 Arbeiter, 500 Handwerker | anno1800.fandom.com/wiki/Population | [B] |
| Railway Empire | Mischform: Ära (Kalender) bestimmt Technik, Forschungspunkte füllen den Baum | Kalypso-Handbuch, gamepressure.com/railway-empire-guide/research-bonds-and-acquiring-competitors/z0aa86 | [B] |

**Was heißt das.** Belegt ist das Warten im frühen Kalender (TF2) und die leere Wirtschaft über die Epochen. Zwang durch Meilensteine fand ich nicht belegt. Spieler lösen das Warten über das Startjahr, nicht über Tore.

**Empfehlung.** Kalender = Frühestdatum plus Tor (3 von 5), aber nie beides als Blockade: ab Kalenderjahr sind Fahrzeuge als teurer "Prototyp" kaufbar, das Tor macht sie zur Serie. Aufwand ≈ 2 PT (Lena, Tobias).

**Jonas.** Kalender-Pausieren bis zum Tor streichen: keine Referenz, kollidiert mit Konkurrenz (E14).

## 3. Mittelspiel und Leerlauf

**Lena.**

| Spiel | Mechanik | Quelle | |
|---|---|---|---|
| Satisfactory | 10 Tiers (0–9), Tier 0 = 6 HUB-Stufen (erste kostet 10 Eisenstäbe), Tiers 3–9 hinter 5 Raumaufzug-Phasen, Reihenfolge innerhalb eines Tiers frei; Inhalte sind Fähigkeiten (Fahrzeuge, Blaupausen, Logistik) | satisfactory.wiki.gg/wiki/Tiers, xgamingserver.com/blog/satisfactory-milestones-tech-tree/ | [B] |
| Factorio | Space Age: 60–100 h geplant, 4 Planeten mit je eigenen Zielen; Rakete soll nicht alles auf einmal verlangen; Ziel früh sichtbar | factorio.com/blog/post/fff-373, factorio.com/blog/post/fff-257 | [B] |
| Anno 1800 | Mittelspiel = Versorgungsprobleme (Insel ohne Hopfen, neue Insel, Handelsroute); Kampagne ist Sandbox mit Missionen | pcgamer.com/anno-1800-review, altchar.com (Thun-Interview) | [B] |
| Mini Metro | Jede Woche eine Lok plus Wahl 1 aus 2 Boni | shapes.inc/fandom/mini-metro/upgrades, killtenrats.com/2017/05/30/mini-metro | [B] |
| shapez | 26 Levels, ab 27 Freispiel; Upgrades bis Stufe 1000 mit sinkendem Zuwachs (+0,1, +0,05 …) | shapes.inc/guides/shapez-guide, shapezio.fandom.com/wiki/Upgrading | [B] |
| Timberborn | Spieler: Mittelspiel "wartet" auf Lager; Vorschlag: andere Aufgaben, während es sich füllt | timberborn.featureupvote.com/suggestions/565673/comment/656464 | [B] schwach |
| Zieldichte | Blog: mehrere halb erfüllte Ziele, immer eins nah, kein natürlicher Stopp; Meinung, keine Messung | polylusion-games-site.pages.dev/blog/what-makes-great-tycoon-game | [E] |

**Was heißt das.** Entwicklerberichte mit Zieldichte-Zahlen fand ich nicht. Die Referenzen lösen es strukturell: kleine Wahl im festen Takt (Mini Metro), Fähigkeiten statt Prozente (Satisfactory), neues Terrain (Space Age). Unser "+8 % je Rang" ist die schwächste Form.

**Empfehlung.** Dreitakt: ≤ 3 min Mikro-Wahl, ≈ 8 min Auftragswahl 1 aus 2, je Epoche ein Tor. Aufwand ≈ 3 PT, davon Bot-Messung.

**Jonas.** Das ist G-01 mit Messpunkt. Priorität 1 vor allem Neuen.

## 4. Skilltree und Meilensteine

**Lena.** CS1: 13 Meilensteine, Schwellen je Karte verschieden (120–500 bis 20.000–90.000 EW; segmentnext.com/cities-skylines-milestones-guide/). CS2: 20 Meilensteine über XP statt Einwohner, XP-Bedarf wächst exponentiell, Belohnung = Geld, Entwicklungspunkte, Erweiterungsrechte, am Ende alles freigeschaltet (colossalorder.fi/news/development-diary-10-game-progression/, .../behind-the-scenes-3-game-balancing/); Summe der gelisteten Baumkosten 227 DP (videogamer.com/guides/cities-skylines-2-development-tree-points, vom Modell summiert). Satisfactory: Phasenkosten 50, dann 1.000–2.500 Teile. Anno: 5 + 2 Stufen. Alle [B]. Dauer je Stufe: nirgends belegt.

**Was heißt das.** Für 6 Epochen passt eine Staffel von ≈ 6 Punkten je Epoche (≈ 36 [R]) zur Größenordnung von CS2 (20 Stufen). Abstände wachsen, wie bei Colossal Order.

**Empfehlung.** Tabelle nur für Epoche I–II kalibrieren, Rest mit Messpunkt als Platzhalter. Aufwand ≈ 2 PT.

**Jonas.** Tauschregel: 110 Knoten auf ≈ 40 für I–II kürzen.

## 5. Einstieg

**Lena.** Factorio: Tutorial brauchte 30–45 min bis Automatisierung, galt als zu lang; Rezepte als Forschungsbelohnung, jedes Level startet auf dem Stand des vorigen (FFF-241, [B]). Two Point Hospital: Tutorial nur Bauen, Kamera, Menüs, die meisten spielen ≈ 45 min, Komplexität gestaffelt (pcgamesn.com/two-point-hospital/two-point-hospital-developer-interview, [B]). Satisfactory: erste Stufe kostet 10 Stäbe [B]. TF2: Kampagne als sanfter Start, aber Missionen eintönig, Startgeld wie Cheat (gamepressure, [B]). Unser Slice (7 Ziele in 12 min) steht gut da. Risiko bleibt 1820: Fuhrwerk ist langsam (TF2-Befund). Empfehlung: Slice-Einstieg behalten, für 1820 eine schnelle erste Belohnung messen (Bot, ≈ 0,5 PT).

**Jonas.** Kein Tutorialausbau jetzt.

## 6. Eigene Ideen

| Idee | Zielperson | Kosten | Billigster Test | Risiko |
|---|---|---|---|---|
| A Zwei Uhren (Wirtschaft fix, Kalender wählbar 1,5/3/6/12 min je Jahr) | Basti, Kurzspieler | 1 PT | Bot-Lauf: Minuten bis W2 je Kalenderrate | Preise fühlen sich zeitlos an |
| B Prototyp vor Serie: Fahrzeug ab Kalenderjahr teuer kaufbar, Serie nach Tor (3 von 5) | Optimierer | 2 PT | Skript-Bot kauft Prototyp, misst Gewinn | Tor wirkt wie Hürde |
| C Punkte nach Minute 60: ≈ 6 je Epoche (Tor 2, drei Etappen je 1, Schlüsselfähigkeit 1) | Fortgeschrittene | 2 PT | Tabelle plus Bot, Punktminuten | Zahlen unkalibriert |
| D Dreitakt-Leerlaufregel mit Auftragswahl 1 aus 2 | alle | 3 PT | Bot zählt Lücken ≤ 3 min | Wahl ohne echte Kostenunterschiede |
| E Fenster-Partie: Start- und Endepoche wählbar (Dampfzeit W1–W3 ≈ 3–5 h) | Gelegenspieler | 0,5 PT | Parameter E4/E8 | "bis heute" verliert Reiz |

**Jonas.** Priorität: D vor A vor C; B und E erst nach grünem G-01-Bot. Streichkandidaten gegen den Aufwand: Epochen-Alt-Industrie "vier Zustände" und Preiskampf-Konkurrenz. Basti entscheidet A und E.

## Neue Lern-Zeilen (2026-11-03)

| Datum | Situation | Lücke | Folge |
|---|---|---|---|
| 2026-11-03 | Zeitskala | OpenTTD ≥ 14 trennt Kalender und Wirtschaft [B]; Skill kannte TF2 nur als [E] | A4 ersetzen |
| 2026-11-03 | Zieldichte | Keine Quelle mit Zahlen; nur Blog [E] | Bot statt Recherche |
| 2026-11-03 | Quellen | Reddit/tt-forums zum 2. Mal gesperrt, Zähler 2 | Steam-Threads und Foren der Entwickler nutzen |
| 2026-11-03 | Skilltree | Stufendauer in keinem Spiel belegt | Eigenmessung per Bot |
| 2026-11-03 | PO | Neue Idee ohne Streichkandidat | Tauschregel |

## Vorschläge für Skill-Änderungen (nur Vorschläge)

- mt-gamedesign A4: TF2-"10 h" [E] ersetzen durch die Tabelle aus Frage 1 und "zwei Uhren".
- mt-gamedesign A10: Mini-Metro-Wochenwahl und Satisfactory-Tiers als Muster; CS1 13 / CS2 20 Meilensteine in A2.
- mt-gamedesign B5.5: Zielzeiten in Wirtschaftsminuten, Kalender getrennt.
- mt-po D: "Jede neue Idee nennt einen Streichkandidaten."
- Beide D: Quellenregel "URL nur aus Suchergebnissen abrufbar".
