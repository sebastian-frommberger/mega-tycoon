# Wiki · Art · S-03 Entscheidung: Zoom-Blend und Lesbarkeitsgrenze

Sophie Martin, Art Lead · Stand 20.11.2026 · Ticket S-03 · Status: **Entscheidung getroffen, Belege aus Messung an Personen und auf GPU stehen aus** (G7 damit höchstens Gelb).

Diese Seite ersetzt den vorläufigen Teil 3 in `day1-3/sophie/s03_look_test_befund_und_entscheidung.md`. Alles andere dort (Szene, Messaufbau, Mängel) gilt weiter.

---

## 1. Entscheidung

| Punkt | Entscheidung | Gilt bis |
|---|---|---|
| **Zoom-Blend** | **Ja, als Morphing** (Höhen flachen ab, Details schrumpfen auf Anker, Netz verbreitert sich, Flächen und Icons blenden per Alpha), **kein harter Austausch** von Modellen. Zonen: `mid_blend` 150 m ± 40, `map_blend` 800 m ± 120. | Rücknahme, wenn 2 von 4 Reviewern im Video ein Umspringen sehen **oder** ein GPU-Lauf auf dem Zielrechner einen Frame > 33 ms zeigt |
| **Lesbarkeitsgrenze Kartenstufe** | **4.000 m Kamerahöhe bei 70° Neigung** (Obergrenze des Zooms im VS). Darüber trägt nur noch das Icon, Stadtumriss und Netz werden zur Linie. | Nachprüfung mit dem Kollegentest und auf dem Zielrechner (1080p) |
| **Folge für 512² (D5)** | 4.000 m zeigt die **volle Kartenbreite (5,5 km), aber nur ca. 2/3 der Kartentiefe (3,4 km von 5,12 km)**. Eine 512²-Karte ist bei 70° erst ab ca. **6.100 m** komplett im Bild, und dort ist sie nach meiner Grenze nicht mehr lesbar. **Entscheidung: Die Kartenstufe im VS ist eine Scroll-Ansicht bis 4.000 m, keine Gesamtansicht.** Eine Gesamtansicht (Minimap oder Übersichtsmodus mit Icon-Clustern) ist ein eigenes Ticket, nicht S-03. | F-08 am 24.11. |

Meine Aussage aus Tag 3 „512² passt ab ca. 3,7 km komplett ins Bild“ war **falsch**: sie rechnete nur die Breite. Korrektur siehe 2.2.

---

## 2. Was belegt ist und was nicht

### 2.1 Gerechnet (nachvollziehbar, `s03/lesbarkeit_512.py`, Ausgabe `s03/lesbarkeit_512_ausgabe.txt`)

Kamera FOV 40° vertikal, 16:9, Neigung 70°. Sichtbreite in Bildmitte = 1,377·h, sichtbare Tiefe am Boden = 0,839·h (Strahlen bei 50° und 90°).

| Höhe | Breite | Tiefe | m/px 720p | m/px 1080p |
|---|---|---|---|---|
| 1.000 m | 1,4 km | 0,8 km | 1,08 | 0,72 |
| 2.000 m | 2,8 km | 1,7 km | 2,15 | 1,43 |
| **4.000 m** | **5,5 km** | **3,4 km** | **4,30** | **2,87** |
| 6.100 m | 8,4 km | 5,1 km | 6,56 | 4,38 |

Volle 512²-Karte (5,12 km) im Bild: Breite ab 3.718 m, **Tiefe erst ab 6.102 m** (70°). Senkrecht (90°) hilft nicht: 7.034 m, weil das vertikale FOV das engere ist.

Objektgrößen bei 4.000 m (720p | 1080p): Dorf 15 Felder 35 | 52 px, Kleinstadt 30 Felder 70 | 105 px, Stadt 50 Felder 116 | 174 px, Fabrik Stufe 1 (8 Felder) **19 | 28 px**, Fabrik Stufe 4 35 | 52 px, Zug 20 Felder 47 | 70 px, Gleis 0,5 Feld **1,2 | 1,7 px**, Lkw 2,3 | 3,5 px.

Folgerungen aus der Rechnung:
- Eine Stufe-1-Fabrik ist bei 4.000 m in 720p unter der 24-px-Markergrenze aus S-05. **Industrien tragen ab ca. 2.500 m nur über das Icon** (56 px fest, `pixel_size`), nicht über die Fläche. Das ist im Kartenmodus so vorgesehen und in der Szene so gebaut.
- Das Netz ist geometrisch 1–2 px; die **Verbreiterung im Kartenmodus (auf ca. 5 px) ist Pflicht**, nicht Kosmetik. Ohne sie ist das Netz ab ca. 2.000 m weg.
- 1080p verbessert alles um Faktor 1,5. Die Grenze 4.000 m ist für 720p gerechnet und damit die konservative.
- Cluster-Abstände aus dem Konzept (Stadt zu Cluster 40–90 Felder = 400–900 m) sind bei 4.000 m mit 90–210 px Abstand klar getrennt.

### 2.2 Selbst gesehen (eigener Blick auf Screenshots, Software-Renderer, 720p, eine Szene mit 3 Objekten)

- `shots_far/far_4000m.png`: Stadtumriss mit Raster erkennbar (ca. 70 px), beide Industrie-Icons klar, Netz als Linie zwischen den drei Objekten sichtbar, Weiher erkennbar. **Ich würde die drei Ziele hier finden.** Das ist mein Urteil, kein Messwert.
- `shots_far/far_6000m.png`: nur noch Icons sicher, Stadt ein Fleck, Netz nur dort, wo Fahrzeuge als Farbpunkte liegen.
- Neu aufgefallen bei 4.000 m: Die Fahrzeug-Quader sind als bunte Punkte auf dem Netz sichtbar und machen die Linie überhaupt erst auffällig. Bei 10.000 Fahrzeugen wird das Rauschen. Das stützt Felix' Konzept „Fahrzeuge werden im Fernzoom zu Punkten oder Linienfarbe“, ist aber nicht gebaut.
- Das 70-m-Zellmuster des Bodens blendet mit der Höhe nicht aus (Mangel der Szene, kein Argument gegen die Grenze).
- Popping-Proxy (Tag 3, gerechnet): harter Wechsel 5,8× Median, Blend 1,5×. Rechenindiz für das Morphing, kein Urteil von Personen.

### 2.3 An echten Personen und auf GPU offen (nicht erzeugbar in dieser Umgebung)

| Kriterium (G7) | Stand | Was fehlt |
|---|---|---|
| Kein Frame > 33 ms, Fahrt 50 → 1.000 m in 5 s | **nicht belegt** (Software-Renderer, ≈ 290 ms/Frame) | Zielrechner mit GPU (Katrin, B3). Lauf dauert 15 min, `run_all.sh` |
| 3 von 4 Reviewer sehen kein Popping | **wartet auf echte Durchführung** | 4 Reviewer (Vorschlag Jonas, Felix, Aylin, Daniel), 10 min |
| 4 von 6 Kollegen finden Stadt, Industrie, Strecke in < 10 s je Ziel | **wartet auf echte Durchführung** | 6 Kollegen ohne Art-Beteiligung (Katrin, Block 19.11. 16:00 war angesetzt, kein Beleg der Durchführung). Aufbau `day1-3/sophie/s03_testaufbau_kollegentest.md` |
| Lesbarkeit bei 4.000 m | nur Rechnung und mein Blick | **Zusatzaufgabe für den Kollegentest:** dieselben drei Ziele einmal bei 4.000 m statt 1.000 m (Standbild `far_4000m.png` ohne HUD), gleiche Zeitnahme. Trefferzonen dafür sind noch nicht berechnet (0,25 h) |

**Keine Zahl auf dieser Seite stammt von einer Testperson oder von einer GPU.**

---

## 3. Offene Fragen an Felix (30-min-Review `visibility_range`)

Ich brauche das Review vor dem F-08-Record am 24.11., weil die Grenze 4.000 m nur mit einer funktionierenden Kartenstufe gilt. Konkrete Fragen:

1. **Morphing statt LOD-Fade:** Ich blende per Shader (Höhe, Alpha, Ankerpunkt) und lasse alle Meshes im Baum. `visibility_range_begin/end` plus `visibility_range_fade_mode` würde Meshes ganz aus dem Rendern nehmen. Ist das bei 300 Häusern × LOD + 10.000 MultiMesh-Instanzen ein messbarer Unterschied in Draw Calls oder GPU-Zeit? Reicht Morphing für Häuser und Industrien, und braucht nur das MultiMesh `visibility_range`?
2. **MultiMesh und Fernzoom:** Ab welcher Höhe schaltest du Fahrzeuge auf „Punkte oder Linienfarbe“ (felix.md)? Vorschlag von mir: ab `map_blend` = 1 (920 m) keine Quader mehr, nur noch Belegungsfarbe auf dem Netzsegment. Wer baut das, und zählt es in den F-05-Benchmark?
3. **Schatten:** Ich lasse Schatten an und schrumpfe die Reichweite mit der Höhe, weil Abschalten im Compat-Renderer einen Helligkeitssprung gab. Kosten auf GPU unbekannt. Gibt es eine Schattenschwelle, die du für 10k Fahrzeuge vorgibst?
4. **Tiefenpräzision:** Z-Fighting des Wassers ab 1.500 m bei `near` = 2 m. Darf `near` mit der Höhe skalieren (z. B. `near` = h/200), oder kollidiert das mit dem Bau-Tool-Picking?
5. **Chunks und Kartenmodus:** Terrain in Chunks (256 m) und Streckenmeshes pro Chunk: Kann der Kartenmodus pro Chunk einen zweiten, flachen Mesh-Satz bekommen, oder muss der Terrain-Shader das allein per `map_blend` machen? Das entscheidet 6 PT in S-06a (G3/G4).
6. **Zoom-Obergrenze:** Darf die Kamera im VS hart bei 4.000 m enden, oder braucht das Spiel aus Sim- oder UI-Sicht eine Gesamtansicht (dann eigenes Ticket, nicht S-03)?

Antwortformat reicht als Kommentar unter dieser Seite. Ohne Antwort bis 23.11. gilt für F-08: Grenze 4.000 m, Fahrzeug-Punkte ab 920 m als Annahme.

---

## 4. Restaufwand S-03

0,5 T, davon nichts in meiner Hand: GPU-Lauf (0,25 T, braucht Rechner), Reviewer und Kollegen (0,25 T plus Katrin), Trefferzonen 4.000 m (0,25 h). Ticket bleibt **„wartet auf echte Durchführung“**, die Entscheidung oben ist davon unabhängig gültig, bis sie durch Rücknahmebedingung fällt.
