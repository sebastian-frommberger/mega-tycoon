# Sprint 4 (14.–25.12.) – Entscheidung Jonas (PO)

**Sprintziel:** Am 25.12. liegt ein Release-.exe vor, in dem Basti ohne Moderation (D16) in ≤ 10 min ab Start die erste Lieferkette baut und in 30 min ≥ 3 Lieferungen mit Gewinn sieht. 0 Abstürze, Karte lädt ≤ 3 s, Bench-Median ≥ 60 FPS bei 5.000 Einheiten (3/3 Läufe), Bankrottrate 10–30 % in 100 Headless-Läufen.

**Stretch:** A-08 mit einer Diagnose ("Verbindung fehlt") plus Aktion, Felix 0,5 T, nur wenn F-16 bis 22.12. grün ist.

**F-15-Frage:** Der Dialog ist nicht nötig, der Prototyp-Weg reicht. Minimal nötig ist ein sichtbarer Button "Lizenz kaufen" (1 Klick, zeigt Preis und Ertrag/Monat) in F-16. Firma = Startkapital, Linien über das Bau-Tool (Annahme). Keine versteckte Debug-Taste: Basti spielt allein.

| ID | Ticket | Owner | Tage | Akzeptanz | Folge |
|---|---|---|---|---|---|
| S-10 | Karte ausgleichen, JSON bis 15.12. eingefroren | Sophie | 2 | Quadrant 25 % ±5 PP, Stadtabstand ≥ 15 % Breite | blockiert F-14, T-12 |
| F-14 | Grey-Box-Slice aus S-09-JSON, 2 Geländetypen | Felix 3,5; Lena 1 Abnahme; Daniel 1 Smoke | 5,5 | Ladezeit ≤ 3 s, 0 fehlende IDs, Region ≤ 40 % | Basis F-12, T-12 |
| F-16 | Ökonomie-Kern, Lizenz-Button, 8× nur bis 5k; kein Kredit | Felix 2,25; Tobias 2; Daniel 1,5 Tests | 5,75 | Zwischenlager 0 $; Umweg 1,5× ≤ Luftlinien-Ertrag; Kauf in 1 Klick | Kredit, Dialog in S5 |
| T-12 | Kalibrierung, Start erst wenn F-14 lädt (ca. 18.12.) | Tobias 1,5; Sophie 0,5 | 2 | Bankrott 10–30 % in 100 Läufen à 30 min | Zahlen für R1 |
| H-01 | Headless-Sim ohne UI | Tobias | 1,5 | 100 Läufe, 0 Abstürze, gleicher Seed gibt gleiches Ergebnis | entlastet Felix |
| L-10 | Holz-Lücke per Regel (keine Quelle), L-08 Stufe 2 = 2.000 $ | Lena 1,5; Tobias 0,5 | 2 | Kleinstadt 72–90 min statt 154 | stabile Sättigung |
| S-08 | Lesbarkeit, 3 Farbtokens, B-04 | Sophie | 1 | 100 % Marker/Ghosts ≥ 3:1 | Review lesbar |
| F-12 | Release-Export, 3 Läufe pro Start, Vorlauf nach F-14 | Felix 1; Daniel 1,5; Tobias 0,5 | 3 | 3/3 ohne Absturz, Median ≥ 60 FPS, Streuung ≤ 10 % | Frühwarnung |
| D-06 | Messskript im Repo, kein CI-Server | Daniel | 1 | 1 Befehl erzeugt Ergebnisdatei | S5 wiederverwendbar |
| B-03 | required-Listen im Schema | Tobias | 0,5 | 0 Validierungsfehler in S-09/T-06-JSON | sauberes JSON |
| J-07 | Demo-Skript, Pfeiler-Checkliste, Aufgabenkarten, Testplan | Jonas 1; Aylin 2; Lena 0,5; Daniel 1 | 4,5 | 5 Aufgabenkarten, Basti-Spielzeit ≤ 45 min | Review 15.01. |
| F-15/A-08 Spec | Happy-Path-Spec für S5 | Aylin 3; Lena 0,5 | 3,5 | S5-Abnahme: ≤ 3 Klicks, ≤ 15 s, 5/5 | S5 baut ohne Raten |

## Geschoben / gestrichen
- Geschoben nach S5: F-15 Dialog-Bau, A-08 Bau, Kredit. Sophies F-15-Theme (1,5 T) ist Puffer.
- Gestrichen: CI-Server, Sim-Thread (F-17), dritter Geländetyp, B-01/B-02 (außer Daniel meldet bis 17.12. einen Linienbau-Blocker, dann Tausch gegen F-16-Umfang).

## Streitprotokoll
- F-15: Felix, Daniel, Lena, Tobias gewinnen gegen Aylin (Engpass, kein messbares Kriterium). Aylin behält Spec, Button-Infotext und ihr Kriterium als S5-Abnahme.
- A-08: raus (Lena, Felix, Tobias vor Aylin). Ihre Spec bleibt.
- D-06: Kompromiss. Daniel und Felix gewinnen das Skript, Lena gewinnt "kein CI".
- Kredit: Lena gewinnt gegen Felix (im ersten Loop nicht erlebbar).
- L-10: Lena und Tobias gewinnen, nur Regel.
- T-12-Start: Lena und Sophie gewinnen; Tobias prüft vorab nur headless.
- F-12: Daniel gewinnt 1,5 T statt 0,5.

## Kapazität (T)
| Person | Geplant | Puffer |
|---|---|---|
| Felix | 6,75 | 0,25 |
| Daniel | 6 | 1 |
| Lena | 5,5 | 1,5 |
| Tobias | 6,5 | 0,5 |
| Aylin | 5,5 | 1,5 |
| Sophie | 5 | 2 |
| Jonas | 5 | 2 |

Cut-Line: Ist F-14 am 18.12. nicht grün, entfallen F-12-Vorlauf und Sättigungs-Feintuning. Der Herkunftsstempel bleibt (unser Unterschied, D15).

## Basti
1. Bis 21.12. einmal die Bench-.exe doppelklicken, Ergebnisdatei bleibt neben der .exe.
2. Am 15.01. 30 min allein mit den Aufgabenkarten spielen (D16). Leitfrage: Baue ich in 10 min meine erste Lieferkette?
