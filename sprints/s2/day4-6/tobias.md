# Tobias – Sprint 2, Tag 4–6
(Alles Modellrechnung oder Schema-Validierung auf der Sandbox; keine Messwerte.)

## Daily Tag 4 (19.11.)
Gestern: Entscheidungsrunde D1–D14. Heute: T-05 mit Lenas HQ-Werten gegengerechnet, Kohle-Zufluss und Kreditrahmen ins Modell, Übergabe an Lena, T-04 nach D4 fixiert. Blocker: D14-Frist 18:00 für G5 verpasst.

## Daily Tag 5 (20.11.)
Gestern: T-05/T-04 final. Heute: G5 bestätigt (verspätet, begründet), Kreditregel an Felix. Blocker: kein Felix-Bericht Tag 4–6 (`felix/spike/` wie Tag 1–3), F-09-Review nicht terminiert.

## Daily Tag 6 (23.11.)
Gestern: G5, Kreditregel. Heute: F-09 Schemas, Beispieldaten, Validator (Exit 0); Lenas Tarifkarten gegengelesen. Blocker: Felix' Abzeichnung F-09.

## Ergebnisse
- **T-05: fertig, bestätigt durch D1 (Testannahme, revidierbar nach L-05).** `tobias/t05_final.md`, `t05_final_modell.py`, `t05_final_*.csv`, `uebergabe_lena.md`. AK Tabelle mit Break-even: **ja**. ≥ 1 Startfall Lizenzroute vorn je Archetyp: **ja, 4/4** (Agrar nur über Rohstoff-/Kleinmarkt-Fälle). Zahlen am 19.11. bei Lena: **ja** als Datei; Lena rechnete am 20.11. trotzdem mit dem alten Modell (Abgleich `gegenlesen_l05_tarife.md`). Abweichung zu Tag 1–3: Bergbau mit Kohle braucht Startpaket 2.280 $, Formel ergäbe 8.000 $, D1 setzt 7.000 $ (reicht, Rest 720 $); Lenas Untergrenze 6.000 $ nur mit Kreditrahmen. Lenas übrige Werte sind meine Setzungen, keine zweite Quelle.
- **T-04: fertig nach D4.** `t04_final.md`. Variante B, 1,8 %/Monat, Zuschlag ≤ +25 %, +0,5-%-Regel gestrichen, Etikett „ungetestet“. AK ≤ 15 %: **ja (Rechnung, geeicht)**, CSV.
- **G5-Bestätigung: 20.11., Frist war 19.11. 18:00.** `g5_bestaetigung.md`. Schwellen bestätigt, drei Protokollhinweise (Agrar dünn, R = Konstruktion, Bergbau-Formel). M-Teil: 0/3 Runden.
- **Felix' Frage Kreditrahmen: beantwortet.** `antwort_felix_kredit.md`: 2.000 $ ab Minute 0, 1 %/Spielminute auf den gezogenen Betrag, Firmenkauf/Ausbau nur aus Guthaben. Im Raster alle Soft-Locks weg, Kredit in Minute 1 zurück, Zinsen 3–9 $.
- **F-09: in Arbeit, Abzeichnung offen.** `tobias/f09/`: 4 Schemas, 3 Beispieldateien (10 Güter, 4 Fahrzeuge, Konstanten mit D1/D4-Werten), `validate.py` (jsonschema 4.26.0 plus eigener Fallback, 8 Negativfälle), `run_validate.log` **Exit 0**. AK Schema: **ja**; Beispieldatei Exit 0: **ja** (Sandbox); Felix' Abzeichnung: **nein**. Drei Entscheidungen bei ihm (Raten je Periode, `feld_mm`, 2^53-Grenze).

## Annahmen und offene Fragen an andere (mit Namen)
- Annahmen: Kohlemine 1.200 $, 15 Felder, 1:1; Kreditrahmen-Höhe/Zins; `feld_mm = 1000`, Spieljahr = 12 Spielminuten, Fleisch-Frische 6 min; Werkzeugfabrik als Bergbau-Abnehmer.
- **Lena:** Erzberg-Tarif und Erwartungskonto auf Final-Werte (4.230 statt 4.650 $), Kohlemine als Karte, Bergbau-Untergrenze 6.500 $ oder Kreditregel auf der Karte.
- **Felix:** F-09-Review (30 min) terminieren; Antworten zu Periode/Öko-Tick, `feld_mm`, JSON-Loader `int()`.
- **Jonas:** Formelabweichung Bergbau zur Kenntnis; Sperre für Lizenz-Neuabschluss im Minus (ich: nein).
- **Sophie:** Güterliste in `f09/data/goods.json`.

## Risiko für das Sprintziel
G5 hat am 27.11. nur den R-Teil; ohne Tester bleibt der M-Teil offen und D8 heißt Vertagen, unabhängig von meiner Rechnung. Mein Versäumnis: die D14-Frist, ohne Folge für die Schwellen, aber ein Vertrauensverlust. F-09 ist ohne Felix' Abzeichnung nicht fertig; sein Review-Slot ist durch F-04/F-05 belegt.
