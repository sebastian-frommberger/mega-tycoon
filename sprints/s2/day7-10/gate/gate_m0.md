# Gate M0, 27.11.2026
Moderation: **Katrin Vogel**. Entscheidung: **Jonas Weber**. Maßstab: D7/D8 wörtlich; synthetisch ist kein Messwert.

| ID | Status | Belegstufe | Beleg | Begründung |
|---|---|---|---|---|
| G1 | offen | synthetisch | `panel/auswertung.md` | 0 echte Tester („< 6: offen, nicht Rot“); Haiku-Panel zählt nicht. |
| G2 | Gelb (vorläufig) | Messwert, eingeschränkt | `zielrechner/f05_zielrechner.md` | SoA 10k Median 1,90 ms, Spike 5k 10,9 ms; aber Editor-Build ohne Deadlock-Prüfung: nach D7 nur obere Schranke. |
| G3 | Grün | Messwert (Sandbox, hardwareunabhängig) | `daniel.md` | 6/6, 0 Fehlalarme in 6.000 Ticks (Daniel: 10 min). Auflage: Wiederholung am Zielrechner. |
| G4 | Grün | Messwert (Sandbox) | `daniel.md` | 9/9, Smoke 3/3, je ≥ 120 s sichtbar. Nur md5, kein Export. |
| G5 | offen | Rechnung | `tobias.md`, `lena.md` | R-Teil 4/4 und DR bestätigt (D1), M-Teil 0/3 Runden. Messwert fehlt. |
| G6 | Rot (formal) | – | keine | Kein F-08-Record vorgelegt; nach Wortlaut Rot, heilbar. |
| G7 | offen | Rechnung | `sophie.md` | Nichts gemessen; 512²-Grenze nur gerechnet. |
| G8 | Gelb, fest | – | `gate_kriterien.md` | „Nicht nachgewiesen“; Bau-Spike erstes M1-Ticket. |
| G9 | Rot (formal) | – | `sophie.md` | S-06a Entwurf, kein Poker belegt; nicht gate-blockierend. |

## Go-Regel D8, wörtlich angewandt
**Katrin:**
- „Go: kein Rot in G1–G6; Messwerte G1–G5 vorhanden; höchstens 2 Gelb in G1–G3.“ **Nicht erfüllt:** G6 formal Rot, für G1 und G5 fehlt der Messwert.
- „Vertagen auf 02.12.: drei Gelb in G1–G3, oder ein Messwert in G1–G5 fehlt (offen).“ **Erfüllt:** G1 und G5.
- „No-Go: G1 Rot, oder G3 Rot, oder G2 Rot ohne Alternativplan.“ **Nicht erfüllt:** G1 ist offen, nicht Rot; G3 Grün; G2 nicht Rot.

## Entscheidung
**Jonas: Vertagen auf 02.12.** Technik stimmt, aber ob Spieler die Kette lesen und die Leiter Kaufwunsch erzeugt, ist ungemessen. Ich rechne nichts hoch. Keine zweite Vertagung: Fehlen G1 oder G5 am 02.12. weiter, protokolliere ich No-Go.

## Bis 02.12. muss passieren
1. **L-06 mit 6 echten Testern:** Basti führt sie nach `aylin/testskript_l06_final.md` und `felix/f06_start.md` durch. Vorher Materialfehler des Panels beheben (Zeiten, markierte Wurzelzeile, Orte). Owner: Katrin, Lena, Daniel.
2. **L-05, 3 Runden** mit Nicht-Designern. Owner: Lena, Katrin.
3. **F-05 als Release-Export** auf dem Zielrechner, mit Deadlock-Prüfung. Owner: Felix, Daniel.
4. **F-08-Record**. Owner: Jonas mit Felix, Sophie.
5. **K-07 Planning-Poker** und Abstimmung S-06a. Owner: Katrin, Felix, Sophie.

## Sprint 3 startet trotzdem
- **Erlaubt:** SoA-Umbau des Sim-Kerns, ereignisgesteuerte Deadlock-Prüfung, Release-Export und F-05-Wiederholung, F-06-Export mit sha256, Bau-Spike (G8), F-08, F-09-Abzeichnung, S-03-Messung auf der Zielrechner-GPU, K-07.
- **Gesperrt bis Go:** Artist-Produktion für den Vertical Slice, Ketten 4/5, Hafen/Fluss, Lizenz-/Kauf-Implementierung im Build vor L-05, Ausbau des Diagnose-Panels über F-06 hinaus.
