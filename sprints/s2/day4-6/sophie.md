# Sophie – Sprint 2, Tag 4–6

## Daily Tag 4 (19.11.)
Gestern: S-03-Befund, Palette v1, Klick-Test. Heute: D5/D10 gelesen, 512²-Rechnung, Ghost-Umstellung. Blocker: kein Zielrechner, kein Kollegen-Block belegt, nichts in `day4-6/daniel/`.

## Daily Tag 5 (20.11.)
Gestern: Rechnung 512². Heute: S-03-Wiki-Eintrag, Felix-Fragen, S-05 final mit Ghost-Prüfung. Blocker: Kollegentest und GPU-Lauf nicht durchführbar; Daniels Farbcheck fehlt.

## Daily Tag 6 (23.11.)
Gestern: Wochenende. Heute: S-06a Asset-Liste, Kenney: 18 Proben gemessen, Godot-Probeszene. Blocker: Ketten-Scope (3 oder 5) und Artist-Start unentschieden; Katrin erst 24.11.

## Ergebnisse
- **S-03: Entscheidung steht, Ticket „wartet auf echte Durchführung“.** `s03_entscheidung_wiki.md`, `s03/lesbarkeit_512.py`. Blend ja (Morphing), Grenze 4.000 m bei 70°. **Korrektur zu Tag 3:** 512² passt bei 4.000 m nur in der Breite (5,5 km), nicht in der Tiefe (3,4 von 5,12 km); ganze Karte erst ab 6.100 m, dort nicht mehr lesbar. Kartenstufe im VS = Scroll-Ansicht, Gesamtansicht eigenes Ticket. AK: Szene ja; Frame ≤ 33 ms **nein, nicht belegt**; Popping 3/4 und Kollegen 4/6 **nicht geprüft** (keine Personen, keine GPU); Wiki-Eintrag **ja**. Sechs Fragen an Felix im Eintrag.
- **S-05: fertig (v1 final, gerechnet).** `s05_palette_v1_final.md`, `s05/palette_v1_final.csv`. Ghost Weiß = baubar, Rot schraffiert = nicht baubar, Blau nur Hinweis. Weiß gegen Stadtfläche ΔE ≥ 14 (ok), gegen Konsum-Weiß 2,6 → dunkler Saum Pflicht. Daniels Lauf fehlt, Rechnung von mir mit seinem Skript. Kein Mensch mit Farbschwäche geprüft.
- **S-06a: Entwurf fertig, nicht mit Katrin abgestimmt.** `s06a_assetliste.csv` (51 Zeilen), `s06a_assetliste.md`, `kenney_messung.md`, `kenney/`. Summen: Sophie 48 PT, Artist 67,5 PT (KERN 46 / 5 Ketten +11 / Archetypen +10,5), mit Kenney Artist 49 PT. Kapazität (Annahme): Sophie 56, Artist 68 ab 01.12. bzw. 49 ab 04.01. **3 Ketten passen, 5 Ketten plus Hafen/Fluss nur ohne Puffer bei Start 01.12.** Kenney gemessen: Bäume/Felsen/Anbauten/Schiff final tauglich, **Fahrzeuge 7–8× über Budget (Lkw 2.082–2.488 Tris)**, Gleiskacheln treffen das 10-m-Raster nicht, Kits nicht maßstäblich (Faktoren 3,4–10). AK „mit Katrin abgestimmt bis 24.11.“: **nein, offen.**

## Annahmen und offene Fragen an andere
- **Jonas:** Ketten-Scope VS 3 oder 5 (Brief vs. `katrin_overview`); Hafen/Schiff und Fluss im VS; Regeländerung Platzhalter-Meshes (Vorschlag in `s06a_assetliste.md` §4); Kamera hart bei 4.000 m ohne Gesamtansicht?
- **Felix:** 30-min-Review, sechs Fragen im Wiki-Eintrag; Kenney-Wagen tragen Ladegut im Mesh, Instanzfarben-Pfad betroffen; F-05 bitte mit Quadern/300 Tris messen, nicht mit Kenney.
- **Katrin:** Abstimmung S-06a 24.11., Artist-Start, Zielrechner, 6 Kollegen + 4 Reviewer, Farbschwäche-Personen.
- **Daniel:** Farbcheck mit `palette_v1_final.csv`, Kollisionsprotokoll.
- **Aylin:** Ghost-Saum/Alpha in A-06; Annahme: Formen übernommen.
- **Tobias:** Güterliste (S-05b, U1).

## Risiko für das Sprintziel
S-03 bleibt für G7 höchstens Gelb, weil alle drei Messkriterien ohne Personen und GPU offen sind; G6 bekommt meine 4.000-m-Grenze als Rechnung, nicht als Beleg. S-06a geht ohne Katrin-Abstimmung und ohne Ketten-Entscheidung als Entwurf ins Gate; G9 ist dann Gelb. Das Sprintziel selbst (Playtest, Sim-Kern, Lizenzleiter) hängt an meinen Tickets nicht.
