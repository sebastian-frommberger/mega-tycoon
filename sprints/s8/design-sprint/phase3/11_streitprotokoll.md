# 11 Streitprotokoll Phase 3 „Entscheiden“ (Design Sprint Welt, 02.11.2026)
Moderation und Entscheidung: **Jonas (PO)**. Am Tisch: Lena (Game Design), Tobias (Ökonomie), Aylin (UX), Sophie (Art), Felix (Technik), Daniel (QA); Skizzen von Art Director, Technical Artist (TEAM-02), Stadt-/Level-Designer.
Grundlage: `charter.md` (E1–E5), `referenzen.md`, `asset_audit.md`, `phase2/01–10`, `feedback_02-11`, `s7/review_retro.md`, Bastis TF3-Referenzen `referenz_bilder/tf3_01–09`.
Status-Werte: **entschieden** (PO, gilt) · **Annahme** (PO setzt, Prototyp oder Basti kann kippen) · **an Basti** (Grundsatz, `13_fragen_an_basti.md`).

## Übersicht
| # | Konflikt | Entscheidung (kurz) | Status |
|---|---|---|---|
| K1 | Siedlungszahl, Nachfrage, Label | Hierarchie B+: 2 Kleinstädte (min. 1), 2–3 Marktflecken, 12–16 Dörfer, Kulisse-Weiler; Umland-Modell; Label = sichtbare Einwohner | Annahme, F1 |
| K2 | Stahl ohne Abnehmer 1820 | Scheinkonflikt: Manufaktur ist schon heute die Senke. Kein Kartenrand-Markt | entschieden |
| K3 | Gleis-Steigung | hart 6 % (Fallback 8 %), Kosten über Hangregel, Tempoabschlag S8 | Annahme |
| K4 | Fahrzeugtempo | Sim-Tempo bleibt, Darstellung testet Basti im Rundgang | an Basti, F4 |
| K5 | R7-Abstände, Erz-Lage | abgestuft 1,2/3/4 km; Erz 0,75–3 km, ≥ 1 Erzfleck ≤ 2 km | entschieden |
| K6 | Terrain (Boden, Relief, Schnee, Plateaus) | Bodenkarte; ds_v2; Schnee 1.000 m; Plateaus nach Ortsform | entschieden |
| K7 | Wasser (Shader, Bachbreite) | opaker Shader aus 09; Bach 4–6 m + Gehölzsaum + Fernlinie | entschieden |
| K8 | Straße: Band vs. Kachel | Sim-Kante bleibt, Bild = Spline-Band ohne Kacheln | entschieden |
| K9 | Dorfformen, Kohle/Erz, Deko-Dörfer, unversorgte Orte | nach Gelände + Regionsgewicht; getrennte Flecken; Deko-Weiler ja; Wachstum offen | Annahme, F2 |
| K10 | Kenney-Raster gegen Skalen (Lok, Bürgerhaus) | Lok-Längsfaktor 1,13; Traufe Haus L 9,5–12 m | entschieden |
| K11 | Kraftwerk-Slot 1820 als Köhlerei | Kalkofen/Ziegelei | Annahme |
| K12 | Mühle am Wasser, aber nur ein Fluss | Generator bekommt Bäche und Nebenflüsse | entschieden |
| K13 | Anti-Revier AR3 gegen knappe Kohle | AR3 nur für Mühlen | entschieden |
| K14 | Sim-Footprint Industrie (100 m) gegen 12-m-Mühle | Footprint bleibt, Bild füllt Werksgelände | entschieden |
| K15 | Gebirge innen 32 % statt ≤ 15 % | Massiv −15 %, Gate ≤ 20 % | Annahme |
| K16 | Zahlenwidersprüche zwischen den Skizzen | Auflösung in `12_welt_regelwerk_v1.md` §12 | entschieden |
| K17 | Bäume real groß = 3–4× so viele | Wald fern als Boden + Tupfen, Deckel 120k | entschieden |
| K18 | Marktflecken-Nachfrageknick | unverändert, an Tobias S8 | entschieden |
| K19 | Startjahr als Schwierigkeit | zwei getrennte Optionen | entschieden |
| K20 | Abgleich Transport Fever 3 | bestätigt E1 und die Skizzen weitgehend; Seen an Basti; HQ-Bonus als Annahme | Annahme, F5 |

---

## K1 Siedlungszahl, Nachfrage, Label
| Rolle | Argument |
|---|---|
| Art Director (Skizze 03) | 1 Kleinstadt, 2–3 Marktflecken, 12–18 Dörfer. Das ist die Hierarchie um 1820, und sie erzeugt von selbst drei Streckentypen. Die zweite große Senke kommt als Kartenrand-Markt. |
| Tobias | Mit einer Kleinstadt fehlt die Fernstrecke zwischen zwei gleichwertigen Senken, und genau davon lebt das Genre. Die Gesamtnachfrage fällt auf ein Drittel, dann kippen Kredit ab Minute 12, 3 %/min Zins und das Bankrottband 15/17/18 %. Ich will 2 Kleinstädte und T-15 nicht anfassen. |
| Lena | Eine Einwohnerzahl am Schild, die nicht zu den Häusern passt, ist unehrlich. Basti hat ausdrücklich gefragt, wie viele Menschen in einem Haus wohnen. Lieber ehrliche Zahl und die Nachfrage über einen Multiplikator anpassen. |
| Stadt-/Level-Designer (05) | Umland-Modell: Sim-EW = Ort + Gemarkung. Die Dorfbänder in der Sim bleiben (400–900), die Häuser stimmen mit der Ort-Zahl. Ein Teil des Umlands steht als Weiler und Einzelhöfe sichtbar in der Landschaft. |
| Aylin | Bei 40 Dörfern hat die Übersicht 40 Schilder, das ist nicht lesbar. 15–21 Knoten gehen mit Hierarchie: Kleinstadt und Marktflecken immer, Dorf unter 3 km Kamera, Weiler nie. Das Schild zeigt, was man sieht, und der Tooltip erklärt das Einzugsgebiet. |
| Daniel | Ein Generator mit „bis zu 2 Kleinstädten“ muss bei 7 km Mindestabstand auf 12,8 km in ≥ 18 von 20 Seeds aufgehen. Sonst haben wir wieder Ausnahmen im Validator. |

**Entscheidung (PO):** Szenario **B+**: **2 Kleinstädte** an den Enden des Flusstals (min. 1, wenn das Gelände 7 km Abstand nicht trägt), 2–3 Marktflecken, 12–16 Dörfer, 6–12 Kulisse-Weiler ohne Schild. **Umland-Modell** gilt. **Schild = Ort-EW** (sichtbare Häuser), mit Trendpfeil und bis zu 3 Bedarf-Icons; Tooltip „Einzugsgebiet 650 (Nachfrage)“. **T-15 wird nicht neu kalibriert.** Tobias macht parallel zum Prototyp eine Stichprobe (3 Seeds × 3 Bot-Läufe); liegt die Bankrottquote außerhalb 15–18 % ±3, wird nur `demand_per_100` oder die Dorfzahl (+2) gedreht, nicht die Ortsgröße.
**Begründung:** Die zweite Kleinstadt bringt die Fernstrecke auf der Karte und macht den Kartenrand-Markt überflüssig. Das Umland-Modell trennt Bild und Ökonomie sauber: Die erste Kette (Mühle → Dorf mit 650–750 Sim-EW) rechnet wie in S7. Das Schild folgt Bastis Frage „Haus → Menschen → Anzahl“. TF3 zeigt dasselbe: Name, Einwohner, Trend, Bedarf (tf3_02, tf3_04).
**Folgen/Risiko:** Sim-EW gesamt ≈ 20.000 (12.000–29.500) statt 36.250, Ort-EW ≈ 12.000 (real 10–16k). Mittelspiel hat ~55 % der S7-Nachfrage. Risiko: Bot-Stichprobe fällt aus dem Band. Zweites Risiko: Spielende verstehen „Einzugsgebiet“ nicht (Aylin prüft im Rundgang).
**Status:** Annahme, Grundsatz bestätigt Basti mit F1.

## K2 1820 hat keinen Abnehmer für Stahl
| Rolle | Argument |
|---|---|
| Stadt-/Level-Designer (05) | Stahl steht nur im Warenkorb der Sim-Stufe „stadt“. 1820 gibt es keine Stadt, also hat die Montankette keinen Endkunden. |
| Art Director (03) | Kartenrand-Markt: eine Großstadt außerhalb der Karte, erreichbar über Chaussee oder Fluss. Das ist real und bringt die Fernstrecke. |
| Tobias | Ein Markt außerhalb der Karte ist eine neue Spielregel mit eigenem Preis- und Sättigungsmodell. Dann lieber Stahl in den Kleinstadt-Korb. |
| Felix | Ich habe nachgesehen: In `economy_slice.json` ist die Werkzeugfabrik `rolle_modus: abnehmer` mit Eingang Stahl. Sie ist die Senke der Montankette, Werkzeug wird gar nicht produziert. Der Stadt-Korb nennt die Kategorie „stahl“, Stahl hat aber die Kategorie „zwischenprodukt“. Die Stadt nimmt Stahl also heute schon nicht an. |
| Lena | Dann ist die Kette 1820 vollständig: Erz + Kohle → Hütte → Manufaktur. Werkzeug als Gut für die Kleinstadt ist ein S8-Thema. |

**Entscheidung:** Kein Kartenrand-Markt in v1. Die Montankette endet 1820 an der **Manufaktur** (Sim-Slot `werkzeugfabrik`, Senke). Kein Stahl im Kleinstadt-Korb. Felix/Tobias prüfen in S8, ob die Korb-Kategorie „stahl“ ein toter Eintrag ist (auch `gate_unlock_good_id: stahl`).
**Begründung:** Der Konflikt beruht auf einer falschen Annahme über die Sim. Mit K1 (zwei Kleinstädte) gibt es die Fernstrecke ohnehin.
**Folgen/Risiko:** Keine Ökonomie-Änderung. Die Manufaktur liegt am Rand eines Marktfleckens oder einer Kleinstadt (R5), nicht im Nirgendwo. Export/Werkzeug-Gut bleibt S8.
**Status:** entschieden.

## K3 Gleis-Steigung
| Rolle | Argument |
|---|---|
| Art Director (01) | Real 1–2,5 %. Hart 4 %, Abschlag ab 2 %. Alles darüber sieht nach Zahnradbahn aus und bricht E1. |
| Tobias | Bei 1.000 m Relief auf 12,8 km sperrt 4 % das Gebirge für die Bahn. Erz und Kohle liegen am Gebirgsfuß, die Montankette wäre bahnlos. |
| Felix | Heute misst der Validator 120 ‰ (`world_s7_meta`), das S7-Backlog nennt 12 %. Ein Tempoabschlag nach Steigung ist eine neue Sim-Regel, die steht im Charter als „nicht Teil“. |
| Daniel | Jede Senkung macht V-E2 („je Montangruppe eine Kette als Gleis“) knapper. Ich brauche eine Zahl, die ich auf 20 Seeds prüfe, nicht ein Gefühl. |
| Lena | Steigung soll eine Entscheidung sein: Umweg oder teurer Hang. Bei 12 % gibt es keine Entscheidung, bei 4 % keine Bahn. |

**Entscheidung:** Gleis **hart 60 ‰** (6 %, etwa reale Adhäsionsgrenze [~]); Fallback **80 ‰**, wenn V-E2 nicht in ≥ 18/20 Seeds aufgeht. Kosten über die bestehende Hang-Baukostenregel. Ein Tempoabschlag ab 20 ‰ ist S8-Kandidat (Tobias), nicht v1. Straße bleibt 200 ‰ hart; die generierte Start-Chaussee hält ≤ 50 ‰.
**Begründung:** 6 % lässt Bahnen über Hügelland und in Täler bis zum Gebirgsfuß, sperrt aber Gratlinien. Das erzwingt Trassenwahl (P5), ohne die Montankette abzuschneiden.
**Folgen/Risiko:** V-E2 wird knapper; Felix rechnet die 20 Seeds in Phase 4 mit. Spielende brauchen in der Bauvorschau die Steigung als Zahl (Aylin, S8).
**Status:** Annahme (gilt bis zum Seed-Lauf).

## K4 Fahrzeugtempo
| Rolle | Argument |
|---|---|
| Art Director (01) | Größen sind jetzt real, aber ein Fuhrwerk fährt 150 m/s, das sind 540 km/h. Das ist 100-fach gerafft und bricht E1 in der Zeitachse. |
| Tobias | Das Tempo ist T-15: Ertrag pro Minute, Fahrzeugzahl, Bankrottquote. Wer es halbiert, kalibriert das ganze Spiel neu. |
| Felix | Sim-Parität ist exakt, Bild und Sim zeigen dieselbe Position. Ein zoomabhängig gebremstes Bild bricht das. Möglich ist nur, das ganze Spiel beim Heranzoomen langsamer laufen zu lassen (Railway-Empire-Option). |
| Lena | Im Genre fahren Fahrzeuge zu schnell, das stört niemanden, solange die Pferde nicht galoppieren. Die Animation entscheidet, nicht die Zahl. |
| Aylin | TF3 zeigt 48 km/h im Fahrzeugpanel (tf3_06): Fahrzeuge fahren dort nahe Echtzeit, dafür läuft der Kalender schnell. Das ist der andere Genre-Weg, und Basti hat genau diese Bilder geschickt. |
| Daniel | Das ist eine Gefühlsfrage. Ich will sie im Rundgang mit A/B beantworten lassen, nicht am Tisch. |

**Entscheidung:** Sim-Tempo bleibt (0,6 bzw. 1,0 Felder/Tick). Die Prototyp-Szene bekommt einen **Darstellungsschalter** (A heute, B Spieltempo ×0,25 unter 400 m Kamera, C Echtzeit-Vorschau) nur für Bastis Rundgang. Pferde-Gangart wird gedeckelt (kein Galopp-Flackern).
**Begründung:** Grundsatzfrage zu Zeit und Spielgefühl, mit großen Folgen für die Ökonomie. Basti soll sie sehen, nicht lesen.
**Folgen/Risiko:** Option C hieße neue Ökonomie (S8+). Option B ist eine Einstellung ohne Kalibrierung.
**Status:** an Basti (F4), Prüfung im Rundgang (Karte A7).

## K5 Mindestabstände gleicher Typen (R7), Erz-Lage
| Rolle | Argument |
|---|---|
| Stadt-/Level-Designer (06) | R7 mit 160 Feldern (4 km) für alle Typen verhindert Mehrfachquellen. Abgestuft: Rohstoff 1,2 km, Veredelung 3 km, Produktion 4 km. Erz 0,75–3 km von der Hütte löst die Baukasten-Reviere auf. |
| Tobias | Erz im Fernband schiebt die Strecke über den Ertragsknick von 60 Feldern. Das lohnt sich und macht die Bahn sinnvoll. |
| Lena | Drei Wege statt zwei kurze sind für Anfänger zu schwer. Die HQ-Vorschau zeigt dann öfter „Wagnis“. |
| Art Director (03) | Hütte im Tal am Wasser, Lagerstätten nur an 1–2 Bergflanken. Die Ferne entsteht von selbst über die Lage, ohne Zahl. |
| Daniel | Achtung: AR3 verlangt Quellen aus ≥ 2 Richtungen. Das Kraftwerk hat nur Kohle als Eingang, und Kohle liegt an 1–2 Flanken. AR3 ist dort kaum erfüllbar. |

**Entscheidung:** R7 abgestuft (1,2 / 3 / 4 km). Erz 0,75–3 km zur Hütte, aber **mindestens ein Erzfleck ≤ 2 km** zu einer Hütte, damit die Kette mit dem Fuhrwerk spielbar ist. Kohle bleibt im Nahband 15–30 Felder. **AR3 gilt nur für Mühlen**; bei der Hütte genügt „Erz und Kohle aus verschiedenen Richtungen“, das Kraftwerk ist ausgenommen (siehe K13). Agrar bleibt die Einstiegskette (V-E7).
**Begründung:** Gegen Reviere (Daniel M1) braucht es die Lösung von Erz. Die 2-km-Garantie hält Lenas Einstieg.
**Folgen/Risiko:** Montan ist die zweite Kette mit Bahn-Anreiz. Generator-Erfüllbarkeit sinkt; Retry wie S7.
**Status:** entschieden.

## K6 Terrain
### K6a Vertexfarben oder Bodenkarte
| Rolle | Argument |
|---|---|
| Felix | Vertexfarben reichen, die Sim rechnet in Feldern. Ein weiterer Sampler kostet auf schwachen iGPUs im Compatibility-Renderer messbar. |
| Technical Artist (08) | Farmen legen zur Laufzeit Äcker an. Ein Pixel-Update ist billiger als ein Chunk-Neubau, und Ackerkanten bleiben scharf statt 25 m weich. Der Zugriff ersetzt den doppelten Maskenzugriff. |
| Sophie | 11 Klassen sind zu bunt. Railway Empire lebt von 3–4 Flächen. |
| Aylin | Jede Klasse besteht 3:1 gegen Saum oder Marker, das ist gemessen. In der Übersicht dominieren 4 Flächen. |

**Entscheidung:** **Bodenkarte** (512² RGBA8: Acker, Heide, Sumpf, Wald), Rest prozedural. Fallback Vertexfarben, wenn die iGPU-Messung im Prototyp mehr als 0,3 ms kostet. Neu aus K20: Wald-Wiesen-Mosaik (Waldflecken 100–800 m, Feldgehölze, Hecken) und Bergheide-Gürtel 750–1.000 m.

### K6b Reliefprofil ds_v2 (Hügel in der Fläche 13,8 %, Soll ≥ 10 %)
| Rolle | Argument |
|---|---|
| Daniel | 13,8 % ist knapp. Ein Seed weiter und der Validator wird rot. |
| Technical Artist (08) | Die Hügelquote misst das Falsche. Gemeint ist Abwechslung, also Reliefstufen-Anteile. Ebenen sind jetzt ebener und Hügel hügeliger. |
| Sophie | Die neuen Flanken wirken plastisch glatt (Bild `08_relief_vergleich_massiv.png`, rechts). Kenney verträgt mehr Kante. |
| Tobias | Hügelland macht Strecken teurer. Das ist gewollt, muss aber in die Stichprobe (K1). |

**Entscheidung:** Profil **ds_v2**. Validator-Regel V-L1 „Reliefstufen-Anteile innen“ ersetzt die Hügelquote ab der Prototyp-Abnahme; bis dahin bleibt ≥ 10 %. Kante kommt aus dem Shader (Fels/Schotter nach Neigung). Gain 0,46 nur, wenn Basti im Rundgang „zu glatt“ sagt.

### K6c Schneelinie 1.000 m oder 780 m
| Rolle | Argument |
|---|---|
| Tobias | 1.000 m nimmt dem Gebirge sein stärkstes Signal. |
| Technical Artist (08) | 780 m wirkt alpin, wir sind 1820 im Mittelgebirge. Bei 1.000 m liegt nur 0,2 % der Fläche im Schnee. |
| Sophie | Signal geht auch über Fels und Geröll. TF3 zeigt einen Biomverlauf Wiese → Heide/Geröll orange-braun → Fels → eine Schneekappe (tf3_01, tf3_04). |

**Entscheidung:** **1.000 m**. Das Signal liefern der Bergheide-/Geröllgürtel und die Schneekappe auf dem höchsten Gipfel (max. 1.121 m), wie in TF3.

### K6d Stadtplateaus mit kreisrunden Böschungsringen
| Rolle | Argument |
|---|---|
| Technical Artist (08) | Die Ringe sind in jedem Kartenbild sichtbar und wirken konstruiert (Basti Punkt 8). |
| Felix | Plateaus braucht der Stadtgenerator, sonst stehen Häuser schief am Hang. |
| Stadt-/Level-Designer | Mit Dorf-Radius 125–200 m statt 225–800 m werden Plateaus ohnehin klein. |

**Entscheidung:** Plateau nur für den Kern, Form folgt der Ortsform, Terrassen quer zum Gefälle, Radius ±20 % verrauscht, kein Kreisring. Häuser außerhalb des Kerns bekommen einen Sockel statt Plateau.
**Folgen/Risiko (K6 gesamt):** Generator-Laufzeit steigt (KD-Baum, 26–70 s, nur bei der Erzeugung). Bodenkarte +1 Sampler.
**Status:** entschieden.

## K7 Wasser
| Rolle | Argument |
|---|---|
| Sophie | Normal- und Flowmap sehen nah lebendiger aus. Die Sinuswellen wirken nah gekachelt. |
| Technical Artist (09) | Nahsicht unter 100 m zeigen wir kaum. Opak läuft ohne Sortierprobleme im Compatibility-Renderer, kostet +3 DC und 7k Dreiecke. `wellen_grad()` ist 1:1 gegen Normal-Map tauschbar. |
| Art Director (01) | Bach 4–6 m real plus Ufergehölz. Die Referenz sagt 8–12 m (×2), das bricht E1. |
| Aylin | Ein 5-m-Bach ist ab 1 km eine Haarlinie (Bild `ds_v2_wasser_bach.png`). Ohne Zeichenlinie ist er weg. |
| Daniel | Die Uferlinie zackt im 25-m-Raster (`ds_v2_wasser_mittel.png`, Teich). Das sieht Basti sofort. |
| Felix | Feiner unterteilen kostet ~10k Dreiecke im Flusskorridor. Eine flachere Uferböschung kostet nichts. |

**Entscheidung:** **Opaker prozeduraler Shader aus 09** für Fluss, Teich, Bach; Flowmap später als Tausch. **Bach 4–6 m** + Gehölzsaum 10–20 m je Seite + Zeichenlinie ab 1 km Kamera (E1: Lesbarkeit aus Zeichen). Uferböschung im Generator 22 → **40 m**; Teiche unter 3 Feldern auf eigenem 5-m-Mesh. Farbe aus K20: Variante B (teal, breiterer Flachwasserverlauf) als A/B im Rundgang, Kontrast 3:1 neu messen.
**Folgen/Risiko:** Wenn 40 m Böschung nicht reichen, 12,5-m-Unterteilung im Korridor (+10k Tris).
**Status:** entschieden.

## K8 Straße: geglättetes Band oder Kacheln
| Rolle | Argument |
|---|---|
| Art Director (01) | 6-m-Band als durchgehendes Spline-Mesh durch geglättete Feldmitten, keine Kacheln, keine Fugen. Das löst Bastis Punkt 1 (Fugen, Zickzack). |
| Felix | Die Sim bleibt Kante zwischen Feldmitten. Kreuzungen, Brücken und Bahnübergänge sind mit einem Band schwer: dort braucht es Knotenstücke. Und jede Änderung baut das Band neu. |
| Sophie | 8 Richtungen zwingen Ortsgassen auf 45°. Ein Haufendorf wirkt dann wieder konstruiert, nur schräg. |
| Stadt-/Level-Designer (05) | Ortsstraßen dürfen im Bild bis ±20° und ±8 m von der Kante abweichen, solange sie im Feldband bleiben. Häuser folgen der Bildkurve. |
| Daniel | Die Stadt-KI darf nur hinzufügen. Wenn sie Zellen löscht, laufen Fahrzeugpfade ins Leere. |

**Entscheidung:** Sim-Kante bleibt. Bild = **Spline-Band** je Kantenzug, Neubau nur des betroffenen Zugs; **Knotenstücke** je Kreuzungstyp; Brücke = Sim-Brückenfelder mit Band darüber. Ortsstraßen-Abweichung ±20°/±8 m. Spielernetz bekommt dieselbe Glättung (W-04b). Stadt-KI fügt nur hinzu, kreuzt kein Gleis, schließt an Spielerstraßen nur über Kreuzung an. TF3 bestätigt geschwungene, schmale Ortsstraßen (tf3_02).
**Folgen/Risiko:** Größter Technikposten in S8 (W-04b). Im Prototyp nur Dorfstraße + Chaussee + 1 Kreuzung.
**Status:** entschieden.

## K9 Weitere
| Thema | Positionen | Entscheidung | Status |
|---|---|---|---|
| a Dorfformen gemischt oder je Region | Sophie: gemischt nach Gelände ist glaubwürdig. Lena: eine Region mit Charakter (Haufendörfer im SW) macht Karten unterscheidbar. Daniel: Regionsregel darf die Geländeeignung nicht überstimmen. | Form nach Gelände (05/06), plus **Regionsgewicht** je Seed: eine dominante Form +30 %. | Annahme |
| b Kohle und Erz an verschiedenen Bergen | Tobias: verschiedene Berge verlängern die Kette, gut. Lena: Einstieg wird schwer. Felix: bei nur 1–2 Flanken je Seed ist „verschiedene Berge“ nicht immer möglich. | Getrennte Flecken ≥ 0,75 km, **gleiches Massiv erlaubt**; Erz-Garantie aus K5. | entschieden |
| c Deko-Dörfer in der Randlandschaft | Aylin: ohne Orte wirkt die Karte wie eine Insel. Felix: Randlandschaft hat keine Sim, nur Proxys. Daniel: Spielende dürfen sie nicht für Ziele halten. | Ja: **Kulisse-Weiler/-Dörfer als Proxy**, ohne Schild, ohne Klick, ~0,15 je km². | entschieden |
| d Unversorgte Orte: stagnieren oder wachsen | Lena: Basti sagt, Städte wachsen im Genre automatisch. Tobias: Wachstum ist die Belohnung für Versorgung. Aylin: Eine Karte, auf der alles Unversorgte schrumpft, wirkt früh tot. | Bis zur Antwort: S7-Verhalten (unter 30 % Versorgung −45 bp/Monat, Leerstand statt Abriss). Empfehlung an Basti: nie unter Startgröße schrumpfen. | an Basti, F2 |

## K10 Kenney-Raster gegen Skalen (gefunden in 10_import_faktoren)
| Rolle | Argument |
|---|---|
| Daniel | Die Kenney-Lok ist mit Bezug Höhe 6,7 m lang. Real sind es 7,62 m, also 0,88×. Das unterschreitet die Fahrzeug-Untergrenze 0,9×. Das Bürgerhaus hat 9 m Traufe statt 12 m, genau −25 %, der Rand der Toleranz. |
| Sophie | Die Lok in die Länge zu ziehen macht den Kessel oval, das sieht man. |
| Felix | Ein Längsfaktor in z bis ±15 % fällt bei einem Zylinder kaum auf; R3 erlaubt Querfaktoren bei Fahrzeugen schon. |
| Art Director | 3 Geschosse à 3 m sind 9 m. Mit Sockel 0,6 m und dem realen Band 10–14 m ist 9,5–12 m ehrlich. |

**Entscheidung:** Lok-**Längsfaktor z 1,13** → 7,6 m (1,0× real); R3 gilt für Fahrzeuge und Brücken als Quer- *oder* Längsfaktor bis ±35 %. Haus L Traufe **9,5–12 m**, First 12,5–15 m.
**Status:** entschieden.

## K11 Kraftwerk-Slot 1820 als Köhlerei (gefunden)
| Rolle | Argument |
|---|---|
| Lena | Eine Köhlerei verbraucht Holz und erzeugt Holzkohle. Im Spiel liefert die Kohlemine an den Slot. Das ist inhaltlich umgekehrt. |
| Sophie | Der Meiler ist billig und sieht epochal aus. |
| Tobias | Der Slot ist ein Kohle-Abnehmer ohne Ausgang. Jeder Kohle-Verbraucher 1820 passt: Kalkofen, Ziegelei, Saline, Brauerei. |
| Aylin | Der Name im Spiel muss zum Gut passen, sonst lernen Spielende eine falsche Kette. |

**Entscheidung:** Darstellung 1820 = **Kalkofen/Ziegelei** (Ofen 8–12 m, Kalkhalde, Ziegelstapel). Köhlerei bleibt Kandidat für eine Holz-Kette in S8.
**Status:** Annahme (Benennung Lena in S8).

## K12 Mühle am Wasser, aber der Generator hat nur einen Fluss (gefunden)
| Rolle | Argument |
|---|---|
| Daniel | 06 verlangt Mühle ≤ 200 m vom Wasser und Orte bevorzugt ≤ 300 m vom Bach. ds_v2 hat einen Fluss und sonst nichts. Dann stehen alle Mühlen und Dörfer am Fluss, das ist wieder ein Revier. |
| Technical Artist | Bäche sind im Band-Mesh und Shader schon vorbereitet (Demo 5 m). Im Generator fehlen sie. |
| Felix | Bäche blockieren die Sim nicht, Bachbrücke liegt im Feld. Das ist nur Generator und Bild. |
| Tobias | Ohne Bäche gibt es keine Mühlen in der Fläche, die Agrarkette wird linear. |

**Entscheidung:** Generator bekommt **4–8 Bäche** (Tiefenlinien, münden in den Fluss) und **1–2 Nebenflüsse** (15–25 m, 1 Brückenfeld). Aue-Band für Mühlen 0–1.000 m (08). Neue Validator-Regel V-L3.
**Status:** entschieden.

## K13 AR3 gegen knappe Kohle
Siehe K5 (Daniels Einwand). Entscheidung dort: AR3 nur für Mühlen. **entschieden.**

## K14 Sim-Footprint Industrie gegen reale Gebäude (gefunden)
| Rolle | Argument |
|---|---|
| Daniel | `main.gd` setzt Footprints 4×3 bis 4×4 Felder (100 m). Eine Mühle ist laut Skalen 12 m. Entweder leere Fläche oder ein riesiges Gebäude. |
| Tobias | Footprint ist Bau-, Lade- und Klickfläche. Eine Änderung verschiebt Abstände und Ketten. |
| Sophie | Die Fläche füllt sich mit echtem Werksgelände: Teich, Graben, Halde, Holzplatz, Acker. So zeigt TF3 seine Höfe (tf3_03). |

**Entscheidung:** Sim-Footprint bleibt in v1; Bild füllt mit Werksgelände nach Skalen D. Footprint je Typ erst mit W-05.
**Status:** entschieden.

## K15 Gebirgsanteil (gefunden)
| Rolle | Argument |
|---|---|
| Daniel | 08 setzt „Gebirge ≤ 15 % innen“ als Ziel, misst aber 31,6 % für ds_v2. Das Regelwerk widerspricht seinem eigenen Generator. |
| Technical Artist | Massiv-1-Radius 3,3–4,0 → 2,8–3,4 km, nicht gerechnet. |
| Sophie | Das Massiv ist auch in ds_v2 ein runder Fleck (`08_relief_vergleich_karte.png`). Kleiner allein macht es nicht natürlicher. |
| Lena | Gebirge ist Kostentreiber und Rohstoffort. Zu wenig, und Montan hat keinen Ort. |

**Entscheidung:** Massiv-1-Radius **2,8–3,4 km**, Massivrand mit Rauschen ±25 % (kein Kreis). Gate v1: Gebirge innen **≤ 20 %**, Zielwert 15 %.
**Status:** Annahme (Messung im Generator-Lauf Phase 4, Bild im Rundgang).

## K16 Zahlenwidersprüche zwischen den Skizzen
| Wert | Skizzen | v1 |
|---|---|---|
| EW-Zuwachs Handwerker → Bürgerhaus | 05: +5, 07: +7 | **+7** (Mittel 7 → 14) |
| EW-Zuwachs Bürger → Mietshaus | 05: +18, 07: +16 | **+16** (14 → 30) |
| EW je Wohnhaus Marktflecken | 05: 8,5, 07: 9 | **9** (Ganzzahl) |
| Marktflecken-EW | 01/ref: 800–1.500, 03: 800–1.300 | **800–1.300** (1820) |
| Kleinstadt-EW | 01: 2.000–5.000, 03: 2.000–4.000 | **2.000–4.000** (1820) |
| Dorfabstand | 03: 1,5 km genügt; 06: max(1,6 km; 5 × Ø) | **06** (V9 ist prüfbar) |
| Fahrzeuge/Bäume Überhöhung | Audit ×1,5/×1,2 | **≤ 1,2 / 1,0** (E1) |
| Bach | ref 8–12 m | **4–6 m** + Saum (E1) |
| Kraftwerk 1820 | 01/06 Köhlerei | **Kalkofen/Ziegelei** (K11) |
**Status:** entschieden.

## K17 Wald bei realer Baumgröße
| Rolle | Argument |
|---|---|
| Felix | S7-Bäume sind 34 m hoch (Faktor 0,8). Real 18 m heißt 3–4× so viele Bäume für denselben Wald, das reißt das Perf-Gate. |
| Sophie | Wald aus der Ferne als Fläche mit Kronentupfen wirkt flach. |
| Technical Artist | Fern zeigt die Bodenkarte den Wald, Tupfen im Shader kosten 0 Dreiecke. Bäume nur bis 2,5 km, Übersicht ≤ 120k Baum-Dreiecke. |
| Aylin | TF3 zeigt Wald fern als dichte Kronen-Textur, nicht als Einzelbäume (tf3_01). Für die Lesbarkeit reicht das. |

**Entscheidung:** Bäume 1,0; Wald fern über Boden + Tupfen; Deckel 120k Tris Übersicht, ≤ 6.000 Bäume nah.
**Status:** entschieden.

## K18 Marktflecken-Nachfrageknick (gefunden in 05 §6)
Tobias: Der Dorf-Multiplikator ×2 fällt bei 1.000 Sim-EW weg, ein Marktflecken (1.550) fragt kaum mehr nach als ein großes Dorf (650). Lena: Das bestraft Wachstum über die Schwelle. **Entscheidung:** v1 unverändert, Tobias prüft in der Stichprobe K1 und schlägt in S8 einen gleitenden Übergang vor. **entschieden** (vertagt).

## K19 Startjahr als Schwierigkeitshebel
Tobias (04): „Leicht“ = Start 1840. Aylin: Das ist eine andere Epoche, keine leichtere. Lena: Welt-Hebel höchstens knappe Rohstoffe und Relief. **Entscheidung:** Startjahr und Schwierigkeit sind **zwei getrennte Optionen**; Siedlungsdichte ist kein Hebel. Ob die Schwierigkeit die Welt überhaupt verändern darf: F6. **entschieden.**

## K20 Abgleich Transport Fever 3 (Bastis Referenzen tf3_01–09)
Basti: „kein macht es genau so“, nur wie das Genre es heute löst. Kennung [E] = Bildeindruck.

| Beobachtung | Bild | Bezug zu uns | Wertung |
|---|---|---|---|
| Orte sind kleine Cluster in großer Landschaft, Schilder mit Name, EW, Trend und Bedarf darüber | 01, 02, 04 | P2, P4, K1 Label | **bestätigt**; Bedarf-Icons ins Schild übernommen |
| Nesbyen 296 EW ≈ 40–60 Gebäude, Folldal 538 EW ≈ 100+ (inkl. Mietshäuser) | 02, 04 | Dorf 150–350 Ort-EW = 25–56 Häuser | **bestätigt** (TF ≈ 5 EW/Gebäude, wir 7–11, weil 1820 Höfe statt Wohnungen) |
| Fahrzeuge real groß: Kesselwagen 9,6 m, Lok + 2 Wagen 26 m, Bus kleiner als Fassade, Menschen winzig; Gleis schmal mit Schotterbett | 05, 06, 07 | E1, Skalen C (≤ 1,2×) | **bestätigt**: das Genre überzeichnet heute nicht |
| Bäume 20 m+, Wald reicht bis an die Häuser | 02, 08 | Bäume 1,0 (K17); bei uns 1820 Acker-/Gartengürtel | Baumhöhe **bestätigt**; Wald an Häusern **widerspricht** bewusst (Agrarlandschaft 1820, Skandinavien in TF3) |
| Wald-Wiesen-Mosaik statt großer Blöcke, Biomverlauf bis zum Gipfel | 01, 04, 09 | 08 Boden (Wald 30 % in Blöcken) | **übernommen**: Mosaik-Regel, Bergheide-Gürtel (K6a/c) |
| Viele Seen und Buchten | 01, 04, 09 | bei uns 1 Fluss + Teiche | **widerspricht**; Grundsatz an Basti (F5), bis dahin 0–2 kleine Seen |
| Wasser teal mit Tiefenverlauf und hellem Ufersaum, ruhig, Kielwasser nur an Schiffen | 01, 03 | 09 opaker Shader | **bestätigt**; Farbe Variante B als A/B (K7) |
| Straßen geschwungen, folgen dem Gelände, Ortsstraßen schmal | 01, 02, 04 | K8 Spline-Band | **bestätigt** |
| Industrie kompakter umzäunter Hof, neutral, nur Plakette farbig | 03, 09 | Einfärberegel 10, Basti Punkt 5 | **bestätigt** |
| Fahrzeugkauf mit Filter „Year of Availability“ | 07 | E4 Startjahr als Daten | **bestätigt** |
| Fahrzeug fährt 48 km/h nahe Echtzeit, Kalender gerafft | 06 | K4, bei uns Fahrzeuge gerafft | **widerspricht**, Teil von F4 |
| HQ = Villa auf Lichtung, „nächster Ort wird Hauptstadt“, Town Growth +5 % | 08 | HQ frei platzieren (D22), Wachstum 05 | **Annahme** (siehe unten) |
| Bürger mit Wohnen/Einkaufen/Arbeit, Lärm/Verschmutzung | 05, 06 | Bastis Arbeitskräfte/Energie-Idee | nur **vermerkt** (S8, „Spätere Kopplungen“) |
| Lieferketten als Pfeilbänder über der Karte, Mehrfachquellen je Fabrik, Aufträge mit Belohnung/Strafe | 09 | P2 Zeichen; 06 Mehrfachquellen | Mehrfachquellen **bestätigt**; Pfeilbänder und Aufträge nur **vermerkt** (UI/S8) |

**HQ-Wachstumsbonus (Prüfung gegen 05):**
| Rolle | Argument |
|---|---|
| Lena | Passt: Das HQ macht einen Ort zu „meinem“ Ort, und die Stadt-KI hat schon Richtungsgewichte. |
| Tobias | Nur, wenn der Bonus auf eine positive Rate wirkt und im bestehenden Zuschlag-Deckel (250 ‰) bleibt. Sonst wächst der HQ-Ort ohne Versorgung, und das unterläuft F2. |
| Felix | Technisch ist es ein Faktor auf die Rate plus ein Gewicht in der Stadt-KI, keine neue Struktur. |
| Daniel | Testbar in der Bot-Stichprobe, wenn der Faktor im JSON steht. |

**Entscheidung K20:** Abgleich wie Tabelle. HQ-Bonus als **Annahme, keine Pflicht**: Rate des nächsten Orts ×1,05, nur bei positiver Rate, innerhalb `zuschlag_max_promille`; Stadt-KI-Richtungsgewicht zum HQ ×1,5. HQ 1820 = Kontor/Handelshaus mit Hofmauer, zählt nicht zur Ort-EW. Abnahme Tobias in S8.
**Status:** Annahme; Seen an Basti (F5).

## Folgeaufgaben aus dem Protokoll
| Wer | Was | Wann |
|---|---|---|
| Tobias | Bot-Stichprobe Umland-Modell (K1), Marktflecken-Knick (K18), HQ-Bonus (K20) | parallel Phase 4 |
| Felix | Seed-Lauf Gleis 60 ‰ (K3), Korb-Kategorie „stahl“ prüfen (K2), iGPU-Messung Bodenkarte (K6a) | Phase 4 |
| Technical Artist | Bäche/Nebenflüsse (K12), Massiv −15 % (K15), Uferböschung 40 m (K7), Plateaus (K6d) | Phase 4 |
| Lena | Benennung Kalkofen/Ziegelei (K11), Holz-Kette S8 | S8 |
| Aylin | Schild mit Bedarf-Icons, Einzugsgebiet-Tooltip, Kontrast Wasser B | Phase 4 |
