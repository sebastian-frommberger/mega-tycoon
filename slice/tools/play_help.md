# Zocker-Session – Spieleranleitung

Du spielst den Slice in Zügen: Befehl an `commands.txt` anhängen, `tools/play.sh <ordner>` starten,
`shot.png` und `state.md` ansehen, nächsten Befehl wählen.

```
tools/play.sh /tmp/claude-0/gd/sprint6/zocken/<name>      # Ordner mit commands.txt
```

- Jeder Lauf startet das Spiel **frisch** und spielt **alle** Zeilen von vorn ab (deterministisch: gleiche
  Befehle ergeben den gleichen Stand). Leerzeilen und `#Kommentare` werden übersprungen.
- Ergebnis nach dem letzten Befehl: `shot.png` (1600×900), `state.md` (Spielstand), eine Zeile in `log.md`,
  Konsolen-Log in `run.txt`.
- Dauer: ca. 22–25 s für den Beispiel-Durchlauf (davon ~5 s Start + Schlussbild), je UI-Befehl 0,3–2 s, `wait 30` ca. 2 s.
- Die Spielzeit läuft **nur** bei `wait`. Alle anderen Befehle passieren in derselben Spielsekunde.

## Befehle

IDs zeigt `list` (z. B. `haberau`, `farm_1`, `muehle_1`). Statt der ID geht auch der Anzeigename mit
`_` statt Leerzeichen (`getreidefarm_1`).

| Befehl | Was passiert (Weg im Spiel) |
|---|---|
| `list` | schreibt alle Städte/Industrien mit ID, Typ, Feld, Lizenzstatus und Lizenzpreis in `state.md` |
| `hover <id>` | Maus über Stadt/Industrie fahren (vor der Gründung: HQ-Vorschau rechts) – **echte Maus** |
| `click <id>` | Mausklick: vor der Gründung wählt er eine Stadt, danach öffnet er das Info-Panel – **echte Maus** |
| `found_hq` | Klick auf den Knopf „HQ hier gründen“ im Vorschau-Panel – **echte Maus** |
| `buy_licence <id>` | Klick auf die Industrie, dann auf „Lizenz kaufen“ im Panel – **echte Maus** |
| `road <a> <b>` / `rail <a> <b>` | Werkzeug „Straße“/„Gleis“ in der Leiste anklicken, Maustaste auf A drücken, zu B ziehen, loslassen – **echte Maus** (Kamera schwenkt beim Ziehen mit, wie WASD) |
| `warehouse <x> <y>` | Werkzeug „Lager“, Klick auf Feld x,y (2×2, freie Ebene) – **echte Maus** |
| `truck_line <a> <b>` / `train_line <a> <b>` | Werkzeug „Lkw“/„Zug“, Klick auf Quelle A, dann Ziel B; kauft ein Fahrzeug – **echte Maus** |
| `remove_line <a> <b>` | Papierkorb an der Linie in der Linienliste links anklicken (Fahrzeuge verkauft, 50 % zurück) – **echte Maus** |
| `credit +` / `credit -` | Knopf [+] / [−] am Kredit oben – **echte Maus** |
| `speed 0\|1\|2\|4\|8` | Tempo-Knopf oben rechts – **echte Maus** |
| `esc` | Taste Esc (Wahl/Werkzeug/Panel abbrechen, HQ-Umsetzen abbrechen) – **echte Taste** |
| `wait <min>` | Spielzeit vorspulen (Minuten, Kommazahl erlaubt). **Abkürzung:** läuft über die Sim-Ticks des Spiels, nicht in Echtzeit; das Tempo zählt dabei nicht, nur Pause (Tempo 0) blockiert |
| `camera <id> [zoom]` | Kamera auf ein Ziel fürs Bild (Zoom 0,4–26; Default 3,2; Start-Übersicht 16). **Abkürzung** statt WASD/Mausrad |

Die Kamera fürs Bild folgt dem letzten Befehl (Strecke/Linie: beide Enden im Bild; Klick: auf das Ziel).
Muss die Maus ein Ziel treffen, das nicht frei im Bild liegt, schwenkt die Kamera vorher dorthin.

**Bekannte Falle (Spiel, nicht Werkzeug):** In den ersten 2 Spielminuten nach der Gründung (bis zur ersten Lizenz)
ist der HQ-Ring klickbar. Liegt eine Industrie auf dem Ring (z. B. Getreidefarm 3 bei HQ Mittelfurt), startet ein
Klick auf ihre Mitte das HQ-Umsetzen statt ihr Panel zu öffnen. `state.md` meldet das; `esc` und dann z. B. `wait 2.1`.

## state.md

Spielzeit/Tempo, HQ, Kasse, Kredit, Einnahmen und Fahrtkosten der letzten Spielminute, laufende Kosten/min,
Fahrzeuge, Linien (Gewinn/min, Status, was die Fahrzeuge gerade tun), Ziele mit Haken, „Nächster Schritt“,
Text des offenen Panels (inkl. Knöpfe, gesperrte markiert), Hinweisleiste, Werkzeug, letzte 12 Meldungen
(Toasts und erreichte Ziele mit Spielzeit), Bankrott, Fehler des letzten Befehls und frühere Fehler.
„Fehler“ heißt: der Befehl hatte keine Wirkung; den Grund hängt das Werkzeug als „Spiel meldet: …“ an, wenn das Spiel einen Toast zeigt.

## Beispiel-Durchlauf

```
list
hover haberau
click haberau
found_hq
buy_licence farm_1
road farm_1 muehle_1
truck_line farm_1 muehle_1
wait 10
click muehle_1
```

Ergebnis (Referenz `/tmp/claude-0/gd/sprint6/zocken/beispiel/`): 10:00, Kasse 6.018 $, 1 Lkw-Linie +45 $/min,
20 Lieferungen, 6 von 7 Zielen, Panel Mühle 1 offen (Lizenz 140 $). Nächster Zug z. B. `truck_line farm_1 muehle_1` (zweiter Lkw) oder `buy_licence muehle_1`.

Tipp: Für Experimente einen Ordner kopieren und dort weiterspielen – `log.md` bleibt pro Ordner.
