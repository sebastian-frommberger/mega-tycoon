# Referenzen: Aufbau- und Logistikspiele (Stand 2026-11-03)

Lena (Game Design), Aylin (UX), Tobias (Ökonomie). Marken: **[B]** belegt mit Quellenkürzel (Liste unten), **[E]** Gedächtnis ohne Quelle. Alle [B] aus WebFetch stammen von einem kleinen Modell und sind nicht wörtlich geprüft (WF). Gesperrt und nicht umgangen: Widelands-Forum (Anubis), Gamegrin (PROVENANCE_REQUIRED). Reddit nicht geöffnet. Aktualität: Anno 117 erschien Nov. 2025 [B A3]; The Crust 1.0 laut Steam-Seite am 10.09.2026 [B C3, WF]; neueste Siedler-Vollversion ist "Neue Allianzen" (2023), eine spätere habe ich nicht gefunden [E]; Siedler Online ging im April 2025 an CipSoft [B S5]. Zahlen zu Dauer je Anno-Stufe habe ich nicht gefunden (Lücke).

## 1. Versorgungsketten und Bedürfnisse (Lena)

| Spiel | Mechanik / Zahl | Quelle | |
|---|---|---|---|
| Anno 1800 | 5 Stufen Alte Welt (Bauern bis Investoren), 2 Neue Welt; Aufstieg nur mit vollem Haus, allen Grundbedürfnissen und Baumaterial; Luxusbedürfnisse optional (Glück, Steuern, Festivals) | A1 | B (WF) |
| Anno 1800 | Inselgrößen an Stufen gekoppelt (100 Bauern Dorf, 500 Ingenieure Hauptstadt) | A1 | B (WF) |
| Anno 117 | Bedürfnisse in Kategorien (Essen, Mode, Dienste, neu: Haushaltswaren); je Gut ein Versorgungswert, je Kategorie eine Schwelle; Verbrauch inselweit aus dem Lager | A2 | B (WF) |
| Anno 117 | Teilerfüllung gibt Teilbonus (50 % Brei = +1 statt +2 Einwohner); Bedürfnis lässt sich pausieren; Spieler wählt wenige komplexe oder viele einfache Ketten | A2 | B (WF) |
| Anno 117 | Frühe Stufen autark auf einer Insel; höhere Stufen längere Ketten (Lyra: vier Rohstoffe über mehrere Werkstätten, oft Import) | A3 | B (WF) |
| Siedler 2 | Ketten über Flaggen und Straßen, Brot z. B. Farm, Mühle, Bäcker | S1 | E für die Kette |
| Siedler NA | Ketten stark vereinfacht (Farm macht aus Getreide direkt Fleisch); Kritik: Tiefe verloren | S3 | B (WF) |
| Ixion | keine Schwierigkeitswahl, dauerhafte Vertrauensabzüge, Nicht-Arbeiter essen mit; Rohstoffe wandern nicht von selbst zwischen Sektoren | I2 | B (WF) |
| Banished | Warnungen zu Hunger/Kälte kommen laut Test oft zu spät; Spiel "für Planer" | B1 | B (WF) |

**Was heißt das für uns:** Anno lehrt die Reihenfolge durch die Stufe: Jede neue Stufe bringt wenige neue Bedürfnisse, also genau eine neue Kette. Das passt zu "Orte wachsen nur durch Versorgung". Gegen Todesspiralen hilft in Anno 117 das *Abgestufte*: Teilversorgung gibt Teilnutzen statt Absturz, Luxus ist freiwillig. Ixion und Banished sind die Gegenbeispiele (Strafen wirken lange, Warnung zu spät). Unsere Sättigungskante bei 150 % (0,4 auf 0,1) ist das Gegenteil von abgestuft.
**Empfehlung:** Ortswachstum aus Versorgungsgrad *stetig* machen (Teilversorgung = Teilwachstum) und je Stufe höchstens ein neues Gut einführen. Aufwand 1 PT (Tobias, Test im Bot), Lena schreibt die Stufentabelle 0,5 PT.

## 2. Logistik als Spielgegenstand (Lena)

| Spiel | Mechanik / Zahl | Quelle | |
|---|---|---|---|
| Siedler 2 | Straßen mit Flaggen, ein Träger je Abschnitt, Esel verdoppeln; Ware nimmt immer den kürzesten Weg, auch bei Stau; Staus an der Flagge vor HQ/Lager; Abhilfe: Ringstraßen, Lager verteilen, Transportprioritäten | S1 | B (WF) |
| Siedler 3 | Straßennetz entfällt, Siedler laufen frei, Marktplätze bilden Handelswege | S2 | B (WF) |
| Siedler NA | Träger liefern zuverlässig, keine Transportpriorität | S4 | B (WF) |
| Anno 117 | Verbrauch pro Insel aus Inselspeicher; die eigentliche Logistik sind Schiffe/Handel zwischen Inseln; volle Lager stoppen Produktion | A2, A4 | B (WF) |
| DSP | Station: 4 Güter (interstellar 5), Drohne fliegt direkt, je Gut Angebot/Nachfrage/Lager, Mindestladung in %, Transport hält bis Ladung erreicht ist | D1 | B (WF) |
| Timberborn | Hauler-Gebäude je Bezirk, doppelte Traglast, Priorität je Gebäude | T1 | B (WF) |
| The Crust | Förderbänder und Drohnen, Expeditionsteams | C2, C3 | B (WF) |

**Was heißt das für uns:** Vergleichbar mit unserem Fahrzeug-Tycoon sind nur Siedler 2 (Ware auf Kanten eines Netzes, Engpass an Knoten, kürzester Weg ohne Rücksicht auf Last) und DSP (Abfahrtsregel Mindestladung). Gegenentwurf sind Anno 117, Siedler 3/NA und Timberborn: Logistik wird zu einem *Pool* (Inselspeicher, freie Läufer, Haulerzahl). Das macht die Spiele lesbar, nimmt aber das, was bei uns den Reiz ausmacht (der einzelne Wagen auf der Strecke).
**Empfehlung:** Nicht pooling, aber die Siedler-2-Lehre übernehmen: Knoten (Bahnhof, Lager) sind die sichtbaren Engpässe, nicht die Strecken. Prüfen, ob der Diagnosetext zuerst Knoten nennt. Aufwand 0,5 PT (Mira, Grep in `diagnostics.gd`).

## 3. Rückmeldung und Diagnose (Aylin)

| Spiel | Mechanik | Quelle | |
|---|---|---|---|
| Anno 1800 | Statistik mit fünf Reitern; je Gut aktuelle gegen potenzielle Rate (gestreift), Produktivität je Gebäude, Klick springt zum Gebäude; Handelsrouten fehlen in der Produktionsansicht | A6 | B (WF) |
| Anno 117 | Statistik zum Vergleich Produktion gegen Bedarf, wenig Zeitdruck | A3 | B (WF) |
| DSP | Statistik zeigt Raten; Mod BetterStats ergänzt theoretisches Maximum und rot/gelb bei Defizit (Hinweis, dass das im Original fehlt) | D4 | B (WF, Mod-Seite) |
| Timberborn | Meldung "keine Hauler im Bezirk" mit Angabe, welche Gebäude betroffen sind | T1 | B (WF) |
| Siedler 2 | Stau nur sichtbar an der Flagge, kein Hinweis | S1 | E (nicht erwähnt) |
| Ixion | kein Alarmsystem beschrieben; Rat: Verlustbedingungen (Legierung, Stabilität) kennen; Tonsignale je Mechanik | I2, I3 | B (WF) |
| The Crust | Rezension: man rät, was zu reparieren oder zu erforschen ist | C2 | B (WF) |

**Was heißt das für uns:** Übertragbar ist Annos *Ist gegen Potenzial* (die Lücke ist die Botschaft) und Timberborns Meldung mit Betroffenenliste. Keines der Spiele nennt eine Wurzelursache; ohne Ursache bleibt Anno eine Ableitungsübung für den Spieler (A6, "Diagnosepfad" muss man selbst gehen). Das stützt Aylins Befund: Unser USP ist ein echtes Alleinstellungsmerkmal, aber nur wenn er in der Oberfläche steht.
**Empfehlung:** In A-08 Toast = Ort + Ursache + betroffene Linien; dazu eine Tabelle "Linie: Ist / Soll" im Protokoll. Aufwand 1,5 PT (Aylin, Mira), gemeinsam mit der Toast-Queue.

## 4. Mittelspiel, Fortschritt, Wiederspielwert (Lena)

| Spiel | Mechanik / Zahl | Quelle | |
|---|---|---|---|
| Anno 117 | Kampagne ca. 6 h, insgesamt über 40 h; läuft eine Kette, braucht sie weniger Dauerausbau; Aufträge von Kaiser und Parteien setzen Ziele von außen; Forschung/Götter nebenher | A3 | B (WF, ein Tester) |
| Anno 1800 | Aufstieg kostet Material (Bauern 4 Holz bis Ingenieure u. a. 3 Stahlbeton) | A1 | B (WF) |
| DSP | Sechs Matrixfarben (Blau bis Weiß), Ziele wachsen von Planet zu System zu Sphäre; erste ca. 10 h ähnlich Factorio; langsame Anfangsphase kritisiert (Polygon) | D2, D3, D5 | B (WF), D5 Spiegelseite, Herkunft unklar |
| Ixion | Kapitelende verlangt "Ausharren" über Zeit (PC Gamer: lange Wartezeiten); 50+ h; Game Over zurück zum Kapitelanfang, kostet Stunden | I1, I2, I3 | B (WF) |
| The Crust | drei Forschungsbäume; Baum zeigt nicht, was sinnvoll ist | C2, C3 | B (WF) |

**Was heißt das für uns:** Stufenaufstieg ist Annos Zielverteilung: das Ziel *steckt* in der Stufe (nächstes Bedürfnis), nicht in einer Aufgabenliste. Leerlauf bleibt aber auch dort (A3: "weniger Dauerausbau"), also gibt Anno 117 Außenaufträge dazu. Ixion zeigt, wie Zeitdruck durch Warten aufgefangen wird: gar nicht. Zahlen zur Dauer einer Phase habe ich nicht belegt.
**Empfehlung:** G-01 um "Ortsaufträge" ergänzen (Ort X braucht Gut Y bis Tag Z, ohne Strafe, mit Skillpunkt), als Füllung der Lücke 12 bis 60 min. Aufwand 2 PT, Test per Bot-Messpunkt (Lena, Tobias).

## 5. Ökonomie (Tobias)

| Spiel | Mechanik / Zahl | Quelle | |
|---|---|---|---|
| Anno 1800 | Steuer je bewohntem Haus (nicht je Kopf), nur bei erfüllten Bedürfnissen; ab 1.000 Bauern Steuer fällig; Unterhalt je Produktionsgebäude im Finanzreiter | A7, A6 | B (WF) |
| Anno 1800 | Im Forum: "Königliche Steuern" bei zu vielen Häusern gleicher Stufe als Hauptlast (Einzelstimme) | A8 | B (WF), schwach |
| Anno 117 | Flächeneffekt-Einnahmen nur, solange das Gebäude produziert; volles Lager stoppt Produktion und damit Einnahmen; Heer 100 Münzen/min, 20 im Lager | A4 | B (WF) |
| Anno 117 | Militär kostet Arbeitskraft (Trireme 35 Liberti), Aufstieg ab Stufe 3 kostet viel Arbeitskraft | A5 | B (WF) |
| Kredit (Anno) | in A4, A6, A7, A8 kein Kredit erwähnt; Abwesenheit ist kein Beweis | - | Lücke |

**Was heißt das für uns:** Annos Senken sind *an Struktur gebunden*: Unterhalt pro Gebäude, Aufstiegsmaterial, Arbeitskraft als zweite Währung. Es gibt keinen Zins, der Druck kommt aus Bilanz und Wachstumskosten. Das ist stabiler gegen Überschwemmung als Zins und lässt sich nicht durch Kreditschleifen ausnutzen. Exploit-Schutz: Einnahmen nur bei laufender Produktion (A4) verhindert Hortbau.
**Empfehlung:** Gegenprüfen, ob unsere Ortssteuer an Versorgung gekoppelt ist; Unterhalt je Fahrzeug nach Alter testen (Lkw-Fixkosten 22 %/Monat gegen 10 bis 17 %/Jahr, bereits offen). Aufwand 1 PT (Tobias).

## 6. Eigene Ideen

| # | Idee (Quelle) | Zielperson | Kosten | Billigster Test | Risiko |
|---|---|---|---|---|---|
| 1 | Stetiges Ortswachstum: Teilversorgung gibt Teilwachstum (A2), Kante bei 150 % glätten | Tobias | 1 Tag | Bot, 2 Kurven, n = 300 | Bankrottquote verschiebt sich |
| 2 | Zusatzbedarf je Ort: ein freiwilliges Gut für Steuern (A1) | Lena, Tobias | 2 Tage | Tabelle, kein Spielcode, im Bot | Kette verdoppelt, zu viel |
| 3 | Ist/Soll-Streifen je Linie im Protokoll (A6) | Aylin | 1,5 Tage | Tabellenansicht aus `diagnostics.gd` | Zwei Zahlen verwirren |
| 4 | Toast mit Betroffenenliste (T1) plus Wurzelursache | Aylin, Mira | 1 Tag | Text im Protokoll | Alarmflut, OpenTTD-Fehlalarm |
| 5 | Abfahrtsregel Mindestladung je Linie (D1), verknüpft mit Diagnose "Warten auf Ladung" | Lena, Tobias | 1,5 Tage | Parameter im Bot | Selbstgebaute Staus für Anfänger |
| 6 | Ortsaufträge ohne Strafe als Mittelspiel-Ziel (A3) | Lena | 2 Tage | Liste in G-01, Bot-Messpunkt | Zeitdruck passt nicht zu "ruhig" |

Meine Reihenfolge: 4, 3, 1. Alle drei sind klein, stützen den USP oder lösen ein bekanntes Problem (Kante, Leerlauf).

## Neue Lern-Zeilen

| Datum | Situation | Lücke | Folge |
|---|---|---|---|
| 2026-11-03 | Anno-Recherche | Dauer je Anno-Stufe und Zeit bis zur obersten Stufe nicht gefunden | Lücke bleibt, ggf. Spielerumfrage oder Testspiel |
| 2026-11-03 | Anno 1800 Kredit | Quellen erwähnen keinen; Beleg der Abwesenheit fehlt | als [E] führen |
| 2026-11-03 | Quellenqualität | Mehrere Seiten sind Spiegel oder Mod-Seiten (D4, D5) | in Skills als schwache Quelle markieren |
| 2026-11-03 | Siedler | Keine Zahl zu Transport-Durchsatz je Straße gefunden | nur Prinzip nutzen |

## Vorschläge für Skill-Änderungen (nur Vorschläge)

- mt-gamedesign A12: Anno (Stufe = neue Kette, Teilversorgung), Siedler 2 (Knoten-Engpass), DSP (Mindestladung) mit Quellenkürzel.
- mt-ux: Muster "Ist gegen Potenzial" (A6) und "Meldung mit Betroffenenliste" (T1) als Standard für A-08.
- mt-oekonomie A4: Senken an Struktur binden (Unterhalt, Aufstiegsmaterial, Arbeitskraft) statt nur Zins; Anno kennt keinen Zins in den gelesenen Quellen.

## Quellen

A1 https://anno1800.fandom.com/wiki/Population?oldid=3313 · A2 https://devtrackers.gg/anno-1800/p/18329e7d-devblog-fulfil-needs-your-way (Anno-117-Devblog) · A3 https://www.digitec.ch/en/page/anno-117-review-reaching-a-flow-state-by-building-in-ancient-rome-40324 · A4 https://intoindiegames.com/walkthroughs/anno-117-pax-romana-money-and-economy-guide/ · A5 https://primagames.com/tips/how-to-increase-population-in-anno-117-pax-romana/ · A6 https://anno1800.fandom.com/wiki/Statistics · A7 https://www.giga.de/tipp/geld-verdienen-und-bilanz-verbessern-anno-1800/ · A8 https://forums.pcgamer.com/threads/anno-1800-cashflow-in-the-negative.611/latest · S1 https://settlers2.net/guides/roads/ · S2 https://en.wikipedia.org/wiki/The_Settlers_III · S3 https://www.gameswelt.de/die-siedler-neue-allianzen/test/das-ende-einer-legende-318935 · S4 https://www.pcgames.de/Die-Siedler-Neue-Allianzen-Spiel-61903/Tests/Review-Wertung-Alternativen-1414057/ · S5 https://www.pcgames.de/Spiele-Thema-239104/News/die-siedler-sind-gerettet-ubisoft-ist-raus-so-wird-die-zukunft-des-spiels-1470063/ · D1 https://www.dsp-wiki.com/Logistics_network · D2 https://bit-tech.net/reviews/gaming/pc/dyson-sphere-program-review/1/ · D3 https://en.wikipedia.org/wiki/Dyson_Sphere_Program · D4 https://thunderstore.io/c/dyson-sphere-program/p/brokenmass/BetterStats/ · D5 https://wwwrockpapershotgos.pages.dev/posts/dyson-sphere-program-research-how-research-works-matrix-labs-and-cubes-explained · I1 https://en.wikipedia.org/wiki/Ixion_(video_game) · I2 https://progameguides.com/ixion/ixion-review-casual-strategy-players-need-not-apply/ · I3 https://www.fanatical.com/en/blog/ixion-tips--tricks · C1 https://www.pcgamesn.com/the-crust/reviews-players · C2 https://www.gaming.net/reviews/the-crust-review · C3 https://store.steampowered.com/app/1465470?l=thai · T1 https://timberborn.wiki.gg/wiki/Hauling_Post · B1 https://gameinformer.com/games/banished/b/pc/archive/2014/02/17/banished-review-winter-is-coming
