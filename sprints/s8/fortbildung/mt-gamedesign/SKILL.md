---
name: mt-gamedesign
description: Game-Design-Wissen für Mega Tycoon (Godot-Transporttycoon 1820 bis heute): Kernschleife, Progression und Skilltree, Schwierigkeit, Konkurrenz, Epochen, Wasser/Floß, Fahrzeug-Easing. Nutzen bei Design-Entscheidungen, Zielen, Spielgefühl, Skillpunkten, Meilensteinen oder Wasser.
---

# Lena, Game Design (Wissensstand nach Fortbildung, 03.11.2026)

Rolle: Game-Designerin. Aufbau: Teil A allgemeines Fachwissen mit Quellen (Sx, Liste am Ende von Teil A), Teil B nur Belegtes aus `/home/claude/mega-tycoon` (Dateiangabe je Aussage), Teil C eigene Lücken und Konfidenz.

Kennzeichen: [K] Konsens (mehrere unabhängige Quellen oder Standardlehre), [S] Streit (Quellen widersprechen sich), [E] Einzelmeinung oder Einzelquelle, [R] eigene Folgerung (nachvollziehbar, keine Quelle), [~] aus dem Gedächtnis, nicht geprüft, [M] im Repo gelesen. Ohne Kennzeichen steht die Aussage direkt hinter ihrer Quelle.

Ehrliche Vorbemerkung: Reddit (r/gamedesign, r/gamedev, r/openttd, r/TransportFever, r/factorio, r/CitiesSkylines) war per WebFetch gesperrt (SITE_BLOCKED) und wurde nicht umgangen (keine Spiegelserver). tt-forums.net (Anubis) und wiki.openttdcoop.org (robots.txt) waren nicht lesbar. Community-Stimmen stammen nur aus einem Steam-Thread und Blogs. Entwicklermeinungen stammen aus Entwickler-Blogs (Colossal Order, Factorio) und einem Interview (Sawyer).

---

# TEIL A: Allgemeines Fachwissen

## A1 Kernschleife, Ziele, Rückmeldung (Flow)
- Flow-Bedingungen nach Csíkszentmihályi: klare Ziele mit sichtbarem Fortschritt, klare und sofortige Rückmeldung, Gleichgewicht von wahrgenommener Herausforderung und Fähigkeit. [K] S1.
- Acht-Kanal-Modell (Massimini/Csíkszentmihályi/Carli 1987): Apathie (wenig Herausforderung, wenig Können), Langeweile (Können über Herausforderung), Angst (Herausforderung über Können). Flow am wahrscheinlichsten, wenn beides über dem Durchschnitt liegt. Kritik [S]: das Modell sichert die wahrgenommene Balance nicht; eine Studie fand Genuss auch bei unterfordernden Situationen; Flow ist uneinheitlich definiert und wird nachträglich selbst berichtet; Csíkszentmihályi warnte vor Suchtwirkung; Soderman („Against Flow“, 2021) kritisiert Gamification als unbezahlte Arbeit. S1.
- Folgerung [R]: Flow ist ein Diagnose-Raster (wo kippt es in Langeweile/Angst?), kein Rezept. Für einen Tycoon heißt das: Zielhorizont an jedem Punkt mindestens ein erreichbares kurzes und ein erkennbares langes Ziel; Rückmeldung (Gewinn je Minute, Sättigungswarnung) ohne Verzögerung.
- Core-Loop-Test [R]: Kann ich die Schleife in einem Satz mit fünf Schritten sagen (Erkennen, Bauen, Verbinden, Beobachten, Optimieren) und führt der letzte Schritt wieder zum ersten? Fehlt die Rückführung, ist es eine Kette, keine Schleife.
- RollerCoaster Tycoon (S2 Sawyer-Interview, S3 Artikel): Kernreiz ist, Gästen beim Fahren zuzusehen; Szenarien tragen die Schwierigkeit (Startlage, Landrechte, Ziel „1.000 Gäste bis Ende Jahr 3“); Sawyer will, dass man mit dem Spiel spielt, nicht gegen es; Grundstückskauf und Außenbaurechte gliedern die Progression. Der Artikel [E] bemängelt fehlende Übersicht über Fahrgeschäft-Beliebtheit und eine undurchsichtige Forschungsfinanzierung (Kategorie wählbar, Einzelforschung zufällig).

## A2 Fortschritt freischalten: Punkte, Handlungen, Stufen
- Layouts von Skilltrees (S4, Adrian Crook, F2P-orientiert [E]): linear (gut zum Einführen), verzweigt (Spezialisierung), hybrid (linear mit Verzweigung), netzartig (mehrere Voraussetzungen). Hemmschwellen: Level, Ressourcen, Zeit. Respec per Token. Der Artikel nennt keine Knotenzahlen, keine Breite-gegen-Tiefe-Abwägung und keine Fehlerliste; Meinung: Premium darf kritische Inhalte nicht blockieren.
- „Freischalten durch Tun“ statt „Punkte ausgeben“ [K, drei Quellen]: Factorio-Trigger-Technologien (S5, FFF-376: Freischaltung durch Abbauen, Herstellen, Raketenstart, ohne Labor; Ziel: erst forschen, was man gesehen hat); Colossal Order (S6: Meilensteine über Erfahrungspunkte statt Einwohnerzahl, Anforderungen steigen exponentiell, so wird das Tempo gesetzt); Anno (S7: Ortsstufe braucht volles Haus, Grundbedarf, Baumaterial). Konsens ist die Richtung, nicht die Zahl.
- Exploit-Prävention bei XP (S6): Belohnungen so setzen, dass ein billiges Verhalten (Straßen allein) keinen Meilenstein auslöst. Colossal Order akzeptiert etwas „Cheese“, weil es „davon abhängt, wie man spielt“ [E, Entwicklermeinung].
- Kostenkurven: Spike zwischen Stufen glätten. Factorio kostete Science-Pack 3 etwa 4,5-mal die ersten beiden zusammen und überarbeitete das (S8, FFF-275). Unendliche Forschung mit Kostenbasen unter 2 hält Wahlen sinnvoll (S5, Diskussion, nicht final).
- Schreiber/Romero (S9, nur Inhalt): Kostenkurven, Progression PvE, Tabellenarbeit. Playtesting nicht im Klappentext.
- Mod-Konzept Logistic Challenge (S10, [E]): Orte öffnen Baugenehmigungen erst nach genug Fahrgästen, höchstens 2 Angebote offen, jede gekaufte Genehmigung erhöht die Ansprüche der übrigen; Stufenwechsel mit „Euphorie“ (wächst ohne Versorgung, schrumpft nicht); Zeitbudget mit Strafe alle 12 Minuten, keine Strafe vor dem ersten Meilenstein. Zeigt, wie Fortschritt, Zeitdruck und Stadtwachstum verzahnt werden können.
- Regeln [R]: (1) Jeder Punkt zeigt vorab, was er bringt. (2) Punkte entstehen dort, wo gespielt wird (sonst Zwangsverteilung). (3) Begrenzte Punktezahl macht Entscheidungen real (2 Äste tief oder 4 flach). (4) Respec muss etwas kosten, aber nie den Run sperren.

## A3 Schwierigkeit
- OpenTTD-Presets (S11, Archiv-Wiki [E], Version evtl. veraltet): Easy/Medium/Hard: Konkurrenten 2/4/7, Anfangskredit 300.000/150.000/100.000, Zins 2/3/4 %, Subventionen ×3/×2/×1,5, Gelände flach/hügelig/gebirgig, Baukosten niedrig/mittel/hoch, Pannen reduziert/normal/normal. Die aktuelle Struktur hat 22 Felder (S12), darunter Konkurrenzzahl und -intervall, Städtezahl, Industriedichte, max. Kredit, Zins, Fahrzeugkosten, Konkurrenztempo, Pannen, Subventionen, Baukosten, Gelände, Seen/Meer, Wirtschaftsvolatilität, Katastrophen, Stadtrats-Toleranz, unendliches Geld.
- Hebelfamilien [K aus S11/S12 und Repo-Streit]: Geld, Welt, Gegner, Ziele, Hinweise. Geld-Hebel sind messbar und lassen die Welt gleich. Welt-Hebel verändern Entscheidungen, vermischen sich aber mit dem Seed. Ziele (RCT: Szenario) sind ein dritter Hebel.
- Dynamische Schwierigkeit (S13): Challenge-Funktion; Gummiband sparsam; Rollings/Adams: Anpassung verbergen; Hunicke/Chapman: Parameter statt Gegner anpassen. [S] Fairness gegen Unvorhersehbarkeit ist ungelöst.
- Fairness-Regel [R]: Druck ja, Sackgasse nie (Soft-Lock). Nie eine Handlung bestrafen, die das Spiel selbst angeboten hat (Kredit anbieten, dann Zwangsverkauf ohne Vorwarnung).
- Hinweise sind ein Schwierigkeitshebel (Repo-Skizze `phase2/04_schwierigkeit.md`): Fehlertexte mit Lösung bleiben immer an (Aylin). Allgemein [R]: Hilfen ausblenden ist legitim, Fehler zu verschleiern nicht.
- Konkurrenz in OpenTTD (S14, S15, S16): Zahl, Startzeit, erlaubte Fahrzeugtypen je KI, Rechenbudget (5.000–250.000 Opcodes, empfohlen 10.000, weniger = meist leichtere KI), Profil Easy/Medium/Hard wird an KIs gemeldet. Verhaltensempfehlung (optional): „freundlich“ senkt Wettbewerb um gemeinsame Industrien, auf Easy standardmäßig an, kein Kauf exklusiver Transportrechte. Keine Bankrottregel gefunden.
- Dev-Blog Colossal Order (S6): Ziel „zugänglich und doch tief“; früh auslaufende Subventionen; jede Variante einer Kategorie „eine gültige Wahl“. [E]

## A4 Epochen, Zeitskala, Länge der Partie
- Zeitskala: Transport Fever 2 wird laut Rezensent in einer Sitzung geschätzt etwa 10 Stunden von 1850 bis zu Hochgeschwindigkeitszügen gespielt (S17, [E] Einzelsitzung, Schätzung). Die Logistic-Challenge-Mod rechnet mit 100–200 Stunden für maximalen Ausbau (S10, [E]). Das Repo rechnet 12 min je Jahr, 206 Jahre ≈ 41 Stunden (Teil B).
- Orte in Referenzspielen: TF2-Foren nennen natürliche Ortsgrößen um 2.700, mit Clustern 3.000+ (S18, [S] zwischen Spielern, Stand Oktober 2023). OpenTTD: 1 Mio. EW entspricht 150–200 Feldern Durchmesser (S19).
- Epochenwechsel [R]: Weiterentwicklung bestehender Ketten und neue Industrien sauber trennen; nie alte Industrien schlagartig entwerten; Vorwarnung eine Epoche vorher. (Das ist Repo-Konzept in `concept/lena.md`, hier als Prinzip festgehalten; belegt ist es nicht durch externe Quelle.)
- Historische Taktgeber für Epochen (S20, S21, S24): Chaussee 1750er bis 1820er (Steigung 3–5 %, Breite 8–10 m), Dampfeisenbahn ab 1835 [Repo-Epoche], Verstädterung im Deutschen Reich 1871 63,9 % in Orten unter 2.000 gegen 45,6 % 1900, Städte über 10.000 von 271 (1875) auf 576 (1910). Pfister: Wachstum der Städte beginnt um 1800, Jahrzehnte vor der Industrialisierung (S24, nur Zusammenfassung ohne Zahlen).

## A5 Wasser als Verkehrsweg und das Floß
- OpenTTD Schiffe (S25): größte Kapazität aller Fahrzeuge (etwa kleiner Zug), langsam, geringe Infrastrukturkosten, beliebig viele Schiffe an einem Hafen ohne Routing/Warteschlange, ein Schiff kann lange im Minus laufen, bis die Fracht geliefert ist. Passt für hohe Volumen, besonders zwischen großen Städten; reines Schiffsspiel ist möglich, aber schwer. Wasserbauten (S26): Docks nur an gerader Küste, Einzugsradius 5 Felder; Bojen als Wegpunkte; Kanäle wie Meer, auch auf Land; Schleusen nötig für Höhenwechsel (ca. £13.125 je Schleuse mit zwei Kanalfeldern); Aquädukte ohne Höhenwechsel; Flüsse auf ebenen Feldern befahrbar.
- Transport Fever 2: Schiffe haben auf „Hard“ das 2,5-fache der Betriebskosten (S27, [E]).
- Floßfahrt realhistorisch (S28 de.wikipedia Flößerei, S29 Planet Wissen, S30 Schwarzwald-Tourismus): Rheinflöße 200–400 m lang, 40–80 m breit, 400–500 Mann; Weserfloß bis 80 cm Tiefgang; Frankenwald: Grundkuppel aus 3–10 Stämmen höchstens 2,60 m breit; Kinzigflöße bis 600 m (S29), bis 10 Gestöre zusammengekoppelt „wie Eisenbahnwaggons“ (S30); Holländerfloß bis 300 × 50 m, 500–600 Flößerknechte, bis zu 2 Jahre von Bindung bis zum Holzverkauf in Dordrecht, Mannschaft etwa 3 Monate an Bord (S29); Bayern Höhepunkt 1848 etwa 5.800 Flöße je Jahr, Trift 2–3 % Verlust, Ordinari München–Wien wöchentlich, ca. 7 Tage, 3 Gulden (S28); Wolfach 1763 20 % der Erwerbsbevölkerung (S29); Schwellweiher erzeugten künstliche Flutwellen, Saison April bis November (S30); letzte kommerzielle Fahrt Schiltach 1894, Rhein 1967 (S29/S30). Der Floß-Verkauf am Ziel: das Holz wurde verkauft, das Floß war die Fracht. Rückreise der Mannschaft: in keiner gelesenen Quelle beschrieben.
- Folgerungen [R]: (1) Das Floß ist Fracht und Fahrzeug in einem, es braucht keine Rückfahrt, sondern einen „Neubau am Oberlauf“ als Kostenblock (Bindung, Wieden). (2) Strömung als Tempo (nur flussabwärts). (3) Sehr hohe Kapazität, sehr lange Laufzeit, daher zeitunempfindliche Güter (Holz, Stein; vergleiche OpenTTD-Holz days2 = 255, S31). (4) Als Mechanik ist es ein Einbahn-Wandler: Holz am Oberlauf rein, Holz am Unterlauf raus, ein Fahrzeug verbraucht. Das ist eine eigene Kettenlogik, nicht „Lkw auf Wasser“.

## A6 Bewegung und Easing (nur Darstellung)
- Zwölf Prinzipien der Animation (S32): Slow in/slow out (weich anfahren und bremsen), Anticipation, Follow-through/Overlapping, Arcs (natürliche Bewegung folgt Kurven; mechanische Bewegung ist die Hauptausnahme und läuft eher geradlinig), Squash/Stretch.
- Godot (lokale 4.7-Doku, nicht per Web): Tween bietet TRANS_* und EASE_* (z. B. CUBIC, QUAD). MultiMesh hat `INTERP_QUALITY_FAST = 0` und `INTERP_QUALITY_HIGH = 1`; FAST mischt die Basis linear, was in Kurven das Modell schrumpft und als Sehne dreht (Repo-Befund B7). Penners Gleichungen (Standardsammlung für Easing) wurden nur als Suchtreffer gefunden, nicht geöffnet.
- Regeln [R]: Easing ist ein Darstellungsproblem, nicht ein Simulationsproblem. Sim-Zeit niemals durch Easing verändern. Rampen statt Sprünge (gleitender Mittelwert). Ein Pferd trabt, nie galoppieren (Gangart entscheidet). Frequenzen deckeln, sonst Flackern bei hohem Tempo.
- Townscaper-Artikel (S33): Große Formen vorhersagbar, kleine Details variiert; auf Übergänge achten; Struktur zuerst, Dekor danach; Lesbarkeit aus der Ferne. Gilt für Stadtbild und Fahrzeuge.

## A7 Stadtwachstum als Spielziel
- OpenTTD: Wachstum nur bei aktiver Station in 50 Tagen (S19), Wachstumsintervall sinkt mit mehr Stationen (S34, Original-TTD-Mechanik). Community-Vorschlag: Wachstum nur bei erfüllter Nachfrage, die mit der Klasse steigt (S35, [E]). Iron Roads koppelt Wachstum an ein einziges klares Ziel, damit Spielende wissen, was zu tun ist (S36, [E]).
- Anno: Aufstiegsbedingungen sichtbar (S7). TF2 wird in Foren als Prozentboni-System erklärt, Spieler streiten über Wirkung der Fracht (S18, [S]).
- Folgerung [R]: Wachstum ist die sichtbarste Belohnung eines Tycoons. Wer es versteckt (Prozentboni ohne Anzeige), erzeugt Forenstreit statt Gefühl. Darum Schild mit Trendpfeil und Bedarf-Icons (Repo B).

## A8 Checklisten
1. Ziel-Check: Hat jede Spielphase ein kurzes (unter 3 min), ein mittleres und ein langes Ziel? 2. Entscheidungs-Check: Gibt es zu jedem Zeitpunkt eine Wahl mit mindestens zwei Optionen unterschiedlicher Kosten? 3. Rückmelde-Check: Sieht man sofort, warum etwas zahlt oder nicht (Tooltip, Warnung)? 4. Sackgassen-Check: Kann man sich festspielen? 5. Exploit-Check: Billigste Handlung, die den Meilenstein auslöst? 6. Epochen-Check: Wird etwas schlagartig entwertet? 7. Kontrolle: Passt der Skalen-Gedanke („nichts überzeichnet“) zu dem, was das Spiel zeigt? 8. Messbarkeit: Gibt es für das Ziel eine Messgröße und einen Bot-Test?

## A9 Typische Fehler
- Zwei Fortschrittswährungen (Punkte aus Meilensteinen und XP aus Transport), ohne Regel, welche gilt.
- Epochen über Kalender und über Meilensteine gleichzeitig definieren, ohne Rangordnung.
- Hilfen ausblenden und gleichzeitig Fehler verschleiern.
- Spielziele ohne Messgröße („Ziel hakt falsch“, wenn es beim ersten Lkw zählt).
- Wasser als Kulisse ankündigen, aber Karten so wählbar machen, dass Wasser zum Hindernis wird (Seenreich ohne Fähre).
- Meilenstein-Belohnungen, die nur Zahlen ändern (+8 %), verschwinden im Rauschen der Sättigung; Schlüssel-Fähigkeiten brauchen einen Satz Nutzen („Was kann ich jetzt, was vorher nicht ging?“, Konzept Lena). Ob +8 % je Rang spürbar ist, ist offen (G-01 Frage 2).
- Hilfetexte, die erst auf Abruf erscheinen, in einem Spiel mit unsichtbarer Nachfragefunktion: Einzugsgebiet muss im Tooltip stehen, sonst wirkt ein Ort mit 244 Einwohnern und 650 Sim-EW wie ein Fehler (Aylin-Test im Rundgang steht aus, K1).
- Ziele ohne Bot-Messpunkt sind nicht prüfbar [R]; G-01 verlangt für die Leerlauf-Regel ausdrücklich einen Bot-Lauf. Neue Ziele daher mit Messpunkt einreichen.

## A10 Entscheidungsdichte und Taktung (Prinzip)
- Drei Zeitebenen gleichzeitig bedienen [R aus S1]: Sekunden (Rückmeldung, Tooltip), Minuten (kurzes Ziel, Bauentscheidung), Stunden (Meilenstein, Epoche). Fehlt die mittlere Ebene, entsteht das S7-Plateau (Teil B3).
- Belohnungsabstand: Colossal Order koppelt Meilensteine an XP mit exponentiell steigenden Anforderungen (S6). Das heißt: früh dicht, später dünner; die Abstände wachsen mit dem Fortschritt. Übertragbar als Regel [R]: Die ersten drei Ziele in unter 15 Minuten, danach 7–10 Minuten, später Stunden.
- Zwangs-Entscheidungen vs. Wahl-Entscheidungen: Logistic Challenge schränkt auf höchstens 2 offene Angebote ein (S10, [E]). Zwei Optionen genügen für Kopfleisten-Entscheidungen; mehr überfordert.
- Auslaufende Starthilfen (S6: Subventionen schrumpfen, bis die Stadt selbsttragend ist) sind ein Muster für „Tutorial ohne Tutorial“: früh Sicherheit, dann Eigenverantwortung.
- Zeitdruck als Option, nicht als Standard: Mod-Strafe alle 12 Minuten, keine Strafe vor dem ersten Meilenstein (S10, [E]). Regel [R]: Zeitdruck nur nach dem ersten erreichten Ziel, Sandbox ohne.

## A11 Eine Design-Idee prüfen (Arbeitsverfahren) [~]
Aus Fachpraxis, nicht aus einer der geöffneten Quellen: 1. Wer ist die Zielperson (Archetyp, Vorwissen)? 2. Was kostet es (Bauaufwand, Balancing, UI, Test)? 3. Was ist der billigste Test (Papier, Skript-Bot, Prototyp-Szene)? 4. Was wird dafür gestrichen (Ein-Ding-Regel)? 5. Welche Messgröße zeigt Erfolg oder Misserfolg? Für Mega Tycoon gilt zusätzlich: Passt es zu E1–E15 und P1–P7, und lässt es sich von einem deterministischen Bot messen?

## A12 Referenzspiele auf einen Blick (was jedes lehrt, mit Quelle)
- OpenTTD: sehr offene Presets (22 Felder), Wachstum über aktive Stationen, KI-Konkurrenz mit Profil und Rechenbudget (S11, S12, S14, S19). Lehre: Einstellungen sind Daten, Konkurrenz ist ein Skript mit Grenzen.
- Transport Fever 2: Ortswachstum als Prozentboni, Foren streiten über Wirkung (S18); Rezensent sieht Fracht ohne Zeitstrafe und Nachfrage ohne Rückkopplung (S17, [E]). Lehre: Wachstum muss sichtbar erklärt sein.
- RollerCoaster Tycoon: Ziele und Szenario-Startlage statt Schwierigkeitsregler, Forschung als Budget (S2, S3). Lehre: Ziele sind ein Schwierigkeitshebel.
- Cities: Skylines II: XP-Meilensteine mit exponentiellen Anforderungen, auslaufende Subventionen, jede Variante „eine gültige Wahl“ (S6). Lehre: Tempo über Anforderungskurve, nicht über Zufall.
- Factorio: Freischaltung durch Handlung, Kostenspitzen glätten, Spreadsheet-Modell (S5, S8). Lehre: Pfade sichtbar, Spikes messen.
- Anno: Stufenaufstieg über sichtbare Bedingungen (S7). Lehre: Aufstiegsbedingungen anzeigen.
- Townscaper/Bad North: Große Form vorhersagbar, kleine Details variieren, Übergänge betonen (S33). Lehre: Stadtbild und Fahrzeugbild.

## Quellen Teil A (per WebFetch geöffnet, außer „nur Suchtreffer“)
- S1 Wikipedia Flow (psychology) https://en.wikipedia.org/wiki/Flow_(psychology)
- S2 Sawyer-Interview (rctspace) https://rctv1.rctspace.com/test/info/interview.html
- S3 Spieltimes zu RollerCoaster Tycoon https://www.spieltimes.io/news/breaking-down-rollercoaster-tycoon
- S4 Adrian Crook, Skill Tree Design https://adriancrook.com/?p=8095
- S5 Factorio FFF-376 (Spiegel) https://devtrackers.gg/factorio/p/82118ef4-friday-facts-376-research-and-technology
- S6 Colossal Order, Behind the Scenes 3 https://colossalorder.fi/news/behind-the-scenes-3-game-balancing/
- S7 Anno-Wiki Population https://anno1800.fandom.com/wiki/Population?oldid=2694
- S8 Factorio FFF-275 https://factorio.com/blog/post/fff-275
- S9 Routledge, Game Balance (nur Inhalt) https://www.routledge.com/Game-Balance/Schreiber-Romero/p/book/9781315156422
- S10 transportfever.net Logistic Challenge https://www.transportfever.net/lexicon/entry/427-logistic-challenge-new-gameplay/
- S11 OpenTTD Wiki Difficulty (Archiv) https://wiki.openttd.org/en/Archive/Manual/Settings/Difficulty
- S12 OpenTTD DifficultySettings https://docs.openttd.org/source/d6/d6c/structDifficultySettings
- S13 Wikipedia Dynamic game difficulty balancing https://en.wikipedia.org/wiki/Dynamic_game_difficulty_balancing
- S14 OpenTTD Wiki AI settings https://wiki.openttd.org/en/Manual/AI settings
- S15 OpenTTD Wiki Competitors (Archiv) https://wiki.openttd.org/en/Archive/Manual/Settings/Advanced%20Settings/Competitors
- S16 OpenTTD Wiki Script Behaviour https://wiki.openttd.org/en/Development/Script/Behaviour
- S17 dedoimedo TF2 https://www.dedoimedo.com/games/transport-fever-2.html
- S18 Steam-Thread TF2 Stadtwachstum https://steamcommunity.com/app/1066780/discussions/0/3879346999825598874
- S19 OpenTTD Wiki Towns https://wiki.openttd.org/en/Manual/Towns
- S20 Wikipedia (de) Chaussee https://de.wikipedia.org/wiki/Chaussee
- S21 Wikipedia Urbanization in the German Empire https://en.wikipedia.org/wiki/Urbanization_in_the_German_Empire
- S24 Pfister RePEc https://ideas.repec.org/p/cqe/wpaper/9020.html
- S25 OpenTTD Wiki Ships https://wiki.openttd.org/en/Manual/Ships
- S26 OpenTTD Wiki Water Transport Tiles https://wiki.openttd.org/en/Manual/Water%20Transport%20Tiles
- S27 gameplay.tips TF2-Guide https://gameplay.tips/guides/9066-transport-fever-2.html
- S28 Wikipedia (de) Flößerei https://de.wikipedia.org/wiki/Fl%C3%B6%C3%9Ferei
- S29 Planet Wissen, Floßschifffahrt https://www.planet-wissen.de/technik/schifffahrt/geschichte_der_schifffahrt/pwiegeschichtederflossschiffahrt100.html
- S30 Schwarzwald-Tourismus, Holländertanne https://www.schwarzwald-tourismus.info/schwarzwald/online-magazin/geschichten-aus-dem-schwarzwald/kultur/der-weg-der-hollaendertanne
- S31 OpenTTD Wiki Cargo income https://wiki.openttd.org/en/Manual/Game%20Mechanics/Cargo%20income
- S32 Wikipedia Twelve basic principles of animation https://en.wikipedia.org/wiki/Twelve_basic_principles_of_animation
- S33 Game Developer, How Townscaper works https://www.gamedeveloper.com/game-platforms/how-townscaper-works-a-story-four-games-in-the-making
- S34 TTWiki TTDTownGrowth https://www.tt-wiki.net/wiki/TTDTownGrowth
- S35 Peter1138 Towngrowth Challenge https://wiki.openttd.org/en/Community/Essays/Peter1138's%20Towngrowth%20Challenge
- S36 Iron Roads Devlog 026 https://cowleyforniastudios.itch.io/iron-roads/devlog/694919/026-reworking-town-growth
- Die Nummern S22 und S23 sind nicht vergeben.
- Nur Suchtreffer (nicht geöffnet): Penner-Easing-Sammlungen (mehrere Code-Seiten), „Respec Your Game“ (wayline.io), „what makes a skill tree interesting to explore“ (mygamedesign), Steam-Threads zu TF2-Wachstum außer dem geöffneten.

---

# TEIL B: Wissen für Mega Tycoon (nur Belegtes aus dem Repo)

Pfade relativ zu `/home/claude/mega-tycoon/`.

## B1 Verbindliche Entscheidungen (Charter, Basti, 02.–03.11.2026)
Quelle: `sprints/s8/design-sprint/charter.md`.
| # | Entscheidung |
|---|---|
| E1 | Nichts wird überzeichnet, alles im Verhältnis; Fahrzeuge höchstens 1,2× real; Lesbarkeit aus Icon, Name, Farbe, Zoom, nicht aus Größe |
| E2 | Einfacher Wasser-Shader, Breiten realistisch im Verhältnis |
| E3 | Siedlungszahl folgt aus Prinzipien, nicht aus einer Zahl |
| E4 | Start 1820; Startjahr später wählbar (Datenparameter) |
| E5 | Schwierigkeitsgrade: offen, Papier von Tobias/Lena, Entscheidung S8 |
| E6 | Gestufte Ortsordnung (2 Kleinstädte, Marktflecken, viele Dörfer) |
| E7 | Orte bleiben ohne Versorgung stabil, wachsen nur mit Versorgung |
| E8 | Partie bis in die Moderne (heute); Epochentabelle bis heute |
| E9 | Fahrzeug-Easing je Kategorie (nicht je Modell); nur Darstellung |
| E10 | Gewässer mit sichtbar sinnvoller Nutzung; Kartentyp wählbar (Flusstal, Seenplatte, Seenreich) |
| E11 | Konkurrenz als Schwierigkeitshebel (fehlte) |
| E12 | Kalendertempo (Dauer 1820 bis heute) wählbar |
| E13 | Karte bleibt zunächst die heutige (Großstadt bis ca. 100.000) |
| E14 | Konkurrenz per Default an, sichtbar auf den Straßen, im Freien Spiel abschaltbar |
| E15 | Wasser als Verkehrsweg: theoretisch von Anfang an mit Flößen (Holz/Stein flussabwärts); Mechanik-Entscheidung S8/S9; im Prototyp nur Kulisse mit Funktion auf dem Fluss; Fähre und Schiffe später |

## B2 Design-Prinzipien der Welt (Regelwerk v1)
`sprints/s8/design-sprint/phase3/12_welt_regelwerk_v1.md` §1: P1 Verhältnis vor Größe, P2 Zeichen statt Maßstab, P3 gewachsen statt konstruiert, P4 Landschaft dominiert (Siedlung < 3 % der Fläche, ≥ 5 Dorfdurchmesser zwischen Dörfern), P5 Gelände ist Spielelement („steht hier, weil …“), P6 belebt im Detail, ruhig im Ganzen, P7 Epoche ist ein Parameter. Nie: Objekte vergrößern (außer Fahrzeuge ≤ 1,2×), Gebäude einfärben, Raster (außer Bahnhofsviertel), Ort ohne Lagegrund, Modernes ohne Epochenfreigabe, 1820 eine Industrie größer als das Dorf daneben. Bastis Regel „nicht neu erfinden“ (Genre-Standard) wird in K37 zitiert (`phase3b/15_regelwerk_v1_1.md`).

## B3 Progression nach M7 (G-01, nur Konzept, Platzhalter für Tobias)
`sprints/s7/block-b/g01_progression.md`:
- Problem: alle 7 Slice-Ziele nach 12 min, danach 38 min dieselbe Handlung; Plateau ab ca. 20 min.
- Fernziele F1 (Min 15, zweite Stadt versorgt, V ≥ 50 %), F2 (22, Netto ≥ 1.000 $/min 5 min gehalten, ohne Kredit, 1 Punkt), F3 (30, Stadt passiert Stufen-Tor durch eigene Lieferung, 1 Punkt), F4 (38, Fernkette ≥ 3 km mit Fluss/Hang), F5 (45, M7 HQ Stufe 2, 5.000 $/min, 1 Punkt), F6 (52, drei Städte V ≥ 80 %, Zug- und Lkw-Anteil je ≥ 25 %), F7 (60, Firmenwert ≥ 100.000 $ und Netto ≥ 2.500 $/min, Punkt plus Schlüssel-Fähigkeit). Danach Endlosspiel mit Auftrag alle ca. 8 min mit Wahl zwischen 2 Aufträgen.
- Leerlauf-Regel: keine 3 min ohne Entscheidung mit mindestens 2 Optionen unterschiedlicher Kosten, sichtbar in der Kopfleiste; Prüfung per Bot-Lauf (Lücke ≤ 3 min, sonst Test rot).
- Druckquellen: Stadtwachstum (Hauptquelle, Stufen-Tore), Sättigung (vorhanden, Sichtbarkeit fehlt), Lizenzpreise (+10 % je Verlängerung), Gleisunterhalt (Ziel Zug : Lkw ≤ 3 : 1), KI-Konkurrenz light (S8 nur passiv, abschaltbar, ab Min 35).
- Punkte: 6 bis 60 min, 4 bis M7; „Quellen nur Meilensteine und Etappen, keine Transport-XP (Streitprotokoll)“. Firmenkauf als Wahlziel neben F4.
- Sechs offene Fragen an Tobias (Minuten, +8 % je Rang, Lizenz +10 %, Gleisunterhalt, KI-Anteil 15 %, F6 messbar und exploitfrei). Laut den gelesenen Dateien nicht beantwortet.

## B4 Skilltree, Epochen, Onboarding (Konzept Lena)
`concept/lena.md`:
- Core Loop: Erkennen, Bauen, Verbinden, Beobachten, Optimieren. Meta-Loop (4–10 Stunden): HQ und Lizenzen, Ketten schließen und Ast-XP, Skills kaufen, Meilensteine, Epochenwechsel, Szenarioziel/Firmenwert.
- Skilltree: 6 Äste (Stadtverkehr, Agrar & Nahrung, Schwerindustrie, Schiene, Straße & Logistik, Wasser). Währung Ast-XP durch Transportieren (Tonnen-km, Personen-km), 1.000 XP = 1 Punkt im Ast, dazu freier Punkt je Tutorial- und Epoch-Meilenstein. Rangskills 1/3 oder 1/5, Schlüssel-Fähigkeiten (1 Punkt, schalten neue Möglichkeit frei, 1 je Ast und Epoche, Wahl aus 2 benachbarten Ästen). Ca. 40 Punkte bis Epoche V, ca. 110 Knoten (2 Äste tief oder 4 flach). Respec: Rangskills jederzeit gegen 25 % der bisherigen Ast-XP, Schlüssel-Fähigkeiten gesperrt bis Gratis-Respec beim Epochenwechsel. Sichtbar nur aktuelle und nächste Epochenstufe.
- Epochen (Konzept): I 1850–1890 bis V 1995–2030, Wechsel über 3 von 5 Epoch-Meilensteinen, alte Industrien in vier Zuständen (u. a. schrumpft über 30–60 min, Umrüsten mit 50 % Firmenwert), Epochenwechsel-Info 1 Bildschirm, max. 2 neue Ketten und 3–4 Fahrzeuge je Wechsel.
- Onboarding: Meilensteine als Tutorial (HQ gründen, erste Lizenz, Lkw-Linie …), „Erfahrener Start“: 60.000 $, zwei Startfirmen, alle Äste offen, 3 freie Punkte. Startkapital-Testannahmen dort: 4.500/4.500/7.000/5.000 $ je Archetyp.

## B5 Konflikte und Lücken im Repo (für Design-Entscheidungen zuerst klären)
1. Skillpunkt-Quelle: G-01 „keine Transport-XP“ gegen `concept/lena.md` Ast-XP durch Transport. Nicht aufgelöst gefunden.
2. Epochen: Konzept I–V ab 1850 (Meilensteine) gegen Regelwerk W1–W6 ab 1820 (Kalender, K21 „Welt-Epoche folgt dem Kalender; Meilensteine sperren Fahrzeuge/Ketten möglicherweise zusätzlich, entscheidet S8“). `phase3b/15_regelwerk_v1_1.md` A2, K21, K22.
3. Startkapital: Konzept 4.500–7.000 $ je Archetyp, Slice und Normal 6.000 $ (`slice/data/economy_constants.json`), Schwer 4.500 $ (Skizze).
4. Großstadt: Schwelle/Größe zwischen Regelwerk A3 und Stufen im Slice; Ökonomie späterer Epochen ist laut Regelwerk „eigener Sprint“.
5. Partie: 12 min je Jahr (206 Jahre ≈ 41 Std.); Basti hat Kalendertempo als wählbar entschieden (E12, Optionen 12/6/3 min je Jahr aus F7); die Ökonomie rechnet je Minute weiter (K26). Folge für Progression: Zielzeiten in Minuten (G-01) und Jahreszahlen der Epochen laufen auseinander, solange keiner festlegt, welche der beiden Skalen für Ziele gilt.

## B6 Offene Fragen an Basti und Arbeitsannahmen (Phase 3b)
`phase3b/15_regelwerk_v1_1.md` §F: F7 Partielänge (Empfehlung C wählbar, Arbeitsannahme A 12 min), F8 größte Stadt (A heutige Karte bis ~100.000), F9 Sichtbarkeit der Konkurrenz (B sichtbar auf Straßen, E14 entschieden), F10 Wasser als Verkehrsweg (Empfehlung B erst Fähre dann Schiffe; E15 hat das Floß als Anfangsmechanik angekündigt). Laut Charter sind sie beantwortet: F7 → E12 (Kalendertempo wählbar), F8 → E13 (heutige Karte), F9 → E14 (sichtbar, Default an, abschaltbar), F10 → E15 (Wasser: Floß von Anfang an als Idee, Mechanik offen). Die Fragen stehen im Dokument noch mit ihren Arbeitsannahmen.

## B7 Easing, Fahrzeuge, Wasser, Konkurrenz (Regelwerk v1.1)
`phase3b/15_regelwerk_v1_1.md`:
- Code-Befund: A*-Weg nur 4-Richtungen (`DIAGONAL_MODE_NEVER`), konstantes Tempo, kein Anfahren/Bremsen, Fuhrwerk fährt 15 m je Tick (Ecke in 1–2 Ticks), `physics_interpolation_quality` unbelegt = FAST, daher schrumpft das Modell in der Ecke auf ca. 71 % und dreht als Sehne („Schuhkarton“). Entscheide K27–K31: nur Darstellung, Fahrlinie = Spline des Bands plus Spur-Versatz, gleitender Mittelwert über W Ticks (Versatz ≤ W/2), zeiterhaltende Umparametrisierung je Kurvenzone (Überhöhung ≤ +15 %), Nah-LOD (Kamera ≤ 600 m, max. 128 Fahrzeuge, eigenes MultiMesh), Fern mit `physics_interpolation_quality = HIGH` (prüfen).
- Profile je Kategorie (§B3): Fuhrwerk Sim 0,6 F/Tick, Fenster 4, Kurvenfaktor min 0,55, Wippen 0,12 m / 2,0 Hz, Bein 2,5 Hz Schritt/Trab, nie Galopp; Postkutsche Federung; Dampfzug 1,0 F/Tick, Fenster 8, Mindestradius Gleis 100 m; Schiff 0,4 F/Tick, Fenster 20, Krängung 4°. Messprotokoll `easing_test.gd` (E1–E9 und Bastis Rundgang stehen aus).
- Gewässer (E10): Kartentypen Flusstal (3–5 % Wasser, 1 Fluss 60–100 m), Seenplatte (8–12 %), Seenreich (15–25 %); Validatoren V-W1 Erreichbarkeit (≤ 8 Brückenfelder), V-W2 Querungsstellen (See > 1 km: Engstelle ≤ 200 m), V-W3 sichtbare Nutzung (≥ 300 m Gewässer oder je 2 km Fluss), V-W5 Inseln ohne Knoten. K32: Seenreich erst wählbar, wenn Fähre oder Schiff spielbar ist. K34: 1820/S8 nur Mühle ist Mechanik; Fähre und Schiffe Kandidaten.
- Floß (E15): im Prototyp nur Kulisse; Holztrift, Steg, Fischer; Mechanik-Entscheid steht aus. Dokument zum Prototyp-Floß: `sprints/s8/design-sprint/phase4/ta_welle2.md`.
- Konkurrenz (§D, K36–K40): Hebel Anzahl 1/2/3, Start Min 45/35/20, Aggressivität passiv/aktiv/aggressiv, Marktanteil-Deckel 10/15/20 %, Lizenzbelegung, Preiskampf (nur Schwer), Übernahme nie gegen die Spielerfirma. Sichtbar (Farbe, Fahrzeuge, belegte Lizenzen, Rangliste). Schutzregeln K39. Basis: Bot `d08_bankrott` als Spielfigur (K38). Ziel-Bankrottquoten ≤ 5/15–18/30–40 % inklusive Konkurrenz (K40). Es gibt keinen KI-Code.

## B8 Schwierigkeit (E5, Skizze)
`sprints/s8/design-sprint/phase2/04_schwierigkeit.md`: Presets als Daten (leicht/normal/schwer), Startjahr als eigene Option (K19, Aylin), Siedlungsdichte kein Hebel (12–18 Dörfer), Welt-Hebel höchstens knappe Rohstoffe und Relief (Lena), Tobias: nur Geld. Hinweise-Hebel; Fehlertexte mit Lösung bleiben immer. Offene Fragen an Basti dort: darf die Schwierigkeit die Welt verändern; Startjahr und Schwierigkeit getrennt. Zahlen und Messung siehe Skill `mt-oekonomie` (Teil B9).

## B9 Stadt aus Spielersicht (Regelwerk v1, Auswahl)
- Hierarchie B+: 2 Kleinstädte (min. 1), 2–3 Marktflecken, 12–16 Dörfer, 6–12 Kulisse-Weiler ohne Schild; Schild = Ort-EW mit Trendpfeil und bis zu 3 Bedarf-Icons; Tooltip „Einzugsgebiet N (Nachfrage)“. K1 Annahme, Grundsatz bestätigt mit F1 (`phase3/11_streitprotokoll.md` K1, `phase3/12_welt_regelwerk_v1.md` §3).
- Wachstum: pro Monat eine sichtbare Aktion bei positiver Rate; Reihenfolge Lücke, Upgrade, Hofteilung, Vorstadt, Gasse, Platz. HQ-Bonus ×1,05 (Annahme, nicht verpflichtend, Abnahme Tobias S8).
- Basti-Feedback (Wortlaut): Städte zu geometrisch, Blöcke leer, zu groß für frühes 19. Jh., Anordnung konstruiert; Wunsch: Haus-Größen und Einwohner je Haus, Städte sollen automatisch wachsen, größere Häuser aus kleinen, Straßen von der „Stadt-KI“ (`sprints/s8/feedback_02-11/basti_feedback_02-11.md`).

## B10 Slice-Meilensteine und Zielzeiten (Ist-Stand im Code)
- `slice/data/economy_slice.json › meilensteine`: ms_1a HQ gegründet (Einflussradius), ms_1b erste Lizenz im Einfluss (1 Skillpunkt), ms_2 Lkw-Linie zum Verarbeiter (1 Punkt Straße), ms_3 Endprodukt an Abnehmer (Stadt-Panel), ms_4 Buslinie in einer Stadt (Ast Stadtverkehr), ms_5 Lager mit 2 Quellen (Zug frei), ms_5b erste Firma gekauft (Kaufrabatt einmalig), ms_6 Zugstrecke mit Signal (Doppelgleis-Werkzeug), ms_7 HQ Stufe 2 (12.000 $, +10 Felder Radius). Zielband M7: 21.000–30.000 Ticks (35–50 min). ms_8 und KI-Spediteur sind im Slice nicht vorhanden (Flags `ms_8_im_slice_flag: false`, `ki_spediteur_im_slice_flag: false`).
- Genre-Standard-Schalter (`economy_slice.json › genre_standard`): Abbruchrückerstattung 50 %, Haltestellenradius Bus 5 / Bahnhof 10 Felder, Bau-Snap 45°, Spielgeschwindigkeit 0/1/2/4, Linienketten, Kontextdialog bei Klick, Nachfragekorb wächst mit der Stufe.
- Wachstums-Zielzeiten (Design-Eichung): Dorf → Kleinstadt in ca. 12 min und Kleinstadt → Stadt in ca. 80 min bei Höchstversorgung, Rahmen ±15 %. Variante B (Wachstum hängt nur an Gütern, Personen und Jobs als Zuschlag) hält den Rahmen auch für reine Güterspieler (13/91 min). `design/game-design/day1-3/wachstumsgewichte.md`; Ziel in `refinement/tobias.md` (T-04). Gilt für den Slice-Takt 1 Monat = 1 min; die neue Welt hat Orte mit 150–4.000 Ort-EW und ist damit nicht gemessen.
- HQ-Startwerte (Entwurf): Einkommen einer ersten Kette 399–844 $/min je Archetyp, Zielzeit bis zur ersten Gewinnkette 6–10 min; Tobias-Befund: das Startkapital taktet das Spiel kaum. `design/game-design/day1-3/hq_startwerte.md` §1–§2.

## B11 Prüfung der 3-Minuten-Regel an G-01 [R]
Die Beispiele der Regel liegen bei Minute 13, 19, 26, 33, 41 (`g01_progression.md` §2), also mit Abständen von 6 bis 8 Minuten. Die Etappenziele F1–F7 liegen bei 15, 22, 30, 38, 45, 52, 60 (7–8 Minuten), Punkte bei 22, 30, 45, 52, 60, Aufträge alle etwa 8 Minuten. Die Beschreibung der Regel („Lücke ≤ 3 min, sonst Test rot“) wird von der Beispielliste selbst nicht erfüllt: Es fehlen etwa zwei bis drei zusätzliche Entscheidungsquellen je 8-Minuten-Fenster (Sättigungswarnung mit Wahl, Lizenzende, Stufen-Tor, Hub-Entscheidung). Das ist eine Rechnung aus dem Dokument, kein Bot-Befund; der Bot-Test dazu existiert laut den gelesenen Dateien nicht.

## B12 Entscheidungsvorlagen, die ich als Lena vorbereiten würde (Vorschläge [R], keine Beschlüsse)
1. Skillpunkt-Quelle: Vorschlag hybrid. Freie Punkte aus Meilensteinen (verlässlich, planbar) plus Ast-XP aus Transport (lenkt den Stil). Offen für Tobias: Verhältnis, Exploit-Prüfung (Colossal-Order-Muster: kein XP-Gewinn aus billigem Verhalten, S6). Gegenposition aus G-01: nur Meilensteine, weil Transport-XP den Plateau-Effekt verstärkt.
2. Epochen-Steuerung: Bild und Haustypen folgen dem Kalender (K21, entschieden). Freischaltung von Fahrzeugen und Ketten: Vorschlag Kalender als Frühestdatum plus Meilenstein-Tor (Konzept 3 von 5), damit keine Spielerin blind wartet (Vorschau im Epochenpanel).
3. Floß: Vorschlag Einbahn-Wandler (Holz oder Stein flussabwärts, Neubau am Oberlauf), erste Ausbaustufe nur eine Strecke, danach Fähre. Prüfpunkte: Entscheidungen je Floß (Zeit, Last), Anzeige der Strömung, Kosten des Neubaus.
4. Entscheidungsquellen gegen die 3-Minuten-Lücke: Sättigungswarnung mit Wahl, Lizenzende, Stufen-Tor, Hub-Bau, Aufträge. Je Quelle eine Bot-Messung der Häufigkeit.
5. Zeitskala: Zielzeiten in Minuten halten, Jahreszahlen nur für Epochenanzeige; Kalendertempo (E12) darf Ziele nicht verschieben.

---

# TEIL C: Eigene Lücken und Lernstand

## C1 Was ich jetzt kann (Konfidenz)
- Entscheidungsgrundlagen der Welt (E1–E15, P1–P7) auswendig und mit Datei zitieren (hoch, [M]).
- Progression nach M7 als Zielkette mit Leerlauf-Regel erklären und die Lücken benennen (hoch).
- Freischalten-durch-Tun gegen Punkte-ausgeben mit Beispielen aus Factorio, Colossal Order und Anno gegenüberstellen (mittel, drei Quellen, aber keine Messdaten).
- Floß als Einbahn-Wandler und Fracht modellieren (mittel, [R] aus S28–S30; Rückreise nicht belegt).
- Easing als Darstellungsproblem mit den Repo-Entscheidungen K27–K31 vertreten (mittel; Messprotokoll steht aus).

## C2 Noch unsicher (Konfidenz niedrig bis mittel)
1. Welche Skillpunkt-Quelle gilt (Meilenstein oder Ast-XP)? Ohne Entscheid keine Kalibrierung. Konfidenz in „Meilenstein reicht als alleinige Quelle“: niedrig.
2. Welche Epochensteuerung gilt (Kalender, Meilenstein, beides)? K21 trennt Bild (Kalender) von Spielfortschritt (offen).
3. Wie schwer ist „Schwer“ wirklich? Die Zielquoten 30–40 % sind Annahme; nur Geld-Hebel sind bisher gemessen (B-Teil Ökonomie).
4. Spielwert des Floßes: Einbahn-Wandler ist plausibel [R], aber nicht erprobt; Rückfahrt, Mannschaft, Wartezeit am Unterlauf sind offen.
5. Ob Leerlauf-Regel „keine 3 min ohne Entscheidung“ in der neuen Welt mit 15–21 Orten gilt: nie per Bot geprüft.
6. Hat Basti die Fahrzeug-Easing-Optik (E1–E9) gesehen? Rundgang steht aus.
7. Konkurrenz in der Praxis: Hebel sind Skizzen; keine Spielerprobe.
8. Zielgruppen: Ich habe keine Spielerdaten (Reddit gesperrt). Aussagen über „was Spielende mögen“ stützen sich auf Entwicklerblogs, einen Steam-Thread und Rezensionen.
9. Skillbaum-Zahlen (110 Knoten, 40 Punkte, 1.000 XP je Punkt) sind unkalibriert; keine externe Quelle liefert Knotenzahlen (S4 nennt keine).

## C3 Was ich künftig anders mache
- Vor jedem Zielsystem die Messgröße und den Bot-Test mitdefinieren (Ziele ohne Messgröße hakten schon einmal).
- Eine Entscheidung je Konflikt einfordern, statt zwei Konzepte nebeneinander zu pflegen (Skillpunkte, Epochen).
- Spielerstimmen aus mindestens zwei Quellenarten holen und Reddit als Lücke ausweisen, nicht als Konsens.
- Flow, DDA und Fairness als Prüfraster verwenden, nicht als Beweis.
- Floß, Fähre und Schiff erst als Prototyp-Funktion zeigen, dann entscheiden.

## C4 Meine offenen Lernfragen (Kurzform, Details und Rangfolge in `LERNBERICHT.md`)
1. Skillpunkt-Quelle und Kalibrierung. 2. Epochen-Steuerung (Kalender gegen Meilenstein). 3. Schwierigkeit: Welt- oder nur Geld-Hebel. 4. Konkurrenz als Spielfigur und Fairness. 5. Floß- und Wassermechanik. 6. Leerlauf-Regel messen. 7. Zeitskala 1820 bis heute (Kalendertempo, Zielzeiten). 8. Skilltree-Umfang (Knoten, Punkte, Respec) kalibrieren. 9. Easing-Abnahme durch Basti. 10. Zugänglichkeit des Einzugsgebiets (Aylin-Test).

## D. Lern-Routine (verbindlich, seit 2026-11-03)
**1. Wissenscheck** vor jeder fachlichen Antwort/Entscheidung: Steht sie hier mit Marke [K]/[V]/[R]? Ja: anwenden. Nein, oder nur [E]/[W]/niedrige Konfidenz: weiter mit 2.
**2. Recherche-Trigger** (einer genügt; laut sagen: "Wissenslücke: <Frage>, ich recherchiere"): a) Ich weiß es nicht oder rate. b) Derselbe Kompromiss/Workaround zum 2. Mal ("wieder X statt Y"). c) Eintrag unter Offene Lücken oder [E]/[W]/niedrig, und die Entscheidung hängt daran. d) Skill, Repo, Doku oder Messung widersprechen sich. e) Engine/Tool/Version neuer als der Skill-Stand. f) Basti korrigiert oder eine Entscheidung wird zurückgenommen. g) Teure oder unumkehrbare Entscheidung bei Konfidenz unter mittel. h) Derselbe Fix scheitert 2x.
Rollen-Trigger: Regel nur aus Gefühl begründet; Balancezahl ohne Vergleichsspiel; Frage nur per Prototyp klärbar (dann Prototyp statt Recherche).
Erst prüfen statt recherchieren, wenn billig messbar (Test, Doku-grep, Mini-Versuch). Geschmack klärt Prototyp oder Basti, nicht das Web.
**3. Ablauf**: Frage in einem Satz; Primärquellen zuerst (Doku, Issues, Forum, Postmortems; Reddit blockiert, nicht umgehen); 2 unabhängige Quellen; wenn möglich Eigenversuch [V]; Ergebnis mit Quelle, Datum, Marke. Budget 15 min, mehr nur als Agent. Unbeantwortet: Lücke eintragen, Basti/Team fragen, nie raten.
**4. Insight aufnehmen**, wenn alle vier stimmen: wiederverwendbar (2x gebraucht oder über 1 h Aufwand), belegt, noch nicht drin, kein Tagesstand (der gehört in Repo-Doku). Sofort bei Basti-Korrektur, Fehler im Skill oder Engine-Falle mit Repro, sonst gesammelt zum Sprintende. Eine Zeile mit Marke, Datum, Quelle; Widerspruch ersetzt den alten Eintrag; geschlossene Lücke streichen; Skill bleibt ca. 10.000 Zeichen. Im Account nur per Vorschlagskarte an Basti.
**5. Kompromisslog**: jeden Kompromiss, Workaround, jedes "wusste ich nicht" mit Datum in `sprints/s8/fortbildung/mt-gamedesign/LERNLOG.md` zählen; Zähler 2 löst Trigger b aus; Auswertung in der Sprint-Retro.
