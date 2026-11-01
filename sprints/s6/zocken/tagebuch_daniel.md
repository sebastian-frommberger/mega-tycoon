# Tagebuch Daniel Richter (QA) – Zocker-Session Steinbach

Sessions unter `/tmp/claude-0/gd/sprint6/zocken/spiel_daniel/` (s1–s22, ca. 25 Läufe). Bild: `tagebuch_daniel_45min.png` (Steinbach nach 45 min), `tagebuch_daniel_lager_fluss.png` (Z-03).

## 1. Steinbach-Verlauf
Vorschau: "Wagnis: kein Rohstoff im Radius", Farm 81 / Mühle 139 / Kohle 284 Felder, Lizenzfaktor x1,78, "Kette nur über Fernlizenzen erreichbar. Im Slice nicht balanciert."

Gespielt (Befehle in `s3/commands.txt`, `s20/commands.txt`):
- 0:00 HQ gründen, `buy_licence farm_3`: **gratis** (erste Lizenz), obwohl die Vorschau x1,78 nannte. Straße Farm 3 → Mühle 2: 78 Felder, 980 $. Lkw-Linie (Startpaket-Lkw gratis).
- 0:21 erste Lieferung, 2:45 "3 Lieferungen mit Gewinn" (6/7 Ziele). Kasse nach 5 min: 5.469 $ (Start 6.000), +89 $/min.
- 5:00 Mühle 2 Lizenz 704 $ + Straße zu Mittelfurt 530 $ + Mehl-Lkw. 5:31 M3 erreicht (7/7 Ziele). Mühle→Mittelfurt bringt +326 bis +454 $/min (Stadt 12.000 Einw.).
- 10:00 je 2. Lkw (400 $ je). 20:00: Kasse 13.782 $. 45:00: Kasse 27.776 $, 4 Lkw, 222 Lieferungen, nie Kredit nötig, tiefster Kassenstand 5.469 $ (bei 5:00).

**Urteil:** Spielbar, und zwar leicht. Die Vorschau warnt zu hart: Das "Wagnis" ist faktisch der bequemste Start, weil die erste Lizenz gratis ist und Mittelfurt als Mehlabnehmer riesig ist. Der Weg (Farm 3 → Mühle 2 → Mittelfurt) liegt nur ~80 Felder entfernt; "Fernlizenzen" und "Kette nur über..." sind nicht spürbar. Wer es wirklich schwer will, braucht eine Vorschau, die das Ergebnis nicht verfehlt (oder Wagnis-Aufschläge, die greifen). Nach M3 (5:31) fehlt ein Ziel; "Weiter: zweite Kette" ist der einzige Hinweis.
Bankrott: erreichte ich nur absichtlich (s15: 10 Lager à 800 $ + Kredit 2.000 $ → Kasse 0 → "BANKROTT nach 0:00").

## 2. Spielfehler (Bugliste)
| ID | Schwere | Befund | Reproduktion | erwartet / tatsächlich |
|---|---|---|---|---|
| Z-01 | mittel | Straße, die **auf einer Stadt endet**, wird abgelehnt; umgekehrte Richtung geht | `click steinbach`, `found_hq`, `buy_licence farm_3`, `road farm_3 muehle_2`, `click muehle_2`, `buy_licence muehle_2`, `road muehle_2 mittelfurt` → "Gebäude im Weg: Mittelfurt", `truck_line` danach "Keine Straßenverbindung". Dasselbe mit `road kohlberg lindach`, `road seehafen weidenau`. `road mittelfurt muehle_2` klappt. | Erwartet: Stadt als Ziel wie Industrie. Tatsächlich: nur als Start. Spieler:in erfährt nicht, wie man Städte anbindet. Hinweistext fehlt. |
| Z-02 | niedrig | Kasse zeigt "-0 $" bei Bankrott | s15: 10 Lager, `credit +` ×4, `wait 3` | Erwartet "0 $". |
| Z-03 | niedrig, unsicher | Lager am Flussufer: bei y=300 wird x=382 und x=388 gebaut, x=385 abgelehnt ("kein Platz"); Lager 4 (388) liegt im Bild auf blauen Flussfeldern | `click steinbach`, `found_hq`, `warehouse 376 300`, `warehouse 379 300`, `warehouse 382 300`, `warehouse 385 300`, `warehouse 388 300`, `camera lager_1 1.5` (Bild: `tagebuch_daniel_lager_fluss.png`) | Erwartet: Lager nie auf Wasser. Ob 388 wirklich Wasser überdeckt, konnte ich mit Bild allein nicht sicher klären (2x2-Ursprung unklar). |
| Z-04 | niedrig | Lager auf Kartenecke (0,0) wird gebaut, Beschriftung schwebt im Wasser | `click steinbach`, `found_hq`, `warehouse 0 0`, `camera lager_1 6` | Erwartet: Randfeld abgelehnt oder sinnvoll. 800 $ gezahlt. |
| Z-05 | niedrig | Lizenzverlängerung ohne Meldung | `s21`: Farm 3 Lizenz läuft 30:00 ab, bei 40:18 "noch 19:42" – kein Toast, Kosten nicht erkennbar | Erwartet: Toast "Lizenz verlängert, X $". Ob Mühle 2 (704 $) bei 35:00 bezahlt wurde, kann ich nicht sehen. |
| Z-06 | niedrig | Linie auflösen verkauft gratis Startpaket-Lkw für +0 $ und der Gratis-Platz ist weg | s22: nach 10 min `remove_line farm_3 muehle_2`, `truck_line farm_3 muehle_2` ×2 → 800 $ | Hilfe sagt "50 % zurück"; Toast "+0 $" ohne Erklärung. Möglicherweise gewollt, aber unklar kommuniziert. |
| Z-07 | Hinweis | Vorschau widerspricht Realität (siehe Urteil): x1,78 genannt, Lizenz gratis; "Wagnis" aber leicht | s1 | Balance, kein Absturz. |

Gelungen/ohne Fund: Straße und Gleis über den Fluss (Brücke automatisch), Lager auf Berg/Wasser/Stadt abgelehnt, Kredit-Knöpfe sperren korrekt (Rahmen 2.000, "-" bei 0), HQ-Umsetzen-Modus stoppt die Zeit, `esc` bricht sauber ab (2:00-Grenze überlebt: "HQ jetzt fest" dann bei 2:15), doppelte Linie fasst zu ×2 zusammen, Linie ohne Passung ("nimmt von … nichts an") liefert klare Toasts, kein SCRIPT ERROR in allen Läufen.

## 3. Werkzeug (play.sh) – getrennt von Spielfehlern
| ID | Mangel |
|---|---|
| T-01 | Kein Befehl für "HQ hierher umsetzen" und kein Klick auf den HQ-Ring: Umsetzen lässt sich nur auslösen (über Farm 3 bei HQ Mittelfurt), nie abschließen. `found_hq` meldet im Modus "HQ schon gegründet". Die Frage "Umsetzen an der 2-min-Grenze" ist damit nur halb prüfbar (Zeit steht im Modus, Grenze wurde nicht überschritten). |
| T-02 | `speed 8` hat keine Wirkung auf `wait` (Abkürzung über Sim-Ticks). "Tempo 8 über lange Zeit" ist im Echtbetrieb nicht testbar; Befehl `speed` nur fürs Bild. |
| T-03 | Kein Weg, Werkzeug-Zwischenzustände zu prüfen (Esc *mitten* im Ziehen, Doppelklick): jeder Befehl ist atomar, Werkzeug steht danach immer auf "Auswahl". Esc/Doppelklick nur als Einzelbefehl getestet. |
| T-04 | `warehouse` nimmt Feldkoordinaten, trifft aber nur Felder im Bild; sonst "Maus trifft Feld nicht" (z. B. y=600) – Werkzeug, nicht Spiel. `camera` nimmt nur IDs. |
| T-05 | Zoom-Wert gegenläufig zur Erwartung (größer = weiter weg); Hilfe nennt Bereich, aber nicht die Richtung. |
| T-06 | Lauf mit >30 Befehlen überschreitet leicht 2 min (s14: 114 s); in Terminal-Umgebungen mit 120-s-Limit bricht der Aufruf ab ("Terminated"). Mit `run_in_background` lösbar, in der Hilfe nicht erwähnt. Zudem: `nohup … &` mit nachfolgendem `echo` startete in einem Fall gar nicht (s21 leer). |
| T-07 | `list` meldet vor der Gründung "nicht nötig (Abnehmer)", nach der Gründung "keine (gratis)" für dieselben Industrien: Werkzeug-Text oder Spielzustand uneinheitlich (unklar, welches). |
| T-08 | `wait` rundet auf 15-s-Schritte: "HQ jetzt fest" bei 2:15 statt 2:00. |

## Gesamturteil
Steinbach ist spielbar und eher zu leicht (Kasse 27,8 k nach 45 min, 7/7 Ziele nach 5:31), die Vorschau warnt vor einer Schwierigkeit, die der Slice nicht liefert – dazu fällt vor allem Z-01 (Straße endet nicht auf Städten) auf; keine Abstürze.
