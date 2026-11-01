# Daily Tag 6 (23.11.) – moderiert von Katrin (zusammengefasst)

Stand je Ticket:
- F-04 Felix: D9 umgesetzt (kanonischer Ort, Zusatzfelder), Tests Exit 0; float32-Überlauf ab 46 m Kante gefunden und behoben. NEU B8 (Daniel): get_wait_chain() liefert {} wenn ein Glied auf einen im selben Tick freigegebenen Block wartet (80/6.000 Ticks) – Blocker für F-06/L-06.
- F-05 Felix/Daniel: Sandbox reproduziert, Spike 10k = 67–72 ms/Tick (Rot), SoA 10k = 2,2 ms (p95 ~5 ms). Zählt nicht für G2. NEU: Zielrechner verfügbar – Bastis PC (Godot 4.7.2, GPU) über Godot-MCP; erster Lauf Prototyp v3: 120 FPS (VSync), 8,4 ms CPU/Frame, 180 Draw Calls.
- F-06 Felix: nicht gebaut, Schätzung 1,35 T, Build realistisch 24.11. 12 Uhr statt 10 Uhr; 2D-Testszene.
- D-04 Daniel: 6/6 Szenarien, 0 Fehlalarme (Mini-Modell). Offen: Wende-Deadlock als bekannte Ursache?
- A-05/A-06 Aylin: Datenvertrag v1, Textvorlagen D11, Testskript final, F-06-Panel-Spezifikation, A-06 geliefert. Nicht gegengezeichnet.
- L-06 Lena: Fehler final, Variante A (echter Build) statt Plan B. Echte Tester: keine (Umgebung). L-05: Material fertig, Pilot ok, 0/3 echte Runden.
- T-05/T-04 Tobias: final; Kreditrahmen 2.000 $ ab Minute 0, 1 %/Spielminute; F-09 Schemas Exit 0, Felix-Abzeichnung offen; Erzberg-Tarif in L-05 korrigieren.
- S-03/S-05/S-06a Sophie: Blend als Morphing, Kartenstufe = Scroll-Ansicht (512² passt erst ab 6.100 m ganz ins Bild); Palette final (Ghost Weiß mit dunklem Saum); Asset-Liste 51 Zeilen (Sophie 48 PT, Artist 67,5 PT; 3 Ketten passen, 5 nur ohne Puffer). Kenney gemessen: Natur/Industrie-Anbauten tauglich, Fahrzeuge 7–8x über Budget, Maßstab der Kits uneinheitlich.

Entscheidungen offen für Jonas (bis Gate): Ketten-Scope 3 oder 5; Kenney als Spike-Platzhalter (Sophies Vorschlag); Wende-Deadlock; Kanonischer Ort (Mitte der umkämpften Abschnitte vs. Lenas Tabelle).
Neu: Zielversion Godot 4.7.2 (vom Auftraggeber). Agents: Sonnet bzw. Opus für Code, synthetische Personas Haiku; Fable nur nach Freigabe.
