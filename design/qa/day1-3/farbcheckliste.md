# Farbsehschwäche-Checkliste für S-05 (Statusfarben und Palette v1)

Daniel Richter, QA · Stand Tag 3 · Status: **Checkliste und Prüfskript fertig, erster Durchlauf nicht möglich** (Sophies Palette-Entwurf und Statusformen liegen noch nicht vor, geplant 20./21.11.).
Werkzeuge im Ordner: `farbcheck.py` (Paarprüfung und Bildsimulation), `palette_testwerte.csv` (nur Skripttest, **nicht** die Team-Palette).

## 1. Verfahren

**Simulation:** Normal, Protanopie, Deuteranopie, Tritanopie, Graustufen. Das Skript nutzt Machado et al. (2009), Schweregrad 1.0 (volle Dichromasie, strengster Fall), im linearen RGB; Graustufen = relative Luminanz Rec. 709. Der Abstand ist CIEDE2000. Geprüft habe ich die Implementierung gegen drei veröffentlichte Referenzwerte (Sharma-Testdaten: 2,0425 / 2,8615 / 27,1492, alle exakt getroffen) und die Matrizen darauf, dass Weiß Weiß bleibt. Das beweist die Rechnung, nicht die Eignung für echte Menschen.

**Grenzen der Simulation (ehrlich):** Voll-Dichromasie ist der Extremfall, anomale Trichromasie (häufiger) ist milder. Ein Simulator ersetzt keinen Test mit Betroffenen. Wenn möglich: 1 bis 2 Kollegen oder Tester mit gemeldeter Rot-Grün-Schwäche im L-06-Umfeld ansprechen (Katrin). Das ist Zusatz, nicht Teil der Messgröße.

**Reihenfolge je Prüfpunkt:** (1) Hex-Werte in CSV, `python3 -I farbcheck.py pairs datei.csv --limit 10`; (2) Screenshot aus dem Testbuild bzw. Sophies Szene durch `python3 -I farbcheck.py image shot.png ordner` (4 Varianten); (3) Varianten visuell prüfen: Formen, Muster, Beschriftung noch unterscheidbar?

**Grenzwert (Annahme, mit Sophie abstimmen):** zwei Farben, die **Verschiedenes** bedeuten und im selben Kanal liegen, müssen in **jedem** Modus ΔE2000 ≥ 10 haben **oder** sich zusätzlich durch Form/Muster/Beschriftung unterscheiden, die im Graustufen-Bild noch erkennbar ist. Ein Wert unter 10 ohne zweiten Kanal ist eine Kollision. Die 10 ist ein QA-Richtwert, kein Normwert.

**Ergebnisprotokoll = Kollisionsprotokoll** (Sophies S-05-Anforderung): Zeile je Kollision, siehe 4.

## 2. Prüfpunkte

Legende Ergebnis: ok / Kollision / nicht prüfbar (Material fehlt). Aktuell **alle „nicht geprüft“**.

| # | Prüfpunkt | Wie geprüft | Bestanden, wenn | Quelle | Ergebnis |
|---|---|---|---|---|---|
| F1 | **Statusformen** Kreis (ok) / Dreieck (Engpass) / Achteck (blockiert) | Screenshot in Graustufen bei kleinster Anzeigegröße (Weitzoom, Kartenmodus), 1080p | Alle drei Formen ohne Farbe unterscheidbar; Mindestgröße der Form dokumentiert (px) | concept/sophie.md (Farbsprache) | nicht geprüft |
| F2 | **Statusfarben** ok / Engpass / blockiert | `pairs`, Gruppe `status` | je Paar ΔE ≥ 10 in allen Modi oder F1 trägt allein | S-05 | nicht geprüft |
| F3 | **Schweregrad-Farben** kritisch rot / Warnung gelb / Hinweis blau (Aylin) | `pairs`, Gruppe `schweregrad` | wie F2; Schweregrad zusätzlich an Form, Symbol oder Text ablesbar, nicht nur an Farbe | concept/aylin.md | nicht geprüft |
| F4 | **Statusfarbe gegen Schweregradfarbe**: gleiche Farbwerte für unterschiedliche Bedeutung? | Beide Listen nebeneinander legen | Gleiche Farbe bedeutet nie zwei Dinge. Bekannt: gelb = „Engpass“ (Status) und gelb = „Warnung“ (Schweregrad), rot = „blockiert“ und rot = „kritisch“. Das ist nur dann kein Konflikt, wenn beide dasselbe meinen. Klären mit Aylin/Sophie | S-05 | nicht geprüft |
| F5 | **Güterfarben** (7 Familien: Agrar gelb/ocker, Tier/Nahrung rot, Holz braun, Erz/Stahl blaugrau, Öl/Chemie violett/schwarz, Energie cyan, Konsum weiß mit Rand) | `pairs`, Gruppe `gueter`, dazu Piktogramm und Muster auf Kartenbändern | ΔE ≥ 10 oder Piktogramm/Muster unterscheidet; Muster (Streifen, Punkte, Raster) im Graustufenbild erkennbar. Erwartete Problemstellen: gelb/ocker gegen braun, rot gegen braun (Rot-Grün-Schwäche), blaugrau gegen violett | concept/sophie.md; **Güterliste von Tobias fehlt, S-05b bleibt „Briefing“** | blockiert (kein Material) |
| F6 | **Blockfärbung** frei (neutral) / belegt (Zugfarbe) / reserviert (gestrichelt in Zugfarbe, Pfeil) | Screenshot Gleisbau-Tool und Streckenzoom, alle Modi | „belegt“ und „reserviert“ unterscheiden sich durch Strichmuster, nicht durch Farbe; Zugfarben untereinander ΔE ≥ 10 oder beschriftet; „frei“ vom Gelände abgrenzbar | concept/aylin.md | nicht geprüft |
| F7 | **Bau-Ghost** gültig / ungültig / teuer | `pairs`, Gruppe `ghost`, Screenshot über Gelände und Wasser | Gültigkeit lesbar an Form (Schraffur, Kreuz), nicht an Farbe allein; Grund als Text am Cursor | siehe Konflikt unten | nicht geprüft |
| F8 | **Wartezeit-Icon** (gelb ab 60 s, rot ab 120 s) | Screenshot | Sekundenzahl steht immer am Icon, Farbe nur Zusatz | concept/aylin.md | nicht geprüft |
| F9 | **Hintergrundkontrast** der Statussymbole und Marker gegen Gelände (max. 35 % Sättigung), Wasser, Schnee/Fels | Screenshot Karte, ΔE Symbolrand zu Untergrund | Symbol hat Umriss oder Rand, der in jedem Modus ΔE ≥ 10 zum Untergrund hat | concept/sophie.md | nicht geprüft |
| F10 | **Text und Label** in der Karte und im Feed | Kontrastverhältnis mit Rand/Outline | WCAG-Richtwert 4,5:1 für Text, 3:1 für große Symbole (als QA-Richtwert) | WCAG 2.x | nicht geprüft |
| F11 | **Firmenfarbe** (Spielernetz, Default Signalorange) gegen Fremdnetz-Farben und Konkurrenz | `pairs`, Gruppe `netz` | ΔE ≥ 10 in allen Modi oder Muster | concept/sophie.md | nicht geprüft |
| F12 | **Paletten-Presets** Deuteranopie / Protanopie / Tritanopie (Sophie plant sie) | Preset aktivieren, F2 bis F11 wiederholen | Preset behebt jede Kollision, die im Standard auftrat; Preset erzeugt keine neue | concept/sophie.md | nicht geprüft |
| F13 | **Farbe nie allein** Stichprobe: 10 zufällige Stellen im Spiel, in Graustufen | Screenshots | An jeder Stelle bleibt die Bedeutung erkennbar | concept/sophie.md („Farbe ist nie allein Bedeutungsträger“) | nicht geprüft |

### Bekannter Konflikt, bevor ich messe

Der Ghost ist in zwei Konzepten unterschiedlich definiert: Aylin: **weiß = baubar, rot schraffiert = nicht baubar**, Kosten in eigenem Label. Sophie: **Blau = baubar, Gelb mit Schraffur = teuer/außerhalb Einfluss, Rot mit Kreuz = unmöglich**. Das sind zwei verschiedene Farbsysteme für denselben Zustand. Ich kann nur prüfen, was gilt. Frage an Aylin und Sophie, welches System in S-05 und im Bau-Spike (A-06) gilt.

Prototyp-Befund aus dem Team-Feedback: „Ghost-Farben missverständlich“. Das war ohne Farbsehschwäche bereits ein Problem.

## 3. Was ich ohne Sophies Material schon belegt habe

Mit generischen Testfarben (`palette_testwerte.csv`, ausdrücklich nicht die Team-Palette) liefert das Skript lauffähige Ergebnisse. Beispiele aus diesem Testlauf: Ampel-Rot gegen Ampel-Grün kollidiert unter Deuteranopie (ΔE 9,0) und Graustufen (0,8); Rot gegen Blau kollidiert nur in Graustufen (ΔE 2,0). Das zeigt, dass die Prüfung nicht nur Rot-Grün trifft und dass Graustufen als eigener Modus nötig ist. Es ist **keine Aussage über Sophies Palette**.

## 4. Kollisionsprotokoll (Vorlage)

| Nr. | Prüfpunkt | Farbe A (Name, Hex) | Farbe B (Name, Hex) | Modus | ΔE2000 | zweiter Kanal vorhanden? (Form/Muster/Text) | Bewertung | Maßnahme (Sophie) | Nachprüfung (Datum, ΔE) |
|---|---|---|---|---|---|---|---|---|---|
| | | | | | | | | | |

## 5. Ablauf und Aufwand

| Schritt | Wer | Wann |
|---|---|---|
| Palette-CSV und Screenshots der Statusformen liefern | Sophie | bis 21.11. (Statusfarben im Testbuild-Overlay) |
| Erster Durchlauf F1 bis F4, F6 bis F13 | Daniel | nach Lieferung, 0,5 T |
| Kollisionsprotokoll an Sophie | Daniel | am selben Tag |
| Nachprüfung nach Korrektur | Daniel | 0,25 T, danach Freigabe „Palette v1 farbsehschwäche-geprüft“ |
| F5 Güterfarben | Daniel | erst wenn Tobias' Güterliste und S-05b-Entwurf vorliegen (nicht in Sprint 2) |

Die ursprünglich genannten 1,5 PT (Plan) bzw. 0,5 T (Refinement) bzw. 1 T (Daniels Forderung) widersprechen sich. Das Refinement-Kapazitätsblatt nennt 0,5 T. Das gilt für einen Durchlauf plus Nachprüfung, wenn Sophie sauber liefert.

## 6. Offene Fragen

- **Sophie:** Palette v1 als CSV (Name, Hex, Gruppe) und Statusformen als Screenshot, 3 Größen. Welches Mindestmaß haben die Symbole in px?
- **Aylin/Sophie:** Ghost-System (siehe oben). Gleiche Farben für Status und Schweregrad gewollt?
- **Sophie:** Grenzwert ΔE ≥ 10 akzeptiert oder anderer Wert?
- **Katrin:** Gibt es Kollegen oder Tester mit gemeldeter Farbsehschwäche für eine kurze Gegenprobe?
