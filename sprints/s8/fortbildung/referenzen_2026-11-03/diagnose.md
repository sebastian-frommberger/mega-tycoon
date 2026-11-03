# Diagnose und Rückmeldung: Referenzen (Stand 2026-11-03)

Aylin (UX) und Mira (Entwicklung). Marken: **[B]** belegt mit Quelle, **[E]** Eindruck aus dem Gedächtnis, ohne Quelle. Alle [B] stammen aus WebFetch-Zusammenfassungen eines kleinen Modells, nicht wörtlich geprüft. Zahlen in Klammern: Quellenliste unten.

**Aylin vorab:** Unser Vorteil ist real. `diagnostics.gd` kennt vier Wurzelursachen (Deadlock, Gegenverkehr, Warten auf Ladung, Block belegt) samt Kette. Keines der Referenzspiele, das ich gelesen habe, nennt dem Spieler eine Wurzelursache; sie zeigen Symptome. Im Slice sieht Basti davon nichts.

## 1. Warum läuft etwas nicht?

| Spiel | Mechanik | Quelle | |
|---|---|---|---|
| OpenTTD | Meldung "Zug X ist verirrt", Klick springt zum Zug; die Ursachen (Signal falsch, Gleis fehlt) stehen im Wiki, nicht in der Meldung | Q1 | B |
| OpenTTD | Stationsbewertung je Fracht aus Zeit seit Abholung, Wartemenge, Fahrzeugalter, Tempo; unter 50 % geht Fracht verloren | Q2 | B |
| OpenTTD | Fehlalarm: Schiffe "verirrt", obwohl sie Geld verdienen | Q3 | B |
| Factorio | Icon direkt am Objekt, bleibt bis der Zustand wechselt (kein Zugweg, Ziel voll, wenig Strom) | Q4 | B |
| Factorio | Zug-Statusicons seit 2.0; Forum: "Warten auf Platz" ist normal, kein Problem | Q5 | B |
| Satisfactory | Licht am Gerät: rot, gelb, grün; Gelb bündelt viele Ursachen, das Licht allein sagt nicht welche | Q6 | B |
| Anno 1800 | Statistik: Ist gegen Potenzial je Gut, Gebäudeliste mit Produktivität, Klick teleportiert; Ursache muss man selbst ableiten | Q7 | B (Fandom-Wiki) |
| Anno 1800 | Zustand über Animation (aktiv/Leerlauf), nicht über Warnungen | Q8 | B |
| Cities: Skylines | rund 20 Problemsymbole über Gebäuden (kein Strom, keine Straßenverbindung); Seite erklärt Ursachen nicht | Q9 | B |
| CS2 | Zufriedenheit listet positive und negative Faktoren: die klarste Ursachenerklärung dort | Q10 | B |
| Transport Fever 2 | Klick auf Station hebt Einzugsgebiet weiß hervor; Linien- und Gewinnanzeige nicht belegt (Wiki gesperrt) | Q11 | B / nicht belegt |
| Mini Metro | Spielende bei zu langer Überfüllung; Warnanzeige in den Quellen nicht beschrieben (mein Bild: Ring um die Station) | Q12 | E |

**Für uns (Aylin):** Zwei Muster tragen: Zeichen am Objekt, das bei Zustandswechsel verschwindet (Factorio), und Ist gegen Soll (Anno, Station-Bewertung). Schwäche aller: das Symptom ist sichtbar, der Weg zur Ursache nicht. Dort sitzt unser USP. Fehlalarme (Q3) kosten Vertrauen; unsere Schwelle `wait_ticks` entscheidet.
**Empfehlung (Mira):** Erst Zeichen am Wagen und Lager aus den vorhandenen `root_cause`-Werten, dann Klick auf Kette. Aufwand 2 bis 3 Tage, siehe Ideen A und B.

## 2. Meldungssysteme

| Quelle | Befund | Q | |
|---|---|---|---|
| OpenTTD | 9 Meldungsarten, je Aus / Zusammenfassung (Leiste) / Fenster | Q1 | B |
| Factorio | Alarme rechts der Schnellleiste, 5 bis 30 s je Typ, pro Typ abschaltbar | Q13 | B |
| Factorio-Forum | Spieler fordern Gruppierung, Verlauf, Wirkung je Typ (pausieren, zentrieren, nur anzeigen); flackernde Dauer-Icons nerven | Q14 | B (Forum) |
| Carbon (IBM) | Toast 5 s; Warnung/Fehler bleiben bis erledigt; Panel als Verlauf; mehrere Toasts stapeln; dieselbe Meldung nicht erneut senden | Q15 | B |
| SAP Fiori, WCAG 2.2.1 | eine Meldung zugleich; flüchtige Info muss anderswo bleiben | Resümee | nicht neu geprüft |

**Für uns (Aylin):** Die Praxis ist sich bei "eine oder gestapelt" nicht einig (Carbon gegen SAP). Einig ist sie bei drei Dingen: Verlauf, Dauer nach Dringlichkeit, keine Wiederholung. Mein Vorschlag: eine Meldung sichtbar, Zähler "+2", alles im Protokoll.
**Empfehlung (Mira):** `ToastQueue` mit Schlüssel `Ursache+Objekt`, Sperrzeit 60 s Spielzeit [H, Setzung], drei Stufen (Info 4 s, Warnung 8 s, Fehler bis Klick), Klick springt zum Ort. 1 Tag.

## 3. Überlagerungen und Lesbarkeit

| Spiel | Befund | Q | |
|---|---|---|---|
| CS2 | 33 Infoansichten, meist grün bis rot; eine zugleich | Q10 | B |
| Satisfactory | Auslastung in Prozent über rund 5 Minuten im Gebäude | Q16 | B |
| TF2 / TF3 | Einzugsgebiet weiß; TF3-Vorschau: Linien nach Effizienz gefärbt | Q11, Skill A4 | B / übernommen |
| Mini Metro | Farbe stets mit Form gepaart | Skill A4 | übernommen |
| Declutter/LOD für Problemzeichen | in keinem Spiel belegt | | nicht belegt |

**Für uns (Aylin):** Grün-Rot allein scheidet aus (Farbenblindheit, Skill A10). Problemzeichen dürfen nicht wie Orte nach Label-LOD verschwinden: sie bekommen eigene Priorität 0, gleiche Hysterese 8 %.
**Empfehlung (Mira):** Zeichen als eigene Ebene im `proto_schilder`-Overlay, Test mit dem dreifachen Knotenbestand (Regel C4.4). 1 Tag.

## 4. Verkehrsprobleme

| Spiel | Befund | Q | |
|---|---|---|---|
| Cities: Skylines | Fahrzeuge halten an Kreuzungen, wenn vorne blockiert; Spurwechsel wieder entfernt; im Gridlock Teleport zum Ursprung; Takt 4 Hz | Q17 | B |
| Factorio | Icons "kein Weg", "Ziel voll"; Deadlock-Erkennung nicht belegt (Signal-Wiki gesperrt) | Q4 | B / nicht belegt |
| OpenTTD | Meldung nennt Symptom; Deadlock-Erkennung nicht belegt (tt-forums gesperrt) | Q1 | nicht belegt |

**Für uns (Aylin):** Die Referenzen vereinfachen die Simulation (Teleport) oder erklären wenig. Wir simulieren Blöcke wirklich und erklären die vier Ursachen; ein Teleport würde den USP verstecken.
**Empfehlung (Mira):** Nichts wegzaubern. Deadlock als eigener Dauerzustand mit Zeichen, bis der Spieler eingreift. Aufwand in Idee B.

## 5. Eigene Ideen (Hirnen)

**A. Zustandszeichen am Wagen.** Ein Glyph (Form plus Farbe) nur bei Ausnahme: wartet auf Ladung, Block belegt, Gegenverkehr, Deadlock. Normales kurzes Warten bleibt still (Schwelle in `wait_ticks`).
Zielperson: Spieler mit stehendem Wagen. Kosten 1,5 Tage. Billigster Test: vier feste Glyphen als Debug-Overlay auf Bestandsfahrzeugen, drei Fremde fragen "Warum steht der?". Risiko: Rauschen bei großen Netzen, Fehlalarm.

**B. Ursachenkette per Klick.** Klick auf den Wagen hebt Symptom, Zwischenglieder, Wurzel auf der Karte hervor, ein Satz (max. 90 Zeichen, Klasse FT) nennt Ursache und Vorschlag (`suggestion_id`). Zielperson: Spieler, der verstehen will. Kosten 2 Tage. Test: Screenshot mit gezeichneter Kette auf Papier vorlegen. Risiko: Deadlock-Kreis (mehrere Wagen) schwer lesbar.

**C. Meldungsfluss mit Protokoll.** Queue, Wiederholungssperre, Sprung zum Ort (siehe Frage 2). Zielperson: alle. Kosten 1 Tag. Test: Sim-Lauf aufzeichnen, Meldungen je Spielminute zählen. Risiko: zu viele Meldungen trotz Sperre.

**D. Soll-Ist-Marke am Lager.** Kleiner Balken am Industrieschild: `fuell_ist` gegen `fuell_soll`, dazu Wagenanzahl (Daten liegen in `WARTEN_AUF_LADUNG`). Antwort auf "wo fehlt Ladung". Kosten 1,5 Tage. Test: statischer Balken im Prototyp-Schild. Risiko: Schild wird zu voll (Plakette 22 bis 34 px).

**E. Diagnoseansicht auf Taste.** Eine Taste dimmt die Welt und zeigt nur Problemzeichen (wie Alt-Modus, Taste N für Schilder besteht schon). Normalansicht bleibt ruhig. Kosten 1,5 Tage. Test: in der Prototyp-Welt mit Taste belegen. Risiko: Spieler entdeckt sie nie; Hinweis über Idee C.

**Nicht belegt:** ob die Sim Kosten je Streckenabschnitt kennt ("was kostet die Strecke"). Das klärt Mira im Code, bevor wir eine Linienbilanz planen.

## Neue Lern-Zeilen

- 2026-11-03 | Referenzspiele auf Ursachenanzeige gelesen | wusste nicht, ob irgendein Spiel Wurzelursachen nennt: keines belegt | USP-These bleibt [E], Test mit 3 Fremden bleibt nötig
- 2026-11-03 | Meldungsregeln: SAP (eine zugleich) gegen Carbon (stapeln) | Skill führt nur SAP | beide nennen, Entscheidung als Setzung [H]
- 2026-11-03 | TF2-Wiki, tt-forums, Factorio-Signal-Wiki nicht abrufbar | Linienanzeige und Deadlock-Verhalten ungeprüft | als Lücke führen, nicht raten
- 2026-11-03 | OpenTTD-Fehlalarm bei Schiffen | Schwelle für "verirrt/wartet" ist Vertrauensfrage | `wait_ticks`-Schwelle als Testwert festlegen

## Vorschläge für Skill-Änderungen (nur Vorschläge)

1. mt-ux A5: Zeile "Warnungen ohne Modal" um Carbon ergänzen: Toast 5 s, Warnung bleibt, Verlauf im Panel, keine Wiederholung [B].
2. mt-ux A4: Satisfactory-Ampel und Anno Ist-gegen-Potenzial aufnehmen.
3. mt-ux C: Lücke "Problemzeichen und Label-LOD" eintragen.
4. mt-gameplay-ui-dev B4: Zeile Toast mit Verweis auf Queue-Entwurf (Schlüssel, Sperrzeit [H]).
5. Beide: Fandom-/Forenquellen als [S] statt [K] führen.

## Quellen

Q1 https://wiki.openttd.org/en/Archive/Manual/Settings/Message%20settings und https://wiki.openttd.org/en/Archive/Manual/Settings/Train%20is%20lost%20warning
Q2 https://wiki.openttd.org/en/Manual/Game%20Mechanics/
Q3 https://github.com/OpenTTD/OpenTTD/issues/8937
Q4 https://wiki.factorio.com/Warnings
Q5 https://forums.factorio.com/viewtopic.php?p=548038
Q6 https://satisfactory.wiki.gg/wiki/Indicator_Light
Q7 https://anno1800.fandom.com/wiki/Statistics
Q8 https://anno-union.com/author/bb_volty/page/12
Q9 https://www.gamepressure.com/citiesskylines/notifications-trouble/za758f
Q10 https://gameplay.tips/guides/cities-skylines-ii-info-views-guide.html
Q11 https://guides.magicgameworld.com/?p=2707
Q12 https://en.wikipedia.org/wiki/Mini_Metro_(video_game) und https://gamerhorizon.com/2014/10/16/indiecade-2014-mini-metro-mega-fun/
Q13 https://wiki.factorio.com/Alerts
Q14 https://forums.factorio.com/viewtopic.php?p=542598
Q15 https://v10.carbondesignsystem.com/patterns/notification-pattern/
Q16 https://satisfactory.wiki.gg/wiki/Productivity_Display
Q17 https://www.gamedeveloper.com/design/how-traffic-works-in-cities-skylines
Nicht erreichbar: wiki.transportfever2.com, wiki.factorio.com/Railway/Train_signals und /Alt-mode (PROVENANCE_REQUIRED), tt-forums.net (Anubis-Sperre), Reddit-Spiegel (nicht genutzt). Railway Empire und Shapez: nicht recherchiert.
