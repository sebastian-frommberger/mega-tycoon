# Bastis Rückmeldung zum Prototyp „Welt“ (Phase 5, 03.11.2026, 23:11)

Erste Rückmeldung aus dem Rundgang, vom Nutzer aus dem Chat übernommen. Noch nicht entlang der Aufgabenkarten ausgefüllt (keine Noten, keine Screenshots).

## Wortlaut (Auszug, gekürzt auf die Aussagen)
- Sieht gut aus; Bodentexturen teilweise „echt krude“.
- Fahrzeuge bewegen sich bei 1× viel zu schnell.
- Placement der Gebäude an manchen Stellen ziemlich „off“.
- Proportionen „ziemlich gelungen“.
- Fluss hat jetzt eine Größe, mit der man arbeiten kann; Inlandsflüsse angemessen, für Flöße vielleicht etwas schmal.
- See wirkt unstimmig: zu klein für Schiffsverkehr (z. B. Personenschiff zwischen zwei Seeenden) oder Handel.
- Städte „viel, viel besser“.
- Baumallee wirkt arg konstruiert.
- Keine Berge wahrgenommen; auch Senken, Hügel und leichte Bodenunterschiede nicht.

## Einordnung gegen den Bestand (Stand Repo f75987e)
| Aussage | Befund im Repo | Status |
|---|---|---|
| Fahrzeuge zu schnell | `phase4/proto_sim_anbindung.md` Z. 33: „15 m/Tick = 150 m/s bei 1×, eine 1-km-Fahrt dauert ≈ 7 s. Das ist so entschieden (E9)“; 0,6 F/Tick, 1 Feld = 25 m, Tick 10 Hz. Das sind 540 km/h für ein Fuhrwerk. | **Bestätigt, Kernproblem.** Hängt an der Zeitskala (12 min/Jahr, Lena-Pilot: Zwei Uhren). Nicht per Easing lösbar. |
| Gelände ohne Höhen | Höhendaten `slice/world/data/proto/proto_hoehe.r16` × `SKALA` 0,05: Spanne 33,6 bis 153,8 m, Mittel 68 m. Die Daten haben Relief. | **Hypothese, nicht geprüft:** Darstellung (Schattierung, Kamera-Neigung, Textur) oder Orte eingeebnet. Karte A9 kündigte „Hügelland“ an. |
| See zu klein | Aufgabenkarte: Steg, Fischerhütte, Ruderboot; Charter E10 „Gewässer mit Nutzung“, K32 „Seenreich erst mit Fähre/Schiff“. Binsensee ist als Fischersee gedacht. | **Zielkonflikt**: Basti will einen Handels-/Personensee. Entscheidung nötig (siehe unten). |
| Fluss/Flöße | Fluss 170 m Ansicht (`integration_w2.md` Z. 66), Floß 7 Stämme à 8 m. | Fluss ok; Floßbreite bei Engstellen prüfen (nicht geprüft). |
| Textur, Allee, Placement | Keine Messung vorhanden; nur Platzhalter-Hinweise in den Aufgabenkarten. | Offen, braucht Screenshot-Stellen von Basti. |

## Ticket-Vorschläge (nicht priorisiert, Basti entscheidet)
1. **T-V1 Sim-Tempo vs. Bildtempo** (hoch): Entscheidung Zwei Uhren / Standardtempo (Lena-Pilot: 3 min/Jahr, Wanduhr-Stufen 1×/2×/4×). Ohne sie bleibt jedes Fahrzeug unglaubwürdig, egal wie das Easing aussieht.
2. **T-G1 Relief sichtbar machen** (hoch): Erst messen, ob Daten oder Darstellung schuld sind (Höhenschummerung, Kamera, Schatten); dann Amplitude/Verteilung. Berge sind laut Karte A9 nur als Bild vorgesehen.
3. **T-W1 Seegröße** (mittel): Entscheidung, ob ein Schifffahrts-See (Länge > 1 km, V-W2 Engstelle ≤ 200 m) zum Slice gehört oder ob der Binsensee Fischersee bleibt; K32 verlangt für Seenreich Fähre/Schiff.
4. **T-T1 Bodentextur** (mittel): Stellen mit Screenshots von Basti sammeln; Sophie/Tech Art.
5. **T-S1 Gebäude-Placement** (mittel): Stellen mit Screenshots von Basti; Stadtdesign.
6. **T-S2 Baumallee** (gering): weniger regelmäßig (Abstände, Arten, Ausfälle); Stadtdesign/Art.
7. **T-W2 Floßbreite** (gering): Fluss 170 m ist auf Ansicht bezogen; Flussbreite an Engstellen gegen Floßbreite prüfen.

## Fehlt noch
Karte-für-Karte-Tabelle, Antworten auf die fünf Schlussfragen, Screenshots, Freigabe ja/nein.
