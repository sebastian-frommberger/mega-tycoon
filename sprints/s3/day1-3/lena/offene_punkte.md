# Offene Punkte vor dem echten Test (L-07)

Stand Sprint 3, Tag 1. Frist für alles Rote: **Freitag 28.11.**, damit Basti am 01.12. ohne Rückfrage startet. Die Befunde zum Build stammen aus dem synthetischen Panel (Haiku-Personas, nur Text und ein Screenshot). Sie sind Hinweise, keine Messung; Felix und Daniel prüfen am echten Build.

## Muss vorher korrigiert werden

| Nr | Punkt | Wer |
|---|---|---|
| 1 | **Zeitangaben angleichen.** Material sagt 2:10 / 1:40 / 2:10, der Build zeigt 2:05 / 2:07 (4 von 6 Personas stolperten). Dazu: 1:40 bei Zug 5 widerspricht „Stillstand mindestens 120 s“. Der Build ist die Wahrheit. Felix legt fest, ob die Zeit eingefroren oder laufend ist, Aylin gleicht Skript, Papier-Beispiel und Bogen an. | Felix, Aylin |
| 2 | **Orte auf der Karte beschriften.** „Mühlbach–Kornfeld“, „Kreuzung Südfeld“, „Hafen-Ost“ und die Abschnittsnummern 31–34 stehen im Text, aber nicht auf der Karte (2 Personas). Sonst messen wir Suchen, nicht Lesen. | Felix (Szene), Aylin (Liste der Namen) |
| 3 | **Pfad und Stand des Builds bestätigen.** Basti nennt `f04-signal`, Felix' Anleitung nennt den F-06-Ordner `spike/`. Felix trägt den echten Pfad in die Anleitung ein und bestätigt, dass die Sprint-3-Änderungen (F-10) F-06 nicht verändern. | Felix |
| 4 | **Godot 4.7.2 auf Bastis Rechner**, `run_smoke.sh` einmal laufen lassen (Exit 0), F5-Start bei 1080p prüfen. Es gibt keinen Export, der Test läuft über das Godot-Programm. | Daniel |
| 5 | **Zeile „WURZELURSACHE“** ist im Build als solche beschriftet und verrät, dass die letzte Zeile die Antwort ist. Entscheidung Lena: bleibt, weil das Produkt so aussieht und wir genau das testen. Der Bericht weist dafür den Anteil der Nur-letzte-Zeile-Leser und den Deckeneffekt aus. Einspruch bis 28.11. an Jonas. | Lena (entschieden), Aylin |
| 6 | **Zählregeln gegenzeichnen** (Spalte `zeilen_vorgelesen`, „(12 von 40)“ in der Ladezeile, Ort nach Regel D9). Zeile 5 bei Fehler 3 muss im Build stehen, sonst ist Fehler 3 unlösbar. | Lena, Daniel |

## Papier-Prototyp (L-05)

| Nr | Punkt | Wer |
|---|---|---|
| 7 | Druckdateien setzen (Layout fehlt), Spielgeld, Marker und Kreisschablone besorgen oder beilegen. | Lena (Dateien), Aylin (Layout, 1 h) |
| 8 | Tarife prüfen: Sie gelten mit den Zahlen vom 18.11., Tobias bestätigt, dass sich nichts geändert hat. | Tobias |
| 9 | Kohlemine „ohne eigenen Ertrag“ kann verwirren. Bleibt, wird als Verwirrung notiert. | keiner |

## Organisation

| Nr | Punkt | Wer |
|---|---|---|
| 10 | Termine für 6 + 2 L-06-Tester und 3 L-05-Mitspieler bis 30.11. festmachen. **Risiko:** Build kommt am 01.12., Ergebnisse sind am 02.12. um 12 Uhr fällig, das sind rund 4 Stunden Test an einem Tag plus Vormittag. Rutschen die Termine, meldet Basti das am 01.12. abends an Lena. | Katrin, Basti |
| 11 | Einwilligungstext prüfen (3 Sätze, bisher nicht juristisch geprüft). Zweite Person für L-05 klären. | Katrin |
| 12 | Aufnahme: OBS-Kurzanleitung für Basti (Bildschirm und Ton), sonst reicht Handy-Ton. Ohne Aufnahme kann Lena Grenzfälle nicht nachprüfen. | Daniel |
| 13 | Rot-Grün-Schwäche: Statusfarben sind im Testbuild nicht unterscheidbar (Formen S-05 fehlen). Kein Hindernis für den Test, aber Basti fragt bei der Rekrutierung und notiert es. | Sophie, Daniel (Farbcheck) |
| 14 | Auswertung der Bögen und Logs für den Bericht. | Lena, Aylin (L-09) |
