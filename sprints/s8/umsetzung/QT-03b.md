# QT-03b Loop-Bot mit Firmenkauf, Exploit-Sweep X1-X3, a-Bisektion (Daniel, S8 Block B/C, 05.11.2026)

**Ergebnis:** Der Bot spielt den Firmenkauf (FK-02) und das Ersetzen (FZ-04) über die echte `ProtoSim`-API. Exploit-Sweep X1-X3 und a-Bisektion sind gebaut und gelaufen. Die Tabelle k = 1/4/8/20 × plan/normal/naiv, jeweils mit und ohne FK, steht fertig (n = 20). **Kalibriert habe ich nichts.** Branch `s8-qt3` (von `s8` de75721), nichts gepusht, kein Spielcode geändert (`main.gd`, `economy.gd`, `proto_sim.gd`, UI unberührt).
Messart überall: **gemessen, headless, Godot 4.7.2, Sandbox 2 vCPU, ein Prozess nach dem anderen** (Loadavg je Lauf in `lauf_zeiten*.txt`). Wo etwas gerechnet oder gesetzt ist, steht es dabei.

## Befehle
```
cd slice; G=/tmp/claude-0/gd/Godot_v4.7.2-stable_linux.x86_64
$G --headless --path . -s res://tests/s8_loop_bot.gd -- --n=20 --strategie=alle --tempo_k=4 [--fk=aus] [--a=<‰>] [--alterung=aus] [--deckel=0] --csv=/abs/lauf.csv
$G --headless --path . -s res://tests/s8_exploit.gd -- --modus=alle --tempo_k=4 --csv=/abs/x_k4.csv
python3 -I tools/qt03b_auswerten.py <ordner>          # tabelle_qt03b.csv, fk_paare.csv
python3 -I tools/qt03b_exploit.py <ordner> --k=1,4,8,20 [--a=1572] [--scan=1000:6000:500]   # x_auswertung.csv, x_scan_a.csv
python3 -I tools/qt03b_a_bisektion.py --k=4 --n=20 --keff=2.746 --ziel=netto --wert=1107 --out=/abs/ordner
```
Neue Bot-Schalter: `--fk=aus` (Firmenkauf abschalten, Vergleichslauf), `--a=<‰>` (Ertragsfaktor, siehe Hinweis a), `--alterung=aus|an` und `--deckel=N` (Zuordnung, ändern `ps.alterung_an` bzw. `eco.inbuf_cap_perioden` nur im Testlauf).
Neue CSV-Spalten am Ende: `fk_kauf_min, fk_preis_cent, fk_ausbau_min, fk_ausbau_cent, ersetzt_n, ersetzt_erst_min, ev8_erst_min, tief_min, a_pm, bonus_cent, fk_grund, ev8_folgemodell_min, ev8_alter_min, ers_angebot_min, ers_spart_min`; dazu `<csv>.serie.csv` (je Periode Netto, Kasse, Kredit, Ertrag, Fahrzeuge).
Prüfungen: Abgleich je Periode (zwei Wege zur Kassenänderung) **0 Abweichungen in 480 Läufen** (8 Zellen × 60); Determinismus-Doppel Seed 1 je Strategie in allen 8 Zellen gleich. Der Standardlauf ohne `--a`/`--fk` bleibt RNG-identisch (Naiv-Zufall nur bei `naiv_fk_pct > 0`).

## 1. FK-02 im Bot (Auftrag 1)
Plan kauft die Mühle ab Minute 14 (+ Jitter 0-2 min, Versuch alle 30 s Spielzeit, Bedingung `kaufbar` und Kasse − Preis ≥ Reserve 1.500 $) und baut sie aus (Ausbau-Angebot, Bedingung wie beim Kauf). Normal kauft ab Minute 28 plus Reaktionszeit, Ausbau nach 3 min. Naiv kauft nicht (Parameter `naiv_fk_pct = 0`). Preis laut API **1.530 $** (Kauf) und **2.000 $** (Ausbau).

| Messung (k = 1, n = 20, Seeds 1-20) | plan | normal | naiv |
|---|---|---|---|
| Kauf-Minute, P50 (min-max) | 15,0 (14-16), 20/20 | 30,0 (28-31), 12/20 (8 Bankrotte vorher) | kein Kauf |
| Im Zielfenster 14-25 | 20/20 | 0/12 | n. a. |
| Ausbau-Minute P50 | 15,5, 20/20 | 33,0, 9/12 | n. a. |
| Amortisation A (kumuliertes Δ Netto operativ gegen "ohne Kauf" ≥ Kauf+Ausbau), Minuten nach Kauf | **P50 11 (11-12), 20/20 im Ziel 8-20** | nicht erreicht (0/12, Horizont nur 15 min) | n. a. |
| Kassen-Gleichstand (Kasse gegen "ohne Kauf" wieder gleich) | P50 12, 20/20 | 0/12 | n. a. |
| Netto operativ, 5-Perioden-Mittel Minute 30, P50 | **1.107 $/min mit FK, 83 $/min ohne** | -54 | 0 |
| F2 (600 $/min-Platzhalter, 5 Perioden, Kredit 0) | 20/20, P50 Minute 27 (ohne FK: 0/20) | 0/20 | 0/20 |

**Schneeball** (Paar: gleicher Seed, Lauf mit Kauf gegen Lauf `--fk=aus`; Verdopplung = erste Minute, in der das 3-Perioden-Mittel Netto ≥ 2 × der Vergleichslauf liegt; Definition in `tools/qt03b_auswerten.py`): **Das Ziel "keine Verdopplung in < 10 min" ist bei plan k = 1 verletzt.** 20/20 Paare verdoppeln, P50 nach 7,0 min, alle < 10 min. Gegen den Wert vor dem Kauf: ebenfalls 20/20, P50 7,0 min. Das größte Verhältnis in 10 min liegt bei P50 10,8 ×. Einschränkung: Das Netto "ohne Kauf" ist in dieser Phase klein, das Verhältnis ist darum groß; die absoluten Werte stehen in `fk_paare.csv` und `n20_*.serie.csv`. Normal k = 1: 6/12 verdoppeln, P50 3 min. Bei k = 4 (plan) 8 von 20 Paaren, P50 2 min; 14 von 20 Plan-Läufen gehen bankrott, die Paare sind dort verzerrt.
Bei k = 4 erreicht Plan die Amortisation nur in 7/20 Läufen (P50 17 min, 6 davon im Ziel); bei k = 8 und 20 geht alles bankrott, kein Kauf.

**Ersetzen-Ereignis (Minute 28-35):** Das Angebot (`ersetzen_angebot`, Frachtwagen ab 1830) erscheint bei plan in Minute 30 (20/20, im Fenster). Die Ersparnis `spart_cent_pro_periode` ist aber erst ab **Minute 36** > 0; der Bot ersetzt erst dann (20/20, P50 36,0, **0 im Fenster 28-35**). Folgemodell-Hinweis (ev8) bei Minute 30, Alters-Schwelle (8 Jahre) bei 24,5. Auf Seed-Ebene gibt es hier keine Streuung (min = max), das Ereignis hängt am Kalender.

## 2. Ergebnistabelle (Auftrag 3): n = 20 je Zelle, Wilson 95 %
Volle Tabelle (alle Spalten, mit/ohne FK): `qt03b/tabelle_qt03b.csv`. Auszug **mit FK** (Minute P50 der erreichten Läufe; "-" = nie erreicht):

| k | Strategie | Bankrott (Wilson) | E-1 | E-2 | E-3 | E-4 | E-5 | E-6 alle | F1 | F2 op | Lücke P90 (min) | Kassentief P50 (Min. 5-20) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | plan | 0/20 = 0 % (0-16) | 0,5 | 0,5 | 0,9 | 4,4 | 16,0 | 4,0 | 11,0 | 27,0 (20/20) | 8,0 | 3.139 $ |
| 1 | normal | 8/20 = 40 % (22-61) | 2,0 | 2,0 | 2,4 | 2,8 | 2,0 | 5,0 (6) | 37,0 (5) | - | 15,0 | 4.232 $ |
| 1 | naiv | 19/20 = 95 % (76-99) | 2,0 | 2,0 | 2,4 | 3,8 | 2,0 | - | - | - | 9,0 | 15 $ |
| 4 | plan | 14/20 = 70 % (48-86) | 0,5 | 0,5 | 0,8 | 4,5 | 0,5 | - | 11,0 | - | 5,0 | 1.274 $ |
| 4 | normal | 19/20 = 95 % (76-99) | 2,0 | 2,0 | 2,6 | 3,1 | 2,0 | - | 9,0 (9) | - | 6,0 | 507 $ |
| 4 | naiv | 19/20 = 95 % (76-99) | 2,0 | 2,0 | 2,6 | 4,1 | 2,0 | - | - | - | 7,0 | 27 $ |
| 8 | plan | 20/20 = 100 % (84-100) | 0,5 | 0,5 | 1,1 | 4,7 | 0,5 | - | 10,0 (19) | - | 5,0 | 36 $ |
| 8 | normal | 20/20 | 2,0 | 2,0 | 2,8 | 3,5 | 2,0 | - | - | - | 5,4 | 25 $ |
| 8 | naiv | 20/20 | 2,0 | 2,0 | 2,8 | 4,5 | 2,0 | - | - | - | 7,9 | 10 $ |
| 20 | plan | 20/20 | 0,5 | 0,5 | 1,7 | 5,3 | 0,5 | - | - | - | 4,3 | 19 $ |
| 20 | normal | 20/20 | 2,0 | 2,0 | 3,2 | 5,4 | 2,0 | - | - | - | 3,1 | 29 $ |
| 20 | naiv | 20/20 | 2,0 | 2,0 | 3,5 | 5,7 | 2,0 | - | - | - | 7,0 | 11 $ |

Ohne FK ändert sich nur, wo FK ins Spiel kommt: k = 1 plan 0/20 Bankrott, aber F2 nie (0/20), E-5 Minute 21, Lücke P90 10,0, Kassentief 5.275 $; k = 1 normal 8/20 (unverändert); k = 4 plan **16/20** (mit FK 14/20), normal 11/20 (mit FK 19/20; Ursache nicht getrennt untersucht). k = 8 und 20: identisch, weil niemand bis zum Kauf überlebt.
Die Bandprüfung steht in Abschnitt 6.

## 3. Exploit-Sweep X1-X3 (Auftrag 2)
Aufbau: `tests/s8_exploit.gd`, synthetische Strecke (Knoten alle 5 Felder, Umweg als gleichschenkliges Dreieck), Linien über `add_line_vehicle`, Takt über `ps.tick()`, Flotte N = 1 … Nachfrage + 1, Fenster 40 min (10 min Warmlauf). Lizenzen, Mühlenpuffer, Stadtgröße und Kasse sind gesetzt, damit nur Strecke und Flotte wirken. Fix ist **gerechnet** (N × 6.000 ¢ × Fenster, ohne Alterung), alles andere gemessen. Netto je Einheit bei bestem N* (¢/E), Getreide / Mehl:

| d (Felder) | k = 1 | k = 4 | k = 8 | k = 20 |
|---|---|---|---|---|
| 10 | -27 / 393 | -61 / 359 | -202 / 218 | -585 / -165 |
| 20 | 244 / 1.084 | 70 / 780 | -176 / 664 | -956 / -334 |
| 40 | 755 / 2.435 | 369 / 1.876 | -198 / 1.263 | -1.914 / -1.760 |
| 60 | 1.004 / 3.524 | 632 / 2.976 | -168 / 1.373 | -1.961 / -2.381 |
| 80 | 1.275 / 4.215 | 609 / 3.167 | -682 / 352 | -4.110 / -4.600 |
| 100 | 1.561 / 4.921 | 662 / 3.148 | -844 / -536 | -7.004 / -7.425 |
| 150 | 1.894 / 6.304 | 567 / 2.405 | -763 / -1.498 | -16.028 / -16.007 |

Regel (design §2.3): Maximum bei 40-80 Feldern, bei d = 150 ≤ 80 % des Maximums, bei 20/40 ≥ 0.
- **X1 bei a = 1.000: Getreide ROT bei k = 1, 4, 8, 20. Mehl ROT bei k = 1 und 20, GRÜN bei k = 4 (Maximum bei 80, d = 150 bei 76 %) und k = 8 (Maximum bei 60, aber d ≥ 100 negativ).** Bei k = 1 steigt Netto je Einheit bis d = 150 weiter: die Regel greift im heutigen Zustand schon bei k = 1 nicht. Bei k = 8 und 20 ist Getreide über alle Strecken negativ (Fix und Kap tragen nicht, das deckt sich mit den Bankrotten).
- **X2 (Umweg 1,6 bei d = 60, Senkung Netto je E ≥ 20 %):** k = 1 ROT (Senkung Getreide 2 %, Mehl 1 %), k = 4 GRÜN (Senkung 84 % / 32 %), k = 8 Mehl GRÜN (Senkung 144 %, Netto wird negativ), Getreide nicht bewertbar (Basis negativ), k = 20 nicht bewertbar (Basis negativ). Bei k = 1 sind die Fahrkosten klein gegen den Ertrag; der Umweg kostet nur 1-2 %.
- **X3** (Netto je Fuhrwerk-Minute, ¢; reale Karte, Erlenbach mit Nachfrage 999 / Lindenfurt):

| k (a = 1.000) | Erlenbach 999 | Lindenfurt | Lindenfurt Netto je Minute (N*) | Erlenbach 999 Netto je Minute (N*) |
|---|---|---|---|---|
| 1 | 14.735 | 36.683 | 73.366 | 14.735 |
| 4 | 8.862 | 8.541 | 34.164 | 8.862 |
| 8 | 3.677 | 667 | 1.335 | 7.353 |
| 20 | -1.921 | -4.747 | -4.747 | -1.921 |

Lindenfurt dominiert nur bei k = 1 (beide Maße) und bei k = 4 je Gesamtminute (4 Fuhrwerke gegen 1); je Fuhrwerk-Minute liegen beide bei k = 4 gleichauf. Die Regel "Lindenfurt dominiert nicht" lässt sich also nur je Fuhrwerk-Minute prüfen; Die gemessene Sättigung V_sat von Erlenbach 999 liegt bei k = 1 und 4 bei 20-24 ‰ (Lindenfurt 875-1.666 ‰). **Die Definition von X3 braucht eine Entscheidung (Tobias/Lena)**, welches Maß gilt.
- **a-Scan** (`x_scan_a.txt`, `x_scan_a_fein.txt`, a = 1.000-6.000 ‰): k = 1: X1 und X2 für beide Güter in jedem a ROT. k = 4: X1 Getreide in jedem a ROT (Maximum wandert ab a = 1.200 auf d = 150), X1 Mehl GRÜN nur bei a = 1.000, ab 1.100 ROT (Maximum bei 100, d = 150 bei 80-98 %); X2 Getreide grün bis a = 1.600 (24 %), ab 2.000 rot. k = 8: X1 Getreide in jedem a ROT (bis a = 1.300 wegen negativem Netto bei 20/40, ab 1.500 weil das Maximum bei d = 150 liegt), X1 Mehl über alle a GRÜN; X2 Getreide grün bis a = 3.000.
- **Für die in Abschnitt 4 gefundenen a-Werte** (k = 4, a = 1.572: X1 Getreide ROT [Maximum bei 150], Mehl ROT [d = 150 bei 88 %], X2 grün; k = 8, a = 3.133: X1 Getreide ROT, Mehl GRÜN, X2 grün).

Schluss für Tobias/Felix: **Ein a, das Netto und F2 bei k = 4 und 8 hält, verletzt X1 für Getreide.** Je größer a, desto mehr belohnt die Strecke Länge; ein weiter wirkender Ausgleich ist nur über Fix, Kap oder Preise zu haben. Das ist in OE-02 (Folge 3) schon als Möglichkeit genannt; jetzt ist es gemessen.

## 4. a-Bisektion (Auftrag 2)
`tools/qt03b_a_bisektion.py` ruft den Bot mit `--a=`. Ziele: `f2min` (kleinstes a mit F2-Median ≤ Wert + Band) und `netto` (kleinstes a mit P50 Netto-5-Mittel Minute 30 ≥ Wert). Intervall [1.000; k_eff × 1.000], Abbruch bei 50 ‰ oder 8 Schritten.
`tempo_ausgleich_promille` wird von **keinem** Spielcode gelesen. Der Bot bucht deshalb einen Bonus a/1.000 auf jeden Lieferertrag (im Abgleich als `bonus_cent` geführt). **Anforderung an Felix:** Ein Haken `yield_cent × a` im Ertrag, sonst lässt sich a nicht im Spiel prüfen. Tobias entscheidet den Wert; `economy_proto.json` ist unberührt.

| k | Ziel | Ergebnis a | Bemerkung |
|---|---|---|---|
| 4 | f2min (25 ± 5) | 1.545 ‰ | F2 erreicht 13/20, Median Minute 30 (Bandrand). Ohne Band (Median ≤ 25) war die Klammer leer: bei a = 2.746 liegt der Median bei Minute 26 |
| 4 | netto ≥ 1.107 $/min | **1.572 ‰** | 0/20 Bankrott, F2 13/20 |
| 8 | netto ≥ 1.107 $/min | **3.133 ‰** | 0/20 Bankrott, aber F2 nur 1/20 |

(k_eff-Vergleichswerte: 2,746 bei k = 4 und 5,077 bei k = 8; Umlauf(k)/Umlauf(1).) Der Zielwert 1.107 $/min ist der gemessene Plan-Wert bei k = 1, a = 1.000 mit FK. Daraus:
- Bei k = 4 und 8 genügt weniger als k_eff × 1.000 für dasselbe Netto; mit a = k_eff × 1.000 liegt Netto bei 2.786 bzw. 2.870 $/min, also gut doppelt so hoch wie bei k = 1.
- Die Minute von F2 ist durch den Fahrplan nach unten begrenzt (Kauf ~15, Farm 2 ~20, dann 5 Perioden): gemessen **26-28 selbst bei großem a**. Sie taugt nicht als Bisektionsziel; die Netto-Variante ist die belastbare.
- **Zirkularität:** Die F2-Schwelle (600 $/min) ist ein Platzhalter, OE-04 soll sie aus demselben Bot setzen (OE-01 OFFEN 2). Wer a über F2 kalibriert und danach F2 aus dem Bot setzt, dreht sich im Kreis.
- Läufe: 8-9 Messpunkte à n = 20, 344-739 s je Bisektion (Loadavg 2-4).

## 5. Zuordnung: warum gehen k = 4 und 8 bankrott? (ohne FK, n = 20, a = 1.000)
Zwei Schalter nur im Testlauf: Alterung (FZ-03, 500 bp/Jahr) und Mühlen-Eingangspuffer-Deckel (2 Perioden). Bankrott/20:

| k | Strategie | Basis | Alterung aus | Deckel 0 | beide aus |
|---|---|---|---|---|---|
| 1 | normal | 8 | **0** | 8 | 0 |
| 1 | plan | 0 | 0 | 0 | 0 |
| 1 | naiv | 19 | 18 | 19 | 18 |
| 4 | plan | **16** | **0** | **0** | 0 |
| 4 | normal | 11 | 10 | 11 | 10 |
| 4 | naiv | 19 | 19 | 19 | 19 |

Bei k = 4 plan reicht **jeder** der beiden Schalter allein, um den Bankrott auf 0 zu bringen: Er entsteht erst, wenn Alterung **und** Deckel zusammen wirken (Wechselwirkung, keine einzelne Ursache). Bei k = 1 normal macht allein die Alterung 8 Bankrotte (nach Minute ~30, Fuhrwerk-Fix 6.000 → 9.000 nach 10 Jahren). Naiv und normal bei k = 4 ändern sich kaum (19/20 bzw. 10-11/20); ihr Treiber ist ein anderer, den ich nicht getrennt habe. **Im Vergleich mit QT-03 (ohne Alterung/Deckel in der Sim: plan k = 4 0/20) sind Alterung und Deckel die neuen Bankrott-Treiber.** Bei a = 1.000 trägt die Welt nur k = 1.

## 6. Welche Bänder sind bei n = 20 beurteilbar, was kostet n = 300?
Wilson 95 %: n = 20 gibt bei 20 % Bankrott 8-42, bei 30 % 14-52; bei n = 300 sind es 16-25 bzw. 3-8 % für 5 %.

| Band | Messung | Urteil bei n = 20 |
|---|---|---|
| Naiv 10-30 % Bankrott | 19/20 = 95 % (76-99), k = 1; 19-20/20 sonst | **Verfehlt, beurteilbar** (untere Grenze 76 % > 30 %). Ob ein nachkalibrierter Bot im Band 10-30 liegt, ist bei n = 20 **nicht beurteilbar** (z. B. 4/20 = 8-42 %, breiter als das Band) |
| Plan ≤ 5 % | k = 1: 0/20 (0-16) | **Nicht beurteilbar** (obere Grenze 16 %). n = 100 (nur Plan, k = 1, ohne Determinismus-Doppel): 0/100, Wilson 0-3,7 % → beurteilbar, aber siehe 81-Verläufe unten. k = 4: 14/20 (48-86) klar verfehlt. k = 8, 20: 20/20 klar verfehlt |
| Lücke P90 ≤ 3 min | plan k = 1: 8,0 (mit FK) / 10,0 (ohne); k = 4: 5,0; k = 8: 5,0; k = 20: 4,3 | **Verfehlt, beurteilbar** bei k = 1 und 4 (P90 deutlich über 3, auch ohne Ereignis 3: 8,0 bzw. 7,1). Normal k = 20 mit 3,1 liegt am Rand und ist nicht beurteilbar (P90 = 18. Wert von 20, und die Läufe enden mit dem Bankrott in Minute 7) |
| F2-Minute 25 ± 5 (nur mit FK, k = 1 plan) | P50 27,0, 20/20 | Im Band. Nach unten durch Kauf und Farm 2 begrenzt, daher nicht aussagekräftig (Abschnitt 4) |
| Kassentief P50 Min. 5-20 < 2.000 $ (W24) | plan k = 1 mit FK: 3.139 $ (ohne FK 5.275 $); k = 4: 1.274 $ (aber 70 % Bankrott) | **Nicht erfüllt** bei k = 1 (Info; hängt an Bot-Reserve 1.500 $, Tobias entscheidet) |
| Amortisation FK 8-20 min | plan k = 1: P50 11, 20/20 | Im Ziel (nur Plan-Bot, ein Verhalten) |
| Schneeball < 10 min keine Verdopplung | plan k = 1: 20/20 verdoppeln, P50 7 min | **Verletzt** (Basis klein, siehe oben) |
| Ersetzen-Ereignis 28-35 | Angebot 30, Ersparnis > 0 ab 36 | Angebot im Fenster, Nutzen erst danach |

**Einschränkung Plan-Bot:** Er hat Jitter 0-2 min an vier Schritten, also **höchstens 81 verschiedene Verläufe**. n = 20 oder n = 100 sind darum keine unabhängigen Stichproben; das Wilson-Intervall ist für den Plan-Bot zu optimistisch. Mehr Seeds bringen hier nichts ohne mehr Verhaltensstreuung (z. B. Reserve, Jitter breiter, Verlagerung der Reihenfolge).
**Kosten n = 300** (gemessen, Loadavg ≈ 1, Mittel aus n = 20 linear hochgerechnet, jeweils alle drei Strategien): k = 1 15,0 min, k = 4 15,7 min, k = 8 8,6 min, k = 20 5,0 min, zusammen **44,3 min mit FK**, bei Vergleichslauf ohne FK etwa doppelt (~89 min). Einzelmessung: n = 100 plan k = 1 130 s (1.295 ms je Lauf, Max 1.501 ms), n = 300 plan allein 6,5 min. Bei Parallellast (Loadavg 3-6) waren dieselben n = 20-Läufe bis zu 2 × langsamer (54-136 s). Nicht gemessen: n = 300 selbst. Diese Hochrechnung ist linear aus n = 20 und n = 100.

## 7. Anforderungen an Felix (Spielcode, nicht von mir geändert)
1. **Haken für a:** `tempo_ausgleich_promille` wird nirgends gelesen; Ertrag × a/1.000 muss in Economy/ProtoSim, sonst bleibt a ein Bot-Rechenwert (Abschnitt 4).
2. **`ProtoSim.kauf_total`** zählt Firmenkauf und Ausbau nicht mit; der Bot führt `fk_total` getrennt, der Kassen-Abgleich hängt daran. Eine HUD-/Konto-Zahl "Käufe" würde sonst den Firmenkauf auslassen.
3. Ersetzen: `spart_cent_pro_periode` ist erst ab Minute 36 positiv, das Angebot erscheint bei 30 (Frachtwagen ab 1830). Wenn das Ersetzen-Ereignis in Minute 28-35 spürbar sein soll, ist das eine Daten-/Designfrage, kein Bot-Fehler.

## 8. Übergabe an Tobias (Daten und Beobachtungen, keine Parameteränderung)
Dateien: `qt03b/tabelle_qt03b.csv` (alle Spalten), `fk_paare.csv`, `x_auswertung.csv` (+ `.txt`), `x_scan_a.csv`, `bisektion/`, `attribution/`.
Beobachtungen:
1. Bei a = 1.000 trägt die Welt nur k = 1; mit FK F2 20/20 bei Minute 27, ohne FK nie. Naiv liegt bei 95-100 % statt 10-30 %.
2. Alterung × Deckel ist der Treiber des Plan-Bankrotts bei k = 4 (Abschnitt 5).
3. Das a, das Netto hält, bricht X1 für Getreide; Fix/Kap/Preise zuerst, a danach.
4. Die F2-Minute ist fahrplanbegrenzt (26-28), die F2-Schwelle zirkulär.
5. Schneeball: Der FK verdoppelt Netto in 7 min (plan k = 1); amortisiert nach 11 min.

## 9. Offene Punkte und Grenzen
- **X3-Definition** (Fz-Minute oder Gesamtminute) offen.
- **Ereignis 4** (Kasse erreicht Preis) hängt an der Reaktionszeit des Bots (Flanke am Periodenende), nicht am Spiel; Bandurteile über Ereignislücken sind für Ereignis 4 ein Bot-Artefakt.
- **Naiv kauft keine Mühle** (Setzung); `naiv_fk_pct` ist da, steht auf 0.
- **Normal-Bot** kauft ab Minute 28 (Setzung, Kalibrierung offen).
- F2-Platzhalter 600 $/min und OE-01 OFFEN 2/3 (F2 mit/ohne Investitionen) unentschieden; der Bot liefert beide Varianten.
- Alle Messungen: ein Bot-Verhalten je Strategie, a = 1.000 (außer Bisektion/X-Scan), Seeds 1-20, Proto-Karte; der Plan-Bot spielt den Fahrplan, den wir selbst geschrieben haben (Goodhart, Regel 10: Drift, nicht Spaß).
