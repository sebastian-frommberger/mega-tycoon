# Refinement Sprint 6 (19.–30.01.2027) – Briefing

Release R1 "Spielbarer Loop" ist technisch fertig (S5). Basti spielt den Slice gerade selbst; sein Feedback kommt nach und kann den Sprint noch verschieben (Puffer einplanen). Release R2 beginnt: "Eigener Start und Firmenaufbau".

## Stand nach Sprint 5
- Slice: /home/claude/mega-tycoon/slice/ (Commit 8d9b72e). Theme/Styleguide (D21), angedocktes Kontextpanel, Lizenz in 2 Klicks, SoA-Fahrzeuge Default (Parität alt=soa 10/10), Kredit 2.000 $ mit zeitgewichtetem Zins, Look S-11 (Licht, Labels mit Zoom-LOD, ~2.000 Kenney-Bäume, Mittelfurt-Farm und -Mühle). D-07-Regression 8/8 grün.
- Abnahme D-07 und Bugfixes: /tmp/claude-0/gd/sprint5/day6-10/daniel.md, /tmp/claude-0/gd/sprint5/day11/felix.md, /tmp/claude-0/gd/sprint5/day11/mira.md
- Offen aus S5: keine FPS-Messung auf dem Zielrechner (Bench-.exe wartet auf Basti), Bankrottquote F-19 im Ziel 10–30 % nicht gemessen, Lager-Fix fehlt im eingefrorenen Spike sim-core (economy.gd:746), Daniels B11-NOTE überholt, Linienliste bei langen Zeilen ~388 px breit, Label-Ausblendung an HUD-Kanten (Haberau im Nahzoom).

## Material
- D22 HQ-Platzierung (Konzept, Lena): /tmp/claude-0/gd/sprint5/day1-5/lena/d22_hq_platzierung.md – offene Jonas-Fragen dort (Wagnis-Standorte, freies Umsetzen des HQ in den ersten 2 min, Kleinstadt-Start 2.500 oder 1.000).
- Tobias T-13 / D22-Zahlen / Lok-Fixkosten: /tmp/claude-0/gd/sprint5/day6-10/tobias/tobias.md (einheitlich 6.000 $ trägt nur mit Kartenpaket: Werkzeugfabrik auf 40 Felder, Dorfnachfrage ×2, Mittelfurt-Mühle auf 45 Felder; Zug zu teuer → Lok-Fixkosten 90 $/min).
- HUD-Spec U-02 (Aylin): /tmp/claude-0/gd/sprint5/day6-10/aylin/u02_hud_spec.md
- R1-Review-Ablauf (Lena): /tmp/claude-0/gd/sprint5/day6-10/lena/r1_review.md
- Spike SP-01 Betriebsprofile: Ergebnis "kein Bau in S6, in R2 wieder vorlegen" (/tmp/claude-0/gd/sprint5/day1-5/lena/sp01_regelnotiz.md, tobias.md)
- Vorgemerkt: /tmp/claude-0/gd/sprint5/vorgemerkt.md (D22, SP-01/02, Rollen)
- S5-Ergebnis (Format-Vorbild): /tmp/claude-0/gd/sprint5/refinement/ergebnis.md

## Grundregeln
D15 Genre-Standards übernehmen, Arbeit in unsere Unterschiede. D16 Basti testet selbst, keine externen Tester. D21 UI mit Liebe, keine Modale. D22 Start wie Civ: HQ frei auf der Karte platzieren, keine Archetyp-Auswahl; Spezialisierung über erste Lizenzen und Skilltree. Rollen kommen gestaffelt (neue Rolle nur mit Begründung). Kein Firmenkauf vor Bastis R1-Entscheid.

## Kandidaten (Owner, Tage grob; Kapazität je Person 8 T, Mira jetzt 6 T im zweiten Sprint)
| ID | Ticket | Owner | T |
|---|---|---|---|
| F-20 | D22 HQ-Platzierung: Platzierungsmodus auf der Karte, Hover-Vorschau (Radius, erreichbare Ketten, Stadtgröße), Startdialog entfällt | Mira 3, Felix 1, Aylin 1 | 5 |
| L-12 | D22 Regeln final: Wagnis-Standorte, Umsetzen in den ersten 2 min, Kleinstadt-Startgröße, Vorschau-Texte | Lena 1,5 | 1,5 |
| T-14 | Ein Startkapital (6.000 $) + Kartenpaket rechnen und an Sophie übergeben; Lok-Fixkosten 90 $/min; Bankrottquote Kredit 10–30 % nachmessen | Tobias 3 | 3 |
| S-12 | Kartenpaket umsetzen (Werkzeugfabrik 40 F., Dorfnachfrage, Mühle 45 F.), Karte neu einfrieren | Sophie 1,5, Tobias 0,5 | 2 |
| U-02b | HUD-Bau nach Spec (Zielpfeil, Kopfleiste, Linienliste-Breite, Label-Kanten) | Mira 2, Aylin 1, Sophie 1 | 4 |
| A-08 | Diagnose-Meldung mit Ein-Klick-Aktion (Ort + Ursache) im Theme | Aylin 1, Mira 1, Felix 1 | 3 |
| F-21 | Ökonomie-Pfad auf SoA vervollständigen, Spike-Lager-Fix als eigenes Ticket, 10k-Vorbereitung | Felix 4 | 4 |
| S-13 | Look: Wasser/Gelände, Industrie-Props (Kenney) für die 3 HQ-Kandidaten, HQ-Gebäude | Sophie 4 | 4 |
| SK-01 | Skilltree-Konzept v0 (D22: Spezialisierung über Skilltree), Paper, kein Bau | Lena 2, Tobias 1 | 3 |
| D-08 | Abnahmen, Regression erweitern (Platzierung, HUD), Zielrechner-Messlauf sobald Basti die .exe startet | Daniel 5 | 5 |
| J-09 | R1-Feedback von Basti einarbeiten, R2-Scope (Firmenkauf/Profile) | Jonas 2 | 2 |
| K-10 | Rollenbedarf R2 prüfen (Tech-Art? Audio?), Mira auf volle Kapazität | Katrin 1 | 1 |
Summe über Kapazität bei Mira und Sophie. Streichen/schieben ist ausdrücklich erwünscht.
