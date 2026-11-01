# Refinement Sprint 3: Positionen Lena und Tobias

## Lena Hoffmann, Lead Game Design

**Will im Sprint (8 T):** L-08 Spielregeln Slice-Loop (2 T), L-07 Tester-Material (1,5 T), Auswertung der Basti-Tests L-06/L-05 bis 02.12. (2 T, neu, sonst liest niemand die Ergebnisse), J-06 Mitarbeit (0,5 T), Abnahme der Slice-Karte F-14 (0,5 T), Puffer 1,5 T.

**Raus/kleiner:** Dank D15 entfällt die Spec für Bau-Tool, Kontextdialog und Standard-HUD; A-07 schrumpft von 2 auf 0,5 T (Referenzliste "wie TF2/OpenTTD", keine Eigenspec). L-08 beschreibt nur unsere Unterschiede: HQ-Start, Lizenz→Kauf-Leiter, Lager als Hub, Ketten-Logik. S-08 (Slice-Look, 3 T) raus aus S3: Look vor spielbarem Loop ist Politur auf Treibsand.

**Einwand:** Gegen T-06 als reines Datenmodell (3 T) vor L-08. Zahlen ohne verbindliche Regeln produzieren Rework bei Felix, der der einzige Programmierer ist. Regeln und Werte müssen in einer Sitzung entstehen, sonst baut Felix zweimal.

**Akzeptanzkriterium L-08:** Das Regelwerk umfasst höchstens 4 Seiten, jede Regel nennt eine Zahl oder Bedingung, und mindestens 5 von 6 Testern erreichen ohne Hilfe innerhalb von 10 Minuten ihre erste bezahlte Lieferung.

## Tobias Brandt, Systems/Economy

**Will im Sprint (8 T):** T-06 Ökonomie in die Sim, aufgestockt von 3 auf 4 T, T-07 Exploit-Katalog (1 T), F-09b nur Minimal-Validator (0,5 T statt 1,5), Balancing-Tabelle und Simulationsläufe (1,5 T, neu), Gate-Zuarbeit (1 T).

**Raus/kleiner:** F-09b auf Kernschema kürzen, Rest nach S4. Raus: S-08, und F-14 kleiner (kein Gelände-Feinschliff, nur 3 Ketten und Städte).

**Zu D15:** Karte, Bau und Dialoge sind Standard. Die Ökonomie (Ertrag nur beim Endabnehmer, Lizenz→Kauf, Kredit) ist unser Unterschied, und dort fehlt jede Referenz. Das braucht Rechenzeit und Läufe, nicht Meinung. Wer hier kürzt, spart an der einzigen Stelle, die uns vom Genre trennt.

**Einwand:** Gegen F-11 mit 1,5 T vor Kalibrierung: Erst Exploit-Katalog, dann entscheiden, welche Deadlocks wirklich Geld kosten.

**Akzeptanzkriterium T-06:** In 100 simulierten Läufen der Standardlinie (3 Ketten) liegt der Bankrott-Anteil bis Minute 30 zwischen 10 und 30 %, und kein bekannter Exploit liefert mehr als das 1,5-Fache des Referenzgewinns.
