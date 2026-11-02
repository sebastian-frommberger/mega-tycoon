**Zweck:** Verteilungs- und Anordnungsregeln für Orte und Industrien (Abstände, Poisson-Disk, Gelände-Eignung, Industrie-Ebenen, Anti-Revier, Erreichbarkeits-Validator). Ersetzt die Lage-Logik R1–R8 und die Stadtabstände aus `rules_s7`, wo genannt.
**Status:** Skizze, Phase 2 (Stadt-/Level-Designer, 02.11.2026). Zahlen in `07_regeln_vorschlag.json`, Streitpunkte am Ende von `05_stadtmodell.md`.

Kennzeichnung: **[Q]** Quelle (referenzen.md bzw. Repo), **[~]** Fachwissen, prüfen, **[A]** Annahme. Fahrzeiten aus dem Repo [Q `vehicles.json`, `economy_constants.json`]: Lkw/Fuhrwerk 0,6 Felder/Tick = **150 m/s bei 1×**, Lok 1,0 Felder/Tick = **250 m/s**, Schiff 100 m/s; 1 Spielmonat = 60 s; Straße 10 $/Feld; Ertrag steigt linear bis 60 Felder (1,5 km), danach halbe Steigung [Q `ertrag` dist_knee 60].
**Abgleich:** Maße, Ortsgrößen und Startjahr-Bänder sind mit `01_skalen.md` und `03_welt_prinzipien.md` (Art Director) abgeglichen. Eigene Abweichungen stehen in den Positionen (Umland-Modell, Erz im Fernband, Dorfabstand mit V9 statt 1,5 km).

## 1. Prinzipienkette (E3: Anzahl folgt aus Prinzipien)

| Prinzip | Folge für die Verteilung |
|---|---|
| Kleine Orte in großer Landschaft (1820, E1) | Orte klein (05), Lücken zwischen Orten ≥ 0,8 km Freiland, Landschaft liest sich zuerst |
| Jeder Ort hat einen Grund, genau dort zu liegen | Platzierung nach Gelände-Eignung (Wasser, Furt, Kreuzung, Talrand), nicht nach Raster oder Kette |
| Hierarchie statt Gleichverteilung | Wenige zentrale Orte, viele Dörfer; jedes Dorf hat einen Marktort in Reichweite |
| Lieferketten entstehen aus Geologie und Nähe, nicht aus Bausätzen | Rohstoffe an seltenen Lagerstätten, Veredelung dazwischen, Produktion am zentralen Ort |
| Spielbar vor realistisch | Dichte um Faktor ≈ 2 gegenüber real gestreckt (real 30+ Dörfer auf 164 km² [~] ref 1a), damit Linien Länge haben |

**Spielwirkung der Anzahl:** Mehr Orte → kürzere erste Linien (unter der Ertragsschwelle 1,5 km), mehr Labels, weniger Nachfrage je Ort. Weniger Orte → längere, lohnendere Linien, aber weniger Wahl und leere Übersicht. Die Abstände unten zielen auf **15–21 Knoten** (= Szenario B aus `03_welt_prinzipien.md`): typische Dorf–Nachbar-Strecke 1,8–3 km, also knapp über der Ertragsschwelle. Die Dorfzahl (12–16) ergibt sich aus Eignung und Abstand; der Generator setzt nur eine Obergrenze.

## 2. Abstände Ort–Ort

Zentrum zu Zentrum, Luftlinie. Fahrzeit bei 1×; „Straße“ = Baukosten der Luftlinie.

| Paar | Mindestabstand | typisch | Felder | Fuhrwerk | Zug | Straße | Quelle |
|---|---|---|---|---|---|---|---|
| Weiler – jeder Ort | 0,6 km | 0,8–1,5 km | 24 | 5 s | 3 s | 320 $ | [~] ref 1a, [A] |
| Dorf – Dorf | **max(1,6 km; 5 × Ø Dorfdurchmesser)** | 1,8–3 km | 64–80 | 11–20 s | 6–12 s | 640–1.200 $ | real 1,5–3 km [~] ref 1a; V9 aus 01 (≥ 5 Dorfdurchmesser) |
| Dorf – Marktflecken | 2,5 km | 3–5 km | 100 | 20–33 s | 12–20 s | 1.000–2.000 $ | [A] |
| Marktflecken – Marktflecken | **5 km** | 5–7 km | 200 | 33–47 s | 20–28 s | 2.000–2.800 $ | Christaller 7 km [~] ref 1a, gestaucht |
| Kleinstadt – Marktflecken | 4 km | 4–6 km | 160 | 27–40 s | 16–24 s | – | [A] |
| Kleinstadt – Kleinstadt | **7 km** | 7–9 km | 280 | 47–60 s | 28–36 s | 2.800–3.600 $ | Amtsort 12 km [~] ref 1a, gestaucht |
| Stadt – Kleinstadt | 6 km | 6–9 km | 240 | 40–60 s | 24–36 s | – | [A] |
| Dorf → nächster zentraler Ort (MF/KS/Stadt) | höchstens 6 km | – | 240 | ≤ 40 s | – | – | analog S7 `nachbarstadt_max` [Q] |

S7 zum Vergleich [Q `rules_s7`]: Dorf zu jeder Stufe 1,5 km, Kleinstadt–Kleinstadt 3 km, Stadt–Stadt 5 km. Neu sind also größere Abstände bei kleineren Orten.

**Mindestlücke (keine Zusammenwachsen-Garantie)** [A]: Zwischen den Bebauungsgrenzen zweier Orte liegen **im Endausbau** mindestens 0,8 km Freiland (Weiler–Ort 0,4 km). Endausbau-Radius = Startradius × 1,6 + Vorstadtlänge. Die Stadt-KI stoppt Vorstädte bei halber Lücke (05, 4b Regel 4). Beispiel Dorf–Dorf 1,6 km mit r 125 m: 2 × 125 × 1,6 = 0,4 km bebaut, 1,2 km frei. Bei r 200 m greift V9: Abstand ≥ 2 km, 1,36 km frei.

## 3. Platzierung: Poisson-Disk nach Eignung, kein Raster

### 3a Gelände-Eignung S (0–1.000 ‰, auf 4×4-Feld-Raster)
| Faktor | Gewicht | Bedingung | Quelle |
|---|---|---|---|
| Wasser nah | +300 | Bach/Fluss 100–400 m, Höhe über Wasser ≥ 3 m (hochwasserfrei) | [~] |
| Furt / schmale Stelle | +250 | Flussbreite im Umkreis 300 m am kleinsten (lokales Minimum) | [~] |
| Natürliche Kreuzung | +200 | Schnitt zweier Talwege (Tiefenlinien) oder Talgabelung | [~] |
| Talrand / Hangfuß | +150 | Übergang Ebene (< 3 %) zu Hang (6–15 %) in 300 m, Süd-/Osthang +50 | [~] |
| Ebene Ortslage | +100 | Umfeld r = Ortsradius < 5 % | [Q] S7 Plateau-Regel, gelockert |
| Aue direkt | −400 | Fluss < 100 m oder < 3 m über Wasser | [~] |
| Steil | −500 | Umfeld > 8 % | [Q] S7 |
| Gebirge | ausgeschlossen | Höhe > 600 m oder Gebirgsklasse | [Q] S7 |
| Waldinneres | −200 | Wald im Umkreis 200 m zu > 70 % | [A] |

### 3b Ablauf (Generator-Schritte)
```
1. S berechnen; Randabstand: Knoten ≥ 1 km (40 F), Weiler ≥ 0,4 km           [Q S7 randabstand]
2. Zentrale Orte hierarchisch, „best candidate“: je Ort k = 30 Zufallskandidaten mit S ≥ 600,
   Mindestabstände aus Tabelle 2, nimm max(S + Rauschen ±100)  →  Stadt (Hebel), Kleinstadt, Marktflecken
3. Dörfer: Bridson-Poisson mit paarweisem d_min (Tabelle 2), Annahme eines Kandidaten mit p = S/1.000,
   Abbruch bei Zielanzahl (nicht sättigen: Lücken bleiben für Weiler) 
4. Christaller-Prüfung: jedes Dorf ≤ 6 km zu MF/KS/Stadt, sonst stärkstes Dorf dort → Marktflecken
5. Dorfform je Ort aus Lage: Talboden/Bach → Straßendorf, Mulde + Wasser → Angerdorf, Kreuzung/Ebene → Haufendorf
6. Weiler: Poisson d_min 0,6 km in verbleibende Lücken mit S ≥ 300, auch an Hängen bis 12 %
7. Gemarkungen: Voronoi der Knoten; Weiler und Einzelhöfe zählen zum Umland ihres Knotens (05 Abschnitt 2)
8. Ausfallwege: Gabriel-Graph der Knoten, je Ort 2–4 Richtungen; Wege nur als Ansatz 0,2–0,5 km (Bild), kein vorgebautes Netz
9. Keine Relaxation (kein Lloyd): sie würde wieder Gleichabstand erzeugen
```
Probelauf dieser Rolle (Pfeilwurf bis zur Sättigung auf 10,8 km, 25 % gesperrt, 20 Seeds): Dorf–Dorf 1,8 km → 18–25 Dörfer, 2,2 km → 13–18, 2,5 km → 11–15. Weil nicht gesättigt wird (Obergrenze 16, Annahme ∝ Eignung), ballen sich Dörfer in guten Tälern und lassen Höhen leer. Das ist die Talhäufung, die der Art Director (03) will [A, Skript nicht im Repo].

**Messgröße gegen „konstruiert“** [~, Clark-Evans]: Nächste-Nachbarn-Index R. R < 1 = Klumpen, 1 = Zufall, > 2 = Raster. Ziel Orte R 1,0–1,6 (Talhäufung erlaubt, kein Gleichabstand), Industrien R 0,9–1,5.

Positionen:
- **Sophie:** Eignung + Poisson ergibt Orte an Flüssen und Talrändern, also „gewachsen“ statt gesetzt.
- **Art Director (03):** Gleichmäßiges Poisson sieht konstruiert aus. Dorfabstand 60 F (1,5 km) reicht, Dörfer dürfen in Tälern clustern. Diese Rolle übernimmt die Talhäufung über die Eignung, setzt aber V9 (5 Durchmesser) als harte Untergrenze.
- **Felix (Gegenposition):** Eignungsflächen ballen die Kandidaten (alle am Fluss), und Ketten brauchen danach Platz. Die S7-Reihenfolge (Industrie-Reviere zuerst, Orte drumherum) war für die Erfüllbarkeit gewählt (20/20 Seeds).
- **Empfehlung:** Orte zuerst (Siedlung folgt Gelände), dann Industrie in die Zwischenräume. Erfüllbarkeit über Retry im Seed-Strom wie S7; Ziel ≥ 18 von 20 Seeds ohne Verstoß, sonst Zielanzahl −1.

## 4. Industrie-Ebenen

| Ebene | Spiel-ID (1820-Darstellung) | Anzahl Start | Lage | Abstand Ortsrand | Quelle |
|---|---|---|---|---|---|
| **1 Rohstoff** | getreidefarm (Gutshof, Felder) | 5–8 | Ebene/Aue, frei verteilt | 0,3–3 km | [Q] R1, Abstand gelockert [A] |
| | kohlemine (Stollen) | 2–3 | nur in Lagerstätte Kohle | ≥ 0,5 km | [A], knapp wie 03 |
| | erzmine (Grube) | 1–2 | nur in Lagerstätte Erz, eigener Fleck ≥ 0,75 km von Kohle | ≥ 0,5 km | 03: „je 1–2 an einem Gebirge“ |
| | holzfaeller (Holzplatz), ab S8 | 3–5 | nur Nutzwald | ≥ 0,3 km | [Q] R6 |
| | vieh, oel | 0 (Hebel) | Vieh: Hänge 3–12 %, frei; Öl: erst `startjahr` ≥ 1860 | – | [A] |
| **2 Veredelung** | muehle (Wassermühle) | 3–5 | am Bach/Fluss ≤ 200 m, Ortsrand erlaubt | **0,1–1,5 km** (Mühle am Dorf ist historisch) | [~] ref 1c |
| | stahlwerk (Eisenhütte/Hammerwerk) | 2–3 | Ebene/Tal, Wasser ≤ 400 m | 0,5–3 km | [~] ref 1c |
| | kraftwerk (Köhlerei/Kokerei als Platzhalter) | 2–3 | Ebene/Waldrand | 0,5–3 km | asset_audit, Benennung Lena |
| **3 Produktion** | werkzeugfabrik (Manufaktur) | 1–3, max 1 je zentralem Ort | Vorstadt eines MF/KS/Stadt | **0,15–1,5 km**, nie im Kern | [Q] R5, [A] |

### Abstände zwischen Ebenen
| Kante | Nahband (≥ 1 Quelle Pflicht) | Fernband (Mehrfachquelle) | S7 [Q] | Fuhrwerk Nah/Fern |
|---|---|---|---|---|
| Farm → Mühle | 0,45–0,75 km (18–30 F) | **≥ 1 weitere Farm 0,75–2,0 km** | 18–30 / 31–80 | 3–5 s / 5–13 s |
| Kohle → Stahlwerk | 0,4–0,75 km (15–30 F) | 0,75–2,0 km | 15–30 | 3–5 s |
| Erz → Stahlwerk | **0,75–3 km** (30–120 F), Nahband nicht nötig | – | 18–30 | 5–20 s |
| Kohle → Kraftwerk | 0,45–0,75 km | 0,75–2,0 km | 18–30 | 3–5 s |
| Stahlwerk → Werkzeug | 0,75–2,0 km (30–80 F) | – | 30–42 | 5–13 s |
| Mühle → Ort | 1,0–3,25 km (40–130 F) | – | 40–130 | 7–22 s |
| Werkzeug → Ort | 0,75–6,5 km | – | 30–260 | – |

Das Lösen von Erz aus dem Nahband ist der Hebel gegen die Baukasten-Reviere (Daniel M1): Kohle und Erz liegen in verschiedenen Lagerstätten, das Stahlwerk sitzt an der Kohle (Brennstoff nah, Erz wird gefahren, historisch [~]).

### Mehrfachquellen und Lagerstätten [A]
- **Getreide an 5–8 Stellen**, jede Mühle hat ≥ 2 Farmen bis 2 km, davon ≥ 1 im Fernband ≥ 0,75 km (gegen Daniel N3 „erste Linie wertlos“).
- **Lagerstätten:** nur an **1–2 Bergflanken** je Seed (03, Basti „Mine nur an manchen Bergen“): 2–3 Kohle- und 1–2 Erz-Flecken (r 300–600 m) per Rauschen am Gebirgsfuß, Kohle- und Erz-Fleck ≥ 0,75 km getrennt; höchstens 20 % des Gebirgsfußes sind Lagerstätte. Mine nur dort und nur bei Relief ≥ 60 m in 500 m (gegen Daniel M2 „Mine im flachen Grün“). Getreide ist dagegen **breit** (5–8, frei in Ebene/Aue).
- **Nutzwald:** Wald ≥ 1 km², Hang < 12 %, 30–50 % der Wälder.
- **Gleicher Typ (ersetzt R7 4 km):** Rohstoff ≥ 1,2 km, Veredelung ≥ 3 km, Produktion ≥ 4 km. R7 schließt sonst die Mehrfachquelle aus.

### Anti-Revier-Regeln (Daniel M1/M2)
| ID | Regel | Prüfbar als |
|---|---|---|
| AR1 | In jedem Kreis r = 1,5 km höchstens 3 Industrien und keine vollständige Kette Rohstoff→Produktion | Zählung |
| AR2 | Keine Baukästen: zwei Gruppen gleicher Typfolge dürfen in ihren Abstandsvektoren nicht innerhalb ±20 % übereinstimmen | Vergleich sortierter Abstandslisten |
| AR3 | Jeder Veredler hat Quellen aus ≥ 2 Richtungen (Winkel ≥ 60°) | Winkel |
| AR4 | ≥ 70 % der Rohstoffe haben ≥ 2 mögliche Abnehmer in 2,5 km (keine exklusiven Pärchen) | Zählung |
| AR5 | Clark-Evans R Industrien 0,9–1,5 | Index |
| AR6 | Kein Knoten weiter als 3 km von der nächsten Industrie; jede 4×4-km-Kachel der Spielfläche hat ≥ 1 Industrie, außer > 60 % Gebirge/Wasser (Süd-Zentrum) | Raster |
| AR7 | Lage sichtbar: Mine Relief ≥ 60 m in 500 m; Mühle Wasser ≤ 200 m; Farm Umfeld < 3 % | Gelände |

Positionen:
- **Tobias:** Erz im Fernband verlängert die Stahlkette, gut für Ertrag (Knie 1,5 km) und Zug-Einsatz.
- **Lena (Gegenposition):** Die Montankette hat dann 3 Wege statt 2 nahe; für Anfänger zu schwer. HQ-Vorschau „Wagnis“ (H3) wird häufiger.
- **Art Director (03):** Erz + Holzkohle → Hütte im Nahband 15–30 F, Hütte im Tal am Wasser. Bei nur 1–2 Bergflanken entsteht die Ferne ohnehin über die Lage.
- **Empfehlung:** Agrarkette bleibt die Einstiegskette (V-E7), Montan ist bewusst die zweite Kette mit Zug-Anreiz.

## 5. Erreichbarkeits-Validator

Grundsatz aus der Retro: **Spiel und Validator rechnen dieselbe Funktion** (Steigung, Brückenhöhe `bruecken_hoehe`, Grenzwerte aus `world_s7_meta.json`: Straße 200 ‰, Gleis 120 ‰, Brücke ≤ 8 Felder [Q]).

| ID | Regel | Grenzwert |
|---|---|---|
| V-E1 | Jede Pflicht-Kettenkante hat einen Landweg (Straße) mit ≤ 2 Zwischenpunkten | Steigung ≤ 200 ‰ je Feld, Umweg ≤ 1,6 × Luftlinie, Brücke gerade ≤ 8 F |
| V-E2 | Je Montangruppe ≥ 1 Kette auch als Gleis baubar | ≤ 120 ‰, Umweg ≤ 2,0× |
| V-E3 | Knotennetz zusammenhängend: jeder Knoten erreicht ≥ 1 Nachbarn per Land | Umweg ≤ 1,5×; je Fluss ≥ 2 Querungen in der Spielfläche |
| V-E4 | Flussquerbarkeit | ≥ 80 % der Fluss-Spalten gerade querbar (Daniel Regression 2) |
| V-E5 | Industrie-Zufahrt | ≥ 2 Footprint-Seiten mit Steigung ≤ 120 ‰ auf 3 Feldern |
| V-E6 | Ortsanschluss (Z-01) | ≥ 2 Ausfallrichtungen bis zum Ortsrand ≤ 120 ‰ |
| V-E7 | Startkette | ≥ 60 % der Knoten haben eine komplette Agrarkette (Farm, Mühle, dieser Ort) in ≤ 2,5 km; HQ-Vorschau rechnet dieselbe Funktion (Daniel H3) |
| V-V1 | Mindestabstände Tabelle 2, Randabstand, Mindestlücke im Endausbau | s. o. |
| V-V2 | Hierarchie: Dorf ≤ 6 km zu zentralem Ort | s. o. |
| V-V3 | Verteilung: Clark-Evans Orte 1,2–1,7, AR1–AR7 | s. o. |

Positionen:
- **Felix:** V-E1 mit A* je Kante kostet 21–30 Kanten × 512² Felder. Machbar mit grobem A* (4×4-Felder) und Feinprüfung nur am Engpass.
- **Daniel (Gegenposition, Abnahme):** Grob-A* übersieht genau die Rampen- und Böschungsfälle (H2, M3). Nur der Fein-Test zählt.
- **Empfehlung:** Grob für die Auswahl im Generator, fein im Validator; Validator ist das Gate.

## Offene Fragen an Basti
1. Gilt „spielbar vor realistisch“ bei der Dichte, also etwa 15–20 Orte statt realer 30+ Dörfer auf der Karte?
2. Sollen Kohle und Erz an verschiedenen Bergen liegen (längere Montankette, Zug lohnt), auch wenn der Einstieg dort schwerer wird?
3. Darf die Randlandschaft (außerhalb der 12,8 km) Deko-Dörfer ohne Funktion zeigen, damit die Karte nicht als Insel wirkt?
