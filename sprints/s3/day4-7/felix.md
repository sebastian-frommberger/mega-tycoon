# Felix – S3 Tag 4–7

## F-13 Bau-Tool, Abriss 50 % – fertig im Prototyp
`felix/prototype/`. Umsetzung wie OpenTTD: ziehen von Start- zu Endfeld, erst gerade, dann 45°. Die Diagonale ist eine Feldtreppe (Raster 4-verbunden, wie die OpenTTD-Halbfelder). Ghost: weiß = baubar, rot schraffiert = nicht baubar. Grund und Kosten stehen am Cursor. Alles oder nichts wie TF2. Abriss [X] wie OpenTTD als Rechteck, Erstattung 50 % des **bezahlten** Feldpreises.
- **Beleg:** `tests/f13_test.gd` → 38 Prüfungen, 0 Fehler, Exit 0 (`f13_test_output.txt`). Geprüft: gerade, 45°, Meer abgelehnt mit Grund, Kosten = Summe Feldkosten, Abriss genau 50 %, Exploits E1–E12 ohne Geldgewinn.
- **Screenshots** (xvfb, opengl3, Drag simuliert): `f13_screenshot.png` (weiß, 234 $), `f13_screenshot_rot.png` (Getreidefarm im Weg).
- **Festgelegt** (bitte prüfen, Daniel/Aylin):
  1. Wasser wird mit einer automatischen Brücke überbaut, aber nur gerade, mit Land an beiden Enden und höchstens 8 Feldern (wie OpenTTD). 6×-Aufschlag bleibt.
  2. Feldpreise werden jetzt pro Feld abgerundet statt über die Summe. Bis zu 1 $/Feld billiger.
  3. Unter einer Linie ist kein Abriss möglich.
  4. Lager/Gebäude reißt [X] nicht ab.
- **Offen:** Der Anschluss an eine Stadtstraße (README) wurde schon im Repo-Code nie geprüft. Kein Undo (S4). Den echten Mausdrag habe ich nicht von Hand getestet, nur programmatisch.

## Zusatz F-06: Labels + Standzeit – fertig
`felix/f06/`. Die Dateien hängen am Spike-Kern, deshalb läuft der Test über `run_smoke_felix.sh` (Spike + Overlay). Ergebnis: Exit 0, 0 SCRIPT ERROR.
- **Karte:** zeigt „Strecke Mühlbach–Kornfeld“, „Kreuzung Südfeld“, „Hafen-Ost“, Abschnitte 11–44 und Signale S11 … (`f06_labels_F*.png`).
- **Standzeit:** Bisher lief der Titel weiter, während Zeile 1 eingefroren war. Jetzt zeigt die offene Meldung im Titel denselben Stand wie Zeile 1 und „Stand m:ss“. Geschlossene Meldungen laufen live. Der Smoke-Test prüft das neu.
- **An Aylin:** Die Zeiten laufen, also keine festen Sekunden ins Material. Startwerte 2:05–2:12, alle über 120 s, „1:40“ ist falsch.
