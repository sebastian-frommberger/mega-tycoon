# QT-03c Loop-Bot am echten a-Haken, Wiederholung der Kernmessung, Rauchtests in der Regression (Daniel, S8, 05.11.2026)

**Ergebnis:** Der Bot rechnet keinen eigenen Ertragsbonus mehr. `--a=` geht an die Welt (`ProtoSim` liest es selbst, `economy.ertrag_a_promille`), `fk_total` wird nicht mehr zu `kauf_total` addiert. Gegen die alte Emulation gemessen: **0 Abweichungen** in 160 Läufen (a = 1.000: 120 Läufe, a = 1.572 und 3.133: 40 Läufe), alle 55 Spalten gleich, auch die Sim-Prüfsumme. Die Kernmessung (n = 20, k = 1/4/8/20 × 3 Strategien) ist wiederholt; die a-Bisektion läuft mit dem echten Haken. **Kalibriert habe ich nichts, Spielcode ist unverändert** (`main.gd`, `economy.gd`, `proto_sim.gd`, `prototyp_welt.gd`, UI; nur `tests/`, `tools/`, Berichte). Branch `s8-qt4` (von `s8` 48d3220, danach `s8` 6a817e9 eingemerged: FX4 und OE-02/03; Merge ohne Konflikt, Bot und Rauchtest laufen danach), nichts gepusht. **Zwei Stände gemessen:** §2/§3 auf 48d3220 (vor FX4), §3b auf 6a817e9 (nach FX4 und Tobias' OE-02/03).
Messart überall: **gemessen, headless, Godot 4.7.2, Sandbox 2 vCPU, ein Prozess nach dem anderen; andere Agenten liefen parallel (Loadavg 1,0 bis 3,4)**. Seeds 1 bis 20, 45 Spielminuten, Takt 300 Ticks, Firmenkauf an. Ein Bot-Verhalten je Strategie (Plan-Bot: höchstens 81 verschiedene Verläufe, siehe QT-03b §6).

## 1. Was am Bot geändert ist (`slice/tests/s8_loop_bot.gd`)
- Bonus-Buchung (`bonus_total`, `cash_cent`/`revenue_total` direkt erhöhen) entfernt. `a_pm` wird nach `spiel_starten` aus `eco.ertrag_a_promille` **gelesen**, nur für CSV und `meta.txt`. `--a=` im Bot ist ein No-op (ProtoSim liest dieselben Nutzerargumente).
- Netto-Abgleich: `kauf = ps.kauf_total − kauf_last` (enthält seit FX3 Firmenkauf und Ausbau). `fk_total` bleibt nur als Anzeige.
- Revenue-Abgleich am Laufende: Σ Lieferungen = `revenue_total` (ohne Bonus). Hält in allen 240 Läufen der Kernmessung (4 k × 3 Strategien × 20; keine "Abgleich"-Meldung im Log).
- CSV: Spalte `bonus_cent` entfällt (55 statt 56 Spalten), sonst unverändert. Die Auswertungsskripte lesen nach Spaltennamen und laufen unverändert.
- **Fund beim Umbau:** Ein GDScript-Formatfehler im CSV-Zeilenbau (`String formatting error: a number is required`) beendet den Bot **nicht** mit Exit 1, schreibt eine ERROR-Zeile und eine kaputte CSV. Gesehen, als ich die Spalte entfernt hatte. Der neue Rauchtest (§5) prüft deshalb auf `ERROR`-Zeilen und auf die Feldzahl jeder CSV-Zeile.

## 2. Abgleich gegen die Emulation (Auftrag 2)
Kontrolle: der alte Bot (`kontrolle_alter_bot_emulation.gd.txt`, = `s8:slice/tests/s8_loop_bot.gd` mit einer Änderung: `fk_total` nicht mehr addiert, sonst Doppelzählung) auf dem heutigen s8-Sim.
| Vergleich | Zeilen | Abweichungen |
|---|---|---|
| a = 1.000, alter Bot gegen neuen Bot, k = 1, alle Strategien, n = 20 | 60 | **0/60** (alle 55 Spalten, inkl. Prüfsumme) |
| dasselbe, k = 4 | 60 | **0/60** |
| a = 1.572, k = 4, Plan, n = 20: Emulation (`--ea=`, Welt-a = 1.000) gegen echten Haken (`--a=`) | 20 | **0/20** (Bankrott 0/20, Netto 1.182 $/min, Lücke P90 6,0 min in beiden) |
| a = 3.133, k = 8, Plan, n = 20: dasselbe | 20 | **0/20** (Bankrott 0/20, Netto 1.143 $/min, Lücke P90 5,0 in beiden) |
Die Rundung von `yield_cent` (`rdiv(c × a, 1000)` je Lieferung) und die Emulation (Bonus nach der Lieferung, halb auf) geben in diesen 40 Läufen dieselben Cents. Das ist ein Messbefund für diese Fälle, kein Beweis für alle a.
**Falle, die ich gemessen habe:** Ruft man den alten Bot mit `--a=1572` auf dem heutigen s8 auf, wirkt a **doppelt** (Welt und Emulation): Netto 2.495 statt 1.182 $/min (k = 4), 7.228 statt 1.143 $/min (k = 8). Wer eine alte Bot-Fassung oder alte CSV (QT-03b) mit `--a=` neu rechnet, bekommt Unsinn. Die Rohdaten dieser Doppelzählung liegen in `qt03c/m2_kontrolle/alt_a_*` (nicht verwenden).

### Abweichung gegen die gespeicherten QT-03b-Daten (anderer Sim-Stand)
Die QT-03b-CSV entstanden auf `s8-qt3` (von de75721). **Reproduzierbarkeit gemessen:** Der QT-03b-Bot (`s8-qt3`) auf einem Auszug von de75721 gibt die gespeicherte CSV k = 4, Plan, n = 20 zurück, **0/20 Zeilen abweichend** (56 Spalten); derselbe Bot auf 48d3220 nicht (alle 20 Zeilen abweichen, schon bei Lieferungen und Ertrag). Zwischen de75721 und 48d3220 hat `s8` die Weltdaten neu bekommen (`world/data/proto/proto_wege.json`, `proto_orte.json`, `proto_instanzen.json`, `regelwerk.json` u. a.) sowie FX3; FX3 selbst ist bei a = 1.000 verhaltensgleich (§2 oben). Welche der Weltdaten-Änderungen die Zahlen verschiebt, habe ich nicht getrennt. Bei **a = 1.000** ist deshalb nicht jede Zahl gleich (Kernwerte, n = 20; vollständige Tabelle `qt03c/vgl_tab.md`):
| k | Strategie | Bankrott QT-03b → QT-03c (48d3220) | Lücke P90 (min) | Netto5 Min 30 P50 ($/min) |
|---|---|---|---|---|
| 1 | plan | 0 → 0 | 8,0 → 8,0 | 1.107 → 1.108 |
| 1 | normal | 8 → 8 | 15,0 → 15,0 | −54 → −49 |
| 1 | naiv | 19 → 19 | 9,0 → 9,0 | 0 → 0 |
| 4 | plan | **14 → 13** | 5,0 → 4,0 | 0 → 0 |
| 4 | normal | **19 → 18** | 6,0 → 5,1 | 0 → 0 |
| 4 | naiv | 19 → 19 | 7,0 → 7,0 | 0 → 0 |
| 8, 20 | alle | 20 → 20 | 3,1 bis 7,9, nahe gleich (naiv k = 8: 7,9 → 6,9) | 0 → 0 |
Die Prüfsumme ist gegen QT-03b deshalb nicht vergleichbar; gegen die Kontrolle in der ersten Tabelle ist sie gleich.

## 3. Kernmessung am echten Haken (a = 1.000, Firmenkauf an, n = 20, Wilson 95 %)
Quelle: `qt03c/m1_neu_bot/n20_k{1,4,8,20}_fkan.csv`, Auswertung mit `tools/qt03b_auswerten.py` (`tabelle_qt03b.csv`).
| k | Strategie | Bankrott (Wilson) | Bankrott-Minute P50 | F1 erreicht | F2 op erreicht | Lücke P90 min (ohne Ereignis 3) | Kassentief P50 Min 5-20 | Netto5 Min 30 P50 $/min | FK gekauft |
|---|---|---|---|---|---|---|---|---|---|
| 1 | naiv | 19/20 (76-99 %) | 7,5 | 0/20 | 0/20 | 9,0 (9,0) | 24 $ | 0 | 0/20 |
| 1 | normal | 8/20 (22-61 %) | 39,8 | 5/20 | 0/20 | 15,0 (15,0) | 4.263 $ | −49 | 12/20 |
| 1 | plan | 0/20 (0-16 %) | - | 20/20 | 20/20 | 8,0 (8,0) | 3.245 $ | 1.108 | 20/20 |
| 4 | naiv | 19/20 (76-99 %) | 7,7 | 0/20 | 0/20 | 7,0 (8,0) | 26 $ | 0 | 0/20 |
| 4 | normal | 18/20 (70-97 %) | 22,4 | 9/20 | 0/20 | 5,1 (8,0) | 560 $ | 0 | 9/20 |
| 4 | plan | 13/20 (43-82 %) | 27,2 | 20/20 | 0/20 | 4,0 (4,0) | 1.331 $ | 0 | 20/20 |
| 8 | naiv | 20/20 (84-100 %) | 7,2 | 0/20 | 0/20 | 6,9 (6,9) | 12 $ | 0 | 0/20 |
| 8 | normal | 20/20 (84-100 %) | 9,3 | 0/20 | 0/20 | 5,3 (5,3) | 28 $ | 0 | 0/20 |
| 8 | plan | 20/20 (84-100 %) | 14,6 | 19/20 | 0/20 | 5,0 (5,0) | 28 $ | 0 | 0/20 |
| 20 | naiv | 20/20 (84-100 %) | 7,2 | 0/20 | 0/20 | 7,0 (7,0) | 21 $ | 0 | 0/20 |
| 20 | normal | 20/20 (84-100 %) | 7,4 | 0/20 | 0/20 | 3,1 (3,1) | 18 $ | 0 | 0/20 |
| 20 | plan | 20/20 (84-100 %) | 8,6 | 0/20 | 0/20 | 4,3 (4,3) | 23 $ | 0 | 0/20 |
"Netto 0" heißt bei k ≥ 4: P50 liegt bei einem Lauf mit Bankrott, der als 0 zählt (Methode des Bots). Bandurteile: bei n = 20 nur die Zeilen mit eindeutigem Intervall (naiv 76-100 % gegen Band 10-30 % verfehlt; Plan k ≥ 4 gegen ≤ 5 % verfehlt; Lücke P90 gegen ≤ 3 min verfehlt bei k = 1, 4, 8). Alles andere ist bei n = 20 nicht beurteilbar (QT-03b §6). Determinismus-Doppel (Seed 1 je Strategie) in allen vier k-Zellen gleich.
Laufzeit (gemessen, Loadavg 2,5 bis 3,4): Mittel je Lauf k = 1 1.695 ms, k = 4 1.362, k = 8 757, k = 20 571 (Max 3.049 ms). Gesamtlauf n = 20 × 3 Strategien einschließlich Determinismus: 116 / 93 / 51 / 40 s Wanduhr. Hochrechnung n = 300 × 3 (Mittel × 900, linear): 25,4 / 20,4 / 11,4 / 8,6 min, zusammen 66 min (QT-03b: 44 min bei Loadavg ≈ 1; die Last der anderen Agenten ist hier mit drin).

### 3b. Nach FX4 und OE-02/03 (s8 6a817e9, a = 1.000, n = 20, Firmenkauf an)
Quelle: `qt03c/m4_nach_fx4/`. Zwischen 48d3220 und 6a817e9 liegen FX4 (Wirtschafts-Station am Ladeplatz) und Tobias' OE-02/03 (Kalibrier-Sets, **inaktiv**; F2-Schwelle 620 $/min in `ziele_welt.json`). Ausgabe der Läufe: Determinismus OK in allen vier k, keine ERROR-Zeile, kein Abgleichfehler.
| k | Strategie | Bankrott vor → nach | Lücke P90 (min) | Netto5 Min 30 P50 ($/min) | F2 op erreicht | Kassentief P50 ($) |
|---|---|---|---|---|---|---|
| 1 | plan | 0 → 0 | 8,0 → 8,0 | 1.108 → 1.132 | 20 → 20 | 3.245 → 3.084 |
| 1 | normal | 8 → 7 | 15,0 → 13,0 | −49 → −8 | 0 → 0 | 4.263 → 4.354 |
| 1 | naiv | 19 → 19 | 9,0 → 9,0 | 0 → 0 | 0 → 0 | 24 → 20 |
| 4 | plan | **13 → 4** (Wilson nach: 8-42 %) | 4,0 → 5,0 | 0 → 268 | 0 → 0 | 1.331 → 1.636 |
| 4 | normal | 18 → 18 | 5,1 → 5,0 | 0 → 0 | 0 → 0 | 560 → 833 |
| 4 | naiv | 19 → 19 | 7,0 → 7,0 | 0 → 0 | 0 → 0 | 26 → 18 |
| 8 | plan, normal, naiv | 20 → 20 | 5,0 / 5,3 / 6,9 → 5,0 / 5,5 / 7,9 | 0 → 0 | 0 → 0 | 28 / 28 / 12 → 17 / 26 / 10 |
| 20 | plan, normal, naiv | 20 → 20 | 4,3 / 3,1 / 7,0 → 4,3 / 3,2 / 7,8 | 0 → 0 | 0 → 0 | 23 / 18 / 21 → 8 / 27 / 6 |
**Zuordnung gemessen (k = 4, Plan, n = 20):** Der Bot auf einem Auszug von `bd24053` (FX4, vor dem OE-Merge) gibt **4/20 Bankrott und Netto 268 $/min**, dasselbe wie 6a817e9: gleiche CSV bis auf die Spalte `ev8` (16 von 20 Zeilen, ein Zähler; die Ursache liegt im Bot-Merge, nicht untersucht). Die Verbesserung 13 → 4 kommt also von **FX4 (Ladeplatz-Halt)** und nicht von den inaktiven OE-Sets. Warum FX4 so wirkt (kürzere Wege, andere Wartezeit am Halt), habe ich nicht untersucht. Bei k = 8 und 20 trägt die Welt weiter nichts (20/20). Laufzeit (Loadavg 0,5 bis 1,1): Mittel je Lauf 1.163 / 1.254 / 644 / 373 ms (k = 1/4/8/20); Gesamtlauf einschließlich Determinismus 79 / 83 / 43 / 25 s; Hochrechnung n = 300 × 3: 17,4 / 18,8 / 9,7 / 5,6 min, zusammen **51,5 min** (ruhiger als §3: 66 min bei Loadavg 2,5 bis 3,4).

### a-Bisektion mit echtem Haken (`tools/qt03b_a_bisektion.py`, Ziel: Netto5 Min 30 P50 ≥ Plan-Wert bei k = 1, a = 1.000 auf demselben Stand)
| Stand | k | Zielwert | kleinstes erfülltes a | Intervall am Ende | Messpunkte | Bankrott / F2 bei diesem a |
|---|---|---|---|---|---|---|
| 48d3220 (vor FX4) | 4 | 1.108 | **1.545 ‰** | [1.517; 1.545] (28 ‰, Toleranz 50) | 8 à n = 20, 356 s | 0/20, F2 15/20 (P50 Min 30) |
| 48d3220 | 8 | 1.108 | **3.101 ‰** | [3.069; 3.101] (32 ‰) | 9, 539 s | 0/20, F2 0/20 |
| 6a817e9 (nach FX4, OE-02/03) | 4 | 1.132 | **1.545 ‰** | [1.517; 1.545] (28 ‰) | 8, 362 s | 0/20, F2 14/20 (P50 Min 30) |
| 6a817e9 | 8 | 1.132 | **2.783 ‰** | [2.751; 2.783] (32 ‰) | 9, 505 s | 0/20, F2 0/20 |
QT-03b (Emulation, Stand vor FX3/FX4): k = 4 1.572, k = 8 3.133. Rohdaten: `qt03c/m3_bisektion/` (vor FX4), `qt03c/m5_bisektion_nach_fx4/`. Bei k = 4, a = 1.000 liegt nach FX4 der Plan-Bot schon bei 4/20 Bankrott und Netto 268 $/min; bei k = 8 geht a = 2.019 noch 18/20 Bankrott (Stufe, nicht stetig).
Die Unterschiede zu QT-03b bei k = 4 (27 ‰) und k = 8 (32 ‰ vor FX4) liegen in der Größe der Toleranz und des Sim-Standes (Weltdaten). Nach FX4 sinkt a bei k = 8 um 318 ‰ gegen vor FX4 (3.101 → 2.783), bei k = 4 bleibt es gleich. Es ist **kein** Ergebnis der Emulation gegen den Haken (§2: 0 Abweichungen). Die Einschränkungen aus QT-03b §4 gelten unverändert: Zielwert hängt am Plan-Bot bei k = 1; F2-Minute ist durch den Fahrplan begrenzt (nicht als Ziel brauchbar); die F2-Schwelle (600 $/min) ist ein Platzhalter und zirkulär; X1 für Getreide wird mit diesem a verletzt (QT-03b §3). Bei k = 8 erreicht in keinem der beiden Stände ein Plan-Lauf F2 bei diesem a.
Exploit-Sweep: `s8_exploit.gd` rechnet bei `--a=` jetzt ebenfalls über den Haken. `qt03b_exploit.py` skaliert den Ertrag linear mit a nach der Messung; der Rauchtest (§5) prüft, dass `--a=2000` genau 2 × Ertrag und dieselbe Liefermenge ergibt (gemessen: 168.000 → 336.000 ¢, 386.400 → 772.800 ¢, Abweichung 0). Die a-Scan-Ergebnisse aus QT-03b bleiben damit gültig.

## 4. Aufrufe für Tobias (Kalibrierung, Worktree oe3)
Ich ändere nichts an seinen Dateien. Die Aufrufe laufen mit jedem Parameterset, das `economy_proto.json` / `vehicles.json` in seinem Worktree liefert (Bot und ProtoSim lesen die Dateien selbst; `--oe_set=<name>` ist sein Schalter in seiner Bot-Fassung). Alles aus dem Ordner `slice/` bzw. der Repo-Wurzel; `G=/tmp/claude-0/gd/Godot_v4.7.2-stable_linux.x86_64`.
```
# 1) Kernmessung, ein k, alle Strategien, mit Firmenkauf (Dauer n = 20: 40 bis 116 s je k bei Loadavg ~3)
$G --headless --path . -s res://tests/s8_loop_bot.gd -- --n=20 --strategie=alle --tempo_k=4 [--a=1545] [--oe_set=k4] [--fk=aus] --csv=/abs/n20_k4.csv
# 2) Tabelle (Bankrott, Wilson, Lücke, Netto, FK, Schneeball): Dateien n20_k{K}_fk{an|aus}.csv in einen Ordner legen
python3 -I tools/qt03b_auswerten.py <ordner>            # -> tabelle_qt03b.csv, fk_paare.csv
# 3) a-Bisektion (nur Plan, n = 20, Ziel Netto Min 30); Bot-Schalter hinter ein blankes '--'
python3 -I tools/qt03b_a_bisektion.py --k=4 --n=20 --keff=2.746 --ziel=netto --wert=1108 --out=/abs/ordner -- --oe_set=k4
# 4) Exploit X1-X3 auf der Zelle (Strecken, Umweg, Weltkarte), mit echtem a
$G --headless --path . -s res://tests/s8_exploit.gd -- --modus=alle --tempo_k=4 --a=1545 --csv=/abs/x_k4.csv
python3 -I tools/qt03b_exploit.py <ordner> --k=1,4,8,20 [--a=1545]
# 5) Abgleich zweier Läufe (alt/neu, Zeile für Zeile, alle gemeinsamen Spalten)
python3 -I tools/qt03c_vergleich.py alt.csv neu.csv [--strategie=plan]
# 6) Rauchtest vor jedem Commit
bash tests/s8_bot_smoke.sh bot ; bash tests/s8_bot_smoke.sh exploit
```
Hinweise: `--a=` überschreibt `tempo_ausgleich_promille` aus der JSON (Priorität: Kommandozeile). Ohne `--a` gilt der Wert der Datei, steht als `a_pm` in der CSV. Wer `--oe_set` und `--a` mischt, sieht beide in `<csv>.meta.txt`. Beim Bot gilt Determinismus: gleiche Argumente, gleiche Dateien = gleiche CSV (zwei Prozesse, md5 gleich, gemessen in QT-03). Zielwert für die Netto-Bisektion bei geänderten Fahrzeugwerten: den Plan-Wert bei k = 1 mit **denselben** Dateien neu messen (er hängt an Fix/Kap, nicht nur an a).
**Merge:** `git merge-tree s8-qt4 s8-oe3` meldet keinen Konflikt (nur gerechnet, nicht ausgeführt). Beide Zweige ändern `s8_loop_bot.gd` an verschiedenen Stellen; ob die zusammengeführte Fassung läuft, habe ich **nicht** geprüft. Nach dem Merge den Rauchtest laufen lassen (Formatzeile der CSV prüfen: die Zahl der `%`-Platzhalter muss zu den Spalten passen).

## 5. Rauchtests in d07 und regress_fast (Auftrag 4)
`proto_ui_welt_test` und `s8_fk02_test` standen schon in `d07_regression.sh` und `regress_fast.sh` (QT-01b). Neu:
- `slice/tests/s8_bot_smoke.sh bot`: Bot n = 2 × 3 Strategien, k = 1. Sechs Prüfungen: Exit 0, keine `ERROR`-Zeile, Determinismus OK, Kassen-/Lieferungs-Abgleich ohne Meldung, 6 CSV-Zeilen, gleiche Feldzahl in jeder Zeile. Misst keine Bänder.
- `slice/tests/s8_bot_smoke.sh exploit`: X1 mit zwei Strecken, Getreide, k = 1: zweimal gleiche CSV (deterministisch), `--a=2000` gibt dieselbe Liefermenge E und 2 × Ertrag. Sechs Prüfungen.
- Eingebunden als Zeilen `s8_bot_smoke (QT-03c)` und `s8_exploit_smoke (QT-03c)` in `d07_regression.sh` (§2h, nach den Proto-Suiten) und als `s8_bot_smoke`/`s8_exploit_smoke` in `regress_fast.sh`. Timeout = 3 × Baseline (`laufzeiten.txt`: Bot 50 s, Exploit 8 s; gemessen 35 s bzw. 8 s bei Loadavg 2 bis 3).
- `flaky_nacht.sh` ruft `d07_regression.sh` (Stufe voll) bzw. `regress_fast.sh` und liest deren Zusammenfassungen: die neuen Zeilen sind ohne Änderung der Auswertung dabei (voll: gemessen 40 Zeilen). Ich habe nur den Kommentar im Kopf angepasst.
- **Wächter einmal absichtlich rot gemacht (gemessen):** Exploit mit `--a=1500` statt 2000 → "Ertrag = 2 ×" FAIL (5/6); Bot mit wieder falscher Formatzeile → "keine ERROR-Zeile" und "gleiche Feldzahl" FAIL (4/6), Exit 0 des Bots allein hätte es nicht gezeigt.
- **Messung des Gesamtlaufs:** siehe §6.

## 6. Regressionslauf mit den neuen Zeilen
`slice/tests/flaky_nacht.sh --n=1 --stufe=beide` (nohup, Log): **1 Lauf, Exit d07 = 0, Exit fast = 0, 864 s Wanduhr** (Loadavg vor/nach 2,0 / 2,2). `d07_regression.sh` 734 s, **40 Zeilen alle OK** (davon `s8_bot_smoke` 16,5 s und `s8_exploit_smoke` 4,3 s, beide 6/6); `regress_fast.sh` 130 s (Ziel < 300 s), **30 Zeilen alle OK** (Bot 16,5 s, Exploit 4,2 s). Flaky-Tabelle: 70 Zellen, 0 rot, 0,00 %. Ein Lauf kann keine Flakiness zeigen (QT-02): Die Zeilen sind aufgenommen und ein Mal grün, nicht 10/10. Die Zeiten liegen unter dem Bot-Timeout (50 s Baseline → 150 s). Git-Stand des Laufs ce84121 (vor den letzten Berichts-Commits; Code unverändert). Logs: `qt03c/flaky1/`.

Nach dem Merge von `s8` (FX4, OE-02/03) in `s8-qt4`: `regress_fast.sh` erneut gelaufen, **Exit 0, 30 Zeilen alle OK, 133 s** (Loadavg ca. 1; `qt03c/fast_summary_nach_merge.md`). Der volle d07-Lauf nach dem Merge ist **nicht** wiederholt.

## 7. Grenzen
- Die Gleichheit Emulation = Haken ist an 160 Läufen gezeigt (a = 1.000, 1.572, 3.133). Nicht gezeigt: andere a, andere Strategien bei a ≠ 1.000, `naiv`/`normal` mit `--a`.
- Die Kernmessung hat n = 20 und einen Bot je Strategie; Wilson-Intervalle sind für den Plan-Bot zu optimistisch (≤ 81 Verläufe). n = 300 nachts ist nicht gelaufen (Hochrechnung 66 min bei Loadavg 2 bis 3).
- Ich habe nur a = 1.000 und die zwei Bisektionswerte neu gemessen; die QT-03b-Tabellen ohne Firmenkauf (`--fk=aus`), Zuordnung (Alterung/Deckel) und den X-Scan habe ich **nicht** wiederholt. Sie stammen vom älteren Sim-Stand (vor FX4).
- Die Rauchtests sind Rauchtests: Sie finden Formatfehler, Nichtdeterminismus, kaputten Abgleich und einen defekten a-Haken. Eine Drift der Spielwerte (Kalibrierung) sehen sie nicht, absichtlich: sonst würde jeder Kalibrierschritt von Tobias die Regression rot machen.
- Bandurteile, Spaß und Spielbarkeit: unverändert Bot-Proxy (mt-qa Regel 10).
