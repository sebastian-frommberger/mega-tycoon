# Art Director: Resümee (Stand 03.11.2026)

Pfade relativ zu `/home/claude/mega-tycoon/`. [Beleg] = nachgelesen/nachgerechnet, [Eindruck] = meine Einschätzung.

## 1. Wie ich Spiel und Konzept heute sehe

Kern: gelesene, ruhige Landschaft; Information kommt über Zeichen (Icons, Schilder), nicht über Überzeichnung des Maßstabs. Charta E1 "nichts überzeichnet", 1 Feld = 25 m. [Beleg: `sprints/s8/design-sprint/charter*`, `concept/leitplanken.md`]

Was trägt: geteilte Palette mit Tokens, Look-Gates G1 (Industrie/Gebäude neutral) und G2 (keine 25-m-Uferzacken bei 160 m), Marker #FFC21A, Ghost weiß mit Saum #0F1720. [Beleg: `sprints/s4/` S-08, Charta]

Was noch Papier ist: G3 (Kontrast >= 3:1) für Wasser/Boden ist nicht erfüllt (14 Paare, 1,08-2,95) und die Metrik selbst ist fraglich (s. 7). Fernlesbarkeit ist nie mit Personen getestet. Der Epochen-Look W2/W3 hat keine Assets. [Beleg: `phase4/aylin_kontrast_g3_wasser.csv`, `asset_audit*`]

## 2. Entwicklungsverlauf S2-S8

- S2/S3: Kenney-Look als Basis, "Spielzeugproportion" als Streitpunkt. [Beleg: `design/art/day4-6/kenney_messung.md`]
- S4: Palette-Tokens und Marker/Ghost festgelegt. [Beleg]
- S6: S-13 Props x1,25-2,4 gestreckt; SP-03-Spike. [Beleg: `sprints/s6/zocken/sophie_sp03.md`]
- S7: Basti-Feedback 01-11, Maßstab bleibt Thema. [Beleg: `sprints/s7/`]
- S8: Charta, Gates G1-G3, K23 (Ersatzneubau + Altstadtschutz), Welle 1/2. [Beleg: `phase3/11_streitprotokoll`, `phase4/`]

## 3. Was gut lief

- E1 + Gates geben der Diskussion ein Maß; vorher war es Geschmack. [Beleg: Charta]
- K23 entscheidet den Epochen-Look im Repo (Daten W1-W5/6, Ersatzneubau). Mein Skill führt ihn noch als offen: der Skill ist veraltet, das Repo nicht. [Beleg: `phase3/11*`, `fortbildung/mt-artdirection/SKILL.md` Abschnitt C2]
- Eigener Graustufen+Blur-Test an `ta_w2_uebersicht.png` und `ta_w2_dorf.png`: Fluss und Teich lesen sich als dunkle Fläche gegen den Boden, helle Felder klar; Wald/Wiese teils ähnlich. [Eindruck, ein Lauf, Tonwerte nicht ausgemessen]

## 4. Was nicht gut lief (Kompromisse mit Zähler)

| Kompromiss | Zähler | Beleg |
|---|---|---|
| Maßstab-Überhöhung | 3 (S2, S6, S7) | S-13, Feedback |
| Kontrast nur gerechnet; Saum rettet | 4 | `aylin_kontrast_g3_wasser.csv`, S-08 |
| Gebäude einfärben statt modellieren | 2 | phase4 |
| 25-m-Raster-Treppen sichtbar | mindestens 5 | phase4/bilder |
| S-03-Kriterien ungeprüft (FOV 40°/720p, Prototyp nutzt 50°) | 1 | `design/art/` S-03, `slice/proto/prototyp_welt.gd` |
| Lok 1,341 / 9,04 m gegen K10 1,13 / 7,6 m | 1 | `phase4/ta_welle2*`, `phase2/10*` |

Widerspruch zu den anderen Rollen: Die Artistin zieht die Lok in die Länge, um die Silhouette zu halten; ich bestehe auf E1, weil sonst jedes Fahrzeug "nur ein bisschen" größer wird (das war der Weg zu Zähler 3). Die Technik wiederum hängt am 25-m-Raster und an Perf-Grenzen und würde Look-Gates (G2) eher lockern als Polygone erhöhen. Mein Skill verlangt Graustufentest als Lesbarkeitsmaß, aber G3 rechnet Luminanz, und Wasser/Boden unterscheiden sich vor allem im Farbton. Beides gleichzeitig zu fordern ist inkonsistent. [Eindruck]

## 5. Risiken (nach Eintrittswahrscheinlichkeit)

1. G3 wird weiter an der falschen Metrik gemessen: Teams "reparieren" Luminanz und verlieren Farbton. Hoch. [Beleg: Rechnung unten]
2. Fernlesbarkeit bleibt ungetestet bis S9. Hoch. [Beleg: kein Test im Repo]
3. W2/W3-Assets fehlen, Epochen-Look wird improvisiert. Hoch. [Beleg: asset_audit]
4. Sättigungsregel (<= 35 %) ist undefiniert (HSV/HSL/Lab). Mittel. [Beleg: Rechnung]
5. Farbfehlsichtigkeit (ca. 8 % der Männer) trifft die Wasser/Boden-Unterscheidung stärker als die Luminanz-Regel zeigt. Mittel. [Eindruck, Quelle sekundär]

## 6. Drei Empfehlungen für Sprint 8

1. **G3 aufteilen**: Luminanz 3:1 nur für UI/Icons/Marker (WCAG-Bereich), für Gelände ein Farbabstand ΔE2000 >= ca. 20 (heutige Paare 22-50, also erfüllt). Aufwand 0,5 Tag inkl. Charta-Änderung und Neuprüfung der 14 Paare.
2. **Fernlesbarkeitstest mit 3 Personen** (Basti + 2) an Übersicht/Dorf, FOV 40° gegen 50° nebeneinander, 3 Fragen ("wo ist Wasser, Wald, Straße"). Aufwand 0,5 Tag.
3. **Lok-Entscheid und Sättigungsdefinition** in `decisions`: Lok 1,13 oder 1,19x begründet; Sättigung in Lab-Chroma statt HSV. Aufwand 0,5 Tag.

## 7. Recherchen dieser Runde und Lernlog

**Wasser/Boden-Kontrast.** Frage: Ist 3:1-Luminanz die richtige Messlatte? Eigene Rechnung an `aylin_kontrast_g3_wasser.csv`: Kontrastverhältnis 1,28-2,95, aber ΔE2000 22-50. Sättigung Wasser tief HSV 59 %/HSL 42 %/Lab-C* 22,5; Wasser flach HSV 46 %; Wiese 38 %; Aue 42 %; Wald 36 %; Acker hell 47 %: je nach Modell reißt oder hält die 35-%-Regel. Quellen: W3C WCAG 2.1 SC 1.4.11 (Anwendungsbereich: UI-Komponenten und Grafikobjekte, die zum Verständnis nötig sind), CIEDE2000-Formel (Sharma et al.). Ergebnis: G3 ist als Gelände-Gate die falsche Metrik. Konfidenz: hoch für Rechnung, mittel für Übertragung auf Spielgelände.

**Farbfehlsichtigkeit.** Frage: Häufigkeit. Primärquellen (nei.nih.gov, colourblindawareness.org, PMC12385717) vom Abruf-Tool geblockt, nicht umgangen; ca. 8 % Männer nordeuropäischer Herkunft aus Sekundärquellen. Konfidenz: mittel.

**SSAO in Compat.** (Querbezug TA) Seit Godot 4.6 unterstützt; S-03 gilt als veraltet (getestet mit 4.4.1). Quelle: Godot Environment-Doku und Renderer-Vergleich. Konfidenz: mittel-hoch (Doku, nicht ausgeführt, keine Engine hier).

Lernlog-Zeilen:
- 2026-11-03 | G3 gegen Gelände mit Luminanz gemessen | Lücke: Metrik passt nicht zur Aufgabe | Zähler 1
- 2026-11-03 | Fernlesbarkeit nur an Screenshots, nie an Personen | Lücke | Zähler 1
- 2026-11-03 | Epochen-Look im Skill als offen, im Repo entschieden (K23) | Lücke: Skill nicht nachgezogen | Zähler 1

## 8. Vorschläge für Skill-Änderungen (nur Vorschläge)

Zeilennummern nicht gesichert; Verortung nach Abschnitt in `sprints/s8/fortbildung/mt-artdirection/SKILL.md`.

1. Abschnitt C2: "Epochen-Look offen" ersetzen durch "entschieden in K23 (Ersatzneubau + Altstadtschutz), offen nur Assets W2/W3" [Q], Quelle: `phase3/11_streitprotokoll`.
2. Gate-Abschnitt G3: Luminanz-Gate nur für UI, Gelände über ΔE2000 >= ca. 20 [~], Quelle: Rechnung oben, WCAG 1.4.11.
3. Abschnitt Fern/Wasser-Boden: "Graustufentest ersetzt keinen Farbtontest" [M], Quelle: eigene Bildtests.
4. Abschnitt Sättigung: Modell festlegen (Lab-Chroma) [Annahme].
