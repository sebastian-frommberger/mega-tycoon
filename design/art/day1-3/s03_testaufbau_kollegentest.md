# S-03 Testaufbau: Lesbarkeit der Kartenstufe mit 6 Kollegen

**Status: nicht durchgeführt. AN ECHTEN PERSONEN PRÜFEN.** Es gibt keine Daten von Personen. Das Akzeptanzkriterium „4 von 6 Kollegen finden Stadt, Industrie und Strecke in < 10 s“ ist damit **offen**. Der Aufbau ist fertig und läuft (Funktionstest mit simulierten Klicks, siehe unten). Aufwand für die Durchführung: 6 × ca. 5 min plus Auswertung, ca. 0,25 T, Rekrutierung Katrin.

## Messgröße (wörtlich übernommen, Auslegung markiert)

4 von 6 Testpersonen finden **Stadt, Industrie und Strecke** in der Kartenstufe (Kamerahöhe 1000 m) jeweils in **< 10 s** ab Aufforderung. *Auslegung (Annahme, mit Jonas/Daniel abstimmen):* die 10 s gelten je Ziel, nicht für alle drei zusammen. Gilt eine Person als bestanden, wenn alle drei Ziele einen Treffer unter 10 s haben.

## Aufbau

| Punkt | Festlegung |
|---|---|
| Personen | 6 Kollegen, die die Szene noch nicht gesehen haben und nicht an Art/Look-Entscheidungen beteiligt waren. Rekrutierung durch Katrin, nicht durch Sophie, um Auswahl-Bias zu vermeiden. |
| Gerät | Rechner mit echter GPU, Fenster 1280×720 (die Trefferzonen sind darauf berechnet), gleicher Monitor für alle. |
| Reiz | Standbild der Szene bei 1000 m, 70° Neigung, `map_blend` = 1. **Ohne Beschriftung, ohne HUD, Fahrzeuge eingefroren.** Beschriftungen würden die Aufgabe trivial machen. |
| Aufgabe | Text oben: „Klicke auf: STADT / INDUSTRIE / STRECKE“. Instruktion neutral, nichts erklärt („Du siehst einen Kartenausschnitt eines Transportspiels“). Kein Üben vorab. |
| Reihenfolge | Lateinisches Quadrat über die 6 möglichen Reihenfolgen, Testperson 1 bis 6 = `--pid=1..6`. |
| Zeitnahme | Automatisch ab Einblenden der Aufforderung bis zum ersten Klick **in der Trefferzone**. Fehlklicks werden mitgeloggt, Abbruch nach 20 s je Ziel (Wert „timeout“). |
| Trefferzonen | Automatisch aus der Kameraprojektion berechnet, Datei `clicktest/trefferzonen_1000m.json`. Stadt = Stadtfläche, Industrie = Farm- oder Stahlwerksfläche oder Icon (34 px), Strecke = Gleislinie ± 14 px. Ein Klick auf das Gleis in der Stadt trifft auch die Stadtzone (bei Ziel „Stadt“ gilt das als Treffer). |
| Start | `godot --path lookscene -- --clicktest --pid=N`, Leertaste = Start, Ergebnis in `clicktest/pid_N.csv`. |
| Auswertung | `python3 clicktest/auswerten.py clicktest/pid_*.csv`. |
| Nachfrage (qualitativ) | „Woran hast du die Industrie erkannt?“, „Was war am schwersten zu finden?“ (Icon, Fläche, Form). Antworten notieren, nicht werten. |

## Zweiter Teil: Popping im Video (3 von 4 Reviewern)

- Reiz: 5-s-Kamerafahrt 50 → 1000 m (`--movie`), 2× abspielen, einmal danach 1× in Zeitlupe (0,25×).
- Frage: „Siehst du ein plötzliches Umspringen (Objekte erscheinen oder verschwinden, Helligkeit springt)? Wann?“ Zeitpunkt in Sekunden notieren.
- Bestanden: 3 von 4 Reviewern nennen keinen Sprung. 4 Reviewer: Jonas, Felix, Aylin, Daniel (Vorschlag, nicht abgestimmt).
- **Grenze:** Das Video entsteht im Software-Renderer, nicht auf Zielhardware. Ob der Blend auf der GPU gleich aussieht, ist nicht belegt (siehe Ergebnisdokument).

## Bekannte Schwächen des Tests

- Kleine Stichprobe (6) und Kollegen kennen das Spielthema. Ein Bestehen belegt keine Lesbarkeit für Spieler.
- Nur ein Layout, nur 3 Zielobjekte, hoher Kontrast (Signalorange). Die echte Karte (1.024² Felder, viele Objekte) ist schwerer. Lerneffekt über die 3 Aufgaben ist durch das Lateinische Quadrat nur teilweise ausgeglichen.
- 10 s ist eine Setzung aus dem Refinement, keine abgeleitete Grenze.
- Der Test prüft Finden, nicht Verstehen („welches Gut?“).
- Farbsehschwäche: keine der 6 Personen wird gezielt darauf geprüft. Dafür gibt es S-05 (gerechnet).

## Funktionstest (kein Messwert)

`godot ... -- --selftest --pid=2` klickt pro Ziel einmal daneben und einmal in die Zone und schreibt `clicktest/selftest.csv` mit dem Kopf „FUNKTIONSTEST … KEINE Messdaten“. Er belegt nur, dass Trefferzonen und Zeitnahme technisch funktionieren.
