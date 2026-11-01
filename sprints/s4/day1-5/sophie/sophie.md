# Sophie Martin, Art Lead: S-10 und S-08 (Sprint 4, Tag 1-5)

## S-10 Karte ausgeglichen, eingefroren 15.12. (Stichtag im JSON: `status.stand = eingefroren`, `stichtag 2026-12-15`)
Repo `sprints/s3/day4-7/sophie/s09/` (Vorversion `v1_s3_entwurf/`), Kopie hier: `slice_map.json`, `slice_map.png`, `slice_map.schema.json` (neues optionales Feld `status`), `build_slice_map.py`, `validate_slice_map.py`, `check_s10.py`, `s10_check.json`.
- 3 Ketten, Cluster statt Streifen: Bergbau NW (Kohlberg, Kohle, Erz, Stahlwerk, Kraftwerk), Agrar SO (Haberau, 2 Farmen, Mühle), Absatz NO (Werkzeugfabrik, Mittelfurt, Eichwald, Steinbach), SW (Lindach, Weidenau, Seehafen, Holz Bergbau). Hafen-Kette und Sägewerk entfernt; Hafen-/Handel-HQ bleiben als "nicht im Slice" (bau_quelle "keine"). 8 Städte, 10 Industrien im Slice (Holz-Quellen für D13 zählen mit). Fluss, Küste Süd, 2 Gebirge.
- Zahlen (`check_s10.py`, 18 Inhalte): Quadranten NW 27,8 % / NO 22,2 % / SW 22,2 % / SO 27,8 % (Ziel 20-30 %). Kleinster Stadtabstand 80,6 Felder = 15,7 % (Lindach-Weidenau, Ziel ≥ 15 %). Gelände Gebirge 13,1 %, Meer 6,8 %, Wald 1,4 % (alle < 40 %). Nischen: Kohle-Stahlwerk 25, Farm 2-Mühle 26 Felder.
- Validierung: `validate_slice_map.py` (importiert Tobias' F-09-`validate.py`, jsonschema und Fallback) 0 Fehler; Geometrie-Skript 0 Fehler. Der T-06-Validator prüft nur Ökonomie-JSON, für die Karte nicht anwendbar.
- Bitte beachten: "Region ≤ 40 %" deute ich als Quadrant- und Geländeanteil (Felix/Lena bestätigen). Ketten-Luftlinien sind jetzt länger (K1 126, K3 169): Tobias muss sie in T-12 gegenrechnen. Kartenschema weiter ohne Abzeichnung von Tobias (B-03).

## S-08 Farben (`palette_s08.json`, `palette_s08_tabelle.md`, `compute_palette_s08.py`)
WCAG-Kontrast gegen Gras, Stadt (Straße, 3 Hausfarben), Wasser (2 Töne); Werte aus `prototype/main.gd`. Regel: Füllung oder dunkler Saum ≥ 3:1 gegen Hintergrund, Füllung ≥ 3:1 gegen Saum. Ergebnis: 35/35 Pflicht-Kombinationen (50/50 inkl. Wald/Berg/Schnee), schwächster Wert 3,73:1 (status_bad auf Straße).
Tokens: marker #FFC21A; status ok #48E08A, warn #FFA640, bad #FF988A (Alpha 0,9; Schraffur bleibt als zweites Merkmal); ghost weiß #FFFFFF Alpha 0,75 mit Saum #0F1720 (B-04: Füllung allein auf Gras nur 2,63:1, mit Saum 5,26:1).
Grenze: Rechnung, nicht in der Engine gemessen; gilt für unshaded Material (Felix setzt Saum, ≥ 2 px, und unshaded für Marker). Daniel prüft per Screenshot.
