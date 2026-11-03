# QA: Resümee (Stand 03.11.2026)

Ich bin Daniel. Read-only aus dem Repo (`/home/claude/mega-tycoon`) und aus Recherche. [Beleg] = Datei oder URL genannt, [Eindruck] = meine Wertung.

## 1. Wie ich Spiel und Konzept heute sehe

**Kern:** Ein deterministischer Simulationskern (SoA, 10 Hz) mit einer großen Regression. Mein Maßstab: Was nicht gemessen und gegen den Spielwert getestet ist, gilt nicht. [Beleg: Belegstufen M/V/R/O]

**Was trägt:**
- Die Regression ist breit: 24 Zeilen grün in 1.090 s (`slice/tests/d07_regression_summary.md`). [Beleg]
- Perf-Gates zählen Dinge, nicht FPS: 10.000 Fahrzeuge etwa 1,9 ms Median pro Tick. [Beleg]
- Der Exploit-Katalog (`s3/day8-10/daniel/t07_exploit_katalog.md`) hat Spiellücken früh sichtbar gemacht. [Beleg]

**Was noch Papier ist:**
- Die Diagnose-Schicht (`slice/core/diagnostics.gd`) wird von `slice/main.gd` nicht benutzt; A-08 ist offen. [Beleg]
- Es gibt keine Flaky-Rate. Läufe schwanken (1.361 bis 1.565 s laut Lernbericht), ob ein Test sporadisch rot wird, weiß niemand. [Beleg]
- Live-Perf gegen gezählte Perf ist nicht systematisch getrennt (1,6 M gegen 0,62 M). [Beleg]
- [Eindruck] Grün heißt: die Tests, die wir haben, bestehen. Nicht: das Spiel ist in Ordnung.

## 2. Entwicklungsverlauf aus meiner Sicht (S2 bis S8)

- **S2:** Gate M0, Panel-Auswertung, Zielrechner-Messung offen (`s2/day7-10/panel/auswertung.md`, `daniel.md`). [Beleg]
- **S3:** Exploit-Katalog T07; A-08 Diagnose erstmals verschoben. [Beleg]
- **S4/S5:** Keine Review/Retro im Repo; ich habe keinen Abnahmeeintrag dazu. [Beleg] Lücke.
- **S6:** `s6/block-c/daniel.md`; Diagnose-Stretch nicht erreicht. [Beleg]
- **S7 (Wendepunkt):** Abnahme D09 (`s7/abnahme/daniel_d09.md`): Messfehler Faktor 2,5, Fehlalarm 1,6 M gezählt gegen 0,62 M live, Tests rot auf Platzhalterkarte. [Beleg]
- **S8:** Prototyp "Welt", Regelwerk v1.1, Fixpass W2; Regression "nicht neu gelaufen" in Integration W2 (`phase4/integration_w2.md`, `fixpass_w2.md`). [Beleg]
- Zahlen: 24 grüne Regressionszeilen, 76 Commits in drei Tagen. [Beleg]

## 3. Was gut lief (belegt)

- Der Fehlalarm 1,6 M wurde als Zählwert ohne Culling erkannt, bevor er Planung gekippt hat. [Beleg: `s7/review_retro.md`]
- Gate-Schwellen vor der Messung (D7/D8) verhindern Schönrechnen. [Beleg]
- Belegstufen M/V/R/O verhindern "synthetisch zählt als bewiesen". [Beleg]
- Der Exploit-Katalog liefert reproduzierbare Fälle statt Bauchgefühl. [Beleg: T07]

## 4. Was nicht gut lief, wiederkehrende Kompromisse (Zähler)

| Kompromiss | Zähler | Beleg |
|---|---|---|
| Wall-Clock im Test (H29; A21 `tmax <= 150.0 + 40.0` mit aufgeweiteter Toleranz) | 2 | `slice/tests/d07_abnahme.gd:271` |
| Spiel und Validator mit verschiedenen Regeln (B-1, H2/H3) | 2 | `s6/block-c/daniel.md`, `s7/block-a/daniel.md` |
| Gezählt/Headless statt Live (1,6 M, Faktor 2,5, DC-Zuordnung) | 3 | `s7/review_retro.md` |
| Tests rot wegen Platzhalterkarte | 2 | `s7/abnahme/daniel_d09.md` |
| Regression "nicht neu gelaufen" | 2 | `phase4/integration_w2.md`, ta_welle2 P7 |
| A-08 Diagnose verschoben | 4 | `s3/.../s4_kandidaten.md`, `s6/review_retro.md`, `s7/review_retro.md` |
| "ABW bewusst" ohne Ablaufdatum (E6, M8) | 2 | `phase3b/15_regelwerk_v1_1.md` |

- [Eindruck] Die Aufweitung der A21-Toleranz auf 190 s war ein Kompromiss, der ein echtes Problem (Lastabhängigkeit, Ladezeit 0,48 bis 1,7 s) versteckt statt löst.
- Bot-Zeit M7: 36,0 statt 30,4 min, Repo-Drift ungeklärt. [Beleg: Lernbericht mt-produktion]

## 5. Wo das Spiel oder das Konzept scheitern könnte (nach Wahrscheinlichkeit)

1. **Hoch:** Ein Fehler, den kein Test kennt, weil Spiel und Validator verschieden rechnen. [Beleg: Zähler 2]
2. **Hoch:** Perf-Aussage bricht live, weil nur gezählt wurde (Faktor 2,5 schon einmal falsch). [Beleg: S7]
3. **Mittel:** Flaky-Tests werden ignoriert, bis ein echter Fehler untergeht. [Eindruck; Flaky-Rate nicht erhoben]
4. **Mittel:** Ein Tester (Basti) findet nach Nielsen/Landauer bei L = 31 % nur etwa ein Drittel der Probleme (fünf etwa 84 %). [Beleg: Rechnung, R1]
5. **Niedrig bis mittel:** Bot-Metriken (Bankrott 10 bis 30 %) sind ein Proxy; bei kleinem n sind Wald-Intervalle zu eng. [Beleg: R2]

## 6. Meine drei wichtigsten Empfehlungen an Basti für Sprint 8

1. **Wall-Clock-Tests entfernen:** H29 und A21 auf Tick- oder Zählwert-Assertions umstellen, keine Toleranzaufweitung mehr. Aufwand: 0,5 bis 1 Tag.
2. **Flaky-Rate erheben:** Regression 10-mal laufen lassen (etwa 18 Minuten je Lauf, rund 3 Stunden Laufzeit), rote Zeilen je Lauf protokollieren. Aufwand: 1 Stunde Arbeit, 3 Stunden Wartezeit.
3. **Einen Regelsatz für Spiel und Validator:** ein gemeinsamer Test, der dieselbe Eingabe durch beide schickt (B-1, H2/H3), plus Regression-Pflichtlauf vor jeder Abnahme. Aufwand: 0,5 Tag.

## 7. Recherchen dieser Runde und Lernlog-Zeilen

**R1: Tester-Abdeckung.** Quellen: Nielsen/Landauer, Cornell- und UMD-Vorlesungsfolien (sekundär); NN/g-Seite ohne Prozentzahlen. Ergebnis: Ein Tester etwa 31 bis 35 %, fünf 75 bis 84 %. Konfidenz: mittel. [Beleg]
**R2: Wald gegen Wilson bei kleinem n.** Quellen: Wikipedia und Lehrfolien; Brown/Cai/DasGupta (projecteuclid) gesperrt (PROVENANCE_REQUIRED, nicht umgangen). Ergebnis: Wilson für Anteile nahe 0/1 und kleines n. Konfidenz: mittel. [Beleg]
**R3: Godot-Render-Messung.** Quelle: godot-docs `class_performance.rst`; die RenderingServer-Seite war abgeschnitten, `--doctool` lieferte leere Beschreibungen. Ergebnis aus der Doku allein: nicht belegt, ob Headless-Zähler Culling enthalten; belegt ist nur die Repo-Messung 1,6 M gegen 0,62 M. Konfidenz: niedrig (Doku), hoch (Repo). 
**Nicht erreichbar:** wiki.openttd.org (client_error), Reddit (nicht umgangen), Google-Flaky-Blog (kein Text).

| Datum | Situation | Kompromiss/Lücke | Zähler | Folge |
|---|---|---|---|---|
| 2026-11-03 | Abnahme A21 | Wall-Clock mit Toleranz 150+40 s | 2 | Tick-Assertion |
| 2026-11-03 | Integration W2 | Regression nicht neu gelaufen | 2 | Pflichtlauf |
| 2026-11-03 | Perf-Aussagen | Zählwert statt Livewert | 3 | Messart-Feld |
| 2026-11-03 | Validator/Spiel | Verschiedene Regeln | 2 | Gemeinsamer Test |

## 8. Vorschläge für Skill-Änderungen (nur Vorschläge)

1. **Teil C, Tests:** "Keine Wall-Clock-Assertions; Toleranz nie aufweiten ohne Ursache." Marke [Repo, hoch]; Quelle: `d07_abnahme.gd:271`.
2. **Teil C, Perf:** "Jede Perf-Zahl nennt Messart (gemessen/gezählt/berechnet) und Last." Marke [Repo, hoch]; Quelle: S7 1,6 M gegen 0,62 M.
3. **Teil D, Statistik:** "Anteile mit Wilson-Intervall, n nennen." Marke [Beleg sekundär]; Quelle: R2.
4. **Teil D, Flaky:** "Flaky-Rate je Sprint erheben." Marke [Einzel]; Quelle: Lernbericht (Unsicherheit), Google-Blog nicht lesbar.
