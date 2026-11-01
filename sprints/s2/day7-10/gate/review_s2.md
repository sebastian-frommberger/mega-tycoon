# Sprint-Review S2, 27.11.2026
Moderation: **Katrin**. Abnahme: **Jonas**. Ticketliste aus den Tagesberichten rekonstruiert; Katrin gleicht sie mit dem Backlog ab.

## Sprintziel
| Teilziel | Erreicht | Grund |
|---|---|---|
| Auswertung Diagnose-Playtest gegen Messgröße | **nein** | Build, Skript, Protokoll stehen. 0 echte Tester; das synthetische Panel zählt nicht. |
| Benchmark-Entscheidung „Sim-Kern bleibt GDScript“ | **ja, mit Vorbehalt** | Zielrechner-Messung (Editor-Build): SoA 10k 1,9 ms. Release-Export und Deadlock-Prüfung fehlen. |
| Konsistente Lizenz/Kauf-Leiter | **teilweise** | Rechnung 4/4, DR bestätigt. L-05 0/3 Runden. Lenas Rechnung: Kauf bringt +50 bis +250 $/Takt und zahlt sich im Lauf nie aus; getestet wird nur der Wunsch. |

## Tickets
| Ticket | Endstatus | Grund |
|---|---|---|
| J-05 Gate-Kriterien | Done | `gate_kriterien.md`. |
| F-04 (inkl. B8) | Done | Daniels Abnahme grün. |
| D-04 | Done | 36/36, 0 Fehlalarme (Sandbox). |
| A-05, A-06 | Done | Text; Felix' Bestätigung je Feld nur als Code. |
| T-05, T-04 | Done | Rechnung, per D1/D4 bestätigt. |
| S-05 | Done | Gerechnet; kein Test mit Farbschwäche. |
| F-05 | nicht Done | Messung nur im Editor, kein Release-Export. |
| F-06 | nicht Done | Export mit sha256 und Pilot fehlen. |
| F-08 | nicht Done | Kein Record. |
| F-09 | nicht Done | Felix' Abzeichnung offen. |
| L-06 | nicht Done | 0 von 6 Testern. |
| L-05 | nicht Done | 0 von 3 Runden. |
| S-03 | nicht Done | Entscheidung und Wiki da, Messkriterien offen. |
| S-06a | nicht Done | Entwurf, nicht abgestimmt. |
| K-07 | nicht Done | Gerüst da, Poker nicht belegt. |
| F-07 | gestrichen | D6. |

Bilanz: 8 Done, 8 nicht Done, 1 gestrichen.

## Demo für den Auftraggeber
**Katrin:** Gezeigt wird nur, was real läuft.
1. F-06-Testbuild (3 Fehler, Panel, Klick-Log, Replay) samt `f06_start.md` für eigene Tests.
2. F-05-Tabelle vom Zielrechner (Spike gegen SoA).
3. D-04-Szenarien und B8-Fix.
4. T-05-Tabelle, Palette S-05, A-06-Strings.
5. S-06a mit Kenney-Messung.
6. Gate-Ergebnis: Vertagen auf 02.12. und die fünf Bedingungen.

## Velocity
Punkte oder Stunden liegen nicht vor, ich erfinde keine. Die Technik- und Konzepttickets liefen, alle Tickets mit externem Beleg (Tester, Release-Export, Abstimmung) stehen. Das ist ein Engpass außerhalb des Teams, kein Tempoproblem. Für S3 plane ich nur Tickets ein, die ohne fremde Hilfe abschließbar sind, und Basti-Termine getrennt.
