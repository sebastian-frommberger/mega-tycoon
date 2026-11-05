# L1: Start, Tempo, Gelände (ca. 10 min, Tag 4)

Hallo Basti, das ist die erste von drei Karten für Sprint 8. Kein Test mit Prüfung: Was dich stört, ist unser Fehler. Zwei Dinge vorab, ehrlich: **(1)** Der Stand liegt nur auf dem Branch `s8`. Auf deinem Rechner ist er erst da, wenn du ihn holst. **(2)** Für die Tempo-Messung (Aufgabe 3) laufen die Verknüpfungen mit der festen Kette Gut Kuppenhof → Erlenmühle → Erlenbach (`--kette=fest`), du schaust und stoppst. Eigenes Bauen und Kaufen gibt es in einer **Rohfassung** (Aufgabe 6, freiwillig): Das Spiel ist noch nicht ausbalanciert, Pleite kann vorkommen, das ist erwartet.

## Einmal einrichten (ca. 5 min)
1. Eingabeaufforderung in `C:\Dev\mega-tycoon`: `git fetch` und `git checkout s8` und `git pull`. Meldet git, es gebe `s8` nicht, ist er noch nicht hochgeladen: dann sag Bescheid. Meckert git wegen eigener Änderungen: nichts erzwingen, sag Bescheid.
2. Godot 4.7.2 starten, Ordner `C:\Dev\mega-tycoon\slice` öffnen, warten bis der Import fertig ist, Godot schließen.
3. **Drei Verknüpfungen** zur Godot-Datei anlegen (Rechtsklick → Verknüpfung erstellen), „MT Tempo A“, „MT Tempo B“ und „MT Tempo C“. Rechtsklick → Eigenschaften → Feld **Ziel**, hinter den Dateipfad anhängen:
   - A: ` --path "C:\Dev\mega-tycoon\slice" -- --tempo_k=4 --kette=fest`
   - B: ` --path "C:\Dev\mega-tycoon\slice" -- --tempo_k=8 --kette=fest`
   - C: ` --path "C:\Dev\mega-tycoon\slice" -- --tempo_k=20 --kette=fest` (deutlich langsamer, ein Fuhrwerk wie ein Auto im Stadtverkehr; wir haben es dazugenommen, weil du gesagt hast, es sei bei 1× viel zu schnell)

   (Das zweite `--` ist richtig: Erst danach liest das Spiel sein Tempo.) Statt der Verknüpfung geht auch im Editor: Projekt → Projekteinstellungen → Editor → Run → **Main Run Args** = `-- --tempo_k=4 --kette=fest`, dann F5. Die Verknüpfungen sind auf einem Windows-Rechner noch nicht getestet. Geht es nicht, sag es und lass F5 mit Main Run Args laufen.

## Aufgaben
**1. Start (1 min).** „MT Tempo A“ doppelklicken, im Startmenü auf **„Welt spielen (Loop S8)“** (Taste P geht auch). Nichts anklicken, **Screenshot** (Windows + Shift + S) mit dem dunklen Feld oben links. Lies ab, was hinter „Gelände:“ steht.

**2. Pause und Tempo (1 min).** **Leertaste** = Pause, oder Knöpfe oben links (Pause, 1×, 2×, 4×). Stehen bei Pause wirklich alle Fahrzeuge? Läuft 4× sichtbar viermal so schnell wie 1×?

**3. Tempo A, B und C (7 min).** Strecke: die **Hinfahrt von Gut Kuppenhof zur Erlenmühle**, rund 500 m. Tempo auf **1×**, Taste **F** drücken, bis im dunklen Feld „folgt Fuhrwerk 1 (Getreide)“ steht. Dort steht auch eine Zeile „Fuhrwerk 1 (Getreide): …“. **Handy-Stoppuhr:** starten, wenn dort **„fährt“** steht, stoppen, wenn dort **„entlädt“** steht. Die erste Fahrt beginnt gleich nach dem Start. Die zweite Fahrt kommt etwa 50 bis 75 Sekunden später (zwischendurch gern auf 4×, vor der Messung zurück auf 1×). Danach das Spiel-Fenster schließen und **„MT Tempo B“**, dann **„MT Tempo C“** starten, genauso messen (C dauert gut eine Minute je Fahrt, dabei gern auf 4× stellen und nur die Fahrt auf 1× stoppen). A sollte am schnellsten, C am langsamsten wirken, die Welt ist sonst dieselbe.

**4. Hügel und Senken (2 min).** Taste **1** (Übersicht), mit **M** kannst du die Häuser ausblenden, mit Q/E drehen. Nenne **3 Stellen**, an denen das Gelände deutlich hoch (Hügel) oder tief (Senke) liegt, zum Beispiel „400 m südlich der Mühle“. Pro Stelle **F12** (oder Screenshot). „Ich sehe keine“ ist eine gültige Antwort.

**5. Stellen merken (1 min).** Fällt dir Boden oder ein Gebäude auf, das schief wirkt: **F12**, ein Satz dazu (siehe Blatt „Stellen melden“, bis heute insgesamt 5).

**6. Freihändig bauen (freiwillig, 10 min).** Starte ohne die Verknüpfungen über den Knopf „Welt spielen (Loop S8)“ (Start ohne Kette, 6.000 $). Klick auf das Gut, **„Linie von hier“**, dann Mühle, dann Erlenbach; Lizenz und Fuhrwerk werden mit angeboten. Dann gern: zweites Fuhrwerk, Kredit, Mühle kaufen, Fuhrwerk ersetzen. Schreib auf, **wo du nicht weiterweißt oder etwas unklar ist** (Text, Knopf, Zahl) und wie viele Klicks du bis zur ersten Lieferung brauchst.

## Deine Antworten
| Frage | Antwort |
|---|---|
| 1 Start über den Knopf | geklappt: ja / teils / nein · Gelände: ______ |
| 2 Pause und 1×/2×/4× | in Ordnung / Problem: ______ |
| 6 Freihändig (optional) | Klicks bis zur ersten Lieferung: ___ · unklar: ______ · Pleite? ja/nein |
| 3 Tempo A (k=4): Dauer der Hinfahrt | Fahrt 1: ___ s · Fahrt 2: ___ s · wirkt: zu schnell / passt / zu langsam |
| 3 Tempo B: Dauer der Hinfahrt | Fahrt 1: ___ s · Fahrt 2: ___ s · wirkt: zu schnell / passt / zu langsam |
| 3 Welches ist glaubwürdiger? | A / B / beide zu schnell / beide zu langsam |
| 4 Hügel/Senken | Stelle 1: ______ (sicher / geraten) · Stelle 2: ______ · Stelle 3: ______ · gefunden: ___ von 3 |
| 5 Stellen | Anzahl insgesamt: ___ |
| Gesamtzeit und wo es gestockt hat | ______ |

**Zurück in den Chat:** dieses Blatt ausgefüllt, den Start-Screenshot und den Ordner `stellen` (gezippt, Lage siehe Blatt „Stellen melden“).
