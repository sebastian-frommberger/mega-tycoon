# Lena (Game Design): Resümee (Stand 03.11.2026)

Pfade relativ zu `/home/claude/mega-tycoon/`. Marken: [Beleg] = Datei oder URL genannt, [Eindruck] = meine Wertung.

## 1. Wie ich Spiel und Konzept heute sehe
**Kern:** Ein Tycoon, in dem man Güterketten bis zum Endabnehmer schließt, Orte nur durch Versorgung wachsen lässt (E7) und jedes Klemmen mit Ort und Ursache erklärt bekommt (`concept/lena.md`, `sprints/s8/design-sprint/charter.md`) [Beleg].

**Was trägt:** die ersten 12 Minuten (knappe Kasse, erste Mehl-Linie, +326 $/min bei 7:37) [Beleg: `sprints/s6/zocken/tagebuch_lena.md`], fünf von fünf Starts erreichen die erste Kette [Beleg: `sprints/s7/abnahme/daniel_d09.md`], Bankrottquote 17,8 % bei n = 2.700 [Beleg: `phase4/tobias_welle1.md` §1].

**Was noch Papier ist:** alles nach Minute 12 bis 20. G-01 (F1–F7, Leerlauf-Regel), Skilltree (SK-01 Papier, SK-02 nicht gebaut), Epochen (nur W1 als Prototyp), Konkurrenz (kein Code), Floß (Kulisse), Schwierigkeitsstufen (Skizze), Firmenkauf, Energie und Mitarbeitende. Dazu: Die 1820-Welt (Fuhrwerk, Dörfer mit 150–350 EW) und die Ökonomie (Slice-Karte, Lkw und Zug) sind noch nicht verbunden; Aylins Rundgangkarten sagen selbst „nicht an die Wirtschaft angeschlossen“ [Beleg: `phase4/aufgabenkarten_v1_1.md`; `phase4/tobias_welle1.md` §2.1]. [Eindruck] Heute existiert ein 50-Minuten-Slice plus eine Welt zum Ansehen. „1820 bis heute“ ist eine Absicht, kein Produkt. Alle Tester außer Basti sind simuliert (`README.md`).

## 2. Entwicklungsverlauf aus meiner Sicht
- **S2:** Konzept und Widerspruchsliste (24 Punkte, 12 entschieden, 8 offen). L-05/L-06 liefen mit 0 von 9 Testern, Gate vertagt [Beleg: `sprints/s2/day7-10/gate/review_s2.md`, `design/game-design/day1-3/widersprueche.md`].
- **S3/S4:** L-08 Slice-Regeln (Validator gleicht 143 Keys ab), L-10 Baustoff-Regel. Vier offene Fragen lagen bis D17–D20 [Beleg: `sprints/s3/day8-10/review/retro_s3.md`].
- **S5/S6, Wendepunkt D22:** Kein Archetyp mehr, HQ frei wählbar; Startkapital von 4.500/7.000 $ auf 6.000 $ für alle (T-14).
- **S6, Wendepunkt Zocker-Tagebuch:** 7/7 Ziele nach 12 min, danach 38 min Plateau, Zug +1.091 gegen Lkw +100 $/min. Daraus G-01 und T-15 [Beleg: `tagebuch_lena.md`].
- **S7:** G-01, Skillpunkt-Quelle entschieden (Meilensteine und Etappen, keine Transport-XP) [Beleg: `sprints/s7/refinement/ergebnis.md` Z. 80, 91]. Bastis Rundgang 02.11. löst den Design Sprint aus.
- **S8-Design-Sprint, 02.–03.11.:** E1–E15, K1–K40, Regelwerk v1/v1.1, Prototyp Welle 1–2. Wendepunkt E4/E8: Start 1820 und Partie bis heute, bei 12 min je Jahr 206 Jahre ≈ 41 Stunden [Beleg: `phase3b/15_regelwerk_v1_1.md` A1].

## 3. Was gut lief (belegt)
- Messgröße je Ziel („Ziel hakt falsch“ als Lehre) und Wiederspielbarkeit der Tests: `g01_progression.md` §1.
- Tagebuch statt Meinung: Mein S6-Befund war der wirksamste des Projekts, T-15 senkte den Mehl-Exploit von 20,1 auf 30,4 Minuten bis M7 [Beleg: `sprints/s7/block-a/tobias.md`].
- Entscheidungsfluss im Design Sprint: 20 Konflikte (K1–K20) mit PO-Entscheid und Bastis E6–E15 innerhalb von zwei Tagen [Beleg: `phase3/11_streitprotokoll.md`, `charter.md`].
- Leitplanke „Fehlertexte mit Lösung bleiben immer an“ steht in Schwierigkeit und UX [Beleg: `phase2/04_schwierigkeit.md`].

## 4. Was nicht gut lief, wiederkehrende Kompromisse
| Muster | Zähler | Beleg |
|---|---|---|
| Zahlen als „Platzhalter für Tobias“ übergeben, ohne Messpunkt | 3 (L-08, SK-01, G-01) | `sprints/s6/block-b/sk01_skilltree_v0.md`, `g01_progression.md` §6: keine der 6 Fragen beantwortet |
| Konzeptdatei nicht nachgezogen (D12/D13 nur teils, D22, Punktequelle S7, K21) | 4 | `concept/lena.md` zeigt noch Ast-XP, Epochen ab 1850, Archetyp-Startkapital 4.500–7.000 $ |
| Test mit Menschen vertagt | 4 (S2, S3, S6, S8-Rundgang) | `review_s2.md`; `retro_s3.md`; `l13_aufgabenkarten.md` |
| Entscheidung auf S8/S9 geschoben | 17 + 16 + 7 Nennungen (grep) | `11_streitprotokoll.md`, `15_regelwerk_v1_1.md` |
Dazu ein Fehler im eigenen Skill: Er behauptet, die Skillpunkt-Quelle sei „nicht aufgelöst“. Das Repo hat den Entscheid seit S7 (Trigger d). [Eindruck] Mein Konzept driftet, weil ich Entscheide in Protokollen ablege, aber `lena.md` nicht ändere.

## 5. Wo das Spiel scheitern könnte (nach Wahrscheinlichkeit)
1. **Hoch: Leere nach M7 bleibt.** G-01 ist Papier, die 3-Minuten-Regel wird von ihren eigenen Beispielen verfehlt (Abstände 13→19→26→33→41 = 6–8 min, eigene Rechnung nach `g01_progression.md` §2). [Eindruck]
2. **Hoch: Zwei Welten, eine Kalibrierung.** Sobald die 1820-Welt an die Ökonomie angeschlossen wird, gelten T-15/T-16 nicht mehr (59 % der Orte liegen unter 15 Nachfrage/min) [Beleg: `tobias_welle1.md` §1].
3. **Mittel-hoch: Zu viel Papier.** Konkurrenz, Wasser, Skilltree, Energie, Firmenkauf, 6 Epochen bei ca. 8 PT je Person und Sprint (`sprints/s7/refinement/ergebnis.md`). [Eindruck]
4. **Mittel: Zeitskala.** 12 min je Jahr ergibt 6–8 Stunden je Epoche (W1: 30 Jahre = 6 h), mein Konzept rechnet 60–120 min je Epoche und 4–10 h je Run (`concept/lena.md`). Passend wäre 1,5–4 min je Jahr [Beleg: eigene Rechnung aus beiden Dateien].
5. **Mittel: Punktelücke.** Seit dem S7-Entscheid gibt G-01 Punkte nur bis Minute 60, das Konzept erwartet ca. 40 Punkte bis Epoche V. Wer liefert sie in Stunde 2 bis 40? [Beleg: `g01_progression.md` §4; `concept/lena.md`]
6. **Niedrig-mittel:** Einzugsgebiet wird nicht verstanden (Aylin-Test steht aus, K1).

## 6. Meine drei wichtigsten Empfehlungen für Sprint 8
1. **Eine Wahrheit für Fortschritt (ca. 2,5 PT: Lena 1,5, Tobias 0,5, Jonas 0,5).** `lena.md`, `tobias.md`, `hq.md`, `city.md` auf D12–D22, K21 und den S7-Entscheid bringen. Dazu festlegen: Punktequelle nach Minute 60 und Epochensteuerung (Vorschlag: Kalender als Frühestdatum plus Meilenstein-Tor).
2. **G-01 messbar bauen (ca. 8 PT: Lena 2, Mira 3, Tobias 3).** F1–F7 mit Bot-Messpunkt, Leerlauf-Lücke ≤ 3 min als Testkriterium, Tobias kalibriert die sechs offenen Fragen. Vorher 25 min Basti am Rundgang (Karten A1–A7), damit E9 und das Einzugsgebiet nicht Papier bleiben.
3. **Kalendertempo und Floß entscheiden, bevor gebaut wird (ca. 4 PT).** Basti wählt Standardtempo (siehe 7.2); Floß als Einbahn-Wandler zuerst als Papier (1 PT) plus Ein-Tages-Prototyp (Felix 1,5, TA 0,5), Kriterium: Spieler trifft je Floß eine Entscheidung.

## 7. Recherchen dieser Runde und Lernlog
**7.1 Floß: Rückreise der Mannschaft?** Quellen: [planet-schule, Skript Waldarbeiter und Flößer](https://live-origin.planet-schule.de/schwerpunkt/der-schwarzwald/die-waldarbeiter-und-floesser-film-104.pdf): Kinzig-Flößer gingen von Willstätt „ca. 70 Kilometer in etwa 14 Stunden“ zu Fuß heim; [Flößerpfad, Holz im Fluss](https://floesserpfad.de/resources/01%20Website/PDFs/Holz%20im%20Fluss%202020.pdf): Fahrt 2–6 Tage; [Keweloh, DSA 1988](https://urn.dsm.museum/DSA/DSA11_1988_073098_Keweloh.pdf) nennt die „Heimreise“ ohne Einzelheiten. Ergebnis: Rückweg etwa ein Tag, Hinfahrt mehrere; bei 12,8 km Kartenbreite vernachlässigbar, kein Rückfahrt-Fahrzeug nötig. Holländerfloß (Rhein bis Dordrecht): nicht belegt. Konfidenz mittel (Kurzstrecke, Fußmarsch nur 1 Quelle), niedrig (Fernfahrt).

**7.2 Kalenderlänge in Referenzspielen.** Quellen: [openttd.org, Timekeeping](https://www.openttd.org/news/2024/03/23/timekeeping.html) und [OpenTTD PR 10322](https://github.com/OpenTTD/OpenTTD/pull/10322): 74 Ticks je Tag, 27 ms je Tick, Wirtschaftsmonat ≈ 60 s, Wirtschaftsjahr ≈ 12 min, Wallclock-Standard 12 Minuten je Jahr. Ergebnis: Mega Tycoon (600 Ticks à 100 ms je Monat, 12 min je Jahr) entspricht dem OpenTTD-Standard, das schließt den [~] in `15_regelwerk_v1_1.md` A1. Das Problem ist nicht das Tempo, sondern 206 Jahre. Konfidenz hoch (2 Dokumente, aber dieselbe Projektquelle). Nicht belegt: OpenTTD-Standardlaufzeit.

**Nicht recherchiert:** Leerlauf-Regel (Rollen-Trigger „nur Gefühl“): braucht einen Bot-Lauf, keine Quelle. tt-wiki.net-Abruf wurde mangels Freigabe nicht gesendet; Reddit blieb gesperrt.

| Datum | Situation | Kompromiss / Lücke | Zähler |
|---|---|---|---|
| 2026-11-03 | Skill gegen Repo | Punktequelle: Skill „offen“, Repo „entschieden“ (grep, kein Web) | 1 |
| 2026-11-03 | Konzept-Drift | `lena.md` nicht nachgezogen | 4 |
| 2026-11-03 | Platzhalter | Zahlen „für Tobias“ ohne Messpunkt | 3 |
| 2026-11-03 | Tests | Mensch-Test vertagt | 4 |
| 2026-11-03 | Floß | Rückreise: geschlossen (7.1) | 1 |
| 2026-11-03 | Zeitskala | 12 min je Jahr belegt (7.2) | 1 |

## 8. Vorschläge für Skill-Änderungen (nur Vorschläge)
- B5.1, C2.1, C3 Zeile 2, C4.1: „Skillpunkt-Quelle offen“ ersetzen durch „entschieden S7: Meilensteine plus Etappen, keine Transport-XP“; `concept/lena.md` als veraltet markieren. [Beleg: `sprints/s7/refinement/ergebnis.md`]
- A5 Floßzeile: „Rückreise: Fußmarsch ca. 70 km in 14 h (Kinzig), Fernfahrt offen“ [Beleg, mittel: planet-schule].
- A4 Zeitskala: „OpenTTD ≥ 14: Wirtschaftsjahr ≈ 12 min [Beleg: openttd.org]“ statt Transport-Fever-[~] im Regelwerk-Zitat.
- B5.5 ergänzen: „W1 = 30 Jahre = 6 h bei 12 min je Jahr; Konzept 60–120 min je Epoche entspricht 1,5–4 min je Jahr [R]“.
- A9 neuer Fehler: „Entscheid im Protokoll, Konzeptdatei nicht geändert“.
