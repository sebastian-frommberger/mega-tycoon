# Projektübersicht „Mega Tycoon“ (Producer: Katrin Vogel, Stand 31.10.2026)

## Meilensteine und Zeitplan

| Meilenstein | Zeitraum | Ziel | Gate-Kriterium (messbar) |
|---|---|---|---|
| **M0 Pre-Production & Spikes** | 02.11.–27.11.2026 (4 Wo.) | Offene Konzeptfragen entschieden, technische und gestalterische Kernrisiken per Spike geprüft | Entscheidungslog mit 7/7 Entscheidungen bis 13.11.; Benchmark 10.000 Fahrzeuge headless Sim ≤ 4 ms/Tick Median (≤ 6 ms p95) oder belegter GDExtension-Plan; Signal-Spike erkennt Deadlock in 3/3 Testszenarien; Bau-Tool-Spike: 45°-Gleis mit Kurve, Weiche, Abriss, Undo; ≥ 4 von 6 Testern finden im kaputten Netz die Ursache in < 3 min; VS-Backlog zu 100 % geschätzt und ≤ 85 % der Kapazität |
| **M1a Review „Spielbarer Loop“** | 30.11.2026–15.01.2027 | Kern-Loop durchgängig spielbar | HQ → Lizenz → Lkw-Linie → Getreidekette geschlossen → Gewinn ohne Absturz in 30 min; 1 Zugstrecke mit Blocksignalen; Diagnose-Feed nennt Ort und Ursache für 3 Problemtypen (keine Ladung, Signal blockiert, keine Verbindung); 0 Blocker-Bugs |
| **M1b Vertical Slice** | 16.01.–26.03.2027 | VS-Umfang laut Rahmen in Release-Qualität, externer Playtest | 12 externe Tester: Median Zeit bis erste geschlossene Kette ≤ 20 min, ≥ 75 % lösen eine Signal-Blockade selbst über den Diagnose-Feed, SUS ≥ 70, „würde weiterspielen“ ≥ 70 %; 60 fps bei 2.000 Fahrzeugen auf Zielhardware (GTX 1660); 0 Blocker, ≤ 10 kritische Bugs; Determinismus-Test (Replay-Prüfsumme) grün |
| **M2 Alpha / Feature-Produktion** | 29.03.–24.09.2027 | Alle Release-Features drin (4 Epochen, 10 Ketten, alle Verkehrsmittel, freie Kurven, KI, Energie, Speichern) | Feature-Complete-Checkliste 100 %; Langzeit-Run 1850 → Epoche IV ohne Absturz (8 h Autotest); 10.000 Fahrzeuge ≤ 4 ms/Tick; Speicherstand-Migration über 2 Versionen grün; interner 6-h-Szenario-Run abschließbar |
| **M3 Beta / Early Access** | 27.09.2027–29.02.2028 | Content-Complete, Balancing, Steam EA (Launch Anfang Nov. 2027) | ≥ 10.000 Wishlists vor EA-Start; Absturzrate < 1 % der Sessions; Steam-Rating ≥ 80 % positiv nach 30 Tagen; Modding-JSON-Schemas dokumentiert, ≥ 3 Community-Mods lauffähig |
| **M4 Release 1.0** | 01.03.–31.05.2028 | Veröffentlichung 1.0 inkl. Lokalisierung DE/EN | 0 Blocker, ≤ 20 offene kritische Bugs; Steam-Deck-Prüfung bestanden oder bewusst gestrichen; Release-Kandidat 2 Wochen ohne neue Blocker |

**Wichtigste Abhängigkeiten zwischen Personen**
- Jonas Entscheidungslog bis 13.11. → Lena, Tobias, Felix, Sophie (VS-Specs, Economy-Tabelle, Spike-Ausrichtung, Kartengröße für Terrain)
- Felix Graph-Netz mit Blockreservierung bis 20.11. → Aylin Diagnose-Feed (Texte „wartet an S4, weil …“) und Diagnose-Playtest 24.–25.11.
- Felix Playtest-Build „kaputtes Netz“ bis 23.11. → Aylin/Daniel Diagnose-Playtest 24.–25.11. → Gate M0 am 27.11.
- Sophie Maßstabsband und Kartengröße-Test bis 20.11. → Felix Terrain-Chunks und Kamera-LOD, Freelancer-3D-Pakete ab 30.11.
- Tobias Economy-Tabellenmodell (Ketten, Erlösformel, Sättigung) bis 27.11. → Felix/Neueinstellung Gameplay Implementierung Ketten und Lizenz → Kauf ab Sprint 1
- Lena Skilltree-Spec 2 Äste + Meilensteinkette bis 18.12. → Aylin Skilltree-UI, Gameplay-Programmierung ab Januar
- Neueinstellung Gameplay-Programmierung Start spätestens 01.02.2027 → Bus/Stadt, Lager und Fabrikstufen im VS (sonst Kürzung auf 2 Ketten)
- Daniel Release-Kandidat VS 12.03.2027 → externer Playtest 16.–19.03. → Gate M1 26.03.

**Kritischer Pfad:** Konzeptentscheidungen (13.11.) → Graph-Netz mit Blockreservierung und festem Tick (Felix, 20.11.) → Signale + Diagnose-Feed im spielbaren Loop (15.01.) → Lager/Lkw/Zug-Umschlag mit 2–3 Ketten (Felix + Gameplay-Neueinstellung, Feb.) → VS-Release-Kandidat (12.03.) → externer Playtest und Gate (26.03.); jede Verzögerung bei Netz und Signalen verschiebt den Vertical Slice 1:1, weil Diagnose, Lager und Playtest darauf aufbauen.

## Risiken, Personalbedarf und Entscheidungen

### Top-6-Risiken

| Risiko | Wahrscheinlichkeit | Auswirkung | Gegenmaßnahme | Owner |
|---|---|---|---|---|
| Felix ist Engpass (einziger Programmierer für Sim, Netz, Signale, Tools und Gameplay) | hoch | hoch – VS verzögert sich um Monate | Gameplay-Programmierung sofort ausschreiben, Freelancer als Brücke; Felix nur Sim/Netz/Signale, Gameplay-Regeln in GDScript an Neueinstellung; Scope-Kürzungsliste vorab (3. Kette, Bus) | Katrin |
| Signal-/Reservierungslogik erzeugt Deadlocks oder bleibt unverständlich (USP scheitert) | mittel | hoch | Signal-Spike zuerst in M0; Deadlock-Erkennung mit UI-Text; Diagnose-Playtest 24.11. und erneut vor 15.01.; automatisierte Szenariotests in CI | Felix (mit Aylin) |
| Scope-Creep: Konzept beschreibt deutlich mehr als VS-Rahmen (5 Ketten, 6 Äste, KI, Umzug, Niederlassungen) | hoch | mittel–hoch | Entscheidungslog bis 13.11., VS-Umfang eingefroren am Gate M0; Change-Requests nur mit Jonas-Freigabe und Gegenkürzung | Katrin (mit Jonas) |
| Performance-Ziel 10.000 Fahrzeuge verfehlt bzw. Karte 1.024² sprengt Speicher/Bauzeiten | mittel | hoch | Benchmark ab Woche 2 in CI; GDExtension-Port als Plan B vorbereitet; VS mit kleinerer Karte (512²), 1.024² erst in M2 nach Terrain-Chunk-Test | Felix |
| Rekrutierung dauert zu lange (Kündigungsfristen 3 Monate in DE) | hoch | mittel | Ausschreibung bis 11.11.; Freelancer-Verträge für 3D ab 30.11. und Gameplay ab Jan.; Remote-Kandidaten zulassen | Katrin |
| Bau-Tool fühlt sich im 45°-Raster nicht gut an (Pfeiler 2 „Bauen fühlt sich gut an“ verletzt) | mittel | mittel | Bau-Tool-Spike mit Kurvenglättung in M0, Vergleichstest gegen Railway Empire im VS-Playtest; Spline-Datenmodell von Tag 1; Tools-Programmierer ab 01.04.2027 für freie Kurven | Felix (Bewertung: Jonas) |

### Personalbedarf mit Zeitpunkt

| Rolle | Warum | Ausschreibung | Eintritt (Ziel) | Überbrückung |
|---|---|---|---|---|
| **3D-Artist** (Low-Poly, Hard-Surface, Godot-Import) | Sophies VS-Minimum ist nur mit 1 Artist + Sophie in ca. 3 Monaten machbar | 11.11.2026 | 04.01.2027 (spätestens 01.02.) | Freelancer ab 30.11.2026 mit Asset-Paketen (Industrien, Fahrzeuge) |
| **Gameplay-Programmierer/in** (GDScript, Godot 4) | Felix kann Sim-Kern, Netz und Signale nicht parallel zu Ketten, Städten, Lizenzen, Skilltree und UI-Anbindung bauen | 11.11.2026 | 01.02.2027 (spätestens 01.03.) | Freelancer GDScript ab 11.01.2027 für Ketten/Lizenz-Logik |
| **Tools-/Bau-Programmierer/in** (Spline-Tools, Terrain, C++) | Freie Kurven, Terrain-Deformation, Brücken/Tunnel sind M2-Kern und Pfeiler 2 | 11.01.2027 | 01.04.2027 (Start M2) | 45°-Tool im VS durch Felix |
| Optional: Sound-Design (Freelance) | Audio-Minimum VS und epochengebundene Musik M2 | 15.01.2027 | Feb. 2027 (Paketvertrag) | Lizenzierte Platzhalter-Sounds |
| Optional: Community/Marketing (Teilzeit) | Steam Coming Soon, Next Fest, EA-Launch | 01.04.2027 | 01.06.2027 | Katrin + Jonas |

### Konzeptentscheidungen bis 13.11.2026

| Entscheidung | Widerspruch im Konzept | Empfehlung Producer | Owner |
|---|---|---|---|
| **Epochenzahl** | Lena: 5 Epochen (I–V, Chips in V); Tobias, industry.md und Rahmen: 4 Epochen (E1–E4) | 4 Epochen für Release, Chips in E4; Epoche V als möglicher Post-Launch-Inhalt; alle Konzeptdateien bis 20.11. angeglichen | Jonas (mit Lena, Tobias) |
| **Skillpunkt-Quelle** | Lena: Ast-XP aus genutztem Spielstil (+ Meilenstein-Punkte); Tobias: Punkte nur über Meilensteine | Hybrid festschreiben: Punkte nur aus Meilensteinen (Menge kontrollierbar), Ast-XP bestimmt nur, welcher Ast verbilligt/empfohlen ist; im VS testen | Lena (mit Tobias) |
| **Startketten** | Rahmen: 2–3 Ketten im VS (Getreide, Kohle, Erz → Stahl); Tobias: 5 Ketten inkl. Vieh, Holz, Werkzeug | VS: Getreide, Kohle → Kraftwerk, Erz + Kohle → Stahl; Vieh, Holz, Werkzeug erst M2 | Tobias (Freigabe Jonas) |
| **Kartengröße 192 vs. 1.024** | Prototyp: 192 × 192 Felder; Sophie: mind. 1.024 × 1.024 (≈ 10 km) für Maßstab und Clusterabstand | VS mit 512 × 512 (ein Cluster-Ring, 3–4 Städte); 1.024² als Release-Ziel nach Terrain-Chunk-Benchmark in M0 | Felix (mit Sophie) |
| **Vertical-Slice-Umfang** | Rahmen-Scope vs. Konzept-Extras (HQ-Umzug, Niederlassungen, Verträge, KI, Experten-Signale, 6 Äste, Epochenausblick E2) | Rahmen-Scope gilt; explizit raus: KI, Umzug, Niederlassungen, Verträge, Energie-Radiusbonus nur als Stub, E2 nur als Vorschau-Panel | Katrin (Freigabe Jonas) |
| **KI und Lizenzen** | hq.md: darf KI HQ setzen und Lizenzen teilen/blockieren?; industry.md: geteilte Lizenz 50/50, Exklusivität ×2,5; KI im VS? | KI nicht im VS; Regel für M2: KI setzt HQ, darf Lizenzen teilen, Exklusivität nur gegen Aufpreis; Lizenzlaufzeit in Spieljahren statt Minuten (stabil bei Zeitraffer) | Tobias (mit Lena) |
| **Bau-Tool** | Felix: VS im 45°-Raster mit Kurvenglättung; Jonas-Pfeiler 2 und Ideengeber: Railway-Empire-Haptik mit freien Kurven | VS 45°-Raster mit Live-Kosten, Steigungsfarbe, Abriss, Undo; freie Kurven in M2 durch Tools-Neueinstellung; Haptik-Kriterium im VS-Playtest (≥ 70 % „Bauen fühlt sich gut an“) | Felix (Freigabe Jonas) |
