# Farbcheck S-05 (Palette v1) und Ghost-Weiß (D10) – Ergebnis an Sophie

Daniel Richter, QA · 19./20.11.2026 · Werkzeug `day1-3/daniel/farbcheck.py` (CIEDE2000, Machado 2009, Schweregrad 1.0, Grenze ΔE ≥ 10 = QA-Annahme). Rohausgaben: `farbcheck_palette_v1_ausgabe.txt`, `ghost_check.csv`, `ghost_check_ausgabe.txt`.
Gerechnet, nicht mit Betroffenen geprüft (Katrins Rot-Grün-Tester: keiner belegt). Sandbox ohne GPU, für Farbrechnung irrelevant.

## 1. Palette v1 (`day1-3/sophie/s05/palette_v1.csv`): 21 Kollisionen, identisch mit Sophies Gegenprobe

Mein Lauf liefert zeilengleich dieselben Werte wie `sophie/s05/daniel_farbcheck_ausgabe.txt` (diff leer). Die Synchronisationslücke aus Tag 3 („Palette fehlt“) ist damit geschlossen. Die 21 Kollisionen nach Gruppen:

| Gruppe | Kollisionen | Kritisch? |
|---|---|---|
| **status** (Hinweis-Blau, Warnung-Gelb, Kritisch-Rot) | **0** in allen 5 Modi (kleinster Wert Blau/Rot 11,7 Graustufen, knapp über der Grenze) | – · Form (Kreis/Dreieck/Achteck) trägt zusätzlich |
| netz (Spieler-Orange gegen KI3-Hellgrau, KI1 gegen KI2) | 2, nur Graustufen (8,7 / 8,0) | gering: Spieler-Netz muss sich vom KI-Netz unterscheiden, Graustufen ist der härteste Fall; Vorschlag KI3 etwas dunkler (≈ `#A8B0B8`) |
| terrain | 15 (Gras/Feld, Gras/Fels, Gras/Wasser, Wasser/Fels 0,4 Graustufen, Feld/Stadtfläche 5,7–8,9 in **allen** Modi inkl. Normal) | mittel: Gelände ist absichtlich gedeckt (≤ 35 % Sättigung), aber **Feld-Ocker gegen Stadtfläche** liegt schon ohne Farbsehschwäche unter 10 und betrifft S-03 („Stadt finden < 10 s“). Entscheidung Sophie: Stadtfläche heller/kühler oder Umriss Pflicht |
| gueter_entwurf | 4, nur Graustufen | offen bis S-05b, Icons geplant |

## 2. Ghost-Weiß gegen `#F2F2F2` und Stadtfläche (D10)

Kein Hex für „Ghost weiß“ liegt vor (Aylin: „weiße Kontur“, Sophie: „weiß = baubar übernehmen“). **Annahme:** Kandidaten `#FFFFFF` und Aylins UI-Weiß `#F0F0F0`.

| Ghost-Kandidat | gegen `#F2F2F2` (Konsum-Weiß, Güter-Entwurf) | gegen Stadtfläche `#CBBFA8` | gegen `ok_ring` `#E6EAED` | gegen `outline_hell` `#F0F0F0` |
|---|---|---|---|---|
| `#FFFFFF` | **ΔE 2,6** in allen 5 Modi → **< 10** | 14,1–17,7 → ok | 4,5–5,5 → < 10 | 3,0 → < 10 |
| `#F0F0F0` | **ΔE 0,4** → praktisch gleich | 11,1–15,0 → ok | 1,5–3,6 → < 10 | 0,0 (identisch) |

Gegen alle Geländefarben liegt Weiß sicher über 10 (kleinster Wert: `#F0F0F0`/Feld-Ocker 16,8 Graustufen).

**Ergebnis nach D10-Regel (ΔE < 10 → dunkle Kontur):** Ghost-Weiß kollidiert mit dem Konsum-Weiß `#F2F2F2` (und mit `ok_ring`/`outline_hell`), **nicht** mit der Stadtfläche. **Konsequenz (Sophie):** dunkle Kontur am Ghost (z. B. `outline_dunkel #14161A`) ist nach D10 Pflicht, **oder** das Konsum-Gut bekommt eine andere Farbe (Güter sind nur Entwurf für S-05b, also billig zu ändern). Mein Vorschlag: beides, weil der weiße Ghost auch über `ok_ring`-Markern liegt.

## 3. Was nicht geprüft ist
Formen (Kreis/Dreieck/Achteck) visuell in Graustufen-Screenshots (Checkliste Teil 2), Kontrast der Marker mit Ring auf Gelände (Sophie hat das gerechnet, ich habe es nicht nachgerechnet), Betroffenen-Test (Katrin, offen).
