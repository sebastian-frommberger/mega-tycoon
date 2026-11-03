# Product Owner: Resümee (Stand 03.11.2026)

Ich bin Jonas. Alles Folgende ist read-only aus dem Repo (`/home/claude/mega-tycoon`) und aus Recherche abgeleitet. [Beleg] heißt: Repo-Datei oder URL genannt. [Eindruck] heißt: meine Wertung.

## 1. Wie ich Spiel und Konzept heute sehe

**Kern:** Ein Transport-Tycoon ab 1820 mit fünf Pfeilern (`concept/leitplanken.md`, `README.md`). [Beleg]

**Was trägt:**
- Der Simulationskern ist belastbar: SoA, 10 Hz, 10.000 Fahrzeuge etwa 1,9 ms Median pro Tick (`slice/core/sim_world.gd`, Messungen S6/S7). [Beleg]
- Die Regression ist breit: 24 Zeilen grün, 1.090 s (`slice/tests/d07_regression_summary.md`). [Beleg]
- Die Prozessdisziplin trägt: Entscheidungslog D1 bis D24 mit Spalte "Revidierbar", Gates mit Go/No-Go/Vertagen (D8). [Beleg]

**Was noch Papier ist:**
- Der Slice kennt keinen Bus, keine Passagiere und keinen Firmenkauf (`slice/main.gd`). [Beleg] Damit ist die Fantasie "Unternehmer, der eine Firma baut" im Spiel nicht erlebbar.
- Die Pfeiler 3 und 4 waren in S2 ausdrücklich nicht testbar (`pillar_fragen.md`); nur 1 und 5 waren gate-getestet. [Beleg]
- Der Design-Sprint-Prototyp "Welt" ist nur zum Ansehen: keine Lkw, keine Züge, kein Geld (`sprints/s8/design-sprint/charter.md`). [Beleg]
- [Eindruck] Wir haben eine sehr gute Maschine und eine noch nicht bewiesene Spielstunde.

## 2. Entwicklungsverlauf aus meiner Sicht (S2 bis S8)

- **S2:** Gate M0. 8 erledigt, 8 nicht erledigt, 1 abgebrochen; Zielrechner-Messung offen (`s2/day7-10/gate/review_s2.md`, `retro_s2.md`). [Beleg]
- **S3:** Exploit-Katalog (`s3/day8-10/daniel/t07_exploit_katalog.md`); A-08 Diagnose wird erstmals nach S4 geschoben. [Beleg]
- **S4/S5:** Refinement und Briefs vorhanden, aber kein Review und keine Retro im Repo. [Beleg] Das ist eine Lücke in meiner Dokumentation.
- **S6:** Review/Retro vorhanden; die Diagnose bleibt Stretch und wird nicht fertig. [Beleg]
- **S7 (Wendepunkt):** Der Fehlalarm "1,6 M Dreiecke" war ein Zählwert ohne Culling, live etwa 0,62 M. Ein Messfehler lag bei Faktor 2,5. Basti korrigiert den Maßstab (10 m gegen 25 m je Feld) (`s7/review_retro.md`, `basti_feedback_01-11.md`). [Beleg]
- **S8:** Design-Sprint "Welt" mit 37 Streitpunkten (K1 bis K37), Regelwerk v1.1 und Welle 1/2 (`s8/design-sprint/phase3/11_streitprotokoll.md`, `phase4/integration_w2.md`). [Beleg]
- Tempo: 76 Commits in drei Tagen (33, 34, 9) (`git log`). [Beleg]

## 3. Was gut lief (belegt)

- Gates mit Vorab-Kriterien haben stilles Schönrechnen verhindert (D8). [Beleg: `s2/.../gate_m0.md`]
- Der 1,6-M-Fehlalarm wurde als Zähl- und nicht als Livewert enttarnt, bevor er Planung bestimmt hat. [Beleg: `s7/review_retro.md`]
- Das Streitprotokoll macht Gegenpositionen sichtbar statt sie zu glätten (K1 bis K37). [Beleg]
- Entscheidungen haben Typ und Revisionsspalte. [Beleg: `decisions_19-11.md`, `decisions_04-12.md`]

## 4. Was nicht gut lief, wiederkehrende Kompromisse (Zähler)

| Kompromiss | Zähler | Beleg |
|---|---|---|
| A-08 Diagnose verschoben (S3 nach S4, S4 raus, S6 Stretch nicht fertig, S7 nach S8; nicht im S8-Charter) | 4 | `s3/.../s4_kandidaten.md`, `s6/review_retro.md`, `s7/review_retro.md` |
| Firmenkauf verschoben | 3 | `s7/review_retro.md` |
| Zielrechner-Messung offen | 3 | `s2/.../f05_zielrechner.md` |
| Basti korrigiert Maßstab/Umfang nachträglich | 2 | `basti_feedback_01-11.md`, `basti_feedback_02-11.md` |
| Meine Entscheidung kam zu spät | 2 | `s6/block-a/entscheidungen_jonas.md`, `s7/refinement/ergebnis.md` |
| "ABW bewusst" ohne Ablaufdatum (E6, M8-Vertragsänderung) | 2 | `phase3b/15_regelwerk_v1_1.md` |
| Retro-Maßnahme Pairing wiederkehrend (Wirkung "nicht belegt") | 3 | `retro_s2.md`, `retro_s3.md` |

- [Eindruck] Mein größtes Muster: Ich schiebe auf, statt zu streichen. Ein Punkt, der viermal "nach hinten" geht, ist faktisch gestrichen, nur ohne Entscheidung.
- Die Bastis-Entscheidungen E8, E10, E11, E14, E15 erweitern den Umfang ohne Kapazitätsbewertung (Lernbericht mt-po). [Beleg]

## 5. Wo das Spiel oder das Konzept scheitern könnte (nach Wahrscheinlichkeit)

1. **Hoch:** Umfang wächst schneller als Kapazität. Der Prototyp ist nur "ansehen", dahinter warten Firmenkauf, Bus, Passagiere. [Eindruck, gestützt auf Zähler oben]
2. **Hoch:** Ein einziger Tester (Basti) ist zugleich Auftraggeber. Nach Nielsen/Landauer findet ein Tester bei L = 31 % etwa 31 % der Probleme, fünf finden etwa 84 % (1-(1-L)^n). [Beleg: Rechnung, Quellen in Abschnitt 7]
3. **Mittel:** Pfeiler 3 und 4 bleiben Poster, weil nie ein Feature wegen ihnen abgelehnt wurde. [Eindruck; kein belegter Gegenfall im Repo]
4. **Mittel:** Das Bot-Zielband (Bankrott 10 bis 30 %) ist ein Proxy; Goodhart-Risiko. [Beleg: Lernbericht, Unsicherheit]
5. **Niedrig bis mittel:** Maßstabsfehler wiederholen sich (10 m gegen 25 m). [Beleg: S7]

## 6. Meine drei wichtigsten Empfehlungen an Basti für Sprint 8

1. **A-08 Diagnose entscheiden:** entweder in S8 bauen (Schätzung: 1 Tag) oder streichen mit ADR-Eintrag. Eine fünfte Verschiebung ist keine Option. Aufwand: 1 Tag oder 15 Minuten.
2. **Kapazitätsbilanz vor jeder neuen Entscheidung:** E8, E10, E11, E14, E15 in Tagen bewerten; neue Punkte nur gegen Streichung eines alten (Tausch). Aufwand: 0,5 Tag, danach 15 Minuten je Refinement.
3. **Spielstunden-Test mit 3 bis 5 Fremden** statt nur Basti, sobald Bus und Passagier laufen. Aufwand: 1 Tag Vorbereitung, 0,5 Tag Auswertung. Vorher: Leitfrage und Nicht-Beweis-Liste je Welle schriftlich.

## 7. Recherchen dieser Runde und Lernlog-Zeilen

**R1: Wie viele Tester braucht ein Test?** Quellen: Nielsen/Landauer (1-(1-L)^n, L = 31 %), Einzelauswerter etwa 35 %, fünf etwa 75 % (Cornell- und UMD-Vorlesungsfolien, sekundär); NN/g-Seite ohne Prozentzahlen. Ergebnis: Ein Tester reicht nicht, die Zahl hängt an der Fehlerart. Konfidenz: mittel (sekundär). [Beleg]
**R2: Bot-Zielband mit kleinem n.** Wilson statt Wald für Anteile nahe 0 oder 1; ich habe beides gerechnet (Python, lokal), Wilson ist enger an der Wahrheit. Brown/Cai/DasGupta (projecteuclid) gesperrt; Ersatz durch Lehrfolien und Wikipedia. Konfidenz: mittel. [Beleg]
**R3: Vertical-Slice-Definition.** Xsolla-Artikel gesperrt (PROVENANCE_REQUIRED, nicht umgangen); weitere Quellen stützen nur die Kernaussage "ein Slice zeigt eine spielbare Stunde in Endqualität". Konfidenz: niedrig; die Folgerung für unseren Slice ist [Eindruck].
**Nicht erreichbar:** Reddit (nicht umgangen), wiki.openttd.org (client_error), engineered.at (kein Text).

**Lernlog-Zeilen (2026-11-03):**

| Datum | Situation | Kompromiss/Lücke | Zähler | Folge |
|---|---|---|---|---|
| 2026-11-03 | Refinement S8 | A-08 Diagnose erneut verschoben | 4 | Entscheidung erzwingen (Empf. 1) |
| 2026-11-03 | Basti-Feedback 02.11 | Umfang wächst ohne Kapazitätsbewertung | 2 | Tauschregel |
| 2026-11-03 | Prototyp-Abnahme | "ABW bewusst" ohne Ablaufdatum | 2 | Ablaufdatum Pflicht |

## 8. Vorschläge für Skill-Änderungen (nur Vorschläge, nichts geschrieben)

1. **Teil D, neue Regel:** "Nach der dritten Verschiebung entscheidet der PO: bauen oder streichen." Marke [Konsens] (PMI-Scope-Creep 52 %, Lernbericht); Quelle: Zähler A-08 = 4.
2. **Teil B, Entscheidungsvorlage:** Zeile "revidierbar bis/durch" und Sprintpräfix (S2-E3 gegen S8-E3). Marke [Konsens] (Nygard-ADR); Quelle: Namenskollision im Lernbericht.
3. **Teil C, Tester-Regel:** "Ein Tester findet etwa 31 %; Testergebnisse mit n nennen." Marke [Beleg sekundär]; Quelle: R1.
4. **Teil A, Pillars:** "Pillar gilt erst nach einem abgelehnten Feature." Marke [Konsens]; Quelle: Lernbericht, Raspberry-Pi-Beispiel.
