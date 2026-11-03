# Außerordentlicher Design Sprint „Welt“ – Charter (Jonas, Katrin; 02.11.2026)

**Status:** Außerordentliche Session außerhalb der Sprintzählung. Sprint 8 (Firmenkauf, Skilltree, Progression nach M7) folgt danach. Auftraggeber entscheidet am Ende (Entscheider-Rolle wie im Design Sprint).

## Anlass
Bastis Rundgang durch die S7-Welt (`sprints/s8/feedback_02-11/`): Proportionen, Anordnung, Verteilung, Städte, Gelände und Wasser überzeugen noch nicht. Technik und Look der Bausteine tragen, aber es fehlt ein gemeinsames Regelwerk der Welt.

## Leitplanken von Basti (verbindlich)
- Wesentlich sind **Proportionen, Anordnung und Verteilung**; Assets sind austauschbar.
- Epoche als Andeutung: frühes 19. Jahrhundert. Ein Auto darf eine Kutsche oder ein Pferd sein, Häuser müssen nicht streng zeitgetreu sein.
- Das Asset Pack (Kenney All-in-1) wird systematisch ausgeschöpft; Basti besorgt bei Bedarf ein weiteres Pack.
- Recherche und Referenzen vor und während des Sprints.
- Neue Rollen sind einverstanden.

## Rollen
| Rolle | Neu? | Aufgabe in diesem Sprint |
|---|---|---|
| Art Director (Welt) | neu | Design-Prinzipien, Skalen-Tabelle, Look-Regeln der Welt, Abnahme der Prototyp-Szene |
| Technical Artist (TEAM-02) | neu, schon für S8 vorgesehen | Asset-Audit, Maßstab-Normalisierung, Gelände (Biome, Relief, Wasser), Kachel-/LOD-Regeln |
| Stadt-/Level-Designer | neu | Stadtmodell (Haustypen, Einwohner je Haus, Wachstum, Stadt-KI), Verteilungs- und Anordnungsregeln |
| Lena, Tobias, Sophie, Aylin, Felix, Mira, Daniel, Jonas, Katrin | bestehend | Beratung und Gegenprüfung (Spiel- und Wirtschaftsfolgen, UX, Technik, Abnahme) |

## Ablauf (5 Phasen)
1. **Verstehen:** Recherche (`designsprint/referenzen.md`), Asset-Audit (`asset_audit.md`), Bestandsaufnahme der Proportionen im Spiel. Ergebnis: gemeinsame Faktenbasis.
2. **Skizzieren:** Skalen-Tabelle (Haus, Straße, Fahrzeug, Industrie, Fluss, Stadtgrößen), Stadtmodell, Landschaftsregeln, Verteilungsregeln als Vorschläge, jeweils mit Gegenposition.
3. **Entscheiden:** Streitprotokoll, Jonas als PO, Basti entscheidet offene Grundsatzfragen. Ergebnis: **Welt-Regelwerk v1** (Design-Prinzipien, Skalen, Regeln), in Daten (JSON) wo möglich.
4. **Prototyp:** Eine kleine Prototyp-Welt (z. B. 1 Dorf, 1 Kleinstadt, 2 Industrien, Fluss, Hügel) mit echten Proportionen, Fuhrwerk/Pferd statt Lkw, belebten Blöcken. Messbar gegen die Skalen-Tabelle.
5. **Test:** Rundgang mit Basti (Aufgabenkarten), Feinschliff, Freigabe für die Umsetzung im Generator (W-03/W-05/W-06) in Sprint 8.

## Ergebnisse (Definition of Done)
- [ ] Design-Prinzipien (max. 1 Seite): was die Welt ausmacht, was sie nie tut.
- [ ] Skalen-Tabelle in Metern und Feldern, inklusive bewusster Überhöhung von Spielobjekten (Faktor, Begründung).
- [ ] Stadtmodell: Haustypen, Einwohner je Haus, Wachstum (Upgrade kleiner → größer), Straßenanlage durch die Stadt, Dorfformen (Haufen-, Straßen-, Angerdorf).
- [ ] Landschaftsregeln: Relief, Biome/Böden, Wasser (Breiten), Gebirge (Rauschen runter), Flussbreiten und Brücken.
- [ ] Verteilungsregeln: weniger konstruierte Reviere, mehr Streuung, Abstände zwischen Orten.
- [ ] Asset-Mapping: Haus-, Fahrzeug-, Industriemodelle je Rolle, Lückenliste, Empfehlung für ein weiteres Pack.
- [ ] Prototyp-Szene, gemessen gegen die Skalen-Tabelle (kein Objekt außerhalb ±25 %, außer bewusster Überhöhung).
- [ ] Rundgang mit Basti und seine Freigabe.

## Nicht Teil dieses Sprints
Firmenkauf, Skilltree, Energie und Pendler (Konzept liegt bei Lena/Tobias für S8), Terrain-LOD (Technik), neue Spielregeln.

## Risiken
- Epoche und Assets reißen auseinander → Andeutung genügt (Basti), Platzhalter sind erlaubt.
- Regelwerk bleibt Papier → der Prototyp ist Pflicht, nicht optional.
- Tokenlimit → Agenten arbeiten auf Opus/Sonnet, Recherche gezielt (12–20 Quellen), kein Fable.

## Entscheidungen von Basti (02.11., 21:36)
| # | Entscheidung | Folge |
|---|---|---|
| E1 | Nichts wird überzeichnet, alles steht **im Verhältnis zueinander** (Haus : Straße : Fahrzeug : Industrie : Fluss). | Skalen-Tabelle mit festen Verhältnissen. Lesbarkeit kommt aus Icon, Name, Farbe und Zoom, nicht aus Größe. Einzige Toleranz laut Vorschlag: Fahrzeuge höchstens 1,2× real („macht das so mit den Fahrzeugen“). |
| E2 | Das Wasser bekommt einen **einfachen Shader**, entworfen im Design Sprint. | Technical Artist: Wasser-Shader (Farbe nach Tiefe, Ufer, leichte Bewegung) im Prototyp. Breiten realistisch im Verhältnis, nicht überzeichnet. |
| E3 | **Siedlungszahl folgt aus den Prinzipien**, nicht aus einer Zahl: Was steht hinter mehr oder weniger Städten? Was heißt das fürs Spiel, für Strecken und Lieferketten? | Welt-Prinzipien beantworten diese Kette vor der Verteilungsregel. |
| E4 | **Start 1820.** Das Startjahr wird später **wählbar** für Spielende (Option). | Epoche als Datenparameter (Regelwerk bekommt `startjahr`), keine Festverdrahtung. |
| E5 | Offene Frage (eher nicht Design): wie äußern sich **Schwierigkeitsgrade**? | Kurzes Papier von Tobias/Lena im Sprint (Hebel), Entscheidung in S8. |

## Entscheidungen von Basti zu den Fragen aus Phase 3 (02.11., 23:06)
| # | Entscheidung | Folge |
|---|---|---|
| E6 | F1 **B**: gestufte Ortsordnung (2 Kleinstädte, Marktflecken, viele Dörfer). | Wie im Regelwerk v1. |
| E7 | F2 **C**: Orte bleiben ohne Versorgung stabil, wachsen nur mit Versorgung. | Wie im Regelwerk v1. |
| E8 | F3: Die Partie reicht **bis in die Moderne (heute)**, nicht nur bis 1900. | Epochen-Tabelle bis heute: Gebäudestile, Fahrzeugkategorien, Stadtgrößen bis Großstadt je Epoche; Prototyp bleibt 1820. Kenney City/Car-Kit werden für spätere Epochen interessant. |
| E9 | F4 **A**, aber mit **Fahrzeug-Easing je Kategorie** (nicht je Modell): Fahrzeuge fahren nicht wie ein Schuhkarton um die Ecke. | Bewegungsprofile je Kategorie (Anfahren, Bremsen, Kurventempo, Wippen); nur Darstellung, Sim bleibt in Feldern. |
| E10 | F5 **C bzw. je nach Einstellung**: Gewässer, Flüsse und Seen mit **sichtbarer sinnvoller Nutzung**. | Kartentyp/Wasseranteil als Einstellung (Flusstal, Seenplatte, Seenreich); Nutzung sichtbar (Mühle, Fischer, Steg, Fähre, Hafen, Holztrift), Schiffsverkehr als Folgefrage. |
| E11 | F6 **B** plus Parameter **Konkurrenz** (fehlte). | Schwierigkeitshebel Konkurrenz (Zahl, Stärke der KI-Firmen) in `04_schwierigkeit`. |

## Entscheidungen von Basti zu den Fragen aus Phase 3b (03.11., 06:26)
| # | Entscheidung | Folge |
|---|---|---|
| E12 | Kalendertempo (Dauer 1820 bis heute) **wählbar**. | Datenparameter Zeit je Spieljahr, im Prototyp nur Hülle. |
| E13 | Kartengröße: **bleibt zunächst bei der heutigen Karte** (Großstadt bis ca. 100.000). | Größere Karte später. |
| E14 | Konkurrenz **per Default an, sichtbar auf den Straßen**; im Freien Spiel später **abschaltbar**. | Schwierigkeitshebel Konkurrenz mit „aus“-Stufe; S8 (Bot als Grundlage). |
| E15 | Wasser als Verkehrsweg: **theoretisch von Anfang an mit Flößen**. | Floß als erstes Wasserfahrzeug (Holz/Stein flussabwärts), Mechanik-Entscheidung Lena/Tobias in S8/S9; im Prototyp nur als Kulisse mit Funktion auf dem Fluss. Fähre und Schiffe später. |
Phase 4 Welle 1 (Variante schlank) gestartet 03.11. 06:50; Vertrag unter `/tmp/claude-0/gd/designsprint/p4/VERTRAG.md` (Arbeitskopien je Rolle).
