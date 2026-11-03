---
name: mt-artdirection
description: Art Direction fuer Mega Tycoon - Look-Entscheidungen, Massstabsdoktrin, Palette und Wertestruktur, Lesbarkeit je Zoomstufe, Epochen-Look, Stilmix Kenney/Quaternius, Look-Abnahme. Verwenden bei Stil-, Farb-, Referenz- und Abnahmefragen.
---

# Art Direction (TEAM-02) - Mega Tycoon

Rolle: Sophie als Art Director. Ich lege fest, WIE das Spiel aussieht und warum, und entscheide Look-Konflikte. Ich liefere keine Meshes (Artist) und keine Shader (Technical Artist), sondern Kriterien, Referenzen und Abnahmen.

Kennzeichen:
- [Q] Quelle geoeffnet und gelesen (URL angegeben)
- [~] Fachwissen ohne geoeffnete Quelle
- [M] im Repo belegt (Dateiangabe)
- [Annahme] nicht belegt
Konsens = mehrere Quellen. Streit = Widerspruch. Einzelmeinung = eine Quelle.

---------------------------------------------------------------------
# TEIL A - Allgemeines Fachwissen
---------------------------------------------------------------------

## A1. Was Art Direction in einem Strategiespiel leisten muss

1. Der Look ist Informationstraeger, nicht Dekoration. [Q] pcgamer.com "Tactical advantage: how visuals can affect strategy games". Konsens im Genre.
2. Lesbarkeit schlaegt Realismus. Wenn Realismus und Erkennbarkeit kollidieren, gewinnt die Erkennbarkeit, aber ueber Zeichen, nicht ueber Groessenverzerrung (siehe B1, Charter E1).
3. Ein Look = eine kleine Menge Regeln, die man pruefen kann (Wert, Farbe, Silhouette, Detailstufe). Ohne pruefbare Regeln ist Abnahme Geschmacksdebatte.
4. Entscheiden und festhalten: Art-Bible mit Tie-Breaker (was gewinnt bei Konflikt), Detail-Floor (was ist die kleinste Detailgroesse, die wir noch pflegen), Schatten als Wertkomponente. [Q] blog.makko.ai "What public game art bibles say". Einzelquelle (Analyse oeffentlicher Art-Bibles), Muster plausibel.

## A2. Wert, Farbe, Silhouette - die Pipeline

- Reihenfolge der Lesbarkeit: Silhouette, dann Wert (hell/dunkel), dann Farbton, dann Detail. [Q] Valve "Art in Source" (cdn.fastly.steamstatic.com/apps/valve/2008/GameFest08_ArtInSource.pdf), Mitchell TF2 (advances.realtimerendering.com/s2007/Mitchell-IllustrativeRenderingInTF2). Konsens.
- Test: Szene in Graustufen und mit Blur ansehen. Wenn Funktionales (Bahnhof, Strasse, Wasser, Feld) nicht trennbar bleibt, ist die Wertestruktur falsch. [Q] medium.com/@xavierck "Character readability in TF2 and Overwatch": Desaturieren und Blur-Test, Saettigung nur fuer Funktionales. Einzelmeinung eines Autors, aber Standardverfahren.
- Dorfromantik: Palette zuerst in Graustufen pruefen, Graustufen-Albedo plus hoechstens 5 Vertex-Color-Kanaele, Silhouette als Benchmark, eine Sonne. [Q] 80.lv/articles/how-dorfromantik-expands-its-cozy-world-through-minimalist-design. Einzelmeinung des Studios, plausibel.
- TF2 (Mitchell, SIGGRAPH 2007): gedaempfte dominante Farben, kleine gesaettigte Akzente, warm/kalt-Schattierung (warm im Licht, kalt im Schatten), Fresnel-Rim (1 - n.v)^4, Tiefennebel, Detailreduktion, Half-Lambert. [Q] Konsens im Feld. Gilt fuer Figuren-Shooter, Ideen fuer Strategie nur sinngemaess uebertragbar.
- Valve L4D: Team-Unterscheidung ueber Farbtemperatur, nicht nur Farbton. [Q] Art in Source. Fuer uns: Ketten (Spieler/Konkurrenz) ueber Zeichen und Temperatur, nicht ueber Gebaeudefarbe (siehe B4).

## A3. Farbtheorie fuer Karten und Aufsicht [~]

- Gelaende gedaempft (Saettigung niedrig), Funktionales gesaettigt. Hierarchie: Boden < Bauwerk < Verkehr < Spielerobjekt < Interaktion.
- Kontrast: WCAG-Verhaeltnis 3:1 als Mindestmass fuer Flaechenunterscheidung (nicht Text) ist verbreitet, fuer Spielkarten uebertragbar. [~] Konsens bei UI, auf 3D-Szene nur Naeherung.
- Farbsehschwaeche: ca. 8 % der Maenner (Rot-Gruen). [~] Standardzahl, hier nicht aus geoeffneter Quelle. Folge: Rot/Gruen nie als alleiniger Zustandstraeger, immer Form oder Wert dazu.
- Farbabstand rechnen (CIEDE2000 oder Lab-Distanz) statt schaetzen. [~]
- Atmosphaerische Perspektive: Ferne heller, blaeulicher, weniger Kontrast. Ersetzt Detail in der Distanz. [~] Konsens, TF2 nutzt Tiefennebel.

## A4. Referenzen und Stil-Beispiele

- Townscaper: Regenbogenpalette plus 2 Grau und Weiss, Detail an Fuegestellen statt Texturen. [Q] mcvuk.com/business-news/when-we-made-townscaper. Einzelmeinung (Entwickler).
- Anno 1800: Aufsicht heisst Daecher und grossflaechige Verwitterung zaehlen, historisch inspiriert, nicht real. [Q] news.ubisoft.com Anno-1800-Artikel (Create The Unknown). Einzelmeinung (Studio).
- Firewatch: 23 Baummodelle, "instance the crap out of them", Distanz-Shader vereinfacht Baeume. [Q] pcgamer.com Firewatch-Artikel. Einzelmeinung (Studio).
- Alba: Gradient-Palette ueber UVs, keine Normalmaps, 4 Terrain-Splats auf RGBA. [Q] medium.com/@ustwogames. Einzelmeinung (Studio).
- Dioramen mit Wave Function Collapse (80.lv): modulare Tiles, Stil durch Regelwerk statt Handarbeit. [Q] 80.lv/articles/using-wave-function-collapse-algorithm-for-dioramas. Einzelmeinung.
- Monument Valley, Firewatch-GDC, Dorfromantik-GDC: nur Landing-Pages, kein Inhalt gelesen. Nicht als Beleg verwenden.
- Transport Fever 3 Dev-Blog: nur Infrastruktur-Features, keine Masse. Victoria-3-Diary: kein Zoom/LOD-Inhalt. HOI4-Diary: Browser-Validierung, nicht gelesen. [Q] (dünn)

## A5. Modulare Kits und Art Fatigue [Q]

- Skyrim-Modularkit: Footprint-Raster, Pivot, Wandstaerke 0,125 m, gleiche Schnittstellen. [Q] gamedeveloper.com/design/skyrim-s-modular-approach-to-level-design.
- Ian London: Texeldichte-Toleranz +-25 %, Modulgroessen fest. [Q] ianlondon.github.io/posts/modular-level-kit-geometry.
- Art Fatigue: Details werden eher als Wiederholung bemerkt als Architektur selbst. [Q] 80.lv/articles/building-huge-open-worlds-modularity-kits-art-fatigue. Einzelmeinung, plausibel. Folge: Variation ueber Palette und Varianten, nicht ueber neue Meshes.
- 80.lv "Stylized production tips and tricks": Stil durch wenige konsistente Regeln. [Q] Einzelmeinung.

## A6. Look-Abnahme - Verfahren

Allgemein [~] mit Belegen wo genannt:
1. Kriterien VOR dem Bild festlegen (messbar: Kontrastverhaeltnis, Silhouetten-Erkennung, Palettenanzahl, Detail-Floor).
2. Gleiche Kamerastufen wie im Spiel (Zoom-Stufen), nicht Lieblingsperspektive.
3. Graustufen-Test, Blur-Test, 3-Sekunden-Test (was sehe ich zuerst).
4. Referenzvergleich Seite an Seite.
5. Befund: Bestanden / Nicht bestanden / Bedingt, mit Zahl. "Sieht gut aus" ist kein Befund.
6. Konflikte: Tie-Breaker aus der Art-Bible anwenden, nicht neu verhandeln.

## A7. Haeufige Fehler (Liste)

1. Maßstab "ein bisschen groesser, damit man es sieht". Wird zur Gewohnheit. Stattdessen Zeichen.
2. Gebaeude in Kettenfarbe einfaerben (Look wird bunt, Epochen-Look kaputt).
3. Palette nur in Farbe geprueft.
4. Stilmix ohne Stilprobe (texturiert neben flat).
5. Referenzen ohne Aussage, was genau uebernommen wird.
6. Detail an Stellen, die bei Spielzoom unter 1 Pixel fallen.
7. Abnahme nur im Nahzoom.
8. Annahmen aus einer Quelle als Standard behandeln (Firewatch gilt fuer First-Person-Wald, nicht fuer Aufsicht).

## A8. Quellenliste Teil A (geoeffnet)

1 advances.realtimerendering.com/s2007/Mitchell-IllustrativeRenderingInTF2 (Siggraph07 Course Notes, PDF); 2 cdn.fastly.steamstatic.com/apps/valve/2008/GameFest08_ArtInSource.pdf; 3 medium.com/@xavierck TF2/Overwatch Readability; 4 blog.camposanto.com (Firewatch-Post); 5 pcgamer.com Firewatch-Baeume; 6 80.lv Dorfromantik; 7 gamedeveloper.com Dorfromantik-Tile-Placement; 8 mcvuk.com Townscaper; 9 80.lv WFC-Dioramen; 10 news.ubisoft.com Anno 1800; 11 pcgamer.com Tactical advantage; 12 blog.makko.ai Art Bibles; 13 medium.com/@ustwogames Alba; 14 gamedeveloper.com Skyrim-Modular; 15 ianlondon.github.io Modular Kit; 16 80.lv Art Fatigue; 17 80.lv Stylized production tips; 18 transportfever3.com Dev-Blog (duenn); 19 admin-forum.paradoxplaza.com Victoria-3-Diary (duenn); 20 stephenberryart.com Gurney-Rezension (qualitativ); 21 gamedeveloper.com Monument-Valley/Firewatch-Landing (nicht verwertbar).
Als verwertbar gezaehlt: etwa 17. Rest nur Landing/duenn.

## A9. Lesbarkeit nach Zoomstufe (Methode)

Allgemein [~], Rechnung aus Repo-Werten in Teil B:
1. Pixelrechnung: Meter pro Pixel = 2 * Abstand * tan(FOV/2) / Bildhoehe in Pixeln (senkrechte Aufsicht). Damit ist jede Detailgroesse in Pixel umrechenbar. Gegenprobe zum Repo-Wert (ca. 4,8 m/px bei 5,6 km): mit FOV 50 Grad ergibt die Formel 4,8 m/px bei 1080 px Bildhoehe und 7,3 m/px bei 720 px. Der Repo-Wert passt also zu 1080 px, die 4.000-m-Grenze ist laut Repo auf 720p gerechnet. Welche Aufloesung gilt, ist vor Abnahme zu klaeren.
2. Drei Informationsebenen je Zoom: (a) Nahe: Form, Material, Detail; (b) Mittel: Silhouette, Farbe, Zeichen; (c) Fern: Flaeche, Wert, Icon.
3. Jede Ebene bekommt eine eigene Abnahme (nicht nur Nahzoom).
4. Uebergaenge zwischen Ebenen weich (Morphing/Blend), nicht hart umschalten. Das Projekt nutzt Zoom-Blend (S-03, Teil B).
5. Was beim Herauszoomen unter 1 Pixel faellt, darf wegfallen. Was Funktion traegt (Bahnhof, Industrie), braucht ein Zeichen (Icon, Schild) mit Mindestgroesse.
6. Ikonen-Mindestgroesse ist UX-Thema (Aylin), nicht meins. Ich liefere die Pixelrechnung.

## A10. Epochen-Look - Optionen [~]

Fuer ein Spiel, das ueber Jahrhunderte laeuft, gibt es zwei Grundansaetze. Keine geoeffnete Quelle belegt eine Praxis, daher Fachwissen:
- Aufstocken: gleiche Meshes, Epoche wirkt ueber Palette, Zusatzobjekte (Schornstein, Leitungen), Bodenversiegelung. Billig, konsistent, kann alt wirken.
- Austauschen: neue Meshes je Epoche. Teuer, glaubwuerdig, riskiert Stilbruch.
- Mischform: Kern (Haus-Grundform) bleibt, Epochen-Module (Dach, Anbau, Fassade) wechseln. Passt zu modularen Kits (A5). Meine Empfehlung bis Gegenbeweis [Annahme].
- Anno 1800: historisch inspiriert, nicht real. Look folgt Wiedererkennbarkeit der Epoche, nicht Dokumentation. [Q] news.ubisoft.com.
- Regel: Epoche muss im Graustufen-Test und im Silhouetten-Test unterscheidbar sein, nicht nur in der Farbe.

## A11. Stilmix (Kenney und Quaternius) - Pruefansatz [~]

1. Gleiche Palette ueber alle Quellen (Remap auf Projektpalette), nicht Originalfarben.
2. Gleiches Detailniveau (Detail-Floor), sonst fallen detailreichere Assets auf.
3. Gleiche Kantenhaerte (Flat Shading oder Smooth) einheitlich.
4. Stilprobe: sechs Assets nebeneinander bei Spielzoom, dann Graustufen. Stilprobe VOR dem Beschaffen weiterer Kits.
5. Dokumentieren, welche Kits Stilbruch sind (Repo: Retro Fantasy, Hexagon, City/Car).
Belegte Praxis zu Stilmix: keine geoeffnete Quelle (Polycount nicht lesbar). Ansatz ist Fachwissen.

## A12. Art-Bible-Minimum (drei Seiten genuegen)

1. Seite 1 - Leitbild: ein Satz Anmutung, drei Referenzen mit Aussage "uebernehme X, ignoriere Y".
2. Seite 2 - Regeln: Wertestruktur, Palette (Anzahl, Saettigungsgrenzen), Silhouetten-Regeln, Detail-Floor, Maßstab-Doktrin.
3. Seite 3 - Entscheidungen: Tie-Breaker-Liste (bei Konflikt gewinnt X), Abnahmekriterien, bekannte Ausnahmen mit Begruendung.
Quelle fuer Struktur: blog.makko.ai (Analyse oeffentlicher Art-Bibles). [Q] Einzelquelle.

## A13. Abnahme-Befundvorlage

Titel, Datum, Szene, Kamerastufe. Kriterium (Nummer), Messwert, Grenzwert, Ergebnis (bestanden / nicht bestanden / bedingt), Beleg (Bild, Datei), Massnahme, Verantwortlich. Keine Befunde ohne Messwert. Kriterien, die sich nicht messen lassen, sind zuerst umzuformulieren.

## A14. Streit- und Konsensliste

| Aussage | Status | Beleg |
|---|---|---|
| Silhouette vor Wert vor Farbe | Konsens | Valve, TF2 |
| Gelaende gedaempft, Funktion gesaettigt | Konsens | TF2, Dorfromantik, Medium |
| Graustufen-/Blur-Test | Konsens im Feld, zwei Quellen geoeffnet | Medium, Dorfromantik |
| Warm/kalt-Schattierung im Look | Konsens fuer Figuren, fuer Aufsicht Einzelmeinung | TF2 |
| Aufsicht: Daecher und Verwitterung | Einzelmeinung (Studio) | Anno |
| Epochen aufstocken oder austauschen | offen | keine geoeffnete Quelle |
| Wasser mit 3:1 Kontrast zum Boden | offen, Streitfall im Projekt | G3 |
| Kenney plus Quaternius mischen | offen | keine geoeffnete Quelle |

---------------------------------------------------------------------
# TEIL B - Wissen fuer Mega Tycoon (nur Belegtes aus dem Repo)
---------------------------------------------------------------------

Repo: /home/claude/mega-tycoon

## B1. Charter und Massstabsdoktrin [M]

- Charter E1 "nichts ueberzeichnet". Fahrzeuge hoechstens 1,2 x real, Untergrenze 0,9 x. Toleranz +-25 % wird NICHT auf die Grenze draufgerechnet. [M] sprints/s8/design-sprint/charter.md, phase2/01_skalen.md
- E2: einfacher opaker Wasser-Shader. E4: Startjahr als Datenparameter (1820). E8: bis heute. E9: Fahrzeug-Easing je Kategorie. E10/E15: Gewaesser-Nutzung, Floss. [M] charter.md
- Prinzipien P1-P7: phase2/02_designprinzipien.md. Verhaeltnisregeln V1-V9 und G1-G5: 01_skalen.md.
- Skalentabelle (Auszug): Haus S 8x6 m / H 6-7 m, Haus M 12x9 / H 9-11, Hof = 1 Feld (25 m), Dorfstrasse 6 m, Chaussee 11 m, Fuhrwerk 9,5 x 2,2 m, Postkutsche 12,5 m, Lok+Tender 13,8 m, Zug 69 m = 2,8 Felder, Fluss 60-120 m, Bach 4-6 m plus Saum. [M] 01_skalen.md
- Fernsicht: Bei 5,6 km Kamera ca. 4,8 m/px. Lesbarkeit ueber Zeichen (Icon, Schild). [M] 01_skalen.md
- Lesbarkeitsgrenze 4.000 m bei 70 Grad (nur Rechnung, 720p). Zoom-Blend als Morphing (S-03). [M] design/art/day1-3/s03_look_test_befund_und_entscheidung.md, day4-6/s03_entscheidung_wiki.md

## B2. Look-Gates [M]

- G1: Industrie neutral (keine Kettenfarbe am Gebaeude). [M] phase3/14_prototyp_plan.md Zeile 58-60
- G2: keine 25-m-Uferzacken bei 160 m Kamera. [M] 16_prototyp_plan_v1_1.md
- G3: Kontrast mindestens 3:1. Aylin-Befund: Wasser/Boden 14 Paare mit 1,1-3,0:1, NICHT erfuellt. [M] phase3 und Aylin-Messung
- Abnahmekriterien 1-6 und Messprotokoll M14/M15 stehen in 16_prototyp_plan_v1_1.md. Gate-Reihenfolge nicht verhandeln.

## B3. Palette und Farbsprache [M]

- Palette v1 final: design/art/day4-6/s05_palette_v1_final.md.
- Gelaende Saettigung hoechstens 35 %. [M] design/art/concept/sophie.md, leitplanken.md
- Ghost: Weiss/Rot. [M] concept/sophie.md
- Gebaeude-Palette: Putz D8CDB6, Fachwerk 54402F, Holz 7A5D43, Ziegel 9A5944, Schiefer 5E6268, Reet 8D7A56, Stein A69E8F, Sockel 7E776B. [M] phase4/ta_welle2.md
- Wasserfarben: flach 55909C, tief 345F7E, Ufer 6B7054. [M] proto_water.gdshader
- Einfaerberegel: Gebaeude neutral. Kettenfarbe nur in Icon, Plakette, Wimpel. [M] asset_audit.md, charter.md

## B4. Epochen und Stilbasis [M]

- W1-W5, W1 = 1820-1849 (12_regelwerk_v1_1.json). Prototyp nur W1. Keine Assets nach 1849.
- Basis: Kenney-Kits mit ca. 85 % Abdeckung (Fantasy Town, Nature, Train, Survival, Graveyard, Castle, Prototype, Watercraft, Pirate). Stilbrueche: Retro Fantasy (texturiert), Hexagon, City/Car. [M] asset_audit.md, kenney_messung.md
- Luecken: Pferd (Quaternius Farm Animal Pack, CC0), Kutsche, Personenwagen (Kitbash). [M] asset_audit.md
- Konzept ursprunglich FOV 40, Prototyp FOV 50. [M] prototyp_welt.gd Zeile 44

## B5. Referenzen im Repo [M]

- sprints/s8/design-sprint/referenzen.md und referenz_bilder/ (RE-Referenzbilder, TF3-Bilder, README.md in referenz_bilder). Welche Referenz was belegt, steht dort. Neue Referenzen nur mit Aussage "uebernehme X, ignoriere Y".
- Sichtprueffeedback: integration_w2.md Maengelliste M1-M10, fixpass_w2.md M1-M8.

## B6. Entscheidungsregeln fuer Konflikte (aus Charter abgeleitet)

1. Konflikt Lesbarkeit gegen Massstab: Zeichen (Icon, Schild, Wimpel) einfuehren, Groesse nicht erhoehen. [M] E1, V-Regeln.
2. Konflikt Epochen-Look gegen Kit-Verfuegbarkeit: Prototyp zeigt nur W1. Spaetere Epochen sind Daten, keine Assets. [M] 12_regelwerk_v1_1.json.
3. Konflikt Palette gegen Kenney-Original: Palette gewinnt (Kenney-Meshes sind Vertexfarbe/Flat und werden umgefaerbt). [M] ta_welle2.md.
4. Konflikt Look gegen Perf: Technical Artist hat Veto bei Gate-Verletzung, ich entscheide dann ueber die billigste Look-Variante.

## B7. Bekannte Look-Stolpersteine

1. Wasser/Boden unter 3:1 (G3 offen).
2. 25-m-Uferzacken am Fluss (G2 offen, K35).
3. Feldnaehte/Moire (M5/M6 behoben, Nachpruefung bei neuem Boden).
4. Stilbruch texturierter Kits (Retro Fantasy) neben Flat-Kits.
5. Fernlesbarkeit bei 4.000 m nur gerechnet, nicht mit Spielern getestet.

---------------------------------------------------------------------
# TEIL C - Eigene Luecken und Lernstand
---------------------------------------------------------------------

## C1. Gelernt

| Thema | Stand | Konfidenz |
|---|---|---|
| Wert/Farbe/Silhouette-Reihenfolge | Valve + TF2 + Medium | hoch |
| Graustufen- und Blur-Test | zwei Quellen | hoch |
| Gelaende gedaempft, Funktion gesaettigt | TF2, Dorfromantik, Medium | hoch |
| Art-Bible mit Tie-Breaker, Detail-Floor | eine Analyse (Makko) | mittel |
| Aufsicht: Daecher und Verwitterung zaehlen | Anno-Artikel | mittel |
| Art Fatigue und Wiederholung | eine Quelle | mittel |
| Farbsehschwaeche-Zahl | Fachwissen ohne Quelle | mittel |
| Kontrast 3:1 | Fachwissen WCAG | mittel |

## C2. Weiter unsicher

1. Wie viel Zeichenhilfe (Icon/Schild) reicht, damit E1 haelt UND Fernlesbarkeit bei 4.000 m stimmt. Nur Rechnung, kein Spielertest.
2. Epochen-Look: Aufstocken (gleiche Meshes, andere Palette) oder Austauschen (neue Meshes) je Epoche. Keine belegte Praxis aus geoeffneten Quellen. Konfidenz niedrig.
3. Stilmix Kenney/Quaternius: keine belegte Messmethode ausser dem Repo-eigenen kenney_messung.md. Stilprobe noetig.
4. Wie Strategiespiele (Anno, TF3, HOI4) Zoom-Stufen konkret staffeln: Primaerquellen waren dünn oder nicht lesbar. Konfidenz niedrig.
5. Farbsehschwaeche-Simulation fuer die Palette nicht durchgefuehrt.
6. FOV 40 gegen 50: Entscheidung steht im Repo, Begruendung nicht geprueft.
7. Wasser/Boden-Kontrast: ob 3:1 fuer Wasser sinnvoll ist (Wasser darf sich in Aufsicht sanft abheben) oder ein niedrigerer Wert mit Uferlinie reicht. Streitfrage, nicht entschieden.

## C3. Naechste Schritte (billigster Test zuerst)

1. Graustufen- und Blur-Test aller vier Zoomstufen der Prototyp-Szene.
2. Farbabstand-Tabelle Wasser/Boden/Acker/Wald rechnen, Ziel-Paare festlegen.
3. Kleine Stilprobe: 6 Assets (3 Kenney, 3 Quaternius) in gleicher Palette nebeneinander.
4. Art-Bible-Seite: Tie-Breaker und Detail-Floor in drei Zeilen festschreiben.

## C4. Priorisierte Lernfragen (Details im LERNBERICHT.md)

1. Massstabsdoktrin E1 gegen Lesbarkeit: Zeichen statt Groesse (Prinzip klar, Menge offen).
2. Zoomstufen und Fernlesbarkeit (nur Rechnung, kein Test).
3. Epochen-Look: Aufstocken, Austauschen oder Mischform (offen).
4. Look-Abnahme-Kriterien G1-G3 messbar machen (Methode gelernt, Werte teils offen).
5. Wertestruktur-Test per Graustufen/Blur (gelernt, am Projekt nicht angewandt).
6. Palette und Saettigung 35 % (Repo-Wert, Gegenprobe gegen Quellen steht aus).
7. Stilmix Kenney/Quaternius und Stilprobe (offen).
8. Referenzen mit Aussage (Repo-Referenzen noch nicht neu bewertet).
9. Art-Bible mit Tie-Breaker (Struktur gelernt, Projekt-Seite nicht geschrieben).
10. Farbsehschwaeche (Zahl aus Fachwissen, Simulation offen).
11. Kamera/FOV und Nebel als Look-Parameter (Werte aus Repo, Begruendung offen).

## C5. Grenzen dieser Fortbildung

- Reddit war nicht lesbar (WebFetch SITE_BLOCKED), nicht umgangen. Keine Reddit-Quelle belegt.
- GDC-Vault/YouTube nur Landing-Pages. Vortraege von Dorfromantik, Firewatch, Monument Valley nicht gelesen.
- Polycount nicht abrufbar. Damit fehlt die Praktiker-Debatte ueber Stilmix und Kitbash.
- Viele Quellen sind Studio-Selbstdarstellung (Einzelmeinung), keine Studien.
- Farbtheorie-Zahlen (WCAG 3:1, 8 % Farbsehschwaeche, ΔE2000) aus Fachwissen, nicht aus geoeffneter Quelle.

## D. Lern-Routine (verbindlich, seit 2026-11-03)
**1. Wissenscheck** vor jeder fachlichen Antwort/Entscheidung: Steht sie hier mit Marke [K]/[V]/[R]? Ja: anwenden. Nein, oder nur [E]/[W]/niedrige Konfidenz: weiter mit 2.
**2. Recherche-Trigger** (einer genügt; laut sagen: "Wissenslücke: <Frage>, ich recherchiere"): a) Ich weiß es nicht oder rate. b) Derselbe Kompromiss/Workaround zum 2. Mal ("wieder X statt Y"). c) Eintrag unter Offene Lücken oder [E]/[W]/niedrig, und die Entscheidung hängt daran. d) Skill, Repo, Doku oder Messung widersprechen sich. e) Engine/Tool/Version neuer als der Skill-Stand. f) Basti korrigiert oder eine Entscheidung wird zurückgenommen. g) Teure oder unumkehrbare Entscheidung bei Konfidenz unter mittel. h) Derselbe Fix scheitert 2x.
Rollen-Trigger: Look-Entscheid ohne Vorher/Nachher-Paar; Referenz widerspricht der Epoche; Stil-Mix wieder als Kompromiss.
Erst prüfen statt recherchieren, wenn billig messbar (Test, Doku-grep, Mini-Versuch). Geschmack klärt Prototyp oder Basti, nicht das Web.
**3. Ablauf**: Frage in einem Satz; Primärquellen zuerst (Doku, Issues, Forum, Postmortems; Reddit blockiert, nicht umgehen); 2 unabhängige Quellen; wenn möglich Eigenversuch [V]; Ergebnis mit Quelle, Datum, Marke. Budget 15 min, mehr nur als Agent. Unbeantwortet: Lücke eintragen, Basti/Team fragen, nie raten.
**4. Insight aufnehmen**, wenn alle vier stimmen: wiederverwendbar (2x gebraucht oder über 1 h Aufwand), belegt, noch nicht drin, kein Tagesstand (der gehört in Repo-Doku). Sofort bei Basti-Korrektur, Fehler im Skill oder Engine-Falle mit Repro, sonst gesammelt zum Sprintende. Eine Zeile mit Marke, Datum, Quelle; Widerspruch ersetzt den alten Eintrag; geschlossene Lücke streichen; Skill bleibt ca. 10.000 Zeichen. Im Account nur per Vorschlagskarte an Basti.
**5. Kompromisslog**: jeden Kompromiss, Workaround, jedes "wusste ich nicht" mit Datum in `sprints/s8/fortbildung/mt-artdirection/LERNLOG.md` zählen; Zähler 2 löst Trigger b aus; Auswertung in der Sprint-Retro.
