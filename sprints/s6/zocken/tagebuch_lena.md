# Spieltagebuch Lena – Mittelfurt (Slice Sprint 6)

Gespielt: 50:06 Spielzeit, 22 Läufe, Start Mittelfurt (12.000 Einw.). Alle 7 Ziele (M7) nach 12:06 durch. Kein Bankrott, Kasse nie unter 5.000 $.
Screenshots: `tagebuch_lena_umsetzen.png` (HQ-Umsetzen-Modus), `tagebuch_lena_westcluster.png` (Kohle/Stahl-Cluster), `tagebuch_lena_zug_ende.png` (Stand 50 min, 13 Fahrzeuge).

## Verlauf (Spielzeit / Kasse)
- 0:00 / 6.000 $: HQ Mittelfurt gegründet. Vorschau-Panel ist klar. Klick auf Farm 3 startet HQ-Umsetzen (bekannt). Ich habe es genutzt, um Haberau als Alternative anzusehen: Panel nennt Radius, Kette, Lizenzfaktor und Fluss; das ist informativ. Die Taste "HQ hierher umsetzen" gibt es als Befehl nicht, ich konnte also nicht wirklich umsetzen (Werkzeug-Lücke).
- 2:06 / 6.000 $: `wait 2.1`, dann Lizenz Farm 3 gratis. Ziel 2/7.
- 2:06 / 5.020 $: Straße Farm 3 → Mühle 2, 78 Felder, 980 $. Das ist ein Sechstel der Kasse.
- 2:06–7:06 / 5.648 $: Lkw-Linie läuft, erste Lieferung 2:40, Ziele 6/7 um 4:16. +125 $/min.
- 7:06: Mühle 2 hat Mehl 60 im Lager, ich brauche die Lizenz (140 $). `road muehle_2 mittelfurt` scheitert mit "Gebäude im Weg: Mittelfurt", `road mittelfurt muehle_2` klappt (530 $). M3 um 7:37, +326 $/min. Das ist die erste echte Gewinnlinie.
- 12:06 / 7.236 $: 7/7 Ziele. Zweiter Lkw auf Farm-3-Linie verdoppelt den Gewinn.
- 17:06 / 11.5k: Farm 1 (Lizenz 328 $, Straße 1.490 $) zu Mühle 2.
- 22:06: Kredit +500 $ probiert: Zins 5 $/min, also 1 %/min. Sofort getilgt. Zweiter Mehl-Lkw: +326 → +708 $/min. Farm 2 per 18-Felder-Straße angeschlossen.
- 28:06 / 17.3k: West-Cluster: Lizenzen Kohle 696, Erz 1.260, Stahl 2.584 $, drei Straßen ca. 1.640 $, drei Lkw-Linien. Stahl → Werkzeugfabrik bringt +409 $/min, Rohstofflinien nur +80..90.
- 34:06 / 19.8k, 42:06 / 31.9k: zweite Lkw auf Kohle/Erz, Kohle → Kraftwerk.
- 42:06: Gleis Farm 2 → Mühle 2: 128 Felder, 6.320 $. Zug-Linie 50:06: **+1.091 $/min** gegenüber +100 $/min mit Lkw auf fast gleicher Strecke.
- 50:06 / 44.1k: 13 Fahrzeuge, Kosten 1.234 $/min, Einnahmen ca. 98k gesamt. Ende.

## Die 3 besten Momente
1. **7:37, erste Mehlladung in Mittelfurt (M3).** Die Kette Getreide → Mehl → Stadt geht auf, und die Mehllinie ist mit +326 $/min sofort doppelt so gut wie alles davor.
2. **Zug-Linie 42:06.** 6.320 $ für das Gleis, danach +1.091 $/min. Das ist der "Aha, deshalb gibt es Züge"-Moment. Echte Investitionsentscheidung mit klarer Belohnung.
3. **28:06 West-Cluster.** Rohstoffe liefern allein wenig, erst das Stahlwerk-Ende (+409 $/min) lohnt. Das zu entdecken war die einzige echte Planung im Spiel. Auch der Lizenz-Preissprung (Farm gratis, Stahl 2.584 $) macht Außenposten zu Risiko.

## Die 3 schlechtesten Momente
1. **Nach 12:06: "Alle Ziele erreicht. Weiter: zweite Kette oder Mittelfurt beliefern."** Keine neuen Ziele, kein Fernziel, kein Ranking. Ab hier habe ich 38 Minuten nur dieselbe Handlung wiederholt (Lizenz, Straße, Linie, Lkw dazu). Es gibt nichts zu gewinnen oder zu verlieren.
2. **Zug dominiert alles.** +1.091 vs. +100 $/min. Wer das einmal weiß, baut nur noch Gleise; Lkw-Linien über 80 Felder sind danach Verschwendung. Keine Entscheidung mehr.
3. **Kein Druck.** Kasse wächst von Minute 7 an ohne Einbruch (6k → 44k), Kredit ist unnötig und teuer (1 %/min), Bankrott praktisch nicht möglich. Die ersten 12 Minuten waren spannend (1.000 $ Straße bei 6.000 $ Kasse), danach nur noch Warten mit `wait 6`.

## Bugs
| # | Schwere | Beschreibung | Reproduktion |
|---|---|---|---|
| 1 | mittel | Straße kann nicht **zu** einer Stadt gebaut werden ("Gebäude im Weg: Mittelfurt"), in umgekehrter Richtung schon. Ohne die Straße meldet die Lkw-Linie "Keine Straßenverbindung", obwohl eine Straße am Stadtrand vorbeiführt. | `found_hq` (Mittelfurt), `wait 2.1`, `buy_licence farm_3`, `road farm_3 muehle_2`, `buy_licence muehle_2`, `road muehle_2 mittelfurt` → Fehler; `road mittelfurt muehle_2` → ok |
| 2 | niedrig | `list` meldet Mühle/Stahlwerk als "Lizenz: nicht nötig (Abnehmer)", im Panel kostet die Lizenz 140 $ bzw. 2.584 $ und Laden ist gesperrt. | `list`; `click muehle_2` |
| 3 | niedrig | Panel "Ertrag ca. X $/Monat" ist irreführend: Kohle 696 $ Lizenz bei "192 $/Monat", Farm 1 328 $ bei "156 $/Monat" – sieht wie Verlustgeschäft aus, war aber profitabel. Unklar, was "Monat" heißt. | `click kohle_1`, `click farm_1` |
| 4 | niedrig (UI) | Obere Leiste läuft rechts aus dem Bild (8×-Knopf abgeschnitten) sobald "1 Skillpunkt gespart" erscheint; Linienliste links bricht bei 9 Linien mit "… 1 weitere Linien" ab, keine Scrollmöglichkeit. | siehe `tagebuch_lena_zug_ende.png` |
| 5 | niedrig (Grafik) | Berg im Westen ist ein weißer Pixel-Blob mit sichtbarem Rauschen/Schnee-Fransen, überdeckt Erz/Kohle halb; wirkt wie ein Platzhalter. | `camera kohle_1 6` (bzw. `tagebuch_lena_westcluster.png`) |
| 6 | niedrig (Tool) | HQ-Umsetzen-Knopf ist per Befehl nicht auslösbar, daher nicht vollständig testbar. | `click farm_3` direkt nach `found_hq`, dann `click haberau` |
| 7 | bestätigt | Farm 3 auf HQ-Ring, Klick startet HQ-Umsetzen. | `found_hq`, `click farm_3` |

## Design-Fragen für Refinement Sprint 7
- **Was ist das Spiel nach M7?** Es fehlen Fernziele, Szenarien, Konkurrenz oder wenigstens ein Zielkurs (z. B. 100k bis Minute X). Die Zielleiste sagt "Alle Ziele erreicht" und sonst nichts.
- **Zug vs. Lkw:** Soll der Zug 10× rentabler sein? Dann braucht Lkw eine eigene Rolle (billig, flexibel, Kurzstrecke) oder Gleise brauchen Nachteile (Unterhalt, Brücken, Weichen).
- **Kosten/Risiko:** Laufende Kosten 1.234 $/min sind bei 100k Einnahmen kein Druck. Gibt es Pannen, Preisverfall, Lizenzverlängerung mit Preisanstieg? Ich habe keine Lizenzverlängerung bemerkt (Farm 3 lief bei 32:06 ohne Meldung).
- **Wohin mit dem Geld?** Ab 20k gibt es nichts, das ich nicht schon gebaut hätte. Was kostet "mehr"? Stadtwachstum, Upgrades der Industrie (Stufe 2), neue Waren?
- **Städte als Spielobjekte:** Mittelfurt nimmt Mehl, aber ich sehe nicht, was die Stadt davon hat (wächst sie? will sie mehr?). Städte sind für mich nur Zielpunkte.
- **Bezahlung nach Luftlinie ab Herkunft:** Das belohnt lange Linien. Ist das gewollt, wenn Farm 2 mit 149 Feldern Wegstrecke ~100 $/min bringt?
- **Kredit:** 1 %/min ist so hoch, dass man ihn nie braucht. Entweder früh nötig machen (teurere Start-Straße) oder Zins senken.
- **Erster Eindruck von Basti (Feedback 01.11., mir aufgefallen):** Punkt 1/5 (Proportionen) sehe ich ebenfalls: Mittelfurt ist ein kompakter Voxel-Klotz, die Straßen daneben wirken breit. Punkt 9 (Terrain): flach bis auf den weißen Blob-Berg; Fluss ist ein blaues Band. Die Industrie-Verteilung (Punkt 6) zeigt sich sehr deutlich: der Westen ist "die Bergbau-Ecke", der Süden "die Weizen-Ecke", also genau die Stadt-Spezialisierung, die er nicht will.

## Gesamturteil
**Würde ich weiterspielen? Nein, noch nicht:** Die ersten 12 Minuten mit knapper Kasse und der Mehl-Kette sind gut, aber nach M7 und dem ersten Zug wiederholt sich alles ohne Druck und ohne Ziel; mit Zielen nach M7 und einem Gegengewicht zum Zug würde ich sofort wieder einsteigen.
