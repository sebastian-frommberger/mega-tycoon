# Demo starten und spielen (Basti, Windows)

Stand: Branch `s8-demo` (nach dem Merge auch `s8`). Dauer: 5 min einrichten, 30 min spielen.
Ehrlich vorab: Die Startdatei `play_demo.bat` ist auf keinem Windows-Rechner gelaufen (nur Linux getestet). Geht sie nicht, nimm Weg B oder C.

## 1 Stand holen (Eingabeaufforderung in `C:\Dev\mega-tycoon`)
```
git fetch
git checkout s8-demo
git pull
```
Meldet git, es gebe `s8-demo` nicht, oder meckert es wegen eigener Änderungen: nichts erzwingen, sag Bescheid.

## 2 Einmal importieren
Godot 4.7.2 starten, Ordner `C:\Dev\mega-tycoon\slice` öffnen, warten bis der Import fertig ist (Balken unten), Godot schließen.
(Die `.bat` macht das beim ersten Start auch selbst, das dauert dann ein bis zwei Minuten ohne Fenster.)

## 3 Starten (einer von drei Wegen)
- **A, Doppelklick:** `C:\Dev\mega-tycoon\play_demo.bat`. Sie sucht Godot in dieser Reihenfolge: Variable `GODOT`, eine `Godot*.exe` im Repo-Ordner, in `C:\Dev`, dann `godot` im PATH. Findet sie nichts: die Godot-Datei auf `play_demo.bat` ziehen.
- **B, Verknüpfung:** Verknüpfung zur Godot-Datei anlegen, im Feld **Ziel** anhängen: ` --path "C:\Dev\mega-tycoon\slice" -- --demo` (das zweite `--` ist richtig).
- **C, Startmenü:** Spiel normal starten (Editor F5 oder Verknüpfung ohne `--demo`), im Menü **„Demo spielen (30 Minuten)“** klicken oder Taste **D**.

## 4 Spielen: die ersten fünf Minuten
1. Startbild lesen, **Leertaste**. Die Zeit läuft, du bist im Modus „Firmensitz platzieren“.
2. Maus über Erlenbach, Lindenfurt oder Hasenwinkel bewegen: unten steht, was der Platz bringt (Betriebe im Radius, Lizenzpreise, Heimatbonus). **Klick** setzt den Firmensitz.
3. **Gut Kuppenhof** anklicken → **Lizenz kaufen** (die erste im Radius ist gratis) → **Linie von hier** → **Erlenmühle** anklicken → Anlegen → **Erlenbach** anklicken → Anlegen.
4. Nach etwa 90 Sekunden kommt das erste Vertragsangebot: Taste **V**, annehmen.
5. Jeder Meilenstein gibt einen Skillpunkt: Taste **K**, einen Knoten anklicken.
6. Taste **B**: Straße zum Forsthaus Rotwald. Startpunkt am Ende des Fischerpfads (am See), ein Zwischenpunkt östlich um den See herum, Klick auf den Ring am Forsthaus baut.

Die Zeile **„Jetzt möglich“** unter der Werkzeugleiste zeigt immer, was gerade bezahlbar ist. **„Nächster Schritt“** oben nennt den nächsten Meilenstein.

## 5 Tasten
| Taste | Wirkung |
|---|---|
| H | Firmensitz platzieren, danach Panel Firmensitz (Ausbau, Anbauten, Umzug) |
| B / G | Straße / Gleis bauen (Gleis ab 1824). Enter baut bis zum letzten Punkt, Entf nimmt einen Punkt zurück, Esc bricht ab |
| V / K | Verträge / Skilltree |
| F1 | Hilfe (Startbild) |
| Leertaste | Pause. Tempo 1×/2×/4× oben rechts |
| WASD, Q/E, Mausrad, 1–5 | Kamera schieben, drehen, zoomen, Ansichten |
| F | Kamera folgt einem Fahrzeug |
| Esc | schließt das oberste Panel, danach Abfrage „Zurück ins Menü?“ (Speichern gibt es noch nicht) |

## 6 Was wann kommt (3 Minuten = 1 Jahr)
| Minute | Jahr | Neu |
|---|---|---|
| 0 | 1820 | Fuhrwerk, Straße bauen |
| 6 | 1822 | Planwagen (27 E): Fahrzeug anklicken → Ersetzen |
| 9 | 1823 | Betriebe kaufen (aus der Kasse, nicht mit Kredit) |
| 12 | 1824 | Gleis und Pferdebahn (60 E), Kredit |
| 18 | 1826 | Frachtwagen (36 E) |
| 24 | 1828 | Dampfzug (120 E, schneller) |

Die Jahre sind für die Demo vorgezogen (Zeitraffer), historisch stimmen sie nicht.

## 7 Bitte zurückmelden
- Ab welcher Minute wusstest du nicht mehr, was du tun sollst (falls überhaupt)?
- Baumodus: Hat das Einrasten an Straße, Betrieb und Bahnhof beim ersten Mal geklappt? Wenn nein, wo?
- Firmensitz: Hat die Vorschau deine Wahl beeinflusst?
- Skills und Verträge: echte Entscheidung oder Klickarbeit?
- Tempo k = 8: wirkt das Fahrtempo richtig, zu langsam, zu schnell?
- Bildrate oben im Blick behalten (ruckelt es mit Zügen und vielen Linien?). Auf der GPU ist nichts gemessen.
- Alles, was schief aussieht: F12 (Stelle merken) und ein Satz dazu.
