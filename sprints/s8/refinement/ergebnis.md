# Sprint 8 Backlog (15 Arbeitstage, Annahme), PO Jonas Weber

Stand 05.11.2026, Repo HEAD dc14304, nur gelesen. Quellen: `brief.md`, `design.md`, `tech.md`, `ux_art.md` (alle `/tmp/claude-0/gd/s8ref/`), Entwurf `sprints/s8/planung/loop_s8_2026-11-04.md` („Entwurf“), `sprints/s8/feedback_03-11/basti_feedback_03-11.md`, Format `sprints/s7/refinement/ergebnis.md`, `sprints/s7/review_retro.md`. Marken: [M] im Code/Repo nachgesehen, [R] aus Repo-Zahlen gerechnet, [E] Einzelschätzung. **Kein Godot-Lauf.** Alle Minuten, Umläufe und €/min sind gerechnet, nicht gemessen.

**Schätzregel:** Wo die Beiträge auseinanderliegen, gilt die **höhere Gesamtzahl** mit deren Aufteilung. Das ist in der Spalte „Owner T“ mit „hoch: …“ vermerkt. Kürzungen kommen nur über **Umfang**, nie über eine niedrigere Zahl für denselben Umfang.

**Kapazitätsregel (neu gegenüber S7):** 12 T in 15 Tagen sind 0,8 T je Arbeitstag. Feature-Arbeit muss bis zum Freeze Ende Tag 12 fertig sein. **Bis zum Freeze stehen also 9,6 T je Person zur Verfügung**, Block D (2,4 T) ist Abnahme, Bugfix und Puffer. S7 hat nur gegen die Gesamtkapazität geplant (Felix 7 T bei 6,4 T bis zum Freeze), und die Retro sagt: zu optimistisch.

**Eigene Stichproben [M]:** Mühlendeckel Stufe 1 (`economy.gd` Z. 450, Kommentar „ANNAHME Stufe 1“); ProtoSim-Tempo aus dem Easing-Profil (`proto_sim.gd` Z. 306); `regelwerk.json` Z. 3651 `gleis_ab_jahr` 1835; `tests/proto_sim_test.gd` Z. 63 prüft fest `spd == 600`; 0 Treffer „proto_“ in `tests/d07_regression.sh`; `~/.local/share/godot/export_templates` ist leer; `cash_cent ±=` außerhalb economy/credit: `main.gd` Z. 2714, 2783, 3106 und `proto_sim.gd` Z. 433; die HUD-Zeile „Gelände: %s“ gibt es (`prototyp_welt.gd` Z. 562). **Lücke im Tech-Beitrag:** Die Messwerte stehen als Platzhalter `__REG__`, `__PROTO__` und `__PMENU__` (`tech.md` Z. 65, 67, 75). Regressionslaufzeit, Laufzeit der Proto-Suiten und P-Menü-Absturz sind damit **nicht gemessen**.

---

## 1 Sprintziel

**Sprintziel:** Am Ende von Tag 15 startet Basti die Welt über den Knopf „Welt spielen (Loop S8)“ im Startmenü und spielt 45 min am Stück. Er beginnt mit 6.000 $ ohne fertige Kette und spielt mit Fuhrwerken im gewählten Tempo k (D2): Lizenz kaufen, eigene Linien Farm → Mühle → Erlenbach/Lindenfurt anlegen, Fuhrwerke kaufen, verkaufen und mit Restwert ersetzen. Er sieht die Alterung im Unterhalt (Kalender 3 min/Jahr), nimmt ab Minute 12 Kredit, bekommt bei Kasse < 0 eine Vorwarnung und dann den Bankrott, arbeitet die Ziele E-1 bis E-6 sowie F1 und F2 ab, sieht die Sättigung in Panel und Linienliste, bekommt A-08-Diagnosen mit Ort, Ursache und Aktion und kann die Mühle kaufen und auf 40 E/min ausbauen (C1). **Messbar:** Der Loop-Bot (n = 300, Wilson-Intervall) zeigt Bankrott bei naivem Spiel 10–30 %, bei Planspiel ≤ 5 %, eine Ereignislücke P90 ≤ 3 min von Minute 2 bis 45 und den Entfernungs-Exploit X1 grün (Netto je Einheit maximal bei 40–80 Feldern, bei 150 Feldern ≤ 80 % davon). Bodentextur: Treppenmetrik ≤ 50 % der Baseline und ≤ 17 % absolut, an Bastis Stellen ≥ 80 % „besser“ und 0 „schlechter“. Relief: Leuchtdichte-Differenz zwischen Sonnen- und Schattenhang ≥ 12 %, Basti findet in L1 3 von 3 Hügeln oder Senken. Die Slice-Regression bleibt bitgleich, und der Slice bleibt Default. **Skilltree:** In Szenario (ii) sind 2 Äste mit 6 Knoten spielbar. In Szenario (i) gibt es nur Konzept v1 und Daten, keinen Bau.

**Stretch (nur aus Puffer, nur nach Feature-Freeze Ende Tag 12, eigener Branch):** (1) Windows-Build, nur wenn die Export-Templates an Tag 1 installiert sind (Felix 1, Katrin 0,25, Daniel 0,25). (2) Stichweg-Spike P3 mit Zeitbox 1 T (Felix), ohne Merge in `s8`, nur als Befund für S9. (3) D7-O1 Belebung: Leerläufer und Postkutsche als Kulisse (Felix 0,5, Stadt 0,25); Abnahme: Prüfsumme Eco mit und ohne Kulisse gleich. (4) Nur (ii): Ziel-Marker mit Pfeil, schwebendes „+x $“ und Ortsschild-Status WA-13b (N.N. 1,75, Aylin 0,75).

**Pillar-Check (`concept/jonas.md` Z. 17–23):** S8 testet Pfeiler 1 („Lesbare Komplexität“: A-08, Sättigung) und Pfeiler 5 („Druck kommt aus dem Netz“: Mühlendeckel, Sättigung, Unterhalt). **Pfeiler 2 („Bauen fühlt sich gut an“) testet S8 nicht**, weil der Stichweg fehlt (W4). Das sage ich Basti offen. Pfeiler 4 im Skilltree: Die Schlüsselknoten Frachtwagen-Patent und Mahlrecht sind neue Möglichkeiten und keine Prozentwerte.

---

## 2 Annahmen bis Basti entscheidet

Jede Annahme ist reversibel (Typ 2). Kein Ticket baut etwas, das bei einer anderen Entscheidung verloren ginge, ausgenommen die mit „hängt an“ markierten Tickets.

| # | Arbeitsannahme | Wenn Basti anders entscheidet | Delta | Frist |
|---|---|---|---|---|
| D1 | Der Loop läuft auf Welt-Prototyp + ProtoSim; der Slice bleibt Default und bitgleich | `--welt=s7` mit Fuhrwerk-Skin: Block B bis C entfallen zum großen Teil, dafür ist das Feedback zu Textur, Relief und Placement wertlos (andere Welt) | −6 T Mira, −3 T Felix; Strang D wird gegenstandslos | Tag 1 |
| D2 | Tempo k: A/B zwischen 4 und 8 in L1 (Tag 4), Schalter `--tempo_k`. Bis zu Bastis Urteil kalibriert der Bot beide Werte. Antwortet Basti nicht bis Tag 5, setzt Jonas k = 6 (25 m/s) | k = 1 und nur Zwei Uhren: AT-04 und FZ-09 werden kleiner, aber der Entfernungs-Exploit bleibt offen (`design.md` §2.3, bei k = 1 ist weiter immer besser) | −0,75 Felix, −1 TA; OE-02 X1 wird rot | Tag 5 |
| D3 | Bau: Lizenz, Linie, Halt auf dem festen Netz. **Kein Stichweg** im Sprintziel, nur als Stretch-Spike | Stichweg als Muss: P3 (Felix 2, Mira 1, Aylin 0,25). Dafür fallen FZ-05 (Folgemodell) und FK-03 (C1-UI) heraus, oder es geht nur mit (ii) | +3,25 T auf dem kritischen Pfad | Tag 3 |
| D4 | Keine zweite Kette. Der Loop trägt über 2 Farmen, Mühlenausbau und 2 Abnehmer | Zweite Kette (Neu-Einkleidung): +1,5–2,5 T Stadt/Tobias plus Art (Prefabs). Dafür fällt der Skilltree-Bau weg | +2,5 T [E] + Art | Tag 4 |
| D5 | Lebenszyklus: Kauf, Unterhalt, Alterung (+5 %/Kalenderjahr), Verkauf/Ersetzen mit Restwert, Folgemodell Frachtwagen ab 1830. Kalender 3 min/Jahr (Zwei Uhren), die Wirtschaft bleibt in Ticks. **Kein Depot, keine Ausfälle. Postkutsche nicht kaufbar** (ohne Passagiere fährt sie leer, `proto_sim.gd` Z. 416). Kauf/Wartung zeigt die „Fuhrhalterei am HQ“ als Panel-Eintrag | (a) ohne Zwei Uhren: Alterung im Test unsichtbar (3,75 Jahre in 45 min), FZ-02, FZ-05, FZ-07 und FZ-08 entfallen. (b) Depot mit Depotfahrt: Kerneingriff in `sim_world` mit Paritätsrisiko, 3–4 T, nicht in S8. (c) Kutsche mit Ertrag: Personen-Sim > 5 T, frühestens S10 | (a) −1,25 Felix, −2,25 Art; (b) +4 T; (c) > 5 T | Tag 4 |
| D6 | Bodentextur Stufe A (Übergänge, Makro, Detail, Schläge im Shader, Ufer aus Distanzfeld) mit Messskript, **≈ 6 T TA + 0,75 Sophie**, nicht 2 PT | Nur 2 PT: Messskript + A1/A4. Ursache B1/B2 (25-m-Texel, Flachfarbe) bleibt, und das ist Kosmetik (`ux_art.md` §1) | −3,75 T TA | Tag 4 |
| D7 | Keine Eigenversorgung der Orte, keine Reisenden ohne Spieler | O2 (Datenfeld Eigenversorgung + Bot-Variante): +0,25 Tobias. O3 Personen-Sim: > 5 T, S10+ | +0,25 / > 5 T | S9-Refinement |
| D-F | Firmenkauf = **C1**: Industrie kaufen (Lizenz → Besitz, 50 % der Lizenzgebühren angerechnet, Werksmarge, Unterhalt) **plus ein Werksausbau der Mühle auf Werksstufe 2 (40 E/min, 2.000 $)**. C2 (bankrotte Rivalenfirma) nur als Spezifikation und ADR | C2 bauen: Skript-Rivale + Besitzerfeld an Fahrzeugen/Lizenzen, ≈ 4 T (Tobias 1, Felix 1,5, Mira 1, Lena 0,5, `design.md` F22-2). Geht nur mit (ii) und ohne Skilltree-Bau. Eine Konkurrenzfirma als Spielfigur kostet 6–10 T und ist in S8 nicht machbar | +4 T / +6–10 T | Tag 3 |
| D-S | Skillpunkte nur aus Meilensteinen und Etappenzielen (S7-Entscheid, `s7/refinement/ergebnis.md` Z. 91), im Loop 4 Punkte (E-1, E-6, F1, F2), Respec in S8 kostenlos | Ast-XP: XP-Zähler und Respec „25 % der Ast-XP“ (`concept/lena.md` Z. 124), +1 T Felix/Tobias. Damit wäre der S7-Entscheid zurückgenommen und der Mengen-Exploit wieder offen | +1 T | Tag 3 (nur relevant für (ii)) |
| D-L | 15 Arbeitstage, 12 T je Person, Freeze Ende Tag 12 | 10 Tage: nur Loop + Bodentextur; Strang E auf Spec, Strang F auf Konzept. 20 Tage: kein Gewinn, der Engpass ist Mira/Felix, L3 käme später | – | Tag 1 |
| D-W | Binsensee auf ≤ 150 m Äquivalentdurchmesser verkleinern (Kartentyp Flusstal, Bastis Erwartungsregel 03.11. 23:38) | Nutzbarer See: Fischerei als Kette, nicht geschätzt, kostet eine Kette in Ökonomie und Art → S9 | WA-12 entfällt (−1,75 T) | Tag 5 |
| D-R | Relief zuerst über die Darstellung (Licht, Schummerung). Amplitude (RL-2) nur, wenn die Personenprobe scheitert, und dann in S9 | Amplitude sofort: TA 1,5, Stadt 0,5. Ändert Fahrlinien/Easing (E5/E6) | +2 T TA → WA-05 Ufer fällt | nach L1 |

---

## 3 Widersprüche und PO-Entscheidungen

| # | Widerspruch (Belege) | Entscheidung | Begründung | Revidierbar bis/durch |
|---|---|---|---|---|
| W1 | **Tempo-Quelle.** Laut Entwurf in `vehicles.json` `lkw_e1` (Z. 10). Design: bleibt im Regelwerk (`design.md` Z. 183). Tech: eine Quelle `fuhrwerk_e1` in `vehicles.json`, Regelwerk-Wert soll fehlen (`tech.md` Z. 47) | **Einzige Tempo-Quelle der Welt ist `regelwerk.json fahrzeug_easing.kategorien.<kat>.sim_felder_je_tick_promille`**, ÷ k aus `tempo_k`. `fuhrwerk_e1`/`frachtwagen_e1` in `vehicles.json` tragen nur Kosten, Kapazität und Lebensdauer, **kein Tempofeld**. Ein statischer Check sorgt dafür, dass kein Tempofeld in `fuhrwerk_e1`/`frachtwagen_e1` steht | ProtoSim und Easing lesen es schon dort (`proto_sim.gd` Z. 306, `proto_easing.gd` Z. 64). Alle Easing-Grenzen hängen an `v_nom` (`tech.md` §2). Ein Umzug bringt zwei Leser plus Migration und keinen Nutzen. `lkw_e1` bleibt für den Slice unberührt | Jonas, beim Default-Wechsel der Welt (frühestens S9) |
| W2 | **Ertragsausgleich.** Entwurf: Ertrag × k, Bedarf ÷ k (§2.2). Design: nur ein globaler Faktor a per Bisektion, kein ×k (§2.4). Tech: Preis × gemessenes k_eff, Fristen unskaliert (§2) | **Ausgleich nur über den Preis**: Faktor `tempo_ausgleich_promille` = a in `economy_proto.json`, Bisektion im Intervall [1.000; k_eff × 1.000]. Ziel: Plan-Bot erreicht F2 bei Minute 25 ± 5, und Designregel X1 hält. **Bedarf, Produktion und Frischefristen bleiben unverändert** | Der Bedarf gilt je Wanduhr-Periode und hängt nicht am Fahrzeugtempo. Ein voller Faktor × k stellt das Kosten-zu-Ertrag-Verhältnis von k = 1 wieder her und holt damit den Exploit zurück (`design.md` §2.3/2.4, `tech.md` Widerspruch 2) | Tobias, bei Gate C, falls X1 rot |
| W3 | **Mühlendeckel 20 E/min.** Entwurf W4: „nur Weltdaten“. Design: Ausbau über C1 nötig, sonst ist Farm 2 wirkungslos (§0.1, §5.2). Tech: Werksausbau = „Stufe 2, S9+“ (§6a) | **Werksausbau Mühle auf 40 E/min gehört in S8**, als Teil von FK-02 (Schlüssel `fabrik` 40 E/min und 2.000 $ gibt es, D19). **Rückfall ohne Kosten**: Ist FK-02 bei Gate C nicht grün, setzt `economy_proto.json` den Durchsatz der Mühle fest auf 40, und Farm 2 trägt die Wahl allein | Ohne Ausbau bleibt nach Minute ≈ 14 nur „mehr Fuhrwerke“, und der Loop fällt wieder ins Plateau (G-01 Z. 3). Neue Begriffe gegen die Dreifachbelegung von „Stufe“: **Kaufstufe C1/C2** (Firmenkauf), **Werksstufe 1/2** (Durchsatz), **Konkurrenzstufe** (KI) | Tobias, Gate C |
| W4 | **Stichweg P3.** Entwurf: MUSS. Tech: MUSS, 3 T auf dem kritischen Pfad (P-03). Design: Stretch (§7). UX: Spec UX-3 | **Nicht im Sprintziel. Spike (1 T Zeitbox) als Stretch** auf eigenem Branch, ohne Merge | Basti nennt Bauen in seiner Loop-Liste nicht (`brief.md` Z. 7). Inkrementeller Bau zur Laufzeit wurde „niemand je versucht“ (`tech.md` §2) und vergibt Knoten-IDs neu. Spart Felix 2 T und Mira 1 T. **Preis:** Pfeiler 2 bleibt in S8 ungetestet | Basti, Frage 3 |
| W5 | **Binsensee.** Entwurf: gestrichen. Design: ≤ 150 m (LD1). UX: hängt an Bastis T-W1 (LV-1) | **Verkleinern auf ≤ 150 m**, `flusstal.see_durchmesser_m` = [0, 150], Validator prüft die Schwelle 150/300 m | Bastis Regel vom 03.11. 23:38 („breiter Fluss: nur kleine Teiche“). Reine Datenänderung, reversibel, Stadt hat freie Kapazität | Basti, D-W |
| W6 | **Speichern/Laden.** Entwurf: SOLL, 1,5–2 PT. Tech: 3 T (§5) | **Raus, S9, mit 3 T** (höhere Zahl) | SoA, Blockhalter, Wartelisten und Easing-Zustand wurden nie serialisiert. Basti spielt 45 min am Stück. Für Fremdtester wird es in S9 Pflicht | – |
| W7 | **Depot.** Entwurf: KANN, 2–3 PT. Tech: 3–4 T. Design: raus | **Raus, S9+, mit 4 T.** Ersatz: Kauf und Ersetzen im Linienpanel und auf der Fahrzeugkarte, dazu die **Fuhrhalterei am HQ** als sichtbarer Panel-Eintrag ohne Sim-Funktion (Text: „Unterhalt enthält Futter, Knecht, Stellmacher“) | Eine Depotfahrt ist eine dritte Routenart im Kern (`sim_world.gd` Z. 327–423) und betrifft die Parität alt/SoA. Bastis Frage „wo kauft und wartet man“ bekommt so trotzdem einen Ort | Basti, D5 |
| W8 | **Konkurrenz als Spielfigur.** Entwurf streicht den Firmenkauf ganz. Tech: 6–10 T, nicht S8. UX: Firmenfarben für KI | **Konkurrenz als Spielfigur nicht vor S10.** Die Palette für Firmenfarben kommt in S9 mit C2. Den COLOR-Belegungsvertrag (`COLOR.rgb` Firma, `COLOR.a` Alter) gibt es jetzt (FZ-07) | `economy.gd` kennt eine Kasse (Z. 130), `line_events` bucht ohne Firma, und die KI-Kompetenz fehlt (`tech.md` §10) | – |
| W9 | **F2-Schwelle.** G-01 setzt 1.000 $/min netto. Design: mit einer Mühle liegt das Brutto-Maximum bei ≈ 1.000 $/min, also unerreichbar (§2.2) | **X = P50(Plan-Bot, Minute 30) × 0,8**, mit Messdatum im JSON. Platzhalter 600 $/min, **Ablaufdatum Gate C**. Ohne Bot-Wert kein Haken an F2 | Schwellen aus dem Gefühl („Platzhalter für Tobias“, Zähler 3) | Tobias, Tag 11 |
| W10 | **Gleis ab 1835.** Die Streichliste im Entwurf begründet mit 180 min bei 12 min/Jahr. Bei 3 min/Jahr ist das Minute 45 (`design.md` Z. 70) | **Gleis in der Welt aktiv gesperrt**: kein Werkzeug, und das Kalenderjahr 1835 löst weder Freischaltung noch Toast aus (Test in AT-02) | Sonst kommt am Loop-Ende eine Freischaltung, die ins Leere läuft | S9-Refinement |
| W11 | **Umlauf/k_eff.** Entwurf §2.2: 300 Ticks je Umlauf, aus 200 Getreide zurückgerechnet. Design: die 200 sind die Produktionsgrenze (`design.md` Z. 339) | **Entwurfszahlen zum Umlauf gelten nicht.** k_eff wird gemessen (AT-04-Protokoll, QT-03) | Gerechnet ≠ gemessen (Stolperstein 3) | – |
| W12 | **Statischer Kassen-Check.** Tech will 0 `cash_cent ±=` außerhalb von 3 Dateien. Das Abbruchkriterium des Spikes erlaubt aber nur 3 `main.gd`-Funktionen. `main.gd` Z. 2714/2783 (Erstattungen) liegen außerhalb | **Allowlist** für `main.gd` Z. 2714 und 2783 mit Ablaufdatum S9-Refinement. Der Check schlägt bei jedem **neuen** Treffer an. `proto_sim.gd` Z. 433 muss über `konto.gd` laufen | Sonst schlägt das Abbruchkriterium allein wegen des Checks an. Die Drift-Regel „Eine Regel, eine Datei“ bleibt für alle neuen Buchungen | Felix, S9 |
| W13 | **Bodentextur-Aufwand.** Entwurf D6: 2 PT. UX: Stufe A 3,75 + Messskript 1 + Ufer 1, bedingt 5-m-Karte +2 | **UX-Zahl**: BT-1 + Stufe A + Ufer ≈ 6 T TA + 0,75 Sophie. BT-4 (5-m-Karte) **S9** | Laut `ux_art.md` §1 kommt „krude“ von B1/B2 (Auflösung, Flachfarbe). 2 PT wären Kosmetik. TA liegt nicht auf dem Loop-Pfad | Basti, D6 |
| W14 | **Baumallee.** Entwurf: gestrichen. UX: rein (PL-3, 0,5) | **Rein** | Von Basti genannt, Ursache im Code belegt (`stadt_gen.py` Z. 584–619: 12-m-Takt, strikter Artwechsel), Stadt-Design hat 5 T frei | – |
| W15 | **L1 „vorher/nachher an Bastis Stellen“** (Entwurf Etappe 1) ist unmöglich, weil die Stellen noch fehlen (`ux_art.md` W5) | **L1 sammelt Stellen (F12), L2 vergleicht vorher/nachher** | Logik | – |
| W16 | **Termine der Basti-Karten.** Design: L2 Tag 7, L3 Tag 13. Tech: L1 nach T3, L2 nach T8, L3 nach T12. UX: L1 T5, L2 T10, L3 T13 | **L1 Tag 4, L2 Tag 9, L3 Tag 13**, jeweils am Morgen nach dem Gate | Ein Gate vor jeder Karte. Zwischen L1 und L2 liegen 5 Tage für BT-2 und PL-2 | – |
| W17 | **Skilltree-Umfang.** Design: 2 Äste, 6 Knoten. Tech: Liste, UI als Stretch. UX: 6 Äste, 48 sichtbare Knoten, Baumgrafik | **v1 = 2 Äste, 6 Knoten, Listen-UI**, Bau nur in (ii). Baumgrafik und 6 Äste S9. Ausstoß-Ränge raus (Befund 6) | Mira-Engpass. Ausstoß verpufft unter Sättigung und Mühlendeckel (`design.md` §B) | Basti, Szenario-Wahl |
| W18 | **D-S Punktequelle.** UX: „offen“ (`ux_art.md` §7b). Design: entschieden | **S7-Entscheid gilt** (Meilensteine/Etappen). `sk01`/`lena.md` werden in SK-01 nachgezogen | `s7/refinement/ergebnis.md` Z. 91 | Basti, D-S |
| W19 | **Sättigungsschwellen.** Design: gelb > 100 %, rot ≥ 150 %. UX: gelb 100 %, rot 130 % | **Gelb ab 100 %, rot ab 150 %** (dort erreicht die Kante 0,1, `economy.gd` Z. 353). Die Anzeige rechnet mit derselben Funktion (OE-05). Den UX-Beispieltext auf 150 % ändern | Spiel und Anzeige rechnen dieselbe Regel (Retro S6/S7) | Aylin, nach L3 |
| W20 | **Restwert.** Slice: 50 % pauschal (`main.gd` Z. 2693ff.). Design: 50 % × max(0,2; 1 − Alter/Lebensdauer). Tech: linear fallend auf ≥ 10 % | **Design-Formel** (Untergrenze 10 %, deckt sich mit Tech) | Macht das Ersetzen um Minute 30 zur echten Rechnung (`design.md` §3.2) | Tobias, OE-02 |
| W21 | **Postkutsche.** Basti sagt „Fuhrwerke/Kutschen“, Design: nicht kaufbar, Tech: Tempo auch für die Postkutsche | **Nicht kaufbar in S8.** Ihr Tempo wird mit ÷ k gesetzt (Kulisse, Stretch O1) | Ohne Personen-Sim ist sie eine reine Geldsenke | Basti, Frage 5 |
| W22 | **Fehlende Tech-Messwerte** (`tech.md` Z. 65/67/75 Platzhalter). Die Regressionslaufzeit hat 4 Werte (1.090–1.565 s, Entwurf §4) | **Gilt als nicht gemessen.** QT-01 misst an Tag 1 (Sprintstart Aufgabe 1) | Keine Planung auf Platzhalter | – |
| W23 | **Gelände-HUD.** Tech: 0,25 Felix für „Gelände: TA/Stub“ (§9.7). UX: gibt es schon (`prototyp_welt.gd` Z. 562) [M] | **Kein Ticket.** RL-0: Basti schickt einen Start-Screenshot mit HUD | Im Code belegt | – |
| W24 | **Startkapital.** Entwurf: 6.000 $. Design: im Bot 3.000/4.500/6.000 variieren | **6.000 $ als Annahme.** OE-03 entscheidet nach dem Tiefpunkt-Kriterium (Kasse P50 zwischen Minute 5 und 20 < 2.000 $) | D22 ist auf dem Slice kalibriert | Tobias, Gate C |
| W25 | **Interessenkurve per Taste 1–5** (Entwurf Q5) kollidiert mit den Kamera-Presets 1–5 (`ux_art.md` W9) | (ii): Testmodus mit Knopfleiste (QT-08). (i): Papierformular mit Uhrzeit | Bedienkollision | – |
| W26 | **Mira-Last.** Entwurf 6–9 PT, Tech 11,25 (gekürzt 10,25), Design 13–16 | **Mit den höheren Zahlen 16,25 T** im vollen Umfang. Daher die zwei Szenarien in §5 | Keine Schönfärberei | – |

---

## 4 Tickets (konsolidiert, Definition of Ready)

**DoR je Ticket:** Akzeptanz mit Zahl, Abhängigkeit, Schätzung mit Marke, Testweg (in der Akzeptanzspalte nach „Test:“). „(ii)“ heißt: nur in Szenario (ii). „Kipp“ heißt: Das Ticket fällt als erstes nach S9, wenn Gate B mehr als einen halben Tag zu spät kommt. Herkunft in Klammern (Beitrags-ID).

### A Loop/Technik

| ID | Ticket | Owner T | Akzeptanz messbar | Folge/Abhängigkeit | Block |
|---|---|---|---|---|---|
| AT-01 | Spike + `core/konto.gd` (charge, fix_neu, tick); `main.gd` nur `charge` Z. 3105, `_recompute_running_cost` Z. 3110, `sim_tick`-Kostenblock Z. 3121–3154 (Tech A-01, Design E1) | Felix 1 [E] | d08 `--n=20` CSV gegen Baseline: diff leer; parity 8/8; slice_test 74/74; statischer Check `cash_cent ±=` nur in economy/credit/konto plus Allowlist (W12). Test: `run_tests.sh`, d08, grep. Abbruch nach 4 h → Rückfall Zwillingstest (+0,25) | Baseline aus QT-01; Grundlage für AT-02 | A (T1) |
| AT-02 | ProtoSim spielfähig: Konto, Kredit ab Tick 7.200 über `credit.gd`, Bankrott, Kauf/Verkauf mit Restwert, `linie_anlegen`/`station_anlegen`/`lizenz_kaufen` per API, Start mit 6.000 $ ohne Kette, `--kette=fest` für Alttests, Gleis gesperrt (W10) (Tech A-02, Design E1) | Felix 2, Daniel 0,5 (Gegenprobe) [E] hoch: Tech 3 inkl. AT-01 > Design 2 | proto_sim_test erweitert: 0 $ Fix ohne Fahrzeug; Fix je Periode = Σ fix_eff; Zins wie credit (17 Fälle aus `d07 --only=kredit` gespiegelt); Kasse < 0 → bankrott in ≤ 1 Tick; Paritätstest gleiche Kette Slice-Logik/ProtoSim ±0 ¢ über 6.000 Ticks; Kalender 1835 → 0 Freischaltungen. Test: `proto_sim_test.gd` | AT-01; Grundlage für AT-07ff., QT-03, FK-02 | B (T4–5) |
| AT-03 | Generische Site-Registrierung: alle Farmen/Mühlen/Orte aus `proto_orte.json`, Stadt-ID und `sim_ew` aus den Daten statt fest (`proto_sim.gd` Z. 365–395) (Design W4b) | Felix 0,75 [E] | 2 Farmen, 1 Mühle, 2 Orte als Sites; neuer Test „2. Farm liefert“; Nachfrage Erlenbach 10 ± 2, Lindenfurt 24 ± 3 E/min. Test: proto_sim_test | WA-07; Grundlage für QT-03 | B (T6) |
| AT-04 | Tempo k: `tempo_k` im Regelwerk, `--tempo_k=4/6/8`, ProtoSim setzt `v_nom = promille/k` für Fuhrwerk/Postkutsche; `proto_sim_test` Z. 63 auf `600/k`; Overlay-Gerüst `economy_proto.json` (a = 1.000) (Tech T-01, W1) | Felix 1, Tobias 0,5 [E] hoch: Entwurf 1–1,5 | `proto_easing_test` E5 0 Verstöße bei k = 4 und 8; E6 ≤ 1,3 × W/2 oder ABW mit Datum; Slice md5 unverändert; Umlauf Farm→Mühle in Ticks gemessen und im Ticket protokolliert (k = 1/4/8). Test: proto_sim/easing | hängt an D2; Grundlage für FZ-09, OE-02 | A (T2) |
| AT-05 | Pause (Leertaste) + 1×/2×/4× + Datum im Welt-HUD | Mira 0,25 [E] | Pause: 0 Ticks in 10 s Wanduhr; 4×: 40 ± 1 Ticks/s bei ≥ 20 fps (Zähler). Test: neuer Fall in `proto_welt_test` | WA-03a (Licht ausgelagert) | A |
| AT-06 | Startknopf „Welt spielen (Loop S8)“ im Startmenü | Mira 0,25 [R] | s7_start erweitert: Knopf sichtbar, startet die Welt; L1 Schritt 1 „geklappt“. Test: s7_start | QT-04 (P-Menü) vorher reproduziert oder geschlossen | A |
| AT-07 | Welt-Panel `proto/ui_welt.gd`: Info (Bestand, Bedarf, Sättigung), Lizenz kaufen, „Linie von hier“, Fuhrhalterei am HQ (Tech P-01, UX-2) | Mira 2, Aylin 0,5 [E] | Jede Panelzahl gegen den Spielwert getestet; Lizenzkauf ändert die Kasse um den Vorschaupreis ± 0. Test: Panel-Test + play_welt | AT-02; AT-14 | B |
| AT-08 | Linie anlegen + Fuhrwerk kaufen/hinzufügen, Routenvorschau mit Preis und Fixkosten/min (Tech P-02, Design „+ Fuhrwerk“) | Mira 2 [E] hoch: Entwurf 1–2 > Tech 1,75 | play_welt: Farm→Mühle→Dorf in ≤ 6 Klicks; 3 Fehlerfälle (keine Verbindung, kein Geld, keine Lizenz) je mit Text, 0 stumm. Test: QT-05 | AT-02, AT-07 | B |
| AT-09 | HUD Welt: Kasse, €/min, Fix/min, Kredit-Chip, Datum, Tempo (Tech U-01) | Mira 1 [E] hoch: Entwurf 0,5–1 | Kopfleiste bei 1600 px ohne Clipping; jede Zahl = Spielwert (Test) | AT-02 | B |
| AT-10 | Linienliste: €/min je Linie, Alter/Unterhalt, Sättigung gelb ≥ 100 %/rot ≥ 150 % mit „+x $/min nur mit neuem Abnehmer“ (Tech U-03, UX-4) | Mira 0,75 (i) / N.N. 1 (ii), Aylin 0,5 [E] hoch: Entwurf 0,5–1 | Gewinn je Linie = Σ(Ertrag − Fahrkosten − fix_eff) ± 1 ¢; x = OE-05-Funktion (Test bei 3 Sättigungsstufen). (i) ohne Sortieren | AT-02, OE-05 | C |
| AT-11 | Toast-Queue `ui/toast_queue.gd` (main._toast leitet weiter) + **A-08** Diagnose mit Ort + Ursache + Aktion; Katalog ≥ 6 Fälle (wartet auf Ladung, Restladung, gesättigt, Lizenz läuft ab, Linie mit Verlust, Fuhrwerk alt), nur in der Welt (Tech U-04, UX-5, Design L2) | Mira 1,75, Felix 0,25, Aylin 1,25, Lena 0,25 [R] hoch: Entwurf 1,5–2. (i): Mira 1,5, ohne Fokus-Klick | 3 Meldungen in 1 Tick → nacheinander, 0 verloren; Diagnose bei Wartezeit > 30 s; jeder Text erfüllt das Schema (Test); Slice bitgleich; L3: ≥ 80 % „verstanden“. **Zähler 4, deshalb Teil des Sprintziels** | Queue in Block A (main.gd T2–3), Diagnose in C | A + C |
| AT-12 | Fehlertexte Welt (Kauf, Lizenz, Linie, Kredit, Bankrott); Aylin trägt die Texte direkt in `ui/fehlertexte.gd` ein, Mira verdrahtet (Tech U-05) | Mira 0,25, Aylin 0,75 [E] | 0 stumme Ablehnungen im play_welt-Durchlauf aller Fehlerfälle | QT-05 | C |
| AT-13 | Ziele E-1–E-6, F1, F2 + „Nächster Schritt“ aus `ziele_welt.json` (Design Z1b, Tech U-02, UX-6) | Mira 0,5 (i, Textliste) / +N.N. 1 (ii, Marker, Preis = Stretch), Lena 0,5, Aylin 0,25 [R] hoch: Design 2 | Je Ziel ein Test „hakt nur bei Messgröße“; E-6 hakt nicht, solange eine Linie Verlust macht | OE-01 | C |
| AT-14 | Loop-Flow-Spec: Zustände, Erfolgs- und Fehlerweg je Schritt, Wireframes (UX-1) | Aylin 1 [E] | Jeder Schritt mit ≥ 1 Erfolgs- und ≥ 1 Fehlerweg mit Text; Mira bestätigt die Umsetzbarkeit bis Tag 3 | – | A |

### B Ökonomie/Design

| ID | Ticket | Owner T | Akzeptanz messbar | Folge/Abhängigkeit | Block |
|---|---|---|---|---|---|
| OE-01 | Ziel-Spec E-1–E-6, F1, F2, Ereigniskatalog 1–8 mit Auslöserformel, Fahrplan als `ziele_welt.json` (Design Z1a) | Lena 1,5, Tobias 0,25 [E] | Jedes Ziel nennt Feld, Schwelle und Bot-Messpunkt; Daniel prüft: 0 Ziele ohne Messgröße | Grundlage für AT-13, QT-03 | A |
| OE-02 | Tempo-Kalibrierung: X1 Distanz-Sweep, X2 Umweg, X3 Weltkarte; Faktor a (W2); Fix/Kap Fuhrwerk und Frachtwagen (Design E3a) | Tobias 2 [E] | Designregel §2.3 grün für Mehl und Getreide; Netto P50 (Plan, Min 30) zwischen k = 4 und 8 ± 15 %; X2: Umweg 1,6 senkt das Netto um ≥ 20 % | D2, QT-03 (n = 20 ab T6), FZ-01 | B–C |
| OE-03 | Bankrott-Band und Startkapital-Variation auf der Welt (Design E3b) | Tobias 2 [R] hoch: Entwurf 1,5–2 | Naiv 10–30 %, Plan ≤ 5 % (n = 300, Wilson); Startkapital nach Tiefpunkt-Kriterium (W24) entschieden und im JSON | OE-02 | C |
| OE-04 | F2-Schwelle aus dem Bot (W9) (Design Z1c) | Tobias 0,25 [R] | X = P50 × 0,8 mit Messdatum im JSON; Platzhalter 600 entfernt | QT-03 n = 300 | C (T11) |
| OE-05 | Sättigungsfunktion „x $/min bis V = 1.000 ‰“ in `economy.gd` (Design E2s) | Tobias 0,25 [E] | Test gegen 3 Sättigungsstufen; Anzeige = Formelwert | Grundlage für AT-10 | B |
| OE-06 | Lizenz im Loop: ADR „Verlängerung zum gleichen Preis bleibt in S8“ (Code: `_renew_licences` Z. 602–623). Der Bot zählt Ereignis 6 | Lena 0,25 [E] | ADR mit „revidierbar bis S9-Refinement“; Bot zeigt Ereignis 6 bei Minute 27–30 | OE-01 | B |

### C Fahrzeuge/Kutschen

| ID | Ticket | Owner T | Akzeptanz messbar | Folge/Abhängigkeit | Block |
|---|---|---|---|---|---|
| FZ-01 | `fuhrwerk_e1` und `frachtwagen_e1` in `vehicles.json` (Kosten, Kapazität, `lebensdauer_jahre`, Alterung, `verfuegbar_ab_jahr`, **kein Tempo**); ProtoSim liest Kosten je Kategorie statt `lkw_e1` (Design F3) | Felix 0,5, Tobias 0,5 [E] | Fuhrwerk-Linie bucht 60 $/Periode Fix und 10 E Kapazität (Startwerte `design.md` §3.2); Slice md5 unverändert; statischer Check: kein Tempofeld | AT-02 | B |
| FZ-02 | Zwei Uhren: Kalender `jahr_ticks` 1.800 (Test) / 7.200 (Standard); nur Datum, Alterung und Folgemodell lesen ihn (Tech K-01) | Felix 0,75 [E] | Wirtschafts-Prüfsumme bei 1.800 und 7.200 identisch (ohne Fahrzeugalter); Datum springt alle 150 Ticks um einen Monat | hängt an D5 | B |
| FZ-03 | Alterung: `fix_eff = fix × (10.000 + bp × Jahre)/10.000`, ganzzahlig, einmal je Kalenderjahr; Meldung bei 100 % Lebensdauer (Design F2) | Felix 0,5, Tobias 0,25, Mira 0,25 [E] hoch: Design > Tech | Nach 10 Kalenderjahren Fix = 150 % (Test); Jahr 5 = 125 % exakt | FZ-02 | C |
| FZ-04 | Verkaufen/Ersetzen mit Restwert (W20), Linie läuft weiter; Fahrzeugkarte mit Alter, Unterhalt/min und „Ersetzen spart z/min“ (Design F5, UX-7) | Mira 0,5 (i) / N.N. 0,5 (ii), Felix 0,25, Aylin 0,75 [E] | Restwertformel im Test; Linie läuft ohne Neuanlage weiter; alle Kartenzahlen = Sim; L3: Basti ersetzt ohne Hilfe | FZ-03 | C |
| FZ-05 | **Kipp:** Folgemodell Frachtwagen ab 1830, Kaufwahl im Ersetzen-Dialog, Toast „Frachtwagen verfügbar“ (Design F4) | Felix 0,5, Mira 0,25 (+N.N. 0,25 in ii), Tobias 0,25 [E] | Bei 3 min/Jahr ab Minute 30 kaufbar (Zeitsprung-Test); Bot: Ersetzen-Ereignis zwischen Minute 28 und 35 | hängt an D5, FZ-01 | C |
| FZ-06 | Ladung sichtbar (M10) + Pferd: Lizenz prüfen, dann einbauen oder als Behelf benennen (UX FW-1) | TA 0,5, Sophie 1 [E] | Ladung aus 80 m 3/3 Personen; Lizenzzeile in `asset_audit`; `proto_mass` grün. **Lizenz ungeklärt → nicht einbauen** (§9) | FZ-07 (Vertrag) | B |
| FZ-07 | COLOR-Belegungsvertrag (`rgb` Firma, `a` Alter) + Patina neu/gebraucht/alt (UX FW-2) | TA 0,5, Sophie 0,25 [E] | Vertrag im VERTRAG.md vor dem ersten Shader-Merge; 5 Personen unterscheiden neu/alt aus 80 m in ≥ 4/5; DC unverändert | hängt an D5 | Vertrag A, Patina C |
| FZ-08 | Frachtwagen-Prefab (4 Pferde, Plane, Länge) (UX FW-3) | Sophie 1,25, TA 0,25 [E] | Aus 300 m 5/5 „anderes Fahrzeug“; Maße in `proto_mass` | FZ-05 (Kipp: läuft das Prefab, bleibt es als Asset) | B–C |
| FZ-09 | Easing/Gang nach k: E1–E8 neu messen, Gangdeckel 1,5–2,5 Hz, Gangphase je Doppelschritt (Halbfloat-Fix) (UX FW-4) | TA 1, Felix 0,25 (Review) [R/E] | `proto_easing_test` 0 FAIL; Beinphasen-Sprung ≤ 3°; L1: „Tempo glaubwürdig“ ja | AT-04 gemergt | B |

### D Welt/Art/Bodentextur

| ID | Ticket | Owner T | Akzeptanz messbar | Folge/Abhängigkeit | Block |
|---|---|---|---|---|---|
| WA-01 | Stellenformat A an Basti (eine Seite) + RL-0 Prüfweg TA/Stub per HUD-Screenshot (BT-0, RL-0) | Aylin 0,35 [E/M] | Vorlage Tag 1 bei Basti; ≥ 5 Stellen bis Tag 4, sonst 8 eigene Standorte (5 Presets, Markt-Ufer, 2 Ackerränder) | – | A (T1) |
| WA-02 | F12 „Stelle merken“ (PNG + JSON) + Messskript: Treppen-, Kachel-, Detailmetrik, Frametime xvfb; Baseline eingecheckt (BT-1) | TA 1 [E] | Läuft headless/xvfb < 2 min, schreibt CSV; Baseline auf dem heutigen Stand | Testweg aller WA-Tickets | A |
| WA-03 | Licht/Relief: `world/proto_licht.gd` auslagern (**zuerst, T1**), Sonne 25–30°, Umgebungslicht ~0,2 mit Himmelsquelle, Hangschummerung als Uniform, Höhentönung (RL-1) | TA 1,25, Sophie 0,25 [E] | Leuchtdichte Sonnen- gegen Schattenhang (5–15 %) ≥ 12 % (heute ~7 % [R]); 3 Personen finden höchsten Punkt und tiefste Senke 3/3; L1: Basti 3/3; Perf-Budget hält | WA-02; Auslagerung vor AT-05 | A |
| WA-04 | Bodentextur Stufe A: Übergänge, Makro, Detailtextur CC0, Schläge im Shader (BT-2) | TA 2,75, Sophie 0,5 [E] hoch: UX > Entwurf D6 | Treppenmetrik ≤ 50 % Baseline und ≤ 17 %; Kachel-Nebenpeak ≤ 0,25; Detail-Streuung bei 40 m ≥ 2× Baseline, bei 3 km ≤ 1,2×; ≤ 6 Lookups, VRAM +≤ 8 MB, Ladezeit ≤ 3 s, Frametime +≤ 15 %; CC0-Lizenzzeile je Textur | WA-02, Stellen aus L1 | B |
| WA-05 | Ufer aus Distanzfeld 5 m (Integration M7) (BT-3) | TA 1 [E] | Treppenmetrik Uferkante ≤ 50 % Baseline; Blind-A/B Daniel + Sophie | WA-02. **TA-Kipp:** sonst Kanban in Block D | C |
| WA-06 | Basti-Abnahme Boden in L2 (BT-5) | Aylin 0,25 [E] | Je Stelle besser/gleich/schlechter: ≥ 80 % besser, 0 schlechter | WA-04 | L2 |
| WA-07 | Welt-Daten: Farm 2 (35–50 Felder von der Mühle, Ebene/Aue) mit Ladeplatz, Lindenfurt klassenkonform, `sim_ew` je Ort in `proto_orte.json` (Erlenbach 500, Lindenfurt 2.400) (Design W4a) | Stadt 1,25, Tobias 0,25 (Review) [E] | Validator 0 Verstöße; Slice md5 unverändert | Grundlage für AT-03 | A |
| WA-08 | Ladeplatz je Betrieb/Ort: Datenpunkt ≤ 8 m vom Netz, Kies-Hof, Rampe, Lagerhaufen mit 3 Füllstufen; Halt = Ladeplatz (Design L1, UX LP-1) | Stadt 1, Sophie 1, TA 0,25, Felix 0,25 [E] hoch: Summe beider | Validator: 0 Ladeplätze > 8 m; Gespann-Heck ≤ 3 m vom Ladeplatz (`proto_fixpass_test`); Füllstufe folgt dem Bestand (Test); 3/3 Personen zeigen aus 170 m auf den Ladeplatz | AT-02 | B |
| WA-09 | Validator: Bezugslinie ±10°, Baulinie, Zufahrt, Fundament ≤ 0,5 m im 5-m-Raster (PL-1) | Stadt 1 [E] | Neue Prüfungen in der schnellen Stufe; Baseline-Verstöße als Liste | – | A |
| WA-10 | Placement an Validator-Verstößen und Bastis Stellen beheben, über Generator-Regeln (Design W3, PL-2) | Stadt 1,5 [E] hoch: Design > UX | Validator 0 FAIL; Vorher/Nachher je Stelle (F12); L2: Basti ≥ 80 % „passt jetzt“; proto_sim/proto_welt grün | WA-09, L1-Stellen | B–C |
| WA-11 | Baumallee: Takt 12 ± 3 m, 10–15 % Lücken, Arten gewichtet, Größe ± 15 % (PL-3) | Stadt 0,5 [E] | Validator: Variationskoeffizient der Abstände ≥ 0,15, strikter Artwechsel < 60 %; Blind-A/B ≥ 2/3 „natürlicher“ | – | A |
| WA-12 | Gewässer je Kartentyp: Schwelle 150/300 m im Regelwerk + Validator, Binsensee ≤ 150 m (Design LD1, UX LV-1) | Stadt 0,75, TA 1 [E] hoch: UX 0,75 + Design TA 1 | `regelwerk.json` geändert (nach Gate A, W1: AT-04 schreibt dieselbe Datei); Validator prüft die Schwelle; proto_terrain grün | hängt an D-W | B |
| WA-13a | Schild-Kontrast: Platte ≥ 3:1, Text ≥ 7:1 in allen 15 Bildmessungen (UX OS-1, Teil) | Aylin 0,25, TA 0,25 [M/E] | `proto_schilder_shots.gd`: 15/15 | – | B |
| WA-13b | (ii, Stretch) Ortsschild-Status: Versorgung je Ware, Sättigung als Zustand, „gebremst durch X“ (UX OS-1) | Aylin 0,75, N.N. 0,5 [E] | Status = Sim-Wert (Test je Zahl) | OE-05 | Stretch (ii) |
| WA-14 | Lieferung sichtbar: Lade-/Entladebalken am Gespann, Fuhren/min in der Liste (UX-8) | Aylin 0,25 (Spec) [E]; Umsetzung in FZ-06/AT-10 | L2: Basti beschreibt, wo geladen und wo abgegeben wird | WA-08 | B |
| WA-15 | Mühle kaufbar und Werksstufe in der Karte sichtbar (Hofschild-Platz, Ausbaufläche) | Stadt 0,5 [E] | Validator: kaufbarer Betrieb hat Ausbaufläche ≥ 1 Footprint ohne Überlappung | FK-02 | B |
| WA-16 | Loop-Icons (~10: Fuhrwerk, Alter, Wartung, Sättigung, Ladeplatz …) im Stil `ui/icons.json` | Sophie 1 (i) / UI-Artist (ii) [E] | 3 Personen ordnen 10/10 zu | AT-14 | B |

### E Firmenkauf (Kaufstufe C1)

| ID | Ticket | Owner T | Akzeptanz messbar | Folge/Abhängigkeit | Block |
|---|---|---|---|---|---|
| FK-01 | ADR C1/C2 + Besitzerfeld-Spec (`s_owner` je Standort, 0 frei/1 Spieler/≥ 2 reserviert) + Begriffe Kaufstufe/Werksstufe/Konkurrenzstufe (W3) | Jonas 0,25, Tobias 0,5, Felix 0,25 [E] | ADR „revidierbar bis S9-Refinement“; Feldliste ≤ 1 Seite | – | A |
| FK-02 | C1 in `economy.gd` (Schreiber Tobias): `buy_site`, `s_owner` in `checksum()`, Besitz ersetzt Lizenz in `load_gate`, Werksmarge 15 %, Unterhalt über `konto`, **Werksausbau Mühle auf 40 E/min (2.000 $)**, Kauf nur aus Guthaben, +25 % je weiteres Werk (Design F22-1, Tech C-01) | Tobias 1, Felix 1,5, Daniel 0,5 [E] hoch: Design 2,5 > Tech 2 (+ Daniel aus Tech) | Kaufpreis = Formel (Test je Fall); Slice bitgleich, solange nichts gekauft ist; Bot: Kauf amortisiert sich in 8–20 min, der Plan-Bot kauft zwischen Minute 14 und 25; Schneeball: keine Verdopplung Netto-€/min schneller als in 10 min nach dem 1. Kauf. **Rückfall W3** | AT-02, FK-01 | economy.gd B (Tobias), konto/proto C (Felix) |
| FK-03 | C1-UI im Welt-Panel: Knopf mit Preis und Anrechnung, Bestätigung inline mit Folgen, 4 Fehlertexte (Ursache + Lösung) (UX FK-U1) | Mira 0,5 (i) / +N.N. 0,5 (ii: Amortisationszeile, Pin), Aylin 0,75 [E] | Kauf in ≤ 3 Klicks; jede Ablehnung mit Ursache + Lösung (play_welt); alle Folgezahlen = Sim | FK-02, AT-07 | C |
| FK-04 | C2-Spezifikation (Restwert, Kreditübernahme, Zeitfenster 3 min) + UI-Skizze, nur Papier (Design F22-2) | Lena 1, Aylin 0,5 [E] | 1 Seite mit Formeln und Bot-Testfall; Bauschätzung für S9 | FK-01 | D |
| FK-05 | Besitz sichtbar: Pin-Rand voll/gestrichelt, Hofschild (UX FK-A1, ohne KI-Palette) | Sophie 0,5, TA 0,25 [E] | 3/3 Personen erkennen aus 300 m „gehört mir“; DC unverändert | FZ-07 | C |

### F Skilltree v1

| ID | Ticket | Owner T | Akzeptanz messbar | Folge/Abhängigkeit | Block |
|---|---|---|---|---|---|
| SK-01 | Konzept v1: Punkte aus E-1/E-6/F1/F2 (D-S), 2 Äste × 3 Knoten (Ausspann, Fuhrhalterei, **Frachtwagen-Patent**; Marktstand, Kornspeicher, **Mahlrecht**), höchstens 1 Preisknoten, Respec frei; `skilltree.json`; `sk01`/`lena.md` nachziehen (Design SK-02a) | Lena 1,5, Tobias 0,75 [E] | 1 Seite; jeder Knoten zeigt Wirkung in Zahlen und „wirkt auf“; 0 Ast-XP-Erwähnungen in den Konzeptdateien | OE-01 | (i) D, (ii) B |
| SK-02 | (ii) `skills.gd` + 4 Hooks (Ertrag je Gut, `s_rate`, Kapazität, `konto.fix_neu`), nur in der Welt aktiv (Tech S-01) | N.N. 1, Felix 0,25 (Review) [E] hoch: Tech 1 > Design 0,75 | `s8_skill_test`: Wirkung je Knoten = Spielwert; Deckel +40 %; Punkte nur aus Meilensteinen; Slice-Prüfsumme bitgleich | SK-01, FK-02 gemergt (`economy.gd`) | C (ii) |
| SK-03 | (ii) Skill-Panel als Liste je Ast (Rang, Wirkung „heute +x $/min“, Setzen, Respec), `ui/skilltree_panel.gd` (Tech S-01, UX SK-U1 gekürzt) | N.N. 2, Aylin 1 [E] hoch: Design 2 > Tech 1,5 | Vorschau ± 10 % gegen den gemessenen Effekt (Test); 3 Personen finden „mehr Ertrag in Städten“ in < 30 s; Plan-Bot hat 4 Punkte bis Minute 45 | SK-02, AT-13 | C (ii) |
| SK-04 | (ii) Icons: 2 Ast-, 2 Schlüssel-Icons, 4 Zustandsrahmen (UX SK-A1 gekürzt) | UI-Artist 1 [E] | 3 Personen ordnen 4/4 zu; Stil `make_icons.py` | SK-01 | C (ii) |
| SK-05 | (ii) Dominanz-Check per Bot (Design SK-02c) | Tobias 0,25, Daniel 0,25 (Lauf) [E] | Δ Netto €/min (Min 45) je Knoten: keiner > 2× Median, keiner < 0,3× Median; Ergebnis wird S9-Tuning | SK-02 | D (ii) |

### G Test/Werkzeug/Basti-Tests

| ID | Ticket | Owner T | Akzeptanz messbar | Folge/Abhängigkeit | Block |
|---|---|---|---|---|---|
| QT-01 | Baseline (Laufzeiten aller Suiten, d08-CSV) + `tests/regress_fast.sh` < 5 min + Proto-Suiten in d07 + `timeout` je Godot-Aufruf (Faktor 3) + statischer Check (W1, W12) (Tech Q-01) | Daniel 1, Felix 0,25 [R] | fast < 300 s, 3× gemessen; Timeout-Fall erzeugt eine FAIL-Zeile; Laufzeittabelle im Repo (ersetzt die Platzhalter, W22) | – | A (T1) |
| QT-02 | Flaky-Rate: volle Regression 5× nachts (Tech Q-02) | Daniel 0,25 [E] | Tabelle Rot je Suite und Lauf; jede Suite mit ≥ 1 Rot → Ticket | QT-01 | A–B |
| QT-03 | Loop-Bot `tests/s8_loop_bot.gd` headless auf der ProtoSim-API (wie die UI): Strategien naiv/normal/plan, Ereigniszähler, Bankrott, Lücke, Exploit X1–X3, Determinismus (Tech Q-03, Design Q2) | Daniel 2, Tobias 1 [E] hoch: Tech 3 > Design 2,5 | CSV je Lauf (Bankrott j/n + Minute, Minute E-1…F2, größte Lücke); n = 20 bis Gate B, n = 300 nachts in Block C; Seed zweimal → gleiche Prüfsumme; Laufzeit n = 300 gemessen | AT-02, AT-03, AT-04 | B–C |
| QT-04 | P-Menü-Absturz: reproduzieren, beheben oder schließen (Tech Q-04) | Daniel 0,5, Felix 0,25 (nur bei Repro) [E] hoch: Entwurf bis 1 | Repro-Schritte im Ticket, oder „nicht reproduziert“ an Tag 3 mit Startweg AT-06 | Basti-Repro | A |
| QT-05 | `play_welt.gd`-Sessions (klick/linie/wait/kauf) (Tech Q-05) | Daniel 1,25 [E] | Session „Loop L2“ (Lizenz, 2 Linien, Kredit) headless/xvfb ≤ 120 s, Exit 0 | AT-02, AT-07 | B |
| QT-07 | Aufgabenkarten L1/L2/L3 + Formular + Auswertungsvorlage (Interessenkurve, Toast-Quote) (UX TK-1, Entwurf Q5) | Aylin 1,5, Lena 1 [R] L-14 = 1,5 | Je Karte ≤ 1 Seite, ein Startweg; Auswertung binnen 0,5 T nach Eingang | Gates A/B/C | A/B/C |
| QT-08 | (ii) Testmodus: Interessenleiste alle 5 min, Toast-Knöpfe, `user://test_log.csv` (UX TK-2) | N.N. 0,5 [E] | 45-min-Lauf erzeugt 9 Interessenwerte und je Toast eine Zeile; im Normalspiel unsichtbar | WA-02 (F12) | C (ii) |
| QT-09 | Abnahmeprotokoll je Block, Screenshots; Daniel spielt L3 selbst 45 min mit Interessenkurve (Tech D-01) | Daniel 3 [E] | Protokoll je Gate; L3-Lauf vor Basti | alle | A–D |
| QT-10 | Fremdtester (3 Personen, die das Konzept nicht kennen): Vorbereitung | Aylin 0,5 [E] | nur wenn Basti 3 Personen nennt (Frage 6) | QT-07 | C–D |
| QT-11 | Produktion: Blocker-Check Tag 1 (Templates, 5-h-Limit, Wine), Burn-down täglich, Merge-Gates moderieren, Referenzklasse S5–S7 (Tech K-02) | Katrin 3 [E] | Blockerliste Tag 1; Burn-down täglich; Plan/Ist je Ticket für die Retro | – | A–D |
| QT-12 | Regression und Review je Block (volle Stufe vor jedem Gate) | Daniel 1,75 [E] | Gate-Protokoll mit Laufzeit | QT-01 | A–D |
| QT-13 | Review/Retro, Backlog S9, Basti-Zusammenfassung ≤ 1 Seite | Jonas 1,5, Katrin 1,25, Lena 1,25 (Auswertung Interessenkurve) [E] | §7 | alle | D |
| QT-14 | (ii) Rollenprofile + Onboarding N.N. Gameplay/UI und UI-Artist (wie K-11) | Katrin 1 [E] | Profil + Dateibesitz + Startaufgaben bis Tag 2; Start Tag 4 | Bastis Ja | A (ii) |

Dedupliziert: Entwurf U4/Tech U-04/UX-5 → AT-11; Entwurf Z1/Design Z1b/Tech U-02/UX-6 → AT-13; Design L1/UX LP-1 → WA-08; Design W3/UX PL-2 → WA-10; Design LD1/UX LV-1 → WA-12; D7-O2/F22-K → S9 (gleiche Mechanik); Entwurf Q3/Tech Q-06/UX TK-3 → AT-06; Entwurf Q2/Design Q2/Tech Q-03 → QT-03; Design F2–F5/Tech F-01 → FZ-01 bis FZ-05; Design E1/Tech A-01/A-02 → AT-01/AT-02.

---

## 5 Kapazität (12 T je Person, davon 9,6 T bis zum Freeze Ende Tag 12)

### Szenario (i): ohne neue Rollen (gekürzt)
Gekürzt sind: Skilltree-Bau (nur SK-01 als Papier in Block D), Ortsschild-Status, Testmodus (statt dessen Papier), Ziel-Marker, Fokus-Klick, Sortieren in der Linienliste, C1-Bestätigung nur als Knopf + Toast, BT-4/RL-2 nach S9.

| Person | Kap. | bis Freeze verfügbar | Plan bis Freeze | Plan Block D | Puffer gesamt | Überbuchung bis Freeze | Belegung |
|---|---|---|---|---|---|---|---|
| Felix | 12 | 9,6 | 9,75 + 0,5 Kipp = 10,25 | 0 (Bugfix) | 1,75 | **−0,15 ohne / −0,65 mit FZ-05** | AT-01 1, AT-04 1, QT-01 0,25, QT-04 0,25, AT-02 2, AT-03 0,75, FZ-01 0,5, FK-01 0,25, WA-08 0,25, FZ-09 0,25, FZ-02 0,75, FK-02 1,5, FZ-03 0,5, FZ-04 0,25, AT-11 0,25, (FZ-05 0,5) |
| Mira | 12 | 9,6 | 9,75 + 0,25 Kipp = 10 | 0 | 2 | **−0,15 ohne / −0,4 mit FZ-05** | AT-05 0,25, AT-06 0,25, AT-07 2, AT-08 2, AT-09 1, AT-10 0,75, AT-11 1,5, AT-12 0,25, AT-13 0,5, FZ-03 0,25, FZ-04 0,5, FK-03 0,5, (FZ-05 0,25) |
| Tobias | 12 | 9,6 | 9,0 | 0,75 | 2,25 | – | AT-04 0,5, OE-01 0,25, OE-02 2, OE-03 2, OE-04 0,25, OE-05 0,25, WA-07 0,25, FZ-01 0,5, FZ-03 0,25, FZ-05 0,25, FK-01 0,5, FK-02 1, QT-03 1; D: SK-01 0,75 |
| Lena | 12 | 9,6 | 3,5 | 3,75 | 4,75 | – | OE-01 1,5, OE-06 0,25, AT-11 0,25, AT-13 0,5, QT-07 1, (QT-13 1,25, FK-04 1, SK-01 1,5 in D) |
| Aylin | 12 | 9,6 | 8,35 | 1 | 2,65 | – | AT-07 0,5, AT-10 0,5, AT-11 1,25, AT-12 0,75, AT-13 0,25, AT-14 1, FZ-04 0,75, WA-01 0,35, WA-06 0,25, WA-13a 0,25, WA-14 0,25, FK-03 0,75, QT-07 1,5; D: FK-04 0,5, QT-10 0,5 |
| Sophie | 12 | 9,6 | 6,25 | 0,75 | 5 | – | WA-03 0,25, WA-04 0,5, WA-08 1, FZ-06 1, FZ-07 0,25, FZ-08 1,25, FK-05 0,5, WA-16 1, Vergleichstafeln 0,5; D: Look-Abnahmen 0,75 |
| TA | 12 | 9,6 | 10,0 (WA-05 Kipp → D) | 0,5 | 1,5 | **−0,4 ohne Kipp** | WA-02 1, WA-03 1,25, WA-04 2,75, WA-05 1, WA-08 0,25, WA-12 1, WA-13a 0,25, FZ-06 0,5, FZ-07 0,5, FZ-08 0,25, FZ-09 1, FK-05 0,25; D: Perf 0,5. **Bedingt BT-4 2 / RL-2 1,5 passen nicht → S9** |
| Stadt | 12 | 9,6 | 6,5 | 0 | 5,5 | – | WA-07 1,25, WA-08 1, WA-09 1, WA-10 1,5, WA-11 0,5, WA-12 0,75, WA-15 0,5 |
| Daniel | 12 | 9,6 | 8,25 | 2,5 | 1,25 | – | AT-02 0,5, QT-01 1, QT-02 0,25, QT-03 2, QT-04 0,5, QT-05 1,25, FK-02 0,5, QT-12 1,25, QT-09 1; D: QT-09 2, QT-12 0,5 |
| Katrin | 12 | – | – | – | 7,75 | – | QT-11 3, QT-13 1,25 |
| Jonas | 12 | – | – | – | 9,25 | – | FK-01 0,25, QT-13 1,5, Entscheidungslog/Basti-Fragen/Mitte-Refinement Tag 8 1 |

**Ehrlich:** In (i) gehen Felix und Mira **ohne Puffer** in den Freeze, schon ohne FZ-05 je −0,15 T. **FZ-05 (Folgemodell) passt rechnerisch nicht vor den Freeze** (Felix −0,65). Es bleibt als Kipp-Ticket im Plan und kommt nur, wenn Felix' Vorgänger-Tickets unter Schätzung bleiben; Entscheid am Mitte-Refinement T8, sonst S9. Basti sieht dann die Alterung, aber kein neues Modell, obwohl er ausdrücklich danach gefragt hat. Deshalb steht das Folgemodell nicht im Sprintziel. Der Skilltree-Auftrag „parallel“ ist in (i) **nicht erfüllt**, es gibt nur das Konzept. Sophie (5 T) und Stadt (5,5 T) haben freie Zeit, die aber nicht an den Engpass kommt: Sie schreiben kein GDScript für UI oder Sim.

### Szenario (ii): mit zweitem Gameplay/UI-Entwickler (N.N.) und UI-Artist, beide ab Tag 4
N.N. bringt von Tag 4 bis 12 netto 7,2 T, abzüglich 1,5 T Einarbeitung (S7-Lehre zu TEAM-02: „ein neuer Kopf ohne Einarbeitung kostet mehr, als er bringt“). Der UI-Artist arbeitet in Teilzeit mit ≈ 5 T.

| Person | Plan bis Freeze | Block D | Puffer | Überbuchung bis Freeze | Änderung gegenüber (i) |
|---|---|---|---|---|---|
| N.N. Gameplay/UI | 7,0 (+0,25 Kipp FZ-05) von 7,2 | Bugfix, Stretch Ziel-Marker 1 + WA-13b 0,5 | ≈ 1 von 9,6 | −0,05 mit Kipp | Einarbeitung 1,5, AT-10 1, FZ-04 0,5, SK-02 1, SK-03 2, FK-03 +0,5, QT-08 0,5 |
| UI-Artist | 2,5 | 0,5 | ≈ 2 | – | Einarbeitung 0,5, WA-16 1, SK-04 1 |
| Mira | 9,25 inkl. Kipp | 0 | 2,75 | +0,35 | − AT-10, − FZ-04, + Begleitung/Review N.N. 0,5 |
| Felix | 10,0 ohne / 10,5 mit FZ-05 | 0 | 1,5 | **−0,4 / −0,9** | + SK-02-Review 0,25 |
| Tobias | 9,75 | 0,25 | 2 | **−0,15** | SK-01 nach vorn (Block B), + SK-05 0,25 in D |
| Aylin | 9,35 | 1 | 1,65 | – | + SK-03 1 (WA-13b nur Stretch) |
| Sophie | 6,25 (− WA-16, + 1 Qualität Pferd/Frachtwagen) | 0,75 | 5 | – | − WA-16 an UI-Artist |
| Daniel | 8,75 | 2,75 | 0,5 | – | + SK-02/SK-03-Test 0,5, + SK-05-Lauf 0,25 |
| Katrin | – | – | 6,75 | – | + QT-14 1 |
| übrige | wie (i) | | | | |

**Ehrlich zu (ii):** Die zweite UI-Kraft löst den Mira-Engpass und macht den Skilltree baubar. **Felix bleibt in beiden Szenarien der kritische Pfad** (AT-01 → AT-02 → AT-07/08 → QT-03 → OE-02/03 → Gate C). Die Lücke dort heißt Simulations-/Tools-Entwicklung (`design.md` Rollen Punkt 2, `tech.md` §10), und die deckt (ii) nicht ab. Kommt N.N. nicht bis Tag 4, fällt (ii) automatisch auf (i) zurück: Die (ii)-Tickets sind genau die Kürzungen aus (i), es geht also nichts halb Gebautes verloren.

**Empfehlung an Basti: Szenario (ii)**, unter zwei Bedingungen: (1) Katrin schreibt die Rollenprofile bis Tag 2, und N.N. startet an Tag 4 mit der Datei `ui/skilltree_panel.gd` (keine Überschneidung mit `main.gd` oder `prototyp_welt.gd`). (2) Kein Fable, Sprint-Takt ans 5-Stunden-Limit angepasst (Retro S7). Ohne Ja bis Tag 2 gilt (i).

**Weitere fehlende Kompetenzen (nicht in (ii) enthalten):** Sim-/Tools-Entwicklung (Bot-Harness, Regressionsstufen; würde Felix um ≈ 1,5 T entlasten), 3 Fremdtester (n = 1 seit S3; die „3 Personen“ in den Akzeptanzkriterien sind heute Team-intern und damit befangen), Audio (1–2 T Kuration, S9), 3D-Modellierung Tiere/Fahrzeuge (Teilzeit 3–5 T, S9), KI-/Systemprogrammierung für Konkurrenz (ab S10).

---

## 6 Arbeitsblöcke (15 Tage)

Je Ticket ein Branch `s8/<ID>`, gemergt nur in `s8`. Nach jedem Commit läuft die schnelle Stufe, vor jedem Gate die volle Stufe. Dateibesitz steht in `VERTRAG.md`, das Katrin an Tag 1 nachzieht.

**Kollisionsregeln (disjunkte Dateien):**
| Datei | Block A | Block B | Block C | Block D |
|---|---|---|---|---|
| `main.gd` | Felix (AT-01, T1), danach Mira (`_toast`-Weiterleitung, T2–3) | **gesperrt** | gesperrt | nur Bugfix mit PO-Freigabe |
| `economy.gd` | niemand | **Tobias** (OE-05, FK-02-Ökonomie) | **N.N./Felix** (SK-02-Hooks, nur (ii), erst nach Gate-B-Merge) | Bugfix |
| `core/konto.gd`, `proto/proto_sim.gd`, `proto_easing.gd` | Felix | Felix | Felix | Felix |
| `proto/prototyp_welt.gd` | TA (Licht-Auslagerung T1, ein Commit), danach Mira | Mira | Mira | Mira |
| `proto/ui_welt.gd`, `ui/toast_queue.gd`, `ui/bankrott_warnung.gd` | Mira | Mira | Mira (+N.N. Linienliste als eigene Datei `proto/ui_linien.gd`) | – |
| `ui/skilltree_panel.gd` | – | – | N.N. (ii) | – |
| `regelwerk.json` | Felix (AT-04, `fahrzeug_easing`) | Stadt (WA-12, `gewaesser_kartentyp`) nach Gate A | – | – |
| `vehicles.json` | – | Felix (FZ-01, Werte Tobias) | Felix | – |
| `economy_proto.json` | Tobias | Tobias | Tobias | – |
| `proto_orte.json`, `stadt_*.py`, Wege/Instanzen | Stadt | Stadt | Stadt | – |
| Terrain-Shader, `ta_export.py`, `proto_prefab.gdshader`, `world/proto_licht.gd` | TA | TA | TA | TA (Kanban) |
| `ui/fehlertexte.gd` | – | Aylin (nur Texte) | Aylin | – |
| neue Tests | Daniel; der Ticket-Owner passt die eigenen Suiten an | | | |

**Block A (Tag 1–3): Fundament.** Felix: AT-01 (T1), AT-04 (T2), QT-01-Anteil, QT-04 bei Repro. Mira: Wartet bis T1 Mittag auf TA (Licht), dann AT-05, AT-06, `_toast`-Weiterleitung, Start AT-07 gegen die API-Signaturen aus AT-01. Daniel: QT-01 (T1 Baseline zuerst), QT-04, QT-02 nachts. Tobias: OE-01 mit Lena, FK-01, AT-04-Overlay. TA: WA-03 (Auslagerung T1), WA-02, FZ-07-Vertrag. Stadt: WA-07, WA-09, WA-11. Aylin: WA-01 (T1), AT-14, QT-07 L1. Sophie: Stilrahmen Boden, CC0-Auswahl, Pferd-Lizenzprüfung. Katrin: QT-11-Blocker-Check (T1), (ii) QT-14.
**Gate A (Ende T3):** volle Regression grün, Slice bitgleich (d08-CSV-diff leer, parity 8/8, slice 74/74), Proto-Suiten in d07, schnelle Stufe < 5 min (3× gemessen), Welt startet über den Knopf, Pause/Tempo und `--tempo_k` wirken, Licht neu. **Zwischenstand L1 für Basti an Tag 4 (10 min):** Start, HUD-Screenshot, Tempo A/B k = 4/8 mit Stoppuhr, 3 Hügel/Senken, Stellen per F12.

**Block B (Tag 4–8): Ich betreibe die Kette.** Felix: AT-02 (T4–5), AT-03, FZ-01, FZ-02, WA-08-Anteil. Mira: AT-07, AT-08, AT-09. Tobias: OE-05 + FK-02 in `economy.gd` (allein), OE-02 ab Bot n = 20. Daniel: QT-05, QT-03-Gerüst. TA: FZ-09 (nach AT-04), WA-04 an Bastis Stellen, WA-12-Anteil, WA-13a. Stadt: WA-08, WA-10, WA-12, WA-15. Sophie: FZ-06, WA-08, FZ-08, WA-16. (ii) N.N.: Einarbeitung, AT-10. Mitte-Refinement T8 (Jonas, 1 h): Kipp-Entscheid FZ-05.
**Gate B (Ende T8):** play_welt „Loop L2“ grün (≤ 120 s), 0 stumme Fehler, Bot n = 20 läuft, Konto-/Paritätstest grün, `economy.gd`-Merge von FK-02. **Zwischenstand L2 für Basti an Tag 9 (20 min):** Kette selbst anlegen, 2. Fuhrwerk, Kredit ab Minute 12, Gewinn je Linie, Boden/Placement vorher/nachher an den eigenen Stellen.

**Block C (Tag 9–12): 45 min ohne Plateau + Stränge E/F.** Felix: FK-02-Anteil (konto/proto), FZ-03, FZ-04, FZ-05 (Kipp), AT-11-API. Mira: AT-10 (i), AT-11, AT-12, AT-13, FK-03. Tobias: OE-02/03 mit n = 300, OE-04 (T11). Daniel: QT-03 n = 300 nachts, X1–X3. TA: WA-05 (Kipp), FZ-07-Patina, FK-05. (ii) N.N.: SK-02 (economy.gd ab T9), SK-03, QT-08, FK-03-Zusatz, FZ-04; UI-Artist SK-04.
**Feature-Freeze Ende T12. Gate C:** Bankrott-Band, Lücke P90 ≤ 3 min, X1 grün (Bot n = 300), F2-Schwelle mit Messdatum, volle Regression grün, Perf-Budget hält. Was bis T12 nicht grün ist, wird nach §8 gekürzt und nicht verlängert. **Zwischenstand L3 für Basti an Tag 13 (45 min):** freies Spiel, Interessenkurve alle 5 min, Toast „verstanden ja/nein“, 5 Schlussfragen.

**Block D (Tag 13–15): Abnahme.** Daniel QT-09 (eigener L3-Lauf T13 früh, vor Basti), alle nur Bugfix aus Abnahme und L3, TA Kanban (WA-05 falls gekippt, Perf), Lena/Aylin FK-04 und (i) SK-01, Stretch nur aus Puffer auf eigenem Branch. T15: Review, Retro, volle Regression, Push `s8`.

---

## 7 Definition of Done, Review und Retro

**DoD je Ticket:**
1. **Regression:** schnelle Stufe (`regress_fast.sh` < 5 min) grün je Commit. Vor dem Merge ins Gate die volle Stufe (`d07_regression.sh` inkl. Proto-Suiten, d08 n = 100) grün. Slice bitgleich (md5/CSV). Statischer Kassen- und Tempo-Check grün. Timeout zählt als FAIL.
2. **Abnahme** durch die benannte Rolle: Sim/Ökonomie Tobias, UI-Text Aylin, Look Sophie, Bild-Messung TA, Validator Stadt, Gesamt Daniel. Jede Zahl im Kriterium mit Messart (gemessen/gezählt/berechnet/Annahme). „ABW bewusst“ nur mit Ablaufdatum.
3. **Doku:** Ticket-Bericht in `sprints/s8/umsetzung/<ID>.md` (was, Messwerte, Befehl), Dateibesitz in `VERTRAG.md`, Entscheidungen im Log mit „revidierbar bis/durch“.
4. **Lernlog:** eine Zeile im LERNLOG der Rolle, falls ein Kompromiss, Workaround oder „wusste ich nicht“ vorkam.
5. **Basti-prüfbar:** Erreichbar über den Startknopf, auf einer Aufgabenkarte (L1/L2/L3) mit Schritt und Abfrage. Nicht Bewiesenes steht als „nicht bewiesen“ auf der Karte.

**DoD Sprint:** Sprintziel je Kriterium ja/nein mit Messart. L3 von Basti ausgewertet (oder, falls bis T15 nicht zurück, „offen“ mit Datum). `s8` gepusht, `main` unberührt.

**Review (T15, Jonas, 1 h):** Sprintziel Punkt für Punkt; Bot-Tabelle; Bastis L1–L3 (Interessenkurve gegen Bot-Lücke: weichen sie ab, gilt Basti); Boden vorher/nachher; Kipp-Tickets; Backlog S9 (Speichern, Stichweg, C2, Depot, Skilltree-Baum, BT-4/RL-2). Zusammenfassung für Basti ≤ 1 Seite mit Screenshot-Set und Startweg.
**Retro (T15, Katrin, 1 h):** S7-Maßnahmen prüfen (Tests auf der echten Karte, gleiche Regel in Spiel und Anzeige, kein Fable); Plan/Ist je Ticket → **erste Referenzklasse** (Velocity); Freeze-Rechnung 9,6 T: hat sie gehalten?; Lernlog-Zähler (A-08 Zähler 4, Platzhalter-Schwellen Zähler 3, Slice-Kalibrierung Zähler 5); Wirkung der neuen Rollen in (ii).

---

## 8 Streichliste, Verschiebung, Risiken

### Kürzungsreihenfolge, falls ein Gate reißt (in dieser Reihenfolge)
1. FZ-05 Folgemodell (Kipp, −0,75 T Dev). 2. WA-05 Ufer → Kanban Block D. 3. (ii) SK-03 auf 1 Ast mit 3 Knoten (−1). 4. FK-03 auf Knopf + Toast (−0,25). 5. AT-11 Diagnose-Katalog auf 3 Fälle (−0,5). **Nie gekürzt:** AT-01/02, AT-04, QT-03, OE-02/03, A-08-Grundfall (wartet auf Ladung).

### Verschoben nach S9 (mit Grund)
| Punkt | Aufwand | Grund |
|---|---|---|
| Speichern/Laden | 3 T [E] (Tech) | Nie serialisierte SoA-Strukturen; Basti spielt am Stück (W6) |
| Stichweg P3 bauen | 3,25 T [E] | Höchstes Unbekanntes, kein Basti-Wunsch; Spike als Stretch (W4) |
| C2 Rivalenfirma bauen | ≈ 4 T [R] | Besitzerfeld an Fahrzeugen/Lizenzen und Skript-Rivale fehlen; Spec in S8 (FK-04) |
| Depot mit Depotfahrt | 4 T [E] | Kerneingriff, Parität (W7) |
| Skilltree als Baum, 6 Äste, Ausstoß-Ränge, Epoche II | > 5 T [E] | Mira-Engpass; Ausstoß verpufft unter Sättigung (W17) |
| Bodenkarte 5 m (BT-4), Relief-Amplitude (RL-2) | 2 / 2 T [E] | TA voll; nur eines von beiden wäre machbar, und die Entscheidung fällt erst nach L2 |
| Ortsschild-Status (nur (i)), Testmodus (nur (i)) | 1,25 / 0,5 T | Mira-Engpass |
| D7-O2 Eigenversorgung/Konkurrenzanteil als Datenfeld | 0,25 T | Tobias voll; gleiche Mechanik wie Konkurrenz-Platzhalter |
| Firmenfarben-Palette für KI | 1,5 T [E] | erst mit C2 |
| Stadtwachstum (E4/F3), Lager (P4), Ausfall/Zuverlässigkeit | 1,5–2 / 1 / 1,5–2,5 T | SOLL/KANN, ohne Platz |
| Audio, `main.gd`-Aufteilung, InputMap/Fokus, `tr()` | – | Kein Loop-Wert in S8 |
| Windows-Build | 1,5 T | nur Stretch; Templates fehlen [M] |

### Gestrichen in S8 (Won't)
Konkurrenz als Spielfigur (6–10 T, frühestens S10), Personen-Sim/Postkutsche mit Ertrag (> 5 T), zweite Kette (D4), Gleis in der Welt (W10), freier Wegebau als Spline-Netz, Fischerei/Seenutzung (D-W), Ast-XP (D-S), Generator auf der Vollkarte, Stadt-KI über 60 Monate.

### Risiken (Top 8)
| # | Risiko | Wahrscheinlichkeit/Wirkung | Gegenmaßnahme |
|---|---|---|---|
| R1 | Felix/Mira-Engpass auf dem kritischen Pfad, beide ohne Puffer bis zum Freeze | hoch/hoch | Szenario (ii); Kipp FZ-05 am Mitte-Refinement T8; Kürzungsreihenfolge oben; `main.gd` ab T3 gesperrt |
| R2 | Tempo k kippt die Kalibrierung (T-15/T-16 ungültig), und n = 300 × 27.000 Ticks ist in der Laufzeit nicht gemessen | hoch/hoch | Bot nachts ab T6 mit beiden k; Basti entscheidet k an T4–5 (D2); Laufzeit n = 20 an T6 messen und auf n = 300 hochrechnen, bei > 6 h n = 150 mit Wilson-Intervall offen benennen |
| R3 | Bot als Proxy (Goodhart): Der Plan-Bot spielt den eigenen Fahrplan | mittel/hoch | Drei Strategien; Interessenkurve von Basti (L3) gilt bei Abweichung; Daniel spielt L3 selbst |
| R4 | Konto-Herauslösung bricht die Slice-Parität | mittel/hoch | Spike T1 mit Zeitbox 4 h; Rückfall Zwillingstest (+0,25); Allowlist W12 |
| R5 | Bastis Stellen (Boden/Placement) kommen nicht oder spät | mittel/mittel | 8 eigene Standorte ab T5; Metriken unabhängig von Basti; Vorher/Nachher in L2 |
| R6 | Regressionslaufzeit unbekannt (Platzhalter in tech.md) plus 5-Stunden-Limit | mittel/mittel | QT-01 misst an T1; schnelle Stufe < 5 min; volle Stufe nur nachts und vor Gates; kein Fable |
| R7 | FK-02 (Kauf + Werksausbau) nicht grün bis Gate C → Farm 2 wirkungslos, Plateau | mittel/hoch | Rückfall W3 ohne Kosten (Durchsatz 40 in `economy_proto.json`); Mahlrecht-Knoten als Alternative in (ii) |
| R8 | n = 1 (Basti) und Team-interne Personenproben; Basti kennt das Konzept | hoch/mittel | Frage 6 an Basti (3 Fremdtester); in jeder Abnahme die Messart „Team-intern“ angeben; nicht Bewiesenes benennen |

Weitere, nicht in den Top 8: Pferd-Lizenz (Quaternius) ungeklärt → Behelf bleibt. COLOR-Kanal von drei Zwecken belegt → Vertrag FZ-07 vor dem ersten Merge. Zwei Uhren machen Zinsangaben mehrdeutig → Zins heißt im UI „je Minute“. P-Menü-Absturz unbekannt → QT-04.

---

## 9 SPRINTSTART (unbeaufsichtigte Ausführung)

**Branch:** `s8` von `main` (HEAD dc14304 oder neuer, Hash im ersten Bericht notieren). Je Ticket `s8/<ID>`, Merge nur nach `s8`. Push nur `s8` und `s8/*`. Godot: `G=/tmp/claude-0/gd/Godot_v4.7.2-stable_linux.x86_64`. Arbeitsverzeichnis: Klon des Repos (`d07_regression.sh` schreibt Logs nach `slice/tests/d07_logs/`, das gehört auf den Branch und nicht nach `main`).

**Erste 8 Aufgaben (Block A, in dieser Reihenfolge, 1–3 und 5 parallel möglich):**

1. **QT-01a Baseline (Daniel, T1 früh).** Vor jeder Codeänderung: `cd slice && time bash tests/d07_regression.sh "$G"`. Dann je Proto-Suite `time timeout 900 "$G" --headless --path . -s res://tests/<suite>.gd` für proto_sim_test, proto_easing_test, proto_band_hoehe_test, proto_fixpass_test, proto_schilder_test, proto_mass und, falls vorhanden, proto_welt/proto_terrain/proto_strassenband (Liste mit `ls tests/proto_*` prüfen). Dazu `"$G" --headless --path . -s res://tests/d08_bankrott.gd -- --n=20 --csv=../sprints/s8/umsetzung/baseline/d08_n20.csv` und `md5sum`. **Akzeptanz:** `sprints/s8/umsetzung/baseline.md` mit Tabelle Suite | Exit | Laufzeit s | Commit-Hash; d08-CSV und md5 eingecheckt. **Abbruch:** eine Bestandssuite rot auf `main` → stoppen, nichts ändern, Befund an Jonas (die Baseline ist dann keine).
2. **QT-11 Blocker-Check (Katrin, T1).** `ls ~/.local/share/godot/export_templates` (heute leer), Godot-Version (`"$G" --version`), Wine vorhanden (`which wine`), Token-Budget je Agent. **Akzeptanz:** Blockerliste in `sprints/s8/umsetzung/blocker_t1.md`. **Kein Download von Templates oder Wine ohne Basti** (Fremdbinärdateien, Lizenzprüfung).
3. **WA-03a Licht auslagern (TA, T1, ein Commit).** Licht- und Umgebungsaufbau aus `proto/prototyp_welt.gd` (Z. 177–195) nach `world/proto_licht.gd` verschieben, **Werte unverändert**. **Akzeptanz:** Testfall liest Sonnenwinkel, `light_energy` 0,52 und Umgebungslicht 0,36 und vergleicht sie mit den alten Werten; `proto_shots`-Lauf ohne SCRIPT ERROR. Test: `timeout 600 "$G" --headless --path . -s res://tests/proto_schilder_test.gd` + schnelle Stufe. Danach gibt TA `prototyp_welt.gd` an Mira ab.
4. **AT-01 Konto-Spike (Felix, T1, Zeitbox 4 h).** Neu `slice/core/konto.gd` (RefCounted: `running_cost_per_period`, `cost_acc`, `expenses_total`, `bankrupt`; `charge(cent)`, `fix_neu(...)`, `tick(tick, credit) -> bool` in der Reihenfolge aus `main.sim_tick` Z. 3138–3148). In `main.gd` nur `charge` (Z. 3105), `_recompute_running_cost` (Z. 3110) und den Kostenblock von `sim_tick` (Z. 3121–3154) umstellen; Felder als Weiterleitung. **Akzeptanz:** d08 `--n=20` CSV `diff` gegen Baseline leer; `bash tests/run_tests.sh "$G"` → parity 8/8, slice_test 74/74; `grep -rnE 'cash_cent\s*[-+]=' --include=*.gd slice | grep -v tests` nur in economy.gd, credit.gd, core/konto.gd sowie `main.gd` Z. 2714/2783 (Allowlist W12). **Abbruch:** CSV-Diff nach 4 h oder eine 4. `main.gd`-Funktion nötig → Rückfall: `konto.gd` nur für die Welt, `main.gd` zurücksetzen, Zwillingstest in d07 (+0,25 T), Bericht an Jonas.
5. **QT-01b Stufen + Checks (Daniel, T1–2).** `slice/tests/regress_fast.sh` (run_tests, d07_abnahme alle Blöcke, d08_lizenzfaktor, s7_boot ×2, alle Proto-Suiten, statische Checks Kasse W12 + Tempo W1: `fuhrwerk_e1`/`frachtwagen_e1` ohne `tempo_mm_pro_tick`); in `d07_regression.sh` die Proto-Suiten ergänzen; `timeout` je Godot-Aufruf = 3 × Baseline-Laufzeit, in `tools/play.sh` `timeout 300`. **Akzeptanz:** fast < 300 s in 3 Läufen; ein absichtlich hängender Testfall erzeugt eine FAIL-Zeile mit Text „TIMEOUT“. Test: `time bash tests/regress_fast.sh "$G"` ×3.
6. **AT-04 Tempo k (Felix, T2).** In `world/data/proto/regelwerk.json` unter `fahrzeug_easing` das Feld `tempo_k` (Standard 1, Varianten [4, 6, 8]) anlegen; ProtoSim (`proto_sim.gd` Z. 306) setzt `v_nom = sim_felder_je_tick_promille / k` für Fuhrwerk und Postkutsche; Nutzerargument `--tempo_k=`; `tests/proto_sim_test.gd` Z. 63 auf `600 / k`; Overlay `slice/data/economy_proto.json` mit `tempo_ausgleich_promille` 1.000 (Tobias). Fristen nicht skalieren. **Akzeptanz:** `timeout 600 "$G" --headless --path . -s res://tests/proto_easing_test.gd -- --tempo_k=4` und `=8`: E5 0 Verstöße, E6 ≤ 1,3 × W/2 (sonst ABW mit Datum); proto_sim_test grün bei k = 1/4/8; Slice md5 unverändert; Umlauf Farm→Mühle in Ticks je k im Ticket-Bericht.
7. **AT-05 Pause/Tempo/Datum (Mira, T2–3, nach Aufgabe 3).** In `proto/prototyp_welt.gd` `sim_tempo` ∈ {0, 1, 2, 4} (Leertaste; Knöpfe; **nicht** die Tasten 1–5); Datum aus dem Kalender-Platzhalter (bis FZ-02: Monat = 600 Ticks). **Akzeptanz:** neuer Testfall: Pause → 0 Ticks in 10 s; 4× → 40 ± 1 Ticks/s bei ≥ 20 fps (Zähler, xvfb). Test: schnelle Stufe.
8. **AT-06 Startknopf + QT-04 P-Menü (Mira/Daniel, T3).** Daniel versucht zuerst die Reproduktion (`start_menu.gd` Z. 136–137, Welt über Taste P laden, xvfb, 5 Starts). Dann setzt Mira den Knopf „Welt spielen (Loop S8)“, der dieselbe Szene lädt. **Akzeptanz:** s7_start erweitert (Knopf sichtbar, 5/5 Starts ohne SCRIPT ERROR); QT-04-Bericht mit Repro-Schritten oder „nicht reproduziert, 5/5 Starts“. Danach Gate-A-Lauf (volle Stufe).

**Abbruchkriterien (Sprint-weit, dann anhalten und Jonas/Basti berichten):**
- Eine Bestandssuite wird rot und ist nach 2 Fix-Versuchen nicht grün (Trigger h).
- Slice nicht mehr bitgleich (d08-CSV-Diff, parity < 8/8, md5 der Slice-Daten).
- Ein Gate reißt um mehr als 1 Tag; dann nur die Kürzungsreihenfolge (§8), keine Verlängerung.
- Ein Ticket braucht mehr als das Doppelte seiner Schätzung; dann Stopp und Entscheidung am nächsten Morgen.
- Token-/5-h-Limit eines Agenten zu 80 % verbraucht; dann sauber committen und den Stand übergeben.
- Perf-Gate +10 % über Budget (1,0 M Dreiecke/300 DC Übersicht, Ladezeit ≤ 3 s).

**Was NIE ohne Basti geschieht:**
- `main` pushen, mergen oder umschreiben; Default auf die Welt umstellen.
- Brüche im Spielstand- oder Datenformat: Schema von `economy_slice.json`, `economy_constants.json`, `vehicles.json`-Bestandsdatensätze (`lkw_e1` u. a.), Umbenennen oder Entfernen von Feldern. Neue Dateien (`economy_proto.json`, `ziele_welt.json`, `skilltree.json`) und neue Datensätze sind erlaubt.
- Löschen von Dateien, Tests, Assets oder Branches; `git push --force`, `reset --hard` auf geteilte Branches.
- Lizenzen: kein neues Asset ohne geprüfte Lizenzzeile (CC0 oder belegt); kein Einbau des Quaternius-Pferds, solange die Lizenz nur aus einer Repo-Notiz bekannt ist; kein Download von Binärdateien (Export-Templates, Wine).
- Fable-Läufe; neue Rollen (Szenario ii) starten; Annahmen D1–D-R als Entscheidung ins Log schreiben (sie bleiben „Annahme“).

---

## Fragen an Basti (eine Antwort je Frage genügt)
1. **Szenario (ii) mit zweitem Gameplay/UI-Entwickler und UI-Artist ab Tag 4?** Empfehlung: ja. Nur so kommt der Skilltree in S8 ins Spiel. Arbeitsannahme bis Tag 2: (i).
2. **Tempo k:** Entscheidest du in L1 (Tag 4) zwischen 4 und 8? Empfehlung: ja. Ohne Antwort bis Tag 5 setze ich k = 6.
3. **Stichweg (Bauen) in S8?** Empfehlung: nein, nur Spike. Preis: Pfeiler 2 bleibt ungetestet. Wenn ja: +3,25 T, dafür fallen Folgemodell und C1-UI.
4. **Firmenkauf = C1 inkl. Ausbau der Mühle auf 40 E/min, C2 nur als Spec?** Empfehlung: ja.
5. **Kutschen:** In S8 nur Fuhrwerk und Frachtwagen kaufbar, die Postkutsche bleibt Kulisse (keine Passagiere). Einverstanden? Empfehlung: ja.
6. **Gibt es 3 Fremdtester für L3 (45 min, das Konzept nicht kennen)?** Ohne sie bleibt n = 1.
7. **Binsensee auf Teichgröße (≤ 150 m) verkleinern?** Empfehlung: ja (deine Regel vom 03.11.).
8. **Stellenliste Boden/Placement:** Format A liegt an Tag 1 bei dir, ab L1 nimmst du F12. Bis Tag 4 genügen 5 Stellen.

## Lernlog-Vorschläge (Repo nur gelesen, daher hier vorgemerkt für `sprints/s8/fortbildung/mt-po/LERNLOG.md`)
| 2026-11-05 | Refinement S8 | Kapazität gegen 12 T statt gegen 9,6 T bis zum Freeze geplant (Beiträge Tech/UX/Design) | 1 | Regel: Feature-Kapazität = Tage bis Freeze × 0,8 |
| 2026-11-05 | Refinement S8 | Beitrag mit leeren Messplatzhaltern (`tech.md` `__REG__`) | 1 | Platzhalter-Grep vor der Konsolidierung |
| 2026-11-05 | Refinement S8 | „Stufe“ dreifach belegt (Kauf/Werk/Konkurrenz) | 1 | Begriffe im ADR FK-01 |
| 2026-11-05 | Refinement S8 | A-08 diesmal im Sprintziel, nicht verschoben | 4 → Abschluss, falls S8 liefert | – |
