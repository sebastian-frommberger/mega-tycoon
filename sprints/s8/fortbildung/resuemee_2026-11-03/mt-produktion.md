# Produktion / Scrum Master: Resümee (Stand 03.11.2026)

Ich bin Katrin. Read-only aus dem Repo (`/home/claude/mega-tycoon`) und aus Recherche. [Beleg] = Datei oder URL genannt, [Eindruck] = meine Wertung.

## 1. Wie ich Spiel und Konzept heute sehe

**Kern:** Ein Transport-Tycoon (Godot 4.7.2) mit einem simulierten Agententeam und dem Vertrag `VERTRAG.md` (Dateieigentümer, Arbeitskopien, dreiseitiger Merge). [Beleg]

**Was trägt:**
- Der Prozess liefert: 76 Commits in drei Tagen (01.11.: 33, 02.11.: 34, 03.11.: 9) und Regression 24 Zeilen grün in 1.090 s (`slice/tests/d07_regression_summary.md`). [Beleg]
- Gates mit Go/No-Go/Vertagen (D8) und Belegstufen M/V/R/O ("synthetisch zählt nicht"). [Beleg]

**Was noch Papier ist:**
- Wir haben keine Velocity, keine Referenzklasse und keinen Messwert, ob Parallelbetrieb der Agenten netto Zeit spart (`mt-produktion/LERNBERICHT.md`). [Beleg]
- Retro-Maßnahmen haben keinen Wirkungsnachweis. [Beleg: `retro_s3.md`]
- [Eindruck] Wir planen nach Gefühl und messen nach der Tat.

## 2. Entwicklungsverlauf aus meiner Sicht (S2 bis S8)

- **S2:** 8 erledigt, 8 nicht erledigt, 1 abgebrochen; Felix' Puffer verbraucht (`s2/day7-10/gate/review_s2.md`, `retro_s2.md`). [Beleg]
- **S3:** Export-Templates fielen erst spät als Blocker auf (`s3/day8-10/review/retro_s3.md`). [Beleg]
- **S4/S5:** Briefs und Refinement vorhanden, aber weder Review noch Retro im Repo (`s4/brief_day1-5.md`, `s5/brief_day1-5.md`). [Beleg] Meine Lücke.
- **S6:** Review/Retro; Stretch-Ziel Diagnose nicht erreicht (`s6/review_retro.md`). [Beleg]
- **S7:** Messfehler Faktor 2,5; 1,6 M gezählt gegen 0,62 M live; Tests rot auf Platzhalterkarte; zwei Agenten liefen ins 5-Stunden-Limit (`s7/review_retro.md`). [Beleg]
- **S8:** Design Sprint "Welt" mit Aufgabenkarten v1.1, Welle 1 und 2, Fixpass (`s8/design-sprint/phase4/aufgabenkarten_v1_1.md`, `fixpass_w2.md`). [Beleg]
- Wendepunkt: S7, weil dort erstmals Messart (gezählt gegen live) als Prozessproblem sichtbar wurde. [Eindruck]

## 3. Was gut lief (belegt)

- Dateieigentümer plus Arbeitskopien verhindern die meisten Merge-Konflikte. [Beleg: `VERTRAG.md`]
- Gate-Kriterien vor der Messung (D7/D8) haben "nachträgliches Schönrechnen" verhindert. [Beleg: `s2/.../gate_m0.md`]
- Die Regression wächst mit (24 Zeilen) und läuft vor Abnahme. [Beleg: `d07_regression_summary.md`]
- Aufgabenkarten v1.1 haben Ziel, Eigentümer und Prüfkommando. [Beleg: `aufgabenkarten_v1_1.md`]

## 4. Was nicht gut lief, wiederkehrende Kompromisse (Zähler)

| Kompromiss | Zähler | Beleg |
|---|---|---|
| Retro-Maßnahme Pairing kehrt wieder, Wirkung "nicht belegt" | 3 (S2, S3, S4) | `retro_s2.md`, `retro_s3.md` |
| A-08 Diagnose verschoben | 4 | `s3/.../s4_kandidaten.md`, `s6/review_retro.md`, `s7/review_retro.md` |
| Zielrechner-Messung ausstehend | 3 | `f05_zielrechner.md` |
| Zählwert/Headless-Wert statt Live-Wert (1,6 M, Faktor 2,5, DC-Zuordnung) | 3 | `s7/review_retro.md` |
| Tests auf Platzhalterkarte rot | 2 | `s7/abnahme/daniel_d09.md` |
| Regression "nicht neu gelaufen" | 2 | `phase4/integration_w2.md`, ta_welle2 P7 |
| Hook in fremder Datei, doppelte INSTANCE_CUSTOM-Nutzung | 2 | `VERTRAG.md`, `phase4/tobias_welle1.md` |
| Vertragsänderung M8 nachträglich | 1 | `VERTRAG.md` |

- [Eindruck] Der Kern: Wir erkennen Muster, aber ohne Owner und Datum kehren sie zurück. Pairing ist das Lehrbeispiel.
- Die Bot-Zeit M7 weicht ab: 36,0 statt 30,4 min, Repo-Drift ungeklärt (Lernbericht). [Beleg]

## 5. Wo das Spiel oder das Konzept scheitern könnte (nach Wahrscheinlichkeit)

1. **Hoch:** Token- und Limitverbrauch wird zum Engpass. Zwei Agenten liefen in S7 ins Limit; Unteragenten ziehen ebenfalls vom selben Kontingent (Alex Cloudstar, 28.10.2026, sekundär). [Beleg]
2. **Hoch:** Schätzung bleibt Gefühl. Ohne Referenzklasse liegt der Planungsfehlschluss bei im Mittel 55,5 statt 33,9 Tagen, nur etwa 30 % im Plan (Buehler-Studie, laut Lernbericht). [Beleg sekundär]
3. **Mittel:** Parallele Schreiber erzeugen Schnittstellenfehler (Hooks, Vertragsänderung), Anthropic und Cognition raten zu einem Schreiber oder disjunkten Dateien. [Beleg, Herstellerquellen mit Eigeninteresse]
4. **Mittel:** Flaky-Rate der Suiten unbekannt (Läufe 1.361 bis 1.565 s laut Lernbericht, 21 Suiten; später 24 Zeilen). [Beleg]
5. **Niedrig:** Blocker erst spät entdeckt (Export-Templates S3). [Beleg]

## 6. Meine drei wichtigsten Empfehlungen an Basti für Sprint 8

1. **Retro-Revisit mit Datum:** höchstens 3 Maßnahmen, je Owner und Prüfdatum; Retro beginnt mit der Prüfphase. Aufwand: 15 Minuten je Retro, Einführung 1 Stunde.
2. **Referenzklasse und Verbrauchslog:** aus S5 bis S7 Kartenlaufzeit (Start/Ende) und Token-/Limitverbrauch sammeln, danach Schätzung als Spanne. Aufwand: etwa 1 Tag einmalig, danach 10 Minuten je Karte.
3. **Blocker-Check Tag 1 und Messprotokoll:** Export, Tools, Zielrechner, Limit; jede Messung mit Messart, Last, n, Wiederholungen, gezählt/live getrennt. Aufwand: 1 Stunde Vorlage, 15 Minuten je Sprintstart.

## 7. Recherchen dieser Runde und Lernlog-Zeilen

**R1: Retro-Umsetzung.** Quelle: Retromat (Revisit-Phase 2/4/6 Wochen), Blogs; Ergebnis: Maßnahmen brauchen Owner und Datum; Konfidenz: mittel (Praxis, kaum Studien). [Beleg]
**R2: Planungsfehlschluss.** Quelle: Wikipedia zu Buehler et al., Cone of Uncertainty (McConnell-Original gesperrt); Ergebnis: Spanne statt Einzelwert; Konfidenz: mittel.
**R3: Claude-Code-Limits.** Quelle: Alex Cloudstar (28.10.2026): 5-Stunden-Fenster plus Wochenlimit, Unteragenten verbrauchen Kontingent, Agententeams etwa 7-fach Tokens; Wochenlimit seit 14.09.2026 um 25 % höher. Offizielle Seiten `support.claude.com/.../11145838` und `code.claude.com/docs/en/costs.md` waren gesperrt (PROVENANCE_REQUIRED, nicht umgangen). Konfidenz: niedrig bis mittel (nur eine unabhängige Zweitquelle: Lernbericht nennt Anthropic etwa 15-fach gegenüber Chat).
**R4: METR.** Selbsteinschätzung gefühlt 20 % schneller, real 19 % langsamer (2025, überholt laut Lernbericht); Konfidenz: mittel.
**Nicht erreichbar:** Reddit (nicht umgangen).

| Datum | Situation | Kompromiss/Lücke | Zähler | Folge |
|---|---|---|---|---|
| 2026-11-03 | Retro S7/S8 | Maßnahme wiederholt ohne Owner/Datum | 3 | Revisit-Phase |
| 2026-11-03 | S8 Integration W2 | Regression "nicht neu gelaufen" | 2 | Pflichtlauf vor Abnahme |
| 2026-11-03 | S7/S8 | Zähl- statt Livewert | 3 | Messprotokoll |

## 8. Vorschläge für Skill-Änderungen (nur Vorschläge)

1. **Teil D, Retro:** "Jede Maßnahme: Owner, Revisit-Datum, Wirkungsprüfung." Marke [Konsens] (Retromat); Quelle: R1, Pairing-Zähler 3.
2. **Teil B, Planung:** "Schätzung als Spanne mit Referenzklasse." Marke [Konsens] (Buehler, Cone of Uncertainty); Quelle: R2.
3. **Teil C, Agenten:** "Token-/Limitverbrauch je Karte mitführen." Marke [Einzel] (sekundär, R3); Quelle: S7-Review.
4. **Teil B, Gate:** "Messart, Last, n, Wiederholungen Pflichtfelder." Marke [Repo, hoch]; Quelle: S7 (1,6 M gegen 0,62 M).
