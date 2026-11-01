## Interface, Diagnose und Signale

*Autorin: Aylin Kaya, UX/UI*

### Leitprinzip „lesbare Komplexität“
1. **Jede Warnung hat Ort, Ursache, Vorschlag.** Keine Meldung ohne Sprungziel auf der Karte, ohne „weil …“ und ohne mindestens eine Handlungsoption. „Keine Verbindung“ allein ist verboten.
2. **Zustand vor Zahl.** Erst Farbe/Form zeigen, ob etwas gut läuft (grün fließt, gelb stockt, rot steht), Zahlen erst beim Hover oder im Detailpanel.
3. **Gültigkeit und Kosten sind getrennte Kanäle.** Form/Farbe des Ghosts = baubar ja/nein, Zahl daneben = Preis. Nie beides in einer Farbe.
4. **Die Karte ist das Interface.** Probleme, Auslastung und Reservierungen erscheinen dort, wo sie entstehen – Panels ergänzen, ersetzen aber nicht.

### Diagnose-System
**Problem-Feed (Inbox)** rechts am Rand, eingeklappt als Zähler mit Schweregrad-Punkten. Einträge werden gebündelt („3 Lkw auf Linie Mehl-Nord warten auf Ladung“ statt drei Einzelmeldungen).

**Schweregrade:**
- **Kritisch (rot):** Geld- oder Netzstillstand – Linie ohne Ertrag, Deadlock, Lager voll. Pausiert optional das Spiel.
- **Warnung (gelb):** Effizienzverlust – Wartezeit > 30 %, Auslastung < 40 %, Stadt unterversorgt.
- **Hinweis (blau):** Chance – „Getreidefarm in Reichweite verkaufsbereit“, „Kraftwerk würde Cluster Nord +15 % geben“.

**Klick springt zum Ort**, Kamera fährt hin, betroffene Objekte pulsieren kurz, Rest wird abgedunkelt. **Ursachenkette** als aufklappbare Zeilen, jede Zeile klickbar:

> **Zug 4 steht seit 2:10 min**
> → wartet an Signal 12, weil Block 13 belegt ist
> → Block 13 belegt von Zug 2
> → Zug 2 wartet auf Ladung im Lager Hafen-Ost (12/40)
> → Lager Hafen-Ost wird nur von 1 Lkw beliefert
> **Vorschlag:** [Lkw hinzufügen] [Mindestbeladung senken] [Ausweichgleis vor Lager bauen]

Die Kette endet immer bei einer **Wurzelursache** (Ladung, Infrastruktur, Geld, Nachfrage). Deadlocks werden als Kreis erkannt und so formuliert: „Zug 3 und Zug 7 blockieren sich gegenseitig auf der eingleisigen Strecke Mühlbach–Kornfeld.“

### Signale und Blöcke
- **Blockfärbung:** Ab Zoomstufe „Strecke“ und immer bei aktivem Gleisbau-Tool sind Blöcke farbig: frei (neutral), belegt (Farbe des Zugs), reserviert (gestrichelt in Zugfarbe, mit Pfeil der Fahrtrichtung).
- **Reservierungsanzeige:** Hover auf einen Zug zeigt seinen reservierten Pfad bis zum nächsten Halt als Leuchtband; endet das Band an einem roten Signal, steht dort ein Symbol mit Grund („wartet auf Zug 2“).
- **Wartende Züge** bekommen ein Uhr-Icon mit Sekunden, ab 60 s gelb, ab 120 s rot.
- **Bauvorschläge:** Die Diagnose markiert Engstellen direkt auf dem Gleis: „Hier fehlt ein Ausweichgleis – 2 Züge kreuzen sich auf 14 Feldern eingleisig“ mit [Vorschlag anzeigen] als Ghost.
- **Einfache Signale (Standard):** Ein Signaltyp „Blocksignal“, das Spiel setzt bei Bahnhöfen und Weichen automatisch sinnvolle Signale („Auto-Signalisierung“). Einbahnstrecken per Rechtsklick.
- **Experten-Signale (freischaltbar über Skilltree/Option):** Pfadsignal, Einfahrsignal, Prioritätsweiche. Jedes Expertensignal zeigt im Tooltip in einem Satz, was es anders macht. Wechsel jederzeit, Auto-Signale bleiben bearbeitbar.

### Overlays
| Overlay | Zeigt | Erscheint automatisch, wenn … |
|---|---|---|
| Abdeckung/Einzugsbereich | Haltestellenradien, unversorgte Häuser grau | Haltestelle oder Bus-/Tramlinie platziert wird |
| Wunschlinien | Bögen von Herkunft zu Ziel, Dicke = Fahrgäste, Wartende als Zahl am Halt | Stadt oder Haltestelle angeklickt |
| Güterfluss | Animierte Pfeile je Gut, Dicke = Menge/min | Linie oder Lager angeklickt |
| Auslastung | Fahrzeuge/Linien grün–rot nach Beladung | Linienliste geöffnet |
| Engpass-Heatmap | Wartezeit an Signalen, Kreuzungen, Rampen | Warnung „Stau“ im Feed angeklickt |
| Einfluss | Radius, Kostenzonen außerhalb, Firmen kaufbar | Firmenkauf- oder Bau-Tool außerhalb des Radius |

Automatische Overlays verschwinden beim Verlassen des Kontexts; manuell gewählte bleiben (Taste O öffnet Overlay-Rad). Maximal ein Daten-Overlay gleichzeitig plus Einfluss als Kontur.

### Ressourcen und Ketten lesbar machen
- **Güterbaum (Taste G):** Eine Übersicht aller Güter der aktuellen Epoche als Flussdiagramm von links (Rohstoff) nach rechts (Stadt/Endkunde): „Getreide → Mühle → Mehl → Stadt“. Jeder Knoten zeigt mit Status-Punkt, ob ich ihn bediene (voll), teilweise (halb) oder gar nicht (leer). Klick auf einen Knoten hebt alle passenden Industrien auf der Karte hervor, sortiert nach Entfernung zu meinem Einflussradius.
- **„Wer braucht was?“:** Hover auf ein Gut zeigt Abnehmer und Lieferanten in Reichweite plus Lücke: „Werkzeug – gebraucht von 3 Städten, geliefert: 0. Nächste Werkzeugfabrik: 34 Felder, kaufbar für 3.200 $.“ Hover auf eine Stadt zeigt ihren Warenkorb als Icon-Reihe mit Versorgungsgrad („Fleisch 80 %, Bretter 20 %, Werkzeug fehlt“).
- **Ketten auf der Karte:** Ab mittlerem Zoom zeigt jede Industrie kleine Ein- und Ausgangs-Icons; fehlender Input blinkt nicht, sondern ist ausgegraut mit Lücke. Im Güterfluss-Overlay erkennt man ganze Ketten als zusammenhängende Farbbänder; unterbrochene Ketten enden sichtbar mit einem „offenes Ende“-Marker.
- **Epochenwechsel als Vorher/Nachher:** Beim Übergang erscheint kein Textfenster, sondern eine kurze Kamerafahrt plus Änderungsliste mit Sprungzielen, aufgeteilt in drei Spalten: **Neu** („Chipfabrik – braucht Strom und Silizium“), **Modernisiert** („Sägewerk Nord: +1 Ausbaustufe Möbel verfügbar“), **Rückläufig** („Kohle-Nachfrage in Städten −30 % bis Epoche 4“). Rückläufige Industrien bekommen ein Pfeil-nach-unten-Symbol auf der Karte und im Güterbaum, damit niemand von Ertragsverlusten überrascht wird. Der Güterbaum zeigt in einer Vorschau-Lage („nächste Epoche“) gestrichelt, welche Ketten hinzukommen und welche Güter auslaufen – so wird der Wechsel planbar statt erlitten.

### Bau-UX
- **Vorschau:** Ghost-Kontur weiß = baubar, rot schraffiert = nicht baubar (mit Grund am Cursor: „Zu steil – 9 % > 6 %“). Kosten als eigenes Label: „1.240 $“ weiß, bei zu wenig Geld orange, aufgeschlüsselt bei Hover („davon Brücke 720 $, außerhalb Einfluss +180 $“).
- **Kurven statt L-Form:** Gleise per Ziehen mit weichen Kurven, Mindestradius sichtbar.
- **Snapping:** Straßen und Gleise docken automatisch an Gebäude-Anschlüsse, Lager und bestehende Strecken an (Magnet-Radius sichtbar); Haltestellen schnappen an Straßenseiten.
- **Live-Erreichbarkeit:** Während des Baus prüft das Spiel, ob die Verbindung ein Ziel erschließt: „✓ verbindet Getreidefarm ↔ Mühle (28 Felder)“ oder „✗ noch keine eigene Firma angebunden“.
- **Rückgängig/Abriss:** Strg+Z für die letzten 20 Bauaktionen mit voller Erstattung innerhalb von 30 s Spielzeit, danach Abriss mit 50 % Erstattung. Abriss ist immer möglich – kein Soft-Lock.

### Skilltree-UI und Epochen-Vorschau
- **Skilltree als Karte von Spielstilen**, nicht als Forschungsleiste: Äste wie „Stadtverkehr“, „Getreidekette“, „Schwerindustrie“, „Logistik/Lager“, „Schiene“, „Straße“. Knoten zeigen Rang („Stadtticket 2/5: +20 % Ticketerlöse in Städten“), Fähigkeits-Knoten (z. B. „Expressbus“) sind größer und rund.
- **„Dein Stil“-Hinweis:** Das Spiel markiert Äste, in denen der Spieler schon aktiv ist: „Du transportierst 70 % Personen – Stadtverkehr empfohlen.“
- **Epochen-Zeitleiste** oben im Baum: aktuelle Epoche, nächste Epoche mit Fahrzeugen, Ketten und Meilenstein-Bedingungen als Vorschau („Epoche 3: Diesel-Lok, Chipfabrik – braucht Strom. Noch 2 von 4 Meilensteinen“). Nichts ist verborgen, nur gesperrt.
- **Planungsmodus:** Spieler kann Punkte vormerken („Pinnen“), der Pfad wird hervorgehoben und im HUD als nächstes Ziel angezeigt.

### HUD-Struktur und Onboarding
**HUD:** oben links Geld, Gewinn/min, Epoche; oben Mitte aktuelles Ziel/Meilenstein; rechts Problem-Feed; unten Bauleiste (Straße, Schiene, Lager, Haltestelle, Linien, Abriss). Kontextpanel erscheint unten rechts bei Auswahl.

**Onboarding:** Keine Textwände. Kontextuelle Hinweise erscheinen beim ersten Auftreten eines Problems, maximal ein Satz plus Aktion:
- „Dein Zug wartet. Klick auf das Uhr-Symbol, um zu sehen, warum.“
- „Der Lkw fährt halb leer. Ein Lager kann mehrere Farmen sammeln. [Lager zeigen]“

Hinweise sind wegklickbar, im Feed nachlesbar und für Veteranen komplett abschaltbar („Ich kenne das Genre“ beim Start).

**Label-LOD nach Zoom:**
- Weit: nur Städtenamen und Cluster-Icons mit Status-Punkt.
- Mittel: Firmen-Icons, Linien mit Gewinn/min, Problem-Marker.
- Nah: Fahrzeugnummern, Ladungs-Balken, Signalzustände, Haltestellen-Wartende.
Kritische Probleme bleiben auf jeder Zoomstufe als Marker sichtbar.
