# Für das Refinement Sprint 5 vorgemerkt

## SP-01 Spike: Betriebsprofile (Spezialisierung/Trade-offs) – Idee des Auftraggebers, 01.11.
Leitfrage: Erzeugen 2–3 Betriebsprofile je Industrie (z. B. Schnell / Ertrag / Qualität) echte Entscheidungen ohne dominante Strategie?
- Kein neues Gut je Variante (Getreide bleibt Getreide), sondern Profil-Parameter: Takt, Menge pro Zyklus, Preisfaktor beim Endabnehmer, Sättigungsrate.
- Vor dem Kauf wählt die KI das Profil; nach dem Firmenkauf steuert der Spieler es (Umstellzeit + Umstellkosten). Gibt dem Kauf einen Nutzen über die Marge hinaus (T-11-Befund: Kauf bringt zu wenig).
- Gleiches Muster für Fabriken (z. B. Massenware vs. Premium).
- Referenz nach D15: Factorio-Module, Anno-Produktionsoptionen; UI = Feld + Aktion im Kontextdialog mit Vorschau.
- Spike: Tobias rechnet 2–3 Profile im Headless-Modell durch (dominante Strategie? Zusammenspiel mit Sättigung/Stadtbedarf), Lena formuliert Regeln, Aylin ein Feld im Kontextdialog. Timebox 2 T. Bau erst nach positivem Ergebnis.

## SP-02 Erweiterung: Betriebsprofile für Transport – Idee des Auftraggebers, 01.11.
- Fahrzeuge/Linien bekommen ebenfalls Profile mit Trade-off, z. B. Güterzug "stärker befeuert": mehr Zuglast ohne Geschwindigkeitsverlust, dafür höherer Verschleiß/Wartung; umgekehrt "schonend": weniger Last/Tempo, geringer Verschleiß.
- Personenverkehr: Dreieck aus Löhnen (Personal), Wartung und Ticketeinnahmen (Ticketpreis als Hebel: Auslastung vs. Erlös).
- Güterverkehr hat keine Tickets → Hebel dort: Frachtrate/Vertragspreis? Liefertermin/Zuverlässigkeit? Ladungsmenge vs. Tempo vs. Verschleiß. Team soll das Pendant zum Ticketpreis für Güter vorschlagen.
- Prüfen: Passt in denselben Spike wie SP-01 (gemeinsames "Profil"-System für Industrien, Fabriken, Fahrzeuge)? Gefahr: Mikromanagement – Auftraggeber wünscht "einfaches Firmen-Mikromanagement" (Konzept). Default-Profil muss immer sinnvoll sein.
- Referenzen nach D15: Railway Empire (Wartung/Personal), Transport Fever (Ticketpreis? nur indirekt), OpenTTD (Fahrzeugalter/Zuverlässigkeit), Cities in Motion (Ticketpreise, Löhne).

## TEAM-01 Neue Rolle ab Sprint 5: Gameplay-/UI-Programmiererin (Auftraggeber, 01.11.)
- Wie im Projektplan für Januar vorgesehen; übernimmt Kontextdialog (F-15), Lizenz-Kauf-Flow, Diagnose-Aktion (A-08), Bau-Tool-Bugs. Felix bleibt beim Sim-Kern/Technik.
- Realistisches Onboarding: erster Sprint mit reduzierter Kapazität (ca. 50–60 %), Einarbeitung durch Felix (Code-Walkthrough, Pairing), erstes Ticket klein.
- Leitlinie des Auftraggebers: Den Entwicklungsprozess wie im echten Leben abbilden – Rollen kommen gestaffelt dazu, wenn Phase und Budget es erlauben (nicht alle von Anfang an). Weitere Rollen (Tools-Programmierung, Technical Artist, Audio, später Lokalisierung/Marketing) erst bei Bedarf und mit Begründung im Refinement bzw. Release-Review.

## D22 Konzeptänderung HQ-Start (Auftraggeber, 01.11.)
- Spielstart wie Civ: direkt auf der Karte das HQ in frei wählbarer Stadt/Dorf platzieren; KEINE Archetyp-Auswahl/Ausprägung. Spezialisierung entsteht über erste Lizenzen und Skilltree.
- Standort-Vorschau beim Hover: Einflussradius (Lizenzen im Radius günstiger), erreichbare Industrien/Ketten als Information, Stadtgröße (Nachfrage vs. teurere Lizenzen/KI-Konkurrenz; Dorf = Wachstumspotenzial), Gelände (Fluss/Küste für spätere Schiffe, Gebirge teurer). Keine festen HQ-Einnahmen.
- Folgen: ein Startkapital-Wert (Tobias), L-08-Archetyp-Regeln → Regel "Standort-Vorschau" (Lena), Platzierungsscreen im Theme (Aylin), Bau (Mira/Felix).
- Timing (vom Auftraggeber bestätigt): R1-Review 15.01. noch mit heutigem Startdialog; Lena schreibt das Konzept in S5 (kurzes Papier, 1 T); Bau als erstes Ticket in S6.
