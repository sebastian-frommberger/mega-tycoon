# S-05 Statusformen, Schweregrad-Farben, Palette v1

Sophie Marx, Art Lead · Stand Tag 3 (18.11.2026) · Status: **Entwurf v1 gerechnet, nicht an Personen geprüft** · Kanban-Karte, nicht Teil des Sprint-Commitments

Dateien (Ordner `sophie/s05/`): `palette_v1.csv` (Format wie Daniels `farbcheck.py`), `statusformen.svg`, `swatch_modi.png` (Normal, Deut, Prot, Trit, Grau), `cvd_scene_1000m_uebersicht.png` (Look-Szene bei 1000 m in vier Simulationen), `s05_pruefung.py` mit `cvd.py` (Rechnung), `pruefung_ergebnis.txt`, `pruefung_paare.csv`, `daniel_farbcheck_ausgabe.txt` (Gegenprobe mit Daniels Skript).

## 1. Statusformen (Form trägt, Farbe ist Zusatz)

Ein System für Status und Schweregrad. Das löst Daniels F4 („gleiche Farbe, zwei Bedeutungen“): gelb heißt überall Warnung/Engpass, rot überall Kritisch/blockiert.

| Form | Bedeutung (Zustand = Schweregrad) | Füllung | Glyph | Hex |
|---|---|---|---|---|
| Kreis hohl | ok, läuft (nur in Legende/Listen, in der Welt kein Marker) | keine | – | Ring `#E6EAED` |
| Kreis gefüllt | Hinweis / Chance | blau | „i“ weiß | `#3D8FE0` |
| Dreieck | Warnung / Engpass | gelb | „!“ dunkel | `#FFD43B` |
| Achteck | Kritisch / blockiert | rot | Balken weiß (Stoppschild) | `#C8372D` |

**Marker-Aufbau:** Füllung, 2 px dunkler Ring `#14161A`, 1 px heller Halo `#F0F0F0`. Auf der Karte wirkt der kontrastreichere Ring, auf dem UI-Panel `#2B2B2B` der helle.

**Mindestgröße (Rechnung, keine Wahrnehmung):** Das Achteck weicht nur 0,076·r vom Kreis ab, das ist erst ab ca. 26 px Durchmesser ≥ 1 px. Darunter sind Kreis und Achteck ohne Glyph nicht sicher zu trennen. Regel: Marker mit Glyph ab 24 px, darunter nur Dreieck und Kreis, Achteck-Fall dann als Glyph-Variante.

## 2. Palette v1 (Hex)

| Gruppe | Name | Hex |
|---|---|---|
| Netz | Spieler, Default Signalorange | `#FF7A00` |
| Netz | KI 1 Schiefer, durchgezogen | `#44546A` |
| Netz | KI 2 Violettgrau, gestrichelt | `#7A5C99` |
| Netz | KI 3 Hellgrau, gepunktet | `#B9C0C7` |
| Gelände (Sättigung ≤ 35 %, gemessen 2–32 %) | Gras / Wald / Feld / Wasser / Fels / Stadtfläche / Straße | `#8F997D` / `#5F7355` / `#B7AB7F` / `#6F8FA3` / `#8C8A82` / `#CBBFA8` / `#5C5C5E` |
| Umriss | dunkel / hell | `#14161A` / `#F0F0F0` |
| UI (aus Aylins Mini-Entwurf) | Panel | `#2B2B2B` |
| Güter **Entwurf für S-05b** | Agrar / Tier-Nahrung / Holz / Erz-Stahl / Öl-Chemie / Energie / Konsum | `#E8C14F` / `#C7473A` / `#5C4029` / `#7088A6` / `#704C9E` / `#2CC6D6` / `#F2F2F2` |

Netzlinien bekommen ein 1,5 px dunkles Casing. KI-Netze unterscheiden sich zusätzlich durch Linienmuster.

## 3. Prüfung

**Methode:** Simulation nach Machado et al. (2009), Schweregrad 1.0, im linearen RGB. Die drei Matrizen habe ich gegen die Quelle (Oliveira-Seite der UFRGS) abgeglichen, der Selbsttest prüft Weiß-bleibt-Weiß und drei Sharma-Referenzwerte für CIEDE2000. Abstand CIEDE2000, Grenze ΔE ≥ 10 (Daniels QA-Richtwert, von mir übernommen). Graustufen als fünfter Modus. Gegenprobe: Daniels `farbcheck.py` liefert auf derselben CSV identische Werte (z. B. blau/gelb 59,1 / 63,8 / 60,0 / 44,4 / 21,5).

**Ergebnis der Kernpaare (Status und Netz):** In allen vier Farbmodi (Normal, Deut, Prot, Trit) liegt jedes Paar ≥ 10. Knappste Werte: KI 1 gegen KI 2 unter Deuteranopie 10,7 und Protanopie 10,9, gelb gegen Spieler-Orange unter Deuteranopie 12,4, rot gegen Spieler-Orange unter Tritanopie 14,9. In Graustufen bleiben zwei Netzpaare unter 10 (Spieler/KI 3: 8,7, KI 1/KI 2: 8,0). Dort trägt das Linienmuster.

**Kontrast:** Marker-Füllung gegen Gelände ohne Ring 1,0 bis 4,7:1, in 19 von 21 Kombinationen unter 3:1 (blau auf Gras 1,1:1). Der Ring ist deshalb Pflicht. Mit Doppelring ≥ 4,5:1 auf allen sieben Geländefarben. Rot gegen den dunklen Ring: 3,5:1, unter Protanopie 2,6:1 (unter 3:1). Gegenmaßnahme: weißer Balken (5,2:1) und heller Halo.

### Kollisionsprotokoll (Format Daniel, Auszug)

| Nr. | Prüfpunkt | A / B | Modus | ΔE | Zweiter Kanal | Bewertung / Maßnahme |
|---|---|---|---|---|---|---|
| 1 | F11 Netz | Spieler-Orange / KI 3 | Grau | 8,7 | Linienmuster, Casing | akzeptiert, im Testbuild zu prüfen |
| 2 | F11 Netz | KI 1 / KI 2 | Grau | 8,0 | gestrichelt / gepunktet | akzeptiert |
| 3 | F9 Netz auf Gelände | Spieler-Orange / Gras, Feld | Grau | 3 | Casing | **Casing Pflicht.** Erste Szenenversion ohne Saum: Orange auf Gras in Graustufen fast unsichtbar. Mit Saum in der Look-Szene sichtbar (`cvd_scene_1000m_uebersicht.png`). Neu aufgefallen: die Stahlwerk-Fläche hebt sich in Graustufen kaum vom Gelände ab, dort trägt nur das Icon |
| 4 | F2 Marker | Rot-Füllung / dunkler Ring | Prot | 2,6:1 | Balken, Halo | Maßnahme festgelegt |
| 5 | F1 Form | Kreis / Achteck | alle | < 1 px unter 26 px | Glyph | Mindestgröße 24 px mit Glyph |
| 6 | F5 Güter (Entwurf) | Agrar/Energie, Tier/Erz, Tier/Öl, Holz/Öl | Grau | 4,5 / 7,8 / 7,6 / 8,4 | Piktogramm, Muster | Muster pro Familie nötig, S-05b |
| 7 | Gelände | Gras/Fels, Gras/Feld, Feld/Stadt, Wasser/Fels | mehrere | bis 0,4 (Wasser/Fels Grau) | Form, Textur | Gelände trägt keine Bedeutung, bei ≤ 35 % Sättigung kaum vermeidbar. Risiko Wasser/Fels im Terrain-Shader beobachten |

## 4. Grenzen, ehrlich

- Alles gerechnet. **An Menschen mit Rot-Grün-Schwäche nicht geprüft** (Katrin wollte 1–2 Personen ansprechen).
- Voll-Dichromasie ist der Extremfall, anomale Trichromasie ist milder. Die Simulation ersetzt keinen Test.
- Die Form-Mindestgröße ist Geometrie, keine Sichtbarkeitsmessung.
- Güterfarben sind ein Entwurf: sieben Familien erreichen in allen fünf Modi gleichzeitig kein ΔE ≥ 10 (bester Suchlauf 7,6 bei meinen Kandidaten, danach Energie nachgezogen). Piktogramme und Muster sind nicht optional.
- Statusformen liegen als SVG vor, **nicht** im Testbuild-Overlay (F-06). Der Testbuild bleibt grau, das war so beschlossen.

## 5. Offene Punkte

- **Aylin:** Hinweis als Kreis gefüllt blau, ok als hohler Ring: einverstanden? Ghost: Konflikt blau (baubar, mein Konzept) gegen Hinweis-Blau. Vorschlag: Aylins „weiß = baubar“ übernehmen, dann bleibt Blau nur „Hinweis“.
- **Daniel:** Erster Durchlauf F1 bis F4 und F9 bis F13 ist mit `palette_v1.csv` möglich. Screenshots der Look-Szene liegen unter `s05/cvd_scene/`.
- **Tobias:** Güterliste für S-05b.
- Restaufwand S-05: ca. 0,5 T (SVG in drei Größen als Atlas, Daniels Gegenprüfung einarbeiten).
