# Fehlertexte final (Aylin, S7 Block A) – Grundlage U-03 und W-04

Regeln (D21): Ursache + Lösung, max. 90 Zeichen, Du-Form, sachlich, kein Systemjargon, keine Rohcodes. Jede Ablehnung zeigt Text; Bau-Fälle zusätzlich rot in der Vorschau, bevor man loslässt. `{…}` = Platzhalter aus dem Spielwert (Test gegen den Spielwert, Retro S6). Meter: 1 Feld = 25 m nur auf der S7-Welt (`--welt=s7`); der Slice zeigt Felder.
Code-Stand: /home/claude/mega-tycoon/slice/ (nur gelesen). Zeilen = main.gd, außer wo anders genannt.

Anzeige-Kürzel: **V** = rote Vorschau (Fehlstelle rot + Grund am Cursor, `_update_cursor_label` 2606ff.), **T** = Toast (`_toast`, 1478), **P** = Panel/Banner/Tooltip.

## 1 Bau (Straße, Gleis, Abriss, Lager)

| # | Fall | heutiger Text (Datei:Zeile) | stumm? | neuer Text (max. 90 Z.) | Anzeige |
|---|---|---|---|---|---|
| B1 | Brücke diagonal | „Wasser ohne Brücke: Brücken nur gerade, nicht diagonal“ (2187) | nein, aber ohne Lösung | Brücke geht nur geradeaus. Baue bis zum Ufer, dann gerade hinüber. | V + T |
| B2 | Brücke zu lang / Fluss zu breit (S7) | „Wasser ohne Brücke: Brücke zu lang (max. 8 Felder)“ (2177) | nein, ohne Lösung | Der Fluss ist hier {n} Felder breit, Brücken schaffen {max}. Such eine schmalere Stelle. | V + T |
| B3 | Brückenkopf ohne Land | „Wasser ohne Brücke: Brückenkopf braucht Land an beiden Enden“ (2175) | nein, unverständlich | Die Brücke braucht festen Boden an beiden Ufern. Ziehe bis ans Land drüben. | V + T |
| B4 | Gebäude im Weg | „Gebäude im Weg: {Name}“ (2123) | nein, ohne Lösung | {Name} steht im Weg. Führe die Strecke außen herum. | V + T |
| B5 | Stadt: Ziel in der Stadt (Z-01) | „Gebäude im Weg: Mittelfurt“ (2123, Stadtmitte als Ziel) | nein, falsche Ursache | (entfällt: Drag auf die Stadt dockt am Randfeld an, Punkt sichtbar. Siehe S2) | V (Anschlusspunkt) |
| B6 | Gleis auf Stadtstraße | „Gleis auf Stadtstraße nicht erlaubt: Gleis um die Stadt herum führen“ (2114) | nein | Gleise dürfen nicht durch die Stadt. Ziehe zum Bahnhof am Stadtrand. | V + T |
| B7 | Außerhalb der Karte | „Außerhalb der Karte“ (2110) | nein | Hier endet die Karte. Ziehe die Strecke zurück ins Spielfeld. | V + T |
| B8 | Kasse reicht nicht (Bau) | „Zu wenig Geld: {x} nötig, {y} vorhanden“ (2147) | nein, ohne Fehlbetrag | Es fehlen {Δ}. Nimm Kredit (Knopf neben der Kasse) oder baue kürzer. | V + T |
| B9 | Strecke schon vorhanden / 0 neue Felder | – (build_track gibt true, baut nichts, Toast nur bei total > 0: 2229) | **ja** | Hier liegt schon eine Strecke. Ziehe zu einem Ziel, das noch nicht verbunden ist. | V (grau) + T |
| B10 | Drag ohne Ziel (außerhalb, Start = Ende) | – (`end_drag`: `end.x < 0` → false, 2380) | **ja** | Ziehe die Maus bis zum Ziel und lass dort los. Esc bricht ab. | T |
| B11 | Zu steil (S7, neu) | – (neu, W-02) | – | Zu steil: {x} % Steigung, erlaubt {max} %. Führe die Strecke am Hang entlang. | V + T |
| B12 | Teuer am Hang (S7, Hinweis, kein Fehler) | – (neu, W-04) | – | Hang: Bau ×{f} teurer. Gesamt {Preis}. | V (Preis gelb) |
| B13 | Abriss: Linie fährt hier | „{Linie} fährt hier. Erst links unter „Linien“ auflösen (Papierkorb).“ (2322) | nein, gut | unverändert (schon Ursache + Lösung) | V + T |
| B14 | Abriss: Stadt/Gebäude | „Stadtstraßen und Gebäude kann man nicht abreißen“ (2331) | nein, ohne Lösung | Stadtstraßen und Gebäude bleiben stehen. Markiere nur eigene Strecken. | V + T |
| B15 | Lager: kein Platz | „Hier ist kein Platz für ein Lager.“ (2417) | nein, Ursache fehlt | Lager braucht 2×2 freie Wiese: nicht auf Wasser, Berg, Straße, Gebäude. | V (Fußabdruck rot) + T |
| B16 | Lager: Kasse | „Zu wenig Geld: {x} nötig.“ (2420) | nein | Lager kostet {x}, es fehlen {Δ}. Nimm Kredit oder warte auf Einnahmen. | T |
| B17 | Lager vor dem Bau (Hinweis) | nach dem Bau: „…bezahlt wird erst beim Endabnehmer.“ (2439) | zu spät | Lager bringt allein kein Geld: Bezahlt wird erst beim Endabnehmer. | P (Werkzeug-Tooltip, 1416ff.) + T nach Bau |

## 2 Stadtanschluss (Z-01, W-04)

| # | Fall | heutiger Text | stumm? | neuer Text | Anzeige |
|---|---|---|---|---|---|
| S1 | Drag auf Stadtfläche (Erfolg) | „Gebäude im Weg: {Stadt}“ (2123) | nein, falsch | Anschluss an {Stadt}: Die Strecke endet am Stadtrand (Punkt ▼). | V (Anschlusspunkt, grün) |
| S2 | Stadtrand nicht erreichbar (Wasser, Berg, zu steil) | „Brücke zu lang…“ (2177) | nein, falsche Ursache | {Stadt} ist von hier nicht anschließbar. Wähle eine andere Seite der Stadt. | V + T |
| S3 | Linie ohne Anschluss an Stadt | „Keine Straßenverbindung zwischen {A} und {B}.“ (2508) | Toast ja, aber state.md meldet „Fehler: keiner“ (Bug 4) | Zwischen {A} und {B} fehlt die Straße. Baue sie bis zum Stadtrand von {B}. | T (+ Fehlerzeile im Zustandsbericht) |

## 3 Linien, Fahrzeuge, Lizenz, Kredit

| # | Fall | heutiger Text (Datei:Zeile) | stumm? | neuer Text (max. 90 Z.) | Anzeige |
|---|---|---|---|---|---|
| L1 | Keine Verbindung | „Keine Gleisverbindung / Straßenverbindung zwischen A und B.“ (2508) | nein, ohne Lösung | Zwischen {A} und {B} fehlt die Straße. Baue sie mit [1] und setz die Linie neu. | T |
| L2 | Quelle liefert nichts | „{Name} liefert nichts – wähle Farm/Mine, Verarbeiter oder Lager.“ (2007) | nein | {Name} liefert nichts. Starte die Linie bei Farm, Mine, Mühle oder Lager. | T |
| L3 | Quelle ohne Lizenz | „Laden nur mit Lizenz: Klick auf {Name} (Auswahl, Esc) und „Lizenz kaufen“.“ (2009) | nein, zu lang | {Name} hat keine Lizenz. Kaufe sie im Panel (Klick auf das Gebäude). | T + Panel öffnet |
| L4 | Ziel nimmt Ware nicht an | „{Ziel} nimmt von {Quelle} nichts an.“ (2017) | nein, ohne Lösung | {Ziel} nimmt {Ware} nicht an. Wähle einen Abnehmer, der sie braucht (Panel). | T |
| L5 | Klick auf leeres Feld im Linienmodus | – (`click`: `b == null` → return, 1999) | **ja** | Klicke ein Gebäude an: erst die Quelle, dann das Ziel. | T (leise, 2 s) |
| L6 | Fahrzeug: Kasse | „Zu wenig Geld für Lkw ({x}).“ (2459) | nein, ohne Fehlbetrag | Lkw kostet {x}, es fehlen {Δ}. Nimm Kredit oder warte auf Einnahmen. | T |
| L7 | Lizenz: schon lizenziert | „{Name} ist schon lizenziert.“ (1539) | nein | unverändert | T |
| L8 | Lizenz: Kasse | „Zu wenig Geld: Lizenz kostet {x}.“ (1541) | nein | Lizenz kostet {x}, es fehlen {Δ}. Nimm Kredit oder warte auf Einnahmen. | T + Knopf grau mit Fehlbetrag |
| L9 | Lizenz: sonstige Ablehnung | „Lizenz nicht möglich: {Rohcode}“ (1543) | nein, Rohcode | Lizenz gerade nicht möglich. Bitte erneut klicken (Meldung an uns: {Code}). | T |
| L10 | Lizenz-Klick ohne gültiges Angebot | – (`ui_buy_licence`: `not q["ok"]` → false, 1531) | **ja** | Dieses Gebäude braucht keine Lizenz. | T |
| L11 | Lizenzverlängerung (B-xx) | – (Verlängerung ohne Meldung, Daniel Z-05) | **ja** | {Name}: Lizenz verlängert für {x}. | T |
| L12 | Kreditrahmen voll | „Kreditrahmen ausgeschöpft ({x}).“ (1218) | nein | Kreditrahmen {x} ist voll. Tilge Schulden oder warte auf Einnahmen. | T |
| L13 | Tilgen: Kasse | „Zum Tilgen fehlen {x} in der Kasse.“ (1230) | nein | Zum Tilgen fehlen {x} in der Kasse. Warte auf Einnahmen. | T |
| L14 | Tempo 8× | „8× nur bis {n} Fahrzeuge.“ (1506) | nein | 8× geht nur bis {n} Fahrzeuge. Tempo bleibt bei 4×. | T |
| L15 | Auflösen: „+0 $“ (B-xx) | „… verkauft, +0 $.“ (2293) | Text unklar | Gratis-Lkw: Rückkauf 0 $, der Gratis-Platz ist verbraucht. | T (nur bei 0 $) |

## 4 Kasse und Bankrott (neu)

| # | Fall | heutiger Text (Datei:Zeile) | stumm? | neuer Text (max. 90 Z.) | Anzeige |
|---|---|---|---|---|---|
| K1 | Bankrott-Vorwarnung (≥ 60 s Spielzeit vor 0 $ bei aktuellem Verlauf) | – (Tobias: Kasse 6.000 → 0 ohne Toast) | **ja** | Kasse reicht noch ~{t}. Größter Verlust: {Posten} (−{x}/min). Kredit nehmen oder Linie auflösen. | T (6 s, persistent bis Kasse stabil) + Kasse im HUD rot |
| K2 | Bankrott-Overlay | „Kasse {x} nach {t} Spielzeit. Ein Konto unter 0 $ ist das Ende (Kredit vorher aufnehmen).“ (2676) | nein, Ursache nur als Zahlen | Bankrott: {Posten} kostete {x}/min, die Kasse war leer. Beim nächsten Mal früher Kredit. | P (Banner) |

Vorwarn-Logik (nur Text, U-03): Kassenprognose = Kasse ÷ (laufende Kosten − Einnahmen je Minute der letzten 2 Spielminuten). Warnung ab ≤ 60 s bis 0 $, einmal je Minute. Posten = größter negativer Block aus Linie (netto), Fahrzeug-Unterhalt, Gleisunterhalt, Lager, Kreditzins. Der Name steht im Text („Lkw-Linie Mühle › Lager“). Ortsangabe kommt erst mit A-08 (S8).

Fehlbetrag Δ = Preis − Kasse. Kredit-Hinweis nur, solange Kreditrahmen frei ist (sonst „warte auf Einnahmen“, L12).

## 5 Unklare Begriffe → besser

| # | Ort (Datei:Zeile) | heute | besser |
|---|---|---|---|
| U1 | Lizenzknopf (1766), Styleguide (ui/styleguide.gd:133) | „Ertrag ca. 145 $/Monat“ | „Ertrag ca. 145 $ je Spielminute“ (überall /min, `Ertrag/min` im Panel 1738 hat es schon). Tooltip „1 Monat = 1 Spielminute“ (987) streichen: der Begriff „Monat“ erscheint nirgends mehr |
| U2 | Ring-Labels (hq_placement.gd:695) | „25 F.“ | „Mühle · 625 m“ (S7-Welt) bzw. „Mühle · 25 Felder“ (Slice). Name + volle Einheit |
| U3 | Panel „Lieferziele“ (1734) | „Mittelfurt (150 F.)“ | „Mittelfurt (150 Felder)“ / „(3,75 km)“ |
| U4 | Kopfleiste (3011, Tooltip 997) | „1 Skillpunkt gespart“ | Raus aus der Leiste (Clipping bei 1600 px). Der Punkt erscheint als Toast bei Meilenstein M1b: „Skillpunkt verdient. Er wartet, bis der Skilltree kommt.“ |
| U5 | Ziel-Hinweis (1802, 1804) | „Tempo 2× oder 4× oben links“ / „Gewinn je Linie steht oben links“ | „Tempo-Knöpfe: oben rechts“ / „Gewinn je Linie: Liste links, unter Linien“ |
| U6 | Ringlabel (hq_placement.gd:724) | „Umsetzen möglich, noch 2:00“ | „HQ noch 2:00 min kostenlos verschiebbar (Ring anklicken)“ |
| U7 | Ziel „3 Lieferungen mit Gewinn“ (1801–1804, 1819) | wird abgehakt, Linie zeigt −2 $/min | „3 Lieferungen mit Ertrag“ (Ertrag je Lieferung, nicht Linien-Gewinn) |
| U8 | „Nächster Schritt“ (stale nach Lizenzkauf) | „Lizenz für Mühle 1 kaufen, Straße bis Mittelfurt …“ | Nur offene Teile, mit Preis: „Straße bis Mittelfurt bauen (ca. 1.300 $)“ |
| U9 | Vorschau-Panel Kette | „Farm 19 und 35, Mühle 25 Felder. Absatz Mittelfurt 150 Felder.“ | „Kette: 2 Farmen (19 und 35 Felder) → Mühle (25) → Mittelfurt (150)“ |
| U10 | Kasse-Tooltip (983) | „Unter 0 $ bist du bankrott – vorher hilft ein Kredit (rechts daneben).“ | „Unter 0 $ bist du bankrott. Ein Kredit (Knopf rechts daneben) verschafft dir Zeit.“ |
| U11 | Lager-Toast nach Bau (2439) | „bezahlt wird erst beim Endabnehmer“ | Warnung schon vor dem Bau (B17) |
| U12 | Vorschau-Zeile (2616) | „Straße: 12 Felder 480 $“ | „Straße: 12 Felder (300 m) · 480 $“ (S7-Welt mit Meter) |
