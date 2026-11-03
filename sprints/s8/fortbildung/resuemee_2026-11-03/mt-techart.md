# Technical Artist: Resümee (Stand 03.11.2026)

Pfade relativ zu `/home/claude/mega-tycoon/`. [Beleg] = nachgelesen/nachgerechnet, [Eindruck] = meine Einschätzung.

## 1. Wie ich Spiel und Konzept heute sehe

Kern: 512² Felder (12,8 km) in Godot 4.7.2 mit gl_compatibility (opengl3). Tragende Technik: MultiMesh-Chunks (kein Culling pro Instanz), Visibility Ranges mit Hysterese, Fern-LOD `mesh_fern` ab 650 m, Shader-Animation über UV2 (part*100+pivot), eine Palette für alle (20 Klassen x 5 Stufen x 4 Zeilen). [Beleg: `slice/world/proto_prefab.gdshader`, `slice/proto/proto_fahrzeuge.gd`, `phase4/ta_welle1*`]

Was trägt: Prefab-Regeln R1-R6 (ein Mesh, eine Surface, ein Material, normalisierter Pivot), Import-Faktor je Rolle. [Beleg: `phase3/14*`]

Was noch Papier ist: Alle Perf-Zahlen stammen aus xvfb/llvmpipe-Zählwerten, keine echte GPU-Frametime. Gates: Übersicht <= 1,0 M Tris/300 DC, Stadt nah <= 2,9 M, Ladezeit <= 3 s. Erfüllt heißt "gezählt", nicht "gemessen". [Beleg: `phase4/felix_perf_aufschluesselung*`]

## 2. Entwicklungsverlauf S2-S8

- S2/S3: Kenney-Import, Kit-Faktoren, erste Messung. [Beleg: `design/art/day4-6/kenney_messung.md`]
- S4: Palette-Shader, Tokens. [Beleg: `sprints/s4/`]
- S6: S-13 Props, SP-03-Spike (Fahrzeuge in MultiMesh). [Beleg: `sprints/s6/zocken/sophie_sp03.md`]
- S7: Feedback 01-11, Perf rückt in den Vordergrund. [Beleg]
- S8 Welle 1: Gates, headless gezählt: 1,62 M Tris, live nur ca. 0,62 M, also Faktor 2,6 daneben. [Beleg: felix_perf_aufschluesselung]
- S8 Welle 2: Fixpass W2, Integration W2. [Beleg: `phase4/fixpass_w2*`, `integration_w2*`]

## 3. Was gut lief

- Shared Palette-Shader und R1-R6 halten Draw Calls klein und machen Import vorhersagbar. [Beleg]
- Perf-Aufschlüsselung (Felix) hat den Zählfehler 1,62 gegen 0,62 M überhaupt aufgedeckt. [Beleg]
- Fern-LOD ab 650 m mit Hysterese verhindert Poppen an der Grenze. [Eindruck, nur Standbilder gesehen]

## 4. Was nicht gut lief (Kompromisse mit Zähler)

| Kompromiss | Zähler | Beleg |
|---|---|---|
| Perf nur Zählwerte/llvmpipe | 4 | felix_perf_aufschluesselung |
| Headless-Zählfehler | 2 | ebd. |
| 25-m-Raster-Treppen (Terrain) | mindestens 5 | phase4/bilder |
| Gang-Phase in INSTANCE_CUSTOM.x mod 240 m | 1 (neu entdeckt) | `proto_prefab.gdshader` Z. 7 |
| Kenney-Teil passt nicht, Eigenbau | mindestens 7 | `ta_welle2*` |

Neu in dieser Runde: Die Gangphase wird als `fmod(Gangstrecke, 240)` in `INSTANCE_CUSTOM.x` abgelegt (`slice/proto/proto_fahrzeuge.gd`, `use_custom_data = true`). In Compat ist INSTANCE_CUSTOM Halbfloat (16 Bit). Mein Rechenergebnis mit float16: Auflösung 0,0625 m bei 64-128 m, 0,125 m bei 128-240 m. Der Schritt pro Frame beträgt bei 2,5 Hz Gangtakt und 60 FPS etwa 0,108 m, also liegt die Auflösung in rund 46,7 % der Periode über dem Frameschritt. Folge: Beinphase springt bis 17,3° (Schwung ±24°), Rad bis 8,2°. Auf [0,1) normalisieren hilft nicht (gleiche Mantisse); Phase pro Doppelschritt (2,6 m) gibt 0,00127 m Auflösung. [Beleg: Godot MultiMesh-Doku, Rechnung; Sichtbarkeit im Spiel nicht getestet, keine Engine im Sandkasten: Eindruck]

Widerspruch zu den anderen Rollen: Die Art Direction fordert Look-Gates (G2: keine 25-m-Uferzacken bei 160 m) und E1-Maßtreue; ich würde für Perf lieber das Raster beibehalten und Zacken per Shader/Normal glätten statt per Geometrie. Die Artistin streckt Teile gern manuell (Lok 1,341), ich möchte Streckung ausschließlich im Import-Faktor. Wenn alle drei gewinnen, haben wir mehr Tris und mehr Sonderfälle. [Eindruck]

## 5. Risiken (nach Eintrittswahrscheinlichkeit)

1. Perf auf echter GPU weicht von llvmpipe-Zählung ab (Zähler 4, Faktor 2,6 schon einmal daneben). Hoch. [Beleg]
2. Gang-Sprünge werden in Bewegung sichtbar (47 % der Periode). Mittel-hoch. [Beleg: Rechnung; Sichtbarkeit Eindruck]
3. Chunkgröße der MultiMeshes ungetestet (offene Lücke C2). Mittel. [Beleg: SKILL C2]
4. Ladezeit-Gate <= 3 s nie auf Zielhardware gemessen. Mittel. [Beleg]
5. Impostor-Strategie für sehr viele Fahrzeuge fehlt. Niedrig bis mittel. [Eindruck]

## 6. Drei Empfehlungen für Sprint 8

1. **Gangphase umbauen**: Phase pro Doppelschritt (2,6 m) statt 240 m; Shader (`phase = ...`) und `proto_fahrzeuge.gd` ändern. Aufwand 0,5 Tag.
2. **Echte Frametime messen**: ein Lauf auf Bastis Zielhardware, Übersicht und Stadt nah, 60 s, Frametime-Median/P99 statt Zählwerte. Aufwand 0,5-1 Tag plus Verfügbarkeit der Hardware.
3. **SSAO-Test in Compat und Zählmethode korrigieren**: SSAO ist seit 4.6 in Compat verfügbar, S-03 gilt als veraltet; ein A/B-Test mit Aufnahme, dazu headless-Zählung gegen Live kalibrieren. Aufwand 0,5 Tag.

## 7. Recherchen dieser Runde und Lernlog

**INSTANCE_CUSTOM in Compat.** Frage: Welche Genauigkeit hat die Instanz-Custom-Data? Quellen: Godot MultiMesh-Klassendoku und Renderer-Dokumentation (`renderers.rst`), Godot-Quelltext-Auszug `ms.cpp` (lokal gesichert). Ergebnis: Halbfloat; Quantisierung wie oben berechnet. Konfidenz: hoch (Spezifikation + Rechnung), Sichtbarkeit mittel.

**SSAO in Compat.** Frage: Ist SSAO verfügbar? Quellen: Godot Environment-Doku (`env_*.xml`), Renderer-Vergleich (`renderers_*.rst`). Ergebnis: ab 4.6 unterstützt. Konfidenz: mittel-hoch (Doku, nicht ausgeführt).

**Signed-Distance-Texturen für scharfe Kanten** (Valve 2007; Spiegel auf realtimerendering.com, da steamcdn-Link geblockt). Ergebnis: für Marker/Schilder auf großer Distanz brauchbar, kein Ersatz für Palette. Konfidenz: mittel.

Geblockt, nicht umgangen: steamcdn (Valve-PDF), wiki.transportfever2.com (modding:buildings), quaternius.com Packseite.

Lernlog-Zeilen:
- 2026-11-03 | Gangphase als Halbfloat in INSTANCE_CUSTOM.x | Lücke: Präzision nie geprüft | Zähler 1
- 2026-11-03 | Perf-Gate mit llvmpipe-Zählwerten abgehakt | Kompromiss | Zähler 4
- 2026-11-03 | S-03 SSAO-Aussage veraltet (4.4.1 getestet) | Lücke | Zähler 1

## 8. Vorschläge für Skill-Änderungen (nur Vorschläge)

Zeilennummern nicht gesichert; Verortung nach Abschnitt in `sprints/s8/fortbildung/mt-techart/SKILL.md`.

1. Abschnitt Compat-Grenzen: "INSTANCE_CUSTOM ist Halbfloat, Phasen modular mit kleiner Periode kodieren" [Q], Quelle: Godot MultiMesh-Doku, Rechnung oben.
2. Abschnitt C2 (SSAO): "SSAO in Compat ab 4.6 unterstützt, Wirkung zu testen" [~], Quelle: Godot Environment-Doku.
3. Abschnitt Perf: "llvmpipe-Zählwerte nie als Frametime ausgeben; Headless-Zählung gegen Live kalibrieren" [M], Quelle: felix_perf_aufschluesselung.
