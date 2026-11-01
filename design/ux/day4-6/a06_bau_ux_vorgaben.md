# A-06 Bau-UX-Vorgaben für den Bau-Spike (45°-Raster)

Autorin: Aylin Kaya · Stand 23.11.2026 · **F-07 ist gestrichen (D6).** Dieses Dokument ist Eingang für das M1-Ticket "Bau-Spike" (erstes M1-Ticket, Auflage G8) und geht heute als Info an Felix. Umfang nach Refinement: Grund-Strings im Klartext und Ghost-Regel. Magnet-Radius und Erreichbarkeits-Label kommen erst in der Bau-Spezifikation M1.

## 1. Ghost-Regel (D10)

| Zustand | Darstellung | Zusatz |
|---|---|---|
| **baubar** | Ghost **weiß** `#FFFFFF` (`ghost_baubar_weiss`, Sophie `palette_v1_final.csv`), Füllung Alpha 0,35, Kontur 2 px weiß plus 1,5 px dunkler Saum `#14161A` darunter (Sophie) | Kostenlabel weiß neben dem Cursor: "1.240 $" |
| **nicht baubar** | Ghost rot `#C8372D` (`ghost_nicht_baubar_rot`) mit diagonaler Schraffur 45°, gleiche Kontur und Saum | Grund-String am Cursor (Abschnitt 2), Kostenlabel ausgegraut |
| **Hinweis** (baubar, aber teurer oder außerhalb Einfluss) | Ghost bleibt **weiß**, Hinweis-Symbol blau (`#3D8FE0`, S-05 "Hinweis") am Cursor | Kostenlabel mit Zuschlag: "1.420 $ (+180 $ außerhalb Einfluss)" |

Regeln:
1. **Weiß heißt baubar, immer.** Blau ist nie ein Ghost-Zustand, nur ein Hinweis (D10). Rot heißt nie "teuer", nur "nicht baubar".
2. Gültigkeit ist auch ohne Farbe lesbar: Schraffur = nicht baubar, glatt = baubar (Daniel, Farbsehschwäche).
3. Gültigkeit und Kosten sind getrennte Kanäle: Form/Farbe des Ghosts sagt baubar ja/nein, das Label sagt den Preis. Zu wenig Geld färbt das **Label** orange (`#E08A2E`), nicht den Ghost; bauen geht dann trotzdem nicht (Grund G8).
4. Dunkler Saum ist Pflicht. Daniels Farbcheck (`day4-6/daniel/ghost_check_ausgabe.txt`, CIEDE2000, Grenze 10): Weiß `#FFFFFF` gegen Stadtfläche ΔE 17,4 (ok, auch in allen Simulationsmodi ≥ 14,1), gegen Gras, Wald, Feld, Wasser, Fels, Straße ≥ 19,7 (ok); **Kollision** gegen Konsum-Weiß `#F2F2F2` (2,6), `ok_ring` (4,9) und helle Outline (3,0). Die Stadtfläche braucht nach D10 also keinen Zusatz, der Saum ist wegen Konsum-Gut-Markern und Ok-Ringen trotzdem nötig; Sophie hat ihn in die Palette aufgenommen. Konsum-Marker dürfen während des Bauens nicht unter dem Ghost liegen (Overlay-Regel M1).
5. Der Grund-String steht 8 px rechts unter dem Cursor, 14 px, weiß auf `#2B2B2B` mit 80 % Deckung, max. 2 Zeilen, verschwindet mit dem Ghost.
6. Bei mehreren Gründen zeigt der Ghost nur den ersten nach Priorität der Tabelle (oben zuerst).

## 2. Grund-Strings im Klartext (kein `ERR_*` im Bild)

Spike-Umfang: Gleis per Ziehen im 45°-Raster, Snap an Knoten, Gültigkeit Steigung und Kollision (Felix' Plan). Platzhalter in `{}` füllt das Tool.

| Nr | Code (intern, nur Log) | String am Cursor | Prüfung |
|---|---|---|---|
| G1 | `STEIGUNG` | `Zu steil: {ist} % (max. {max} %)` | Steigung je Kante gegen Grenzwert, Schiene 4 % (Annahme aus Felix' Konzept "3–4 %", Felix setzt den Wert) |
| G2 | `KOLLISION_GEBAEUDE` | `Hier steht {name}` | Ghost schneidet Gebäude-Footprint |
| G3 | `KOLLISION_GLEIS` | `Kreuzt bestehendes Gleis ohne Weiche` | Schnitt mit Kante ohne Knoten; Spike hat keine Kreuzungen |
| G4 | `WASSER` | `Über Wasser braucht eine Brücke` | Kante über Wasserfeld, Brücke nicht im Spike |
| G5 | `KURVE_ZU_ENG` | `Kurve zu eng für Züge` | Richtungswechsel > 45° zwischen zwei Segmenten |
| G6 | `ZU_KURZ` | `Zu kurz: mindestens {min} m` | Segment unter Mindestlänge (Felix setzt den Wert) |
| G7 | `KARTENRAND` | `Außerhalb der Karte` | Rasterzelle außerhalb 512² (D5) |
| G8 | `GELD` | `Zu teuer: {preis} $, Kasse {kasse} $` | Preis > Konto; zusätzlich Label orange (Regel 3) |
| G9 | `KEIN_ANSCHLUSS` | `Endet im Nichts: an Gleis oder Bahnhof anschließen` | nur als Hinweis (blau), **nicht** blockierend; Spieler darf frei beginnen |
| G10 | `AUSSERHALB_EINFLUSS` | `Außerhalb deines Einflusses: +{zuschlag} $` | Hinweis (blau), nicht blockierend (Konzept: Kostenzone, kein Verbot) |

Schreibregeln: Grund zuerst, dann die Zahl, Einheit immer dabei, kein Fachwort ("Steigung" ja, "Gradient" nein), kein Code, kein Ausrufezeichen, höchstens 45 Zeichen je Zeile. Mit Beispielwerten gezählt (Skript): längste G9 mit 50 Zeichen, sie bricht auf zwei Zeilen um; alle anderen unter 40.

## 3. Was der Spike nicht braucht

Undo, Abriss, Kurvenglättung, Steigungsfarben, Brückenvorschlag, Live-Erreichbarkeit, Magnet-Radius-Darstellung. Diese Punkte stehen in `plan/aylin.md` "Bau-UX-Spezifikation final" (M1).

## 4. Offen

| An | Punkt |
|---|---|
| Felix | Grenzwerte G1, G6; welche der Gründe G1–G7 der Spike wirklich prüft (Rest fällt im Spike weg, Strings bleiben für M1) |
| Daniel | ΔE liegt vor (siehe Regel 4). Offen: Rot-Schraffur gegen `kritisch_rot` der Statusmarker ist dieselbe Farbe; Unterscheidung nur über Form (Schraffur gegen Achteck) |
| Sophie | Werte aus `palette_v1_final.csv` (20.11.) übernommen: `ghost_baubar_weiss #FFFFFF`, `ghost_nicht_baubar_rot #C8372D`, `hinweis_blau #3D8FE0`. Nur bestätigen, dass die Schraffur bei Rot als Form-Merkmal bleibt |
