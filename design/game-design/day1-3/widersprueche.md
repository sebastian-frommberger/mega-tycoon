# Widersprüche in den Konzeptdateien (Prüfung Tag 1–3)

## Stand 23.11.2026 nach D1–D14 (`sprint2/decisions_19-11.md`)

Entschieden = PO hat festgelegt; „eingepflegt“ = steht in der Konzeptdatei. Gate-relevant (H1: 1, 4, 5, 7, 12, 21, 23) sind 7/7 entschieden. Der Satz „entschieden ist keiner“ in der Einleitung unten gilt nur für den Stand 18.11.

| # | Status | Durch | Eingepflegt | Rest |
|---|---|---|---|---|
| 1 | entschieden | D1 (Option A, Testannahme) | `lena.md` Phase 1 (23.11.) | revidierbar nach L-05 (25.11.); `hq.md`/`industry.md` Satz und Tabelle bis GDD |
| 2 | entschieden | D1 (Rabatt einmalig M5b) | `lena.md` Meilenstein 5b | `hq.md` Tabelle „Kaufrabatt“ streichen bis GDD |
| 3 | teilweise | D12/D13 nutzen `hq.md`-Zählung (1a/1b, 5b, 7) | `lena.md` auf hq-Nummerierung (23.11.) | `industry.md` („Meilenstein 5“) bis GDD |
| 4 | entschieden | D13 (M3 = Endprodukt an Abnehmer) | `lena.md` (23.11.) | Tobias' Werkzeugfabrik-Annahme markiert |
| 5 | entschieden | D13 (5.000 $/min gestrichen, Ziel HQ-Stufe 2, Zahl mit Ausbaupfad M1) | `lena.md` (23.11.) | `hq.md` Zielwert-Satz bis GDD; Ausbaupfad M1 |
| 6 | **offen** | – | – | Ausgleichslogik `hq.md` neu begründen (Lena, GDD) |
| 7 | entschieden | D12 | `leitplanken.md`, `lena.md` (23.11.) | Freigabe des Eintrags durch Jonas |
| 8 | vertagt | D1: „60-k-Skala: M1“ | Hinweis in `lena.md` | M1 |
| 9 | **offen** | – | – | Lesart Werksmarge (Tobias, Lena) |
| 10 | entschieden | D1 (Spielminuten im VS) | L-05-Material | Release-Entscheidung später |
| 11 | **offen** | – | – | Kohle-Zufluss im Modell (Tobias), nicht im Sprint |
| 12 | entschieden | D13 (Tor erst Kleinstadt→Stadt, Bau-Rohstoff im Radius garantiert) | `lena.md` (23.11.) | `city.md`, `hq.md` bis GDD |
| 13 | entschieden | D4 (+0,5-%-Regel gestrichen) | – | `industry.md`, `city.md` (Tobias) |
| 14 | entschieden | D4 (Variante B, 1,8 %, +25 %, „ungetestet, Grey-Box Januar“) | – | `city.md` (Tobias) |
| 15 | **offen** | – | – | Metropole-Zeile (Lena, GDD) |
| 16 | **offen** | – | – | Zielzeiten je Archetyp (`hq_startwerte.md`), Tobias |
| 17 | **offen** | – | – | `lena.md` auf 4 Epochen (Jonas bestätigt), GDD |
| 18 | im Material gelöst | L-05: Gratis-Lizenz zählt als dritte (Seehafen hat nur 2 Industrien); K2 zählt ohnehin nicht (G5) | `day4-6/lena/l05_material.md` | Konzeptsatz in `hq.md` bis GDD |
| 19 | **offen** | – | – | Radius des Lizenzrabatts (Lena, Tobias) |
| 20 | **offen** | – | – | Begriff Spezialisierung/Fokus (GDD) |
| 21 | entschieden | K6 / D3 (Fehlerliste = Spike S1–S3) | `day4-6/lena/l06_fehler_final.md` | Daniel streicht Quellenzeile |
| 22 | entschieden | D9 (ein Namensraum = Felix' Enum, UI-Tabelle) | `l06_fehler_final.md` | Felder nicht geliefert (Annahme, 23.11.) |
| 23 | entschieden | D3 (6 darstellbare Szenarien, Tick-Schwelle gestrichen) | `gate_kriterien.md` G3 | Daniels Prüfplan |
| 24 | im Material gelöst | 4 Stadtkarten, Spieler pinnt 3 | `l05_material.md` | – |
| E (HQ-Fragen 1–3) | **offen** | – | – | kein Sprintthema; Annahme im Papier: alle 4 Archetypen auf der Karte |

Bilanz (24 Punkte): 12 entschieden (1, 2, 4, 5, 7, 10, 12, 13, 14, 21, 22, 23), 1 vertagt (8), 1 teilweise (3), 2 im Testmaterial gelöst (18, 24), 8 offen (6, 9, 11, 15, 16, 17, 19, 20) plus E. Die offenen sind alle „vor dem GDD“, keiner Gate-relevant.

---

Lena Hoffmann · geprüft: `concept/{hq,industry,city,tobias,lena,leitplanken}.md`, `plan/lena.md`, `refinement/ergebnis.md`, Sprint-2-Dateien von Tobias, Aylin, Felix, Daniel, Jonas (Stand der Dateien vom 18.11.). Nicht geprüft: `concept/{aylin,felix,jonas,sophie}.md` Zeile für Zeile, nur die Stellen, die diese Tickets berühren. Jeder Punkt hat einen Vorschlag, entschieden ist **keiner**.

## A. Lizenz/Kauf-Leiter und Ökonomie (hoch, berühren Gate G5)

| # | Stelle | Widerspruch | Folge | Vorschlag (wer entscheidet) |
|---|---|---|---|---|
| 1 | `industry.md` „Startkapital reicht für 3 Lizenzen oder knapp 1 Kauf“ gegen `hq.md` Startkapital 15–30 k $ gegen Kaufpreise 1–4 k $ × Stufe | 3 Lizenzen kosten 17–18 % eines Kaufs, das hq-Kapital reicht für 6–15 Käufe. Der Satz stimmt in keinem Teil. | Leiter nicht konsistent (Gate G5) | Option A von Tobias: Startkapital 4.500 / 4.500 / 7.000 / 5.000 $, Satz neu fassen (`hq_startwerte.md`). Alternativ Option C. (Lena, Jonas, Tobias) |
| 2 | `hq.md` Tabelle: „Kaufrabatt −20 % bei jeder lizenzierten Firma im Radius“ gegen `hq.md` Meilenstein 5b: „Belohnung: Kaufrabatt −20 % auf die nächste“ | Dauerregel oder einmalige Belohnung? Als Dauerregel macht Rabatt plus 50 % Anrechnung „erst Lizenz, dann Kauf“ billiger als Direktkauf (0,87 × statt 1,00, Tobias). | Direktkauf nie wegen Preis sinnvoll | Einmalige Belohnung bei 5b (Lena, Tobias) |
| 3 | Meilenstein-Nummerierung: `lena.md` (1 „Erste Firma kaufen“, 5 Lager, 7 „zweite Firma vergünstigt“) · `hq.md` (1a/1b, neu 5b Firmenkauf, 7 = HQ-Stufe 2) · `industry.md` („Firmenkauf rückt auf Meilenstein 5“) | Drei Zählungen für denselben Ablauf. 5 ist Lager (`lena.md`), Firmenkauf (`industry.md`) oder 5b (`hq.md`). | Onboarding-Leiste und Tests zeigen verschiedene Nummern | `hq.md`-Nummerierung (1a, 1b, …, 5b, 7) als einzige übernehmen, `lena.md` und `industry.md` anpassen (Lena, bis GDD) |
| 4 | `lena.md` Meilenstein 3 „Endprodukt in Stadt liefern“ gegen Bergbau-Start (Kleinstadt 2.500, Warenkorb Nahrung + Bau) | Die Kleinstadt fragt keinen Stahl nach, Werkzeug erst ab Stadt (5.000 Einw., im Bergbau nach ca. 36 min). Meilenstein 3 ist am Start nicht erreichbar. | Bergbau-Onboarding blockiert | Meilenstein 3 = „Endprodukt an Abnehmer geliefert (Stadt, Export oder nächste Verarbeiterstufe)“. Tobias' Modell nimmt eine Werkzeugfabrik als Abnehmer an (Annahme, 40 E/min). (Lena, Tobias) |
| 5 | `hq.md` Zielwert: alle Archetypen erreichen Meilenstein 7 (5.000 $/min) nach 35–50 min, ±15 % | Erste Kette bringt 399–844 $/min (Tobias, von mir reproduziert), 5.000 $/min entsprechen 5,9 bis 12,5 solchen Ketten. Das Modell kennt keinen Ausbaupfad. Spanne zwischen Archetypen 2,1 ×. | Zielwert nicht belegt | Ausbaupfad (Stufe 1–4) in T-04/T-05 ergänzen, dann Zielzeit neu setzen (Tobias, Lena) |
| 6 | `hq.md` „Kapital, Fahrgäste und Rohstoffnähe gleichen sich aus“ (Agrar 30 k, Bergbau 25 k, Handel 20 k) gegen T-05 | Nach der Rechnung folgt das Kapital dem Kaufpreis des Verarbeiters: Bergbau braucht am meisten (7.000 $), Agrar am wenigsten (4.500 $). Reihenfolge dreht sich. | Begründung der Archetypen fällt weg | Ausgleichslogik neu begründen: Kapital = Pflicht, Ausgleich über Ausbau und Fahrgäste (Lena) |
| 7 | `leitplanken.md` „Start durch Firmenkauf. Laden nur bei eigenen Firmen“ (als getroffene Richtungsentscheidung) gegen `hq.md`/`industry.md` (Lizenz, später Kauf) und `lena.md` Run-Phase 1 „Firmenkauf“, Meta-Loop 1 „Firma kaufen → Einfluss entsteht“ | `industry.md` benennt die Abweichung, `lena.md` ist nicht angepasst. | GDD widerspricht sich in Kapitel Core/Meta-Loop | Leitplanken-Satz durch Jonas als geändert freigeben, `lena.md` Phase 1 auf „HQ und Lizenzen“ (Jonas, Lena) |
| 8 | `lena.md` Erfahrener Start (Meilensteine 1–6 erledigt, 60.000 $, zwei Startfirmen) gegen `hq.md` (HQ Stufe 2, 1 Niederlassung, 60.000 $, 2 gekaufte Firmen + 2 Lizenzen). Preise: HQ-Stufe 2 = 12.000 $, Stufe 3 = 30.000 $, Niederlassung 15.000 $ + 150 $/min | Zwei Fassungen. Bei Startkapital 4.500 $ steht die 60.000-$-Marke im Verhältnis 13 : 1 (Agrar), die Niederlassung mit 150 $/min kostet 18–38 % einer ersten Kette. | Skala der Meta-Ebene unklar | Nach Entscheidung zu Punkt 1 neu setzen, eine Fassung behalten (Lena, Tobias) |
| 9 | `industry.md` Werksmarge „auf alles, was Abholer (auch die KI) damit verdienen“ gegen T-05 (Lesart: Zuschlag auf Transportertrag **eigener** Fahrzeuge) | Die Lesart ändert die Rechnung: „nur Fremdabholer“ macht Besitz noch weniger attraktiv (Tobias). | Break-even unsicher | Lesart festlegen (Tobias, Lena) |
| 10 | `industry.md` Offene Frage 1 / `plan/lena.md`: Lizenzlaufzeit 30 Spielminuten oder Spieljahre | Bei Zeitraffer bleibt die Laufzeit in Minuten nicht stabil. | Abrechnung bei Zeitraffer | Spielminuten für den Vertical Slice, Entscheidung für Release später (Jonas) |
| 11 | `tobias.md`: Stahlwerk braucht Erz **und** Kohle gegen T-05-Modell Bergbau (nur Erz-Zufluss) | Stahl ist ohne Kohle nicht herstellbar, der Kettenertrag im Modell ist zu hoch angesetzt oder die Kohlemine fehlt in der Kostenrechnung. | Bergbau-Zahlen unsicher | Zweiten Zufluss modellieren (Tobias) |
| 18 | `hq.md` „Gratis-Lizenz verbrennt kein Startkapital“ gegen T-05 (3 Lizenzen ohne Gratis gerechnet) | Mit Gratis-Lizenz reicht das Kapital weiter, Tobias rechnet das schlechtere Szenario. Unterschiedliche Lesarten desselben Satzes. | L-05-Zählung (3 Lizenzen) | Im Paper-Test: 3 bezahlte Lizenzen als Bedingung, Gratis-Lizenz zusätzlich (Lena) |
| 19 | `hq.md` Lizenzrabatt „im Radius −30 %“ gegen `industry.md` „Lizenz = halber Einflussradius, Kauf = voller“ | Gilt der Rabatt im vollen oder im halben Radius? | Preise am Radiusrand | Lizenzrabatt gilt im vollen Radius, Einfluss der Lizenz im halben (Lena, Tobias klärt Modell) |

## B. Städte und Wachstum

| # | Stelle | Widerspruch | Folge | Vorschlag |
|---|---|---|---|---|
| 12 | `city.md` Stufen-Tor (bei 95 % der Schwelle Halt, bis Bau ≥ 25 % versorgt) gegen `hq.md` Agrar-Start (Dorf 900 Einw., nur Getreide + Vieh im Radius) | Das Tor liegt bei 950 Einw., rund Minute 3. Der Agrar-Start hat keine Bau-Kette in Reichweite. Das Dorf steht, bis Bretter geliefert werden. T-04 rechnet für Agrar 6 min ohne Tor. | Agrar-Onboarding stockt | Eine Bau-Rohstoff-Kette (Holz) im Agrar-Radius garantieren, oder das Tor beim Start ausnehmen (Lena, Tobias) |
| 13 | `city.md` W = … + 0,15 × Arbeitsplätze gegen `industry.md` „+0,5 %/Monat bei Fabrik im Pendlerradius“ und `tobias.md` Pendler 80 % / 110 % Produktivität gegen `industry.md` Arbeitsfaktor 0,5 + 0,6 × Pendlerdeckung ab Stufe 3 | Arbeitsplätze zählen doppelt (W und +0,5 %). Pendlereffekt hat zwei Formeln (die Abweichung ab Stufe 3 ist in `industry.md` benannt). | Wachstum wird überschätzt | +0,5 %-Regel streichen, Arbeitsplätze wirken nur über J bzw. X (`wachstumsgewichte.md`) (Tobias) |
| 14 | `city.md` W (0,6 / 0,25 / 0,15) gegen `tobias.md` Versorgungsgrad V | `city.md` benennt die Abweichung. T-04: Reiner Güterspieler hat W = 0,60 und braucht 45 / 323 min statt 12 / 80. | Güterspieler wird um das Vierfache bestraft | Variante B (Personen als Zuschlag bis +25 %, Basis 1,8 %) (Tobias, Jonas) |
| 15 | `hq.md` „Handelsknoten/Metropole“, Startkapital-Tabelle (Metropole 15.000 $, Radius 40) gegen `city.md` (Metropole ≥ 60.000 Einw.) und Beispiel 12.000 Einw. | Der Beispielarchetyp ist eine Stadt (5.000–19.999), nicht Metropole. Startwerte für Metropole haben keinen Spieler. | Tabelle hat tote Zeile | Handelsknoten = Stadt, Metropole-Zeile streichen oder als späteren Start markieren (Lena) |
| 16 | `hq.md` „Dorf < 1.000“ (Agrar 900) gegen T-04-Zielzeit 12 min (Start 800 Einw.) | Die „12 min“ gelten nicht für die HQ-Stadt der Archetypen (Agrar 6 min, Hafen 23, Bergbau 36 bis zur nächsten Stufe). | Zielzeit-Abweichung scheinbar | Zielzeiten je Archetyp führen (`hq_startwerte.md`) (Lena, Tobias) |

## C. Epochen und Begriffe

| # | Stelle | Widerspruch | Folge | Vorschlag |
|---|---|---|---|---|
| 17 | `lena.md` 5 Epochen (I–V) gegen `tobias.md`, `industry.md`, Plan: 4 (E1–E4) | `plan/lena.md` hält die Entscheidung auf 4 fest, Hightech als Post-Release. `lena.md` ist nicht angepasst. | Zahl in GDD uneinheitlich | `lena.md` auf 4 Epochen, V als Post-Release (Lena, Jonas bestätigt) |
| 20 | „Spezialisierung“: `tobias.md` (drei Ausrichtungen Menge, Qualität, Effizienz) gegen `industry.md` („Fokus“ als vierte Ausrichtung, Skill „Spezialisierung“ wird „Fokus“) und `lena.md` („Spezialisieren oder diversifizieren“) | Ein Wort, drei Bedeutungen. | Skill- und Firmenbegriff kollidieren | Firmen-Ausrichtung „Spezialisierung“, Skill „Fokus“ (Lena, Tobias) |

## D. Diagnose-Playtest (Tag 1–3 neu gefunden)

| # | Stelle | Widerspruch | Folge | Vorschlag |
|---|---|---|---|---|
| 21 | `plan/lena.md` 5 Fehler (Deadlock eingleisig, fehlendes Signal, 1 Zulieferer, Stadt übersättigt, Lizenz abgelaufen) gegen Beschluss 3 Fehler und Felix' Spike (Gegenverkehr, Kreis, Ladung) | Alte Fehlerlisten kursieren in `plan/lena.md`, `plan/felix.md`, `daniel/l06_protokollvorlage.md` (Quellenzeile). | Tester und Build könnten verschiedene Fehler meinen | Fehlerliste in `playtest_szenario.md` Abschnitt 2 gilt (Lena, bis 19.11.) |
| 22 | Ursachencodes: Aylin (`KREIS_BLOCKIERUNG`, `ZULIEFERUNG_ZU_GERING`) gegen Felix (`DEADLOCK`, `WARTEN_AUF_LADUNG`) | Zwei Namen für dieselben Ursachen, Felix liefert zudem `BLOCK_BELEGT_UNTERWEGS`, `KEINE` und unterscheidet Geld/Nachfrage nicht. | Mapping fehlt | Mapping-Tabelle im Pairing (Felix, Aylin) |
| 23 | Daniel D-04: Szenarien „Weiche ohne Signal“ und „Ausweichgleis zu kurz“ gegen Felix' Spike | Beide sind im Spike nicht baubar. Das Gate „≥ 5/6“ ist so nicht erreichbar. Außerdem ist die Schwelle „≤ 50 Ticks“ wirkungslos (Parameter = 4 Ticks, laut Daniel). | G3 nicht prüfbar | D-04 mit F1, F2 und F2 (3 Züge) prüfen (`playtest_szenario.md`, Abschnitt 7) (Daniel, Felix, Jonas) |
| 24 | `plan/lena.md` Paper-Test „3 Startstädte (Hafen, Bergbau, Agrar)“ gegen T-05 mit 4 Archetypen | Handelsknoten würde nicht getestet. | G5 deckt nur 3 von 4 ab | 4 Karten, Spieler pinnt 3 (`paper_prototyp_plan.md`) |

## E. Offene HQ-Fragen (kein Widerspruch, aber ohne Entscheidung)

Garantiert jede Karte alle 4 Archetypen, oder entscheidet der Seed? Darf die KI ein HQ setzen und Lizenzen teilen oder blocken? Braucht es den Umzug? (`hq.md` Offene Fragen 1–3, Termin laut `plan/lena.md` 13.11., in den Dateien dieser Tage nicht entschieden.) Sie beeinflussen die Städte-Auswahl im Paper-Test und die KI-Annahme (40 % ab Minute 15) in T-05.

## Gewichtung

Vor dem Gate wichtig: 1, 4, 5, 7, 12, 21, 23. Vor dem GDD wichtig: 2, 3, 6, 8, 13–17, 20. Rest beim Ausarbeiten.
