# S-05 Statusformen und Palette v1 – final (Kanban)

Sophie Martin, Art Lead · 20.11.2026 · Status: **Kanban-Karte abgeschlossen (v1 final, gerechnet).** Nicht an Menschen mit Farbsehschwäche geprüft, nicht im Testbuild (so beschlossen).

Dateien: `s05/palette_v1_final.csv` (Format Daniel), `s05/palette_v1_final_farbcheck.txt` (Lauf mit Daniels `farbcheck.py`, von mir ausgeführt), `s05/ghost_check.csv` + `ghost_check_ausgabe.txt` (Ghost-Prüfung nach D10). Statusformen-SVG und Swatches unverändert aus `day1-3/sophie/s05/`.

## 1. Was sich gegenüber v1 (18.11.) geändert hat

| Punkt | Entscheidung | Quelle |
|---|---|---|
| Ghost | **Weiß `#FFFFFF` = baubar, Rot `#C8372D` schraffiert = nicht baubar.** Kein Ghost-Blau, kein Ghost-Gelb mehr. Kosten und „außerhalb Einfluss“ stehen im Kosten-Label (Aylin: Gültigkeit und Kosten sind getrennte Kanäle), nicht in der Ghost-Farbe | D10, `concept/aylin.md` |
| Blau | nur noch **Hinweis** (Kreis gefüllt `#3D8FE0`) | D10 |
| Ghost-Aufbau | Füllung Alpha 0,35, Kontur 2 px weiß, **zusätzlich 1,5 px dunkler Saum `#14161A`** unter der Kontur | eigene Rechnung, siehe 2 |
| Status = Schweregrad | ein System, Gelb heißt überall Warnung/Engpass, Rot überall Kritisch/blockiert (Daniels F4 geschlossen) | unverändert |
| Güterfarben | bleiben **Entwurf** (S-05b), nicht Teil von v1 final; Tobias' Güterliste fehlt weiterhin | unverändert |

## 2. Ghost-Prüfung (eigene Rechnung mit Daniels Skript, Daniels Lauf steht aus)

D10 verlangte: Daniel prüft Weiß gegen `#F2F2F2` (Konsum) und Stadtfläche; bei ΔE < 10 dunkle Kontur. In `day4-6/daniel/` liegt nichts (Stand 23.11.), ich habe die Rechnung selbst gemacht. **Das ersetzt Daniels Durchlauf nicht, es nimmt ihn vorweg.**

| Ghost-Weiß gegen | ΔE2000 (min über 5 Modi) | Bewertung |
|---|---|---|
| Stadtfläche `#CBBFA8` | 14,1 (Grau) bis 17,7 | ok |
| Feld-Ocker `#B7AB7F` | 19,7 bis 25,9 | ok |
| KI-3-Hellgrau `#B9C0C7` | 14,4 bis 15,3 | ok |
| Hinweis-Blau | 29,5 bis 39,3 | ok |
| Ghost-Rot | 40,3 bis 51,9 | ok |
| Konsum-Weiß `#F2F2F2` | **2,6** | Kollision. Konsum ist kein VS-Gut (Kategorie ab E3) und eine Marker-/Ladegutfarbe, keine Fläche, auf der der Ghost liegt. Trotzdem: **dunkler Saum Pflicht**, damit der Ghost nie allein über Weiß liegt (Schnee/Fels-Varianten, Konsum später) |
| Outline-Hell `#F0F0F0`, ok-Ring `#E6EAED` | 3,0 / 4,5 | gleiche Familie „Weiß“, gewollt; Ghost unterscheidet sich durch Fläche + Schraffur + Saum, nicht durch Ton |

Folgerung: Weiß gegen Stadtfläche besteht Daniels Grenze (≥ 10) ohne Kontur. Ich setze den dunklen Saum trotzdem, weil der Ghost auch über helleren Flächen liegen wird, die es in der Palette noch nicht gibt.

## 3. Gesamtlauf Palette v1 final (Daniels Skript, 21 Kollisionen, alle bekannt)

- Status-Paare: alle ≥ 10 in allen Modi (unverändert).
- Netz: Spieler/KI 3 in Grau 8,7; KI 1/KI 2 in Grau 8,0 → Linienmuster trägt (akzeptiert, Tag 3).
- Gelände: 17 Kollisionen (Gras/Feld, Gras/Fels, Feld/Stadt, Wasser/Fels in Grau 0,4). Gelände trägt keine Bedeutung, bei ≤ 35 % Sättigung nicht vermeidbar. Risiko Wasser/Fels im Terrain-Shader bleibt notiert.
- Güter-Entwurf: Kollisionen wie Tag 3, S-05b.

## 4. Offen

- **Daniel:** eigener Durchlauf F1–F4, F6–F13 mit `palette_v1_final.csv` und Kollisionsprotokoll; Bestätigung ΔE-Grenze 10. Mein Lauf ist nur Vorabprüfung.
- **Katrin:** 1–2 Personen mit Rot-Grün-Schwäche, 15 min mit Swatches (nicht erzeugbar hier).
- **Aylin:** Ghost-Saum und Alpha 0,35 in die A-06-Textspezifikation; Hinweis als blauer Kreis, ok als hohler Ring (keine Antwort gelesen, Annahme: übernommen).
- **Tobias:** Güterliste für S-05b.
- Rest: Statusformen-Atlas in 3 Größen (U2 in S-06a, 0,5 PT), nicht mehr Teil dieser Karte.
