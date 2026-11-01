# Sprint 6 – Review und Retro (30.01.2027)

## Review (Jonas)
**Sprintziel erreicht** (Modell und Sandbox; Basti spielt, wenn er Zeit hat – Karten: l13_aufgabenkarten.md):
- 8/8 Städte mit Hover-Vorschau, Gründung in 2 Klicks (max. 5 mit Wechsel), kein Dialog, kein Archetyp im Code.
- Ein Startkapital 6.000 $, 2 Gratis-Lkw, Lok-Fix 90 $/min, Dorfnachfrage ×2.
- 3 Standorte mit vollständiger Kette (Haberau, Kohlberg, Mittelfurt). Bankrott im Modell 10–15 % (Band 10–30 %), Kohlberg-M7 nach D24 36–38 min.
- Regression 12/12 Suiten grün, neu: d08_bankrott (Drift-Wächter), d08_lizenzfaktor, d08_maus (echte Maus).
- Zielrechner: 89,7 FPS Median bei 5.000 Lkw (vor p95-Fix und vermutlich ohne Kenney-Look, B-2). Neuer Bench-Lauf steht aus.

**Abnahmen (Daniel):** ja: F-21a, S-12, SK-01, B-Fixes. Mit Auflagen: T-14 (Haberau/Kohlberg am unteren Bandrand), F-20/U-02b/S-13 (Zielrechner: Hover-Latenz, Look-Last, p95).

**Nicht geschafft / Stretch:** A-08 Diagnose-Toast, Label-Kanten allgemein, Pin-Vergleich.

## Retro (Katrin)
- **Gut:** Kartenpaket vor Platzierung hat funktioniert; Felix' Ein-Kapital-Schnitt in Block A hat Mira entlastet. Daniels echte Mausprüfung fand, was die headless-Tests nicht sehen.
- **Schlecht:** Vorschau-Daten rechneten einen Faktor, den das Spiel nicht kennt (B-1) – Modell und Spiel sind auseinandergelaufen. Kenney-Loader las von der Platte (B-2), dadurch war die erste Zielrechner-Messung ohne Look.
- **Ändern:** (1) Jede Zahl, die der Spieler sieht, bekommt einen Test gegen den Spielwert (Vorbild d08_lizenzfaktor). (2) Export-Check per --export-pack wird Teil der Regression. (3) Daniel bekommt Screenshots früher, nicht erst an Tag 8.

## Kandidaten Sprint 7
Firmenkauf (R2, Basti: ja), Größenfaktor Lizenz (A2), A-08 Diagnose, Skilltree-Entscheid (Punkte nur Meilensteine oder auch Transport-XP), Bankrott-Bot kalibrieren, neuer Bench-Lauf, B-11/B-12 Ghost/Ring-Lesbarkeit, B-15 Archetyp-Altlast in der Karte, main.gd-Aufteilung.
