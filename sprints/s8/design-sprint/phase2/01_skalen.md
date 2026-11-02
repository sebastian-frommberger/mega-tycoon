# 01 Skalen-Tabelle Welt (Art Director Welt, Design Sprint „Welt“, 02.11.2026)
Zweck: Feste Maße und Verhältnisse für alle Weltobjekte in Metern und Feldern (1 Feld = 25 m, Karte 512² Felder = 12,8 km), Grundlage für Stadtmodell, Asset-Mapping und Prototyp-Messung.
Status: Skizze, Phase 2. Kennung: [Q] Quelle laut `referenzen.md`, [~] Fachwissen ungeprüft, [Annahme] Setzung Art Director, [S7] Bestand im Code.

## Grundregeln
| # | Regel |
|---|---|
| G1 | **Ein Maßstab für Sim und Bild:** Länge in Feldern = Meter / 25. Die Sim rechnet weiter in Feldern [S7], das Bild zeigt dieselbe Länge in Metern. Kein Objekt bekommt einen eigenen Bildmaßstab. |
| G2 | **Wahl im Realband statt Faktor:** Wo etwas lesbarer sein muss, wird das obere Ende der realen Spanne gewählt (Kirchturm 45 statt 30 m), nie ein Vergrößerungsfaktor. |
| G3 | **Einzige Überhöhung: Fahrzeuge ≤ 1,2× real** (E1). Häuser, Industrie, Bäume, Wasser, Wege = 1,0. Der Vorschlag aus dem Asset-Audit (Fahrzeuge ×1,5, Bäume ×1,2) ist damit überstimmt. |
| G4 | **Feld ≠ Objekt.** Ein Feld (25 m) ist größer als ein Haus (12 m) und viermal so breit wie eine Straße (6 m). Das Feld ist eine Netz- und Rechenzelle, keine Bildfläche. |
| G5 | Kit-Importfaktoren aus `asset_audit.md` Tab. 1 bringen jedes Kit auf echte Meter. Erst danach greift diese Tabelle. |

## A Gebäude
| Objekt | real (m) | Spiel (m) B×T, H | Felder | Faktor | EW | Kenn. |
|---|---|---|---|---|---|---|
| Haus S (Kate, Tagelöhner) | 8×6, First 6–7 | 8×6, H 6–7 | 0,32×0,24 | 1,0 | 4–6 | [~] |
| Haus M (Bauern-/Handwerkerhaus) | 12–20×9–12, First 9–12 | 12×9, H 9–11 | 0,48×0,36 | 1,0 | 6–10 | [~], ref. 12×10 → 12×9 (Kenney-Modulraster 3 m) |
| Hofstelle (Haus M + Scheune + Hof) | 25–40 | 25×25 | **1×1** | 1,0 | (6–10) | [~], 1 Hof = 1 Feld |
| Scheune/Stall | 15–25×10–12 | 18×10, H 8–10 | 0,72×0,4 | 1,0 | 0 | [~] |
| Haus L (Bürgerhaus, 3 Gesch.) | 8–14×12–15, Traufe 10–14 | 12×14, Traufe 12, First 15 | 0,48×0,56 | 1,0 | 12–20 | [~] |
| Haus XL (Mietshaus, erst ab 1840) | 15–20 Front, 4–5 Gesch. | 16×12, H 16–18 | 0,64×0,48 | 1,0 | 25–40 | [~], Epochenparameter |
| Dorfkirche | Schiff 20–25, Turm 25–35 | 20×10, Turm 30 | 0,8×0,4 | 1,0 | – | [~] |
| Stadtkirche (Landmarke) | Schiff 25–40, Turm 30–60 | 35×15, Turm 45–55 | 1,4×0,6 | 1,0 | – | [~], oberes Band (G2) |
| Marktplatz | – | 40×60 (Marktfl.) bis 60×80 (Kleinstadt) | 1,6×2,4 bis 2,4×3,2 | 1,0 | – | [Annahme] |
| Bahnhof früh | Empfangsgeb. 20–40×10–15 | 30×12, H 10 | 1,2×0,5 | 1,0 | – | [~] |

## B Wege und Gleis
| Objekt | real (m) | Spiel (m) | Felder | Steigung / Radius | Kenn. |
|---|---|---|---|---|---|
| Feldweg | 3–4 | 3,5 (Erdband, kein Rand) | 0,14 | folgt Gelände | [~] |
| Dorfstraße | 5–8 (Anger bis 12) | Fahrbahn 6, Ortsdurchfahrt bis 10 | 0,24 | – | [~], ersetzt Kenney 12 m |
| Stadtgasse | 4–6 | 5 | 0,2 | – | [~] |
| Chaussee/Landstraße | Steinbahn 5–6, gesamt 10–13 | Fahrbahn 6 + Bankett/Graben/Baumreihe = 11 | 0,24 (Trasse 0,45) | ≤ 5 % [Q], Radius ≥ 50 m | Breite [~] |
| Gleis eingleisig | Spur 1,435, Schwelle 2,6 | Bettung 4, Trasse mit Graben 7 | 0,16 (Trasse 0,28) | Ziel ≤ 1–2,5 %, Radius ≥ 100 m | [~] |
| Gleis zweigleisig | 8–10 | 9 | 0,36 | wie oben | [~] |
| Bahnsteig früh | 60–120 × 3–4 | 110 × 4 | 4,4 × 0,16 | – | [~], trägt Zug von 70 m |

## C Fahrzeuge (Ausnahme ≤ 1,2×)
| Objekt | real (m) | Spiel (m) | Felder | Faktor | Kenn. |
|---|---|---|---|---|---|
| Pferd (Reit-/Zugpferd) | 2,4–2,8 × 0,7 | 3,0 × 0,8 | 0,12 | 1,1 | [~] |
| Fuhrwerk, 2 Pferde (ersetzt Lkw) | 8–9 × 2 | 9,5 × 2,2 | 0,38 | 1,1 | [~] |
| Postkutsche, 4 Pferde (ersetzt Bus) | 10–12 × 2 | 12,5 × 2,2 | 0,5 | 1,1 | [~] |
| Dampflok + Tender (Adler-Klasse) | 7,62 + ca. 4 | 9 + 4,8 = 13,8 | 0,55 | 1,19 | [Q] Lok, Tender [~] |
| Personenwagen | 5,74 | 6,9 | 0,28 | 1,2 | [Q] |
| Güterwagen | 5–6 | 6,9 (Kenney 7 m passt) | 0,28 | 1,15–1,2 | [~] |
| Zug: Lok + Tender + 8 Wagen (`max_anhaenger` 8 [S7]) | ca. 57 | 69 | **2,8** | 1,2 | aus [Q] |
| Raddampfer früh | 35–50 × 6 (Radkästen 12) | 50 × 12 | 2,0 × 0,5 | 1,1 | [~], fährt nur auf Fluss ≥ 50 m |
| Kahn/Treidelboot | 20–30 × 4–5 | 28 × 5 | 1,1 | 1,0–1,1 | [~] |

## D Industrie (Standard 1820, Spätformen über Startjahr)
Gebäude real (1,0). „Werksgelände“ ist die Signalfläche: echter Inhalt (Acker, Halde, Holzplatz, Teich), keine eingefärbte Fläche. Farbe nur in Icon und Plakette (Basti-Punkt 5).

| Typ (Sim-Slot) | Hauptgebäude (m) | Landmarke H (m) | Werksgelände m (Felder) | Signal im Gelände | Kenn. |
|---|---|---|---|---|---|
| Gutshof/Getreidefarm | Vierseithof 40×40 | Speicher/Scheune 12–15 | Hof 40 (1,6 F) + Schläge 150–300 (6–12 F) | große einheitliche Getreideschläge (real, nicht überzeichnet) | [~] |
| Wassermühle | 12×12, Rad Ø 5 | 12 | 50 (2 F) + Mühlgraben/Teich 75–150 (3–6 F) | Graben, Wehr, Teich | [~] |
| Windmühle (Holländer) | Ø 8 | 20–25 | 25 (1 F) | Flügel Ø 20 | [~], ref. 25–30 → real 20–25 |
| Erz-/Kohlengrube (Stollen) | Kaue 15×10 | Göpel/Haspel 10–15 | 75–125 (3–5 F) | Halde Ø 30–60, H 5–15, Stollenmund am Hang | [~] |
| Tiefbauzeche (ab 1840) | 30×15 | Malakowturm 25–35 | 150–250 (6–10 F) | Halde, Gleisanschluss | [~] |
| Eisenhütte (Holzkohle; Stahl-Slot) | Hochofen 10×10 + Gießhaus 25×12 | Gicht/Esse 15–20 | 150–250 (6–10 F) | Kohlplatz, Erzhaufen, Teich, Hammer | [~] |
| Hammerwerk | 20×12 am Bach | Esse 12–15 | 50–75 (2–3 F) | Wehr, Wasserrad | [~] |
| Manufaktur (Werkzeug-Slot) | 40×12, 3 Gesch. | Dachreiter 14–16; ab 1850 Schornstein 30–40 | 75–100 (3–4 F) | Lagerhof, Fuhrwerke | [~]/[Annahme] |
| Köhlerei (Kraftwerk-Slot 1820) | Meiler Ø 8–10, Hütte 8×6 | Rauchsäule | 50–75 (2–3 F) am Waldrand | Meiler, Holzstöße | [Annahme], Slot-Mapping offen |
| Sägemühle | 25×10 | 8–10 | 50–75 (2–3 F) | Stammholzplatz | [~] |
| Lager/Speicher | 25×12 | 12 | 25–50 (1–2 F) | Fässer, Kisten | [~] |
| Bahnhofsanlage früh | s. A | – | 150–250 × 50 (6–10 × 2 F) | Gleisfächer, Bahnsteig | [~] |

Gegen S7: Industrie-Plateau Ø 150 m und Signalflächen 150–300 m [S7] sind 1820 nur für Hütte und Tiefbauzeche richtig. Mühle, Grube, Hammer und Säge schrumpfen auf 2–5 Felder.

## E Wasser und Brücken
| Objekt | real (m) | Spiel (m) | Felder | Darstellung | Kenn. |
|---|---|---|---|---|---|
| Mühlgraben | 2–4 | 3 | 0,12 | Spline-Mesh | [~] |
| Bach | < 5 | 4–6 (oberes Band) + Ufergehölz 10–20 je Seite | 0,2 (mit Saum 1–1,6) | Spline-Mesh, Lesbarkeit über Erlen/Weidensaum | [Q], ref. ×2 → 1,0 |
| Nebenfluss | 10–30 | 15–25 | 0,6–1 | Spline-Mesh + flache Rinne | [Q]/[~] |
| Fluss (Hauptfluss Karte) | 50–150 | **60–120** (S7 heute 32–72) | 2,4–4,8; Aue 20–80 F (0,5–2 km) | Gelände-Rinne + Wasser-Shader (E2) | [~] |
| Strom | 300–450 | nur Kartenrand, wenn überhaupt: 250–350 | 10–14 | – | [~], ref. ×0,7 → 1,0 oder weglassen |
| Dorfteich / Mühlteich | 15–30 / 50–150 | gleich | 0,6–1,2 / 2–6 | Fläche | [~] |
| Bachbrücke (1 Steinbogen) | 5–10 Spannweite | 8, Breite = Weg | 0,3 | liegt innerhalb eines Feldes | [~] |
| Flussbrücke Stein | Bögen 10–25 | 4–8 Bögen à 15, Länge Fluss + 30 | 3–6 | Bogenzahl aus Breite | [~] |
| Holzbrücke | Joche 6–10 | Joche 8 | – | billiger, nur Weg/Straße | [~] |
| Eisenbahnviadukt (ab 1840) | Bögen 15–20, H bis 30 | gleich | – | Epochenparameter | [~] |
| Laubbaum / Obstbaum / Nadelbaum | H 15–25 / 6–8 / 20–30 | gleich | Krone 0,3–0,5 | MultiMesh | [~], Audit ×1,2 → 1,0 |

## F Ortsgrößen (Start 1820)
| Klasse | EW | Wohnhäuser (S/M/L) | Nebengeb. | Radius Ortslage m (Felder) | Dichte EW/ha | Häuser je Feld | Form | S7 heute |
|---|---|---|---|---|---|---|---|---|
| Weiler | 20–60 | 4–10 (M) | 4–10 | 40–75 (2–3) | – | ≤ 1 Hof | lose, ohne Kern | – |
| Dorf | 150–400 | 25–60 (S 30 %, M 70 %) | 20–50 | 125–200 (5–8); Straßendorf 400–800 lang | 25–40 | 0,5–1 Hof | Haufen-, Straßen-, Angerdorf | r 225 m, ≥ 80 Geb., 400–999 EW |
| Marktflecken | 800–1.500 | 100–180 (M 70 %, L 20 %) | 40–80 | 175–250 (7–10) | 60–100 | 2–3 | Haufendorf + Marktplatz, Ausfallstraßen | – |
| Kleinstadt | 2.000–5.000 | 200–400 (L im Kern) | 50–100 | Kern 200–300 (8–12) + Vorstädte bis 350–450 (14–18) | Kern 120–200 | 3–5 | Mauerring, Tore, Vorstadt-Zeilen | r 450 m, ≥ 400, 1.000–4.999 EW |
| Stadt (nur Wachstum/Spätstart) | 10.000–20.000 | 900–1.500 | – | 600–900 (24–36) | 150–250 | 4–6 | + Bahnhofsviertel (einziges Raster) | r 800 m, ≥ 1.200, 5.000–19.999 EW |

Herleitung Dorf: 250 EW in r 160 m (8 ha) = 31 EW/ha, 250 / 6,5 EW je Haus = 38 Wohnhäuser. Kleinstadt: 3.000 EW in Kern r 250 m (19,6 ha) = 150 EW/ha, 300 Häuser. Alle Werte im Band von `referenzen.md` 1a.

## G Verhältnis-Regeln (prüfbar, ±25 %)
| # | Verhältnis | Soll | Prüfsatz |
|---|---|---|---|
| V1 | Haus M Länge : Dorfstraße : Fuhrwerk | 12 : 6 : 9,5 (= 2 : 1 : 1,6) | Ein Fuhrwerk ist kürzer als ein Haus M und länger als die Straße breit. |
| V2 | Straße : Fahrzeugbreite | ≥ 2,5 : 1 | Zwei Fuhrwerke begegnen sich auf der Dorfstraße ohne Überlappung. |
| V3 | Feld : Haus M | 25 : 12 ≈ 2 : 1 | Eine Hofstelle füllt genau ein Feld. |
| V4 | Lok + Tender : Haus M | 14 : 12 ≈ 1,2 : 1 | Die Lok ist nie länger als 1,5 Häuser. |
| V5 | Zug : Bahnsteig | 69 : 110 | Der längste Zug passt an den frühen Bahnsteig. |
| V6 | Kirchturm : Traufe Haus M | ≥ 3 : 1 | Bis 1840 ist der Kirchturm der höchste Punkt im Ort. Ab 1850 darf ein Schornstein gleichziehen (Epochensignal). |
| V7 | Industrie-Hauptgebäude : Haus M (Grundfläche) | ≤ 4 : 1 (1820) | Kein Werksgebäude ist größer als 4 Bauernhäuser. Nur das Gelände darf groß sein. |
| V8 | Fluss : Haus M | 60–120 : 12 = 5–10 Hauslängen | Der Hauptfluss ist breiter als ein Dorf-Straßenzug lang ist. |
| V9 | Abstand Dorf–Dorf : Dorf-Ø | ≥ 5 : 1 | Zwischen zwei Dörfern liegen mindestens 5 Dorfdurchmesser Landschaft. |

## Toleranz und Ausnahme
- **Prototyp-Test:** Jedes Objekt wird per Bounding-Box gegen den Spielwert gemessen. Erlaubt sind **±25 %** (Charter). Bei Bändern gilt das Band ±25 %.
- **Fahrzeuge:** harte Obergrenze 1,2 × real-Maximum, die Toleranz wird **nicht** draufgerechnet (sonst 1,5×). Untergrenze 0,9 × real.
- **Begründung der Ausnahme:** Fahrzeuge sind die einzigen Objekte, denen das Auge folgt. Bei 1,0 wirken Pferd und Wagen neben 25-m-Feldern spielzeughaft dünn. 1,2× fällt im Nebeneinander mit Häusern nicht auf (V1, V4 halten). Mehr als 1,2× bricht V1 (Basti: Lkw „gigantisch“).
- **Fernsicht (FOV 50° [S7], 1080p):** Bei 5,6 km Kamera ≈ 4,8 m/px. Haus 2–3 px, Fuhrwerk 2 px, Straße 1 px, Zug 14 px, Fluss 12–25 px. Lesbarkeit dort nur über Zeichen: Ortsname + EW-Plakette, Industrie-Icon, Fahrzeug als Punkt/Icon mit Linienfarbe, Wege und Bäche als Linie mit Mindestbreite 1–2 px **im Bildraum**. Die Geometrie bleibt real (siehe 02, P2).

## Straße und Gleis im 25-m-Raster
| Ebene | Regel |
|---|---|
| Sim | Straße/Gleis ist eine Kante zwischen Feldmitten (8 Richtungen) [S7]. Kosten, Wege, Fahrzeugposition und Länge in Feldern. Zug 2,8 F, Fuhrwerk 0,38 F. |
| Bild: Band | Die Fahrbahn ist ein 6-m-Band (Gleis: 4-m-Bettung) entlang einer **geglätteten Kurve durch die Feldmitten**. Diagonalen sind gerade 45°-Linien, keine Treppen (W-04b). Richtungswechsel als Bogen: Dorfstraße R ≥ 25 m (1 F), Chaussee ≥ 50 m (2 F), Gleis ≥ 100 m (4 F) [Annahme]. Fahrbahnstücke als ein durchgehendes Spline-Mesh, nicht als Kacheln (keine Fugen). |
| Bild: Restfläche | Die übrigen 19 m des Feldes gehören **nicht** zur Straße. Über Land: Bankett, Graben, Baumreihe (Chaussee), Feldrain. Im Ort: Vorgarten, Hofeinfahrt, Hausfront. Häuser stehen im selben Feld wie die Straße, Traufe 2–6 m vom Fahrbahnrand. So entsteht keine 25-m-Schneise. |
| Bild: Parzellen | Gebäude werden im Generator auf einem **12,5-m-Halbfeld-Unterraster** mit Jitter (±2 m, ±8°) gesetzt. Die Sim zählt Gebäude und EW je Feld [Annahme]. |
| Parallel | Straße und Gleis nebeneinander belegen in der Sim 2 Felder. Im Bild liegen sie bis 25 m auseinander, was historisch passt (Bahn meist abseits der Chaussee). |
| Brücke | Brückenfelder = Wasserbreite / 25 aufgerundet + 1 Rampenfeld je Seite. Bachbrücke liegt im Feld (kein Brückenfeld). |

**Steigung (Konflikt):** Das S7-Backlog nennt eine Gleisgrenze von 12 %. Real waren es 1 % (Hauptbahn) bis 2,5 %. Vorschlag: hart 4 %, Tempo- und Kostenabschlag ab 2 % [Annahme]. Tobias widerspricht: Auf 12,8 km mit 1.000 m Relief wird damit das Gebirge für die Bahn gesperrt. Entscheidung in den Landschaftsregeln.

## Änderungen gegenüber `referenzen.md` / `asset_audit.md`
| Wert | vorher | jetzt | Grund |
|---|---|---|---|
| Bach | 8–12 (×2) | 4–6 + Ufergehölz | E1. Lesbar über den realen Gehölzsaum und Linie im Bildraum |
| Strom | 200–300 (×0,7) | 250–350 oder kein Strom | Unterzeichnen bricht E1 genauso wie Überzeichnen |
| Kirchturm | 35–45, ×1,0–1,2 | Dorf 30, Stadt 45–55, ×1,0 | G2 |
| Windmühle | H 25–30 | H 20–25 | real |
| Zeche | Turm ×1,2 | 1820 Göpel 10–15, Malakow erst ab 1840 | Epoche, ×1,0 |
| Fahrzeuge / Bäume (Audit) | ×1,5 / ×1,2 | ≤ 1,2 / 1,0 | E1 |
| Haus M | 12×10 | 12×9 | Kenney-Modul 3 m |

## Stimmen
| Wer | Position | Gegenposition |
|---|---|---|
| Lena | Hof = 1 Feld ist Gold wert: Stadtwachstum und Einwohner lassen sich je Feld zählen, ohne neues Raster. | Aylin: Ein Hof je Feld wirkt im Dorf als Gitter, darum braucht es Jitter und Halbfeld-Parzellen. |
| Tobias | Sim bleibt in Feldern, Ökonomie unberührt. Zuglänge 2,8 F betrifft nur Bahnsteig und Signalblöcke. | Lena: Bahnsteig 4–5 F ist länger als ein Dorf breit. Der Bahnhof muss deshalb vor den Ort (passt historisch). |
| Aylin | Bei 1,2× ist ein Fuhrwerk ab 2 km nur 5 px groß. Ohne Icon-Ersatz verliert man die eigenen Fahrzeuge. | Art Director: Das Icon ist erlaubt (Zeichen), ein größeres Mesh nicht. |

## Offene Fragen an Basti
1. **Fernsicht:** Dürfen Wege, Bäche und Fahrzeuge ab etwa 2 km als Zeichen erscheinen (Linie oder Icon mit 1–2 px Mindestbreite im Bildraum), während die Geometrie real bleibt? Sonst verschwinden Bach und Fuhrwerk in der Übersicht.
2. **Tempo:** Die Größen sind jetzt real, aber die Fahrzeuge fahren in der Sim 150 m/s (Fuhrwerk-Slot) bzw. 250 m/s (Lok), also 30- bis 100-fach gerafft [S7: 6 bzw. 10 F/s]. Soll das Tempo im Bild gerafft bleiben (Genre-Standard) oder je Zoom gedämpft werden (Railway-Empire-Option)?
3. **Strom:** Darf eine Startkarte einen Strom (250–350 m, Fähre statt Brücke) zeigen, oder höchstens einen Fluss (60–120 m)?
