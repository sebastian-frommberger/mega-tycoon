# Sophie – Sprint 2, Tag 1–3
## Daily Tag 1 (16.11.)
Gestern: Plan, Refinement-Beschluss und Konzept gelesen. Heute: Look-Szene in Godot angelegt (Stadt, 2 Industrien, Gleis, 200 MultiMesh-Quader, Kamerafahrt). Blocker: keiner.
## Daily Tag 2 (17.11.)
Gestern: Szene steht, erste Screenshots. Heute: Farbraum-Fehler und Dither-Rauschen behoben (Morphing statt Dither), Blend-Zonen 150/800 m, S-05-Rechnung begonnen. Blocker: kein Display-Test auf GPU möglich.
## Daily Tag 3 (18.11.)
Gestern: Blend und Palette-Entwurf. Heute: Messläufe (Frame-Zeit, Popping-Proxy), Klick-Test für Kollegen, S-05-Dokument. Blocker: keine Personen für den Test, keine GPU.

## Ergebnisse
- **S-03: in Arbeit, Restaufwand ca. 1 T.** `sophie/lookscene/` (läuft, `run_all.sh`), `s03_look_test_befund_und_entscheidung.md`, `s03_testaufbau_kollegentest.md`, Screenshots 50/150/400/800/1000 m, 5-s-Video.
  - Szene mit 200 MultiMesh-Quadern: **ja** (Log).
  - Kein Frame > 33 ms: **nein, nicht belegt.** Software-Renderer (llvmpipe), ca. 290 ms je Frame, nicht repräsentativ.
  - 3/4 Reviewer ohne Popping: **nicht geprüft.** Proxy: harter Wechsel 5,8× Median, Blend 1,5×.
  - 4/6 Kollegen finden Ziele < 10 s: **nicht geprüft, an echten Personen prüfen.** Aufbau und Klick-Tool liegen vor.
  - Entscheidung: Blend ja (vorläufig), Lesbarkeitsgrenze ca. 4000 m in dieser Szene, nicht im Wiki.
- **S-05: Entwurf v1 gerechnet, in Arbeit, Rest ca. 0,5 T.** `s05_statusformen_palette_v1.md`, `s05/palette_v1.csv`, `statusformen.svg`, `swatch_modi.png`. Alle Kernpaare ΔE ≥ 10 in Deut, Prot, Trit. Gegenprobe mit Daniels Skript identisch. Nur gerechnet, keine Person mit Rot-Grün-Schwäche. Nicht im Testbuild.

## Annahmen und offene Fragen an andere (mit Namen)
- Annahme: „< 10 s“ gilt je Ziel, nicht für alle drei. **Jonas/Daniel**, bitte bestätigen.
- Annahme: ΔE ≥ 10 von Daniel übernommen.
- **Felix:** 30-min-Review `visibility_range`; reicht Shader-Morphing statt LOD-Fade?
- **Katrin:** 6 Kollegen, Zielrechner mit GPU für einen Messlauf, 1–2 Personen mit Farbschwäche.
- **Aylin:** Hinweis als blauer Kreis, ok als hohler Ring einverstanden? Ghost: „weiß = baubar“ übernehmen, damit Blau nur „Hinweis“ heißt?
- **Daniel:** erster Durchlauf mit `palette_v1.csv` möglich.
- **Tobias:** Güterliste für S-05b.

## Risiko für das Sprintziel (1–3 Sätze, ehrlich)
Die Lesbarkeits- und Popping-Kriterien von S-03 stehen ohne Personen und ohne GPU-Messung offen, die Entscheidung am 20.11. ist nur vorläufig. Das Ergebnis betrifft F-08 (Kartengröße): die Rechnung spricht eher für 512² als Rückfallgröße. Das Sprintziel (Playtest, Sim-Kern, Lizenzleiter) hängt an S-03 nicht direkt.
