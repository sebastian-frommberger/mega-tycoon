# Position UX und Art – Aylin (UX), Sophie (Art/Level)

Grundlage: Bastis Feedback, SP-03-Notiz und -Shots, RE-Referenzen, Tagebücher. Leitsatz: Basti sieht zuerst die Welt, der Spieler zuerst die Fehlermeldungen. Beides gehört in S7.

## Kandidaten (Sophie 8 T, Aylin 8 T)

| ID | Votum | Tage Art/UX | Akzeptanz |
|---|---|---|---|
| W-01 Maßstab | **rein**, 25 m/Feld | Sophie 1 | Haus 12x9 m, Stadtstraße 12 m, Gleisabstand 5 m im Spiel gemessen (Szenenmaße = Tabelle SP-03) |
| W-02 Terrain | **kleiner**: Heightmap offline gebacken, Fluss als Rinne, Rand + Kamera-Grenze. Raus: Brücken-Pfeilerlogik, Uferverfeinerung (S8) | Sophie 3 | siehe Look-Ziele Terrain/Rand |
| W-03 Städte | **kleiner**: Generator (Raster, Rand, Bahnhof, Palette-Shader), nur Stufen Dorf/Kleinstadt/Stadt. Raus: Großstadt, Hinterhöfe (S8) | Sophie 3 | siehe Stadtbild |
| W-04 Straßen | **kleiner**: Kenney-Kacheln schmal statt Boxen, Kurven; Spline-Band (3 T) in S8. **Z-01 komplett rein** | Sophie 1, Aylin 1 | Straße endet an Stadt: Drag auf Stadtfläche dockt am Randfeld an, Anschlusspunkt sichtbar markiert |
| W-05 Industrie | **rein**, Lage-Logik Lena/Tobias; Sichtbarkeit bei uns | Aylin 1 (Icons/Labels), Sophie 0 | siehe Industrie-Lesbarkeit |
| W-06 Generator | **rein, aber minimal** (Bake + Validator), sonst S8 | – | gleiche Seed = gleiche Karte |
| U-03 | **rein** | Aylin 2 | keine stumme Ablehnung, jede mit Ursache + Lösung |
| A-08 Diagnose-Toast | **raus** nach S8, U-03 deckt Pflichtfälle | – | – |
| B-xx | rein (Mira) | Aylin 0,5 Abnahme | – |
| F-22, SK-02, T-15, G-01 | Art/UX: **raus** aus S7 (F-22 UX 1 T in S8) | Aylin 1 frei für Abnahme Look/Texte | – |

Sophie: 8 von 8 T, LOD in S8 (Baumzahl in S7 hart gedeckelt, s. u.). Aylin: 2 + 1 + 1 + 0,5 = 4,5 T, Rest Puffer für Z-01-Nacharbeit und Texte.

## Look-Ziele (messbar, Abnahme per Screenshot-Set wie SP-03, gleiche Kamerastandorte)

- **Maßstab:** Haus 12x9 m ±20 %, Stadtstraße 12 m, Landstraße 7,5 m, Gleisabstand 5 m. Straße/Gleis in 700-m-Ansicht schmaler als jeder Block (Verhältnis Straße : Block <= 1 : 5).
- **Stadtbild:** Kleinstadt Radius 450 m ±15 %, Ausfransung +300–700 m an Ausfallstraßen, >= 400 Gebäude, mindestens 3 Gebäudetypen in Kern/Mitte/Rand erkennbar, Bahnhof am Rand. Blockinnenflächen: Anteil leerer Fläche < 50 % (heute ist sie zu leer).
- **Straßenbild:** Kreuzungen und Kurven ohne Lücken, kein Boxstoß; Bordsteinkachel nach Geometrie. Beim Bauen Vorschau mit Preis und roter Fehlstelle.
- **Terrain:** Höhenspanne >= 900 m, mindestens 1 Gebirge, 1 Fluss durchgehend, Hügel in Fläche; Spieler-relevante Flächen (Städte, Industrien) auf Plateau (Neigung < 3 %).
- **Rand:** bei maximalem Zoom an allen vier Ecken 0 Fehltreffer (Himmel/Kante), 7,5 km Landrand mit Gebirgsring, Naht Innen/Außen nicht auffällig (Differenz < 1 Pixel-Stufe im Shot `rand_max_ost`).
- **Industrie-Lesbarkeit Übersicht (aus 4 km):** Fläche **und** Icon. Grundfläche 150–300 m mit Signalmaterial (Halde dunkel, Felder gelb/braun, Holzlager hell) plus Icon + Name. Test: 5 Testpersonen (Daniel + Team) nennen aus der Übersicht 5 von 5 Industrien richtig in < 10 s je Karte. Icon allein reicht nicht (RE-Referenz: Felder tragen die Lesbarkeit, Icons ergänzen).
- **Budget:** Stadt nah <= 2,9 M Dreiecke bis LOD (S8), Bäume <= 60 % der Dreiecke, Übersicht >= 60 FPS auf dem Zielrechner.

## Session-UX-Funde, zwingend in S7

1. Stadtanschluss (Z-01) samt sichtbarem Abnahmepunkt. Ohne ihn ist M3 unerreichbar.
2. Keine stummen Fehler, Brücken-/Stadtfehler mit Lösungstext (Aylins Textliste).
3. "Nächster Schritt" live, mit Preis; Ziel-Abhaken nur für das richtige Objekt.
4. Ring-Labels mit Name + "Felder", "Monat" raus, "oben rechts", Kopfleiste nicht abgeschnitten.
5. Bankrott-Vorwarnung mit Ursache (nur Text, kein Diagnose-System).

Nach S8: Knickpfad/Auto-Brücke beim Drag, Skillpunkt-Erklärung, Lager-Warnung.

## TEAM-02 Technical Artist / Level Designer

**Sophie: dafür.** Terrain, Bake, LOD, Kartenwerkzeug sind ein eigener Beruf; ich bin bei 8 T über Kapazität und sonst Engpass für Städte. **Aylin: eher dagegen für jetzt.** Ein neuer Kopf braucht Einarbeitung, in einem Nacht-Sprint ohne Basti kommt er nicht rein; ich würde die Rolle mit S8 starten und den Kartenbau als Werkzeug vorbereiten. **Gemeinsamer Nenner:** Wenn Rolle, dann ab S8, Auftrag = LOD, Bake, Kartenwerkzeug, damit Sophie bei Look bleibt.

## Widersprüche zu anderen Disziplinen

1. **Gegen Felix/Technik (Performance vor Look):** Erzeugung 15–33 s ist nicht F-12-konform, aber wir lehnen ab, Bäume und Hausdetail für S7 zu kappen, bis der Look steht. Kompromiss: Bake offline in S7, Baum-Deckel, LOD S8.
2. **Gegen Lena (G-01 Progression in S7):** Wir wollen kein Fernziel-Konzept vor Z-01. Ohne Stadtanschluss spielt niemand bis Minute 13. G-01 nach S8.
3. **Gegen Tobias (T-15 Balance in S7):** Wir rechnen neue Distanzen eh neu (x2,5). Balance jetzt tunen ist doppelte Arbeit; nur Exploit-Fix (Mehl + Kredit) jetzt.
4. **Aylin gegen Sophie:** Aylin will die Straßen-Vorschau (Preis, Fehlstelle) in S7, Sophie sieht den Spline-Bau als vorrangig; Aylin bleibt dabei: Vorschau ist Pflicht, Spline kann warten.
