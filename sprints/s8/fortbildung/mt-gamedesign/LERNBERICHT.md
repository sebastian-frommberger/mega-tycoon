# Lernbericht Lena (Game Design), 03.11.2026

Zu `SKILL.md` im selben Ordner. Alle Repo-Verweise relativ zu `/home/claude/mega-tycoon/`.

## 1 Selbstanalyse (Schritt 1): wo Wissen fehlte und wo das Team unsicher war
Gelesen: `design/game-design/` (HQ-Startwerte, Wachstumsgewichte), `concept/lena.md`, `concept/leitplanken.md`, `sprints/s7/block-b/g01_progression.md`, `sprints/s7/review_retro.md`, `sprints/s7/basti_feedback_01-11.md`, `sprints/s8/feedback_02-11/basti_feedback_02-11.md`, `sprints/s8/design-sprint/` (charter, phase2 01–06, phase3 11–14, phase3b 15, phase4 `tobias_welle1.md`, `stadt_welle1.md`, `ta_welle2.md`), `slice/data/economy_slice.json` (Meilensteine, Genre-Standard), `slice/data/vehicles.json`.

Wiederkehrende Unsicherheit mit Beleg:
- Progression nach M7: G-01 mit sechs offenen Fragen an Tobias; Punktquelle widersprüchlich (G-01 nur Meilensteine gegen `concept/lena.md` Ast-XP).
- Epochen: zwei Tabellen (`concept/lena.md` I–V ab 1850 mit 3-von-5-Meilensteinen gegen `15_regelwerk_v1_1.md` W1–W6 ab 1820 nach Kalender); K21 trennt Bild (Kalender) von Spielfortschritt (offen).
- Schwierigkeit: E5 „eher nicht Design“, Entscheid S8; Streit Tobias (nur Geld) gegen Lena (zwei Welt-Hebel) in `phase2/04_schwierigkeit.md`.
- Konkurrenz: kein Code (`15_regelwerk_v1_1.md` D1), E14 Default an und sichtbar, Hebel nur Skizze.
- Wasser/Floß: E15 „theoretisch von Anfang an mit Flößen“, Mechanik offen (K34, F10).
- Easing: E9 entschieden, Prototyp teilweise, Tests E1–E9 und Bastis Rundgang stehen aus (`15_regelwerk_v1_1.md` B5).
- Kalendertempo: E12 wählbar, Ökonomie rechnet je Minute (K26).
- Startkapital: Konzept 4.500–7.000 $ je Archetyp, Slice 6.000 $, Schwer 4.500 $.

Nicht in der Tiefe gelesen: `refinement/` außer Tobias-Teil, `concept/industry.md`, `concept/hq.md`, `design/ux`, `design/qa`, `design/art`.

## 2 Priorisierte Lernfragen
Status: beantwortet / teilweise / offen. Ort im Skill in Klammern.

1. Skillpunkt-Quelle und Progression nach M7: Meilenstein, Ast-XP oder beides? Status: teilweise. Konsens „Freischalten durch Tun“ (Factorio-Trigger, Colossal-Order-XP, Anno-Stufen; A2); Entscheid und Zahlen offen (B3, B5, B12 Vorschlag hybrid).
2. Epochen-Steuerung: Kalender, Meilenstein oder Tor-Kombination? Status: teilweise. Bild folgt dem Kalender (K21, entschieden); Fahrzeuge/Ketten offen (B5, B12).
3. Schwierigkeit: Dürfen Welt-Hebel mitwirken? Status: teilweise. Hebelfamilien Geld/Welt/Gegner/Ziele/Hinweise (A3); RCT zeigt Ziele als Hebel; Entscheid S8 offen.
4. Konkurrenz als Spielfigur: Sichtbarkeit, Fairness, Schutzregeln. Status: teilweise. Sichtbar (E14, K37), Schutzregeln K39; OpenTTD-KI-Rahmen (Rechenbudget, Verbote, „freundlich“-Option, A3); kein Code.
5. Floß und Wasser als Mechanik (E15). Status: teilweise. Reale Größen und Zeiten (A5); Folgerung Einbahn-Wandler, Floß ist Fracht und Fahrzeug; Rückreise der Flößer in keiner Quelle; Mechanik-Entscheid offen.
6. Leerlauf-Regel „keine 3 min ohne Entscheidung“: Stimmt sie? Status: teilweise. Rechnung: die Beispielminuten 13, 19, 26, 33, 41 liegen 6–8 min auseinander, die Etappenziele 7–8 min (B11); ein Bot-Test dazu ist nicht gefunden.
7. Zeitskala 1820 bis heute: Kalendertempo gegen Zielzeiten. Status: teilweise. E12 wählbar, K26 Wirtschaft je Minute; Zielzeiten in Minuten (G-01) gegen Jahreszahlen der Epochen ungeklärt (B5 Punkt 5).
8. Skilltree-Umfang: 6 Äste, ca. 110 Knoten, ca. 40 Punkte, 1.000 XP je Punkt, Respec 25 %. Status: offen. Keine Quelle nennt Knotenzahlen (S4); unkalibriert.
9. Fahrzeug-Easing: Welche Prinzipien und Grenzen? Status: teilweise. 12 Prinzipien (slow in/out, Anticipation, Arcs mit mechanischer Ausnahme), Repo-Entscheide K27–K31, Schuhkarton-Ursache FAST-Interpolation; Abnahme durch Basti offen.
10. Onboarding und Startwerte: Startkapital, „Erfahrener Start“, Meilensteine als Tutorial. Status: teilweise. Slice-Meilensteine ms_1a–ms_7 belegt (B10); Konflikt 4.500–7.000 gegen 6.000 $.
11. Wachstum als sichtbares Ziel: Ist das Einzugsgebiet verständlich? Status: offen. Aylin-Test im Rundgang steht aus (K1); Referenzspiele zeigen Forenstreit bei verstecktem Prozentboni (TF2, A7).
12. Zielgruppen und Spielertypen: Wer spielt das, was wollen sie? Status: offen. Reddit gesperrt; nur Entwicklerblogs, ein Steam-Thread, Rezensionen.

## 3 Die fünf wichtigsten Erkenntnisse
1. „Freischalten durch Tun“ ist die stärkste Gemeinsamkeit der Referenzen (Factorio-Trigger-Technologien, Colossal-Order-XP, Anno-Stufen); Mega Tycoon hat zwei unvereinbare Punktquellen (G-01 Meilensteine gegen Ast-XP) und braucht einen Entscheid, bevor Tobias kalibrieren kann (`g01_progression.md` §4, `concept/lena.md`).
2. Die Leerlauf-Regel „keine 3 min ohne Entscheidung“ wird von ihren eigenen Beispielen nicht erfüllt (Abstände 6–8 min); es fehlen etwa zwei bis drei Entscheidungsquellen je 8-Minuten-Fenster, und der Bot-Test existiert nicht (`g01_progression.md` §2).
3. Das Floß ist Fracht und Fahrzeug in einem: Holz wird am Ziel verkauft (Holländerfloß bis 2 Jahre von Bindung bis Verkauf), also kein Rückfahrt-Fahrzeug, sondern ein Einbahn-Wandler mit Neubau am Oberlauf; Strömung als Tempo; Rückreise der Mannschaft ist nirgends belegt (Planet Wissen, Wikipedia Flößerei).
4. Easing ist ein reines Darstellungsproblem (K27): Der „Schuhkarton“ kommt aus der MultiMesh-Interpolation `INTERP_QUALITY_FAST`, nicht aus fehlendem Easing; Lösung Spline, gleitender Mittelwert, zeiterhaltende Kurvenzonen (`15_regelwerk_v1_1.md` B1–B2).
5. Schwierigkeit hat fünf Hebelfamilien; Geld-Hebel sind messbar, Welt-Hebel vermischen sich mit dem Seed, Ziele (RCT: Szenario) sind ein dritter Weg, und Konkurrenz muss sichtbar sein, sonst wirkt sie wie ein Fehler (K37; OpenTTD-Presets, RCT-Interview).

## 4 Was ich künftig anders mache
- Jedes Ziel mit Messgröße und Bot-Messpunkt einreichen.
- Je Konflikt eine Entscheidung einfordern (Skillpunkte, Epochen), keine zwei Konzepte parallel pflegen.
- Spielerstimmen aus mindestens zwei Quellenarten holen, Reddit als Lücke ausweisen.
- Flow, DDA und Fairness als Prüfraster nutzen, nicht als Beweis.
- Floß, Fähre und Schiff erst als Prototyp-Funktion zeigen, dann entscheiden.

## 5 Ehrliche Einschränkungen
- Reddit war per WebFetch gesperrt (SITE_BLOCKED) und wurde nicht umgangen (keine Spiegelserver). tt-forums.net (Anubis) und wiki.openttdcoop.org (robots) nicht lesbar. WebFetch ließ nur URLs aus Suchtreffern zu.
- 34 Quellen im Skill gelistet, mehrere dünn: Routledge (nur Inhalt), Pfister (Zusammenfassung), Anno-Wiki (nur Stufenfreischaltung), dedoimedo und gameplay.tips (Einzelmeinungen), Steam-Thread (Forenstand 2023), Crook-Artikel (F2P-Fokus, keine Knotenzahlen), Spieltimes-Artikel (Meinungen). Penners Easing-Gleichungen nur als Suchtreffer; Godot-Doku nur lokal gelesen.
- Keine Spielerdaten, keine Playtests, keine Benchmarks; alle „Vorschläge“ ([R]) sind Folgerungen, keine Messungen.
- Zwei Repo-Dokumente widersprechen sich (Skillpunkte, Epochen, Startkapital); der Skill benennt das, entscheidet es nicht.
- Die Fortbildung hat nichts im Repo geändert und nichts committet.
