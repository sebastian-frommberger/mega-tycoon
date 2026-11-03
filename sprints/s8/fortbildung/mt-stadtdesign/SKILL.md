---
name: mt-stadtdesign
description: Stadt- und Leveldesign für Mega Tycoon (Godot-Transporttycoon 1820 bis heute): Siedlungshierarchie, Dorfformen, Ortsklassen, Verteilung, Poisson/Eignung, Anti-Revier, Stadtwachstum und Stadt-KI, Wasser. Nutzen bei Orten, Weltgenerator, Validatoren, Verteilungsregeln.
---

# Stadt-/Level-Designer (Wissensstand nach Fortbildung, 03.11.2026)

Rolle: Stadt- und Leveldesign (Siedlungsmodell, Haustypen, Wachstum, Stadt-KI, Verteilungs- und Anordnungsregeln). Aufbau: Teil A allgemeines Fachwissen mit Quellen (Sx, Liste am Ende von Teil A), Teil B nur Belegtes aus `/home/claude/mega-tycoon` (Datei je Aussage; das Repo markiert viele eigene Zahlen selbst als [~] Fachwissen oder [A] Annahme, das wird mitgeführt), Teil C eigene Lücken und Konfidenz.

Kennzeichen: [K] Konsens (mehrere Quellen oder Lehrbuchstand), [S] Streit (Quellen widersprechen sich), [E] Einzelmeinung oder Einzelquelle, [R] eigene Rechnung oder Folgerung (nachprüfbar, keine Quelle), [~] aus dem Gedächtnis, nicht geprüft, [M] im Repo gelesen. Im Repo heißt [Q] Quelle zitiert, [A] Annahme, [~] Fachwissen ungeprüft, [M] im Code gemessen.

Ehrliche Vorbemerkung: Reddit (r/proceduralgeneration, r/CitiesSkylines, r/gamedev, r/openttd, r/TransportFever) war per WebFetch gesperrt (SITE_BLOCKED) und wurde nicht umgangen (keine Spiegelserver). tt-forums.net (Anubis) und wiki.openttdcoop.org (robots.txt) waren nicht lesbar. Meinungen aus Generator-Foren fehlen deshalb. Genutzt wurden Wikipedia, Entwickler-Devlogs, Originalpapiere, Heimatkunde-Lexika.

---

# TEIL A: Allgemeines Fachwissen

## A1 Zentrale-Orte-Theorie (Christaller) und Rang-Größe
- Christaller: hexagonale Marktgebiete; Prinzipien K=3 (Marktprinzip), K=4 (Verkehrsprinzip), K=7 (Verwaltungsprinzip); sieben Ordnungen. Kritik [K]: isotrope Ebene, rationale Konsumenten, statisch, Eisenbahn prägte Städte (S1). Der Artikel enthält keine Kilometerangaben.
- Geometrie [R]: Wächst die Marktfläche je Ordnung um den Faktor K, wächst der Abstand gleichrangiger Zentren um √K: K=3 ≈ 1,73, K=4 = 2,0, K=7 ≈ 2,65. Anzahl bei K=3: Ein Zentrum der Ordnung n+1 umfasst sich selbst und zwei Zentren der Ordnung n, also Verhältnis 1 : 2 : 6 : … für Zentren jeder Ordnung (Kleinstadt : Marktflecken : Dorf).
- Rang-Größe-Regel: P_r = P_1 / r (α = 1). Eine Studie 2002 verwirft Zipf in 53 von 73 Ländern; „King effect“ (Primatstadt größer als vorhergesagt); die Gesamtverteilung wird eher lognormal erklärt (Gibrat); die Regel dient dem Ländervergleich, nicht der Prognose (S2). [S/E]
- Verwendung im Generator [R]: Christaller und Rang-Größe sind Plausibilitätsprüfer für Ortszahlen und Abstände, keine Generatoren. Als Test auf Klassenlücken taugt Rang-Größe: Zwischen zwei Klassen darf keine Größenlücke größer als etwa der Faktor 2 klaffen, sonst fehlt eine Klasse.
- Realdaten Deutschland (S14, S15, S11): 412 Städte mit mindestens 5.000 EW zwischen 1500 und 1850 (Pfister); Verstädterungsrate stagniert, beginnt um 1800 zu wachsen, Jahrzehnte vor der Industrialisierung (ohne Zahlenwerte in der Zusammenfassung). 1871 lebten 63,9 % der Reichsbevölkerung in Orten unter 2.000, 1900 45,6 %; Städte über 10.000: 271 (1875), 576 (1910); über 200.000: 3 auf 23. Für 1800 und 1850 enthielten die geöffneten Quellen keine Anteile.
- Dorfgrößen (S11, Lienau/Henkel): Weiler 20–100 Hofstätten und bis ca. 100 EW; kleines Dorf unter 100 Hofstätten und unter 500 EW; normales Dorf unter ca. 400 Hofstätten und unter ca. 2.000 EW; Faustformel 4–5 EW je Hausstätte. Die Quelle ist bei der Abgrenzung des kleinen Dorfs widersprüchlich, Grenzen schwanken je Autor [S]. Gruppensiedlung ab Hausabstand unter ca. 150 m. Bayern 1950: ab 10 Wohngebäuden. Brandenburgische Kolonistendörfer nach 1157, Gemeindebildung vorrangig 12./13. Jahrhundert.

## A2 Dorfformen und ihre Lage
- Haufendorf (S10, S11): unplanmäßig, unregelmäßige Grundstücke, oft von einem Ortsetter umgeben, mit der mittelalterlichen Gewannflur (verstreute Feldstreifen) verbunden; Gemarkung gegliedert in Dorfkern, Ackerflur, Allmende. Verbreitungsgebiet und Lage (Quelle, Furt, Kreuzung) nennt der Text nicht.
- Straßendorf (S10, S11): linear, meist doppelzeilig, Häuser giebelständig, Abzweigungen oft Sackgassen. Angerdorf: gestreckt runder Anger im Gemeindebesitz mit Teich oder Brunnen, Grundmoränenplatten und Lössgebiete, in Deutschland vor allem Ost- und Ostmitteldeutschland. Straßenangerdorf (Nordostösterreich, Teile Brandenburgs). Reihendorf an Bach, Graben oder Deich. Waldhufendorf (planmäßige Rodung, z. B. östlich der Saale). Rundling (Saale–Elbe), Wurtendorf (Marsch), Kompaktdorf (Alpen), Streusiedlung (Münsterland, Schwarzwald).
- Folgerungen [R]: Lagebezug im Generator: Talboden/Bach → Straßen- oder Reihendorf; Mulde mit Wasser → Angerdorf; Kreuzung/Ebene → Haufendorf. Regionale Form dominiert (Ost/West), darum Regionsgewicht je Seed. Weiler und Streusiedlung sind kein „kleines Dorf“, sondern eine eigene Klasse.
- Etter-Ring, Allmende, Gewannflur sind Bildmotive für den Ortsrand: Gartenring, dann Acker in Streifen. [R]
- Wasserkraft: Wassermühlen brauchen aufstaubare Bäche (S12). Die Wikipedia-Seite Wassermühle liefert keine Dichte- oder Leistungszahlen (Lücke).

## A3 Ortsdichte und Mühlen als Eichwert (Kurmark um 1800)
- 1801: 2.053 Dörfer, 427 ländliche Wassermühlen, 638 Windmühlen, 330 Stadtmühlen; Rechnung [R]: 0,52 ländliche Mühlen je Dorf, davon etwa 40 % Wasser. Dörfer je Mühle: Altmark 1,5, Prignitz 2,8, Uckermark 2, Mittelmark 2,1. Landbevölkerung ca. 56 % der Gesamtbevölkerung; Berlin 172.132 EW (1800). Wassermühlen brauchen aufstaubare Bäche; Windmühlen häufen sich bei Berlin und Potsdam. Mühlenbann fiel 1810 (S12).
- Köhlerei (S13): Meiler 4–30 m lang; 40–50 Raummeter Holz je Brand; Meilerplätze liegen im Forst (Peitz/Gottow/Jänschwalde ca. 1.300 Grundrisse); Holzkohle für Hammerwerke (Peitz 2,1 Zentner Kohle je Zentner Roheisen).
- Chaussee (S21): 8–10 m breit, 3–5 % Steigung, Chausseehaus alle 1–1,5 Wegstunden, Preußen ab 1788 Magdeburg–Halle–Leipzig über 100 km. Floß (S22–S24): siehe Skill `mt-gamedesign` A5; für den Stadtbau relevant sind Flößerorte (Wolfach 1763: 20 % der Erwerbsbevölkerung), Schwellweiher und Gestör-Bindeplätze am Unterlauf.

## A4 Wahrnehmung von Stadt (Lynch) und Lesbarkeit
- Lynch, The Image of the City (S3): fünf Elemente: Paths (Wege), Edges (Ränder), Districts (Viertel), Nodes (Knoten), Landmarks (Orientierungspunkte). [K]
- Übersetzung [R]: Wege = Chaussee, Dorfstraße, Gasse; Ränder = Mauer, Etter, Fluss; Viertel = Altstadt, Vorstadt, Bahnhofsviertel; Knoten = Markt, Kreuzung, Tor; Landmarken = Kirchturm (≥ 3× Traufe), Mühle, Schlot. Jede Siedlung braucht mindestens je eine Landmarke und einen Knoten; sonst ist sie „konstruiert“ oder konturlos.
- Lesbarkeit aus der Ferne (S9, Townscaper): große Formen vorhersagbar halten, kleine Details variieren, Übergänge betonen, Struktur vor Dekor, Dichte bei Entfernung vermeiden (Rauschen).

## A5 Prozedurale Platzierung (Algorithmen mit Eckdaten)
- Bridson-Poisson-Disc (S4): Kandidaten im Ring r bis 2r um bestehende Punkte, k = 30 Versuche je Punkt, Rasterzelle r/√n (n = Dimension), O(N); keine variable Dichte. [K]
- Karten nach O'Leary (S5): ca. 16.384 Punkte, Lloyd-Relaxation einmal; Flüsse ab Fluss-Schwellwert; Städte per Score (Flussbonus minus Nähe zu bestehenden Städten minus Nähe zum Kartenrand), greedy iterativ; Territorien per Pfadkosten, enden an Graten und Flüssen. Red Blob Games (S6): Poisson-Disc + Delaunay, Dreiecksschwerpunkte als Ecken, Höhe per Breitensuche von der Küste, Entwässerungsbaum (jede Ecke zeigt zum tiefsten Nachbarn; ein Seed wählt unter gültigen Graphen), Flüsse als Teilmenge, Feuchte per Breitensuche von Wasser. Die Ideen „Siedlung an Zusammenflüssen und Mündungen“ im Abruf stammen vom Abrufwerkzeug, nicht von der Seite [E].
- Ortsgeneratoren (S7 Watabou): Mauern optional; Wasser nicht unterstützt, weil schwierig; das Gassenverfahren nennt der Autor „silly“ (zu viele dreieckige Häuser); Stadtgenerator, kein Kartengenerator. Agentenansatz (S8, arXiv 2507.18899): L-Systeme (Parish/Müller), Agenten Extender und Connector, Rasterabweichung, Konnektivitätskonstante k (steuert Schleifen gegen Sackgassen), nur tertiäre Straßen, Bewertung qualitativ.
- Wave Function Collapse (S9): Constraint-Löser; harte Constraints (Kanten passen) gegen weiche (Wiederholung vermeiden); Bad North prüft Erreichbarkeit (jedes Haus vom Strand) und startet bei Fehler neu; Townscaper darf still scheitern; lange dünne Strukturen scheitern oft; Reskin ≈ 500 Kacheln; unregelmäßiges Raster = Sechseck, in Vierecke geteilt, nochmals geteilt, Punkte verschoben (Verzerrung auf Straßenhöhe kaum sichtbar).
- OpenTTD-Stadt (S16): Straßen entstehen per Random Walk, der nach Distanz aufgibt; Kreuzung alle 2–3 Felder; Wachstum ersetzt Häuser durch größere und baut neue an Stadtstraßen; Bank ab 1.200 EW; 1 Mio. EW ≈ 150–200 Felder Durchmesser. TTD-Original (S17): Straßen-Walk höchstens 20 Schritte; Transportzone-Radius 2 Felder (0–3 Gebäude) bis 9 (36–71 Gebäude); ab 72 Gebäude Radius 0.
- Messgröße „konstruiert“ [~ Clark-Evans]: Nächster-Nachbar-Index R = mittlerer Nachbarabstand / erwarteter Abstand bei Zufall (0,5/√Dichte). R < 1 Klumpen, 1 Zufall, bis etwa 2,15 hexagonal-regelmäßig. Nicht in den geöffneten Quellen belegt, aber Standardstatistik; das Repo verwendet sie.
- Fehlende Dichteregelung: Bridson kennt keine variable Dichte. Praxislösung [R]: Abstände je Paar (Klassenmatrix) und Eignungsfilter durch Akzeptanzwahrscheinlichkeit p = S/1.000, danach nicht sättigen (sonst Gleichabstand).

## A6 Wachstumsmodelle
- Referenzen: OpenTTD (S16, S17): 50-Tage-Fenster, Wachstumsintervall nach Zahl aktiver Stationen (0: 160, 1: 210, 2: 150, 3: 110, 4: 80, ab 5: 80), Cities doppelt so schnell. Peter1138 (S18, Community-Vorschlag [E]): 7 Klassen von unter 300 bis 15.500 EW; Wachstum nur bei erfüllter Nachfrage; unter 150 EW wächst ein Ort von selbst. Anno (S19): Stufenaufstieg über volles Haus, Grundbedarf, Baumaterial. TF2-Foren (S20, [S]): Basisgröße plus Prozentboni; natürliche Orte bis etwa 2.700, Cluster 3.000+; Basisbevölkerung wächst laut einem Poster bis +50 %, laut einem anderen gar nicht. Mod-Konzept (S25): Euphorie bei Stufenwechsel.
- Reihenfolge nach Verdichten vor Ausdehnen [R aus S16 „ersetzt Häuser durch größere“]: erst Lücken, dann Upgrade, dann Teilung, dann Vorstadt, dann Gasse, dann Platz. Das ist die Regelwerk-Reihenfolge (Teil B).
- Determinismus [R]: Wachstum muss je Ort und Monat deterministisch rechnen (RNG aus Welt-Seed, Ort-ID, Monat), sonst sind Bot-Messungen und Replays nicht vergleichbar.

## A7 Wasser und Siedlung
- OpenTTD (S26): Docks an gerader Küste, Einzugsradius 5 Felder; Schiffe auf Meer, Kanal, Fluss (ebene Felder); Höhenwechsel nur per Schleuse; Aquädukte ohne Höhenwechsel.
- Siedlungslage [R aus S5, S6, Teil B]: Wasser nah und hochwasserfrei, Furt oder schmale Stelle, Talkreuzung, Talrand. Aue direkt ist teuer (Hochwasser), Waldinneres unattraktiv. Mühlen am Bach, nicht am Strom (Aufstau). Ob eine Furt eine Siedlung erzeugt oder nur eine Brücke, ist Designentscheid.

## A8 Checkliste Ortsgenerator
1. Hierarchie festgelegt (Klassenzahlen, Abstandsmatrix, Rang-Größe-Test). 2. Eignungsfunktion mit Gewichten und Ausschlüssen (Wasser, Steilheit, Aue, Wald, Höhe). 3. Platzierung: zentrale Orte zuerst (best-candidate mit Mindest-S), dann Dörfer (Poisson mit Abstandsmatrix und Akzeptanz), dann Industrien in die Zwischenräume. 4. Validator mit harten Fehlern (Erreichbarkeit, Abstände, Steigung) und weichen (Clark-Evans, Kachelabdeckung). 5. Erfüllbarkeit über viele Seeds messen (Repo: ≥ 18 von 20). 6. Siedlungsform nach Lage, nicht nach Würfel. 7. Mindestens eine Landmarke und ein Knoten je Ort. 8. Wachstum deterministisch. 9. Wasser nur mit sichtbarer Nutzung. 10. Leistungsbudget je Epoche prüfen.

## A9 Typische Fehler
- Reviere: Industrien zuerst, Orte drumherum (S7 des Projekts), erzeugt Pärchen und Baukasten (Basti: „zu konstruiert, zu zusammengewachsen“).
- Ein Raster in Altstadt oder Dorf (Basti: „geometrisch“); Raster nur mit historischem Grund (Bahnhofsviertel).
- Gleiche Blöcke wiederholen (kein Ort mit zwei gleichen Blöcken, P3).
- Lage ohne Grund („steht hier, weil …“ fehlt).
- Sättigende Poisson-Streuung ohne Eignungsfilter: Gleichabstand wirkt künstlich (Bridson kennt keine variable Dichte).
- Wasser nur als Hindernis (Watabou-Generator unterstützt es nicht, S7; Seen ohne Querungen erzeugen Umweg-Labyrinthe).
- Klassenlücken: zwischen Dorf und Marktflecken fehlt eine Größe (Rang-Größe-Test, siehe B3).
- Drift zwischen Dokumenten: gleiche Größe in zwei Tabellen (Repo: Clark-Evans-Band 1,0–1,6 und 1,2–1,7, B10).

## A10 Straßennetz: Topologie und Hierarchie
- Historische Dorfstraßen bilden überwiegend T-Einmündungen und Sackgassen; 4-armige Kreuzungen sind selten [~, im Straßendorf ausdrücklich: Abzweigungen oft Sackgassen, S10]. OpenTTD setzt eine Kreuzung alle 2–3 Felder (S16) und wirkt dadurch rasterartig; das ist für 1820 ein Gegenbild.
- Agentenansatz (S8): Konnektivitätskonstante k steuert Schleifen gegen Sackgassen. Ein einziger Wert genügt, um Ortscharakter zu verschieben (viele Schleifen = planmäßig, viele Sackgassen = organisch). Der Ansatz erzeugt nur tertiäre Straßen, das übergeordnete Netz (Chaussee) muss gesetzt werden.
- Hierarchie [R]: Chaussee (Fernverbindung, Steigung 3–5 %, Allee, Brückenstellen am schmalsten geraden Punkt), Hauptstraße/Dorfstraße (Kern), Gasse (Verdichtung), Feldweg (Hofzufahrt, Flur). Jede Stufe hat eigene Breite, Radius und Steigungsgrenze (Teil B1).
- Sim und Bild trennen: Die Spielkante läuft zwischen Feldmitten, das Bild darf bis ±20° und ±8 m abweichen, solange es im Feldband bleibt (Repo-Empfehlung `05_stadtmodell.md` §3); allgemein [R]: Lesbarkeit der Fahrbahn aus der Sim, Natürlichkeit aus dem Bild.

## A11 Vorgehen bei Ortsbild und Dichte
- Von außen nach innen planen [R]: erst Lage und Gelände (Eignung), dann Wegenetz, dann Parzellen, dann Gebäude, zuletzt Dekor (Bäume, Zäune, Heu). Townscaper trennt Struktur und Dekor genauso (S9).
- Dichte als Kennzahl: Das Repo gibt Dorf 25–40 EW je ha an (`regelwerk.json › ortsklassen.dorf.dichte_ew_je_ha`). Für 250 EW gilt dann 6–10 ha, Radius 140–180 m [R]; das liegt im Regelwerkband 125–200 m. Eine Kennzahl dieser Art ist besser als „sieht richtig aus“, weil Validator und Rundgang sie prüfen können.
- Lücken sind Wachstumsraum: Ein Dorf mit ca. 15 % freien Parzellen (Erlenbach 7 von 44 ≈ 16 %) zeigt Wachstum sichtbar und braucht keine neue Fläche.
- Ränder und Übergänge: Etter, Obstwiese, Flur. Übergänge zwischen Boden, Ort und Wald sind die Stellen, an denen Generatoren auffallen (S9: „es kommt auf Übergänge an“).

## A12 Leistung und Detailstufen für Orte
- Instanzen als MultiMesh je Typ; Kachel-Proxys für die Ferne; Baum-Dreiecke deckeln (Repo-Regeln in Teil B6). Allgemein: Wiederverwendung (Prefab-Varianten) statt Einzelmodelle, Variation über Rotation, Jitter und Material statt über Mesh-Anzahl [R aus S9 „Tileset-Größe ≈ 500 für Reskin“].
- Ein Generator, der in 40 s einen 2×1,6-km-Kern erzeugt (Repo-Prototyp), skaliert nicht automatisch auf 12,8 km; Laufzeit und Speicher auf der Vollkarte sind ungemessen (Teil B8).

## Quellen Teil A (per WebFetch geöffnet, außer „nur Suchtreffer“)
- S1 Wikipedia Central place theory https://en.wikipedia.org/wiki/Central_place_theory
- S2 Wikipedia Rank–size distribution https://en.wikipedia.org/wiki/Rank%E2%80%93size_distribution
- S3 Wikipedia The Image of the City https://en.wikipedia.org/wiki/The_Image_of_the_City
- S4 Bridson, Fast Poisson Disk Sampling (PDF) https://www.cs.ubc.ca/~rbridson/docs/bridson-siggraph07-poissondisk.pdf
- S5 O'Leary, Generating fantasy maps https://mewo2.com/notes/terrain
- S6 Red Blob Games, Polygon map generation https://www.redblobgames.com/maps/polygon-map-generation/
- S7 Watabou, Devlog „some answers and comments“ https://watabou.itch.io/medieval-fantasy-city-generator/devlog/1579/some-answers-and-comments
- S8 arXiv 2507.18899, agentenbasierter Stadtgenerator (Vorschlag) https://arxiv.org/pdf/2507.18899
- S9 Game Developer, How Townscaper works https://www.gamedeveloper.com/game-platforms/how-townscaper-works-a-story-four-games-in-the-making
- S10 Wikipedia (de) Haufendorf https://de.wikipedia.org/wiki/Haufendorf
- S11 Wikipedia (de) Dorf https://de.wikipedia.org/wiki/Dorf
- S12 Brandenburgikon, Mühlenwesen https://www.brandenburgikon.net/index.php/de/sachlexikon/muehlenwesen
- S13 Brandenburgikon, Köhlerei https://brandenburgikon.net/index.php/de/sachlexikon/koehlerei
- S14 Pfister, Urban population in Germany 1500–1850 (nur Zusammenfassung) https://ideas.repec.org/p/cqe/wpaper/9020.html
- S15 Wikipedia Urbanization in the German Empire https://en.wikipedia.org/wiki/Urbanization_in_the_German_Empire
- S16 OpenTTD Wiki Towns https://wiki.openttd.org/en/Manual/Towns
- S17 TTWiki TTDTownGrowth https://www.tt-wiki.net/wiki/TTDTownGrowth
- S18 Peter1138 Towngrowth Challenge https://wiki.openttd.org/en/Community/Essays/Peter1138's%20Towngrowth%20Challenge
- S19 Anno-Wiki Population https://anno1800.fandom.com/wiki/Population?oldid=2694
- S20 Steam-Thread TF2 Stadtwachstum https://steamcommunity.com/app/1066780/discussions/0/3879346999825598874
- S21 Wikipedia (de) Chaussee https://de.wikipedia.org/wiki/Chaussee
- S22 Wikipedia (de) Flößerei https://de.wikipedia.org/wiki/Fl%C3%B6%C3%9Ferei
- S23 Planet Wissen, Floßschifffahrt https://www.planet-wissen.de/technik/schifffahrt/geschichte_der_schifffahrt/pwiegeschichtederflossschiffahrt100.html
- S24 Schwarzwald-Tourismus, Holländertanne https://www.schwarzwald-tourismus.info/schwarzwald/online-magazin/geschichten-aus-dem-schwarzwald/kultur/der-weg-der-hollaendertanne
- S25 transportfever.net Logistic Challenge https://www.transportfever.net/lexicon/entry/427-logistic-challenge-new-gameplay/
- S26 OpenTTD Wiki Water Transport Tiles https://wiki.openttd.org/en/Manual/Water%20Transport%20Tiles
- Geöffnet ohne verwertbare Zahlen: Wikipedia (de) Wassermühle (keine Dichte/Leistung), Wikipedia (de) Hammerwerk (Begriffsklärung). Nicht gefunden: de.wikipedia Köhlerei, Bevölkerungsentwicklung in Deutschland.
- Nur Suchtreffer: Parish/Müller L-Systeme (Suchergebnis), Townscaper-GDC-Vortrag.

---

# TEIL B: Wissen für Mega Tycoon (nur Belegtes aus dem Repo)

Pfade relativ zu `/home/claude/mega-tycoon/`. Wichtigste Quelle: `sprints/s8/design-sprint/` (hier `ds/` abgekürzt). Hinweis: Viele Zahlen sind im Repo selbst [~] oder [A]; „belegt“ heißt hier „so entschieden und dokumentiert“, nicht „empirisch bewiesen“. Zählung der Marker: `ds/phase2/01_skalen.md` 45 × [~]; `05_stadtmodell.md` 21 × [~], 12 × [A]; `06_verteilung.md` 14 × [~], 12 × [A].

## B1 Skala und Karte
- 1 Feld = 25 m (Rechenzelle, keine Bildfläche); Karte 512² Felder = 12,8 km, innen 164 km²; Toleranz ±25 %; Fahrzeuge 0,9–1,2 × real. `ds/phase3/12_welt_regelwerk_v1.md` §2; Karte bleibt (E13), `ds/charter.md`.
- Gebäude: Kate 8×6 m (4–6 EW), Haus M 12×9 (6–10 EW), Hofstelle 25×25 m = 1 Feld, Haus L Bürgerhaus 12×14 (12–20 EW), Haus XL Mietshaus ab 1840 (25–40 EW), Dorfkirche 20×10 Turm 30, Stadtkirche 35×15 Turm 45–55, Marktplatz 40×60 bis 60×80 m. `12_welt_regelwerk_v1.md` §2 A.
- Wege: Feldweg 3,5 m, Dorfstraße 6 (Ortsdurchfahrt bis 10), Stadtgasse 5, Chaussee 6 (Trasse 11, R ≥ 50 m, generiert ≤ 50 ‰), Gleis 4/7 (R ≥ 100 m, 60 ‰ hart, Fallback 80 ‰ [A]). Brücken: ⌈Breite/25⌉ + 1 Rampe je Seite, höchstens 8 Felder. Fluss 60–100 m, Nebenfluss 15–25, Bach 4–6 mit Gehölzsaum, Mühlgraben 3.
- Prüfbare Verhältnisse V1–V9 (Haus M : Dorfstraße : Fuhrwerk = 12 : 6 : 9,5; Hofstelle = 1 Feld; V9 Dorf–Dorf ≥ 5 Dorfdurchmesser). `12_welt_regelwerk_v1.md` §2 F.
- Prinzipien P1–P7 (Siedlung < 3 % der Fläche, gewachsen statt konstruiert, „steht hier, weil …“). `12_welt_regelwerk_v1.md` §1.

## B2 Ortsklassen (Start 1820), Umland-Modell
| Klasse | Ort-EW (sichtbar) | Umland | Sim-EW → Sim-Stufe | Häuser | Radius | Anzahl |
|---|---|---|---|---|---|---|
| Weiler | 20–60 | – | kein Knoten | 4–10 Höfe | 40–75 m | 6–12 Kulisse |
| Dorf | 150–350 | 250–550 | 400–900 → dorf | 25–56 | 125–200 m | 12–16 |
| Marktflecken | 800–1.300 | 400–600 | 1.200–1.900 → kleinstadt | 100–165 | 175–250 m | 2–3 |
| Kleinstadt | 2.000–4.000 | 400–700 | 2.400–4.700 → kleinstadt | 195–380 | Kern 200–300 + Vorstadt bis 450 | 2 (min. 1) |
| Stadt | 10.000–20.000 | 500–1.000 | stadt/metropole | 900–1.500 | 600–900 m | 0 (nur Wachstum) |
Quelle: `12_welt_regelwerk_v1.md` §3. Sim-EW = Ort-EW + Umland-EW, Umland fest ab Generierung (Wachstum nur im Ort), ≥ 30 % des Umlands sichtbar als Weiler/Einzelhöfe (Voronoi der Knoten). Ø EW je Wohnhaus: Dorf 7, Marktflecken 9, Kleinstadt 11, Stadt 14. K1 (`ds/phase3/11_streitprotokoll.md`): Szenario B+, Sim-EW gesamt ≈ 20.000 (12.000–29.500) gegen 36.250 in S7, Ort-EW ≈ 12.000; Schild = Ort-EW mit Trendpfeil und bis zu 3 Bedarf-Icons.
- Ortsklassen je Epoche (Spätstart, Obergrenze durch Versorgung): `ds/phase3b/15_regelwerk_v1_1.md` A3: z. B. Kleinstadt W1 2–4k, W2 4–8k, W3 5–15k, W6 10–30k; Großstadt nur durch Wachstum, bis ca. 100–120k, Metropole nicht auf der Standardkarte (K25, F8 → E13).

## B3 Eigene Plausibilitätsrechnungen am Regelwerk [R]
1. Christaller K=3: Zentren-Abstände 1,6 km (Dorf–Dorf min) → ×1,73 = 2,8 → ×1,73 = 4,8 → ×1,73 = 8,3 km. Regelwerk: Dorf–Dorf min 1,6 (typisch 1,8–3), Marktflecken–Marktflecken 5 (typisch 5–7), Kleinstadt–Kleinstadt 7 (typisch 7–9). Passt grob zu K=3, ohne dass es im Repo so begründet ist (K=3 wird dort nicht zitiert).
2. K=3-Zählung: 2 Kleinstädte → 4 Marktflecken, 12 Dörfer. Regelwerk: 2 Kleinstädte, 2–3 Marktflecken, 12–16 Dörfer. Dörfer passen, Marktflecken liegen eher unter dem Wert. Hypothese: Die Marktflecken sind knapp, das ist ein Teil von K18 (Marktflecken weniger wert als Dorf, siehe `mt-oekonomie` B7).
3. Rang-Größe (P_1 = 4.000): Rang 2 = 2.000, 3 = 1.333, 4 = 1.000, 5 = 800, 6 = 667, 8 = 500, 10 = 400, 12 = 333, 16 = 250, 19 = 211. Regelwerk: Kleinstädte 2.000–4.000 (passt zu Rang 1–2), Marktflecken 800–1.300 (passt zu Rang 3–5), Dörfer 150–350 (passt zu Rang 12–19). Zwischen Rang 6 und 11 (ca. 360–670 Ort-EW) ist keine Klasse vorgesehen; ob das gewollt ist (Sprung Dorf → Marktflecken) oder ein Großdorf fehlt, ist im Repo nicht diskutiert gefunden. In Sim-EW überlappen die Bänder (Dorf bis 900, Marktflecken ab 1.200).
4. Siedlungsfläche W1: 2 Kleinstädte (Radius 450 m: 0,64 km²) + 2,5 Marktflecken (250 m: 0,20) + 14 Dörfer (160 m: 0,08) ≈ 2,9 km², also ca. 1,8 % der 164 km². Regelwerk-Grenze < 3 % (`15_regelwerk_v1_1.md` A3). Gewissheit: Radien aus dem Regelwerk, Flächen als Kreise genähert.
5. Ort-EW-Summe: 2 × 3.000 + 2,5 × 1.050 + 14 × 250 ≈ 12.100, deckt sich mit der Erwartung ≈ 12.000 (K1).
6. Mühlen: 14 Dörfer × 0,52 Mühlen/Dorf × 40 % Wasser ≈ 3 Wassermühlen; Regelwerk 3–5 Mühlen (S12 plus Regelwerk §4). Passt zur oberen Seite, weil das Tal Bäche hat.
7. Großstadt: 100.000 EW bei ca. 6.500 EW/km² [~ im Repo] ≈ 15 km² ≈ 9 % von 164 km² (`15_regelwerk_v1_1.md` A3).

## B4 Verteilung und Eignung
`ds/phase3/12_welt_regelwerk_v1.md` §4; Herleitung `ds/phase2/06_verteilung.md`:
- Abstände Mitte zu Mitte: Weiler–jeder Ort ≥ 0,6 km; Dorf–Dorf max(1,6 km; 5 × Dorfdurchmesser); Dorf–Marktflecken/Kleinstadt 2,5; Marktflecken–Marktflecken 5; Kleinstadt–Marktflecken 4; Kleinstadt–Kleinstadt 7; Dorf → nächster zentraler Ort ≤ 6 km; Mindestlücke 0,8 km Freiland (Weiler 0,4); Randabstand 1 km.
- Eignung S: Wasser 100–400 m +300, Furt/schmale Stelle +250, Talkreuzung +200, Talrand +150 (Süd-/Osthang +50), Ebene +100, Aue direkt −400, steil (> 8 %) −500, Waldinneres −200, Gebirge/Höhe > 600 m ausgeschlossen; Faktoren zum Teil [~]. Seen (v1.1 C3): Seeufer 100–400 m +300, Seeausfluss/Engstelle +250, Buchtkopf +200, Halbinselhals −100, Insel aus, Uferstreifen < 50 m aus (Annahme).
- Reihenfolge: Orte zuerst, dann Industrie in die Zwischenräume; zentrale Orte „best candidate“ (k = 30 Zufallskandidaten mit S ≥ 600); Dörfer Bridson-Poisson mit paarweisem d_min und Akzeptanz p = S/1.000, nicht sättigen, keine Relaxation; Gemarkungen per Voronoi der Knoten. Clark-Evans Orte 1,0–1,6, Industrien 0,9–1,5. Erfüllbarkeit ≥ 18 von 20 Seeds.
- Industrie-Ebenen: Gutshof 5–8 (Ebene/Aue), Kohle 2–3, Erz 1–2 (Lagerstätten an 1–2 Bergflanken, Flecken r 300–600 m, Kohle–Erz ≥ 0,75 km, Relief ≥ 60 m in 500 m), Holz 3–5 (ab S8), Mühle 3–5 (≤ 200 m an Bach/Fluss), Eisenhütte 2–3 (Tal, Wasser ≤ 400 m), Kalkofen/Ziegelei 2–3, Manufaktur 1–3 (max. 1 je zentralem Ort, Vorstadt, nie im Kern). Gleiche Typen: Rohstoff ≥ 1,2 km, Veredelung ≥ 3 km, Produktion ≥ 4 km (ersetzt R7). Kanten: Farm → Mühle 0,45–0,75 km plus Pflicht-Fernquelle 0,75–2 km; Kohle → Hütte 0,4–0,75; Erz → Hütte 0,75–3 (mindestens ein Erzfleck ≤ 2 km); Hütte → Manufaktur 0,75–2; Mühle → Ort 1–3,25.
- Anti-Revier AR1–AR7 (max. 3 Industrien und keine volle Kette je 1,5-km-Kreis; keine kongruenten Gruppen ±20 %; Quellen aus ≥ 2 Richtungen nur für Mühlen; ≥ 70 % der Rohstoffe mit ≥ 2 Abnehmern in 2,5 km; Clark-Evans; jede 4×4-km-Kachel ≥ 1 Industrie außer > 60 % Gebirge/Wasser; Lage sichtbar). K13: AR3 nur für Mühlen, weil Kohle knapp ist.
- Validatoren: V-E1 Pflichtkante per Straße (≤ 200 ‰, Umweg ≤ 1,6), V-E2 je Montangruppe 1 Kette als Gleis (≤ 60 ‰, Umweg ≤ 2,0), V-E3 Netz zusammenhängend und ≥ 2 Querungen je Fluss, V-E4 Flussspalten gerade querbar ≥ 80 %, V-E5 Zufahrt, V-E6 Ortsanschluss, V-E7 ≥ 60 % der Knoten mit Agrarkette in 2,5 km, V-V1–V-V3, V-L1 Reliefstufen, V-L2 Fluss max. Querschnitt ≤ 6, Median 3–5, V-L3 Bäche 4–8; Wasser V-W1 Erreichbarkeit (≤ 8 Brückenfelder, Umweg ≤ 1,5/1,8/2,2), V-W2 Querungsstellen (See > 1 km: Engstelle ≤ 200 m, Abstand zwischen Querungen ≤ 3 km), V-W3 sichtbare Nutzung (≥ 300 m Gewässer oder je 2 km Fluss ≥ 1 Nutzung ≤ 500 m vom Ufer), V-W4 Anteile, V-W5 Inseln ohne Knoten. `12_welt_regelwerk_v1.md` §4, `15_regelwerk_v1_1.md` C3.
- Relief und Wasser: Ebene 20–30 %, Hügelland 30–40 %, Mittelgebirge 15–20 %, Gebirge ≤ 20 % (ds_v2 gemessen 31,6 %, daher Massiv −15 %, Gate ≤ 20 %; K15); Fluss 60–100 m mit Mäander λ = 11–15 × Breite, Uferböschung 40 m, 4–8 Bäche, 1–2 Nebenflüsse, 0–2 Seen 300–800 m; Kartentypen Flusstal 3–5 % Wasser, Seenplatte 8–12 %, Seenreich 15–25 % (K32: Seenreich erst wählbar, wenn Fähre/Schiff spielbar). `12_welt_regelwerk_v1.md` §5, `15_regelwerk_v1_1.md` C2.

## B5 Dorfformen, Haustypen, Ortsaufbau
- Form-Gewichte Haufendorf 50 %, Straßendorf 25 %, Angerdorf 15 %, Weiler 10 %; Form nach Lage (Talboden/Bach → Straßendorf, Mulde + Wasser → Angerdorf, Kreuzung/Ebene → Haufendorf) plus Regionsgewicht +30 % je Seed [A]. Gemeinsam: Hofstelle mit Haus an der Straße (Rücksprung 2–8 m), Nebengebäude hinten, Garten, 1–3 Bäume, Zaun; Halbfeld-Unterraster 12,5 m, Jitter ±2 m/±8°; Etter-Ring 30–60 m, dann Acker. `12_welt_regelwerk_v1.md` §3; Generatorschritte `05_stadtmodell.md` §3.
- Haustypen: Kate (5 EW), Bauernhof (8), Großhof (12), Handwerkerhaus (7), Bürgerhaus (14, ab Marktflecken), Mietshaus (30, Kleinstadt ≥ 4.000 und ab 1840), Sonderbauten (Kirche, Gasthaus, Schmiede, Schule, Rathaus, Speicher, Stadttor, Bahnhof ab 1835 nur Spieler).
- Marktflecken = Haufendorf + Marktplatz (40×60 bis 60×80 m) an der Hauptkreuzung, geschlossene Reihe um den Markt. Kleinstadt = ovaler Mauerkern (r 200–300 m), 2–4 Tore, Marktstraße 15–25 m, Gassen 5 m als „verzogene Leiter“ (Abstand 30–60 m ±30 %, Winkel ±15°, nie durchgehendes Raster), Parzellen 8–12 m Front, Vorstädte als Straßendörfer. Raster nur im Bahnhofsviertel (Ort ≥ 3.000, max. 2×3 Blöcke) und nach Spieler-Bahnhof. `05_stadtmodell.md` §3e.
- Prototyp (Seed 7, deterministisch, md5 gleich bei zweimaligem Lauf): Erlenbach Dorf Haufendorf 244 EW, 34 Wohnhäuser + Kirche/Gasthaus/Schmiede, 44 Parzellen (7 Lücken); Hasenwinkel Weiler 48 EW; Lindenfurt Kleinstadt-Marktausschnitt 387 EW; Gut Kuppenhof; Erlenmühle. 1.049 Instanzen, 15 Wege (~4,0 km), Validator 58 OK / 0 WARN / 0 FAIL. `ds/phase4/stadt_welle1.md`.

## B6 Wachstum und Stadt-KI
`ds/phase3/12_welt_regelwerk_v1.md` §3, `ds/phase3b/15_regelwerk_v1_1.md` A4–A5, `ds/phase4/stadt_welle1.md`:
- Reihenfolge je Spielmonat (deterministisch je Ort): 1 Lücke füllen, 2 Upgrade am Platz (Kate → Handwerker ab 300 EW +2; Hof → Großhof ab 250 +4; Handwerker → Bürger ab 1.000 im Kern +7; Bürger → Mietshaus ab 4.000 und 1840 +16), 3 Hofteilung im Kern ab 1.000, 4 Vorstadt an Ausfallstraße (×3 bei Spieler-Anschluss), 5 Gasse (Kern ≥ 85 % gefüllt, max. 1–2 je Spieljahr), 6 Platz bei Klassenwechsel (800/2.000/10.000 Ort-EW). Jede positive Rate erzeugt im selben Monat ≥ 1 sichtbare Aktion; Gerüstphase 1 Monat; max. 1 Ort je Tick. KI-Straßen: nur hinzufügen, nie Gleis kreuzen, Anschluss an Spielerstraßen nur über Kreuzung.
- Prototyp-Parameter: max. 1 + Ort-EW-Soll/500 Aktionen je Monat, 8 EW je Aktion, Haus-Ruhe 3 Monate, RNG `PCG(hash(welt_seed, ort_id, monat))`. Erlenbach ohne Versorgung 244 EW (0 Aktionen, E7), mit Versorgung 307 (+63 in 12 Monaten: 7 Lücken, 3 Großhof-Upgrades, 1 Vorstadt-Hof, 1 Kate → Handwerker). Teilung, Gasse und Platz werden in 12 Monaten nie erreicht und sind nicht implementiert.
- Epochen-Erweiterungen (A4): W2 Ringstraße auf geschleifter Mauer, Bahnhofsviertel am Spieler-Bahnhof (max. 2×3 Blöcke); W3 Stadterweiterung im Fluchtlinienplan (Raster ≤ 40 % der Stadtfläche); W4 Siedlungszeilen; W5 Großsiedlung nur mit Spieler-Haltestelle, Ortsumgehung; W6 Nachverdichtung. Nie: Raster in Altstadt oder Dorf, Hochhaus im historischen Kern, Wachstum ohne Versorgung (E7). K23: kein globaler Stilwechsel, Altstadtschutz ≥ 30 % der W1-Häuser im Kern, Bestandserneuerung max. 1 % je Spieljahr.
- Leistungsgate: Übersicht ≤ 1,0 M Dreiecke und ≤ 300 DC in jeder Epoche; Schätzung Prototyp 0,18 M Dreiecke für Orte, 35 DC (Schätzung, noch ohne echte Assets).

## B7 Wasser, Brücken, Chaussee im Prototyp
- Rotachbrücke (Steinbogen, 5 Felder = 125 m, 5 Bögen à 15 m, 7 m breit) am schmalsten geraden Punkt der Rinne (75 m); Bachbrücke Spann 8 m; Chaussee Erlenbach–Lindenfurt 1.676 m, max. 4,0 % Steigung, min. Radius 54 m, Allee mit 213 Bäumen. Wasserregeln hart: Rinne ≥ 55 m, See ≥ 45 m jenseits r_eff, Mühlteich ≥ 15 m, Bach ≥ 20 m, Hang ≤ 6 %; Aue weich (35 % des Kerns). `ds/phase4/stadt_welle1.md`.
- Sichtbare Nutzung (E10, K33): Mühle, Fischer, Steg, Fähre, Hafen, Holztrift; im Prototyp Fischerhütte, Steg 25×2 m, Boot (Bootsschleife r 110 m, 300 s Umlauf), Erlenmühle 12×12 m mit Wasserrad. Floß (E15) nur Kulisse. `ds/phase4/stadt_welle1.md`, `ds/phase4/ta_welle2.md`.

## B8 Bekannte Abweichungen und Fallen (Repo)
1. Dorf–Kleinstadt im Prototyp 1,70 km statt 2,5 km (Kern 2×1,6 km, Rotach-Streifen dazwischen; Grenze 1,6 km gehalten). Dorf r_m = 190 statt 160 m (Haufendorf entlang der Hauptstraße), Dorf–Weiler 0,94 statt 0,8 km. `ds/phase4/stadt_welle1.md` Abweichungen 1, 3, 5.
2. Aue deckt 35 % des Kerns; als weiche Regel. Gutsweg bei 9,99 % (Feldweg-Grenze 10 %). Wachstumsrate 180 bp/Monat nicht gegen die Ökonomie geprüft (`RATE_BP`).
3. Der Generator lief nur im Prototyp-Fenster (2 × 1,6 km), nicht auf der vollen Karte mit 15–21 Knoten; Erfüllbarkeit ≥ 18/20 Seeds ist Forderung, keine Messung. Hinweise: `ds/phase4/integration_w2.md`, `proto_sim_anbindung.md`.
4. Clark-Evans-Band für Orte: 1,0–1,6 (`06_verteilung.md` Zeile 69, Regelwerk §4) gegen 1,2–1,7 (V-V3, `06_verteilung.md` Zeile 142). Nicht als aufgelöst gefunden.
5. Hierarchie ist Annahme (K1, bestätigt mit F1 = E6). Sim-Stufe Marktflecken → „kleinstadt“ (×1,0 Nachfrage) führt zu K18 (Marktflecken fragt weniger nach als ein Dorf). `ds/phase3/11_streitprotokoll.md` K18, `ds/phase4/tobias_welle1.md` (siehe Skill `mt-oekonomie` B7).
6. Bot-Stichprobe der Ökonomie lief auf der 8-Orte-Slice-Karte, nicht auf Generator-Welten mit der neuen Ortsordnung. Orte der Welt-Draws wurden dafür ausgelost (`tobias_welle1.md` §2.2).
7. Wachstum im Slice-Code nicht verdrahtet: Einwohner statisch (`tobias_welle1.md` §7 Punkt 7). Das Stadtwachstum der Welt ist deshalb bisher nur im Python-Prototyp gerechnet (`tools_proto/stadt_wachstum.py`).
8. Zwei Ortsbänder in zwei Dokumenten: 05 (+5/+18 EW, 8,5 je MF-Haus) gegen 07 (+7/+16, 9); aufgelöst zugunsten 07 (`12_welt_regelwerk_v1.md` §12).

## B9 Basti-Feedback als Auftrag an die Stadt
Wortlaut: Straßenführung seltsam, Städte zu geometrisch, Blöcke leer, Städte zu groß fürs frühe 19. Jh., Anordnung konstruiert und zu zusammengewachsen, Wunsch nach Häusergrößen mit Einwohnern, automatisch wachsenden Städten (kleine Häuser werden große, Stadt-KI legt Straßen an). Quelle `sprints/s8/feedback_02-11/basti_feedback_02-11.md`. Einordnung: Zeilen 4, 7, 8 gehen an Stadtmodell und Verteilungsregeln.

## B10 Konsistenzprüfung Häuserzahl gegen Einwohner [R]
| Klasse | Häuser (Regelwerk) | Ø EW je Wohnhaus | Produkt | Ort-EW-Band | passt? |
|---|---|---|---|---|---|
| Dorf | 25–56 | 7 | 175–392 | 150–350 | oben 12 % darüber (56 Häuser schließen Sonderbauten ein) |
| Marktflecken | 100–165 | 9 | 900–1.485 | 800–1.300 | oberes Ende 14 % darüber |
| Kleinstadt | 195–380 | 11 | 2.145–4.180 | 2.000–4.000 | oberes Ende 4,5 % darüber |
| Stadt | 900–1.500 | 14 | 12.600–21.000 | 10.000–20.000 | oberes Ende 5 % darüber |
Quellen: `slice/world/data/proto/regelwerk.json › ortsklassen, ew_je_wohnhaus_mittel`, `12_welt_regelwerk_v1.md` §3. Befund: Die Bänder stimmen innerhalb von ±15 %; „Häuser“ enthält teils Sonderbauten (Dorf 3–6), die keine Einwohner tragen, damit schrumpft die Abweichung oben. Erlenbach im Prototyp: 244 EW / 34 Wohnhäuser = 7,2 EW je Haus (`stadt_welle1.md`), also konsistent. Das ist meine Rechnung, das Repo führt sie nicht.

## B11 Datenformate der Welt (wo ein Ort im Datensatz steht)
- `slice/world/data/proto/regelwerk.json` (Regelwerk v1.1 als Daten, Felder u. a. `ortsklassen`, `umland_modell`, `dorfformen`, `wachstum`, `stadt_ki`, `verteilung`, `industrie_ebenen`, `anti_revier`, `validator`, `landschaft`, `epochen`, `gewaesser_kartentyp`, `nachfrage_bruecke`). `nachfrage_bruecke` gibt Beispiele: Dorf 650 EW → 13 E/Monat, Marktflecken 1.550 → 15, Kleinstadt 3.500 → 35, Sim-Stadt 6.000 → 60; Hinweis auf Stadt-Korb „stahl“ (keine Güter-Kategorie, prüfen Felix/Tobias S8) und auf K18.
- `proto_orte.json`: je Ort `id, name, klasse, ew, x, z, r_m, r_max_m, form, gebaeude{}, wohnhaeuser_n, gebaeude_n, parzellen_n, luecken_n, kreuzung`; dazu `industrie`, `gewaesser`, `parzellen`, `_meta` (Seed 7, Abstände, See-Nutzung, Mauer, Kreuzungen). `proto_instanzen.json`: 1.049 Instanzen `{typ, x, z, rot_deg, parzelle, ort, b, t, variante, rolle}`. `proto_wege.json`: 15 Wege mit Punkten, Breite, Länge, max. Steigung, bei der Chaussee Brücken, Allee, Trassenbreite. `proto_vorher_nachher.json`: Wachstum Monat 0/12.
- Lagegrund („steht hier, weil …“) ist laut P5 Pflicht, im Datensatz aber nicht als eigenes Feld gefunden; Begründung steht im Dokument `stadt_welle1.md` (Lagebegründung). Vorschlag [R]: Feld `lagegrund` je Ort und Industrie ergänzen, damit der Validator ihn prüfen kann.

## B12 Entscheidungsvorlagen, die ich als Stadtdesigner vorbereiten würde (Vorschläge [R], keine Beschlüsse)
1. Klassenlücke: Option A „Sprung Dorf (≤ 350) zu Marktflecken (≥ 800) bleibt“ (entspricht Bastis „wenige Städte, viele Dörfer“), Option B „Großdorf 400–700 mit Kirche und Gasthaus als Zwischenklasse“ (füllt Rang 6–10, glättet K18). Prüfmittel: Rang-Größe-Plot der Welt-Draws.
2. Generator-Lauf auf der vollen Karte: 20 Seeds, Erfüllbarkeit, Clark-Evans je Seed, Laufzeit; erst dann Regeln ändern.
3. Eignungsgewichte: Morris-Screening über die neun Faktoren (siehe `mt-oekonomie` A7), um die zwei wichtigsten zu finden und nur diese zu kalibrieren.
4. Clark-Evans-Band festlegen (1,0–1,6 oder 1,2–1,7), Dokumente angleichen.
5. Stadt-KI Schritte 3, 5, 6 (Teilung, Gasse, Platz) mit einem 60-Monate-Lauf prüfen, nicht nur 12 Monate.
6. Umland: den sichtbaren Anteil (≥ 30 %, Weiler/Einzelhöfe) gegen die Streuung der Karte messen (zählbar im Validator).

---

# TEIL C: Eigene Lücken und Lernstand

## C1 Was ich jetzt kann (Konfidenz)
- Die Hierarchie 2/2–3/12–16 plus Weiler mit Christaller K=3 und Rang-Größe plausibilisieren und die Lücke 360–670 Ort-EW benennen (mittel, eigene Rechnung).
- Siedlungsform nach Lage begründen (Haufen/Straße/Anger) mit Quellen zu Dorfformen (mittel bis hoch, Wikipedia-Quellen).
- Verteilungsregeln und Validatoren des Repos vollständig nennen und Verbesserungen vorschlagen (hoch, [M]).
- Dichte-Eichung Mühlen (0,52 ländliche Mühlen/Dorf, 40 % Wasser) anwenden (mittel, eine Region).
- Algorithmen-Einordnung (Bridson, mewo2, Red Blob, Townscaper) mit ihren Grenzen (mittel bis hoch).

## C2 Noch unsicher (Konfidenz niedrig bis mittel)
1. Christaller-Passung ist eigene Rechnung; Regelwerk nutzt K=3 nirgends ausdrücklich. Konfidenz: niedrig, dass die Passung mehr als Zufall ist.
2. Dorfzahl 12–16 auf 164 km² und Abstände 1,6–3 km: nur durch Gedächtnis-Fachwissen und Kurmark-Mühlendichte gestützt; keine Dorfdichte-Quelle für 1820 gefunden (Dorf-Wikipedia nennt keine Dichte). Konfidenz: niedrig bis mittel.
3. Verstädterungsanteil um 1800/1850 nicht belegt (beide Quellen ohne diese Zahlen); die Regelwerk-Siedlungsfläche < 3 % ist Setzung.
4. Der Generator wurde nicht auf der vollen Karte mit allen Regeln ausgeführt; Erfüllbarkeit ≥ 18/20 Seeds ist offen.
5. Eignungsgewichte (+300, +250, −400 …) sind im Repo [~] bzw. [A]; keine empirische Eichung, keine Sensitivitätsanalyse gefunden.
6. Stadt-KI-Teile (Teilung, Gasse, Platz) und Epochen-Erweiterungen sind nicht implementiert oder getestet.
7. Wassernutzung: Flößerorte, Schwellweiher, Furten als Siedlungsfaktor sind Ideen [R]; keine Quelle gibt Siedlungsdichte entlang flößbarer Flüsse.
8. Reddit-Erfahrungen zu Generatoren fehlen (gesperrt).
9. Cluster-/Revier-Messung: Clark-Evans-Grenzen sind [~], keine Quelle bestätigt 1,0–1,6.

## C3 Was ich künftig anders mache
- Generator zuerst auf der vollen Karte und über viele Seeds testen, dann Regeln anpassen.
- Jede Eignungsgewichtung mit einer kleinen Sensitivitätsprobe (Morris, Latin Hypercube) absichern und die Abhängigkeit von Schwellwerten zeigen (Methodik: Skill `mt-oekonomie` A7).
- Ortsklassen immer mit Rang-Größe-Test und Klassenlücken-Prüfung vorlegen.
- Zahlen mit Quellenmarker versehen ([Q]/[A]/[~]), nicht stillschweigend übernehmen.
- Lagegrund jedes Ortes im Datensatz speichern („steht hier, weil …“), damit Validator und Rundgang ihn prüfen können.

## C4 Meine offenen Lernfragen (Kurzform, Details und Rangfolge in `LERNBERICHT.md`)
1. Klassenlücke 360–670 Ort-EW und Marktflecken-Mangel. 2. Generator auf voller Karte mit 15–21 Knoten. 3. Dorfdichte 1820 (Zahlen, Quellen). 4. Eignungsgewichte kalibrieren. 5. Umland-Modell gegen Realität (Gemarkung, Weiler-Anteil). 6. Stadt-KI Schritte 3, 5, 6 prüfen. 7. Wasser als Siedlungsfaktor (Furt, Floßplatz, Mühle). 8. Epochenfolge der Stadtbilder (Altstadtschutz, Raster). 9. Straßenführung (8 Richtungen gegen 4 Richtungen in der Sim). 10. Clark-Evans-Band festlegen.

## C5 Quellenlage ehrlich (was die geöffneten Quellen nicht hergeben)
- Christaller (S1): keine Kilometerangaben; die √K-Abstände sind meine Geometrie, nicht aus der Quelle.
- Haufendorf/Dorf (S10, S11): keine Lage-, Verbreitungs- oder Dichteangaben für 1820; Größenklassen mit widersprüchlicher Abgrenzung.
- Pfister (S14): nur Zusammenfassung, keine Verstädterungsrate für 1800 oder 1850; Urbanization (S15) beginnt 1871.
- Red Blob (S6): die Siedlungsideen im Abruf sind Zusatz des Abrufwerkzeugs; die Seite selbst behandelt Karten, nicht Orte.
- Watabou (S7) und arXiv 2507.18899 (S8): ein Devlog und ein Vorschlag mit qualitativer Bewertung, keine Messdaten.
- Mühlendichte (S12) ist eine Region (Kurmark) und eine Jahresgruppe (1791–1801); Übertragung auf ein Flusstal im Süden ist Annahme.
- Anno-Wiki (S19): nur Stufenfreischaltung, keine Verbrauchszahlen; Steam-Thread (S20) ist Forenstand 2023, nicht offiziell.

## D. Lern-Routine (verbindlich, seit 2026-11-03)
**1. Wissenscheck** vor jeder fachlichen Antwort/Entscheidung: Steht sie hier mit Marke [K]/[V]/[R]? Ja: anwenden. Nein, oder nur [E]/[W]/niedrige Konfidenz: weiter mit 2.
**2. Recherche-Trigger** (einer genügt; laut sagen: "Wissenslücke: <Frage>, ich recherchiere"): a) Ich weiß es nicht oder rate. b) Derselbe Kompromiss/Workaround zum 2. Mal ("wieder X statt Y"). c) Eintrag unter Offene Lücken oder [E]/[W]/niedrig, und die Entscheidung hängt daran. d) Skill, Repo, Doku oder Messung widersprechen sich. e) Engine/Tool/Version neuer als der Skill-Stand. f) Basti korrigiert oder eine Entscheidung wird zurückgenommen. g) Teure oder unumkehrbare Entscheidung bei Konfidenz unter mittel. h) Derselbe Fix scheitert 2x.
Rollen-Trigger: Historische Form/Maß ohne Beleg (1820 vs. 1850); Platzierungsregel wirkt falsch; Bastis Auge widerspricht der Metrik.
Erst prüfen statt recherchieren, wenn billig messbar (Test, Doku-grep, Mini-Versuch). Geschmack klärt Prototyp oder Basti, nicht das Web.
**3. Ablauf**: Frage in einem Satz; Primärquellen zuerst (Doku, Issues, Forum, Postmortems; Reddit blockiert, nicht umgehen); 2 unabhängige Quellen; wenn möglich Eigenversuch [V]; Ergebnis mit Quelle, Datum, Marke. Budget 15 min, mehr nur als Agent. Unbeantwortet: Lücke eintragen, Basti/Team fragen, nie raten.
**4. Insight aufnehmen**, wenn alle vier stimmen: wiederverwendbar (2x gebraucht oder über 1 h Aufwand), belegt, noch nicht drin, kein Tagesstand (der gehört in Repo-Doku). Sofort bei Basti-Korrektur, Fehler im Skill oder Engine-Falle mit Repro, sonst gesammelt zum Sprintende. Eine Zeile mit Marke, Datum, Quelle; Widerspruch ersetzt den alten Eintrag; geschlossene Lücke streichen; Skill bleibt ca. 10.000 Zeichen. Im Account nur per Vorschlagskarte an Basti.
**5. Kompromisslog**: jeden Kompromiss, Workaround, jedes "wusste ich nicht" mit Datum in `sprints/s8/fortbildung/mt-stadtdesign/LERNLOG.md` zählen; Zähler 2 löst Trigger b aus; Auswertung in der Sprint-Retro.
