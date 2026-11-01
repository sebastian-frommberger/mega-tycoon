# Refinement S2 – Tobias (Systems & Economy)

## Meine Tickets

**T-05 Startkapital und Lizenz/Kauf-Leiter – Spike, 2,5 T, nicht verhandelbar.**
Leitfrage: Mit welchem Startkapital pro Archetyp bekommt man „3 Lizenzen oder knapp 1 Kauf“, ohne dass Kaufen immer besser ist?
- AK: Tabelle Startkapital/Lizenz/Kauf für 4 Archetypen, Break-even inkl. 50 % Anrechnung und 15 % Werksmarge.
- AK: Widerspruch 15–30k $ vs. 1–4k $ × Stufe aufgelöst und dokumentiert.
- AK: Zahlen liegen bis 19.11. bei Lena für L-05.
- Abh.: Lena (HQ-Startwerte bis 17.11.), Jonas (Zielgefühl Casual-Start).

**T-04 Sättigung/Stadtwachstum – Spike, 1,5 T.**
Leitfrage: Kommen wir mit F_sätt 1,0/0,4/0,1 und W 0,6/0,25/0,15 auf ca. 12 bzw. ca. 80 min?
- AK: Zeitreihe im Sheet, Abweichung ≤ 15 %.
- AK: Variante „Personen nur als Bonus“ gerechnet, mit Empfehlung.
- Abh.: Lena (Gewichte W).

**T-06 Balance-Targets und Exploit-Katalog – Spike, 1,5 T** (davon 0,5 T Daniel).
Leitfrage: Woran messen wir ab R1, ob die Ökonomie stimmt?
- AK: Balance-Targets v1 mit Messgröße und Toleranz pro Ziel.
- AK: 6 Exploits mit Gegenregel und Testidee im Format von Daniel.

**F-09 JSON-Datenformate – Spike, 1,5 T bei mir, 0,5 T Felix.**
Leitfrage: Trägt die Festkomma-Konvention (Cent, Ticks) die VS-Ketten?
- AK: Schema für goods, vehicles, economy_constants; die VS-Beispieldatei validiert.
- AK: Felix hat die Festkomma-Konvention in 30 min Review abgenickt.
- Den Rest (chains, industries, cities) schiebe ich nach S3. Ich schreibe, Felix reviewt nur.

**T-07 Headless-Sim – schieben nach S3.**
Ehrlich gesagt: Ohne SimWorld-Schnittstelle wird das ein Wegwerfskript, das nichts beweist. Felix hat dafür keine Zeit. Fürs Gate reicht das Sheet. In S3 kommt es als erstes Ticket, zusammen mit Felix' Schnittstelle als eigenem Ticket.

## Einwände

1. **L-03 Onboarding-Leiste mit HQ und Lizenzen:** Die baut auf Startkapital-Zahlen, die aktuell falsch sind. Das bauen wir dann zweimal. → L-03 geht in L-05 (Paper-Prototyp) auf und startet nach T-05. Das spart Lena 3 SP.
2. **L-04 Skilltree als Datentabelle:** Das ist nicht gate-relevant, und die Skillpunkt-Quelle ist auch noch nicht fertig gegengerechnet. → Ab nach S3, dann gleich ins JSON-Schema.
3. **S-05/S-06 Farbatlas und Silhouetten-Sheet, zusammen 8 SP:** Das sind Asset-Karten, die gehören laut Regel nicht ins Sprint-Commitment. → Beides aufs Kanban-Board mit WIP 2. Im Sprint bleiben S-03 und S-04.
4. **S-03 Look-Test hängt an Felix' MultiMesh-Szene:** Das ist schon wieder eine Abhängigkeit auf Felix. → Sophie baut die 200 Quader selbst, als Wegwerfszene. Die Benchmark-Szene bleibt davon getrennt.
5. **F-08 Terrain-Entscheidung als 2-SP-Ticket:** Das ist eine Entscheidung und kein Bauauftrag. → 1 Stunde Termin Felix/Jonas/Sophie und ein Decision Record. Die frei gewordene Zeit geht an F-04.
6. **K-07/J-05 Gate-Kriterien:** Da taucht keine Ökonomie auf. Wenn Benchmark und Playtest grün sind, das Startkapital aber Unsinn ist, starten wir R1 auf Sand. → Gate-Kriterium „Lizenz/Kauf-Leiter konsistent, von Lena im Paper-Test bestätigt“ kommt dazu.

## Meine Kapazität und Forderung

| Ticket | Tage |
|---|---|
| T-05 | 2,5 |
| T-04 | 1,5 |
| T-06 | 1,5 |
| F-09 | 1,5 |
| Gate-Entscheidungsvorlage Economy (Lizenzlaufzeit, Spielmonat) | 0,5 |
| Support L-05 / Puffer | 0,5 |
| **Summe** | **8,0** |

Was ich fordere:
- T-05 ist Commitment und wird nicht gestrichen. Ohne T-05 sage ich beim Gate No-Go zur Ökonomie.
- Lena liefert die HQ-Startwerte und die Gewichte W bis 17.11.
- Felix gibt mir genau 0,5 T für das F-09-Review, mehr nicht.
- T-07 und die SimWorld-Schnittstelle kommen verbindlich als Top-Tickets in S3, und zwar jetzt schon im Release-Backlog R1 eingetragen.
