# Sprint 7 Backlog (02.–13.02.2027), PO Jonas Weber

**Sprintziel:** Am 13.02. startet Basti mit `--welt=s7` eine neue Karte im echten Maßstab (1 Feld = 25 m, 12,8 km spielbar plus 7,5 km Landschaftsrand, Haus 12×9 m, Straße 7,5/12 m, Kamera 40 m–5,6 km ohne Himmelskante an allen 4 Ecken). Die Karte hat Gebirge, durchgehenden Fluss, Täler und Hügel (Höhenspanne ≥ 900 m), Städte breiten sich als Cluster mit Rand und Bahnhof aus (Kleinstadt Radius 450 m ±15 %, ≥ 400 Gebäude), und ≥ 20 Industrien sind nach Lage-Regeln verteilt (Validator 0 Verstöße, 20 Seeds reproduzierbar, keine Stadt-Spezialisierung). Z-01 ist auf beiden Karten behoben, der Mehl-Kredit-Exploit ist geschlossen, und die Slice-Regression bleibt 13/13 grün (plus 3 neue S7-Suiten).
**Stretch (nur aus Puffer, nur nach Feature-Freeze Tag 8):** Gleis-Parallelversatz 5 m im Rendering (Felix 0,5), Baum-Impostor für die Übersicht (Sophie 1), A-08-Ortsangabe im Bankrott-Toast (Mira 0,5).

Bastis Feedback ist der Kern dieses Sprints: Maßstab, Terrain, Rand, Städte, Straßen und Industrie-Lage-Logik. Firmenkauf rutscht nach S8 und bleibt in R2. Alle FPS- und Ladezeit-Zahlen sind Sandbox-Proxy. Am Zielrechner misst Basti (D16), bis dahin gilt "mit Auflage Zielrechner".

**Architektur (Felix) angenommen:** Die neue Welt kommt als zweite Karte hinter `--welt=s7`, neuer Code liegt in `world/`, und main.gd bekommt nur Hooks. Die Sim rechnet weiter in Feldern (`feld_mm` bleibt 1000, neu ist `m_pro_feld = 25` nur für Render und Texte). Die Heightmap wird offline gebacken (16-bit-PNG 513² plus Rand). Begründung: Das ist reversibel, der Slice bleibt Default und spielbar, Bench und Parität bleiben unberührt, und über Nacht passiert nichts Irreversibles. **Den Default wechselt in S7 niemand**, auch bei grünen Suiten nicht. Das entscheidet Basti nach seinem Test (Frage 2).

| ID | Ticket | Owner | T | Akzeptanz | Folge |
|---|---|---|---|---|---|
| W-01 | Maßstab: Schalter `--welt=s7`, `m_pro_feld = 25`, Kamera-Klemme 40 m–5,6 km, km-Texte, `diagnostics.FELD_MM` angleichen, Maßtabelle SP-03 in Szene | Felix 1,5, Sophie 0,5, Tobias 0,5 | 2,5 | Block A. Slice ohne Schalter bitgleich (md5, Parität 10/10, 13/13). Im Spiel gemessen: Haus 12×9 m ±20 %, Stadtstraße 12 m, Landstraße 7,5 m. Mühle→Mittelfurt zeigt 3,15 km | Tempo-Tuning nur nach Bastis Urteil (S8, vehicles.json) |
| W-06 | Generator minimal: `tools/world_gen.py` (Seed + Regeln → Heightmap, Flussmaske, `world_s7.json` im alten Schema) plus Validator als Regressionsschritt | Felix 2, Tobias 1 | 3 | Block B. Gleicher Seed = identische Dateien (md5). 20 Seeds: 0 unlösbare Karten, 0 Regelverstöße. Validator prüft Ketten-Luftlinien in den heutigen Bändern, Gelände je Industrie, Fluss ≤ 8 Felder überbrückbar, Nische 25 | Editor/Kartenwerkzeug → TEAM-02 in S8 |
| W-02 | Terrain: Heightmap-Chunks (WorkerThreadPool), Höhe minimal in der Sim (`hoehe[idx]`, Steigung → Baukostenfaktor, Sperre "zu steil" mit Text), `terrain_at` aus Steigung und Flussmaske, Fahrzeughöhe je Feld vorberechnet; Look: Material, Fluss als Rinne, Randlandschaft mit Gebirgsring | Felix 2,5, Sophie 2,5 | 5 | Block B–C. Höhenspanne ≥ 900 m, ≥ 1 Gebirge, 1 Fluss durchgehend, Hügel in der Fläche. Städte und Industrien auf Plateau < 3 %. Max-Zoom an 4 Ecken: 0 Himmel/Kante. Naht im Shot `rand_max_ost` unauffällig. Ladezeit ≤ 6 s Sandbox (Zielrechner ≤ 3 s mit Auflage). Kein Steigungstempo | Tunnel, Brückenpfeiler, Uferverfeinerung S8 |
| W-03 | Städte: Generator mit Straßenraster, ausfransendem Rand an Ausfallstraßen, Bahnhof am Rand, 3 Stufen (Dorf/Kleinstadt/Stadt), Palette-Shader, Baum-Deckel; Radien je Stufe als Daten | Sophie 3, Lena 0,5 | 3,5 | Block C. Kleinstadt Radius 450 m ±15 %, Ausfransung +300–700 m, ≥ 400 Gebäude, 3 Gebäudetypen Kern/Mitte/Rand. Leerfläche in Blöcken < 50 %. Bäume ≤ 60 % der Dreiecke. Nachfrageformel unverändert (Test) | Großstadt, Hinterhöfe, LOD S8 |
| Z-01 | Stadtanschluss: Drag auf Stadtfläche dockt am Randfeld an, Anschlusspunkt sichtbar, beide Richtungen | Mira 1, Aylin 0,5 | 1,5 | Block A, beide Karten. Neuer Test "Straße endet auf Stadt" in beiden Richtungen grün. Aylins Session-Route (letztes Ziel) per play.sh durchspielbar | – |
| W-04 | Straßen/Gleise neu (nur S7-Welt): schmale Kenney-Kacheln mit Autotile für Kurven, Kreuzungen und T-Stöße, Brücke über Fluss, Bau-Vorschau mit Preis und roter Fehlstelle | Mira 2,5, Felix 1, Sophie 1, Aylin 0,5 | 5 | Block B. Kreuzung/Kurve ohne Lücke und ohne Boxstoß. In der 700-m-Ansicht Straße : Block ≤ 1 : 5. Vorschau zeigt Preis inkl. Steigungsfaktor. Jede Ablehnung mit Ursache | Spline-Band, Knickpfad, Auto-Brücke S8 |
| W-05 | Industrie-Lage-Logik: Lenas Regeln 1–8 als Daten (`rules_s7.json`), im Generator umgesetzt, Karte einfrieren Tag 7; Lesbarkeit mit Signalfläche + Icon + Name | Lena 2, Tobias 2, Mira 1, Aylin 1 | 6 | Block A (Regeln) bis C (Freeze). Je Typ 3–6 Instanzen, ≥ 20 gesamt. Gleicher Typ ≥ 4 km Abstand, kein Typ-Cluster > 2 in 5 km. Jede Stadt hat 2 verschiedene Zulieferer-Typen in 6 km, nie alle (Gini je Stadt < 0,5). Alle Ketten in den heutigen Distanzbändern. Lesbarkeitstest: 5 Personen nennen aus 4 km 5/5 Industrien in < 10 s | Holz/Sägewerk später |
| T-15 | Balance klein (Slice + S7): Mehl-Exploit mit Kredit schließen, Zins, Zug : Lkw, Wagnis-Vorschau korrekt | Tobias 2,5 | 2,5 | Block A–B. Proxy-M7 Kohlberg 30–40 min auch über den Mehlast mit 4× Kredit. Zug : Lkw je Strecke ≤ 3 : 1. Bankrott 10–30 % (300 Läufe je Standort). Steinbach-Vorschau warnt passend zum Messwert | Neu prüfen, falls Basti Tempo ändern lässt |
| T-16 | Bankrott-Bot kalibrieren (offen aus S6) | Tobias 1 | 1 | Block B. Bot-Quote gegen 300 echte Modellläufe ±5 Pp, d08_bankrott grün | – |
| B-xx | Kleinbugs Session: Ring-Klick auf Industrie startet kein Umsetzen, Ziel hakt nur beim richtigen Objekt ab (Haberau, Kohlberg), Toast bei Lizenzverlängerung, "-0 $" | Mira 1,5, Aylin 0,5 | 2 | Block A. 4 Bugs je mit Regressionstest, Abnahme Aylin | – |
| U-03 | Fehlertexte nie stumm (Bau-, Brücken- und Stadtfehler mit Ursache + Lösung nach Aylins Liste), Bankrott-Vorwarnung mit Ursache (nur Text), Linienliste scrollt, Kopfleiste ohne Abschneiden, "Ertrag/Monat" und "oben links" raus | Aylin 2, Mira 1 | 3 | Block B–C. 0 stumme Ablehnungen im play.sh-Durchlauf aller Bau-Fehlerfälle. Vorwarnung ≥ 60 s vor Bankrott mit größtem Verlustposten. Kopfleiste bei 1600 px ohne Clipping. Jede sichtbare Zahl mit Test gegen den Spielwert (Retro S6) | A-08 Diagnose-Toast S8 |
| G-01 | Progression nach M7, nur Konzept: Etappenziele bis 60 min, Druck über Stadtwachstum und Nachfrageverfall, Lizenzpreis, Gleisunterhalt; Skillpunkte aus Etappen | Lena 2 | 2 | Block B–C. Eine Seite: ≥ 6 Fernziele mit Minute und Messgröße, Leerlauf-Regel "keine 3 min ohne Entscheidung" mit Beispielen. Kein Bau | Bau S8 zusammen mit SK-02 |
| L-14 | Aufgabenkarten für Bastis Rundgang durch die neue Welt (Zoom-Rundgang, erste Straße auf Stadt, Industrie-Lage lesen) | Lena 1, Aylin 0,5 | 1,5 | Block D. 4–5 Karten im Ton von L-13, verweisen auf `--welt=s7` und den Bench-Preset | Review |
| D-09 | Regression erweitern: Suiten `s7_boot`, `s7_validator`, `perf_s7` (6 SP-03-Kameras × 2 Karten × 0/5.000 Lkw → CSV), play.sh T-01/T-02/T-06 (Umsetzen bestätigen, speed wirkt auf wait, Läufe ≤ 120 s), Abnahmen, Screenshots je Block | Daniel 7 | 7 | Nach jedem Block 13/13 Slice + alle bis dahin vorhandenen S7-Suiten grün. Perf-Gate S7-Welt: Übersicht ≤ 1,0 M Dreiecke, Draw Calls ≤ 300, Stadt nah ≤ 2,9 M (Ziel 1,8 M erst mit LOD in S8), +10 % = rot. Slice-Budget unverändert. FPS nur Basti mit bench.gd | Gate Default-Wechsel |
| J-10 | Review, Zusammenfassung für Basti am Morgen, Backlog S8 (F-22, SK-02, LOD) | Jonas 1,5 | 1,5 | Zusammenfassung ≤ 1 Seite mit Screenshot-Set und Startbefehl | – |
| K-11 | TEAM-02 Rollenprofil und Onboarding-Paket für den Start in S8 | Katrin 1 | 1 | Eine Seite: Auftrag, Schnittstellen zu Sophie und Felix, Übergabe Bake/Generator | Start S8 |

## Arbeitsblöcke (nach jedem Block: Merge, Regression, Push)

**Block A (Tag 1–2) – Schalter und Quick Wins, Slice zuerst**
- Felix: W-01 Schalter `--welt=s7`, Gerüst `world/`, `m_pro_feld`, Kamera-Klemme. Die S7-Welt bootet als flache 512²-Ebene.
- Mira: Z-01 (beide Karten), B-xx.
- Aylin: Fehlertext-Liste final (Grundlage für U-03 und W-04), Abnahme Z-01/B-xx.
- Tobias: T-15 Mehl-Exploit und Zins auf dem Slice.
- Lena: `rules_s7.json` (Regeln 1–8) bis Ende Tag 2, Radien je Stufe.
- Sophie: Maßtabelle in Szene, Kenney-Kacheln schmal vorbereiten, Terrain-Material.
- Daniel: Perf-Baseline Slice, play.sh-Fixes, Suite `s7_boot`.
- **Merge-Gate:** 13/13 + `s7_boot` grün. Spieler-Nutzen sofort im Default-Slice (Z-01, Bugs, Exploit).

**Block B (Tag 3–5) – Terrain und Generator** (braucht A: Schalter, Regeln)
- Felix + Tobias: W-06 world_gen + Validator, W-02 Höhe in der Sim, Chunks.
- Sophie: Heightmap-Look, Fluss-Rinne, Randlandschaft. Shots an Daniel ab Tag 4.
- Mira: W-04 Kacheln/Autotile + Bau-Vorschau auf der S7-Welt, U-03-Texte (beide Karten).
- Tobias: T-15 Zug : Lkw, Wagnis-Vorschau, T-16.
- Lena: G-01-Konzept.
- Daniel: Suite `s7_validator` (20 Seeds), Smoke "Straße bauen am Hang/über Fluss".
- **Merge-Gate:** S7-Karte mit Terrain lädt ≤ 6 s Sandbox, Validator Exit 0, 13/13 + 2 S7-Suiten grün.

**Block C (Tag 6–8) – Städte, Industrien, Lesbarkeit** (braucht B: Heightmap, Plateaus, Trassen)
- Sophie: W-03 Städte (3 Stufen), Baum-Deckel.
- Lena + Tobias: W-05 Verteilung auf der echten Heightmap feinjustieren, **Karten-Freeze Ende Tag 7**.
- Mira: Industrie-Icons/Labels (gegen Platzhalter ab Tag 6, echte Positionen ab Tag 7), U-03-Rest.
- Felix: Ladezeit/Threads, Fahrzeughöhe je Feld, Stretch nur aus Puffer.
- Aylin: Industrie-Signalflächen abnehmen, Lesbarkeitstest vorbereiten.
- Daniel: `perf_s7` als Gate.
- **Feature-Freeze Ende Tag 8. Merge-Gate:** alle 16 Suiten grün, Perf-Gate S7 hält. Hält es nicht, wird nach Reihenfolge gekürzt: Baumzahl, Randdetail, Stadtgröße Stufe "Stadt". Industrien und Lesbarkeit bleiben.

**Block D (Tag 9–10) – Abnahme**
- Daniel: Abnahme-Lauf, Screenshot-Set an den SP-03-Standorten, Lesbarkeitstest (5 Personen).
- Aylin: Look- und Text-Abnahme. Lena + Aylin: L-14.
- Alle: Bugfix nur aus der Abnahme.
- Jonas: J-10. Katrin: K-11.
- **Ende:** Slice bleibt Default, `--welt=s7` ist opt-in. 16/16 grün, Push.

## Geschoben
- **F-22 Firmenkauf → S8** (bleibt R2, wie Basti entschieden hat). Firmenpreise brauchen die neuen Industrien, sonst kalibrieren wir auf Wegwerfwerte.
- **SK-02 Skilltree-Bau → S8**, zusammen mit dem G-01-Bau. Die Punktequelle ist entschieden (s. u.).
- A-08 Diagnose-Toast → S8. Die Bankrott-Ursache deckt U-03 als Text ab.
- Spline-Band, Mehrgleisigkeit je Feld, Gleis-Parallelversatz (außer Stretch), Tunnel, Brückenpfeiler, Uferverfeinerung → S8+.
- LOD, Kartenwerkzeug/Editor → S8 mit TEAM-02.
- Großstadt-Stufe, Hinterhöfe → S8.
- Größenfaktor Lizenz (A2), neuer Zielrechner-Bench → Basti exportiert, wenn er Zeit hat (Preset unverändert, zusätzlich mit `--welt=s7`).
- Aufteilung main.gd → R2-Ticket, in S7 nur Hooks.

## Gestrichen
- Reale Tempo- und Distanz-Umrechnung der Ökonomie (Spielzeit bleibt gestaucht wie bei RE).
- Steigungsabhängiges Fahrzeugtempo.
- "Eigene Kette je Stadt" als Kartenprinzip und die Validator-Regel "keine Startstadt ohne Kette". Ersetzt durch Regel 8: 2 Zulieferer-Typen in 6 km.
- Transport-XP als Skillpunkt-Quelle.
- Spline-Trassen in S7 (Tech-Vorschlag). Statt dessen Kenney-Kacheln, wie Basti es nahelegt.

## Streitprotokoll
- **Höhe in der Sim (Felix/Sophie ja, Lena/Tobias nein):** Felix, minimal. In der Sim gibt es nur Steigung → Baukostenfaktor und eine Sperre "zu steil" mit Text, kein Steigungstempo und keine Tunnel. Begründung: Terrain ohne Folge wäre Tapete und widerspricht D15 (TF2/RE). Lenas Doppel-Balance-Sorge entfällt weitgehend: Ohne Steigungstempo bleibt die Fahrzeit je Feld gleich, Industrien und Städte stehen auf Plateaus, und der Validator hält die Ketten in den heutigen Bändern. Der Slice hat keine Höhe und bleibt bitgleich.
- **Mehrgleisigkeit (Sophie in der Sim, Technik nur Render):** Technik. 1 Trasse pro Feld in S7. Ein Netzmodell-Umbau sprengt den Sprint und gefährdet die Parität. 5-m-Versatz im Rendering nur als Stretch, echte Mehrgleisigkeit S8+ mit eigenem Spike.
- **Tempo-Umrechnung (Sophie/Tobias real, Technik/Design nicht):** Nicht umrechnen. Die Sim bleibt in Feldern, die Fahrzeit je Feld bleibt, die Spielzeit ist gestaucht wie bei RE. Aylins Einwand "Distanzen ×2,5, Balance doppelt" greift deshalb nicht: In Feldern ändert sich nichts. Wirkt es auf Basti zu schnell, folgt ein Tuning-Ticket in S8 (vehicles.json, d08 neu). Frage 1.
- **G-01 (Lena rein, Aylin/Sophie nach S8):** Lena, nur Papier, 2 T. Das Konzept bindet weder Mira noch Sophie und blockiert Z-01 nicht, Z-01 kommt ohnehin in Block A. Ohne Konzept startet S8 wieder leer, und die Session-Diagnose "nach 13 min nichts mehr zu tun" ist der größte Spielbefund.
- **T-15 (Tobias rein, Aylin/Sophie nur Exploit):** Tobias, klein (2,5 T). Exploit und Zins zuerst (Block A), Zug : Lkw und Wagnis-Vorschau in Block B. Neu gerechnete Distanzen gibt es nicht (s. Tempo), also ist das keine Doppelarbeit. Zug : Lkw ≤ 3 : 1 statt heute ~11 : 1 gehört zur Genre-Erwartung (D15).
- **TEAM-02:** siehe eigener Abschnitt. Ja, ab S8.
- **Firmenkauf (Basti ja für R2; Design, Technik, UX S8):** S8. Bastis Ja gilt für R2, nicht für S7. Mira und Felix sind voll, und die Firmenpreise hängen an den neuen Industrien. Kein Konflikt mit dem Auftraggeber, im Zweifel Frage 3.
- **Skilltree-Punktequelle (Lena Meilensteine + XP, Tobias nur Meilensteine):** Tobias in der Quelle, Lena im Ziel. Punkte kommen aus Meilensteinen und aus den G-01-Etappenzielen bis 60 min, keine Tonnenkilometer-XP. Das gibt Dauerspiel Fortschritt ohne Lkw-Masse-Exploit (E4). Gedeckelte XP sind schwerer zu erklären (D21) als "Etappe geschafft = Punkt".
- **Regression umstellen vs. erweitern (Daniel umstellen, Technik erweitern):** Erweitern. Der Slice bleibt Default, also bleibt seine Suite das Netz (13/13). Dazu kommen 3 S7-Suiten. d08_bankrott/lizenzfaktor laufen in S7 nur auf dem Slice. Umgestellt wird erst mit dem Default-Wechsel.
- **Industrie-Lesbarkeit (Sophie/Aylin Fläche + Icon, Design nur Icons):** Fläche + Icon. Bastis Referenz RE zeigt: Die Felder tragen die Lesbarkeit, Icons ergänzen, und Icons allein lassen die Welt wieder wie ein Brettspiel wirken. Lenas Flächen-Sorge wird so gelöst: Der blockierende Kern bleibt der heutige Sim-Footprint (≤ 150 m), Felder und Halden bis 300 m sind nicht blockierende Bodentextur. Icon + Name ab 2 km Kamerahöhe. Abnahme über den 5/5-Test.
- **W-03 Städte (Design raus, Technik 1 Stadt, UX Generator):** UX, Generator mit 3 Stufen. "Städte zu kompakt" ist Bastis Kernpunkt 5, ohne Städte bleibt die Miniatur-Wirkung. Großstadt und LOD S8.
- **W-04 Spline vs. Kacheln (Technik Spline, Sophie Kacheln, Aylin Vorschau):** Sophie und Aylin. Kenney-Kacheln schmal mit Autotile, wie Basti es vorschlägt. Die Bau-Vorschau mit Preis und Fehlstelle ist Pflicht (D21). Das Spline-Band kommt S8, falls Kacheln am Hang zackig wirken.
- **Perf vor Look (Technik 1,8 M, Art 2,9 M bis LOD):** Art für S7, mit Deckel. Stadt nah ≤ 2,9 M, Bäume ≤ 60 %, Übersicht ≤ 1,0 M als hartes Gate. 1,8 M wird mit LOD in S8 Pflicht. Ladezeit ist durch den Offline-Bake nicht verhandelbar (≤ 6 s Sandbox).
- **Default-Wechsel (Technik: wenn alles grün):** Nein in S7. Das wäre die einzige schwer umkehrbare Nachtentscheidung. Basti entscheidet nach eigenem Test (D16).

## TEAM-02 Technical Artist / Level Designer: Entscheid
**Ja, Start mit S8 (16.02.).** Katrin schreibt in S7 das Profil (K-11), in S7 kommt niemand dazu.
Begründung: Gestaffelt wie im echten Studio kommt der Tech-Art dann, wenn eine Pipeline existiert, die gepflegt werden muss. Die entsteht genau in S7: Heightmap-Bake, world_gen, Validator, Baum-Deckel. In S6 haben wir die Rolle zu Recht abgelehnt, weil es nur Kenney-Props waren. Jetzt liegen ~14 PT Terrain-, LOD- und Kartenarbeit (SP-03) auf Sophie, die bei 7 T steht und Städte, Straßen und Look tragen muss. Felix fängt das nicht ab, er ist Sim- und Engine-Engpass. Nicht schon in S7, weil ein neuer Kopf ohne Einarbeitung in einem Nacht-Sprint mehr kostet, als er bringt (Aylins Punkt). Auftrag ab S8: LOD, Bake-Pipeline, Kartenwerkzeug. Sophie bleibt bei Look, Städten und Stil.

## Kapazität (T)

| Person | Kapazität | Plan | Puffer | Belegung |
|---|---|---|---|---|
| Felix | 8 | 7 | 1 | W-01 1,5, W-06 2, W-02 2,5, W-04 1 |
| Mira | 8 | 7 | 1 | Z-01 1, B-xx 1,5, W-04 2,5, W-05 1, U-03 1 |
| Sophie | 8 | 7 | 1 | W-01 0,5, W-02 2,5, W-03 3, W-04 1 |
| Tobias | 8 | 7 | 1 | W-01 0,5, W-06 1, W-05 2, T-15 2,5, T-16 1 |
| Lena | 8 | 5,5 | 2,5 | W-05 2, W-03 0,5, G-01 2, L-14 1 |
| Aylin | 8 | 5,5 | 2,5 | Z-01 0,5, W-04 0,5, W-05 1, U-03 2, B-xx 0,5, L-14 0,5, Look-Abnahme 0,5 |
| Daniel | 8 | 7 | 1 | D-09 7 |
| Jonas | 8 | 1,5 | 6,5 | J-10 1,5 |
| Katrin | 8 | 1 | 7 | K-11 1 |

Engpässe sind Felix, Mira, Sophie und Tobias mit je 1 T Puffer. Aylins und Lenas Puffer gehen zuerst in Z-01-Nacharbeit, Fehlertexte und den Lesbarkeitstest, nicht in neue Features.

## Fragen an Basti (morgen früh)
1. **Fahrzeuge wirken in der neuen Welt schneller als real (Spielzeit gestaucht wie bei Railway Empire). Ist das ok?** Empfehlung: ja, erst selbst spielen (`--welt=s7`, Karte L-14). Wenn es dich stört, stimmt Tobias in S8 nur das Tempo in vehicles.json, die Ökonomie bleibt.
2. **Soll die neue Welt nach deinem Test Default werden und der alte Slice eingefroren?** Empfehlung: ja, ab S8, wenn dein Bench-Lauf mit `--welt=s7` die Übersicht ≥ 60 FPS hält. Bis dahin bleibt der Slice Default.
3. **Firmenkauf in S8 statt S7 und TEAM-02 (Tech-Art/Level Design) ab S8: einverstanden?** Empfehlung: ja. Die Firmenpreise brauchen die neuen Industrien, und ohne die Rolle bleibt Sophie der Engpass für Terrain, LOD und Kartenwerkzeug.
