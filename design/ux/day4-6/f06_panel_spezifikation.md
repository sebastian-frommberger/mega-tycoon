# F-06 Testbuild: Textspezifikation Diagnose-Panel (A-05, D14)

Autorin: Aylin Kaya · Stand 20.11.2026 · für Felix (F-06, 23.–24.11., 1 T) · ersetzt den Figma-Teil des A-05-Akzeptanzkriteriums (D14) und baut auf `day1-3/aylin/mini_entwurf.md` auf. Daten: `diagnose_datenvertrag_v1.md`, Texte: `textvorlagen_testfehler_v1.md`.

Was gegenüber dem Mini-Entwurf gilt: **Vorschlag ausgeblendet (D11)**, Titel `T_STEHT` (D11), Sprungziel der Wurzelzeile = `root_pos` (D9), Klick-Log ist Muss mit festem Format (Abschnitt 5). Nicht von Felix bestätigt: ob das in 1 T passt (Katrin B10). Die Streichreihenfolge steht in Abschnitt 7.

## 1. Zweck und Muss-Umfang

Der Test misst, ob ein Tester nach Klick auf die Meldung die Wurzelursache findet. Dafür braucht der Build genau vier Dinge: eine Meldungsliste, die Kette als klickbare Liste, den Kamerasprung zum Ort, und ein Klick-Log mit `t_klick`.

| Stufe | Inhalt |
|---|---|
| **Muss** | Zustände Z1 bis Z3 (Abschnitt 2), Kamerasprung (Abschnitt 4), Klick-Log (Abschnitt 5), Vertragsfehler-Verhalten (Z5), Namen aus Lenas Tabelle |
| **Soll** | Nummerierte Markierungen an allen Kettengliedern, gestrichelte Linie, "Zurück zur Übersicht" |
| **Kann** | Rest der Karte abdunkeln, Klick auf den stehenden Zug öffnet seine Meldung |

## 2. Zustände

Grau-Palette und Maße wie im Mini-Entwurf (`bg_panel #2B2B2B`, `bg_row #383838`, `bg_row_hover #454545`, `bg_selected #F0F0F0` mit Text `#1A1A1A`, `text_main #F0F0F0`, `text_dim #A8A8A8`, Raster 8 px, Panel 400 px breit bei 1080p rechts, 320 px bei 720p, Fließtext 16 px, Titel 18 px fett, Untertitel 14 px, nie unter 14 px).

| Zustand | Was sichtbar ist | Übergang |
|---|---|---|
| **Z0 Leer** | Kopf "MELDUNGEN 0", Text `E_LEER` "Keine Probleme." | nur Vorsorge, im Test nicht erreichbar |
| **Z1 Liste** | Kopf "MELDUNGEN n [−]"; je Meldung eine Zeile 72 px: grauer Block 12×12 px links (Schweregrad-Platz, alle gleich), Titel `T_STEHT`, Untertitel `T_ORT`, Pfeil ">" rechts. Reihenfolge fest nach `meldung_id` (Entstehungsreihenfolge), nicht nach Fehlertyp. Feed beim Start **offen**. | Klick auf Zeile → Z2 |
| **Z2 Meldung offen** | Die Zeile bekommt Rahmen 2 px `#F0F0F0`, Pfeil "v". Darunter Block "WARUM? · Stand m:ss" (Spielzeit des Schnappschusses) mit den Kettenzeilen 1..n, nummeriert, je min. 40 px, ganze Zeile klickbar, Pfeil ">" rechts. Letzte Zeile trägt Label "WURZELURSACHE" und helle Fläche `#F0F0F0`/Text `#1A1A1A`. Bei `is_deadlock`: darunter Textzeile `K_ZURUECK` in `text_dim`, nicht klickbar. **Kein Vorschlagsblock (D11).** Knopf "Zurück zur Übersicht" 40 px (Soll). Mehr als 6 Zeilen: innen scrollen, Kopf und Knopf bleiben. Höchstens eine Meldung offen; Öffnen einer anderen schließt die erste. Beim Öffnen: Kamera fährt zu `links[0].pos` (Zeile 1), Objekt mit Kontur. | Klick auf Kettenzeile → Z3; Klick auf Kopf → Z1; Klick "Zurück" → Z1 + Kamera zurück |
| **Z3 Zeile gewählt** | Gewählte Zeile invertiert (`bg_selected`), Kamera fährt zu ihrem Sprungziel (Abschnitt 4), Objekt mit weißer Kontur 3 px, pulsiert zweimal. Markierung dieser Zeile auf der Karte 32 px statt 24 px (Soll). | Klick andere Zeile → Z3 (neu); Klick Kopf → Z1 |
| **Z4 Eingeklappt** | Klick auf [−]: Panel klappt zu, am rechten Rand bleibt ein Badge "n". | Klick Badge → vorheriger Zustand. Im Test nicht erwartet, aber möglich |
| **Z5 Vertragsfehler** | Pflichtfeld fehlt (Validator V1–V8 des Vertrags): Meldung wird **nicht** angezeigt, Log-Zeile `vertragsfehler`. Im Smoke-Test ist jede `vertragsfehler`-Zeile ein Build-Fehler (Daniel). | – |

Schnappschuss: `get_wait_chain(vehicle_id)` wird beim Übergang Z1→Z2 einmal aufgerufen und bis Z2→Z1 eingefroren. "Stand m:ss" zeigt `erstellt_tick / 10` als Spielzeit.

Meldungsentstehung (Vertrag, Abschnitt 3a): Die UI pollt je Sekunde `deadlock_events` und alle Fahrzeuge in `WARTET_LADUNG` mit `wait_ticks ≥ 600`; je Fahrzeug höchstens eine Meldung; `BLOCK_BELEGT_UNTERWEGS` und `KEINE` erzeugen keine. Im Testbuild sind die drei Meldungen beim Start bereits da (Lena, Abschnitt 3 Nr. 2).

## 3. Kettenzeilen: Text und Sprungziel

Die Verdichtung von `links` zu Zeilen steht im Vertrag, Abschnitt 3b. Je Zeile hält die UI: `index` (1..n), `textschluessel`, ausgefüllten Text, `objekt_typ`, `objekt_id`, `pos` (Sprungziel). Zeile n hat `pos = root_pos` (D9).

| Fehler | Zeilen | Sprungziele in Reihenfolge |
|---|---|---|
| F1 | 4 | Zug 4 · Signal 12 · Zug 2 · kanonischer Block der Strecke |
| F2 | 6 | Zug 5 · Zug 5 · Zug 8 · Zug 6 · Zug 9 · kanonischer Block des Kreises |
| F3 | 5 | Zug 10 · Signal 21 · Zug 7 · Lager Hafen-Ost · Lager Hafen-Ost (Industrie) |

In F2 zeigen Zeile 1 und 2 auf dasselbe Objekt; das ist gewollt (Zeile 1 = Symptom, Zeile 2 = erstes Kreisglied).

## 4. Sprung zum Ort

- Kamerafahrt 0,6 s, weich (ease-in-out), Zielpunkt = `pos` in Weltkoordinaten (`Vector2i` mm → Welt: x = `pos.x / 1000`, z = `pos.y / 1000`, Annahme aus dem Vertrag). Zoom auf eine Stufe, in der ein 200-m-Abschnitt ganz im Bild ist (Annahme; Sophies Zoomstufen-Regel liegt mir nicht vor).
- Ein neuer Klick unterbricht die laufende Fahrt.
- Kontur: weißes Outline 3 px auf dem Zielobjekt (Fahrzeug, Signal, Block-Mitte als Marker, Lager), pulsiert 2× (0,4 s), bleibt dann stehen, bis eine andere Zeile gewählt oder die Meldung geschlossen wird.
- Markierungen (Soll): 24-px-Scheibe mit Zeilennummer an jedem Sprungziel, oberste Ebene, Mindestgröße zoomunabhängig; Symptom = Ring, Zwischenglied = graue Scheibe, Wurzel = Quadrat mit runden Ecken. Linie gestrichelt 2 px in Kettenreihenfolge, bei Kreis geschlossen.
- "Zurück zur Übersicht": Kamera zurück zur Position vor dem ersten Sprung dieser Meldung.

## 5. Klick-Log (Muss, liefert `t_klick` für L-06)

Eine CSV je Session, `user://klicklog_<session>.csv`, Kopf in Zeile 1, eine Zeile je Ereignis, Trennzeichen `;`, sofort geflusht (Absturzsicherheit):

```
unix_ms;ms_seit_start;tick;ereignis;meldung_id;vehicle_id;index;ziel
```

| Spalte | Inhalt |
|---|---|
| `unix_ms` | Wanduhr in ms (`Time.get_unix_time_from_system() * 1000`), für den Abgleich mit der OBS-Aufnahme |
| `ms_seit_start` | ms seit Szenenstart (`Time.get_ticks_msec()`) |
| `tick` | `sim.tick_count` |
| `ereignis` | `session_start` · `meldung_geoeffnet` · `meldung_geschlossen` · `zeile_klick` · `sprung_zurueck` · `feed_eingeklappt` · `feed_ausgeklappt` · `klick_sonstige` · `vertragsfehler` |
| `meldung_id`, `vehicle_id` | bei allen Meldungs-Ereignissen; `vehicle_id` ist der Zug der Meldung (Aufgabenbezug) |
| `index` | bei `zeile_klick`: Zeilennummer 1..n |
| `ziel` | bei `klick_sonstige`: `karte_leer` · `karte_objekt:<typ>:<id>` · `ui:<name>`; bei `vertragsfehler`: verletzte Regel (`V3`, `V6`, …) |

**`t_klick` für die Messgröße** = `unix_ms` der ersten `meldung_geoeffnet`-Zeile mit dem `vehicle_id` der Aufgabe, nach dem Aufgabenende. Zeilenklicks (N-A), `zeilen_vor_nennung` und `fehlklicks` (= `klick_sonstige` zwischen `t_klick` und `t_nennung`) werden aus derselben Datei gezählt. Der Replay ist dafür nicht nötig; wenn Felix Klicks zusätzlich in den Replay schreibt, schadet es nicht.

Beispiel (erfunden):
```
unix_ms;ms_seit_start;tick;ereignis;meldung_id;vehicle_id;index;ziel
1764072001234;0;0;session_start;;;;
1764072045890;44656;446;meldung_geoeffnet;2;5;;
1764072052110;50876;508;zeile_klick;2;5;4;
1764072060400;59166;591;klick_sonstige;;;;karte_leer
```

## 6. Testszene (Eingang von Lena, hier nur verwiesen)

Drei getrennte Teilnetze, Stillstände ≥ 120 s alt beim Start, zwei Kontrollzüge auf dem K1-Layout ohne Meldung, Namen aus Lenas Tabelle, Zusatzfelder `n_lkw`, `streckenlaenge_mm`, `gleiszahl` (Vertrag, Abschnitt 2). Smoke-Test-Punkte (Daniel): 3/3 Meldungen da, jede Kette endet in der Soll-Wurzelzeile, Sprung funktioniert, Klick-Log schreibt `meldung_geoeffnet`, keine `vertragsfehler`-Zeile.

## 7. Streichreihenfolge, wenn 1 T nicht reicht (von unten nach oben streichen)

1. Abdunkeln, Klick auf Zug in der Welt (Kann)
2. Linie zwischen Markierungen
3. Nummerierte Markierungen (Kontur am gewählten Objekt bleibt Muss)
4. "Zurück zur Übersicht" (dann schließt der Kopf die Meldung, Kamera bleibt)
5. Puls der Kontur
6. Z4 Einklappen (dann kein [−]-Knopf)

Nicht streichbar: Z1–Z3, Kamerasprung, Kontur, Klick-Log, Z5.

## 8. Offen

| Nr | Frage | An |
|---|---|---|
| 1 | Passt der Muss-Umfang in 1 T? Was fällt nach Abschnitt 7 raus? | Felix, Daily 20.11. |
| 2 | Zoomstufe für den Sprung (Abschnitt 4) | Sophie |
| 3 | Smoke-Test-Punkte Abschnitt 6 in den Prüfplan | Daniel |
| 4 | Markierungsformen gegen S-05-Formen (Kreis/Dreieck/Achteck) | Sophie, nur Soll |
