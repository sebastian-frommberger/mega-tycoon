# Felix Novak, Tag 7 (24.11.): Übersicht

Ergebnisse liegen unter `day7-10/felix/`, der Code unter `spike/` (F-04-Spike plus `f06/`). Alles mit Godot 4.7.2 headless, alle Läufe tatsächlich ausgeführt.

## Stand je Ticket

**B8 (F-04): behoben.**
- Wartet ein Glied auf einen Block, der im selben Tick frei geworden ist, endet die Kette jetzt dort. Ursache: `BLOCK_BELEGT_UNTERWEGS` mit `halter_id −1`. Es entsteht keine Meldung und kein neuer Code.
- Daniels Replay liefert bei Tick 3451 eine gültige Kette.
- Regressionstest K5 deckt drei Fälle ab: einen synthetischen Fall, B8 als mittleres Glied und Daniels Netz über 6.000 Ticks (160 B8-Abfragen, 0 leere oder ungültige Ketten, 0 Fehlalarme).
- Beleg: `spike/test_output.txt`, Exit 0.

**F-06 Testbuild: gebaut, nicht exportiert.**
- 2D-Szene mit F1, F2, F3 und zwei Kontrollzügen.
- Panel Z1–Z5, Ketten mit 4/6/5 Zeilen, Wurzelzeile aus `params`.
- Kamerasprung mit Kontur, Markierungen, „Zurück“-Knopf.
- Klick-Log mit `unix_ms`, Session-Datei und Replay.
- F5 startet die Szene. Gestrichen ist nur die Kann-Stufe.
- Belege:
  - `spike/f06_smoke_output.txt`: Exit 0, 0 × SCRIPT ERROR, 3.000 Ticks
  - `spike/f06_replay_output.txt`: Prüfsummen gleich
  - `f06_screenshot.png`
- Startanleitung und Messliste für den Zielrechner: `f06_start.md`.

## Akzeptanzkriterium F-06

**Teilweise erfüllt.**
- Erfüllt in der Sandbox: Build, Smoke-Test, 3/3 Fehler, Klick-Log.
- Offen:
  - Export mit sha256 (es gibt keine Templates)
  - Pilot mit Lena
  - Daniels Smoke-Test nach seinem Protokoll
- Als Hash dient vorerst md5 der Quellen (`spike/build_md5.txt`).

## Abweichungen (bitte gegenzeichnen)

- Signal- und Abschnittsnummern vergibt das Netz, nicht Lenas Platzhaltertabelle. F1 hat 40 Felder statt 14.
- F3 zeigt „1 von 40“ statt 12, weil der Lkw langsam liefert. Erst nach etwa 37 min Spielzeit löst sich F3 auf.
- F1: Alle Sprungziele liegen nahe beieinander (kanonischer Ort D9).
- `K_ZURUECK` erscheint nur bei Kreisen mit mindestens 3 Zügen.
- Bei 720p ist das Panel ca. 267 px breit statt 320 px.

## Offene Fragen

- Aylin: Ist die Einordnung von B8 in Ordnung?
- Lena: Ist „1 von 40“ akzeptabel?
- Katrin: Wann ist ein Export auf dem Zielrechner möglich?

## Risiko

Es gibt keine echten Tester und keine Hardware-Messung, alle Sandbox-Werte sind synthetisch.
