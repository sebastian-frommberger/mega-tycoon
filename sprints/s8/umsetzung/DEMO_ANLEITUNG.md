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

## 4 Spielen: die ersten zehn Minuten

Neu seit dem 11.11.: Linien und Fahrzeuge laufen wie in Transport Fever 2. **Linie anlegen → im Depot kaufen → zuweisen.** Am Betrieb kaufst du keine Fahrzeuge mehr.

1. Startbild lesen, **Leertaste**. Oben mittig steht ein farbiges Banner: „Firmensitz platzieren“. Dieses Banner steht immer da, wenn das Spiel auf einen Klick in die Welt wartet. **Esc** bricht jeden solchen Modus ab.
2. Maus über Erlenbach, Lindenfurt oder Hasenwinkel bewegen: unten steht, was der Platz bringt. **Klick** setzt den Firmensitz. Daneben steht jetzt der **Fuhrhof**, dein erstes Depot (kostenlos).
3. **Linie anlegen:** Taste **L** → „+ Neue Linie“ → „Straße · Güter“. Das Fenster geht zu, das Banner sagt „Halte für Linie 1 anklicken“. Gültige Halte tragen einen Ring und einen farbigen Rahmen am Schild, alle anderen sind abgedunkelt. **Gut Kuppenhof** anklicken, dann **Erlenmühle**, dann **Enter**. Die Linie kostet nichts und hat noch kein Fahrzeug.
4. **Im Depot kaufen:** Im Fenster steht „Noch kein Fahrzeug: im Depot kaufen und zuweisen“. Knopf **„Zum Depot: Fuhrhof am Firmensitz“** (oder den Fuhrhof in der Welt anklicken). Im Katalog bei „Fuhrwerk“ mit **+** die Menge wählen, **Kaufen**. Die Fuhrwerke stehen im Depot und sind gleich ausgewählt.
5. **Zuweisen:** Unter der Liste steht „Zuweisen an:“ mit einem Knopf je passender Linie. Klick auf **Linie 1**: Die Fuhrwerke rücken aus. Mehrere wählst du mit Klick, einen ganzen Bereich mit **Umschalt+Klick**.
6. **Lizenz:** Ohne Lizenz lädt am Betrieb niemand. Das Linienfenster warnt („Lizenz fehlt“) und hat den Kaufknopf gleich daneben. Die erste Lizenz im Radius des Firmensitzes ist gratis.
7. Dasselbe für **Erlenmühle → Erlenbach**: zweite Linie, ein Fuhrwerk im Fuhrhof kaufen, zuweisen. Jetzt kommt Mehl in Erlenbach an, das erste Geld.
8. Nach etwa 90 Sekunden kommt das erste Vertragsangebot: Taste **V**, annehmen. Jeder Meilenstein gibt einen Skillpunkt: Taste **K**.
9. Taste **B**: Straße zum Forsthaus Rotwald. Startpunkt am Ende des Fischerpfads (am See), ein Zwischenpunkt östlich um den See herum, Klick auf den Ring am Forsthaus baut.
10. Stadtverkehr: **Erlenbach** anklicken → „Personenlinie hier beginnen“ → Erlenbach Ostend und Erlenbach Kirchgasse anklicken → Enter. Im Fuhrhof eine Stadtkutsche kaufen und zuweisen.

**„Nächster Schritt“** oben sagt dir, was im Ablauf gerade offen ist (Linie fehlt, Fahrzeuge stehen im Depot, Lizenz fehlt), danach den nächsten Meilenstein. Die Zeile **„Jetzt möglich“** zeigt, was bezahlbar ist.

### Auswahl und Modus
- Es gibt immer genau **eine Auswahl**: ein Betrieb oder Ort, ein Depot, der Firmensitz oder eine Linie. Am ausgewählten Objekt pulsiert ein goldener Ring, sein Schild hat einen goldenen Rahmen; eine gewählte Linie leuchtet als farbige Route.
- **Klick ins Leere** und **Esc** heben die Auswahl auf.
- Fährst du mit der Maus über etwas Anklickbares, bekommt es einen hellen Ring und der Mauszeiger wird zur Hand.
- Ein neuer Modus beendet den alten. Beispiel: Taste B während du Halte anklickst, wechselt sichtbar in den Straßenbau.

### Später
- **Züge** kaufst du im **Lokschuppen**. Jedes Gleisnetz braucht einen eigenen (Taste L → Reiter Depots → bauen → Stelle am Gleis oder Bahnhof anklicken). Ein Depot kostet 250 $ und 5 $/min.
- Weit weg vom Firmensitz lohnt ein **Betriebshof** an der Linie: Neue Fahrzeuge rücken vom nächsten Depot aus und fahren sonst erst quer durchs Land.
- **Taste U:** alle Fahrzeuge. Filter nach Linie, Art und „im Depot“. Sammelaktionen: Linie zuweisen, ins Depot, ersetzen (neues Modell), überholen, verkaufen.
- Fahrzeuge im Depot kosten ein Viertel des Unterhalts und verdienen nichts.

## 5 Tasten
| Taste | Wirkung |
|---|---|
| H | Firmensitz platzieren, danach Panel Firmensitz (Ausbau, Anbauten, Umzug) |
| B / G | Straße / Gleis bauen (Gleis ab 1824). Enter baut bis zum letzten Punkt, Entf nimmt einen Punkt zurück, Esc bricht ab |
| V / K | Verträge / Skilltree |
| L | Fenster Verkehr, Reiter Linien (anlegen, Halte, Ladeauftrag, Fahrzeuge der Linie) |
| U | Fenster Verkehr, Reiter Fahrzeuge (Mehrfachauswahl, Sammelaktionen). Weitere Reiter: Depots, Strecken |
| Enter / Entf | im Linien-Editor: Linie abschließen / letzten Halt zurücknehmen |
| F1 | Hilfe (Startbild) |
| Leertaste | Pause. Tempo 1×/2×/4× oben rechts |
| WASD, Q/E, Mausrad, 1–5 | Kamera schieben, drehen, zoomen, Ansichten |
| F | Kamera folgt einem Fahrzeug |
| Esc | bricht den laufenden Modus ab, schließt sonst das oberste Fenster, hebt dann die Auswahl auf; erst danach Abfrage „Zurück ins Menü?“ (Speichern gibt es noch nicht) |

## 6 Was wann kommt (3 Minuten = 1 Jahr)
| Minute | Jahr | Neu |
|---|---|---|
| 0 | 1820 | Fuhrwerk, Straße bauen |
| 6 | 1822 | Planwagen (27 E): Taste U → Fuhrwerke auswählen → Ersetzen |
| 9 | 1823 | Betriebe kaufen (aus der Kasse, nicht mit Kredit) |
| 12 | 1824 | Gleis, Pferdebahn (Güter, 60 E), Pferdestraßenbahn (Personen, 30 Plätze), Kredit |
| 15 | 1825 | Pferdeomnibus (16 Plätze) |
| 18 | 1826 | Frachtwagen (36 E) |
| 24 | 1828 | Güterzug mit Dampf (120 E) und Personenzug mit Dampf (80 Plätze), beide schneller |

Die Jahre sind für die Demo vorgezogen (Zeitraffer), historisch stimmen sie nicht.

## 7 Bitte zurückmelden
- **Linie → Depot → Zuweisen:** Hast du die erste Linie ohne Hilfe zum Fahren gebracht? Wo hast du gestockt?
- **Banner und Ring:** Wusstest du jederzeit, ob das Spiel auf einen Klick wartet und was ausgewählt ist? Gab es einen Moment, in dem doch etwas „hing“?
- **Mehrfachauswahl:** Klick und Umschalt+Klick wie erwartet? Fehlt Strg+Klick oder ein Rahmen mit der Maus?
- **Depots:** Ist klar, warum ein Zug einen Lokschuppen braucht und wo er stehen muss?
- **Straßenbau:** Der Befund mit 13 Punkten liegt in `DEMO_STRASSENBAU_BEFUND.md`. Welche davon stören dich wirklich, welche nicht?
- Ab welcher Minute wusstest du nicht mehr, was du tun sollst (falls überhaupt)?
- Firmensitz, Skills, Verträge: echte Entscheidung oder Klickarbeit?
- Tempo k = 8: wirkt das Fahrtempo richtig, zu langsam, zu schnell?
- Bildrate oben im Blick behalten (ruckelt es mit Zügen und vielen Linien?). Auf der GPU ist nichts gemessen.
- Alles, was schief aussieht: F12 (Stelle merken) und ein Satz dazu.
