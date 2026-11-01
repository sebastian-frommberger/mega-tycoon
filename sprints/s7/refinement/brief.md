# Refinement Sprint 7 (02.–13.02.2027) – Briefing

Release R2 "Eigener Start und Firmenaufbau" läuft. Sprint 6 hat den D22-Start geliefert (HQ frei platzieren, Vorschau, 6.000 $, Regression 13/13 grün). Danach: Basti hat selbst draufgeschaut, und das Team hat eine interne Zocker-Session gespielt. Der Sprint wird **über Nacht ohne Basti** abgearbeitet (er schläft); Entscheidungen trifft Jonas, nichts Irreversibles.

## Pflichtlektüre
- Bastis Feedback (Auftraggeber, hat Vorrang): /home/claude/mega-tycoon/sprints/s7/basti_feedback_01-11.md – Proportionen/Miniatur-Wirkung, Straßen sehen schlecht aus, Städte zu kompakt (Railway Empire als Stilreferenz: design/art/referenz/), echter Maßstab wie TF2/RE, Kartenrand wie TF2 (Landschaft hinter der spielbaren Fläche, Kamera-Grenze), Terrain mit Bergen/Flüssen/Tälern/Hügeln, **Industrien nicht pro Stadt spezialisiert ("Weizenstadt/Bergbaustadt"), sondern verteilt wie TF2 (Distanzen wie TF2 gut), aber mit nachvollziehbarer Lage-Logik statt Zufall**. Ring-Bug ist behoben.
- Spike SP-03 (Sophie): /home/claude/mega-tycoon/sprints/s6/zocken/sophie_sp03.md, Bilder spikes/s7-scale-terrain/shots/ – Vorschlag 1 Feld = 25 m, 512² = 12,8 km spielbar + 7,5 km Rand, Straßen 7,5/12 m, Stadtradien 200 m–1,3 km, Kamera 40 m–5,6 km; Heightmap-Terrain; Aufwand ~14 PT Sophie + ~4 PT Felix + Sim-Umrechnung; Befund: Industrien im echten Maßstab aus der Übersicht kaum sichtbar (Fläche 150–300 m oder Icons); Performance: 2,9 M Dreiecke Stadt nah, Bäume 78 %, LOD nötig, Heightmap vorbacken. Prototyp-Code: slice/spikes_s7/.
- Zocker-Session (Spieltagebücher): /home/claude/mega-tycoon/sprints/s6/zocken/tagebuch_{lena,tobias,aylin,daniel}.md. Kernfunde:
  - **Stadtanschluss kaputt:** Straße, die auf einer Stadt endet, wird abgelehnt ("Gebäude im Weg"), nur Gegenrichtung geht (Z-01, von 3 Spielern gefunden); Aylin kam deshalb nicht ans letzte Ziel. Brücken nur gerade, Fehlermeldungen teils stumm.
  - **Progression:** Alle Ziele nach 5–13 min erledigt, danach keine Entscheidungen, keine Fernziele, kein Druck (Lena: "noch nicht weiterspielen"). Steinbach (Wagnis) ist zu leicht, Vorschau warnt falsch.
  - **Balance:** Zug +1.091 $/min vs. Lkw +100 $/min auf ähnlicher Strecke; Exploit Mittelfurt-Mehlkette + 4× Kredit → M7-Proxy 20 statt 33–36 min; Kredit-Zins 1 %/min zu billig?; Bankrott ohne Vorwarnung und ohne Ursache.
  - **Kleinbugs:** Klick auf Industrie auf dem HQ-Ring startet Umsetzen (2 min), Ziele haken mit falscher Industrie ab (Haberau Farm 1/2, Kohlberg "jede erste Lkw-Linie"), Lizenzverlängerung ohne Toast, "Ertrag/Monat" irreführend, Linienliste ohne Scroll, Kopfleiste rechts abgeschnitten (Lena), "Tempo oben links" falsch, "-0 $".
  - Werkzeug-Mängel (play.sh): kein Befehl für Umsetzen-Bestätigung, speed wirkt nicht auf wait, Läufe > 120 s.
- Offen aus S6: Firmenkauf (Basti: ja, R2), Skilltree-Punktequelle (Lena: auch Transport-XP; Tobias: nur Meilensteine), A-08 Diagnose, Größenfaktor Lizenz (A2), Bankrott-Bot kalibrieren, neuer Zielrechner-Bench (Basti, wenn Zeit).
- S6-Review/Retro: /home/claude/mega-tycoon/sprints/s6/review_retro.md. Backlog-Format: /tmp/claude-0/gd/sprint6/refinement/ergebnis.md.

## Rahmen
- Grundregeln: D15 Genre-Standards (TF2, Railway Empire, OpenTTD), D16 Basti testet selbst, D21 UI mit Liebe, D22 HQ frei platzieren. Neu aus Feedback: Weltmaßstab und Industrie-Lage-Logik sind Auftraggeber-Vorgaben.
- D22 und die neue Industrie-Verteilung passen zusammen: Die Vorschau zeigt Lage (welche Industrien in welcher Distanz), keine "eigene Kette" je Stadt.
- Kapazität je Person 8 T, Mira jetzt 8 T. Es ist zu viel Arbeit für einen Sprint: Schneiden, priorisieren, in Etappen denken (z. B. S7 Fundament Maßstab/Terrain/Karte, S8 Firmenkauf). Neue Rolle nur mit Begründung (Leitlinie: Rollen gestaffelt wie im echten Leben) – Kandidat **TEAM-02 Technical Artist / Level Designer** (Terrain, LOD, Kartenbau-Werkzeug), Katrin prüft.
- Arbeitsweise über Nacht: Blöcke mit Merge, Regression, Push nach jedem Block. Spielcode der neuen Welt darf den bestehenden Slice nicht unspielbar zurücklassen: entweder Umbau hinter einem Schalter/neuer Karte oder komplett mit grüner Regression.

## Kandidaten (Owner, Tage grob)
| ID | Ticket | Owner | T |
|---|---|---|---|
| W-01 | Maßstab festlegen und umsetzen (25 m/Feld o. ä.): feld_mm, Fahrzeug-Tempo, Distanzen, Kamera-Grenzen; Sim-Parität | Felix 3, Tobias 1, Sophie 1 | 5 |
| W-02 | Terrain: vorgebackene Heightmap (Berge, Hügel, Täler, Fluss), Höhe in der Sim (Baukosten/Steigung minimal), Kartenrand-Landschaft + Kamera-Grenze | Felix 3, Sophie 3 | 6 |
| W-03 | Städte neu: Straßenraster aus City Kit, lockerer Rand, Bahnhof, Stadtradien je Stufe, LOD | Sophie 4, Mira 1 | 5 |
| W-04 | Straßen/Gleise neu: schmal, Kenney-Roads, Kurven/Kreuzungen, Brücken; Stadtanschluss reparieren (Z-01) | Mira 3, Felix 1, Sophie 1 | 5 |
| W-05 | Industrie-Lage-Logik (Regeln: Farm Ebene/Aue, Mine Gebirgsfuß, Mühle Fluss/Stadtrand …), Distanzen wie TF2, neue Karte erzeugen; Industrien sichtbar (Fläche/Icons) | Lena 2, Tobias 2, Sophie 1 | 5 |
| W-06 | Kartengenerator/Kartenwerkzeug (aus Regeln + Heightmap reproduzierbar erzeugen), Validator/Checks | Felix 2, Tobias 1 | 3 |
| T-15 | Balancing nach Session: Zug vs. Lkw, Mehl-Exploit + Kredit, Zins, Wagnis-Vorschau | Tobias 3 | 3 |
| G-01 | Progression nach M7: Fernziele/Meilensteine bis 60 min, Druck (z. B. Stadtwachstum, Konkurrenz light?) – Konzept | Lena 2 | 2 |
| U-03 | Fehlertexte mit Lösung (nie stumm), Bankrott-Vorwarnung mit Ursache, Linienliste scroll, Kopfleiste, Texte aus Aylins Liste | Aylin 2, Mira 2 | 4 |
| B-xx | Kleinbugs aus der Session (Ring-Klick auf Industrie, Ziel-Abhaken, Toast Verlängerung, -0 $) | Mira 1,5 | 1,5 |
| F-22 | Firmenkauf (R2) | Mira 3, Felix 1, Tobias 1, Aylin 1 | 6 |
| SK-02 | Skilltree: Entscheid Punktequelle + Bau v1 (Anzeige, 3 Äste) | Lena 1, Mira 3, Tobias 1 | 5 |
| A-08 | Diagnose-Toast (Ort + Ursache + 1 Aktion) | Aylin 1, Mira 1, Felix 1 | 3 |
| D-09 | Abnahme, Regression auf neue Welt umstellen, Perf-Budget (Dreiecke/Draw Calls), play.sh-Mängel | Daniel 6 | 6 |
| J-10/K-11 | Review, Retro, Zusammenfassung für Basti am Morgen; Rollenprüfung TEAM-02 | Jonas 1,5, Katrin 1 | 2,5 |
Summe weit über Kapazität (Sophie, Mira, Felix). Schneiden ist Pflicht.
