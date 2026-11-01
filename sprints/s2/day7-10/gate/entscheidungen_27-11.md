# Entscheidungen Jonas, 27.11.2026
**Jonas Weber** (PO) entscheidet die offenen Punkte aus `daily_tag6.md`. Moderation: Katrin.

**1. Ketten-Scope Vertical Slice: 3.**
Sophies Rechnung: 3 Ketten passen in die Kapazität, 5 nur ohne Puffer. Das Gate prüft ohnehin nur drei Fälle; 5 Ketten sind eine Option nach dem Go, nicht vorher.

**2. Kenney als Spike-Platzhalter: ja, mit Grenze.**
Bäume, Felsen, Anbauten und Schiff dürfen als Platzhalter dienen, jeweils mit dem Skalierungsfaktor je Kit (3,4 bis 10) in der Asset-Liste. Fahrzeuge nicht (7 bis 8-fach über Budget); F-05 bleibt bei Quadern mit rund 300 Tris. Finale Assets entstehen erst nach dem Go.

**3. Wende-Deadlock: bekannte Ursache, ja.**
Er läuft unter dem vorhandenen Code `DEADLOCK`, kein neuer Enum-Wert (D9). Er wird als siebtes Szenario zum ersten Prüffall in M1, nicht ins Gate-Scoring. Er steht in der Liste „nicht geprüft“ neben Weiche ohne Signal und Pfadsignalen.

**4. Kanonischer Ort: Felix' Regel gilt.**
Mitte der umkämpften Abschnitte, `ursache.pos == kette[-1].pos`. Das ist implementiert und von Daniel mit 15/15 Zeilenklicks geprüft. Lenas Tabelle mit Platzhalternummern zieht nach; das Netz vergibt die Nummern.

**5. Sim-Kern auf Basis der Zielrechner-Messung.**
- **SoA-Umbau: ja.** Der Spike-Objektkern ist auch auf dem Ryzen 7 5800X3D 5 bis 6-fach über 4 ms (5k: 10,9 ms, 10k: 22 ms). Der SoA-Kern in GDScript liegt bei 1,9 ms (10k). „Sim-Kern bleibt GDScript“ lautet daher **ja**, unter Vorbehalt Release-Export und Deadlock-Prüfung. GDExtension bleibt Skelett.
- **Deadlock-Prüfung ereignisgesteuert: ja.** Ein Vollscan je Tick kostet im Spike rund 4,4 ms (Sandbox, am Zielrechner nicht gemessen) und frisst das Budget. Die Prüfung läuft, wenn ein Fahrzeug über eine Schwelle wartet.
- **8-fache Geschwindigkeit:** SoA 10k liegt bei etwa 15 ms pro Frame und reißt das 8-ms-Budget. Das wird berichtet (D7); Felix legt bis Sprint-3-Planning einen Vorschlag zur Tick-Entkopplung vor.
