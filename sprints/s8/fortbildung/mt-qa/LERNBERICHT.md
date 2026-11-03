# Lernbericht Daniel (QA-Lead): Fortbildung Games-QA und Testautomatisierung

Stand 03.11.2026. Auftraggeber Basti. Ergebnis der Fortbildung: `/tmp/claude-0/gd/skills/mt-qa/SKILL.md` (Teil A Fachwissen, Teil B Projektwissen, Teil C Lücken). Dieser Bericht enthält Selbstanalyse, Lernfragen mit Antworten, Quellen mit Einstufung und die Grenzen der Recherche. Im Repo wurde nichts geändert, kein Commit. Einziges Experiment lief in einem eigenen Scratchpad-Projekt (siehe Abschnitt 7).

Kennzeichen: [K] Konsens, [S] Streit, [E] Einzelmeinung oder Anbieterblog, [V] Zahl aus gelesener Quelle, [W] Fachwissen ohne Quellenlesung in dieser Runde, [X] eigenes Experiment, [R] Belegstelle im Repo.

## 1 Kurzfassung

1. Der größte Wissensmangel lag bei Messmethoden: gezählt, live, headless und Zielrechner wurden vermischt (1,6-Mio-Befund, Faktor-2,5-Messfehler, Draw-Call-Fehlzuordnung "Lkw").
2. Der zweitgrößte lag bei Aussagekraft von Tests: grün auf Platzhalterkarten, Bot-Quoten als Beleg gelesen, Spiel und Validator mit verschiedener Regel.
3. Flakiness war ein Wanduhr-/Lastproblem (H29, A21), nicht Pech; die Regressionssuite ist mit 8 bis 25 Minuten Laufzeit (je nach Last) an der Grenze dessen, was man vor jedem Merge fährt.
4. Was gut war: Prüfsummen und Parität, Seeds, Sinnproben (Gate absichtlich rot machen), echte Maus, Trennung Werkzeug-/Spielfehler, ehrliche Kennzeichnung "Sandbox, kein Zielrechner".
5. Was fehlt: kein automatischer Bildvergleich, keine Stufung der Regression, keine definierte Schwere/Priorität-Skala, kein Verfahren für n=1-Playtests, Windows-Verhalten ungetestet.

## 2 Selbstanalyse: Wo fehlte Wissen, wo lag QA falsch oder unsicher

Alle Belege relativ zu /home/claude/mega-tycoon.

### 2.1 Perf-Zählfehler 1,6 Mio
- Befund: Die Zahl 1,62 M Dreiecke war eine Zählung ohne Culling und ohne Sichtweite. 91,9 % entfielen auf Bäume (1.487.668 Dreiecke, 70 MultiMeshes, 11.500 Bäume); der Renderer zeichnete sie ab 1,8 km gar nicht. Live lag die Szene maximal bei ca. 0,62 M und 136 Draw Calls. [R sprints/s8/design-sprint/phase4/felix_perf_aufschluesselung.md §1-3; ta_welle2.md §5]
- Ursache im Verfahren: Das Gate war als "Szene gezählt" definiert (phase3/14_prototyp_plan.md §4, "2-stufig: (1) Szene gezählt"). Eine Zählung ohne Renderer ist eine obere Schranke, kein Messwert.
- Dazu: Der headless-Dummy-Renderer hält keine MultiMesh-Instanz-Transforms; Nah- und Fern-LOD zählen doppelt (headless 1,14/1,60 M gegen live 0,73/0,60 M) [R integration_w2.md I12].
- Fehlendes Wissen: Wie Godot die Monitore definiert. Laut Doku schließen RENDER_TOTAL_* gecullte Objekte aus, und Primitive sind durch Depth-Prepass und Schatten typisch zwei- bis dreimal höher als die Szenen-Vertexzahl [V Q13].
- Verwandt: Draw-Call-Fehlzuordnung S7. 4.066 DC in der 5.000-Lkw-Übersicht schienen "Lkw" zu sein, kamen aber von 3.366 Straßenfeld-Meshes und 100 Lagern; Fahrzeuge kosteten 2 DC [R sprints/s7/block-b/felix2.md §1]. Retro nennt "Perf-Messfehler Faktor 2,5", durch Nachrechnen gefunden [R sprints/s7/review_retro.md].
- Lehre: Methode im Dateikopf und in jedem Bericht; bei Auffälligkeit Aufschlüsselung vor Maßnahme.

### 2.2 headless gegen opengl3
- Stand: perf_s7 braucht xvfb + opengl3, "headless liefert 0 und wird als FAIL gewertet" [R slice/tests/perf_s7.gd Kopf]. Das Team wusste es praktisch, die Grundlage dafür (Doku: "Most functions from RenderingServer will return dummy values", Q14) war nirgends notiert.
- Eigenes Experiment [X]: In Godot 4.7.2 liefert headless prims=0, dc=0, obj=0, meldet aber trotzdem den Treibernamen "opengl3" (Treibername ist also kein Beleg für aktives Rendern). Unter xvfb + opengl3 meldet der Adapter "llvmpipe (LLVM 20.1.2, 256 bits) | Mesa", eine Standardkugel zählt 4.224 Primitive, 1 Draw Call.
- Unsicher blieb: Wie sehr sich Software-GL-Zählwerte und Bilder von der Basti-GPU (RTX 3080 Ti, Windows) unterscheiden. Zählwerte sollten übereinstimmen (perf_s7-Annahme), geprüft ist es nicht.

### 2.3 Regression 26 Minuten
- Belegt sind andere Zahlen: 478 s (S6, 12 Suiten), 1.090 s (Stand 03.11., 24 Zeilen), 1.361 s, 1.396 s, 1.489 s unter Last, "ca. 30 min" in einer Notiz [R tests/d07_regression_summary.md; sprints/s6/block-c/daniel.md; sprints/s7/block-a/mira.md und daniel.md; phase4/felix_welle1.md; s7/block-b/tobias.md]. Eine Zahl "26 min" habe ich im Repo nicht gefunden.
- Zeitfresser: d08_bankrott 264,6 s, perf_s7 150 bis 300 s unter Software-GL, die xvfb-Suiten.
- Fehlendes Wissen: Teststaffelung. Google-Praxis: Größenklassen und Mischung 80/15/5 [V Q3]; Fowler: Tests so weit unten wie möglich, schnelle Tests früh [V Q1]. Wir fahren eine Stufe für alles. Konsequenz: Entwickler fahren die Gesamtsuite selten, Einzelne ersetzen sie durch Teilmengen ("kein Bestandscode geändert, Regression nicht neu gelaufen", integration_w2.md).

### 2.4 Flakiness
- H29: place_hq startet Tempo 1, _physics_process tickt parallel zu run_ticks; 10 von 40 rot ohne Last, 32/40 bei 60 ms künstlicher Last, 40/40 bei 120 ms, 0/120 mit set_speed(0) [R sprints/s6/block-c/daniel.md]. Das ist vorbildlich nachgestellt (Last erzeugen statt Wiederholen).
- A21 (Panel-Slide ≤ 150 ms) misst Wanduhr, unter Last 191/230 ms: "bleibt wackelig", Regel "Suiten nur nacheinander" [R ebd.].
- Fehlendes Wissen: Quarantäne-Verfahren mit Frist, Schwellen (Google ca. 0,15 %, ab etwa 1 % verlieren Tests Wert, Q3), Ursachenklassen (Q2). Wanduhr-Tests sollten auf Sim-Zeit oder breite Toleranz umgestellt werden.

### 2.5 Messtoleranzen
- Gut: Toleranzen vor der Messung (±25 %, Fahrzeuge 0,9 bis 1,2 ×), "bewusst, Grund" für Abweichungen, E6-Fall mit benannter Toleranz 1,3 × W/2 [R phase3/14_prototyp_plan.md §3; integration_w2.md I11].
- Unsicher: Die 10-%-Streuungsregel stammt aus meiner Annahme [R design/qa/day1-3/benchmark_pruefplan.md §1]; ohne Konfidenzintervalle (Q24) und ohne Messbias-Gegenmaßnahmen außer Reihenfolge-Randomisierung (Q25). Die 1k-Messung war in beiden Läufen "instabil" (28 %/51 %), wurde nicht wiederholt [R design/qa/day4-6/f05_messprotokoll.md §2].
- Float-Rundung: Sim-Takt-Prüfung zuerst 4/5 Ticks, dann mit definiertem Rest 0,5 repariert [R integration_w2.md §2].
- Baseline-Rebase: perf_s7-Baseline wurde nach der DC-Optimierung auf "Nachher-Werte" gesetzt [R s7/block-b/felix2.md §4]; relativ +10 % gegen die jeweils letzte Baseline erlaubt Kriechen (Q42: absolute Budgets plus relative Gates).

### 2.6 Visuelle Abnahme
- Praxis: Bilder per *_shots.gd unter xvfb, Urteil per Auge (abgenommen / mit Auflage / nicht abgenommen) [R sprints/s7/abnahme/daniel_d09.md]; Fixpass W2 mit Vorher/Nachher-Paaren [R phase4/fixpass_w2.md]. Kontrast: farbcheck.py (Machado 2009, ΔE2000 ≥ 10), analytisch WCAG in proto_schilder_test [R].
- Lücke: kein automatischer Bildvergleich; keine Aussage, wie stark Software-GL-Bilder gegen Basti-Bilder abweichen. Wissen jetzt vorhanden: pixelmatch-Schwelle 0,1 und AA-Falle (Q19), Playwright 0,2 und Plattform-Baselines (Q20), llvmpipe-Konformität (Q41).
- Grenze: Look und Spielgefühl bleiben subjektive Urteile (AD, Basti).

### 2.7 Bot-Playtests
- d08_bankrott: Kopf sagt selbst "KEIN Spielerbeleg", Bot und Modell sind Setzungen, KALIB "gefittet, nicht gemessen" [R slice/tests/d08_bankrott.gd]. Ergebnisse sprangen von 2/35/38 % (S6) auf 15/17/18 % (S7) durch Kalibrierung [R].
- Fehlendes Wissen: Konfidenzintervall. Bei n=100 und p=15 % beträgt der Standardfehler 3,6 Pp (95 % rund ±7 Pp, rechnerisch); der Korridor ±5 Pp ist nur als Drift-Wächter bei festen Seeds sinnvoll, nicht als Schätzer. Das ist unsere Rechnung, nicht aus einer Quelle.
- Einordnung Branche: Bots gut für Abdeckung/Smoke/Exploits, nicht für Spaß [V Q35, Q39]; Spieletest überwiegend manuell [V Q29]; RL-Agenten finden Exploits [V Q30, nur Abstract].

### 2.8 Test der UI und Schilder
- Stark: proto_schilder_test 51 Prüfungen, s7_industrie 66, u03_play 12 Fälle "0 stumm", d08_maus mit echter Projektion [R].
- Falsch gelegen: H1 (Stadtlabels 100-350 px versetzt) und H2 (Brückenrampe) fanden die Suiten nicht, weil sie auf der Platzhalterkarte liefen; play.sh projizierte auf y = 0 [R s7/abnahme/daniel_d09.md "Vorab: Werkzeugfehler"; s7/review_retro.md].
- Unsicher: Zielpfeil-Scan nur 1 Treffer in 100 Ansichten, aber nur eine Ansichtenmenge [R s6/block-c/daniel.md].

### 2.9 Windows-Rechner Basti gegen Linux-Sandbox
- Basti: Windows, Ryzen 7 5800X3D, RTX 3080 Ti, gl_compatibility, 89,7 FPS Median, p95 22 ms [R sprints/s6/messung/f12_zielrechner_01-11.txt]. Sandbox: Linux, 2 vCPU, Software-GL.
- Wirkliche Fallen: Export ohne Kenney-GLBs und globalize_path (B-2), Messung "ohne Look" [R s6/block-c/daniel.md]; Export-Templates 4.7.2 nötig [R slice/export_presets.cfg]; Dateinamen-Case (Windows/macOS insensitiv, Linux und PCK sensitiv, Q12) wird von keiner Suite geprüft; play.sh/xvfb laufen nur unter Linux.
- Unklar: TIME_PROCESS 32 ms bei Frame Median 9,4 ms; mein früherer Kommentar "Summe über Ticks" widerspricht der Doku-Definition "Zeit für einen Frame" (Q13) und ist ungeprüft.

### 2.10 Messdaten-CSVs
- CSVs unter res:// werden von Godot als Übersetzung importiert: 27 .translation-Dateien liegen in slice/tests/ und sind in .gitignore eingetragen (Zeile slice/tests/*.translation) [R]. proto_mass schreibt deshalb nach außerhalb res:// [R slice/tests/proto_mass.gd Kopf]. Das Wissen war da, entstand aber aus Schaden.
- Offen: kein einheitlicher Kopf (Seed, md5, Methode, Einheit) in den CSVs; perf_s7-Baselines tragen keinen Methodenvermerk in der Datei.

### 2.11 Testdaten gegen Vertragsdaten
- B-1: Vorschau-Lizenzfaktor ≠ Spielpreis (2 von 8 Städten stimmten) [R sprints/s6/block-c/daniel.md]; H2: Validator "alle Ketten erreichbar", Spiel lehnt Querungen ab [R s7/abnahme/daniel_d09.md]; H3: HQ-Vorschau schreckt vom besten Start ab. Regel aus Retro: jede Spielerzahl bekommt einen Test gegen den Spielwert; Spiel und Validator rechnen dieselbe Regel [R].
- Theorie dahinter: Orakelproblem (Q40) und Consumer-driven Contracts (Q1). Vertragsänderung mit Eintrag: M8 Weiler [R phase4/fixpass_w2.md]; Regelwerk-Rot personenwagen 1,21 × [R phase4/felix_welle1.md §4].

### 2.12 Playtest mit Basti
- n=1, Auftraggeber, Experte; Aufgabenkarten von Aylin, Protokoll durch mich [R sprints/s8/design-sprint/phase4/aufgabenkarten_v1_1.md "Für uns"]. Fehlendes Wissen: Nielsen-Landauer-Modell und Streit (Q6, Q7), Think-aloud-Regeln (Q8), Bias in Playtests (Q36, Q37). Das Kartenformat folgt schon "kein Richtig oder Falsch" und "nur notieren, nicht verteidigen"; stimmig mit Q36.

## 3 Lernfragen (priorisiert) und Antworten

P1 Wie unterscheide ich gezählte, headless gemessene, live gemessene und auf dem Zielrechner gemessene Perf-Werte, und welche darf ein Gate nutzen?
- Antwort: Zählung ohne Renderer = obere Schranke; headless = 0 oder Dummy [Q14, X]; live (xvfb) = Zählwerte der gerenderten Szene, ohne Gecullte, Primitive inkl. Schattenpass [Q13]; Zielrechner = einzige FPS-/Zeitaussage. Gate nutzt live; fehlt das Renderziel, dann "gezählt mit Sichtweite" ausdrücklich als obere Schranke (so seit Welle 2). Methode gehört in jeden Dateikopf.

P2 Wie stufe ich Regression und Flaky-Tests, damit die Suite vor jedem Merge laufen kann?
- Antwort: Größenklassen und 80/15/5 [Q3]; nicht-deterministische Tests in Quarantäne mit Frist, Ursache nach Klassen fixen [Q2]; Flakerate-Ziel ca. 0,15 %, ab 1 % verlieren Tests Wert [Q3]; Wanduhr-Tests umstellen. Vorschlag: schnelle Stufe (headless ohne d08_bankrott/perf) vor Merge, volle Regression nachts/vor Release.

P3 Wie messe ich Frame-Zeiten statistisch sauber (Perzentile, Streuung, Läufe, Build-Typ)?
- Antwort: Frametimes statt FPS, Definition von "1 % Low" nennen [Q27]; Median, p95, Max, Streuung; ≥3 verschränkte Läufe, Warm-up verwerfen, Konfidenzintervalle [Q24], Setup randomisieren [Q25]; Perzentile nicht mitteln [Q26, umstritten]; Release-Export für Gate-Werte [R benchmark_pruefplan.md §5].

P4 Wie vermeide ich, dass Tests auf Test-/Platzhalterdaten grün sind und die echte Karte/Daten rot?
- Antwort: Test schreiben, sobald echte Daten existieren; gleiche Regel in Spiel und Validator; Vertragsprüfung beim Anbieter [Q1]; Orakel unabhängig [Q40]; Matrix über Seeds und Karten (S7-Seeds im Spiel, nicht nur im Python-Validator).

P5 Was überträgt sich von der Linux-Sandbox auf Bastis Windows-Rechner und was nicht?
- Antwort: Überträgt sich: Zählwerte, Sim-Ergebnisse (Prüfsummen), Logik. Nicht: Millisekunden, FPS, Bildpixel, Treiberfehler, Export-/Pfadfehler, Dateinamen-Case [Q12], Eingabegeräte. Gegenmaßnahmen: Export-Check (--export-pack) in Regression (Retro S6 Vorschlag), Bench auf Zielrechner mit Pflichtfeldern, Baselines nie plattformübergreifend [Q20].

P6 Wie gehe ich mit Screenshot-Diffs und visueller Abnahme um?
- Antwort: Diff nur im selben Treiberpfad und mit festen Kameras/Tick; Schwelle starten bei 0,1 (pixelmatch) bzw. 0,2 (Playwright) und kalibrieren; AA-Pixel-Falle beachten [Q19, Q20]; Look-Urteile mit Vorher/Nachher-Paaren und Protokoll (Kamera, Urteil, Beleg); Kontrast 3:1 für Symbole [Q28], ΔE ≥ 10 plus Form [R].

P7 Wie bewerte ich Bot-Playtests richtig?
- Antwort: Bot = Drift-Wächter und Exploit-Suche, kein Spielerbeleg [Q35, Q39, R d08_bankrott]; Konfidenzintervall der Quote ausweisen; Kalibrierung als Setzung kennzeichnen; Seeds festschreiben; Sinnprobe, dass der Wächter anschlägt.

P8 Wie plane und werte ich Playtests mit Basti (n=1) aus?
- Antwort: Ein Tester findet im Mittel 31 % der Probleme [Q6]; Streit über 5-Nutzer-Regel [Q7]; Hypothesen statt Beweise; Think-aloud, Moderator schweigt [Q8]; neutrale Fragen [Q37]; nicht erklären, Stolpern ist Daten [Q36]; zweiten Menschen anstreben; Aussagen wörtlich ablegen.

P9 Wie teste ich UI und Schilder belastbar?
- Antwort: Invarianten maschinell (Rahmen im Viewport, Überlappung, Mindestschrift, Anker), Matrix Zoom × Kamera × Welt × Seed, echte Eingabe über warp_mouse/push_input, Texte gegen Ursache, Scans mit fester Ansichtenzahl; Platzhalterkarte allein reicht nicht.

P10 Wie führe ich Bug-Triage mit Schwere und Priorität?
- Antwort: Schwere (Auswirkung, QA) und Priorität (Dringlichkeit, PO) getrennt [Q38, E]; Nielsen-Skala 0-4 mit Häufigkeit, Auswirkung, Persistenz, mehrere Bewerter [Q9]; Repro als play.sh-Befehle; Werkzeugfehler getrennt; Defektcluster beachten [Q10].

P11 Wie lege ich Messtoleranzen und "bewusste Abweichungen" sauber fest?
- Antwort: Toleranz vor der Messung, hart/weich, Grenze inklusiv/exklusiv, Rundungsregel; Abweichung nur mit Grund, benannter Toleranz und Optionen [R E6]; keine Wertedrehung; Messbias und Streuung ausweisen [Q24, Q25].

P12 Welche Testwerkzeuge/Strukturen gibt es für Godot und was lohnt für uns?
- Antwort: GUT 9.7.1 für Godot 4.7.x [Q16], gdUnit4 v6.2.1 für 4.5-4.7.1 (4.7.2 nicht genannt) mit Scene-Runner und Fuzzer [Q18]; CLI-Flags [Q11]; CI-Fallen mit .godot-Cache [Q17]; xvfb-Grenzen [Q15]. Unsere SceneTree-Suiten bleiben; ein Framework lohnt für Unit-Isolation, Doubles, JUnit-Reports, nicht als Pflicht. Property-/Fuzz-Ansätze für Invarianten lohnen als Experiment.

## 4 Quellen mit Einstufung

Abruf am 03.11.2026 per WebFetch (Antworten kommen durch ein Zusammenfassungsmodell, daher sind wörtliche Zitate nur dort belastbar, wo das Tool sie als Zitat auswies). "gelesen" = Inhalt kam als Fetch-Ergebnis, nicht nur als Suchtreffer.

| ID | Quelle | Art | Einstufung | Verwendet für |
|---|---|---|---|---|
| Q1 | https://martinfowler.com/articles/practical-test-pyramid.html | Fachartikel | K | Pyramide, "push down", Verträge (CDC), Flakiness von E2E |
| Q2 | https://www.martinfowler.com/articles/nonDeterminism.html | Fachartikel | K | 5 Ursachen, Quarantäne, Fixmuster |
| Q3 | https://whatot.github.io/Software-Engineering-at-Google/src/Chapter-11_Testing_Overview.html | Buchkapitel (Mirror) | K für Größen, E für Zahlen | 0,15 %, 1 %, 80/15/5, Beyoncé-Regel |
| Q4 | https://testing.googleblog.com/2017/04/where-do-our-flaky-tests-come-from.html | Blog | nur Kommentare lesbar; keine Hauptzahlen gelesen | Kommentare: 10× grün, 1/6 Produktfehler |
| Q5 | https://www.besthub.dev/articles/analyzing-the-origins-of-flaky-tests-size-tooling-and-instability-at-google-da99e297788a | Sekundärquelle | E | 4,2 M Tests, ~63.000 (≈2 %) flaky pro Woche; klein 0,5 %, mittel 1,6 %, groß 14 % |
| Q6 | https://www.nngroup.com/articles/why-you-only-need-to-test-with-5-users/ | Fachartikel | K Formel, S Anwendbarkeit | 31 %, 85 %, 3×5 statt 15 |
| Q7 | https://humanfactors.com/newsletters/enough_is_enough.asp | Fachartikel | S (Gegenposition) | Spool/Schroeder 35 %, Faulkner 85 % (55-100 %), 10: 95 %, 15: 97 % |
| Q8 | https://www.nngroup.com/articles/thinking-aloud-the-1-usability-tool/ | Fachartikel | K | Think-aloud-Regeln und Grenzen |
| Q9 | https://www.nngroup.com/articles/how-to-rate-the-severity-of-usability-problems/ | Fachartikel | K | Skala 0-4, drei Faktoren, mehrere Bewerter |
| Q10 | https://astqb.org/istqb-foundation-level-seven-testing-principles/ | Standardnah | K | sieben Grundsätze |
| Q11 | https://raw.githubusercontent.com/godotengine/godot-docs/master/tutorials/editor/command_line_tutorial.rst | Doku (Roh) | K | CLI-Flags |
| Q12 | https://raw.githubusercontent.com/godotengine/godot-docs/master/tutorials/best_practices/project_organization.rst | Doku (Roh) | K | Case-Sensitivität, snake_case |
| Q13 | https://raw.githubusercontent.com/godotengine/godot-docs/master/classes/class_performance.rst | Doku (Roh) | K | Definition RENDER_TOTAL_*, TIME_PROCESS |
| Q14 | https://raw.githubusercontent.com/godotengine/godot-docs/master/classes/class_renderingserver.rst | Doku (Roh, nur Teil gelesen) | K | "dummy values" bei --headless |
| Q15 | https://github.com/godotengine/godot/issues/38428 | Issue | E (Godot 4.0, alt) | xvfb mit Vulkan abgestürzt |
| Q16 | https://raw.githubusercontent.com/bitwes/Gut/master/README.md | README | K | GUT-Versionen, Features |
| Q17 | https://github.com/bitwes/Gut/issues/491 | Issue | E (GUT 9.0.1/Godot 4.0.2) | .godot-Cache in CI |
| Q18 | https://raw.githubusercontent.com/MikeSchulze/gdUnit4/master/README.md | README | K | gdUnit4-Versionen, Scene-Runner, Fuzzer |
| Q19 | https://raw.githubusercontent.com/mapbox/pixelmatch/main/README.md | README | K | threshold 0,1, AA-Falle |
| Q20 | https://raw.githubusercontent.com/microsoft/playwright/main/docs/src/test-snapshots-js.md | Doku | K | threshold 0,2, Plattform-Baselines |
| Q21 | https://apple.github.io/foundationdb/testing.html | Doku | K | deterministische Simulation, 10:1, zehntausende Läufe/Nacht |
| Q22 | https://raw.githubusercontent.com/HypothesisWorks/hypothesis/master/README.md | README | K | Property-Based, kleinster Fehlerfall |
| Q23 | https://gafferongames.com/post/fix_your_timestep/ | Fachartikel | K | fester Zeitschritt, Akkumulator |
| Q24 | https://blog.acolyer.org/2017/11/06/statistically-rigorous-java-performance-evaluation/ | Zusammenfassung (Georges et al. 2007) | K | Konfidenzintervalle, "beste von 30" irreführend |
| Q25 | https://sape.inf.usi.ch/publications/asplos09 | Abstract (Mytkowicz et al. 2009) | K | Messbias, 133 Arbeiten, Randomisierung |
| Q26 | https://bravenewgeek.com/everything-you-know-about-latency-is-wrong/ | Blog (Sekundär zu Tene) | S (Leser widersprechen) | Perzentile, Coordinated Omission |
| Q27 | https://www.capframex.com/blog/post/Explanation%20of%20different%20performance%20metrics | Werkzeughersteller | S (Definitionen uneinheitlich) | 1-%-Low-Definitionen |
| Q28 | https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html | Standard | K | 3:1 für UI/Grafik |
| Q29 | https://arxiv.org/abs/2103.06431 | Survey-Abstract (2021) | K | Spieletest überwiegend manuell |
| Q30 | https://arxiv.org/abs/2103.15819 | Paper-Abstract (2021) | E (nur Abstract) | RL-Agenten finden Exploits |
| Q31 | https://gdconf.com/article/sea-of-thieves-devs-share-automated-testing-tips-at-gdc-2019/ ; https://www.gdcvault.com/play/1026366/Automated-Testing-of-Gameplay-Features | GDC-Abstract | nur Ankündigung gelesen | Automatisierte Gameplay-Tests "von Anfang an" |
| Q32 | https://gdcvault.com/play/1027345/Lessons-Learned-in-Adapting-the | GDC-Abstract | nur Abstract | Sea-of-Thieves-Methodik für Minecraft |
| Q33 | https://www.gdcvault.com/play/1021825/Automated-Testing-and-Instant-Replays | GDC-Abstract (2015) | nur Abstract | Determinismus + Input-Replay |
| Q34 | https://autotestingroundtable.com/ | Veranstalterseite (GDC 2024) | E | "still a rarity" |
| Q35 | https://www.gamedeveloper.com/programming/testing-games-with-ai-bots | Fachartikel | K qualitativ, keine Zahlen | Bots: Stärken/Grenzen |
| Q36 | https://www.gamedeveloper.com/design/what-should-a-playtest-smell-like- | Fachartikel | K qualitativ | Playtest-Regeln und Fallen |
| Q37 | https://gamesuserresearch.com/how-to-run-unbiased-player-interviews/ | Fachseite | K qualitativ | neutrale Fragen |
| Q38 | https://marker.io/blog/bug-severity-vs-priority | Anbieterblog | E | Schwere/Priorität, 5 Stufen |
| Q39 | https://www.ixiegaming.com/blog/scaling-game-qa-with-automation-vision-strategy-reality/ | Anbieterblog | E (Zahlen nicht prüfbar) | Was automatisieren; 98 %/5×/75 % nicht übernommen |
| Q40 | https://discovery.ucl.ac.uk/1471263/ | Survey-Abstract (Barr et al., TSE 2015) | K | Orakelproblem |
| Q41 | https://www.khronos.org/news/permalink/mesas-llvmpipe-is-opengl-4.5-conformant | Pressemitteilung (2020) | K | llvmpipe GL-4.5-konform |
| Q42 | https://web.dev/incorporate-performance-budgets-into-your-build-tools | Fachartikel | K | Budgets automatisch in CI |
| X1 | eigenes Experiment (Abschnitt 7) | Messung | [X] | headless 0 gegen xvfb llvmpipe |

Insgesamt 42 Quellen plus Experiment (Q31 enthält zwei URLs, also 43 Adressen); Mischung aus Dokumentation/READMEs, Fachartikeln, Abstracts/Ankündigungen und einigen Anbieter- oder Sekundärquellen, jeweils in der Spalte Art/Einstufung ausgewiesen.

### Reddit
r/QualityAssurance, r/gamedev, r/godot, r/IndieDev, r/softwaretesting: Direktabruf von reddit.com lieferte "SITE_BLOCKED" (Factorio-Testprozess-Thread in r/gamedev). Suchtreffer verwiesen nur auf Mirror-Dienste; die habe ich bewusst nicht als Umgehung benutzt. Community-Erfahrungen aus Reddit fehlen deshalb. Ersatzweise: GitHub-Issues (Q15, Q17) und Anbieterblogs, die als Einzelmeinung gelten.

## 5 Konsens, Streit, Einzelmeinung

Konsens:
- Testpyramide als Heuristik, Tests so weit unten wie möglich (Q1, Q3).
- Determinismus ist Voraussetzung für reproduzierbare Tests; fester Zeitschritt, Replays (Q23, Q33, Q21).
- Flaky Tests ernst nehmen, quarantänisieren, Ursache fixen (Q2).
- Statistik: Einzelzahl/Bestwert irreführend; Intervalle, Median, Streuung (Q24, Q25).
- Bots sind Ergänzung, nicht Ersatz für Menschen (Q35, Q29, Q39).
- Kontrast 3:1 für Symbole (Q28); Think-aloud-Regeln (Q8).

Streit:
- 5-Nutzer-Regel: Nielsen 85 % (Q6) gegen Spool/Schroeder 35 % und Faulkner-Spanne 55-100 % (Q7).
- Perzentile mitteln, Median-Nutzen: Tene/Treat (Q26) mit Leserwiderspruch; unser Gate nutzt Median der Laufmediane.
- 1-%-Low-Definition (Q27).
- Pyramidenform (Trophy, Honeycomb) [W, ohne gelesene Quelle].
- Schwere-Skalen: keine Norm, Teams verschieden (Q38).
- Wie viel Flakiness ist akzeptabel: Google 0,15 % gegen "ab ca. 1 % wertlos" (beides Q3, kein Widerspruch, aber Spanne).

Einzelmeinung (nicht übernehmen ohne Gegenprüfung):
- Anbieterzahlen Q39 (98 % weniger Defekt-Leckage, 5× Effizienz, 75 % Kostenersparnis, kein Maßstab).
- Marker.io-Beispiele (Web, nicht Spiele) (Q38).
- Issue-Berichte Q15 (Godot 4.0) und Q17 (GUT 9.0.1, Godot 4.0.2): Versionen alt.
- RL-Test-Paper (Q30): nur Abstract.

## 6 Zahlen mit Beleg

| Zahl | Quelle | Anmerkung |
|---|---|---|
| Flakerate Google ca. 0,15 %; ab ca. 1 % verlieren Tests Wert | Q3 | wörtliche Aussage des Buchkapitels |
| 80 % / 15 % / 5 % klein/mittel/groß | Q3 | nach Testanzahl, "jedes Team anders" |
| 4,2 Mio Tests, ~63.000 (≈ 2 %) mit mindestens einem Flake pro Woche; klein 0,5 %, mittel 1,6 %, groß 14 % | Q5 | Sekundärquelle, Primärartikel nicht lesbar |
| "1,5 % der Läufe, 16 % der Tests" | nicht verifiziert | verbreitete Zitierung, hier nicht belegt |
| 31 % je Nutzer, 85 % bei 5 Nutzern (rechnerisch 84 %) | Q6 | 1-(1-0,31)^5 |
| 35 % (Spool/Schroeder); Faulkner 5 Nutzer 85 % (55-100 %), 10 Nutzer 95 % (min 82 %), 15 Nutzer 97 % (min 90 %) | Q7 | |
| Severity 0-4; Mittel ca. 3 Bewerter | Q9 | |
| pixelmatch threshold 0,1 | Q19 | Default |
| Playwright threshold 0,2 | Q20 | Default |
| WCAG 1.4.11: 3:1 | Q28 | 2,999 fällt durch |
| FoundationDB: ca. 10:1 simulierte zu realer Zeit, zehntausende Simulationen je Nacht, ca. 1 Billion CPU-Stunden | Q21 | |
| Georges: bis 16 % irreführende Vergleiche, bis 3 % falsche Schlüsse; Student-t unter 30 Messungen | Q24 | |
| Mytkowicz: 133 Arbeiten, keine berücksichtigte Messbias hinreichend | Q25 | |
| web.dev: Beispiel-Budget 250 KB (webpack-Standard), Lighthouse-Score ≥ 90 | Q42 | Web-Beispiele, nicht für Spiele; Prinzip (Budget automatisch in CI prüfen) übertragbar |
| Tene/Treat Beispiel: 0,95^200 ≈ 0,003 %; echte Verteilung vs. gemeldet 100 s gegen 1 ms | Q26 | umstritten |
| RENDER_TOTAL_PRIMITIVES typisch zwei- bis dreifach durch Prepass/Schatten | Q13 | Godot-Doku |
| 4.224 Primitive, 1 DC für Standardkugel unter xvfb; 0/0/0 headless | X1 | Godot 4.7.2 |

## 7 Eigenes Experiment (X1)

Minimales Projekt im Scratchpad (`/tmp/claude-0/-home-claude/c5d1740c-2845-5dd4-b3b3-e4395bd01f30/scratchpad/lab/`), Renderer gl_compatibility, ein SphereMesh und eine Kamera, nach drei Frames Performance-Monitore gelesen.
- `godot --headless`: RENDER_TOTAL_PRIMITIVES/DRAW_CALLS/OBJECTS = 0/0/0, TIME_PROCESS 0, Adapter-Name leer; `get_current_rendering_driver_name()` meldet dennoch "opengl3".
- `xvfb-run ... --rendering-driver opengl3`: 4.224 Primitive, 1 DC, 1 Objekt; Adapter "llvmpipe (LLVM 20.1.2, 256 bits)", Hersteller "Mesa".
Grenzen: eine Szene, eine Mesa-Version, keine Aussage zu Schatten/Prepass, keine Aussage zu Windows-Treibern.

## 8 Einschränkungen der Recherche (ehrlich)

- Reddit nicht lesbar (SITE_BLOCKED), keine Umgehung. Die geforderte Community-Sicht ist damit schwach abgedeckt.
- WebFetch liefert Zusammenfassungen eines kleinen Modells; Primärzahlen können verkürzt sein. Mehrere Fetches lieferten nur Teilinhalt (Google-Testing-Blog nur Kommentare, RenderingServer-Klassenreferenz ohne get_rendering_info-Abschnitt, GDC-Vault nur Abstracts). Zwei Fetches wurden vom Tool mangels Herkunft abgelehnt (Google-Buchkapitel auf abseil.io, Gil-Tene-Folien); an deren Stelle stehen ein Buch-Mirror (Q3) und ein Sekundärartikel (Q26). Die Godot-Forumsseite zum --headless-Verhalten war nicht lesbar (Weiterleitung nicht freigegeben).
- Die ersten Google-Zahlen zur Flakiness (1,5 % / 16 %) konnte ich nicht belegen und habe sie nicht als Fakt übernommen.
- Hypothesis-Dokumentation (readthedocs) nicht lesbar; nur das README. Stateful-Testing und Datenbank der Gegenbeispiele sind nicht belegt.
- GDC-Vorträge: nur Abstracts/Ankündigungen, Inhalte hinter dem Vault. Aussagen "Sea of Thieves/Minecraft machen X" beschränken sich auf das, was die Abstracts nennen.
- Es gab keine eigene Ausführung von GUT, gdUnit4, Hypothesis oder Screenshot-Diffs; alles daraus ist Dokumentationswissen.
- Das Repo habe ich nur gelesen. Die genannte "Regression 26 min" ist dort nicht belegt (belegt: 8 bis 25 min je Last). V3 und V5 der Messkarten fehlen in der Tabelle 14 §3. Ob play_session_d09.patch im Repo gelandet ist, habe ich nicht geprüft.
- Fachwissen, das ich nicht durch Quellenlesung stützen konnte, ist im SKILL mit [W] markiert (u. a. Pyramidenform-Streit, Games-QA-Testarten, Ökonomie-Tests).
- Statistische Aussagen zur Bankrottquote sind eigene Rechnungen (Wald-Intervall), keine Quelle.
- Alle Messzahlen aus dem Repo sind Berichtswerte; ich habe die Regression nicht erneut gefahren (Auftrag: nichts im Repo ändern, Läufe würden Logs schreiben).

## 9 Lernstand und Konfidenz

| Bereich | Vorher | Nachher | Konfidenz |
|---|---|---|---|
| Perf-Methodik (gezählt/live/headless, Statistik) | lückenhaft | gut, mit Experiment | hoch |
| Flaky-Management, Teststaffelung | intuitiv | systematisch | hoch |
| Visuelle Abnahme, Bildvergleich | Auge | Verfahren bekannt, keine Praxis | mittel |
| Bot-/Simulationstests | Praxis ohne Statistik | Statistik und Einordnung | mittel-hoch |
| Playtest-Methodik | Aufgabenkarten, Protokoll | Theorie (n, Bias, Think-aloud) | mittel |
| Bug-Triage | Hoch/Mittel/Niedrig | Schwere vs. Priorität, Skala 0-4 | mittel |
| Godot-Testwerkzeuge | eigene Suiten | GUT/gdUnit4, CLI, CI-Fallen bekannt | mittel |
| Plattformunterschiede Win/Linux | Wissen aus Schäden | Doku-Fakten, keine Praxistests | mittel-niedrig |
| Reddit-/Community-Stimmen | – | nicht zugänglich | niedrig |
