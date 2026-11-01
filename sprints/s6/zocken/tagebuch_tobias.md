# Tagebuch Tobias Brandt – Zocker-Session Slice, Start Kohlberg (ca. 31 Läufe)

M7 (HQ Stufe 2, 12.000 $) gibt es im Slice nicht. Proxy hier: Kasse >= 12.000 $ ohne offenen Kredit. M7-Modellwert Kohlberg: 33-36 min (Block B: 24 min).

## Partie 1: "normale gute" Partie (Ordner s1-s9, s8/x5 fortgeschrieben)
Weg: HQ Kohlberg, `esc`, `wait 2.1` (HQ-Ring-Falle, siehe Bugs), Kohlemine-Lizenz (0 $, im Radius), Straße+Lkw Kohle>Kraftwerk, Erz+Stahlwerk-Lizenz (126+280 $), Linien Erz>Stahl, Kohle>Stahl, Stahl>Werkzeug, ab 18 min Kette Farm 3 > Mühle 2 > Mittelfurt.
| Spielzeit | Kasse | Linien / Stand |
|---|---|---|
| 5:06 | 5.988 $ | 1 Lkw Kohle>Kraftwerk +92 $/min, 6 Lieferungen |
| 8:06 | 3.817 $ | 3 Linien, Stahl>Werkzeug noch ohne Fracht (Kohle>Stahl fehlte) |
| 10:06 | 5.927 $ | 4 Linien, alle 7 Ziele (M3) |
| 18:06 | 7.032 $ | 5 Lkw, netto ca. +200 $/min |
| 28:06 | 8.594 $ | + Farm 3>Mühle 2 (+125) und Mühle 2>Mittelfurt (+268 $/min je Lkw) |
| 38:06 | 16.329 $ | 9 Lkw, Einnahmen 1.831 $/min |
| 48:06 | 23.214 $ | 12 Lkw, ca. +970 $/min netto |
Proxy-M7 bei ca. 33 min (Modell 33-36): passt, aber nur mit dem Mittelfurt-Ast. Reine Kohlberg-Kette (Kohle/Erz/Stahl/Werkzeug) liefert nur ca. +200 $/min netto und bräuchte ca. 43 min: Kohle>Kraftwerk +8..+90, Kohle>Stahl +/-0, nur Erz>Stahl (+88) und Stahl>Werkzeug (+130..+260) tragen. Bankrott in keiner Partie, tiefster Stand 3.747 $.
Vergleich Modell: Zeit passt, Tonlage nicht: Modell lässt Werkzeugabsatz Kohlberg tragen (Block-B-Fund: M7 24 min). Im Spiel trägt Mittelfurt, nicht Werkzeug. Lizenzen außerhalb des Radius sind teuer (Farm 3 766 $, Mühle 2 1.064 $, Farm 1 676 $).

## Exploits
### E1 (relevant): Mittelfurt-Direktkette, Kohlberg-Kette komplett überspringen
Folge (Ordner o1/o2): `hover kohlberg; click kohlberg; found_hq; esc; speed 1; wait 2.1; credit+ x4; buy_licence farm_3; buy_licence muehle_2; road farm_3 muehle_2; truck_line farm_3 muehle_2; road mittelfurt muehle_2; truck_line muehle_2 mittelfurt` (beide Gratis-Lkw), nach 8 min je 1 Lkw nachkaufen.
Ertrag: 18:06 Kasse 12.858 $ (mit 2.000 $ Kredit; netto 10,9k), 19:06 11.470 $ schuldenfrei, Proxy-M7 bei ca. 20 min (Modell 33-36, also ca. 40 % schneller). Zinsen kosten nur 20 $/min. Bankrott-Risiko praktisch null (360 $/min Kosten, +880 $/min Einnahmen). Das HQ in Kohlberg ist dabei wertlos, Standortwahl wird egal. Ursache: Mittelfurt zahlt für Mehl (Nachfrage 120 E/min, 60 Felder = +215 $/min je Lkw) ein Vielfaches der Kohlberg-Linien (+10..+90).
Grenze (Sättigung greift): ab 2 Lkw Mühle>Mittelfurt bringt jeder weitere nichts (2 Lkw +450, 4 Lkw +304 $/min, Kasse nach 10 min 14,9k statt 16,3k). Farm>Mühle skaliert dagegen (4 Lkw +510). Farm 1 (124 Felder) zusätzlich: +348 $/min mit 3 Lkw, hebt aber Mühle>Mittelfurt nicht (+436). Plateau ab ca. 20 min: netto +500..+900 $/min, Einnahmen sinken (879 -> 647 $/min bis min 40). Mühle 1 ist durch Wasser von Mittelfurt getrennt (Brücke max. 8 Felder), also kein zweiter Mehl-Ast.
### E2: Kredit
`credit+` x4 bei Start: Zins 1 %/min (5 $ je 500 $), keine Gebühr, Tilgen frei. Tilgen/Aufnehmen-Schleife bringt nichts (kein Gewinn aus Schleife), aber Zins ist gegen Renditen von 100+ %/10 min lächerlich: Kredit ist immer richtig. Kein Exploit, ein Balancing-Punkt.
### E3: Linie löschen/neu (Ordner x1)
Gratis-Startlkw: Auflösen erstattet 0 $, Gratis-Zähler kommt nicht zurück (2 Gratis-Lkw sind danach weg). Bezahlte Lkw: +200 $ (50 %). Schleife kostet 200 $ je Runde, kein Gewinn. Falle für Spieler: Auflösen der ersten Linie vernichtet den Gratis-Lkw.
### E4: Lkw-Masse
10 Lkw auf Kohle>Kraftwerk: -741 $/min. 4 Lkw auf Stahl>Werkzeug (Ausgang begrenzt): -38 $/min statt +141 bei 2. Nicht profitabel, Bankrott-Treiber (bekannt).
### E5: Lager / Mittelfurt als Abnehmer
Mittelfurt nimmt nur Mehl ("nimmt von Stahlwerk nichts an"). Lager baut (Meldung "nehmen alles an, zahlen erst beim Endabnehmer"); Sättigungsumgehung über Lager nicht nachgewiesen (ohne Brücke Mühle 1 nicht anschließbar). Straße Stahlwerk-Mittelfurt (221 Felder, 2.360 $) ist reine Geldverbrennung, nichts zu holen.
### E6: HQ-Umsetzen
Vorschau-Text bietet "HQ hierher umsetzen / kostenlos" in der 2-min-Frist, Zeit steht. Werkzeug kann den Knopf nicht klicken, nicht getestet. Folge aus E1: ein Umsetzen nach Mittelfurt im Fenster wäre noch stärker (Lizenzfaktor x0,70 auf Farm und Mühle: -570 $).

## Bankrott-Erlebnis (Ordner b1, Screenshot tagebuch_tobias_bankrott.png)
Folge: Gründung, Kohle-Lizenz, Straße, 10 Lkw auf Kohle>Kraftwerk, `wait 5`. Bankrott nach 5:29 Spielzeit, 3:23 min nach dem Kauf. Kasse -1 $, Einnahmen 1.027 $, Ausgaben 7.028 $, Unterhalt 900 $/min. Lesbarkeit: Overlay nennt Kasse, Zeit, Einnahmen, Ausgaben, Fahrzeuge und Unterhalt, der Grund ist erkennbar ("Fahrzeuge 10 / 900 $/min"), aber nicht als Ursache benannt. Das Spiel warnt vorher nicht (Linie -741 $/min im Panel ist unauffällig, Kasse sinkt 6.000 -> 0 ohne Toast), Kredit lag unbenutzt (2.000 $ hätten 2 min Zeit gekauft; Overlay: "Kredit vorher aufnehmen"). Fühlt sich schnell und hart an, aber fair und selbstverschuldet; "Neu starten" ist sofort da. Ein Spieler mit der 4er-Stahl-Falle bankrottiert nicht, er dümpelt (Kasse 6.200 $ bei 28 min).

## Bugs / UX
1. HQ-Ring-Falle: `click kohle_1` in den ersten 2 min startet HQ-Umsetzen, Zeit steht (Kohlberg: Kohlemine im Ring, der erste Zielklick). Panel öffnet nicht, Spieler hängt. Bekannt aus play_help, für Kohlberg Standardweg.
2. `road muehle_2 mittelfurt` scheitert ("Gebäude im Weg: Mittelfurt"), `road mittelfurt muehle_2` klappt. Richtungsabhängig, nicht erklärt.
3. Ziel "Lkw-Linie Kohlemine -> Kraftwerk" wird von beliebiger erster Lkw-Linie abgehakt (o1: Farm 3>Mühle 2), Ziel-Text trügt.
4. Linien-Gewinn Kohle>Kraftwerk fällt von +92 auf +14 $/min nach 2. Lkw, ohne Hinweis auf Sättigung/Wartezeit.
5. Nachfolge Ziele: nach 7/7 "Weiter: zweite Kette oder Mittelfurt beliefern" ohne Hinweis auf Weg (Straße von Stadtseite).

## Balancing-Vorschläge Sprint 7
1. E1 schließen: Mehl-Absatz Mittelfurt je Lieferung sinken (Fernzuschlag begrenzen) oder Lizenz Farm 3/Mühle 2 für Nicht-Mittelfurt-HQ deutlich teurer (x1,5), Ziel: Proxy-M7 Kohlberg 30-40 min auch mit Mittelfurt-Ast.
2. Kredit-Zins auf 3 %/min oder Rahmen an Fahrzeugzahl koppeln, damit Dauerkredit nicht gratis ist.
3. Werkzeug-/Stahl-Kette (+130..+260 $/min) hat im Spiel zu wenig Gewicht: Kohle>Stahl liefert 0 $, nur Zubringer; Vorschlag: Stahl-Preis +30 % oder Kohle>Stahl-Zubringer-Bonus, sonst ist Kohlbergs Start schlechter als Mittelfurts Fernast.
4. Bankrott-Warnung: Toast bei Kasse < 2 Minuten Unterhalt und rote Linie bei Gewinn/min < 0.
5. Gratis-Lkw nicht bei Auflösung verfallen lassen.

## Gesamturteil
Die ehrliche Kohlberg-Kette passt zum Modell (M7 ca. 33-43 min, Bankrott nur mit Absicht), aber die Mittelfurt-Mehlkette per Kredit macht M7 in 20 min und entwertet Standortwahl und Kohlberg-Kette.
