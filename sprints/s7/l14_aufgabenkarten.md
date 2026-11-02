# L-14 Aufgabenkarten für Bastis Rundgang durch die neue Welt (Lena, Aylin)

Hallo Basti, das hier dauert etwa 25 Minuten und ist kein Test mit Prüfung: Du läufst durch die neue Welt und sagst uns, ob sie sich nach Railway Empire / Transport Fever anfühlt. Es gibt kein Richtig oder Falsch. Was dich stört, ist unser Fehler. Notier Stichworte, am besten mit Screenshot (F12 oder Windows+Shift+S).

## Start
1. Godot öffnen, Ordner `C:\Dev\mega-tycoon\slice` laden.
2. Oben rechts auf das Zahnrad / Projekt → Projekteinstellungen → Editor → Run → **Main Run Args** auf `-- --welt=s7` setzen (Alternative: „Erweiterte Einstellungen“ an, Mega Tycoon → Welt = `s7`).
3. Play (F5). Beim ersten Start braucht das Gelände wenige Sekunden zum Laden.
4. Zurück zur alten Karte: Eintrag wieder löschen bzw. `slice` setzen.

## Karte 1: Von oben bis zum Haus (ca. 5 min)
**Aufgabe:** Zoom mit dem Mausrad ganz heraus. Dreh dich einmal um die Karte. Dann zoom auf die größte Stadt (Wiesental) bis zu den Häusern und wieder heraus.
**Du siehst:** zwölf Städte, einen Fluss von West nach Ost, Gebirge mit Schnee im Nordwesten. Am Rand geht die Landschaft weiter, die Kamera hört weich auf.
**Laut denken:** Wirkt das wie eine Landschaft oder wie ein Modell? Stimmt das Verhältnis Straße : Haus? Stört etwas am Kartenrand? Sehen die Städte aus der Ferne nach Stadt aus?

## Karte 2: Erste Straße auf eine Stadt (ca. 6 min)
**Aufgabe:** Gründe in Haberau. Kaufe die Lizenz für Getreidefarm 1, baue Straße zur Mühle 1, lass einen Lkw fahren. Dann Lizenz für die Mühle, Straße von der Mühle nach Haberau und eine Linie dorthin.
**Geklappt, wenn:** Oben steht „angeschlossen am Stadtrand Haberau“ und die Ziele links sind abgehakt (etwa nach fünfeinhalb Minuten Spielzeit).
**Laut denken:** Wie sieht das Ziehen einer Straße aus (Vorschau, Kosten, Kurven)? Sind die Straßen schmal genug? Hat dich eine Meldung nicht weitergebracht?

## Karte 3: Industrie-Lage lesen (ca. 4 min)
**Aufgabe:** Such im Nordwesten am Gebirgsfuß das Kohle-/Erz-Revier (Kohlemine 3, Erzmine 3, Stahlwerk 3, Kraftwerk 3). Dann such ein zweites Getreidegebiet an einer ganz anderen Stelle der Karte.
**Du siehst:** farbige Flächen mit Namen und einer Plakette (grün mit Haken = Lizenz, grau mit Schloss = keine).
**Laut denken:** Verstehst du, warum eine Mine am Berg steht und eine Farm in der Ebene? Gibt es dieselbe Ware an mehreren Orten? Wirkt eine Stadt wie „die Weizenstadt“ oder „die Bergbaustadt“?

## Karte 4: Fluss und Brücke (ca. 5 min)
**Aufgabe:** Neu starten, gründe in Seehafen. Baue Farm 2 → Mühle 2 (Straße und Lkw), dann Mühle 2 → Seehafen. Die Strecke quert den Fluss.
**Geklappt, wenn:** Die Brücke entsteht ohne Umweg, Lkw fahren hinüber.
**Laut denken:** Hast du verstanden, wo man den Fluss queren darf? War die Brücke zu sehen? Hat die Meldung bei Problemen eine Lösung genannt?

## Karte 5: Gebirge und „zu steil“ (ca. 4 min)
**Aufgabe:** Neu starten in Altenbruck. Lizenz für Kohlemine 3, dann Straße zum Kraftwerk 3 direkt ziehen. Es kommt „Zu steil“. Bau die Strecke in zwei Teilen um den Hang herum.
**Geklappt, wenn:** Die Linie Kohle → Kraftwerk fährt.
**Laut denken:** Hat dir die Meldung gesagt, was du tun sollst? Fühlt sich das Gelände wie ein Spielelement an (kostet, sperrt, lässt sich umgehen) oder wie ein Hindernis?

## Vier Fragen zum Schluss
1. Wo wirkt die Welt noch wie eine Miniatur, wo schon echt?
2. Wo fühlt sich Gelände, Fluss oder Stadt falsch oder leer an?
3. Fahren die Fahrzeuge zu schnell oder zu langsam im Verhältnis zu den Entfernungen? (Wir haben das Tempo bewusst noch nicht angefasst.)
4. Welche Stelle würdest du als Erstes ändern?

## Rückmeldung zum Ausfüllen
| Karte | Geklappt (ja/teils/nein) | Minuten | Screenshot | Stichwort |
|---|---|---|---|---|
| 1 Von oben bis zum Haus | | | | |
| 2 Erste Straße auf eine Stadt | | | | |
| 3 Industrie-Lage lesen | | | | |
| 4 Fluss und Brücke | | | | |
| 5 Gebirge und „zu steil“ | | | | |

## Für uns (nicht für Basti)
- Alle Befehle der Karten sind mit `tools/play.sh <ordner> --welt=s7` abgespielt (Daniel, `sprints/s7/`), die Reihenfolge der Lizenzen und Straßen steht im Bericht.
- Karte 3 und Karte 4 setzen die Label- und Brückenfixes aus Block D voraus.
