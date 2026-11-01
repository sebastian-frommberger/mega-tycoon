# Refinement S2 – Felix

## Meine Tickets

27 SP auf acht Tage, das geht nicht.

**F-03 + F-04 zusammen: Netz-, Signal- und Diagnose-Spike** (Spike, 4 T, darin A-05)
Leitfrage: Kann die Sim jeden Stillstand bis zur Wurzelursache zurückverfolgen, mit Ort?
- Graph mit eigenem A* steht. Repath-Welle und verteiltes Caching kommen nach S3.
- Ein Deadlock wird in höchstens 10 Ticks erkannt. `get_wait_chain()` liefert eine Kette mit Koordinaten.
- 3 automatisierte Szenarien sind grün: Gegenverkehr eingleisig, Deadlock-Kreis, Warten auf Ladung.
- Spike-Build an Daniel am 19.11.
Abh.: Aylin, Felder bis 17.11.

**F-06 Testbuild Diagnose-Playtest** (Story, 1 T)
„Als Tester will ich ein kaputtes Netz untersuchen, damit wir die Auffindbarkeit messen.“
- Gegeben ist die Testszene. Wenn ich ein stehendes Fahrzeug anklicke, zeigt das Overlay die Kette als Text.
- Es sind genau 3 Fehler eingebaut. Jede Session wird als Replay gespeichert.
- Fertig am 24.11.
Abh.: F-04.

**F-05 Benchmark** (Spike, 1,5 T)
Leitfrage: Bleibt der Sim-Kern bei GDScript?
- Headless-Messung mit 1k, 5k und 10k Fahrzeugen auf Zielhardware, Median und p95 gegen 4 ms.
- Schriftliche Entscheidung, die Zahlen gehen auf die Gate-Folie.
- CI-Zeitreihe und MultiMesh-LOD kommen nach S3.
Abh.: Zielrechner am 16.11.

**F-07 Bau-Spike** (Spike, 1 T, Wegwerfcode)
Leitfrage: Fühlt sich Ziehen im 45°-Raster mit Snap gut an?
- Ziehen, Snap und Ghost gültig/ungültig funktionieren. Kein Undo, kein Abriss, keine Steigung.
- Jonas hat es angespielt, das Urteil ist dokumentiert.
F-07 fliegt als Erstes raus, wenn F-04 rutscht.

**F-08 Terrain** schiebe ich nach S3. Für Jonas' Kartengröße reichen Benchmark-Zahl und Float-Check.

**F-09 JSON** (0,5 T): Tobias schreibt das Schema. Ich mache Review und hänge den Validator in die CI.

## Einwände

1. **D-04: Spike-Build am 16.11. ist der erste Sprinttag.** Das klappt nicht, frühestens geht es am 19.11. Daniel testet nur, was ich nicht automatisiere; Repath-Welle streichen.

2. **L-06, K-06 und Daniels Playtest sind dreimal derselbe Test.** Lena will 5 Fehler einbauen. „Stadt übersättigt“ und „Lizenz abgelaufen“ brauchen aber Ökonomie und Lizenzen, und die existieren nicht. Mein Vorschlag:
   - Ein Ticket mit Lena als Owner und 3 Netzfehlern.
   - Build am 24.11., nicht am 23.11.
   - Akzeptanzkriterium: „4 von 6 finden die Ursache in < 3 min.“

3. **T-07 hängt nicht an mir.** Für die SimWorld-Schnittstelle habe ich keinen Tag übrig. Tobias, bau dein Skript standalone gegen die Tabelle. Die Integration kommt mit der Daten-Pipeline in M1. Das Kriterium „< 5 % Abweichung zur Tabelle“ prüft die Tabelle gegen sich selbst. Vorschlag: S3.

4. **S-03 braucht meine MultiMesh-Szene nicht.** Die läuft headless. 200 Quader im `MultiMeshInstance3D` baut Sophie in einer Stunde, ich gebe 30 Minuten Pairing. S-06 gehört aufs Kanban-Board, nicht ins Commitment.

5. **L-04 Skilltree mit „von Felix als importierbar bestätigt“:** Es gibt noch keinen Importer. Nicht testbar, also nach S3.

6. **A-06 hat 2 T für einen Spike von 1 T.** Das reicht mit 0,5 T. A-05 machen wir am ersten Tag von F-04 zusammen.

7. **J-05 will spielbare Spikes bis 23.11.** Der Bau-Spike kommt am 25.11., das Review ist am 26.11. K-07 VS-Schätzung: Dafür habe ich null Tage. Ich mache eine Planning-Poker-Session von 2 h, mehr nicht.

## Meine Kapazität und Forderung

F-03/04: 4 T, F-05: 1,5 T, F-06: 1 T, F-07: 1 T, F-09: 0,5 T. Macht 8.

Gate-Folie steckt in F-05. Fragen und Pairing laufen in den restlichen 2 Tagen. Puffer gibt es keinen.

Was ich fordere:
- **PO:** Die Reihenfolge F-04 > F-06 > F-05 > F-07 ist verbindlich. Im Sprintziel heißt es „Bau-Spike angespielt“, nicht „liegt vor“.
- **Team:** Fragen an mich gibt es täglich von 14 bis 15 Uhr, sonst bin ich nicht erreichbar.
- **Katrin:** Zielhardware am 16.11. Interviews für die Programmierstellen bis 20.11. Ohne Januar-Einstellung ist R1 tot.
- **Sophie:** Platzhaltermeshes bis 18.11., sonst nehme ich Würfel.
