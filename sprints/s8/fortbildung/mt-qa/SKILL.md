---
name: mt-qa
description: QA-Fach- und Projektwissen für Mega Tycoon (Godot 4.7, Games-QA, Testautomatisierung); verwenden bei Testplanung, Regression, Perf-Messung und -Gates, Flaky-Tests, visueller Abnahme, Playtest-Auswertung und Bug-Triage.
---

# mt-qa: QA-Wissen für Daniel (Stand 03.11.2026, nach Fortbildung)

Zuerst die 12 Regeln, die am meisten kosten, wenn man sie vergisst. Kennzeichen: [K] Konsens, [S] Streit zwischen Quellen, [E] Einzelmeinung/Anbieterblog, [V] Zahl aus gelesener Quelle, [W] Fachwissen ohne Quellenlesung in dieser Runde, [X] eigenes Experiment (Sandbox, Godot 4.7.2), [R] Beleg aus dem Repo (Pfad dahinter). Q-Nummern stehen am Ende.

1. Jede Zahl trägt ihre Messmethode: gezählt, live (xvfb/opengl3), headless, Zielrechner. Ohne Methode kein Gate-Urteil (Teil A5, B4).
2. headless liefert keine Renderwerte (0) [X]. Dreiecke/Draw Calls nur mit Renderziel (xvfb + opengl3) oder ausdrücklich als "gezählt, obere Schranke".
3. Sandbox-Zeiten sind keine Zielrechner-Zeiten. Zählwerte übertragen sich, Millisekunden nicht (B6).
4. Tests auf Platzhalter-/Testdaten beweisen nichts über die echte Karte. Test schreiben, sobald die echte Karte existiert; Spiel und Validator rechnen dieselbe Regel (B8).
5. Jede Zahl, die der Spieler sieht, bekommt einen Test gegen den Spielwert (B-1, s6/review_retro.md).
6. Wanduhr-Tests und parallele Läufe vertragen sich nicht. Suiten nur nacheinander; Zeitgrenzen nie auf Wanduhr, sondern auf Sim-Ticks stützen (B7).
7. Ein Messwert ohne Streuung ist keine Messung: mindestens 3 Läufe, Median, p95, Streuung, Build-Typ (A5).
8. Bot-Ergebnis ist kein Spielerbeleg. Ein Bot misst Drift, nicht Spaß (A4, B9).
9. Ein Tester (Basti) findet viele, aber nicht alle Probleme; Stichprobe n=1 ist Hinweis, kein Beleg (A8).
10. Schwere (Auswirkung) und Priorität (Dringlichkeit) getrennt führen; nie mit "hoch/mittel" für beides (A9).
11. Abweichung nur mit Eintrag "bewusst, Grund" und benannter Toleranz, nie Werte drehen (B3, E6-Fall).
12. Eine Regression, die niemand mehr vor dem Merge fährt, ist wertlos: Laufzeit ist ein Qualitätsmerkmal der Suite (A3, B2).

---------------------------------------------------------------------------------------------------
# TEIL A: Allgemeines Fachwissen

## A1 Prinzipien (ISTQB, Testtheorie)
- Sieben Grundsätze [K, V Q10]: Tests zeigen Defekte, nicht deren Abwesenheit; erschöpfendes Testen ist unmöglich; früh testen spart Zeit und Geld; Defekte clustern; Vorsicht vor dem Pestizid-Paradox (gleiche Tests finden irgendwann nichts Neues); Testen ist kontextabhängig; "keine Fehler gefunden" heißt nicht "brauchbar".
- Folge für uns: Risiko vor Vollständigkeit. Zuerst testen, was Basti sofort sieht oder was das Spiel blockiert (Z-01, "Stadt anschließen", Brückenrampe H2 waren genau dort [R] sprints/s7/abnahme/daniel_d09.md).
- Pestizid-Paradox konkret: 21 grüne Suiten fanden H1 (Labels), H2 (Brücke) nicht; erst Spielen auf der echten Karte [R s7/review_retro.md]. Gegenmittel: Suiten rotieren/erweitern, explorative Sessions fest einplanen, jeden gefundenen Fehler als Test ablegen.
- Beyoncé-Regel [E, V Q3]: "Test everything that you don't want to break." Praktisch: was ein Gate/Vertrag nennt, hat einen Test.
- Orakelproblem [K, V Q40]: Bei jedem Test fragen: Woher weiß ich, was richtig ist? Orakel-Arten laut Survey: Modell, Spezifikation, Vertrag, metamorphe Relation (A an = A aus, Prüfsumme gleich), Mensch. Unabhängiges Orakel (eigene Rechnung, Nachrechnen) schlägt Entwicklerzahl.
- Metamorphe Tests passen zur Sim: Easing an/aus ändert Sim-Prüfsumme nicht (E1); alt gegen soa (parity_test); gleicher Seed gleiche md5 (s7_validator) [R].

## A2 Teststrategie: Pyramide, Größen, Verträge
- Pyramide [K Heuristik, V Q1]: viele kleine schnelle Tests, wenige grobe, sehr wenige End-to-End. Regeln: "Push your tests as far down the pyramid as you can"; Fehler von oben ohne roten Test unten heißt: unteren Test schreiben. Schichtnamen darf man ändern, wenn konsistent.
- Google-Größen [V Q3]: klein = ein Prozess, kein Sleep, kein I/O; mittel = eine Maschine, nur localhost; groß = beliebig. Empfohlene Mischung nach Testanzahl: 80 % klein, 15 % mittel, 5 % End-to-End; "jedes Team anders".
- Form der Pyramide ist umstritten (Trophy/Honeycomb-Varianten) [S, W]; für ein Spiel zählt eher: Logik ohne Renderer testen (headless), Darstellung getrennt (xvfb), Spielgefühl manuell.
- Übertrag auf Mega Tycoon: klein = Sim-Kern/Wirtschaft/Validator headless (Sekunden); mittel = Szene + Main ohne Rendern (slice_test, d07_abnahme); groß = echte Maus unter xvfb (d08_maus, play.sh), Perf live, Basti-Rundgang. Aktuell ist die Mitte dick, die Spitze teuer (B2).
- Integrations-/Serialisierungsstellen immer testen [K, V Q1]: Wo Daten (JSON, CSV, Karte, Prefab) gelesen oder geschrieben werden, gehört ein Test dazu.
- Verträge [K, V Q1]: Consumer-driven Contracts: Konsument (Spiel/Test) schreibt, was er braucht; Anbieter (Generator, Datei) prüft das in seiner Pipeline. Passt zu world_validate.py, regelwerk.json, VERTRAG.md.
- Gates gestaffelt: schnelle Stufe vor jedem Merge (Minuten), volle Regression nachts oder vor Release, Messläufe auf Zielrechner pro Sprint [W].
- Smoke-Tests (Start, Karte lädt, kein SCRIPT ERROR, Ladezeit) als billigste Stufe [K, E Q39, Q35].

## A3 Determinismus und Flaky-Tests
- Ursachen [K, V Q2]: fehlende Isolation, Asynchronität, entfernte Dienste, Zeit, Ressourcenlecks. Bei uns zusätzlich: Wanduhr, Framerate, Software-GL-Last, parallele Prozesse, Float-Rundung, Reihenfolge von Dictionary-Keys [W].
- Behandlung [K, V Q2]: Quarantäne (eigene Suite, aus der Haupt-Pipeline, mit Frist, nicht löschen); nach Ursache fixen; nie nackte sleeps (pollen mit Timeout); Uhr kapseln/einfrieren; Pools auf 1 setzen, damit das erste Leck laut wird.
- Schwellen [V Q3]: Google-Flakerate ca. 0,15 %; ab etwa 1 % Flakiness verlieren Tests Wert. Zahlen zu Größenklassen (klein 0,5 %, mittel 1,6 %, groß 14 % pro Woche, ~2 % aller Tests mit einem Flake) nur aus Sekundärquelle [V Q5, Q4 nur Kommentare lesbar]; die oft zitierten 1,5 % der Läufe/16 % der Tests konnte ich nicht belegen [nicht verifiziert].
- Immer wiederholen, bevor "flaky" gesagt wird: 10/10 grün ist ein Mindestmaß, 3/3 ist keins [E, V Q4 Kommentar]. Flake nachstellen heißt künstliche Last erzeugen (Beispiel H29: 10/40 rot ohne Last, 32/40 bei 60 ms, 40/40 bei 120 ms [R s6/block-c/daniel.md]).
- Flake kann echter Produktfehler sein [V Q4 Kommentar: Ursache laut einem Team zu 1/6 ein Fehler im Produktcode]. Also erst Ursache, dann Etikett.
- Fester Zeitschritt [K, V Q23]: Sim in festem dt, Akkumulator, Render getrennt; variables delta ist nicht reproduzierbar, selbst Semi-Fixed nicht bitgleich. Godot: --fixed-fps erzwingt Fixed-FPS und schaltet Echtzeit-Sync ab [V Q11]. Unsere Sim ist tick-basiert (10 Hz): Tests nutzen run_ticks, nicht Wanduhr [R].
- Replays als Testmittel [K, V Q33]: deterministischer Kern + Eingabeaufzeichnung = Bug reproduzierbar, Durchlauf auf Knopfdruck, Replay nur KB groß. play.sh/commands.txt ist unser Replay [R tools/play_help.md].
- Test-Hygiene [W]: Seeds festschreiben und ins Protokoll; Testdaten nie nachträglich tauschen; Zeitlimits als Konstanten; Ausgabe-Artefakte (Logs, CSV) außerhalb von res://.

## A4 Simulation, Property-Based, Bots
- Deterministische Simulation [K, V Q21]: FoundationDB testet ganze Cluster in einem Prozess, deterministisch, mit Fehlerinjektion, ca. 10:1 simulierte zu realer Zeit, "zehntausende Simulationen jede Nacht". Übertrag: Seed-Läufe mit Fehlerinjektion (Bankrott-Bot, Lkw-Überbesetzung, Stau).
- Property-Based [K, V Q22]: Eigenschaften statt Einzelfälle; Generator liefert Eingaben; Fehler werden auf den einfachsten Fall verkleinert (Shrinking). Für uns: Invarianten (Kasse nie negativ ohne Bankrott-Meldung, Straße verbindet zwei Felder, Validator: 0 Verstöße über 20 Seeds [R s7_validator.sh]). Godot-Fuzzer: gdUnit4 [V Q18].
- Bots [K, V Q35, Q39, Q29]: gut für Smoke, Abdeckung, Überlauf/Exploits, nächtliche Parallelläufe, Heatmaps; schlecht für Spaß, Lesbarkeit, Fairness. Mensch bleibt für Planung, Risiko, Triage, Deutung.
- Bots mit RL [E, V Q30, nur Abstract]: lernende Agenten finden unbeabsichtigte Mechaniken/Exploits; Methodik und Grenzen aus dem Abstract nicht ableitbar.
- Stand der Branche [V Q29, Q34]: Spieletest ist überwiegend manuell, Automatisierung selten; Roundtables nennen sie "still a rarity". Wir sind damit eher weit vorn, aber nicht der Maßstab für Qualität.
- Gültigkeit von Bot-Studien [W]: Bot und Modell sind beide Setzungen; ein Treffer "Bot = Modell" zeigt Konsistenz, nicht Realität. Kalibrierte Parameter (KALIB) offen als "gefittet" ausweisen.
- Statistik einer Quote: Bei n Läufen und Anteil p gilt Standardfehler sqrt(p(1-p)/n). n=100, p=15 %: 3,6 Pp, 95-%-Intervall rund ±7 Pp; n=300: ±4 Pp [rechnerisch]. Korridor ±5 Pp bei n=100 ist enger als das Intervall: nur sinnvoll, wenn Seeds fest sind (dann Drift-Wächter, kein Schätzer).
- Sinnprobe: Ein Wächter muss anschlagen können. Jede neue Suite einmal absichtlich rot machen (Beispiel: Baseline -15 % ergibt FAIL [R s7/block-a/daniel.md]; Spike-Fix zurückdrehen ergibt E9 rot [R s6/block-c/daniel.md]).

## A5 Performance-Tests
- Frame-Zeit statt FPS [K, V Q27]: gemessen werden Zeitabstände; FPS = 1000/ms. Perzentile drehen sich: P99 der Frametimes = P1 der FPS.
- "1 % Low" ist uneinheitlich [S, V Q27]: (a) P1 der FPS, (b) Mittel der schlechtesten 1 % der Frames (immer niedriger), (c) zeitbasiert (Afterburner/CapFrameX). Immer Tool und Definition nennen. Perzentil hier: Nearest-Rank, Position ceil(0,95·N) [R design/qa/day1-3/benchmark_pruefplan.md].
- Mittelwert/Median allein täuschen [S]: Tene/Treat: Mittel, Median, Standardabweichung seien für Latenzverteilungen nutzlos, Perzentile nicht mitteln, Maximum nie verwerfen [V Q26, Leser bestreiten Teile]. Übertrag: Median UND p95 UND Max berichten; Perzentile über Läufe nicht mitteln, sondern Rohdaten poolen oder je Lauf ausweisen (unser F-05-Plan nimmt "Median der Laufmediane" und nennt den schlechtesten p95 je Lauf; das ist als Gate-Konvention vertretbar, aber kein gepooltes Perzentil).
- Coordinated Omission [K, V Q26]: Eine Messschleife, die bei einem Stau nicht weiterzählt, versteckt die Spitzen (Beispiel der Quelle: echter 99,99-Perzentil-Wert 100 s, gemeldet 1 ms). Übertrag [W]: Wer nur Tick-Zeiten oder Mittelwerte loggt, verliert Ruckler-Frames; Frame-Zeit je gerendertem Frame mitschreiben, Max nicht verwerfen.
- Statistik [K, V Q24]: "Beste von 30 Läufen" ist irreführend; Mittel/Median besser als Bester/Schlechtester; Konfidenzintervalle statt Einzelzahl; bei weniger als 30 Messungen Student-t; Vergleich zweier Varianten: Intervall der Differenz enthält 0, dann kein signifikanter Unterschied. Erste Invocation (Warm-up) verwerfen.
- Messbias [K, V Q25]: Unscheinbare Aufbau-Unterschiede (Umgebung, Reihenfolge) fälschen Ergebnisse; Gegenmittel: Setup randomisieren (Läufe über Konfigurationen verschränken, wie im F-05-Plan) [R benchmark_pruefplan.md §2].
- Streuung: 10-%-Regel (max-min/Median) für "instabil" ist unsere Annahme [R]; bei Ergebnis instabil 2 Zusatzläufe, beide Zahlen nennen.
- Build-Typ ist Messfalle [R benchmark_pruefplan.md §5]: Editor-/Debug-Binary ist nicht Release-Export. Gate-Wert nur Release-Export, sonst "obere Schranke".
- Zählwerte [V Q13]: RENDER_TOTAL_* schließen gecullte Objekte aus; Primitive sind durch Depth-Prepass und Schattenpässe "typisch doppelt oder dreifach"; manche Monitore verzögern bis 1 s. headless: RenderingServer liefert Dummy-Werte [V Q14]; [X] prims=0 dc=0 obj=0, aber get_current_rendering_driver_name meldet trotzdem "opengl3" (Name ist kein Beleg für Rendern).
- Budget-Praxis [K, V Q42]: Schwellen pro Metrik festlegen, in CI automatisch prüfen, Build bricht. Besser: absolutes Budget plus relatives Gate gegen Baseline. Relatives Gate (+10 %) allein erlaubt Kriechen: jede neue Baseline ist eine bewusste, begründete Entscheidung [R d07_regression.sh Kopf, Abschnitt 2e].
- Prüfreihenfolge Perf-Befund: (1) Methode? (2) gezählt oder live? (3) welche Kameras/Abstände? (4) mit/ohne Flotte? (5) was dominiert (Aufschlüsselung je Node-Gruppe)? Erst dann Maßnahme. Fehlattributionen sind häufiger als echte Regressionen (B4).
- Zielrechner-Bericht Pflichtfelder [R benchmark_pruefplan.md §5]: CPU, GPU, Treiber, OS, Godot-Version, Build-Typ, Kommandozeile, Git-Hash, Datum, Energieprofil, VSync, Fenstergröße.

## A6 Visuelle Abnahme, Screenshot-Diffs, Farbe
- Pixel-Diffs [K, V Q19, Q20]: pixelmatch threshold Default 0,1 (0 streng bis 1 lax), Antialiasing-Pixel werden standardmäßig ignoriert (kann echte Änderungen verstecken), Bilder müssen gleich groß sein. Playwright threshold 0,2; Rendering hängt von OS, Version, Hardware, Headless-Modus ab, Baselines je Plattform; im selben Umfeld erzeugen und prüfen, flüchtige Elemente ausblenden, Hover vermeiden.
- Übertrag: Screenshots unter xvfb nutzen llvmpipe (Software-OpenGL) [X: Adapter "llvmpipe (LLVM 20.1.2)"]; Mesa-llvmpipe ist OpenGL-4.5-konform [V Q41], aber Bild auf Basti-GPU kann leicht abweichen. Baselines nur vom selben Treiberpfad; Diff-Gate nie zwischen Linux-Sandbox und Windows-Rechner.
- Wann Diff, wann Auge [W]: Diff für UI-Layout/Icons/Schilder mit festen Kameras und fester Sim-Tick; Auge für Look (Gelände, Wasser, Silhouetten). Bei Look nur Vorher/Nachher-Paare gleicher Kamera (fixpass_w2: m1 bis m8 [R]).
- Kontrast [K, V Q28]: WCAG 1.4.11: Bedienelemente/Symbole mindestens 3:1 gegen Nachbarfarben, Text 4,5:1 (1.4.3, [W]); Schwelle ist hart (2,999 fällt durch). Ausnahme: inaktiv, Logos, Fotos. Unsere Praxis: ΔE2000 ≥ 10 oder Form/Beschriftung zusätzlich [R design/qa/day1-3/farbcheckliste.md]; Farbe nie allein.
- Visuelle Abnahme braucht Protokoll [W]: Kamera/Preset, Bild, Urteil (abgenommen/mit Auflage/nicht), Datei, wer. Urteil "wirkt gut" ist Sichtprüfung, kein Messwert; Look-Gates (G1, G2) liegen beim Art Director [R 14 §3].

## A7 UI-, Label- und Schilder-Tests
- Layout-Invarianten maschinell prüfen [W]: Rahmen im Viewport (Rand 8 px), keine Überlappung, Mindestschrift 12 px, Anker auf Gelände, Zoomstufen-Matrix (Fern/Voll/Nah, Hysterese). Vorbild proto_schilder_test (51 Prüfungen) [R].
- Matrix statt Einzelfall: Zoom × Kamerapositionen × Welt × Seed. H1 fiel durch, weil nur die Platzhalterkarte lief [R].
- Echte Eingabe: push_input und warp_mouse prüfen die Projektion Bildschirm→Feld; sim_hover-Abkürzungen nicht [R s6/block-c/daniel.md d08_maus].
- Texte [W]: jede Ablehnung hat Spielmeldung (u03_play: 12 Fälle, 0 stumm) und nennt Ursache + Lösung; Test: Text gegen Ursache (M4: falsche Ursache im Text).
- Zielgrenzen mit Scans: Zielpfeil-Scan über 100 Ansichten fand 1 Treffer [R]. Scans mit fester Ansichtenzahl und Seeds sind reproduzierbar.

## A8 Playtest-Methodik
- Nielsen-Landauer [K Formel, V Q6]: gefundene Anteile = 1-(1-L)^n, L im Mittel 31 %; 5 Nutzer finden rund 85 % (rechnerisch 84 %); besser 3 Runden à 5 als 1×15; bei verschiedenen Nutzergruppen 3-4 je Gruppe.
- Streit [S, V Q7]: Spool/Schroeder: 5 Nutzer fanden nur ~35 % der Probleme der größeren Menge; Faulkner: 5 Nutzer im Mittel 85 %, aber Spanne 55-100 %; 10 Nutzer 95 % (min 82 %), 15 Nutzer 97 % (min 90 %). Folge: ein 5er-Test kann fast die Hälfte übersehen.
- Think-aloud [K, V Q8]: Aufgaben, lautes Denken sofort, Moderator schweigt ("Shut up and let the users do the talking"), neutral nachfragen, mögliche Beeinflussung notieren und Datenpunkt streichen. Grenzen: künstlich, Filterung, Moderatorbias, keine Statistik.
- Beobachtung statt Erklären [K, V Q36]: nicht danebensitzen, Mechanik nicht erklären ("das Ringen ist die Information"), Fragen aus festem Skript, divers rekrutieren, Entwicklergespräche fernhalten; wenn nie Probleme auftauchen, den Prozess verdächtigen.
- Neutrale Fragen [K, V Q37]: Ziele in neutrale Fragen übersetzen, Skript, sichere Atmosphäre, Kontext des Spielers zuerst, Notizen zu Themen clustern und nach Gewicht ordnen.
- Unser Sonderfall [W]: Basti ist Auftraggeber und Experte, also n=1, nicht repräsentativ, mit Erwartungs-/Höflichkeitsbias; Sim-Teammitglieder sind keine Nutzer. Behandlung: Beobachtungen als Hypothesen führen, Wiederholung mit zweitem Menschen anstreben, Aufgabenkarten (Aylin) einheitlich, Zeit je Karte und Stolperstellen protokollieren, Basti-Aussagen wörtlich ablegen.
- Playtest-Daten [K, V Q36]: Was Spieler tun (Stolpern, Missverstehen), wie sie sich fühlen, Verständlichkeit/Tempo, Erfahrung/Demografie.

## A9 Bug-Triage und Severity
- Schwere und Priorität trennen [K, V Q38]: Schwere = Auswirkung (meist QA), Priorität = Dringlichkeit im Geschäftskontext (Produkt/PO). Fünfstufig (Blocker/Major/Moderate/Minor/Trivial) ist übliche, aber keine Norm-Skala [E, Vendor-Blog].
- Nielsen-Skala 0-4 [K, V Q9]: 0 kein Problem, 1 kosmetisch, 2 gering, 3 groß, 4 Katastrophe. Faktoren: Häufigkeit, Auswirkung (Überwindbarkeit), Persistenz (lernt man es?). Mehrere unabhängige Bewerter: etwa drei Mittelwert reicht oft; ein Bewerter ist unzuverlässig.
- Unsere Praxis [R s6/block-c/daniel.md]: Blocker/Hoch/Mittel/Niedrig/Hinweis, IDs B-/H-/M-/Z-/T- (Werkzeugfehler getrennt von Spielfehlern!). Ergänzen: Priorität-Spalte, Reproduktion als play.sh-Befehle, Beleg (Bild/Log), betroffene Welt (slice/s7/proto), Zuständig.
- Reproduzierbarkeit zuerst: Seed, Version (md5), Befehlsliste, Kamera. Ohne Repro kein Blocker, höchstens Beobachtung mit Frage.
- Defektcluster [K, V Q10]: Wo einer ist, sucht man mehr (Fluss/Brücke: M5, M8, H2 gehören zusammen).
- Regel: Jeder behobene Hoch/Blocker bekommt einen Regressionstest oder eine begründete Ausnahme.

## A10 Testdaten, Vertragsdaten, Messtoleranzen
- Testdaten (Platzhalter, synthetisch) sind Vorläufer; Vertragsdaten (Format, Einheiten, Maße) sind das, wogegen produktive Daten geprüft werden [K, W; passt zu CDC Q1]. Prüfen: Schema, Einheiten (m, dm, Feld = 25 m), Wertebereiche, Herkunft (md5), Version.
- Jede Abweichung Testdaten gegen Realdaten ist ein Befund, kein Rauschen: Beispiel Karten-Distanz Farm 78 gegen Setzung 28 [R s6/block-c/daniel.md A1].
- Toleranz zuerst festlegen, dann messen [W]: Tabelle mit Soll, Toleranz, hart/weich, Quelle. Schwelle ist inklusiv oder exklusiv? (Float-Rundung: Sim-Takt-Prüfung "Rest 0,5" statt 4/5 Ticks, proto_welt_test [R]).
- Weich/hart: harte Gates blockieren; weiche Gates werden berichtet. "ABW bewusst" braucht Grund, benannte Toleranz (E6: 1,3 × W/2) und Optionen für später [R integration_w2.md I11].
- Messdaten-Dateien [R]: CSV mit Kopf, ';' oder ',' festlegen, Dezimalpunkt, Einheit in Spalte, Seed und md5 im Dateikopf oder Nachbardatei, nie in res://.

## A11 Godot-Testwerkzeuge und Kommandozeile
- CLI [V Q11]: --headless = --display-driver headless + Audio Dummy ("Useful for servers and with --script"); --rendering-driver je Display-Driver; --fixed-fps ohne Echtzeit-Sync; --quit-after N; --script/-s; --check-only (nur parsen, nur mit --script); --import (startet Editor, importiert, beendet); --export-release/--export-pack; --disable-render-loop; --write-movie.
- Frischer Checkout/CI [V Q17]: .godot-Cache fehlt; headless-Import erzeugt teils unvollständiges global_script_class_cache; Folge: "Could not find type ... in the current scope". Workarounds: vorher godot --headless --import, notfalls export --export-release nach /dev/null, Szene statt -s starten. Uns betrifft: .godot/ ist ignoriert [R .gitignore], also immer erst --import (ta_welle2.md §11).
- xvfb [V Q15]: Godot 4.0 mit Vulkan unter xvfb stürzt ab (kein Software-Vulkan); unser Weg funktioniert mit --rendering-driver opengl3 (gl_compatibility), Fenster 1600x900x24 [R, X].
- GUT [V Q16]: 9.x für Godot 4.x, 9.7.1 für 4.7.x; Doubles, Stubs, Spies, parametrisierte Tests, Inner Classes, JUnit-XML. gdUnit4 [V Q18]: v6.2.1 laut README für 4.5 bis 4.7.1 (4.7.2 nicht ausdrücklich genannt); Scene-Runner simuliert Maus/Tasten/Touch, Fuzzer, Mocks, CLI, HTML/JUnit. Unsere Suiten sind eigene SceneTree-Skripte mit Exit-Code; Framework lohnt für Unit-Isolation, Doubles und JUnit-Reports, nicht für Pflicht.
- Dateinamen [V Q12]: Windows/macOS case-insensitiv, Linux und PCK im Export case-sensitiv; snake_case überall. Die Sandbox (Linux) findet Groß/Klein-Fehler, Basti-Windows nicht, und umgekehrt scheitert der Export.
- Performance-Monitore [V Q13]: TIME_PROCESS = "Zeit für einen Frame", TIME_FPS aktualisiert nur 1×/s; manche Built-ins debug-only (0 im Release).

## A12 Games-QA-Testarten (Überblick, überwiegend [W], nicht in dieser Runde quellengeprüft)
- Smoke (Start, Ladezeit, kein SCRIPT ERROR), Funktion/Regression, Kompatibilität (GPU/Treiber/Auflösung/OS), Performance (Frame-Zeit, Ladezeit, Speicher), Soak/Langlauf (Speicherlecks, Zeitraffer 8× über Minuten), Eingabe (Maus/Tastatur/Controller), UI/Lokalisierung (Textlängen, Umlaute), Speichern/Laden (Seed, Straßen, Brücken nach Laden gleich: heute kein Feature), Balance/Ökonomie (Bot-Läufe, Exploits), Exploit-/Soft-Lock-Suche (Mehl-Exploit S7), Barrierefreiheit (Farbe nie allein), Exploratives Spielen.
- Typische Spielfehlerklassen: Soft-Lock (Zustand ohne Ausweg, z. B. Kasse 0 ohne Aktion), Exploit (Geld aus dem Nichts), stumme Ablehnung (Aktion scheitert ohne Text), Koordinaten-/Projektionsfehler (Welt vs Bildschirm), Skalierungsfehler (Feld 10 m gegen 25 m), Float-/Rundungsdrift, Reihenfolge-Abhängigkeit, Darstellung ≠ Sim.
- Ökonomie-Tests [W]: Invarianten (Bilanz), Grenzwerte (0, Maximum, Kreditrahmen), Sensitivität (Parameter ±), Seed-Streuung, Exploit-Suche per Bot mit Zufallsstrategien.

## A13 Entscheidungshilfen
| Frage | Antwort |
|---|---|
| Ist der Fehler im Spiel oder im Werkzeug? | Gegenprobe mit zweitem Weg (API gegen echte Maus, anderer Seed); Werkzeugfehler als T-xx führen |
| Zahl rot, aber Ursache unklar? | Methode prüfen, dann Aufschlüsselung je Gruppe, dann Maßnahme; erst danach "Regression" sagen |
| Test rot nach fremder Änderung? | Vorher-Lauf auf gleicher Kopie; Ergebnis im Bericht trennen (nicht von mir) |
| Wann Baseline neu? | Nur bewusst, begründet, abgestimmt; nie, um ein Gate grün zu bekommen |
| Wann Quarantäne? | Flake belegt (10×, Last), Ursache bekannt, Frist und Zuständiger; nie ohne Eintrag |
| Wann Bot, wann Mensch? | Bot für Abdeckung, Drift, Exploits; Mensch für Lesbarkeit, Spaß, Fairness |
| Wann Diff, wann Auge? | Diff für feste UI-Layouts mit gleicher Umgebung; Auge für Look, immer mit Vorher/Nachher |
| Reicht ein Lauf? | Nein; ≥ 3, verschränkt, Streuung ausweisen; bei > 10 % Streuung 2 Zusatzläufe |

## A14 Checklisten
**Testplan (neue Funktion):** Ziel/Risiko; Orakel; Testebene (klein/mittel/groß); Daten (echt, Seed); erwartete Fehlerfälle; Zeitbudget der Suite; wer rotiert; Ablage (Pfad, Exit-Code, Ausgabe "Prüfungen OK").
**Messlauf:** Hypothese und Schwelle vorher; Umgebung eingefroren; Warm-up verwerfen; ≥3 Läufe, verschränkt; Rohdaten speichern; Median/p95/Max/Streuung; Prüfsumme/Gültigkeit; Methode im Dateikopf; Ausreißer nicht streichen, Störläufe mit Grund wiederholen.
**Abnahme:** alle Gates mit Methode; 0 SCRIPT ERROR; rote Zeilen nur "bewusst, Grund"; Regression nacheinander; Bild-Belege angesehen (nicht nur erzeugt); Offene Punkte mit Zuständigem; Abnahme-Urteil ja/mit Auflage/nein.
**Flaky-Triage:** 10× wiederholen; Last künstlich erhöhen; Wanduhr/Parallelität prüfen; Ursache klassifizieren (Isolation, Zeit, Async, Last); fix oder Quarantäne mit Frist; Fix mit Nachlauf 3×30.
**Bug-Report:** ID, Schwere, Priorität, Welt/Seed/Version, Repro-Befehle, erwartet/tatsächlich, Beleg, Verdacht, Zuständig.

## A15 Typische Fehler (aus Fachliteratur und eigener Historie)
1. Methode nicht benannt (gezählt vs live): 1,6-Mio-Befund. 2. Zusammengefasste Metrik ("Objekte ≈ Draw Calls") falsch zugeordnet: Straßenfelder statt Lkw. 3. Test grün auf Platzhalter. 4. Wanduhr als Testgröße. 5. Baseline stillschweigend neu setzen. 6. Bestwert statt Median. 7. Perzentile mitteln. 8. Eine Messung als Ergebnis. 9. Sandbox-Zeit als Zielwert. 10. Toleranz nach der Messung festlegen. 11. Bot-Quote als Spielerquote. 12. Spielfehler und Werkzeugfehler vermischt. 13. Vendor-Zahlen ohne Basis übernommen. 14. Bild erzeugt, nicht angesehen. 15. Zahl im UI ohne Test gegen den Spielwert.

---------------------------------------------------------------------------------------------------
# TEIL B: Wissen für Mega Tycoon (nur Belegtes, Pfade relativ zu /home/claude/mega-tycoon)

## B1 Umgebung und Aufrufe
- Godot 4.7.2: /tmp/claude-0/gd/Godot_v4.7.2-stable_linux.x86_64 (Standard in tests/d07_regression.sh, slice/tools/play.sh). Daneben 4.4.1 und 4.2.2 (Spikes/Altprototyp) im selben Ordner.
- Alle Befehle aus slice/. Exit 0 nur bei grün; zusätzlich zählt "SCRIPT ERROR" im Log als Fehler (run_tests.sh, d07_regression.sh).
- Standardaufrufe: `$G --headless --path . -s res://tests/<name>.gd [-- --opt=...]`; xvfb: `xvfb-run -a -s "-screen 0 1600x900x24" $G --rendering-driver opengl3 --path . -s res://tests/<name>.gd`.
- Frischer Stand: `godot --headless --path slice --import` (sprints/s8/design-sprint/phase4/ta_welle2.md §11).
- Skript-API gegen die installierte Engine prüfen: `--check-only` je Skript (integration_w2.md Kopf).
- Optionen: slice_test `-- --fahrzeuge=alt`; d07_abnahme `-- --only=ui|kredit|parity|lager|hq`; d08_bankrott `-- --n=100 --stadt=kohlberg --csv=<pfad>`; s7_boot `-- --welt=s7`; perf_s7 `-- --welt=slice|s7 --lkw=0,5000 --out=<abs> --check=<baseline.csv>`; proto_mass `-- --csv=<pfad>`.

## B2 Regression (tests/d07_regression.sh)
- Aufruf: `bash tests/d07_regression.sh [godot] [spikes_root]`; schreibt tests/d07_regression_summary.md und tests/d07_logs/; Suiten laufen strikt nacheinander; Spikes werden vor dem Lauf kopiert, Repo bleibt unberührt.
- Stand 03.11. (tests/d07_regression_summary.md): 24 Zeilen GRÜN, Laufzeit 1.090 s (ca. 18 min). Suiten und Prüfungszahlen: slice_test soa/alt je 74, parity_test 8, s11_test 16, d07_abnahme ui 31/kredit 17/parity 12/lager 2/hq 30, d08_bankrott 10 (264,6 s), d08_lizenzfaktor 8, s7_mira 33, s7_w04 31, s7_city 114, s7_u03 125 (xvfb), u03_play slice/s7 (12 Fälle, 0 stumm), s7_industrie 66 (xvfb), s7_start 31 (xvfb), d08_maus 27 (xvfb), s7_boot 39/29, s7_validator (20 Seeds), perf_s7 (xvfb, 12 Messwerte), Spikes sim-core und f04-signal (run_smoke.sh), Statik (JSON, Icons ≥ 24, keine Modal-Klassen, Tween ≤ 150 ms, Export-Filter, B-2-Check).
- Laufzeiten aus Berichten: 478 s (S6, 12 Suiten, s6/block-c/daniel.md); 1.396 s (14 Suiten, s7/block-a/mira.md); 1.489 s unter Last (13 Suiten, s7/block-a/daniel.md); 1.361 s (24 Zeilen, phase4/felix_welle1.md); "ca. 30 min" (s7/block-b/tobias.md). Die Spanne hängt an Parallellast (2 CPUs in der Sandbox); eine Zahl "26 min" ist im Repo nicht belegt.
- Zeitfresser: d08_bankrott 265 s, perf_s7 150-300 s (Software-GL), s7_* unter xvfb.
- Proto-Welt-Suiten (S8, nicht in d07): proto_terrain 15, ta_import 6, ta_welle2 23, proto_epochen 17, proto_strassenband 36, proto_welt 35, proto_easing 15 OK + 2 ABW, proto_sim 11, proto_band_hoehe 2, proto_schilder 51, proto_fixpass 12, proto_mass 95 (headless und xvfb) (integration_w2.md §2, fixpass_w2.md). Sammelskript run_proto_tests.sh liegt nur in der Arbeitskopie p4/int/_out, nicht im Repo.
- Regel: Nach Merge/Änderung an main.gd, economy, Sim, Karte immer volle d07-Regression; nach reinen Proto-Dateien genügen Proto-Suiten plus s7_start (start_menu.gd berührt) (felix_welle1.md §3).

## B3 Messkarten Prototyp "Welt" (sprints/s8/design-sprint/phase3/14_prototyp_plan.md §3, phase3b/16_prototyp_plan_v1_1.md §5/§6)
- Regel: Jedes Objekt ±25 % zum Spielwert; Fahrzeuge Länge 0,9-1,2 × real ohne Zuschlag; Ausgabe proto_mass.csv (Objekt;Soll;Ist;Abw. %;OK;Quelle); Abweichung nur mit "bewusst, Grund".
- M1 Haus S/M/L 8×6×6-7 / 12×9×9-11 / 12×14; M2 Hofstelle 25×25; M3 Kirchturm 30 (Dorf) / 45-55 (Stadt); M4 Dorfstraße 6 / Chaussee 6 (+Trasse 11) / Feldweg 3,5; M5 Pferd 3,0 / Fuhrwerk 9,5×2,2 / Postkutsche 12,5; M6 Lok 7,6 / Tender 4,8 / Wagen 6,9; M7 Mühle 12×12, Rad Ø 5; M8 Gutshof 40×40; M9 Fluss 60-100 / Bach 4-6 / Mühlteich 50-150; M10 Brücke Felder = ceil(B/25)+2 (exakt); M11 Bäume Laub 15-25 / Obst 6-8 / Nadel 20-30; M12 Dorf Radius 125-200 m, 25-56 Wohnhäuser; M13 Kleinstadt-Kern 200-300 m, 120-200 EW/ha; M14 See 400-600 m, Steg 25×2, Hütte 8×6, Boot 4,5 m; M15 See-Nutzung ≤ 500 m, Pfad Pflicht.
- Verhältnisse: V1 Haus M : Straße : Fuhrwerk 12 : 6 : 9,5; V2 Straße : Fahrzeugbreite ≥ 2,5 hart; V4 Lok+Tender : Haus M ≤ 1,5; V6 Kirchturm : Traufe ≥ 3; V7 Mühle : Haus M ≤ 4; V8 Fluss : Haus M 5-8. V3 und V5 stehen in der Tabelle 14 §3 nicht (nachfragen, nicht raten).
- E1-E7 (hart): Parität bitgleich an=aus, kein Sprung, Gierrate, Querbeschleunigung, Halt ≤ W/2, Versatz ≤ W/2, keine Stauchung; E8 ≤ 0,5 ms/Frame bei 10 Fz. Stand: E1-E5, E7 grün; E6 "ABW bewusst" A 1,30 × / B 1,38 × W/2 bei Kurvenfaktor 0,70, Toleranz 1,3 benannt (integration_w2.md §3, I11).
- G1 Industrie-Gebäudefarbe neutral (Sicht + Material-ID); G2 keine 25-m-Uferstufen bei 160 m Kamera (Art Director); G3 Kontrast Wasser A/B, Bodenklassen ≥ 3:1 (Aylin); P7 Startjahr 1850 statt 1820 ändert nur Daten (proto_epochen_test, 17 Prüfungen).
- Gate vor Phase 5 (16 §6): Messprotokoll ohne rote Zeile; Perf-Gate; Kette Farm → Mühle → Dorf mit Easing, Prüfsumme unverändert; See zeigt Nutzung ohne Erklärung; Epochen-Test grün, keine Assets nach 1849; 21 Regressionssuiten grün.
- Regelwerk-Befund als Beispiel: personenwagen l 69 dm gegen real 57 dm = 1,21 × rot; PO setzt 68 (felix_welle1.md §4, ta_welle2.md §1). Fall für "Regel statt Wert ändern" nur mit Entscheid.

## B4 Perf-Gates und Werte (alle: Zählwerte, keine FPS)
- Gate S7/Proto: Übersicht ≤ 1,0 M Dreiecke und ≤ 300 DC; Kleinstadt nah ≤ 2,9 M; Ladezeit ≤ 3 s (14 §4, 16 §6). perf_s7: relatives Gate +10 % gegen tests/perf_s7_baseline_slice.csv (GATE 1.10 in tests/perf_s7.gd), absolut S7_LIMITS (Übersicht nur ohne Flotte).
- 6 Kameras: Übersicht (Slice 4,3 km), Stadt nah 700 m, Stadt Straße 160 m, Mine 420 m, Farm 900 m, Rand max. Zoom; Zoomformel zoom = Abstand / (25,6 · m_pro_feld) (tests/perf_s7.gd Kopf).
- Baseline Slice (tests/perf_s7_baseline_slice.csv, 0 Lkw, Dreiecke/DC): Übersicht 1.106.450/355, Stadt nah 1.094.358/236, Stadt Straße 685.090/209, Mine 1.093.822/198, Farm 1.093.548/282, Rand 1.096.200/321; mit 5.000 Lkw Übersicht 1.392.498/482. Slice reißt das 300er-DC-Budget schon ohne Lkw; das Budget gilt für die S7-Welt (S7-Baseline: Übersicht 755.732/250).
- S7-Welt (sprints/s7/review_retro.md): Übersicht 0,76 M/250 DC, Stadt nah 1,15 M, Ladezeit 2,0-2,2 s.
- Proto-Welt live (xvfb opengl3, integration_w2.md §4): Übersicht 145.702/111, Dorf 574.123/107, Markt 514.611/62, Fluss 823.052/71, See 778.858/144; Laden 1.446-1.640 ms (mit 1. Frame 1.798-1.987 ms).
- Perf-Zählfehler 1,6 Mio (ta_welle2.md §5, felix_perf_aufschluesselung.md): 1,62 M war "gezählt ohne Culling" (Bäume 1.487.668 = 91,9 %, 70 MultiMeshes, 11.500 Bäume, Sichtweite 1,8 km wirkt im Renderer, nicht in der Zählung); live max ≈ 0,62 M/136 DC bei 1.200-1.800 m. Gate war als "Szene gezählt" definiert (14 §4). Gegenmaßnahme: Chunks per Skript nach Abstand schalten, Messsuite zählt zusätzlich "gezählt mit Sichtweite" und live; Gate-Zahl = live, ohne Renderziel "gezählt mit Sichtweite".
- headless-Zählung zählt MultiMeshes konservativ, weil der Dummy-Renderer keine Instanz-Transforms hält; Nah- und Fern-LOD zählen doppelt (headless 1,14/1,60 M gegen live 0,73/0,60 M bei 1,8/1,2 km): Zwischenabstände headless nur "Info, obere Schranke" (integration_w2.md I12).
- Draw-Call-Fehlattribution S7 (sprints/s7/block-b/felix2.md §1): 4.066 DC in der 5.000-Lkw-Übersicht kamen von 3.366 Straßenfeld-Meshes + 100 Lagern (≈292 DC); Fahrzeuge nur 2 DC. "Objekte ≈ Draw Calls" war richtig, die Zuordnung "Lkw" falsch. Fix: Quader-Batch (render_batch.gd), danach 482 DC.
- Aufschlüsselung je Gruppe/Abstand mit tests/proto_perf_gruppen.gd und tests/proto_perf_abstand.gd (live-Differenz durch Ausblenden).
- Retro-Notiz "Perf-Messfehler Faktor 2,5" (s7/review_retro.md): Einzelheiten nur dort; durch Nachrechnen gefunden.

## B5 Zielrechner-Messung F-12 (sprints/s6/messung/f12_zielrechner_01-11.txt)
- Basti-Rechner: Windows, Ryzen 7 5800X3D, RTX 3080 Ti, Treiber 32.0.16.1742, gl_compatibility, 1600×900, VSync aus, 5.000 Lkw auf 51 Korridoren, 3 × 15 s nach 3 s Aufwärmen.
- Ergebnis: Median 89,7 FPS, Streuung 2,7 %, Frame Median 9,4 ms, p95 22 ms (≈ 45 FPS, an der 1-%-Low-Grenze), TIME_PROCESS 32 ms "roh". Auflage: Spitzen profilieren (Vermutung Tick-Frames alle 100 ms), p95 mit RENDER_SPLIT neu messen.
- Einschränkung: Messung ohne Kenney-Look, weil der Export die GLBs nicht enthielt (B-2, s6/block-c/daniel.md); seither behoben (Statikprüfung im d07), Neu-Messung steht aus (s7/review_retro.md "verschoben").
- Deutung TIME_PROCESS = "Summe über Ticks" ist meine frühere Hypothese (Daniel); laut Godot-Doku ist es die Zeit eines Frames (Q13). Ungeklärt, nicht weiter verwenden ohne Gegenprobe.

## B6 headless, xvfb/opengl3, Sandbox, Windows
- headless: Renderwerte 0, perf_s7 wertet als FAIL (tests/perf_s7.gd Kopf; s7/block-a/daniel.md §2). Auch proto_mass: Perf live nur unter xvfb (integration_w2.md I12).
- xvfb: Software-GL (llvmpipe), Zählwerte auf jedem Rechner gleich, Zeiten nicht; Läufe langsam (Bild ca. 10 s; je UI-Befehl 1-1,5 s).
- Sandbox: 2 vCPU, Last durch parallele Agents; Wanduhr-Test A21 (Panel-Slide ≤ 150 ms) rot unter Last (191/230 ms), deshalb: Suiten nur nacheinander (s6/block-c/daniel.md).
- Windows: Basti baut/spielt unter Windows; Export-Preset tests/* ausgeschlossen, include data/*.json, ui/icons.json, ui/assets/*, world/data/*; Templates 4.7.2 müssen auf dem Export-PC liegen (slice/export_presets.cfg). Aufgabenkarten nennen C:\Dev\mega-tycoon\slice (sprints/s8/design-sprint/phase4/aufgabenkarten_v1_1.md).
- B-2-Lehre: Spielcode darf Assets nicht per globalize_path von der Platte lesen (Exe: Pfad neben der .exe); Kenney-Modelle laufen über kenney_loader.load_root; Statikprüfung in d07_regression.sh.
- play.sh/xvfb laufen nur unter Linux; Windows-Verhalten (Treiber, Fenster, Eingabe) deckt keine Suite ab. Messläufe auf Basti-Rechner laufen über die Bench-Szenen in tools/bench-zielrechner/ (bench_runner, bench_soa; README.md des Repos).
- .gitignore: .godot/, *.import, *.exe, slice/tests/*.translation (Godot importiert CSV unter res:// als Translation: 27 solche Dateien liegen in slice/tests/). Folge: CSV-Ausgabe nach außerhalb res:// (proto_mass.gd Kopf, Standardpfad sprints/.../phase4/). Neue Test-Skripte können in .gitignore stehen (integration_w2.md §7: proto_shots_int.gd, Commit mit -f).

## B7 Flakiness und Stolpersteine der Suiten
- H29-Flake (s6/block-c/daniel.md; tests/d07_abnahme.gd Z. 917): place_hq startet Tempo 1, _physics_process tickt parallel zu run_ticks; Fix set_speed(0): 0/120 rot.
- A21 Panel-Slide misst Wanduhr, bleibt wackelig unter Last.
- Historie: Mitte S7 waren s7_w04 ("visible on bool", 2 SCRIPT ERROR, schon im Vorher-Stand) und s7_u03 (6 Textfehler) rot, ohne dass der jeweilige Block schuld war (s7/block-b/tobias.md). Schuldfrage immer per Vorher-Lauf auf gleicher Kopie klären; im Stand vom 03.11. beide grün.
- play.sh: Sim läuft nur in `wait` (_physics_process abgeschaltet); Lauf startet frisch und spielt alle Zeilen ab; Budget 100 s (Exit 3), --bg für lange Läufe; wait rechnet wie _physics_process, state.md nennt Echtzeitäquivalent (T-02); tools/play_help.md.
- Werkzeugfehler S7 (sprints/s7/abnahme/daniel_d09.md): play_session.scr_cell projizierte auf y = 0, S7-Gelände liegt bei 30-150 m: Patch play_session_d09.patch außerhalb des Repos (Übernahme durch Mira/Felix war erbeten; Stand im Repo vor dem Einsatz prüfen). u03_play_check.sh nutzt MT_S7_KARTE=slice (flach) und prüft daher S7 nicht auf der echten Karte.

## B8 Testdaten, Vertragsdaten, Spiel gegen Validator
- Beispiele (alle belegt): B-1 Vorschau-Lizenzfaktor ≠ Spielpreis (nur 2 von 8 Städten gleich), seit S6 Test d08_lizenzfaktor (8/8) [s6/block-c/daniel.md]; H2 Validator "alle Ketten erreichbar", Spiel lehnt Querung (Brückendeck = höchste Landhöhe im Umkreis 3) ab (s7/abnahme/daniel_d09.md); H3 HQ-Vorschau "Wagnis" bei 9 von 12 Städten, Spielstart Kohlberg stärkster (+447 $/min); s7_city/s7_industrie liefen zunächst auf Platzhalterkarte (s7/review_retro.md).
- Vertragsdaten Proto-Welt: phase3b/12_regelwerk_v1_1.json (Kopie slice/world/data/proto/regelwerk.json, md5 bbf1ea8b…), phase2/10_import_faktoren.json, VERTRAG.md; Testdaten slice/proto/testdaten/ (Felix, nur Platzhalter bis TA/Stadt liefern). Vertragsänderung nur mit Eintrag (Beispiel M8 Weiler: Test geändert auf "nie ein Schild", fixpass_w2.md).
- Regel (s7/review_retro.md): Spiel und Validator rechnen dieselbe Regel (Brückenrampe als Vorbild). Offene Kandidaten aus daniel_d09.md §4: play.sh auf echter S7-Karte mit 5 Starts, Spiel gegen Validator für alle Kettenpaare (≥ 80 % Flussspalten gerade querbar), Label-Test auf echter Karte, perf_s7 --welt=s7 --lkw=5000, Zeitraffer 8× mit Gelände, HQ-Umsetzen S7, Gleis 12 %, Vorschau gegen Bot-Spiel, weitere Seeds im Spiel, Slice-Texte in S7, Speichern/Laden.
- Messdaten-CSVs: tests/perf_s7_baseline_*.csv (welt,lkw,ansicht,zoom,dreiecke,draw_calls,objekte), tests/d08_logs_bankrott.csv, sprints/s8/design-sprint/phase4/proto_mass.csv, proto_easing.csv, Tobias' Läufe unter phase4/tobias_welle1_daten/ (Skripte unter skripte/). Baseline-Wechsel nur nach Absprache und im Bericht begründet (d07_regression.sh Abschnitt 2e).

## B9 Bot-Playtest und Bankrott
- tests/d08_bankrott.gd: 3 Städte × 100 Seeds × 30 Spielminuten, 18.000 Ticks, Bot-Verhalten durch Seed (sorgfältig 40 % / normal 40 % / hastig 20 %, Kredithaltung 35/45/15/5), Determinismus (Seed 3 zweimal gleich), Korridor ±5 Pp gegen Modellquote (MODELL: Mittelfurt 16,3, Haberau 14,0, Kohlberg 14,7). Kopf nennt: KEIN Spielerbeleg, KALIB "GEFITTET, nicht gemessen".
- Ergebnisverlauf: S6 erste Fassung 2 % / 35 % / 38 %; S7 kalibriert 15 / 17 / 18 % (d07_regression_summary.md). Ein Seed kippt Haberau 35 → 34 % nach Stadtstraßen-Änderung (s7/block-a/mira.md). Modell: Haberau 10,3-12,3 %, Kohlberg 11,0-11,3 %, Stichprobenfehler ca. 1,8 Pp bei n=300 (s6/block-c/daniel.md); Band 10-30 % ist Setzung (Tobias T-14), kein Spielerwert.
- Bankrotttreiber laut Bot: Lkw-Überbesetzung gegen Nachfrage (Dorf 18 E/min), nicht Kredit; M7 gibt es im Slice nicht; echte Bankrott-Spaßfrage bleibt für Basti.
- Spielen als Test: Zocker-Sessions (s6/zocken/, Daniel Steinbach 45 min) fanden Z-01..Z-07 und zeigten "Wagnis" leichter als gewarnt.

## B10 Visuelle Abnahme, UI, Schilder (Stand)
- Es gibt keinen automatischen Bildvergleich (Diff) im Repo; Bilder entstehen mit *_shots.gd (xvfb) und werden per Auge beurteilt (D-09: abgenommen / mit Auflage / nicht abgenommen, sprints/s7/abnahme/daniel_d09.md). Fixpass W2: Vorher/Nachher-Paare gleicher Kamera (phase4/bilder/fix/).
- Kontrast/Farbe: design/qa/day1-3/farbcheck.py (Machado 2009, ΔE2000 ≥ 10), farbcheckliste.md (Palette v1: Ergebnis day4-6/farbcheck_ergebnis_s05.md); proto_schilder_test rechnet WCAG analytisch (schreibt kontrast_analytisch.csv), proto_schilder_shots misst im Bild.
- Schilder/Label: proto_schilder_test 51 Prüfungen (Stufen, Hysterese, Anker, Überlappung, Rahmen 8 px, Mindestschrift 12 px); s7_industrie_test 66 (4 km ≥ 24 px, kein Überlappen); u03_play 12 Fälle 0 stumm; H1 (Stadtlabels 100-350 px versetzt) fiel nur in der echten Karte auf.
- Offene Look-Urteile S7: Städte aus der Übersicht nicht abgenommen (Raster/Rautenform), HQ-Vorschau "Wagnis"; Proto-Rundgang: Aufgabenkarten A1-A12 (aylin, aufgabenkarten_v1_1.md), Daniel protokolliert Zeit je Karte, Aylin beobachtet.

## B11 Sim-Perf-Messungen F-05 (design/qa/day4-6/f05_messprotokoll.md)
- Sandbox 2 vCPU Xeon 2,8 GHz, Godot 4.4.1 Editor-Binary headless: Spike-Sim 1k 5,38 ms (Streuung 28 %, instabil), 5k 34,27 ms, 10k 71,83 ms (Felix 67,38); SoA 10k 2,26 ms, p95 4,97 ms; Prüfsummen gleich (Gültigkeit). Zählt nicht für G2 (Sandbox).
- Messgröße festgelegt: Median Sim-ms pro Tick bei 10k/1×, 3 Läufe à 3.000 Ticks (+300 Warm-up), Release-Export, gegen 4 ms; p95 Pflicht, Warnschwelle 6 ms; 8× nur Bericht.

---------------------------------------------------------------------------------------------------
# TEIL C: Eigene Lücken und Lernstand (Stand 03.11.2026)

## C1 Gelernt (Konfidenz: hoch = Quelle gelesen oder selbst nachgestellt)
| Thema | Kern | Konfidenz |
|---|---|---|
| Perf-Methode | gezählt/live/headless trennen; headless = 0 [X]; Doku: Primitive inkl. Prepass/Schatten, ohne Culled [Q13] | hoch |
| Frame-Statistik | Frametimes, P-Werte, 1-%-Low-Definitionen uneinheitlich [Q27]; Konfidenzintervalle [Q24]; Messbias [Q25] | mittel-hoch |
| Flakiness | Ursachenklassen, Quarantäne mit Frist, Schwellen 0,15 % / 1 % [Q2, Q3] | hoch |
| Pyramide/Größen | 80/15/5, push down, Verträge [Q1, Q3] | hoch |
| Playtest | 31 %-Modell, 5er-Streit, Think-aloud, Bias [Q6, Q7, Q8, Q36] | mittel-hoch |
| Severity | Schwere ≠ Priorität, Nielsen 0-4, mehrere Bewerter [Q9, Q38] | mittel |
| Screenshot-Diff | Schwellen, Plattform-Baselines, AA-Falle [Q19, Q20] | mittel (Praxis fehlt) |
| Determinismus | fester Zeitschritt, Replay [Q23, Q33] | hoch |
| Godot-CLI/CI | Flags, .godot-Cache, xvfb, GUT/gdUnit4 [Q11, Q15, Q16, Q17, Q18] | mittel-hoch |
| Dateien | Case-Sensitivität Windows/Linux/PCK [Q12]; CSV in res:// wird importiert (27 .translation) | hoch |

## C2 Weiter unsicher
1. Welche Perf-Zahl ist das richtige Gate: live unter Software-GL oder Zielrechner? Zählwerte übertragen sich, aber Treiber-/Cull-Unterschiede (Basti-GPU) nicht geprüft.
2. TIME_PROCESS gegen Frame-Median (32 ms gegen 9,4 ms): Ursache ungeklärt.
3. Wie stabil sind Software-GL-Zählwerte zwischen Mesa-Versionen? Nur eine Version gesehen (llvmpipe LLVM 20.1.2) [X].
4. Reddit (r/QualityAssurance, r/gamedev, r/godot, r/IndieDev, r/softwaretesting) war nicht lesbar (SITE_BLOCKED); Praxisstimmen der Community fehlen, nur Foren-/Issue-Quellen (GUT-Issue, Godot-Issue) und Anbieterblogs.
5. Original-Zahlen Google (1,5 % der Läufe, 16 % der Tests) nicht belegt; nur Buch (0,15 %) und Sekundärquelle.
6. GDC-Vorträge nur über Abstracts (Vault ist Mitglieder-Inhalt): konkrete Testtypen/Techniken von Sea of Thieves/Minecraft nicht gelesen.
7. Property-Based und Fuzzing im Godot-Kontext: Prinzip gelernt, nie selbst ausgeführt; gdUnit4-Fuzzer ungetestet.
8. Screenshot-Diff im Projekt: keine Praxis, Schwellen für unsere Szenen nicht kalibriert.
9. Statistik kleiner Stichproben: Konfidenzintervalle für Bankrottquote nur rechnerisch (Wald), nicht per Bootstrap geprüft.
10. Bewertung Basti-Feedback als n=1: wie viel Gewicht? Kein Verfahren im Team vereinbart.
11. Nicht bestätigt: V3/V5 der Messkarten, Zustand play_session_d09.patch im Repo, aktuelle Laufzeit der Regression nach S8-Merge.
12. Spielgefühl/Look sind nicht automatisierbar; Urteile bleiben subjektiv (AD, Basti).

## C3 Nächste Schritte (Vorschläge, nicht beschlossen)
- Gate-Definition Perf in 16 §6 um Methodenspalte ergänzen (gezählt/live/headless/Zielrechner).
- Regression in Stufen: schnell (ca. 5 min: headless-Suiten ohne d08_bankrott/perf) vor Merge; voll nachts/vor Release.
- Wanduhr-Tests (A21) auf Sim-Zeit umstellen oder in Quarantäne mit Frist.
- Perf-Messbericht-Vorlage (Median, p95, Max, Streuung, Build-Typ, Methode) fest einführen.
- Bildvergleich als Experiment: ein Preset-Satz unter xvfb, Baseline im selben Treiberpfad, pixelmatch-artiger Diff mit threshold 0,1 und Maximalanteil; erst nach Kalibrierung gaten.
- Severity/Priorität-Spalten und Repro-Befehle in jedes Bug-Protokoll.

---------------------------------------------------------------------------------------------------
# Quellen (Details und Einstufung: LERNBERICHT.md). Alle am 03.11.2026 abgerufen.
Q1 https://martinfowler.com/articles/practical-test-pyramid.html
Q2 https://www.martinfowler.com/articles/nonDeterminism.html
Q3 https://whatot.github.io/Software-Engineering-at-Google/src/Chapter-11_Testing_Overview.html (Mirror des Buchkapitels)
Q4 https://testing.googleblog.com/2017/04/where-do-our-flaky-tests-come-from.html (nur Kommentare lesbar)
Q5 https://www.besthub.dev/articles/analyzing-the-origins-of-flaky-tests-size-tooling-and-instability-at-google-da99e297788a (Sekundärquelle)
Q6 https://www.nngroup.com/articles/why-you-only-need-to-test-with-5-users/
Q7 https://humanfactors.com/newsletters/enough_is_enough.asp
Q8 https://www.nngroup.com/articles/thinking-aloud-the-1-usability-tool/
Q9 https://www.nngroup.com/articles/how-to-rate-the-severity-of-usability-problems/
Q10 https://astqb.org/istqb-foundation-level-seven-testing-principles/
Q11 https://raw.githubusercontent.com/godotengine/godot-docs/master/tutorials/editor/command_line_tutorial.rst
Q12 https://raw.githubusercontent.com/godotengine/godot-docs/master/tutorials/best_practices/project_organization.rst
Q13 https://raw.githubusercontent.com/godotengine/godot-docs/master/classes/class_performance.rst
Q14 https://raw.githubusercontent.com/godotengine/godot-docs/master/classes/class_renderingserver.rst
Q15 https://github.com/godotengine/godot/issues/38428
Q16 https://raw.githubusercontent.com/bitwes/Gut/master/README.md
Q17 https://github.com/bitwes/Gut/issues/491
Q18 https://raw.githubusercontent.com/MikeSchulze/gdUnit4/master/README.md
Q19 https://raw.githubusercontent.com/mapbox/pixelmatch/main/README.md
Q20 https://raw.githubusercontent.com/microsoft/playwright/main/docs/src/test-snapshots-js.md
Q21 https://apple.github.io/foundationdb/testing.html
Q22 https://raw.githubusercontent.com/HypothesisWorks/hypothesis/master/README.md
Q23 https://gafferongames.com/post/fix_your_timestep/
Q24 https://blog.acolyer.org/2017/11/06/statistically-rigorous-java-performance-evaluation/ (Zusammenfassung von Georges et al., OOPSLA 2007)
Q25 https://sape.inf.usi.ch/publications/asplos09 (Mytkowicz et al., ASPLOS 2009)
Q26 https://bravenewgeek.com/everything-you-know-about-latency-is-wrong/ (Sekundär zu Tene; Leser widersprechen)
Q27 https://www.capframex.com/blog/post/Explanation%20of%20different%20performance%20metrics
Q28 https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html
Q29 https://arxiv.org/abs/2103.06431
Q30 https://arxiv.org/abs/2103.15819
Q31 https://gdconf.com/article/sea-of-thieves-devs-share-automated-testing-tips-at-gdc-2019/ und https://www.gdcvault.com/play/1026366/Automated-Testing-of-Gameplay-Features
Q32 https://gdcvault.com/play/1027345/Lessons-Learned-in-Adapting-the
Q33 https://www.gdcvault.com/play/1021825/Automated-Testing-and-Instant-Replays
Q34 https://autotestingroundtable.com/
Q35 https://www.gamedeveloper.com/programming/testing-games-with-ai-bots
Q36 https://www.gamedeveloper.com/design/what-should-a-playtest-smell-like-
Q37 https://gamesuserresearch.com/how-to-run-unbiased-player-interviews/
Q38 https://marker.io/blog/bug-severity-vs-priority (Anbieterblog)
Q39 https://www.ixiegaming.com/blog/scaling-game-qa-with-automation-vision-strategy-reality/ (Anbieterblog, Zahlen unbelegt)
Q40 https://discovery.ucl.ac.uk/1471263/ (Barr et al., IEEE TSE 2015)
Q41 https://www.khronos.org/news/permalink/mesas-llvmpipe-is-opengl-4.5-conformant
Q42 https://web.dev/incorporate-performance-budgets-into-your-build-tools
X1 Eigenes Experiment: Godot 4.7.2, minimales Projekt im Scratchpad; headless: prims=0 dc=0 obj=0, Treibername "opengl3"; xvfb opengl3: Adapter "llvmpipe (LLVM 20.1.2, 256 bits) | Mesa", Kugel 4.224 Primitive, 1 DC.

## D. Lern-Routine (verbindlich, seit 2026-11-03)
**1. Wissenscheck** vor jeder fachlichen Antwort/Entscheidung: Steht sie hier mit Marke [K]/[V]/[R]? Ja: anwenden. Nein, oder nur [E]/[W]/niedrige Konfidenz: weiter mit 2.
**2. Recherche-Trigger** (einer genügt; laut sagen: "Wissenslücke: <Frage>, ich recherchiere"): a) Ich weiß es nicht oder rate. b) Derselbe Kompromiss/Workaround zum 2. Mal ("wieder X statt Y"). c) Eintrag unter Offene Lücken oder [E]/[W]/niedrig, und die Entscheidung hängt daran. d) Skill, Repo, Doku oder Messung widersprechen sich. e) Engine/Tool/Version neuer als der Skill-Stand. f) Basti korrigiert oder eine Entscheidung wird zurückgenommen. g) Teure oder unumkehrbare Entscheidung bei Konfidenz unter mittel. h) Derselbe Fix scheitert 2x.
Rollen-Trigger: Messwert ohne Methode; Flake zum 2. Mal; Toleranz ohne Quelle; Gate reißt ohne klare Ursache.
Erst prüfen statt recherchieren, wenn billig messbar (Test, Doku-grep, Mini-Versuch). Geschmack klärt Prototyp oder Basti, nicht das Web.
**3. Ablauf**: Frage in einem Satz; Primärquellen zuerst (Doku, Issues, Forum, Postmortems; Reddit blockiert, nicht umgehen); 2 unabhängige Quellen; wenn möglich Eigenversuch [V]; Ergebnis mit Quelle, Datum, Marke. Budget 15 min, mehr nur als Agent. Unbeantwortet: Lücke eintragen, Basti/Team fragen, nie raten.
**4. Insight aufnehmen**, wenn alle vier stimmen: wiederverwendbar (2x gebraucht oder über 1 h Aufwand), belegt, noch nicht drin, kein Tagesstand (der gehört in Repo-Doku). Sofort bei Basti-Korrektur, Fehler im Skill oder Engine-Falle mit Repro, sonst gesammelt zum Sprintende. Eine Zeile mit Marke, Datum, Quelle; Widerspruch ersetzt den alten Eintrag; geschlossene Lücke streichen; Skill bleibt ca. 10.000 Zeichen. Im Account nur per Vorschlagskarte an Basti.
**5. Kompromisslog**: jeden Kompromiss, Workaround, jedes "wusste ich nicht" mit Datum in `sprints/s8/fortbildung/mt-qa/LERNLOG.md` zählen; Zähler 2 löst Trigger b aus; Auswertung in der Sprint-Retro.
