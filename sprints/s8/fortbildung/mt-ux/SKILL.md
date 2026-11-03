---
name: mt-ux
description: UX/UI-Wissen für Mega Tycoon (Aylin). Nutzen bei Schildern, Zoom-LOD, Declutter, Kontrast, Tooltips ohne Modal, Onboarding, Kamera und Eingabe, Skalierung, Controller, Epochen-UI und UX-Playtests; enthält Genre-Wissen, Repo-Stand und eigene Lücken.
---

# mt-ux: Game-UX-Wissen für Mega Tycoon

Stand 03.11.2026, Aylin nach der Fortbildung. Sprache Deutsch, knapp. Repo: `/home/claude/mega-tycoon` (nur gelesen).
Marker: **[K]** Konsens (mehrere unabhängige Quellen), **[S]** Streit (Quellen widersprechen sich oder Genre uneins), **[E]** Einzelmeinung oder Setzung, **[H]** Hypothese, nicht belegt (aus Gedächtnis oder eigene Rechnung), **[R]** aus dem Repo belegt (Dateiangabe). `Qnn` verweist auf das Quellenverzeichnis am Ende von Teil A.
Arbeitsregel: Zahl ohne Quelle oder Messung wird als [E] oder [H] geführt, nie als Fakt. Reddit war nicht lesbar (siehe Teil C), also fehlen Spielerstimmen von dort.

---
# TEIL A: Allgemeines Fachwissen

## A1 Grundheuristiken (gelten für jede Entscheidung)
- Nielsens 10 Heuristiken [K, Q10]. Für uns am wichtigsten: Sichtbarkeit des Systemstatus; Erkennen statt Erinnern (Info bleibt sichtbar); Flexibilität (Kürzel für Profis, ohne Anfänger zu stören); Fehlertexte in Klartext mit Lösung; Hilfe nur knapp und aufgabenbezogen.
- Visuelle Hierarchie [K, Q09]: etwa drei Größenstufen, höchstens zwei große Elemente, etwa 2 Primär- plus 2 Sekundärfarben, etwa 3 Kontrastbehandlungen; "wenn alles auffällt, fällt nichts auf". Squint-Test: Bild weichzeichnen (Spotify-Beispiel mit 5, 10, 20 px Blur) und prüfen, was als Erstes sichtbar bleibt. Der Test ist Schnellcheck, kein Beweis.
- Progressive Disclosure [K, Q08]: höchstens zwei Ebenen, drei und mehr führen zu Orientierungsverlust; Inhalt der Vorderebene aus Nutzungsdaten wählen; Wege zu Sekundärinfo klar beschriften.
- Reaktionszeit [K, Q13]: 0,1 s wirkt sofort; bis 1 s bleibt der Denkfluss, ab 1 s braucht es Fortschrittsanzeige; 10 s ist die Aufmerksamkeitsgrenze. D21 (Übergänge höchstens 150 ms) liegt im Rahmen von "sofort bis spürbar".
- Informationsbedarf vor Dekoration: Eine Zahl, die der Spieler sieht, muss gegen den Spielwert getestet sein (Retro S6, siehe B1).

## A2 Semantic Zoom und Level of Detail für Beschriftungen
- Semantic Zoom heißt: mit dem Maßstab ändert sich der **Inhalt**, nicht nur die Größe. Pad++ (1994): Namen erscheinen erst, wenn sie lesbar wären; zu kleine Objekte werden nicht gezeichnet; ruckartiges Zoomen desorientiert [Q06].
- Mehr Nähe bedeutet im Normalfall mehr Detail (Kartografie und Pad++). Unser Prototyp dreht das in der Nahstufe um (nur Name); das ist eine Setzung ohne Genrebeleg, siehe B2 und C.
- Studie ExplorViz [Q05]: 15 von 16 Teilnehmenden bevorzugten die Variante mit Semantic Zoom; 12 hielten sie für alltagstauglich; automatische Änderungen (Pakete öffnen und schließen) wirken störend, wenn sie unerwartet kommen. Empfehlung: sanfte Übergänge, abstimmbare Schwellen, Orientierungspunkte erhalten. **Einschränkung [E]:** 16 Studierende, keine Spiel-Domäne, keine numerischen Schwellen.
- Generalisierungsoperatoren der Kartografie [K, Q04]: Selektion (weglassen), Aggregation (viele Häuser werden "Siedlung"), Typifizierung (wenige Symbole stehen für viele), Dimensionsreduktion (Stadt wird Punkt), Überhöhung (Symbol größer als der Gegenstand), Verdrängung (Symbole auseinanderschieben), Verbesserung (Symbol ergänzen). Das entspricht unserem E1: Zeichen statt Maßstab.
- Töpfers Wurzelgesetz **[H, aus Gedächtnis, Töpfer und Pillewizer 1966; Q04 nennt den Namen, aber nicht die Formel]**: n_neu = n_alt · √(Maßstabszahl_alt / Maßstabszahl_neu). Faustregel: bei halbem Maßstab bleiben etwa 70 % der Objekte. Als Richtwert für Labelzahl je Zoomstufe brauchbar, nicht als Gesetz.
- Stabilität bei Zoom und Pan [Q01]: Ziel "Labels verschwinden nur, wenn kein Platz mehr da ist"; gemeinsamer Fade-Zustand je Label über Zoomstufen (`crossTileID`); Fade-in etwa 300 ms, Kollisionslauf etwa alle 150 ms (Beispielwerte der Mapbox-Architektur 2017, [E]). Neue Labels starten bei 0, wichtige erscheinen zuerst.
- Hysterese (Schwelle beim Hin- und Zurückschalten leicht versetzt) ist Standardtechnik gegen Flackern **[H, in Q01 nicht genannt]**. Ob 8 % reichen, ist unbelegt.
- Typischer Fehler: harte Stufenwechsel (Popping) plus Layout, das jeden Frame neu entscheidet, wer weichen muss. Gegenmittel: Priorität stabil halten, Ein- und Ausblenden über Alpha, Verschiebung gleiten statt springen **[H, abgeleitet aus Q01, Q05, Q06]**.

## A3 Label-Declutter
- Rangfolge nach Imhof (1962): wichtigste Orte zuerst, dann der Rest; jedes Label klar dem Objekt zuordenbar, keine Überlappung [K, Q03].
- Das Problem ist NP-schwer; greedy ist schnell, aber nicht optimal; lokale Optimierung und Simulated Annealing finden bessere Lösungen, kosten mehr; Zerlegung in unabhängige Konfliktgruppen ("Rivalen") spart Rechenzeit [Q03].
- Mapbox [Q01, Q02]: deterministischer Greedy nach Wichtigkeit; Rasterindex mit 30-px-Zellen (600 x 600 px ergibt 20 x 20); Punktlabels als Rechtecke; mehrere Ankerkandidaten werden der Reihe nach probiert, passt keiner, wird das Label ausgeblendet. Zahlen sind Mapbox-spezifisch [E].
- Übertrag aufs Spiel [E]: Orte nie ausblenden, Industrie und Nebensächliches weichen; HUD-Flächen und Zielpfeile sind feste Hindernisse; erst nach oben, dann nach unten ausweichen; Zeiger oder Linie zum Fußpunkt, damit die Zuordnung bleibt.
- Prüfen: (1) Stresstest mit dem Drei- bis Fünffachen der echten Knotenzahl; (2) Kamerapfad aufzeichnen und abspielen, Zahl der Sichtbarkeitswechsel je Sekunde zählen; (3) Test auf der echten Karte, nicht auf Platzhaltern (Retro S7, siehe B1).

## A4 Informationshierarchie in Management- und Aufbauspielen
- Anno 1800: so viel wie möglich auf dem Spielfeld statt in Menüs; Vorschau beim Platzieren (Reichweiten werden markiert, Effizienzverlust beim Platz über Bäumen sichtbar) ersetzt Tooltips. Kritik: Off-Map-Menüs für Produktion und Wirtschaft sind zu knapp, das Handelsmenü unintuitiv [S, Q32].
- Factorio [Q27, Q30]: Details erst bei Hover (progressive disclosure); "Spieler im Kontext halten" statt Ansichtswechsel; Tooltips mit kleiner Grafik plus einer Zahl. Gegenstimme im Forum: viele Zahlen können Neulinge abschrecken, Tooltips höher als der Bildschirm lassen sich nicht scrollen [E, Forenkommentare].
- Cities: Skylines hat 19 Info-Views, teils mit Tabs; sie erscheinen auch beim Öffnen des Baumenüs, damit man Standorte plant [Q48].
- Two Point Hospital: Overlays (grün = beliebt, weiß = unbeliebt), Zielreiter, Hover über die Kasse zeigt Einnahmen, Ausgaben, Gewinn [Q40].
- Mini Metro und Mini Motorways: Farbe immer mit Form gepaart, neutraler Hintergrund; Farbenblind-Modus von Anfang an und mit betroffenen Beta-Testenden verfeinert [K, Q31].
- Dorfromantik: Aufgaben stehen auf dem Spielfeld als "Wünsche" (Rehe wollen X Bäume), also lesbar ohne Menü [E, Q39].
- Transport Fever 3 (Vorschau, Sept. 2026): Radiuskreise für Gebäude mit Wirkungsbereich, farbcodierte Linien nach Effizienz, bei negativen Effekten wird gezeigt, welche Gebäude betroffen sind; zum Menü-Aufbau keine Details öffentlich [E, Q34, Q35].
- Genre-Konsens [K]: Zustand zuerst über Form und Farbe auf der Karte, Zahlen erst bei Hover oder im Panel; Overlays nur eines zugleich. Streitpunkt [S]: wie viel in Tooltips statt in Panels.

## A5 Tooltips und Warnungen ohne Modal
- Nielsen/Norman [K, Q07]: kurz halten; keine aufgabenkritische Information in Tooltips; Tastatur-Auslöser vorsehen (Fokus); nicht das verdecken, was sie beschreiben; gleiche Elemente gleich behandeln; ausreichend Kontrast. Keine Zahl für die Verzögerung genannt.
- WCAG 1.4.13 [K, Q14], übertragbar auf eigene Overlays: **dismissible** (ohne Mausbewegung schließbar, z. B. Esc), **hoverable** (Zeiger darf auf den Tooltip), **persistent** (bleibt, bis Hover endet oder geschlossen wird). Ausnahme: der Tooltip verdeckt nichts.
- Verzögerung [S]: 200 ms Öffnen, unter 150 ms öffnen versehentliche Hover, ab 250 ms wirkt es "kaputt"; 300 ms Aufwärmfenster, in dem der Nachbar sofort öffnet [E, Q25, ein Blog]. Windows Forms und Godot: 500 ms [K, Q24 lokal, Q26]. Richtwert für uns: 200 bis 300 ms plus Aufwärmfenster [H].
- Warnungen ohne Modal: Toast mit Ursache, Ort und einer Aktion; Fehlertexte erkennen, diagnostizieren, beheben [K, Q10 Heuristik 9]; Kanäle trennen und jedem einen Zweck geben, Sprechblasen nur wenn nötig, wer alle Texte überspringt, muss das Level trotzdem schaffen [Q29, Factorio].
- Typische Fehler: Tooltip als einzige Quelle für Regeln; Tooltip nur per Maus; Tooltip folgt dem Cursor und verdeckt das Ziel; Text länger als zwei Sätze; unterschiedliche Verzögerungen im selben Spiel.

## A6 Onboarding und FTUE bei komplexen Simulationen
- Game Accessibility Guidelines [K, Q20]: Basis = interaktive Tutorials; Mittelstufe = kontextuelle Hilfe und Erinnerung an Steuerung im Spiel; Basis = Spielgeschwindigkeit einstellbar.
- Factorio-Erkenntnisse [Q28, Q29, E]: das Tutorial soll das Spiel zeigen, nicht nur Handgriffe abfragen; eingeschränkte Aktionen lehren "das Tutorial lösen", nicht das Konzept; verstreute Infokanäle (Zielfenster, Chat, Sprechblase) erzeugen Rauschen; Level sollen aneinander anschließen; Ziele über die Forschung geben.
- Allgemeine Praxis [E, Q43, Mobile-Blog]: ein Konzept zugleich, nur relevante Bedienelemente zeigen, früher Erfolg, Überspringen und optionale Vertiefung, Abbruchstellen messen. **Keine belastbare Zielzahl** für Zeit bis zur ersten Aktion im Genre gefunden; der Blog nennt ausdrücklich keine. Eigene Zielwerte sind [E] und müssen aus eigenen Messungen kommen.
- Veteranenschalter ("Ich kenne das Genre") ist Praxis, aber nicht als Standard belegt [E].

## A7 Kamera- und Eingabekonventionen (Genre)
| Spiel | Verschieben | Drehen/Kippen | Zoom | Quelle |
|---|---|---|---|---|
| Cities: Skylines 2 | WASD | Q/E drehen, T/G kippen | R/F | Q46 |
| Transport Fever 2 | RMB ziehen, optional Kantenscrollen | Q/E drehen, R/F kippen, Mausrad gedrückt halten dreht und kippt | Rad, X und Y/Z | Q47 (Wiki-Angabe aus Forum) |
- Kantenscrollen [S]: viele wollen es abschalten (Fehlscrollen am Rand, Cursorfreiheit); Anno 1800 hatte die Abschaltung zunächst nicht, Ubisoft stellte sie später wieder her [Q44, Q45]. Mindestens einen Schalter anbieten [H, Tendenz K].
- Tasten frei belegbar ist Basisanforderung [K, Q20]. Alle UI-Funktionen mit demselben Eingabemittel wie das Spiel erreichbar [Q20].
- Ziel-Mindestgröße für Zeigerziele: 24 x 24 CSS-px oder Abstandsausnahme [Web-Norm, Q19]; Übertrag auf Spiel ist [H].
- Zoom zum Cursor, Zoom-Schrittweite und Kipp-Automatik: kein belegter Standard gefunden [H].

## A8 Controller-Vorbereitung
- Frostpunk (PS4) [Q37]: kein 1:1-Port; Menüs als Radial-Wheels mit Untermenüs, Gebäudekategorien als Tabs mit Schultertasten, Schnellmenü für Arbeiterzuweisung; These: Komplexität ist kein Problem, die Darbietung ist es.
- Crusader Kings Konsole [Q36]: Stick als virtuelle Maus verworfen, D-Pad frei für Navigation; "Fokus wechseln" zwischen offenen Elementen und Karte; Steuerung an Funktionen statt an viele Kontextbelegungen gebunden; Hinweise am Rand.
- Anno 1800 Konsole [Q33]: Radialmenüs mit begrenzbarer Eintragszahl, Auswahl bleibt bei Stick-Neutral, breiterer Cursor, Handelsrouten als Schrittfolge, Steuerungsübersicht im Pausenmenü, Tasten frei belegbar, Totzonen einstellbar.
- Steam Deck [Q22]: Glyphen müssen zum Eingabegerät passen (Steam Input API empfohlen), Texteingabe per Steam-API oder eigenem Controller-Eingabefeld, auch der Launcher muss mit Controller bedienbar sein.
- Godot-spezifisch **[H, aus Gedächtnis]**: Aktionen über InputMap statt fester `KEY_*`; `focus_mode` und Fokus-Nachbarn setzen; Tooltips und Hover brauchen einen Fokus-Äquivalent.
- Genre-Lage [S]: es gibt keinen Standard für Aufbau- und Strategiespiele auf Konsole (so die Entwickler in Q36); Ansätze reichen von Radial bis Fokuswechsel.

## A9 Skalierung, HiDPI, Textgrößen (Godot und Plattformen)
- Godot [K, Q23]: für Spiele `canvas_items` oder `viewport`; `expand` für mehrere Seitenverhältnisse; Basisgröße als "Designgröße" (Beispiele 1920 x 1080); `content_scale_factor` kann den Spielenden angeboten werden (Barrierefreiheit); Allow hiDPI an lassen; auf hochauflösenden Displays öffnen Fenster klein, Spiele starten oft im Vollbild; 3D wird von der Skalierung kaum berührt; Mipmaps für verkleinerte Texturen.
- **Eigenmessung [Q50], Godot 4.7.2, xvfb:** mit `canvas_items` und Basis 1600 x 900 liefern Fenster 1280 x 720 und 2560 x 1440 für `get_visible_rect().size` stets (1600, 900), während `Window.size` die echte Größe nennt. Folge: "Fensterhöhe / 900" über `get_visible_rect()` ergibt etwa 1,0, nicht einen Fensterfaktor. Verhalten bei Seitenverhältnissen ≠ 16:9 nicht sicher gemessen (Fensterwechsel kam verzögert an).
- Textgrößen [Q21, Q22], **Messdefinitionen unterscheiden sich:** Xbox XAG 101: Standardtext mindestens 18 px bei 1080p auf PC (36 px bei 4K), Konsole 26 px; Skalierung bis 200 %; Höhe gemessen als Unterlänge plus x-Höhe plus Oberlänge. Steam Deck: kleinstes Zeichen nie unter 9 px Höhe bei 1280 x 800, Empfehlung 12 px, Textgröße und Kontrast einstellbar. WCAG "großer Text" = 18 pt (etwa 24 px) oder 14 pt fett (etwa 18,5 px) [Q15].
- Schlussfolgerung [H]: eine verbindliche Messkonvention festlegen (Glyphenhöhe oder `font_size`), sonst sind die Werte nicht vergleichbar.
- Game Accessibility Guidelines [K, Q20]: lesbare Standardgröße (Basis), Schriftgröße einstellbar (fortgeschritten), Oberfläche skalierbar (Mittelstufe).

## A10 Kontrast und Farbenblindheit
- WCAG-Formel: (L1 + 0,05) / (L2 + 0,05) mit relativer Leuchtdichte; Verhältnis wird nicht gerundet [Q15]. Schwellen: Text 4,5:1 (AA), großer Text 3:1; AAA 7:1 und 4,5:1 groß [Q15, Q16]; Grafiken und Bedienelemente 3:1 gegen die Nachbarfarbe [Q17]; Farbe nie als einziger Träger [Q18].
- Begründung der Schwellen [Q16]: 4,5:1 entspricht etwa 20/40-Sehschärfe, 7:1 etwa 20/80; starker Leuchtdichtekontrast hilft auch bei Farbfehlsichtigkeit.
- Text auf wechselndem Grund [Q15]: gemessen wird gegen den tatsächlich gerenderten Untergrund; ein breiter Hof zählt als Hintergrund, ein schmaler Rand als Teil des Zeichens. Dünne Schriften wirken durch Antialiasing schwächer. Eine Platte unter dem Text macht den Kontrast vom Untergrund unabhängig.
- Das Problem verschiebt sich dadurch: Text gegen Platte ist leicht, **Platte gegen Umgebung** (SC 1.4.11, 3:1) ist die schwierige Messung [E, eigener Befund, siehe B3].
- Farbenblindheit: etwa 8 % der Männer, 0,5 % der Frauen [E, Q42]; zweiter Kanal (Form, Symbol, Muster, Helligkeit) Pflicht [K, Q18, Q20, Q31, Q42]; Helligkeitsunterschied ist der stärkste Zweitkanal; Blau/Orange hält, Rot/Grün fällt; Simulation laufend im Design, nicht nur zum Schluss; gezielte Einstellungen (umfärbbare Marker, Muster, Hochkontrast) schlagen reine Vollbildfilter [E, Q42].
- **WCAG-2-Formel ist umstritten [S, H]:** für dunklen Modus und dünne Schrift gilt sie als unpräzise; APCA (Entwurf für WCAG 3) rechnet anders. Beides ist aus dem Gedächtnis, nicht belegt, und bei uns nicht eingesetzt.

## A11 Playtest-Methodik und Metriken
- Qualitativ: etwa 5 Personen je Runde, mehrere kleine Runden statt einer großen; Formel Funde = N · (1 − (1 − L)^n) mit L ≈ 31 % (5 Personen ≈ 85 %, 3 ≈ 67 %); je verschiedene Nutzergruppe 3 bis 4 Personen [K, Q11]. Alter der Studie: 2000, Daten von 1993.
- Quantitativ: etwa 20 Personen je Design für halbwegs enge Konfidenzintervalle, etwa 4x teurer [Q12].
- Kennzahlen [K, Q12]: Erfolgsquote, Zeit je Aufgabe, Fehlerrate, Zufriedenheit; Verbesserung als geometrisches Mittel relativer Werte. Genre-Zusatz [E]: Fehlklicks, Zeit bis zur Ursache (unser A-04), Abbruchstellen.
- Games User Research [Q41, E]: Beobachtung (1 bis 2 Spielende je Beobachtenden), Think-aloud (kann Leistung verändern), Interviews (Aussage ≠ Verhalten), Umfragen (viele Teilnehmende nötig), Telemetrie (Balance), Expertenreview (billig, weniger überzeugend); wiederholt Teilnehmende sind voreingenommen. **Streit [S]:** Q41 rät davon ab, Reviews an Heuristiken auszurichten, Nielsen/Norman setzt genau darauf (Q10).
- Synthetische Personas (LLM) und Selbstauskunft sind kein Ersatz; unser eigener Panel-Durchlauf zählte ausdrücklich nicht (B10).
- Expertentest ≠ Nutzertest: Ist die testende Person selbst UX-Fachkraft und Auftraggeber, ist das ein Expertenreview und der Fund-Anteil pro Person lässt sich nicht auf Neulinge übertragen **[H]**.

## A12 Epochen- und Themen-UI
- Es gibt zu "UI wechselt je Epoche" kaum belastbare Quellen; die Suche ergab nur Forenmeinungen (Age of Empires, Humankind) **[H, Lücke]**. Arbeitsprinzip [E]: Chrome der UI (Platten, Schrift, Statusformen) bleibt epochenstabil; Inhalte (Güter, Fahrzeuge, Ortsklassen, Zahlenbereiche) wechseln per Daten; Zeitbezug über Icons und Texte, nicht über andere Bedienlogik.
- Prüffrage je Epoche: Passen Klassenschwellen, Zahlenformat (Tausenderpunkt, sechsstellige EW), Icon-Anzahl je Schild und Tooltip-Texte noch?

## A13 Typische Fehler (aus Quellen und eigener Praxis)
1. Nur Farbe als Träger; nur Hover als Weg; Tooltip als Regelquelle.
2. Tests auf Platzhaltern, Produktivstand anders (Retro S6 und S7).
3. Zahlen auf dem Schirm, die das Spiel nicht kennt (B-1, Retro S6).
4. Stille Fehlschläge (Tagebuch Aylin S6).
5. Layout, das pro Frame neu entscheidet (Flackern), kein Fade.
6. Schwellen in Metern ohne Bezug zu Bildschirmdichte und Labelzahl.
7. Textgrößen ohne Messkonvention; Mindestwerte nur bei einer Auflösung geprüft.
8. Dev-Schalter und Entwickler-Hinweise im Spielermenü.
9. Esc bricht still eine Szene ab, ohne Rückweg.
10. Nur ein Rechner, nur ein Tester, Auftraggeber als einziger Proband.

## A14 Checklisten
**Schild und Overlay:** Zeichen gegen echten Untergrund (alle Bodenklassen) gemessen; Schild-gegen-Umgebung ≥ 3:1; zweiter Kanal für jede Farbe; Stufenwechsel mit Hysterese und Fade; Labelzahl und Priorität für 3x Knoten getestet; Mindestschrift nach Messkonvention; HUD-Flächen ausgenommen; Weiter-weg-Regel (was verschwindet wann) in Daten, nicht im Code.
**Tooltip:** Verzögerung 200 bis 300 ms mit Aufwärmfenster; Esc schließt; Zeiger darf hinein; Fokus-Weg; höchstens zwei Sätze je Absatz; keine Pflichtinfo.
**Barrierefreiheit:** Text ≥ 4,5:1 (wir fordern 7:1), Grafik ≥ 3:1, Form plus Farbe, Skalierung bis 200 %, Tasten belegbar, Kantenscrollen abschaltbar, Simulation Deuteranopie und Protanopie dokumentiert.
**Playtest:** Aufgabe, Messgröße, Abbruchkriterium vorab; Zeit, Fehlklicks, Abbrüche notieren; Beobachtung statt Nachfrage; Ergebnis als "Expertenreview" oder "Nutzertest" kennzeichnen; n offen legen.

## A15 Quellenverzeichnis (gelesen am 03.11.2026; Tiefe in Klammern: voll, dünn, nur Abstract)
Q01 Mapbox GL native, Collision Detection (voll): https://github.com/mapbox/mapbox-gl-native/wiki/Collision-Detection
Q02 Mapbox, Label-Platzierung optimieren (voll, ohne Zahlen): https://docs.mapbox.com/help/dive-deeper/optimize-map-label-placement.md
Q03 Wikipedia, Automatic label placement (voll): https://en.wikipedia.org/wiki/Automatic_label_placement
Q04 Wikipedia, Cartographic generalization (voll, ohne Formel): https://en.wikipedia.org/wiki/Cartographic_generalization
Q05 arXiv 2510.00003, Semantic Zoom und Mini-Maps (voll): https://arxiv.org/pdf/2510.00003
Q06 Pad++ (CHI 1994) (voll): https://www.cs.umd.edu/projects/hcil/jazz/learn/papers/chi-94-pad.pdf
Q07 NN/g, Tooltip Guidelines: https://www.nngroup.com/articles/tooltip-guidelines/
Q08 NN/g, Progressive Disclosure: https://www.nngroup.com/articles/progressive-disclosure/
Q09 NN/g, Visual Hierarchy: https://www.nngroup.com/articles/visual-hierarchy-ux-definition/
Q10 NN/g, 10 Usability Heuristics: https://www.nngroup.com/articles/ten-usability-heuristics/
Q11 NN/g, Why You Only Need to Test with 5 Users: https://www.nngroup.com/articles/why-you-only-need-to-test-with-5-users/
Q12 NN/g, Usability Metrics: https://www.nngroup.com/articles/usability-metrics/
Q13 NN/g, Response Times, 3 Important Limits: https://www.nngroup.com/articles/response-times-3-important-limits/
Q14 W3C WCAG 2.2, 1.4.13 Content on Hover or Focus: https://www.w3.org/WAI/WCAG22/Understanding/content-on-hover-or-focus
Q15 W3C WCAG 2.2, 1.4.3 Contrast (Minimum): https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html
Q16 W3C WCAG 2.2, 1.4.6 Contrast (Enhanced): https://www.w3.org/WAI/WCAG22/Understanding/contrast-enhanced.html
Q17 W3C WCAG 2.2, 1.4.11 Non-text Contrast: https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html
Q18 W3C WCAG 2.2, 1.4.1 Use of Color: https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html
Q19 W3C WCAG 2.2, 2.5.8 Target Size (Minimum): https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html
Q20 Game Accessibility Guidelines, Full list: https://gameaccessibilityguidelines.com/full-list/
Q21 Microsoft, Xbox Accessibility Guideline 101 (Text): https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/101
Q22 Steamworks, Steam Deck Compatibility: https://partner.steamgames.com/doc/steamdeck/compat
Q23 Godot Docs, Multiple resolutions (aus der Quelldatei gelesen): https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html
Q24 Godot 4.7.2 Klassendoku lokal (tooltip_delay_sec = 0,5): /tmp/claude-0/gd/doc472/doc/classes/ProjectSettings.xml
Q25 master.dev, Tooltips Need a Delay (Blog, Einzelquelle): https://blog.master.dev/tooltips-need-a-delay-and-then-they-need-to-skip-it/
Q26 Microsoft, ToolTip.AutomaticDelay (500 ms): https://learn.microsoft.com/en-us/dotnet/api/system.windows.forms.tooltip.automaticdelay?view=net-9.0
Q27 Factorio FFF-423, Forschungs-Tooltip und Spieler-GUI: https://direct.factorio.com/blog/post/fff-423
Q28 Factorio FFF-241, New player experience: https://factorio.com/blog/post/fff-241
Q29 Factorio FFF-342, The new old tutorial: https://direct.factorio.com/blog/post/fff-342
Q30 Factorio Forum zu FFF-318 New Tooltips (nur Forenkommentare, dünn): https://forums.factorio.com/viewtopic.php?p=463205
Q31 Game Developer, Mini Motorways und Minimalismus: https://gamedeveloper.com/audio/-i-mini-motorways-i-and-the-delicate-art-of-marrying-complexity-and-minimalism
Q32 PC Gamer, Anno 1800 Interface: https://www.pcgamer.com/anno-1800s-clean-easy-to-use-interface-masks-a-fiendishly-compulsive-city-builder
Q33 Ubisoft, Anno 1800 Console Accessibility (2023): https://news.ubisoft.com/en-us/article/6xDLQxuay1FASfTGQyquJl/anno-1800-console-edition-accessibility-spotlight
Q34 But Why Tho, Transport Fever 3 Hands-on (Sept. 2026): https://butwhytho.net/2026/09/final-preview-transport-fever-3-hands-on/
Q35 Loot Level Chill, Transport Fever 3 Video (dünn, ohne UI-Details): https://lootlevelchill.com/news/transport-fever-3-new-video-showcases-tycoon-gameplay-improved-ui-and-more/
Q36 Paradox, CK Konsole Dev Diary 3, UI/UX und Steuerung: https://admin-forum.paradoxplaza.com/forum/developer-diary/console-dd-3-ui-ux-and-controls.1516699/page-2
Q37 PlayStation Blog, Frostpunk Konsole: https://blog.playstation.com/?p=217487
Q38 Game Developer, Game UI Database 2.0 (über 55.000 Screens, 1.700 Videos, 1.341 Titel, Aug. 2024): https://gamedeveloper.com/design/game-ui-database-relaunches-with-new-features-video-support-and-over-55-000-screenshots
Q39 Game Developer, Dorfromantik-Interview (2021): https://www.gamedeveloper.com/disciplines/sparking-joy-through-tile-placement-in-idyllic-village-builder-i-dorfromantik-i-
Q40 Magic Game World, Two Point Hospital UI: https://www.magicgameworld.com/two-point-hospital-ui-and-reading-your-menus/
Q41 Games User Research, Methoden: https://gamesuserresearch.com/games-user-research-methods/
Q42 Bugnet, Colorblind-friendly game design (Blog): https://bugnet.io/blog/colorblind-friendly-game-design
Q43 Adrian Crook, Mobile-Onboarding (Mobile, nur Teilübertrag): https://adriancrook.com/best-practices-for-mobile-game-onboarding/
Q44 Age of Empires Forum, Kantenscrollen abschaltbar: https://forums.ageofempires.com/t/edge-of-screen-scrolling-should-have-the-option-of-being-disabled/131093
Q45 Anno-Devtracker, Kantenscrollen: https://devtrackers.gg/anno-1800/p/d6128f85-disable-edge-scrolling
Q46 Shacknews, Cities: Skylines 2 Steuerung: https://shacknews.com/article/137454/pc-buttons-controls-cities-skylines-2?amphtml=1
Q47 Steam-Forum, Transport Fever 2 Kamera: https://steamcommunity.com/app/1066780/discussions/0/3195867945631429086
Q48 Beyond Sims, Cities: Skylines Dev Diary 9 Info Views (Auszug): https://beyondsims.com/2015/02/skylines-dev-diary-9-info-views/
Q49 GDC Europe 2015, Cities: Skylines Case Study (nur Abstract, Vortrag nur für Mitglieder): https://gdcvault.com/play/1022809/Cities-Skylines-A-Case
Q50 Eigenmessung, Godot 4.7.2, Stretch und `get_visible_rect` (Testprojekt im Scratchpad, nicht im Repo)
Game UI Database (Q38) ist ein Bildarchiv; Schriftgrößen und Icons lassen sich dort vergleichen, ich habe sie hier nicht ausgewertet.

---
# TEIL B: Wissen für Mega Tycoon (nur Belegtes, mit Datei)

## B1 Leitlinien und Entscheidungen
- **D15** Genre-Standards übernehmen (TF2, Railway Empire, OpenTTD), Arbeit in unsere Unterschiede; **D16** Basti testet selbst, keine externen Tester; **D21** UI mit Liebe: Theme, angedockte Panels, Übergänge höchstens 150 ms, Klick-Sounds, keine grauen Modale; **D22** HQ frei platzieren, kein Dialog. Quelle: `sprints/s5/brief_day1-5.md`, `sprints/s6/refinement/brief.md`.
- UI-Kit: Hover 100 ms, Slide 150 ms, Klick-Sound: `slice/ui/ui_fx.gd`. Statusformen: Kreis = ok, Dreieck = warn, Quadrat = bad, jeweils mit dunklem Saum `#0F1720`: `slice/ui/status_shape.gd`. Statusfarben `#48E08A`, `#FFA640`, `#FF988A`: `slice/ui/theme/theme_builder.gd`. Typo-Stufen 32/24/18/14: dort.
- Fehlertexte: Ursache + Lösung, höchstens 90 Zeichen, Du-Form, kein Jargon, nie stumm; Bau-Fälle zusätzlich rot in der Vorschau: `sprints/s7/block-a/fehlertexte.md`. Ghost: weiß = baubar, rot schraffiert = nicht baubar, Kosten als eigener Kanal: `design/ux/day4-6/a06_bau_ux_vorgaben.md`.
- Konzept "lesbare Komplexität": jede Warnung mit Ort, Ursache, Vorschlag; Zustand vor Zahl; Gültigkeit und Kosten getrennt; die Karte ist das Interface; Label-LOD weit/mittel/nah; Epochenwechsel als Kamerafahrt plus Drei-Spalten-Liste (Neu, Modernisiert, Rückläufig): `concept/aylin.md`.
- Retro-Regeln: jede sichtbare Zahl mit Test gegen den Spielwert (`sprints/s6/review_retro.md`); Tests auf der echten Karte (`sprints/s7/review_retro.md`).
- Weltregeln mit UI-Folge: E1 "nichts überzeichnet, Lesbarkeit über Zeichen", E7 Orte bleiben ohne Versorgung stabil, E8 Partie bis heute, E4/E12 Startjahr und Zeittempo wählbar: `sprints/s8/design-sprint/charter.md`. Label-Hierarchie im Regelwerk: Kleinstadt und Marktflecken immer, Dorf unter 3.000 m Kamera, Weiler nie: `sprints/s8/design-sprint/phase3b/12_regelwerk_v1_1.json`, Block `label`.

## B2 Schilder-Spezifikation (Prototyp Welt, Stand Code Commit 754bb14)
Quellen: `slice/proto/proto_schilder.gd`, `slice/proto/proto_schilder_daten.json`, `sprints/s8/design-sprint/phase4/aylin_welle2.md`, `fixpass_w2.md`.
| Stufe | Kameraabstand zum Ort | Inhalt |
|---|---|---|
| Fern | ab 1.500 m | Klassen-Symbol + Name |
| Voll | 400 bis 1.500 m | Zeile 1 Symbol + Name; Zeile 2 Person + Einwohner, Trendpfeil, bis 3 Bedarf-Icons mit Statusform |
| Nah | unter 400 m | nur Name, Deckung 92 % |
- Hysterese 8 % (`HYSTERESE`); Vollschild-Faktor 1,12 bei 400 m bis 0,92 bei 1.500 m (`voll_faktor`). Stufenwechsel sind **harte Wechsel** (kein Cross-Fade im Code); Alpha nur 1,0 oder 0,92, und 0 wenn nicht sichtbar.
- Größen bei 900 px Höhe (px): Kleinstadt Name 21, Zahl 15, Icon 22; Dorf 16, 14, 18; Fern Dorf Name 14, Symbol 22; Weiler 13; Industrie Name 14. Mindestschrift 12 px (`MIN_FONT_PX`), Skalierung `clamp(vp.y / 900, 0,85, 1,5)`. Alles aus `KLASSEN` in `proto_schilder.gd`.
- Hierarchie: Prio Kleinstadt/Marktflecken 0, Dorf 1, Industrie 2, Weiler 3. Orte werden nie ausgeblendet; Industrie und Weiler weichen, wenn nach höchstens 8 Schritten à 12 px kein Platz ist. Reihenfolge der Entzerrung nach Prio, erst nach oben, dann nach unten; Rahmen mit 8 px Rand in den Viewport geklemmt; HUD-Panel wird automatisch als Sperrfläche erkannt.
- **Weiler: kein Schild.** `WEILER_NAH_BIS_M := 0.0` (Fix-Pass M8, `fixpass_w2.md`). Die frühere Fassung "Name bis 500 m" steht noch in `aylin_welle2.md` und `integration_w2.md` und ist überholt.
- Ankerhöhe über Gelände laut Code: Kleinstadt 24 m, Marktflecken 20 m, Dorf 14 m, Industrie 12 m. `aylin_welle2.md` nennt noch 18 m und 40 m (vor Fix-Pass M3). Fußpunkt am Marktplatz (Kleinstadt) oder an der Kirche (Dorf), Zeiger mit Fußlinie und Ring.
- Sichtlinie Kamera bis Anker in 20 Proben gegen `hoehe_at`; bei Verdeckung Anker stufenweise bis 150 m angehoben (Test mit künstlichem Wall: +15 m).
- Tooltip "Einzugsgebiet": nach 0,12 s Hover (`_hover_t > 0.12`), unter dem Schild, kein Klick, verschwindet bei gedrückter Maustaste; Maus nur. Nicht hoverbar, kein Esc, kein Tastaturweg (so in `aylin_welle2.md` §8). Du-Form, kurze Sätze; Lindenfurt markiert die Gesamtzahl 2.950 als Annahme.
- Bedarf-Icons: Dorf und Kleinstadt kaufen die Kategorie Nahrung (Mehl, ersatzweise Fleisch, Zeichen "/"); Statusform neben dem Icon: Kreis gedeckt, Dreieck wird gebraucht, Quadrat fehlt. Beispielstatus ist fest (Prototyp ohne Wirtschaftsanbindung).
- Industrie-Plakette: runde Scheibe in Typfarbe mit Saum `#0F1720`, Name in Typfarbe auf der Platte, Gebäude bleiben neutral (Bastis Rückmeldung, `sprints/s7/basti_feedback_01-11.md` Punkt 5); 22 bis 34 px, bleibt unter 400 m sichtbar.
- Erscheinungsbild: Platte `#191714` mit 88 % Deckung, Rand creme 1,5 px, Schrift Poppins, Eckenradius 6 px.
- Overlay ist 2D (CanvasLayer 0 unter HUD-Layer 1): kein Tiefentest, deshalb Gelände-Anhebung; Gebäude verdecken Schilder nie. Begründung: S7-Label3D rutschten (Daniel D-09 H1) und FOV-Korrektur nötig (`slice/main.gd` `label_kscale`).
- Hooks: `ProtoSchilder.bauen(parent, kamera, orte, terrain)`, `setze_trend`, `setze_ew`, `setze_bedarf`, `setze_sichtbar`, `meiden`. Taste N schaltet die Schilder (`slice/proto/prototyp_welt.gd`).
- Messungen: 51 von 51 Prüfungen grün; Layout 0,60 ms je Frame bei bewegter, 0,06 ms bei ruhiger Kamera (headless, geteilte Maschine); 0 Überlappungen in 5 Presets **mit nur 3 Orten und 2 Plaketten**; Übersicht 133.000 Dreiecke und 110 Draw Calls mit Schildern.
- Slice (anderes System): Label-LOD nach Zoom (fern über 9, mittel 3,5 bis 9, nah bis 3,5; Nah zeigt dort **mehr** Text wie Bestand und Lizenz): `slice/main.gd` `_update_label_lod`; Industrie in S7 über Plaketten (`slice/world/industry_markers.gd`: 34 px ab 1,5 km, 22 px bis 600 m, unter 400 m aus).

## B3 Kontrastwerte
Formel WCAG 2.x wie `industry_markers.contrast`; Gates: Text ≥ 7:1, Grafik ≥ 3:1 (`aylin_welle2.md` §4). Rohdaten: `sprints/s8/design-sprint/phase4/aylin_kontrast_*.csv`.
| Prüfung | Minimum | Wo |
|---|---|---|
| Schildtext auf Platte (analytisch) | **11,59** (Spanne 11,59 bis 14,79) | über Schnee |
| Industrie-Name (Gelb/Hell) auf Platte | 7,94 | über Schnee |
| Statusfarben auf Platte | 6,21 | über Schnee |
| Platte oder Rand gegen Untergrund | 3,73 | Acker dunkel |
| Industrie-Scheibe gegen Untergrund | 3,38 | Waldboden |
| Im gerenderten Bild: Text gegen Platte | 9,33 | Gut Kuppenhof, Fern |
| Im Bild: Platte gegen Umgebung | **2,95** | Erlenbach, Fern (unter 3:1) |
| Im Bild: Schild gegen Umgebung (Rand zählt) | 3,26 | Erlenbach, Fern |
- Die 11,59 sind das Minimum aus 15 Untergründen bei 88 % Plattendeckung (Platte wird über den Untergrund gerechnet). Eigene Nachrechnung [H, Python, identische Formel]: über Schnee ergibt 88 % → 11,59; 70 % → 6,29; 50 % → 3,32. Für 7:1 braucht es etwa ≥ 73 % Deckung, für 4,5:1 etwa ≥ 60 %. Die 88 % tragen den Kontrast.
- Offene Entscheidung (Aylin): Platte auf 94 % oder Rand auf 2 px. Wasser gegen Ufer: 1,1 bis 3,0:1 Leuchtdichte, alle 14 Paare unter 3:1; G3 gilt nur über den Ufersaum im Shader (Art Director und Daniel entscheiden die Messmethode).
- Farbcheck der Palette: ΔE2000-Grenze 10 mit Daniels Skript, aber nicht mit Menschen mit Farbfehlsichtigkeit geprüft: `design/art/day4-6/s05_palette_v1_final.md`. Status-Paare in allen Modi ≥ 10; Gelände ohne Bedeutung, 17 bekannte Kollisionen.

## B4 Kamera, Eingabe, HUD
- Prototyp (`slice/proto/prototyp_welt.gd`): WASD/Pfeile verschieben (0,8 · Abstand je Sekunde), Q/E drehen (1,5 rad/s), Mausrad Zoom mit Faktor 0,88 je Raste, **linke Taste ziehen = schieben, rechte oder mittlere ziehen = drehen**, Presets 1 bis 5, Abstand 40 m bis 3.000 m, FOV 50°, Neigung 36° nah bis 62° fern automatisch (`pitch_for`), kein Kippen per Taste, kein Zoom zum Cursor, kein Kantenscrollen, nichts belegbar. F folgt Fahrzeug, T Tempo ¼×, G Easing, M Modelle aus, N Schilder, V Wasser A/B, H Hilfe-HUD, F11 oder Alt+Enter Vollbild, Esc zurück ins Startmenü.
- Slice (`slice/main.gd`): WASD verschieben, Q/E drehen, Rad Zoom Faktor 0,9 / 1,1, Zoombereich 0,4 bis 26; **linke Taste wählt oder baut, rechte Taste bricht ab**, kein Maus-Schieben, keine Maus-Drehung; 1 bis 5 sind Werkzeuge (Straße, Gleis, Lager, Lkw-Linie, Zug-Linie), X Abriss, Leertaste oder P Pause. Hinweisleiste: "Klick auf Gebäude: Infos und Lizenz · WASD bewegen · Q/E drehen · Mausrad zoomen · Leertaste Pause".
- S7-Welt: Kamera 40 m bis 5,6 km, FOV 50: `slice/world/welt.gd`.
- Prototyp-HUD: ein dunkles Feld oben links (12 px Abstand, 15 px Schrift, 72 % Deckung) mit Ansicht, Abstand, **einer Zeile mit allen Tastenbelegungen**, Sim-Zustand, Zählwerte; H blendet es aus. Kein kontextuelles Hinweissystem im Code.
- Vollbild: `Window.MODE_FULLSCREEN` umschalten, keine Speicherung; Stretch `canvas_items`, Aspect `expand`, Basis 1600 x 900: `slice/project.godot` Abschnitt `display`. Commit 754bb14 (03.11.2026).

## B5 Startmenü und Weltumschalter
- `slice/start_menu.gd`: zwei Karten ("Neues Spiel", "Beispielnetz ansehen"), Tasten 1/2/Enter/Leertaste/Pfeile/Tab, **W wechselt die Welt slice ↔ s7**, P startet den Prototyp (nicht als Karte). Karten haben `FOCUS_NONE`. Unterzeile zeigt Entwicklertext ("Start mit Argument -- --welt=s7 wählt S7 vor · P Prototyp Welt"). Kein Optionen-, Laden- oder Beenden-Eintrag.
- Speichern/Laden existiert noch nicht (`sprints/s7/abnahme/daniel_d09.md` §4 Punkt 11).

## B6 Epochen
- Regelwerk-Epochen W1 (1820 bis 1849, Postkutsche, Chaussee, Mühlen) bis W6 (ab 2000); Startjahr wählbar, Standard 1820; es gibt **keinen Codepfad je Jahr**, nur Daten (`slice/proto/proto_epochen.gd`, Test `proto_epochen_test`).
- Einwohnerbänder je Startjahr (`12_regelwerk_v1_1.json`, `startjahr_hebel`): 1820 Dorf 150 bis 350, Marktflecken 800 bis 1.300, Kleinstadt 2.000 bis 4.000; 2000 Dorf 400 bis 2.000, Kleinstadt 10.000 bis 30.000, Stadt 30.000 bis 100.000 (ab 1860 erste Stadt). Epochenwechsel-UI ist nur Konzept (`concept/aylin.md`, `plan/aylin.md`), nicht gebaut.
- Schilder kennen nur Klassen kleinstadt, marktflecken, dorf, weiler, industrie; unbekannte Klasse fällt auf "dorf" zurück (`_neuer_ort` in `proto_schilder.gd`). Eine Klasse "Stadt" gibt es nicht.

## B7 Genre-Referenzen im Repo
- Railway Empire: Übersicht mit feinen Linien, Städte als dichte Cluster mit Namen, Lesbarkeit über Icon + Name + Felder; Bilder in `design/art/referenz/`; Notizen `sprints/s8/design-sprint/referenzen.md`.
- Transport Fever 3 (Bastis Referenzbilder tf3_01 bis 09): Schilder mit Name, Einwohner, Trend, Bedarf über Ortsclustern, bestätigt im Streitprotokoll K20 (`phase3/11_streitprotokoll.md`).
- Kontextdialog-Feldliste mit Referenz je Zeile (TF2, OpenTTD, Anno, Cities: Skylines): `sprints/s3/day4-7/aylin/a07_kontextdialog.md`. D22 nach Civ-Siedler: `sprints/s6/refinement/ux_art.md`.

## B8 Bekannte Stolpersteine (alle mit Datei)
1. Schild-Skalierung: Doku sagt "Fensterhöhe / 900", Code nutzt `get_visible_rect()` und `canvas_items`; nach Eigenmessung etwa 1,0 bei 16:9 [Q50]. Getestet nur bei 1600 x 900 (`aylin_welle2.md` §8 "Nicht getestet").
2. Dorf-Regel "unter 3 km" ist im Prototyp wirkungslos (Kamera bis 3.000 m). Sie greift erst auf der großen Karte; dort ist die Entzerrung nicht getestet.
3. Entzerrung getestet mit 3 Orten und 2 Plaketten; S7 hat 12 Städte und 21 Industrien (`daniel_d09.md`).
4. Frühere Fehler: Stadtnamen 100 bis 350 px neben der Stadt (D-09 H1), Zielpfeil vs. Label (B-6), Label unter HUD (D-07 BUG-4, `sprints/s5/day11/mira.md`).
5. Zwei Label-Systeme (Slice und Prototyp) mit gegensätzlicher Nah-Logik (B2).
6. Tooltip nach 0,12 s, Godot-Standard und Windows 500 ms (A5); Tooltip nur mit Maus.
7. Fleisch-Icon bei 18 px knapp erkennbar (`aylin_welle2.md` §7 Punkt 11); Erkennbarkeit nur von der Autorin beurteilt.
8. Tagebuch Aylin S6: stille Fehlschläge, "Monat" ohne Spielzeit-Einheit, Hinweis "oben links" bei Knöpfen rechts, veralteter "Nächster Schritt" (`sprints/s6/zocken/tagebuch_aylin.md`); behoben über U-03 in S7.
9. Weiler-Entscheidung hängt an PO: `WEILER_NAH_BIS_M` = 500 schaltet den Namen wieder an (`fixpass_w2.md` Offen 6).
10. Welt-Mauer: Platte 2,95:1 gegen helle Umgebung, Entscheidung offen (B3).

## B9 Eingaben und Pausen im Spiel (Kurzfassung)
Leertaste oder P Pause; Tempo über Knöpfe; Esc bricht im Slice das aktuelle Werkzeug oder Panel; im Prototyp verlässt Esc die Szene sofort. Hotkeys im Werkzeug-Tooltip als "[1] Name": `slice/main.gd` (Zeile um 1533).

## B10 Playtest-Realität
- D16: Basti testet allein, daher Aufgabenkarten statt Moderation (`sprints/s4/refinement/aylin_sophie.md`, `sprints/s8/design-sprint/phase4/aufgabenkarten_v1_1.md`: 11 Karten, etwa 25 min, Rückmeldebogen Note 1 bis 5 und Minuten, Daniel protokolliert, Aylin beobachtet).
- Erster Diagnose-Test S2: 0 echte Tester; ein synthetisches Panel (6 LLM-Personas, nur Text plus ein Screenshot) "zählt nicht für G1" (`sprints/s2/day7-10/panel/auswertung.md`, `gate/review_s2.md`).
- Plan-Ziele ohne Messung: 5 von 6 finden Ursache, 80 % unter 60 s, Zeit je Meilenstein (`plan/aylin.md`); Messgrößen im Rundgang: Zeit je Karte, Screenshots, Stichworte. Zeit bis zur ersten Aktion, Fehlklicks und Fehlerraten sind für den Prototyp nicht definiert.

---
# TEIL C: Eigene Lücken und Lernstand

## C1 Lernfragen (priorisiert) und Stand nach der Fortbildung
| # | Lernfrage | Vorher unsicher weil | Jetzt gelernt | Weiter unsicher | Konfidenz |
|---|---|---|---|---|---|
| 1 | Schilder bei Zoomwechsel: Stufen 1.500/400 m, Hysterese 8 %, harte Wechsel | Werte waren Setzung nach Lesbarkeit | Semantic Zoom heißt mehr Detail bei Nähe; Übergänge weich; Stabilität über Fade und gemeinsamen Zustand (Q01, Q05, Q06) | Ob "Nah = nur Name" bei Basti trägt; ob 8 % reichen; Schwellen in Meter oder Pixel | mittel |
| 2 | Declutter und Labelzahl auf der großen Karte | Test mit 5 Objekten | Priorität, Greedy, Rivalengruppen, Stresstest, Kamerapfad-Replay (Q01, Q03) | Verhalten bei 15 bis 21 Orten und 21 Industrien; Flackerzahl | mittel |
| 3 | Kontrast: was bedeutet 11,6:1 | Zahl wirkte beruhigend | Sie misst Text gegen Platte bei 88 %; der Engpass ist Schild gegen Umgebung (2,95 bis 3,26) und die Deckung (≥ 73 % für 7:1) | Welche Messmethode am gerenderten Bild verbindlich ist; Wasser (G3) | hoch (Rechnung), mittel (Maßstab) |
| 4 | Tooltips ohne Modal | 0,12 s Verzögerung gesetzt, Maus-only | 200 bis 300 ms plus Aufwärmfenster, Esc, hoverbar, Fokus-Weg (Q07, Q14, Q25); Godot und Windows 500 ms | Optimale Zahl fürs Spiel [S]; Controller-Entsprechung | mittel |
| 5 | Mindestschrift, Skalierung, HiDPI, Steam Deck | 12 px Setzung, `_scale` | `canvas_items` skaliert; `get_visible_rect` bleibt 1600 x 900 (Eigenmessung); XAG 18 px PC, Valve 9/12 px | Seitenverhältnis ≠ 16:9; Messkonvention (Glyph oder `font_size`); echtes 4K und 1280 x 800 | mittel |
| 6 | Playtest-Methodik bei D16 (Basti allein) | Aufgabenkarten ohne Metrikdefinition | 5 je Runde, Metriken (Erfolg, Zeit, Fehler), Beobachtung; Expertenreview ist kein Nutzertest (Q11, Q12, Q41) | Ob Basti als Proband genug Signal liefert; Zielwerte für Zeit bis zur ersten Aktion | mittel |
| 7 | Onboarding und Hilfe-HUD | Einzeilige Tastenübersicht, Konzept "kontextuelle Hinweise" ungebaut | GAG, Factorio-Kanalregel, Skip-Fähigkeit (Q20, Q28, Q29) | Zielzahlen; wann Veteranenschalter; Hinweis-Timing | niedrig bis mittel |
| 8 | Kamera und Eingaben | Slice und Prototyp belegen Maustasten gegensätzlich | CS2 und TF2 Konventionen; Kantenscrollen abschaltbar; Tasten frei belegbar (Q44 bis Q47, Q20) | Zoom zum Cursor, Kipp-Steuerung, Maus-Pan in Wahl-/Baumodus | niedrig bis mittel |
| 9 | Bedarf-Icons und Statusformen | Erkennbarkeit nur durch Autorin geprüft; Fleisch-Icon 18 px | Redundante Kodierung ist Konsens (Q18, Q20, Q31, Q42) | Erkennbarkeit bei 12 bis 18 px mit echten Personen; CVD nicht an Betroffenen | mittel |
| 10 | Epochen-UI 1820 bis heute | Nur Konzept | Prinzip: Chrome stabil, Inhalte per Daten (A12); Prüffragen je Epoche | **Keine belastbare Quelle**; Klasse "Stadt" und Icon-Anzahl im Schild fehlen | niedrig |
| 11 | Informationsdichte im Tycoon | Schild trägt Name, EW, Trend, 3 Icons, Tooltip | Hierarchie-Regeln (Q09), Anno-Prinzip "auf der Karte", Factorio-Hover (Q27, Q32); Mehrdeutigkeit zu Tooltip-Dichte [S] | Dichte bei mehr Bedarfskategorien (Stahl, Werkzeug ab Stadt) | mittel |
| 12 | Controller, Vollbild, Startmenü, Weltumschalter | Menü ohne Fokus, Esc destruktiv, Dev-Text im Menü | Steam-Deck-Regeln, Radial und Fokuswechsel (Q22, Q33, Q36, Q37); Godot rät Vollbild bei hiDPI (Q23) | Einstellungsspeicher; Esc-Verhalten; Steuerungsübersicht im Pausenmenü | niedrig bis mittel |

## C2 Weiter unsicher (ehrlich)
- Ob irgendeine meiner Schwellen (1.500 m, 400 m, 8 %, 0,12 s, 12 px, 7:1) für Basti und Neulinge optimal ist; belegt ist nur, dass sie gesetzt wurden und die Tests ihnen genügen.
- Ob Q25 (200 ms) einen echten Genrestandard abbildet; es ist ein einzelner Blog, der Streit mit 500 ms bleibt.
- Zoom zum Cursor, Kantenscrollen-Default und Kippsteuerung: keine Quelle.
- Epochen-UI: nur Prinzip, keine Evidenz.
- Controller: kein Standard für Aufbau-/Strategiespiele, nur Einzelbeispiele (Frostpunk, CK, Anno).
- APCA und WCAG 3 nicht geprüft.

## C3 Nicht erreicht oder blockiert
- **Reddit nicht lesbar:** `WebFetch` auf reddit.com meldete SITE_BLOCKED; eine auf reddit.com begrenzte `WebSearch` wurde vom Proxy abgelehnt (HTTP 400). Redlib-Spiegel tauchten in Suchergebnissen auf; ich habe sie nicht abgerufen (kein Umgehen). Es fehlen daher Spielerstimmen aus r/gamedesign, r/gamedev, r/UI_Design, r/IndieDev, r/TransportFever, r/CitiesSkylines, r/factorio. Ersatz: Steam- und Foren-Threads (Q30, Q44, Q47), die nur Einzelmeinungen sind.
- GDC Vault: Vortrag nur für Mitglieder, nur Abstract (Q49). Unity-LOD-Doku und Godot-Doku zu Visibility Ranges nicht abrufbar. Zu Townscaper, Transport-Fever-2-Entwicklern, Mini-Metro-Blogs keine auswertbaren Inhalte gefunden. TF3-Quellen (Q34, Q35) sind Vorschauen.
- Keine Messung mit echten Menschen, keine echte Zielhardware; Eigenmessung Q50 nur in xvfb.

## C4 Arbeitsregeln für künftige UX-Arbeit
1. Jede Schwelle als Datenwert mit Quelle, Messmethode und Status ([K], [S], [E], [H]) ablegen; Setzungen offen als Setzung markieren.
2. Vor dem Rundgang für jede Aufgabenkarte Messgröße und Abbruchkriterium festlegen; Ergebnisse als "Expertenreview (n = 1)" kennzeichnen.
3. Neue Zeichen immer gegen echten Untergrund messen und beide Kontraste melden: Zeichen gegen Platte und Schild gegen Umgebung.
4. Label-LOD und Declutter mit mindestens dem Dreifachen der echten Knotenzahl und einem aufgezeichneten Kamerapfad testen.
5. Hover-UI immer mit Fokus- und Esc-Äquivalent entwerfen, auch wenn der Prototyp nur Maus kennt.
6. Messkonvention für Textgrößen festlegen und bei 1280 x 800, 1920 x 1080 und 3840 x 2160 prüfen.
