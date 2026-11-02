# 04 Schwierigkeitsgrade: Hebel und Presets (Tobias, Lena; Art Director zur Welt; 02.11.2026)
Zweck: Antwort auf E5. Welche Hebel hat ein Tycoon, welche gehören zur Welt und welche zum Balancing? Dazu eine Skizze für 3 Stufen als Datenpresets. Die Entscheidung fällt in S8.
Status: Skizze, Phase 2. Ausgangswerte [S7] aus `economy_constants.json` (1 Periode = 1 Spielmonat = 1 min).

## Hebel
| Hebel | Bereich | Wirkung | Leicht | Normal (= S7) | Schwer |
|---|---|---|---|---|---|
| Startkapital | Balancing | Spielraum für Fehler | 9.000 $ | 6.000 $ | 4.500 $ |
| Kreditrahmen / ab Minute | Balancing | Rettungsnetz | 3.000 $ / ab Min. 6 | 2.000 $ / ab Min. 12 | 1.500 $ / ab Min. 12 |
| Zins | Balancing | Druck auf Schulden | 2 %/min | 3 %/min | 4 %/min |
| Bankrottregel (Zwangsverkauf unter Rahmen / Vorwarnung) | Balancing | Strafe für Fehler | 15 min / 180 s | 10 min / 90 s | 7 min / 60 s |
| Nachfrage und Wachstum (Basisrate 1,8 %/Monat) | Balancing | Belohnung für gutes Netz | ×1,25 | ×1,0 | ×0,8 |
| Baukosten (Straße 10 $/Feld, Hang, Brücke) | Balancing | Preis des Geländes | ×0,8 | ×1,0 | ×1,25 |
| Konkurrenz | Balancing | Druck von außen | – | – | erst mit KI-Firmen (gibt es noch nicht) |
| Sicht und Hinweise („Nächster Schritt“ mit Preis, HQ-Vorschau „Wagnis“) | UX | Wissen statt Raten | an + Tipps | an | nur auf Abruf. **Fehlertexte mit Lösung bleiben immer** (Aylin) |
| **Siedlungsdichte** (Spieldörfer) | **Welt** | Nachfrage-Verteilung, Weglängen | 16–18 Dörfer | 12–18 (aus Gelände) | 12–14 Dörfer |
| **Quellen je knappem Rohstoff** (Erz, Kohle) | **Welt** | Standortdruck | 2 je Typ | 1–2 | 1 je Typ, weiter weg |
| **Relief** (Anteil Hügel/Gebirge, Flussquerungen) | **Welt** | Kosten über Gelände | flacher Seed | Standard | mehr Relief, 1 Brückenstelle weniger |
| **Startjahr** | **Welt** (03, Abschnitt 4) | Technikstand, Ortsgröße | 1840 (Bahn sofort, größere Orte) | 1820 | 1820 ohne Start-Chaussee |
| Ziel-Bankrottquote (Messung durch Daniel/Bots) | Messgröße | Abnahme der Stufe | ≤ 5 % | 15–18 % [S7-Band 15/17/18 %] | 30–40 % [Annahme] |

## Stimmen
| Wer | Position | Gegenposition |
|---|---|---|
| Tobias | Schwierigkeit **nur über Geld** (Kapital, Zins, Bankrottregel, Kosten). Das ist transparent, mit Bots messbar und lässt die Welt in jeder Stufe gleich. | Lena: Reine Geld-Stufen spielen sich gleich, nur knapper. Wiederspielwert entsteht erst, wenn die Welt sich unterscheidet. |
| Lena | Höchstens zwei Welt-Hebel: knappe Rohstoffe und Relief. Sie verändern die Entscheidungen, nicht nur den Kontostand. | Tobias: Welt-Hebel vermischen sich mit dem Seed. Ein schwerer Seed auf „Leicht“ ist nicht mehr leicht. Darum je Stufe eine Bandbreite und Bot-Prüfung. |
| Art Director | Welt-Hebel sind erlaubt, solange sie die Prinzipien nicht brechen: gleiche Verhältnisse, Werte im Realband, keine leerere oder hässlichere Welt auf „Schwer“. Die Siedlungsdichte bleibt deshalb in 12–18. | Aylin: „Leicht“ mit 1840-Start ist eine andere Epoche, keine leichtere. Das Startjahr gehört als eigene Option neben den Schwierigkeitsgrad, nicht hinein. |

## Vorschlag (Skizze)
- **Drei Presets als Daten:** `schwierigkeit: {leicht|normal|schwer}` überschreibt nur Werte aus `economy_constants.json` und zwei Welt-Parameter (`quellen_knapp`, `relief_profil`). Das Startjahr bleibt eine **eigene Option** (Aylins Punkt übernommen).
- „Normal“ ist der heutige S7-Stand, damit kein Balancing verloren geht. Nach Wechsel auf Szenario B (03) muss Tobias „Normal“ neu messen, weil die Nachfrage sinkt.
- Die Abnahme jeder Stufe erfolgt über die Ziel-Bankrottquote im Bot-Lauf, nicht über das Gefühl.

## Offene Fragen an Basti
1. Soll die Schwierigkeit die **Welt** verändern dürfen (knappe Rohstoffe, Relief), oder nur Geld und Hinweise (Tobias' Linie)?
2. Startjahr und Schwierigkeit als **zwei getrennte Optionen** im Startmenü, einverstanden?
