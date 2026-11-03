---
name: mt-oekonomie
description: Wirtschafts- und Balancing-Wissen für Mega Tycoon (Godot-Transporttycoon 1820 bis heute): Ertrag, Nachfrage, Kredit/Zins/Bankrott, Presets, Bot-Messung. Nutzen bei Fragen zu Ökonomie, Kalibrierung, Bankrottquote, Nachfrage-Knick, Schwierigkeitsgraden oder T-15/T-16.
---

# Tobias, Ökonomie und Balancing (Wissensstand nach Fortbildung, 03.11.2026)

Rolle: Systems- und Economy-Designer. Dieser Skill ist in drei Teile gegliedert. A ist allgemeines Fachwissen mit Quellen, B ist nur, was das Repo `/home/claude/mega-tycoon` belegt (Dateiangabe je Aussage), C sind eigene Lücken und Konfidenz. Wer Zahlen verwendet, nennt die Quelle (Sx aus der Quellenliste am Ende von Teil A, oder Repo-Datei).

Kennzeichen: [K] Konsens (mehrere unabhängige Quellen oder Lehrbuchstand), [S] Streit (Quellen widersprechen sich), [E] Einzelmeinung oder Einzelquelle, [R] eigene Rechnung (nachprüfbar, keine Quelle), [~] aus dem Gedächtnis, in dieser Fortbildung nicht geprüft, [M] im Repo gelesen oder gemessen. Ohne Kennzeichen steht eine Aussage direkt hinter ihrer Quelle.

Ehrliche Vorbemerkung: Reddit (r/openttd, r/TransportFever, r/gamedesign, r/gamedev, r/factorio) war per WebFetch gesperrt (SITE_BLOCKED). Es wurde nicht umgangen, keine Spiegelserver, keine Umwege. tt-forums.net (Anubis-Sperre) und wiki.openttdcoop.org (robots.txt) waren ebenfalls nicht lesbar. Reddit-Meinungen fehlen deshalb vollständig. Forenaussagen stammen nur aus Steam-Thread und Blogs.

---

# TEIL A: Allgemeines Fachwissen

## A1 Grundmodell: Quellen, Senken, Wandler, Rückkopplung
- Spielökonomie = Fluss von Ressourcen durch ein System. Elemente: Pool (Speicher), Source (erzeugt), Drain (vernichtet dauerhaft), Converter (verbraucht A, erzeugt B, wirkt wie ein Drain, der eine Source auslöst), Gate (verteilt nach Wahrscheinlichkeit/Bedingung), State-Verbindung (Verteilung steuert andere Teile). Pools speichern nur ganze Zahlen. [K] S4 (Adams/Dormans, Machinations-Kapitel).
- Inflation entsteht, wenn Zuflüsse (Faucets) dauerhaft größer sind als Abflüsse (Sinks). Abhilfen laut S3: inkrementelle Mechaniken, Steuern/Gebühren, Prestige-Items, Resets. Schwellwerte nennt die Quelle nicht. Der Autor hält Inflation teils für nützlich (Nachzügler holen auf). [K/E]
- Mega-Tycoon-Übersetzung [R]: Faucet = Transportertrag je Lieferung. Sinks = Fahrzeugkauf, Fahrzeug-Fixkosten je Periode, Straßenbau, Lager, Lizenzen, Zins, Ausbaustufen, HQ-Stufen. Begrenzer der Zuflüsse = Nachfrage der Senke und Sättigung. Achtung Namenskollision: im Spiel heißt die Stadt „Senke“ (Abnehmer), in der Ökonomietheorie ist „Sink“ der Geldabfluss. Im Team immer „Abnehmer/Nachfrage“ und „Geld-Sink“ trennen.
- Rückkopplungen benennen: positiv (Gewinn, mehr Fahrzeuge, mehr Gewinn) und negativ (Sättigung, Unterhalt, Zins). Ein Tycoon braucht mindestens eine starke negative Rückkopplung im Mittelspiel, sonst Idle-Kurve (Tagebuch S7: nach M7 38 Minuten dieselbe Handlung, siehe Teil B).

## A2 Transportertrag: wie OpenTTD zahlt (wichtigste Vergleichsformel)
- Ertrag ≈ Menge × Distanz × Zeitfaktor × Frachtbasis. Distanz = Manhattan-Abstand der Stationen. Zeitfaktor 255 bis days1, danach linear sinkend, ab days1+days2 doppelt so steil, Minimum 31. Zeiteinheit = 2,5 Spieltage. Die genaue Gleichung steht im Wiki nur als Bild; die Formelform oben ist [~] aus dem Gedächtnis, die Tabellenwerte sind belegt. S1.
- Belegte Basis/days1/days2 (S1): Kohle 5916/7/255, Passagiere 3185/0/24, Post 4550/20/90, Getreide 4778/4/40, Stahl 5688/7/255, Waren 6144/5/28, Vieh 4322/4/18, Nahrung 5688/0/30, Holz 5005/15/255, Eisenerz 5120/9/255.
- Lehre [R aus S1]: days2=255 heißt „praktisch zeitunempfindlich“ (Kohle, Stahl, Holz, Erz). Passagiere (days1=0, days2=24) und Vieh/Nahrung zahlen sofort weniger, wenn sie langsam sind. Zeitempfindlichkeit ist der billigste Hebel, Frachtarten verschieden zu machen, ohne Preise zu ändern.
- Der Ertrag ist in OpenTTD linear in der Distanz. Wer Fernstrecken nicht überbelohnen will, braucht ein eigenes Dämpfungsglied (Mega Tycoon: Knick bei 60 Feldern, Teil B). Vergleich Transport Fever 2: Fracht zahlt nach Distanz, Passagiere nach Distanz mal Geschwindigkeitsfaktor (S9, Einzelquelle [E]); ein Rezensent schreibt, Fracht zahle voll ohne Zeitstrafe und die Nachfrage wachse nicht mit dem Transport (S10, [E] Einzelmeinung, Ein-Sitzung-Eindruck).
- Simutrans-Extended-Formel war nicht abrufbar (Seite lieferte keinen Inhalt). Keine Aussage dazu.

## A3 Stadtwachstum und Nachfrage in Referenzspielen
- OpenTTD (S2, S5, S6): Eine Station ist „aktiv“, wenn in den letzten 50 Tagen Fracht be- oder entladen wurde (nicht 20). Es zählen bis zu 5 Stationen. Ohne Service wachsen Städte sehr langsam. Städte (Cities) wachsen doppelt so schnell. Bank ab 1.200 EW. 1 Mio. EW entspricht 150–200 Felder Durchmesser.
- Wachstumsintervall nach Zahl aktiver Stationen (normale Geschwindigkeit, S5 TTDTownGrowth): 0 Stationen 160 (mit Blockierwahrscheinlichkeit), 1: 210, 2: 150, 3: 110, 4: 80, ab 5: 80 (der Originalwert 11 war ein Fehler). Gefördert („funded“): 60. Option „largertowns“ halbiert die Wartezeit. Transportzone-Radius wächst mit der Gebäudezahl von 2 Feldern (0–3 Gebäude) bis 9 (36–71 Gebäude). ttdpatch: höchstens 4/5 Stationen zählen, „Fund new buildings“ wirkt 3 Monate (S6). [K, drei Quellen, aber zwei davon sind Fan-Dokumentation der Original-TTD-Mechanik, nicht des heutigen OpenTTD]
- Lehre [R aus S5]: Der Grenznutzen der 2., 3., 4. Station sinkt nicht, er steigt (210 auf 150 auf 110 auf 80). OpenTTD belohnt Breite, nicht Tiefe. Mega Tycoon belohnt dagegen Versorgungsgrad (Teil B). Beides ist ein Designentscheid, kein Naturgesetz.
- Community-Regelvorschlag (Peter1138, S7, nicht Vanilla [E]): 7 Größenklassen (Community <300, Village 300–600, Township 600–1.000, Town 1.000–3.000, City 3.000–6.000, Metropolis 6.000–15.000, Capital bis 15.500). Wachstum nur bei erfüllter Nachfrage (Fracht pro Monat, steigt mit der Klasse). Unter 150 EW wächst ein Ort von selbst. Nützlich als Gegenentwurf zu „Nachfrage = Einwohner/100“.
- Transport Fever 2: Wachstum als Prozentboni auf eine Basisgröße. Spieler nennen Fracht bis +200 %, Passagier-Anbindung und Ortsdichte (Cluster bis +1.500 %). Streit [S] über Obergrenze natürlicher Orte (rund 2.700 vs. 3.000+) und ob Basisbevölkerung wächst (Zapp: nein; Vimpster: bis +50 %). Alles Forenstand Oktober 2023, nichts offiziell (S11 Steam-Thread).
- Mod „Logistic Challenge“ (S12, [E] Modder-Konzept): 7 Ortsstufen, „Euphorie“ bei Stufenwechsel (wächst ohne Versorgung, kann nicht schrumpfen), Nachfragekomplexität steigt mit der Stufe (Rohstoffe, dann verarbeitete Güter, dann Pakete), Ortsverbrauch 2.000 Güter vs. 200 vanilla, volles Ausbauen 100–200 Stunden. Relevante Idee für Stufen-Tore, nicht übertragbar ohne Messung.
- Iron Roads (Devlog, S13 [E]): Wachstum an EIN klares Ziel koppeln (pünktliche Ankunft), damit Spielende wissen, was sie tun sollen. Keine Zahlen.

## A4 Kredit, Zins, Bankrott
- OpenTTD-Voreinstellungen (S14, Archiv-Wiki, Version evtl. veraltet [E]): Easy/Medium/Hard: Konkurrenten 2/4/7, Anfangskredit 300.000/150.000/100.000 GBP, Zins 2/3/4 %, Subventionen ×3/×2/×1,5, Gelände flach/hügelig/gebirgig, Baukosten niedrig/mittel/hoch, Pannen reduziert/normal/normal. Aktuelle Struktur: 22 Felder in DifficultySettings, darunter max_loan, initial_interest, vehicle_costs, subsidy_multiplier, construction_cost, terrain_type, town_council_tolerance, economy (Volatilität), infinite_money (S15).
- Transport Fever 2: fester Zins 1 %/Jahr; Hard bedeutet schmalere Margen, Schiffe 2,5-fache Betriebskosten (S9, [E]).
- Bankrottregel OpenTTD: keine geprüfte Quelle erreicht (tt-forums gesperrt, Wiki-Seiten lieferten nichts). Gedächtnis: mehrere aufeinanderfolgende Quartale mit negativem Saldo lösen Warnung, dann Bankrott/Übernahme aus; die genaue Quartalszahl ist [~] und darf nicht als Fakt zitiert werden.
- Designprinzip [R aus Teil B]: Kredit ist ein Sicherheitsnetz mit Zeitform: Zins erzeugt Druck, Rahmen und Sperren erzeugen Entscheidungen, Zwangsverkauf ist die Strafe. Die Wirkung auf die Bankrottquote ist steil im Startkapital (siehe B8): Kapital und Zins sind die scharfen Hebel, Nachfrage der erste Hebel, der große Streuung erzeugt.
- Colossal Order (Cities: Skylines II, S16): „Government Subsidies“ decken Betriebskosten in der Frühphase und schrumpfen, wenn die Stadt selbsttragend wird. Das ist ein bewusster, auslaufender Faucet für den Einstieg [K im Genre, einzelne Quelle].

## A5 Schwierigkeit als Daten
- Zwei Hebelfamilien: Geld-Hebel (Kapital, Zins, Baukosten, Unterhalt) sind transparent und per Bot messbar, lassen die Welt gleich. Welt-Hebel (Relief, knappe Rohstoffe, Siedlungsdichte) verändern Entscheidungen, vermischen sich aber mit dem Seed (ein schwerer Seed auf Leicht ist nicht leicht). Diese Spannung steht im Repo als Streit Tobias/Lena (`phase2/04_schwierigkeit.md`) und entspricht der OpenTTD-Aufteilung (S15: Gelände, Dichte, Baukosten neben Geldfeldern). [K]
- Dynamische Schwierigkeit (DDA, S17): Challenge-Funktion; Gummiband sparsam; Rollings/Adams: Anpassung verbergen; Hunicke/Chapman: Parameter manipulieren statt Gegner buffen. [S] Fairness gegen Unvorhersehbarkeit (Spannung) ist unentschieden; ein Gegenbeispiel (EA-Klage) ist nicht entschieden. Für Mega Tycoon folgt: unsichtbarer Ertragsabfall wirkt wie ein Fehler (Aylin in K37), deshalb Konkurrenz sichtbar.
- Konkurrenz-KI in OpenTTD (S18, S19, S20): Zahl der KIs, Startintervall, Verbote je Fahrzeugtyp (Zug, Straße, Flug, Schiff getrennt), Rechenbudget „opcodes“ (5.000–250.000, empfohlen 10.000: weniger Zeit = meist leichtere KI), Profil Easy/Medium/Hard wird an KIs gemeldet. Die Verhaltensseite empfiehlt (optional) eine „freundliche“ Einstellung, die den Wettbewerb um gemeinsame Industrien senkt, auf Easy standardmäßig an, und nie exklusive Transportrechte kauft. Keine Bankrottaussage.
- RollerCoaster Tycoon (S21 Sawyer-Interview, S22 Artikel): Schwierigkeit kommt aus Szenario-Randbedingungen (Startlage, Landrechte, Ziel „1.000 Gäste bis Jahr 3“), nicht aus Einstellungen. Preis folgt Aufregung. Forschung = Budget plus Zufall innerhalb einer Kategorie; der Artikel nennt das intransparent [E]. Lehre: Ziele als Schwierigkeitsträger sind ein echter dritter Hebel neben Geld und Welt.

## A6 Balancing-Methodik (Tabellen, Anker, Kurven)
- Spreadsheet-Methode (S23): Normalisieren (v−min)/(max−min), Kurve wählen, min/max-Grenzen setzen, gewichtetes Mittel; Ausreißer stauchen; Farbkonvention Eingaben grün, Kurven gelb, Formeln weiß. [K]
- Anker-Denken (S24, GDC-Vault, nur Sitzungsbeschreibung, Volltext nicht gelesen): „Balance anchors“, Kernbeziehungen, Constraint-getriebenes Design. Nur als Stichwortliste verwendbar.
- Schreiber/Romero, Game Balance (S25, nur Inhaltsverzeichnis): Kostenkurven (transitive Mechaniken), Wirtschaftssysteme, Progression, Tabellenkalkulation in jedem Kapitel. Playtesting wird im Klappentext nicht erwähnt.
- Factorio FFF-275 (S26): Science-Pack 3 kostete etwa das 4,5-Fache der ersten beiden zusammen (Spike); Spreadsheet-Modell; Gesamt-Erzkosten −10 %; Ziel war, die Schwierigkeitsprogression zu glätten und die Pfadwahl klarer zu machen. FFF-376 (S27): Trigger-Technologien (Freischaltung durch Handlung statt Labor), unendliche Forschung mit exponentiellen Kostenbasen unter 2; Kommentator rechnete 1,2 Billionen Packs für Stufe 30 (nicht bestätigt, Kostenbasis offen).
- Colossal Order (S16): Meilenstein-XP wachsen exponentiell und bestimmen das Tempo; XP-Belohnungen für Straßen/Gebäude so gesetzt, dass Straßen allein keinen Meilenstein auslösen (Exploit-Prävention); Master-Spreadsheet mit Zwei-Wege-Sync ins Projekt; Dev-Meinung: Kraftwerke sollen alle „eine gültige Wahl“ sein; etwas XP-Cheese ist akzeptabel.
- Merksatz [R]: Eine Kostenkurve ohne Plateau-Prüfung erzeugt Spikes (FFF-275). Vor jeder Preistabelle: Zeit bis zur Amortisation je Stufe als Spalte, Verhältnis zur nächsten Stufe als zweite Spalte, Sprung >2 begründen.

## A7 Sensitivitätsanalyse und Bot-Tests
- Eine-Variable-je-Lauf (OAT) übersieht Wechselwirkungen und deckt bei 5 Eingaben weniger als 1 % des Parameterraums ab. Besser: Morris-Screening (billig, Rangfolge), Latin-Hypercube-Stichproben, Sobol-Indizes (viele tausend Läufe). Checkliste mit 5 Schritten in S28. [K]
- Prozedurale Personas (S29, Holmgård et al.): MCTS plus evolvierte Heuristiken, 4 Personas, 11 Karten mal 50 Läufe; ein „Runner“-Persona gewann 100 % gegen 10 % der Basis. Grenze: Personas sind handgemacht und nicht gegen Menschen validiert. Übertragung [R]: ein Bot misst Drift und Obergrenzen des Schadens, nicht echtes Spielverhalten.
- Stichprobengröße [R]: 95-%-Intervall einer Quote p bei n Läufen ≈ ±1,96·√(p(1−p)/n). Bei p = 15 %: n=100 ±7,0 Punkte; n=150 ±5,7; n=300 ±4,0; n=450 ±3,3; n=900 ±2,3; n=2.700 ±1,3. Neun Läufe lösen 15 % nicht auf (95-%-Intervall 2–44 %, so im Repo ausgewiesen). Gepaarte Vergleiche (gleiche Verhaltens-Seeds in allen Varianten) senken die Varianz der Differenz; das Repo nutzt das (B9).
- Typische Bot-Fallen [R]: kassegesteuerte Entscheidungen erzeugen nicht-monotone Kurven (mehr Nachfrage, trotzdem früherer Bankrott), weil ein Kauf zeitlich verschiebt; deshalb immer zwei Messpunkte (Bankrott@30 und Bankrott@60) plus Netto-Kapital angeben. Bot kauft nach Angebot statt nach Nachfrage: pessimistisch für kleine Abnehmer.

## A8 Historische Realwirtschaft um 1820 (für Ketten-Parameter)
- Mühlen, Kurmark (S30): 1801 gab es 2.053 Dörfer, 427 ländliche Wassermühlen, 638 Windmühlen, 330 Stadtmühlen. Rechnung [R]: etwa 0,52 ländliche Mühlen je Dorf. Dörfer je Mühle um 1800: Altmark 1,5, Prignitz 2,8, Uckermark 2, Mittelmark 2,1. Mühlenbann und -zwang fielen 1810 mit der Gewerbefreiheit. Mahlleistung nicht angegeben (Lücke). Die Wikipedia-Seite Wassermühle enthält keine Dichte- oder Leistungszahlen.
- Köhlerei Brandenburg (S31): Meiler 4–30 m lang (selten über 12 m), 40–50 Raummeter Holz je Brand, Brenndauer 5–8 oder 12–15 Tage, Saison März bis Oktober. Holzkohleausbeute [S]: 6,75 Zentner je Raummeter (Teicher 1977) gegen etwa 1 Zentner je Raummeter Kiefer (Heuer/Mätzke 1926); die Quellen widersprechen sich deutlich. Verbrauch Hammerwerk Peitz 2,1 Zentner Holzkohle je Zentner Roheisen, Gottow 1,7. Boitzenburg 1838: 20.254 Tonnen verkauft, bei 220 kg je preußische Tonne rund 4.450 t.
- Chaussee (S32): Breite 24–30 Fuß (8–10 m), Steigung 3–5 %, Chausseehaus alle 1–1,5 Wegstunden; Fuhrwerk trägt die dreifache Last; Postkutsche Altona–Kiel 16 h auf alter Straße, 9 h auf der Chaussee. Preußen ab 1788 Magdeburg–Halle–Leipzig über 100 km.
- Flößerei (S33): Rheinflöße 200–400 m lang, 40–80 m breit, 400–500 Mann; Bayern Höhepunkt 1848 etwa 5.800 Flöße je Jahr; Ordinari München–Wien wöchentlich, rund 7 Tage, 3 Gulden; Trift 2–3 % Verlust; ein Holländerfloß konnte bis zu 2 Jahre von Bindung bis Verkauf brauchen, Crew rund 3 Monate an Bord (S34); Wolfach 1763: 20 % der Erwerbsbevölkerung im Floßgeschäft; Saison April bis November, Kinzig bis 10 Gestöre gekoppelt (S35). Rückreise der Flößer: in keiner gelesenen Quelle beschrieben (Lücke).
- Verstädterung (S36, S37): Deutsches Reich 1871 63,9 % der Bevölkerung in Orten unter 2.000, 1900 45,6 %; Städte über 10.000: 271 (1875) auf 576 (1910); über 200.000: 3 auf 23. Zahlen für 1800 und 1850 fehlten in beiden Quellen. Dorfgrößen (S38, Lienau/Henkel): Weiler bis ca. 100 EW, kleines Dorf unter 500, normales Dorf unter ca. 2.000; Faustformel 4–5 EW je Hausstätte.
- Lehre für Ketten [R]: 1820 sind Mühle (Getreide), Kohle/Holzkohle (Wald), Erz/Hütte, Holz (Floß) die Frachtfamilien. Mengenparameter je Kette (Tonnen je Monat) stammen im Spiel aus dem Design, nicht aus belegten Realdaten; die Fortbildung fand keine belastbare Durchsatzquelle.

## A9 Checkliste Ökonomie-Änderung (vor jedem PR gegen `economy_constants.json`)
1. Welche Zielgröße ändert sich (Bankrott@30, Bankrott@60, M7-Zeit, Break-even, Netto@30)? Vorher-Wert mit n und Intervall notieren.
2. Welcher Hebel (Kapital, Zins, Nachfrage, Preis, Kosten)? Nie zwei gleichzeitig ändern, wenn die Wirkung gemessen werden soll.
3. Gleiche Bot-Seeds wie die Vorgängermessung (gepaart). Kontrollkette ohne Änderung muss bitgleich bleiben.
4. Plateau- und Spike-Prüfung: Amortisationszeit je Stufe, Sprung zur nächsten.
5. Exploit-Frage: gibt es eine Handlung, die den neuen Wert umgeht (Straßen allein, Lager-Hub, Zug statt Lkw)?
6. Ist der Preset-Hebel steil? In 500-$-Schritten messen (B8), nicht schätzen.
7. Nach Änderung: Regressionstests (`slice_test`, `parity_test`, `d08_bankrott`) und M7-Skriptspieler laufen lassen; Drift gegen T-15 dokumentieren (B10).

## A10 Typische Fehler (aus Quellen und eigener Rechnung)
- Preise kalibrieren, bevor die Nachfrage der Abnehmer steht (Folge: Bot-Quote bricht bei kleinen Orten, B7).
- Sprung zwischen Ortsklassen: größere Klasse mit weniger Nachfrage als kleinere (K18, B7). Regel: Nachfrage muss über Einwohner und Klasse monoton sein.
- Nur Mittelwerte berichten: Bankrottquote ohne Intervall, ohne n, ohne Zeitpunkt.
- Eine Karte kalibrieren und auf alle verallgemeinern (Slice-Karte, 8 Orte, B7).
- Konkurrenz als unsichtbarer Ertragsabfall (wirkt wie Bug, K37).
- Zwei Epochentabellen im Umlauf (B11): jede spätere Ökonomie-Messung braucht genau eine.

## A11 Formelsammlung (Spickzettel, alle [R] bis auf Quellenangabe)
- Amortisationszeit eines Fahrzeugs: T = Kaufpreis / (Ertrag je Periode − Fixkosten − variable Kosten je Periode). Bei T > Restlebensdauer ist die Stufe ein Verlustgeschäft; bei T < 1 Periode ist sie ein Exploit.
- Sprungfaktor zwischen Stufen: Preis(n+1) / Preis(n). Ab > 2 begründen oder glätten (FFF-275: 4,5-facher Spike war der Anlass der Überarbeitung, S26).
- Sättigungsgrad s = geliefert / Nachfrage je Periode. Erlös je Einheit ist Funktion von s (OpenTTD-Analogon: aktive Stationen, S5). Grenzerlös = d(Erlös)/d(Menge): das ist die Größe, die Spielende spüren.
- Mindestnachfrage einer Senke, damit eine Lieferquelle mit Angebot A ohne Sättigungsverlust läuft: Nachfrage ≥ A. Bei Angebot 20 E/min also Sim-EW ≥ 1.000 (Dorf ×2) bzw. ≥ 2.000 (×1).
- Binomial-Intervall für Quoten: ±1,96·√(p(1−p)/n) (Werte in A7). Für den Unterschied zweier gepaarter Läufe sinkt die Streuung, sofern dieselben Seeds laufen.
- Normalisieren einer Kennzahl für Tabellen: (v − min)/(max − min) (S23). Gewichtetes Mittel nur über normalisierte Spalten.

## Quellen Teil A (alle per WebFetch geöffnet, außer wo „nur Suchtreffer“ steht)
- S1 OpenTTD Wiki Cargo income https://wiki.openttd.org/en/Manual/Game%20Mechanics/Cargo%20income
- S2 OpenTTD Wiki Towns https://wiki.openttd.org/en/Manual/Towns
- S3 Machinations, Spielinflation https://machinations.io/articles/what-is-game-economy-inflation-how-to-foresee-it-and-how-to-overcome-it-in-your-game-design
- S4 Adams/Dormans Machinations (Pearson-Leseprobe) https://ptgmedia.pearsoncmg.com/imprint_downloads/peachpit/peachpit/samplechapters/0321820274/0321820274_gamemechanics_ch05section.pdf
- S5 TTWiki TTDTownGrowth https://www.tt-wiki.net/wiki/TTDTownGrowth
- S6 ttdpatch New Town Growth https://ttdpatch.net/Manual/New-Town-Growth-Mechanism.html
- S7 Peter1138 Towngrowth Challenge https://wiki.openttd.org/en/Community/Essays/Peter1138's%20Towngrowth%20Challenge
- S9 gameplay.tips TF2-Guide https://gameplay.tips/guides/9066-transport-fever-2.html
- S10 dedoimedo TF2 https://www.dedoimedo.com/games/transport-fever-2.html
- S11 Steam-Thread TF2 Stadtwachstum https://steamcommunity.com/app/1066780/discussions/0/3879346999825598874
- S12 transportfever.net Logistic Challenge https://www.transportfever.net/lexicon/entry/427-logistic-challenge-new-gameplay/
- S13 Iron Roads Devlog 026 https://cowleyforniastudios.itch.io/iron-roads/devlog/694919/026-reworking-town-growth
- S14 OpenTTD Wiki Difficulty (Archiv) https://wiki.openttd.org/en/Archive/Manual/Settings/Difficulty
- S15 OpenTTD DifficultySettings (Quellcode-Doku) https://docs.openttd.org/source/d6/d6c/structDifficultySettings
- S16 Colossal Order, Behind the Scenes 3: Game Balancing https://colossalorder.fi/news/behind-the-scenes-3-game-balancing/
- S17 Wikipedia Dynamic game difficulty balancing https://en.wikipedia.org/wiki/Dynamic_game_difficulty_balancing
- S18 OpenTTD Wiki AI settings https://wiki.openttd.org/en/Manual/AI settings
- S19 OpenTTD Wiki Competitors (Archiv) https://wiki.openttd.org/en/Archive/Manual/Settings/Advanced%20Settings/Competitors
- S20 OpenTTD Wiki Script Behaviour https://wiki.openttd.org/en/Development/Script/Behaviour
- S21 Chris-Sawyer-Interview (rctspace) https://rctv1.rctspace.com/test/info/interview.html
- S22 Spieltimes, Breaking down RollerCoaster Tycoon https://www.spieltimes.io/news/breaking-down-rollercoaster-tycoon
- S23 Game Developer, Economy balancing mit Spreadsheets https://www.gamedeveloper.com/design/my-approach-to-economy-balancing-using-spreadsheets
- S24 GDC Vault, Balancing the Economy for Albion (nur Beschreibung) https://gdcvault.com/play/1024070/Balancing-the-Economy-for-Albion
- S25 Routledge, Game Balance (nur Klappentext/Inhalt) https://www.routledge.com/Game-Balance/Schreiber-Romero/p/book/9781315156422
- S26 Factorio FFF-275 https://factorio.com/blog/post/fff-275
- S27 Factorio FFF-376 (Spiegel) https://devtrackers.gg/factorio/p/82118ef4-friday-facts-376-research-and-technology
- S28 Wikipedia Sensitivity analysis https://en.wikipedia.org/wiki/Sensitivity_analysis
- S29 Procedural Personas, Holmgård et al. https://ar5iv.arxiv.org/html/1802.06881
- S30 Brandenburgikon, Mühlenwesen https://www.brandenburgikon.net/index.php/de/sachlexikon/muehlenwesen
- S31 Brandenburgikon, Köhlerei https://brandenburgikon.net/index.php/de/sachlexikon/koehlerei
- S32 Wikipedia (de) Chaussee https://de.wikipedia.org/wiki/Chaussee
- S33 Wikipedia (de) Flößerei https://de.wikipedia.org/wiki/Fl%C3%B6%C3%9Ferei
- S34 Planet Wissen, Floßschifffahrt https://www.planet-wissen.de/technik/schifffahrt/geschichte_der_schifffahrt/pwiegeschichtederflossschiffahrt100.html
- S35 Schwarzwald-Tourismus, Holländertanne https://www.schwarzwald-tourismus.info/schwarzwald/online-magazin/geschichten-aus-dem-schwarzwald/kultur/der-weg-der-hollaendertanne
- S36 Wikipedia Urbanization in the German Empire https://en.wikipedia.org/wiki/Urbanization_in_the_German_Empire
- S37 Pfister, Urban population in Germany 1500–1850 (nur Zusammenfassung, ohne Zahlen für 1800/1850) https://ideas.repec.org/p/cqe/wpaper/9020.html
- S38 Wikipedia (de) Dorf https://de.wikipedia.org/wiki/Dorf
- S8 Anno-Wiki Population (geöffnet, enthält keine Verbrauchszahlen, daher nur Tier-Freischaltung: Village 100 Bauern, Port Town 150 Arbeiter, City 500 Handwerker; Aufstieg braucht volles Haus, Grundbedarf, Baumaterial) https://anno1800.fandom.com/wiki/Population?oldid=2694
- Nur Suchtreffer (nicht geöffnet, nicht belegt): tt-forums „New/Different Bankrupcy model(s)“ https://www.tt-forums.net/viewtopic.php?p=1050512 (Forum gesperrt). Reddit nicht aufgerufen.

---

# TEIL B: Wissen für Mega Tycoon (nur Belegtes aus dem Repo)

Pfade relativ zu `/home/claude/mega-tycoon/`. Stand der Quellen: 03.11.2026.

## B1 Zeit, Raum, Währung
- Tick 100 ms, 1 Periode = 600 Ticks = 60 s = 1 Spielmonat, 1 Spieljahr = 7.200 Ticks = 12 Minuten. `slice/data/economy_constants.json › zeit`.
- Geld in Cent, Festkomma, Rundung „halb auf“, alle Multiplikationen zuerst, genau eine Division am Ende. `slice/data/economy_constants.json › rundung`.
- Welt: 1 Feld = 25 m, Karte 512² Felder = 12,8 km. `sprints/s8/design-sprint/phase2/01_skalen.md`, `phase3/12_welt_regelwerk_v1.md`. Entscheid E13: Karte bleibt zunächst bei der heutigen Größe (`sprints/s8/design-sprint/charter.md`).

## B2 Ertragsformel (Slice-Code)
- `ertrag_cent = runde(einheiten × preis_cent_pro_einheit_feld × d_eff_felder × f_zeit × f_saett)`. `d_eff = d` bis 60 Felder, danach `60 + 0,5·(d−60)`; Mindestdistanz 6 Felder (darunter 0). `slice/data/economy_constants.json › ertrag`.
- Sättigung `f_saett`: 1,0 bis 100 % der Nachfrage, linear auf 0,4 bei 150 %, darüber 0,1; gilt je Stadt und Warenkategorie. `economy_constants.json › saettigung`, `slice/data/economy_slice.json › saettigung (sat_scope_modus: je_stadt_und_kategorie)`.
- Fahrzeuge: Lkw (E1) 400 $, Fixkosten 90 $/Periode, 8 Cent je Feld, Kapazität 10, 0,6 Felder/Tick; Dampflok 1.500 $, 170 $/Periode, 15 Cent je Feld. `slice/data/vehicles.json`. Straße 10 $/Feld, Lager 800 $ (Unterhalt 30 $/Periode, Kapazität 200). `economy_constants.json › bau`.
- Ausbaustufen Verarbeiter: Durchsatz 20/40/70/110 Einheiten je Periode, Kosten 0/2.000/6.000/15.000 $. `economy_constants.json › ausbau`.
- Lizenz: Anteil 100 ‰, Laufzeit 18.000 Ticks (30 min), Radiusrabatt 300 ‰, Zuschlag 120 ‰ je Feld außerhalb, Hinweis 1.800 Ticks vor Ablauf, 1 Gratislizenz zum Start. Kauf: Anrechnung Lizenz 500 ‰, Werksmarge 150 ‰, Unterhalt 20 $/Periode je Stufe, M5b-Rabatt 200 ‰ einmalig. `economy_constants.json › lizenz, kauf`. Lizenz +10 % je Verlängerung ist Konzept/Platzhalter (G-01), nicht als Konstante gefunden: `sprints/s7/block-b/g01_progression.md` §3.

## B3 Nachfrage der Orte (der entscheidende Hebel)
- `city_demand = Sim-EW × demand_per_100 (=1) × mult(Stufe) / 100` je Periode; Multiplikator Dorf ×2, Kleinstadt/Stadt/Metropole ×1. `slice/data/economy_slice.json › saettigung`. Beispiele [R aus Konstanten]: Dorf 900 EW → 18/min; Marktflecken 1.200 EW (Sim-Stufe „kleinstadt“) → 12/min; Kleinstadt 2.400–4.700 EW → 24–47/min. Das bestätigt `sprints/s8/design-sprint/phase4/tobias_welle1.md` §1 („Dorf 8–18/min, Marktflecken 12–19/min, Kleinstadt 24–47/min“).
- Warenkorb nach Stufe: Dorf und Kleinstadt nur „nahrung“, Stadt „nahrung“ und „stahl“. `economy_slice.json › saettigung.basket_by_stage`. Die Stufe steuert außerdem den HQ-Radius (Mittelfurt „stadt“ → „kleinstadt“: 45 → 50 Felder, Dorf 55; tobias_welle1 §2.4).
- Welt-Regelwerk v1: Sim-EW = Ort-EW (sichtbare Häuser) + Umland-EW (Gemarkung); Umland fest ab Generierung, Wachstum nur im Ort; Sim-Stufe-Schwellen 1.000/5.000/20.000. Ortsbänder: Dorf Ort 150–350 / Sim 400–900; Marktflecken 800–1.300 / 1.200–1.900; Kleinstadt 2.000–4.000 / 2.400–4.700. `sprints/s8/design-sprint/phase3/12_welt_regelwerk_v1.md` §3, `slice/world/data/proto/regelwerk.json`.
- Erwartung laut Regelwerk: Sim-EW gesamt ≈ 20.000 (12.000–29.500) gegen 36.250 in S7, also etwa 55 % der S7-Nachfrage im Mittelspiel (`phase3/11_streitprotokoll.md` K1).

## B4 Wachstum (Konstanten vorhanden, im Slice nicht verdrahtet)
- Variante B: Basisrate 180 bp/Monat bei Versorgung ≥ 80 %, 45 bp bei ≥ 50 %, 0 bei ≥ 30 %, −45 bp darunter; Zuschlag max. 250 ‰ (Personen 625 ‰, Jobs 375 ‰); Stufen-Tor bei 950 ‰ Haltestellenanteil, Mindestversorgung 250 ‰; Etikett „ungetestet“. `economy_constants.json › wachstum`.
- Befund: Die `wachstum`-Daten sind im Slice-Code nirgends verdrahtet, Einwohner sind statisch (`tobias_welle1.md` §2.1 und §7 Punkt 7). Wachstum ist ökonomisch also nicht gemessen. E7: Orte bleiben ohne Versorgung stabil, wachsen nur mit Versorgung (`charter.md`).
- Stadt-KI-Prototyp: Erlenbach 244 → 307 EW in 12 Monaten mit Versorgung (Rate 180 bp, max. 1 + Ort-EW-Soll/500 Aktionen je Monat, 8 EW je Aktion), ohne Versorgung 244 (0 Aktionen). Annahme Sim-EW 650, Umland 406 fest; Konstante `RATE_BP`, die economy-`wachstum.band` wird dort nicht gelesen. `phase4/stadt_welle1.md` §Wachstum.

## B5 Kredit, Zins, Bankrott (Slice-Stand)
- Startkapital 6.000 $ (600.000 Cent). Kreditrahmen 2.000 $ in 500-$-Schritten, verfügbar ab Tick 7.200 (Minute 12), Zins 30 ‰ je Periode (3 %/min), Sperre für Firmenkauf und Ausbau im Minus, Zwangsverkauf nach 6.000 Ticks (10 min) unter dem Rahmen. `economy_constants.json › kredit, startkapital_cent`.
- Konflikt im Repo: Der Entwurf T-05 (`design/economy/day4-6/t05_final.md` §3, D1) legt „Kreditrahmen ab Minute 0“ fest und rechnet mit 1 %/min Zins. Der Slice und T-15/T-16 laufen mit Minute 12 und 3 %/min. Das Repo markiert den Entwurf nicht ausdrücklich als überholt; verbindlich für Messungen ist der Slice-Stand (`tobias_welle1.md` Kopfzeile).
- Schwierigkeits-Skizze (nicht implementiert, Entscheid S8): Leicht 9.000 $ / Rahmen 3.000 $ ab Min. 6 / 2 %; Normal 6.000 $ / 2.000 $ ab Min. 12 / 3 %; Schwer 4.500 $ / 1.500 $ / 4 %. Bankrottregel Zwangsverkauf/Vorwarnung 15 min/180 s, 10 min/90 s, 7 min/60 s. Nachfrage- und Wachstumshebel ×1,25/×1,0/×0,8, Baukosten ×0,8/×1,0/×1,25. `sprints/s8/design-sprint/phase2/04_schwierigkeit.md`.
- Ziel-Bankrottquoten je Stufe: Leicht ≤ 5 %, Normal 15–18 %, Schwer 30–40 % (Schwer ist Annahme). Gelten laut K40 inklusive Konkurrenz. `phase2/04_schwierigkeit.md`, `phase3b/15_regelwerk_v1_1.md` K40.

## B6 Der Bot und seine Grenzen
- `slice/tests/d08_bankrott.gd` (T-16, D-08): Test-Spieler über die Main-API mit echten Spielbefehlen, deterministisch je Seed. Spielertypen sorgfältig/normal/hastig 40/40/20 %, Kredit-Haltung nie/Bedarf/voll/Hebel 35/45/15/5, Lkw je Teilstrecke nach Angebot (20 E/min), gefittete Faktoren `KALIB`. `phase4/tobias_welle1.md` §2.1.
- Er spielt nur die Slice-Karte (`data/slice_map.json`, 8 Orte, drei Ketten Haberau/Mittelfurt/Kohlberg). Auf `world_s7.json` hätte er keine gültigen Routen. T-15/T-16 sind auf der Slice-Karte kalibriert. `tobias_welle1.md` §2.1.
- Die Maus-Variante `tools/play.sh` (xvfb, ~20 s je Lauf) ist für Stichproben zu langsam. Test-Hooks `slice/tests/p4_umland_bot.gd` und `p4_umland_bot2.gd` (Kopien in `phase4/tobias_welle1_daten/hooks/`) setzen per `--orte=id:einwohner:stufe,…` Einwohner und Stufe. Kontrolle: Hook ohne `--orte` reproduziert `d08_bankrott` exakt.
- Bot-Grenze (Tobias selbst): kauft Lkw nach Angebot, nicht nach Nachfrage, also pessimistisch für kleine Abnehmer; Hub-Kauf kassegesteuert, daher Bankrott@30 nicht monoton. `tobias_welle1.md` §2.4, §7.

## B7 Messergebnisse Welle 1 (K1-Stichprobe, 03.11.2026)
- Gesamt: Bankrott@30 17,8 % (95 %-KI 16–19, n = 2.700) gegen 15,6 % heute (n = 900). Band 10–30 % und T-16-Band 12–21 % erfüllt. T-16-Messwerte (n=100): Mittelfurt 15, Haberau 17, Kohlberg 18 %; n=300: 14,3 / 18,3 / 14,0 %. `tobias_welle1.md` §1, §3.2; `sprints/s7/block-b/tobias.md` §3.
- Aber: Senken unter etwa 15 Nachfrage/min treiben Bankrott@30 auf 27–35 % (Haberau-Kette ab Dorf ≤ 650 EW, Mittelfurt-Kette bei Dorf ≤ 550 EW oder Marktflecken 1.200 EW). Mittelfurt-Kette Dorf 520 EW (Welt W2): 32,7 % gegen 14,3 % heute (n = 300). Anteil Orte unter 15/min: Dorf 70 %, Marktflecken 43 %, Kleinstadt 0 %, über die Ortsmischung 76/14/10 % etwa 59 % aller Orte. Ortsmix-Erwartung Haberau-Kette 24 %, Mittelfurt-Kette 21,5 %. `tobias_welle1.md` §1, §3.3.
- M7 (Proxy: Netto ≥ 12.000 $, Zielband 35–50 min): Skriptspieler B heute 36,0 min (T-15: 30,4). Bei Senke ≥ 1.900 EW 36,0–38,2 min; Dorf 650 EW 52,5; Marktflecken 1.200 EW 55,4 (außerhalb); Dorf ≤ 520 EW in 60 min nicht erreicht. Skriptspieler C (Kohlberg-Kette) robuster: 39,8–45,3 min bis Senke 520 EW. Kein Skriptlauf geht pleite. `tobias_welle1.md` §3.4.
- Unberührt: Zug : Lkw 2,9 : 1 (gemessen am Mühleneingang, nicht an einer Stadt), erste Zahlung 2,5–2,7 min, Break-even-Median 11,8/13,6 min, Ziele Z2–Z7 bis Minute 3,2, Netto@30 Ø 7.459 $ gegen 7.748 $. `tobias_welle1.md` §1.
- K18-Knick: Marktflecken (1.200 EW, Sim-Stufe „kleinstadt“ ×1,0 = 12/min) fragt weniger nach als Dorf (900 EW, ×2 = 18/min). Streitprotokoll: „unverändert, an Tobias S8“ (`phase3/11_streitprotokoll.md` K18). Knickfrei erst, wenn der Marktflecken-Multiplikator von 1,0 auf mindestens 1,5 steigt. Gegenvorschlag „Dorf-×2 abschaffen“ wurde als schlechter bewertet; wählt man Sim-Stufe „dorf“ (×2) für Marktflecken, hat dieser 24–38/min (`tobias_welle1.md` §5 Punkt 3, §7 Punkt 6).

## B8 Gegenmittel und Schwellen (Daten, keine Regeländerung)
- Nachfrage je 100 EW × k, gepoolt n = 450 je Kette: k = 1,0 / 1,25 / 1,5 → Mittelfurt Bankrott@30 21,6 / 16,7 / 14,9 %, Bankrott@60 28,4 / 24,7 / 21,1 %; Haberau Bankrott@30 19,3 / 16,0 / 14,0 %. Proxy-M7-Quote Mittelfurt 48 → 56 % (heute 58 %). ×1,25 bringt ins T-16-Band, ×1,5 zusätzlich Bankrott@60 näher an heute. Rest: Dorf 400–600 EW bleibt auch bei ×1,5 bei 12–18/min; Mindestnachfrage 18/min je Senke (= Haberau heute) behebt das. `tobias_welle1.md` §4, §5.
- Empfehlung Tobias (Welle 1): T-15 bleibt (Kredit ab Minute 12, 3 %/min, Bankrottregel, 2,9 : 1). Ortsmodell muss die Nachfrage nachführen. Stichprobe auf der echten Welt (bis zu 21 Knoten) wiederholen; Hooks als Regressionstest nach `tests/`. Offen: Umsetzung (Entscheid S8). `tobias_welle1.md` §5.
- Raster der Senken-Einwohner: Mittelfurt-Kette wieder auf heutigem Niveau ab etwa 15–18/min (12–15 % Bankrott@30); Haberau-Kette braucht etwa 18/min (18,0 %; bei 15,4/min 22,7 %; bei 13/min 26,7 %). Die Zickzack-Form kommt vom Kassen-Auslöser des Hub-Kaufs. `tobias_welle1.md` §3.3.

## B9 Presets und Konkurrenz (Näherung, kein Lauf)
- Schätzung Bankrott@30 (aus Mindestkasse, gleiche Entscheidungen angenommen): Normal 6.000 $/3 % ≈ 16,9 % (mit Dorf-Senke 650 EW 20,9 %; mit ×1,5 15,2 %); Schwer 4.500 $/4 % ≈ 34,2 % (mit ×1,5 34,0 %); Leicht ≈ 0 % (auch 7.000 $/2 % nur 0,9 %). Steil: 500 $ Startkapital verschieben Normal von 16,9 % auf 1,1 %; Schwer 4.500 → 5.000 $ senkt 34,2 → 27,6 %. Folge: Preset-Preise in 500-$-Schritten messen. `tobias_welle1.md` §6.1–6.2, §6.3 (Annahmen).
- Konkurrenz: 15 % passiver Marktanteil ab Minute 45/35/20 (Leicht/Normal/Schwer) als reiner Nachfrageverlust (Platzhalter, `g01_progression.md` §3 und §6 Frage 5). Kleinstadt- und Stadt-Senken (≥ 24/min) verlieren nichts, Dorf-Senken 3–15 % Ertrag; wirkt auf Bankrott@60 und M7-Erreichung, nicht auf Bankrott@30, solange Konkurrenz nach Minute 30 greift. Ohne Gegenmittel steigt Bankrott@60 bei schwachen Haberau-Senken um 3–25 Punkte (Normal 41,3 %, Schwer 56,0 %). `tobias_welle1.md` §6.2.
- Konkurrenz-Hebel (Skizze): Anzahl 1/2/3, Start Min 45/35/20, Marktanteil-Deckel 10/15/20 %, Preiskampf nur Schwer, Übernahme nie gegen die Spielerfirma. Schutzregeln K39: KI belegt nie die letzte freie Quelle eines knappen Rohstoffs in 4 km um das HQ, vor Min 45 keine knappe Quelle, Bot-Check V-K1. KI-Firma = Bot aus `d08_bankrott` als Spielfigur (K38, Annahme). Es gibt noch keinen KI-Code. `phase3b/15_regelwerk_v1_1.md` §D, K36–K40.

## B10 Progression, Druckquellen, Zielzeiten
- Problem aus dem Tagebuch: alle 7 Slice-Ziele nach 12 min, danach 38 min dieselbe Handlung; Plateau ab ca. 20 min. Fernziele F1–F7 bis Minute 60 (u. a. F2 Netto ≥ 1.000 $/min, F5 = M7 mit 5.000 $/min Einnahmen, F7 Firmenwert ≥ 100.000 $ und Netto ≥ 2.500 $/min); Firmenwert = 60 % Investition + 12 × Monatsüberschuss. 6 Skillpunkte bis 60 min, 4 bis M7. Sechs offene Fragen an Tobias (Minuten, +8 % je Rang, Lizenz +10 %, Gleisunterhalt, KI-Anteil 15 %, F6-Exploits). `sprints/s7/block-b/g01_progression.md` §1, §4–§6. Davon ist laut den gelesenen Dateien keine kalibriert.
- Zug : Lkw ≤ 3 : 1 als Ziel (T-15 misst 2,9 : 1); der Gleisunterhalt je Feld ist als Hebel vorgesehen, Wert offen (`g01_progression.md` §3, Frage 4).

## B11 Bekannte Fallen und Widersprüche im Repo
- Repo-Drift seit T-15: Skriptspieler B 36,0 statt 30,4 min; `tools/play.sh` mit denselben Befehlen weicht ebenfalls ab (12.595 gegen 14.318 $ bei 31:54). Ursache nicht verfolgt, nicht die Ortsordnung. Absolutzeiten nur im Variantenvergleich lesen. `tobias_welle1.md` §3.4, §7 Punkt 4.
- Zwei Epochentabellen: `concept/lena.md` (Epochen I–V, Wechsel über 3 von 5 Meilensteinen) gegen `phase3b/15_regelwerk_v1_1.md` A2 (W1–W6 nach Kalender, K21). Die Ökonomie späterer Epochen (Nachfrage einer 100k-Stadt ist 5× die einer 20k-Stadt) ist laut Regelwerk „eigener Sprint (Tobias)“. `15_regelwerk_v1_1.md` A3.
- Skillpunkt-Quelle: `g01_progression.md` §4 („keine Transport-XP, nur Meilensteine“) gegen `concept/lena.md` (Ast-XP durch Tonnen-/Personen-km, 1.000 XP je Punkt). Ein Entscheid fehlt; die Ökonomie kann die Punktquote erst kalibrieren, wenn er fällt.
- Die Slice-Karte hat 8 Orte; die neue Ordnung 15–21 Knoten. Bot-Zahlen für Dorf-Senken sind eine Obergrenze des Schadens (Mensch wählt die Senke, Bot nicht). `tobias_welle1.md` §7 Punkt 1–2.
- n = 150 in Stufe 3 und 5 statt 300 (Maschine ausgelastet): Intervall ±6 Punkte, Aussagen stützen sich auf gepoolte Tabellen (n = 450, ±3). `tobias_welle1.md` §7 Punkt 8.
- Sim-Stufe MF → „kleinstadt“ (×1,0) folgt Regelwerk v1/v1.1; ändern ist eine Entscheidung, keine Korrektur.
- Fahrzeug-Easing ist nur Darstellung (K27), die Sim-Fahrzeit bleibt; „echte“ Fahrdynamik (Anfahrzeit, Steigungsabschlag) ist S8-Kandidat K3 und würde T-15 und die Bot-Quoten kippen. `15_regelwerk_v1_1.md` K27, `11_streitprotokoll.md` K3.
- Wasser: Floß (E15) ist Mechanik-Entscheid S8/S9; Tobias: Schiffe sind eine eigene Kette mit Kalibrierung (K34, F10). Heute nur Mühle als Wassermechanik.

## B12 Rechenbeispiel: warum Senken unter etwa 15 Nachfrage/min den Bot ruinieren [R aus Code]
Grundlage ist `slice/economy.gd:353–357` (`f_saett_promille`) und `:780–800` (Lieferung an eine Stadt): F_sätt wird je gelieferter Einheit berechnet, aus dem Anteil s = (bereits geliefert in dieser Periode + u) / Nachfrage, je Stadt und Warenkategorie, Zähler wird jede Periode zurückgesetzt. Bis s = 100 % zahlt jede Einheit voll, bis 150 % linear fallend auf 0,4, darüber 0,1 (also ein Sprung bei 150 % von 0,4 auf 0,1). Der Bot liefert nach Angebot der Stufe-1-Verarbeiter, 20 E/min (`tobias_welle1.md` §2.1). Annahmen: gleichmäßige Lieferung, nur ein Warenkorb, Lkw-Chunks von 10 vernachlässigt, Preis und Distanz gleich. Erlös-Anteil = Σ F_sätt über die gelieferten Einheiten / gelieferte Einheiten:

| Abnehmer (Sim-EW) | Nachfrage/min | 20 E/min liefern | 40 E/min liefern (2 Ketten oder Hub) |
|---|---|---|---|
| Kleinstadt 4.700 | 47 | 100 % | 100 % |
| Kleinstadt 2.400 | 24 | 100 % | 81 % |
| Marktflecken 1.900 (×1) | 19 | 100 % | 66 % |
| Dorf 900 (×2) | 18 | 99 % | 63 % |
| Dorf 780 (×2) | 16 | 96 % | 57 % |
| Dorf 650 (×2) | 13 | 86 % | 48 % |
| Marktflecken 1.200 (×1) | 12 | 81 % | 45 % |
| Dorf 400 (×2) | 8 | 56 % | 33 % |

Lesart: Die Zahlen decken sich qualitativ mit der Bot-Messung (Quote steigt unter 15/min, Marktflecken 1.200 EW ist schlechter als Dorf 900 EW). Das ist keine neue Messung, nur eine Plausibilitätsrechnung; Preis, Zeitfaktor und Kredit-Verhalten fehlen darin. Zwei Beobachtungen: (1) Jede Einheit über 100 % der Nachfrage verdient weniger, jede über 150 % fast nichts, ein zusätzlicher Lkw (Fixkosten 90 $ je Periode) ist dort reine Kostenseite. (2) Der Sprung von 0,4 auf 0,1 bei 150 % ist eine Unstetigkeit der Kurve; ob sie gewollt ist, steht in keiner gelesenen Datei (siehe Teil C). Der Bot hat dieses Verhalten ausgelöst, weil er die Lkw nach Angebot kauft.

---

# TEIL C: Eigene Lücken und Lernstand

## C1 Was ich jetzt kann (Konfidenz)
- Die Ertrags-, Nachfrage- und Sättigungsformeln des Slice im Kopf nachrechnen und auf Ortsbänder anwenden (hoch, [M]).
- Bankrottquoten mit Intervallen angeben und die Stichprobengröße für eine gewünschte Genauigkeit wählen (hoch, [R]).
- Den K18-Knick und das Nachfrage-Minimum begründen und die zwei Gegenmittel-Wege (k = 1,25/1,5, Mindestnachfrage 18/min) mit Messwerten vertreten (hoch, [M]).
- OpenTTD-Referenzwerte (Frachtbasis, Zeitfenster, Wachstumsintervalle, Preset-Zahlen) belegt zitieren (mittel bis hoch, Fan-Dokumentation).
- Sinks/Faucets und Machinations-Elemente auf Mega Tycoon anwenden (mittel, Theorie nur aus zwei Quellen).

## C2 Noch unsicher (Konfidenz niedrig bis mittel)
1. Bankrottregel in Referenzspielen: keine belegte Quelle (nur [~]). Auswirkung: Mega-Tycoon-Zwangsverkauf nach 10 min ist ohne Vergleich begründet. Konfidenz in einen Vergleich: niedrig.
2. Wachstum ökonomisch: Konstanten (180 bp usw.) „ungetestet“, im Slice nicht verdrahtet. Ob Variante B das Mittelspiel trägt, weiß ich nicht. Konfidenz: niedrig.
3. Throughput-Daten der Ketten 1820 (Mühle, Hütte, Meiler) ohne belastbare Quelle (Mahlleistung fehlt, Köhlerausbeute widersprüchlich). Mengen im Spiel sind Design, nicht Realdaten.
4. Presets: Normal/Schwer sind aus Daten geschätzt, keine Läufe. Leicht-Pfad mit Mensch statt Bot ist unbekannt (Mehr Geld, mehr Käufe).
5. Konkurrenzanteil 15 % und Startminuten 45/35/20 sind Platzhalter; kein Preiskampfmodell, keine Ortswahl durch die KI.
6. Die Welt mit 15–21 Knoten wurde nie mit dem Bot gespielt; Bot-Karte hat 8 Orte.
7. Epochenökonomie (später als W1): keine Messung, Nachfrageskalierung 100k-Stadt ungeklärt. Konfidenz: sehr niedrig.
8. Zeitfaktor-Parameter `f_zeit` (Spiel) habe ich nicht gegen Zahlen geprüft; nur die Formel ist bekannt (`economy_constants.json › ertrag.formel`, `economy_slice.json › zeitfaktor`).
9. Reddit-Erfahrungsberichte (z. B. „Wie balancieren OpenTTD-Spielende Kredit?“) fehlen vollständig.

## C3 Was ich künftig anders mache
- Vor jeder Preset-Aussage erst messen (500-$-Raster), dann schreiben.
- Jede Ökonomie-Änderung als gepaarten Bot-Lauf mit Kontrollkette und Intervall ausliefern.
- Genau eine Epochentabelle und einen Skillpunkt-Entscheid einfordern, bevor ich Mengen kalibriere.
- Quellen mit Fan-Dokumentation (TTDpatch, TTWiki) als „Originalspiel“ kennzeichnen, nicht als aktuelles OpenTTD.
- Die Bot-Kalibrierung ausweiten: Welt-Karte mit mehr Orten, Mensch-Verhalten (Senkenwahl) im Bot nachbilden.

## C4 Meine offenen Lernfragen (Kurzform, Details und Rangfolge in `LERNBERICHT.md`)
1. K18/Nachfragemonotonie: welche Variante (×1,5 für Marktflecken oder gleitender Übergang)? 2. Kredit/Zins/Bankrott an der Weltkarte statt Slice neu prüfen. 3. Wachstum ökonomisch messen (Konstanten ungetestet). 4. Presets im 500-$-Raster messen. 5. Konkurrenzmodell (Bot als Spielfigur) mit Messung statt Platzhalter. 6. Eine Epochen-Ökonomie. 7. Skillpunkt-Quelle (Meilenstein oder Ast-XP). 8. Wasser/Floß als Kette kalibrieren. 9. Unstetigkeit der Sättigungskurve bei 150 %. 10. Zeitfaktor-Parameter gegen Frachtarten prüfen.

## D. Lern-Routine (verbindlich, seit 2026-11-03)
**1. Wissenscheck** vor jeder fachlichen Antwort/Entscheidung: Steht sie hier mit Marke [K]/[V]/[R]? Ja: anwenden. Nein, oder nur [E]/[W]/niedrige Konfidenz: weiter mit 2.
**2. Recherche-Trigger** (einer genügt; laut sagen: "Wissenslücke: <Frage>, ich recherchiere"): a) Ich weiß es nicht oder rate. b) Derselbe Kompromiss/Workaround zum 2. Mal ("wieder X statt Y"). c) Eintrag unter Offene Lücken oder [E]/[W]/niedrig, und die Entscheidung hängt daran. d) Skill, Repo, Doku oder Messung widersprechen sich. e) Engine/Tool/Version neuer als der Skill-Stand. f) Basti korrigiert oder eine Entscheidung wird zurückgenommen. g) Teure oder unumkehrbare Entscheidung bei Konfidenz unter mittel. h) Derselbe Fix scheitert 2x.
Rollen-Trigger: Kennzahl nur aus Modell, nie gemessen; historische Preise/Daten ungeprüft; Sim-Ergebnis widerspricht Modell.
Erst prüfen statt recherchieren, wenn billig messbar (Test, Doku-grep, Mini-Versuch). Geschmack klärt Prototyp oder Basti, nicht das Web.
**3. Ablauf**: Frage in einem Satz; Primärquellen zuerst (Doku, Issues, Forum, Postmortems; Reddit blockiert, nicht umgehen); 2 unabhängige Quellen; wenn möglich Eigenversuch [V]; Ergebnis mit Quelle, Datum, Marke. Budget 15 min, mehr nur als Agent. Unbeantwortet: Lücke eintragen, Basti/Team fragen, nie raten.
**4. Insight aufnehmen**, wenn alle vier stimmen: wiederverwendbar (2x gebraucht oder über 1 h Aufwand), belegt, noch nicht drin, kein Tagesstand (der gehört in Repo-Doku). Sofort bei Basti-Korrektur, Fehler im Skill oder Engine-Falle mit Repro, sonst gesammelt zum Sprintende. Eine Zeile mit Marke, Datum, Quelle; Widerspruch ersetzt den alten Eintrag; geschlossene Lücke streichen; Skill bleibt ca. 10.000 Zeichen. Im Account nur per Vorschlagskarte an Basti.
**5. Kompromisslog**: jeden Kompromiss, Workaround, jedes "wusste ich nicht" mit Datum in `sprints/s8/fortbildung/mt-oekonomie/LERNLOG.md` zählen; Zähler 2 löst Trigger b aus; Auswertung in der Sprint-Retro.
