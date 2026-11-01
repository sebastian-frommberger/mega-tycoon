## Städte

*Tobias Brandt (Economy, Federführung) mit Lena Hoffmann (Game Design), Aylin Kaya (UX/UI) und Sophie Martin (Art). Alle Zahlen sind Startwerte für den Vertical Slice. Annahme: 1 Spielmonat = 1 min Echtzeit.*

**Leitsatz:** Eine Stadt ist ein Kunde mit einer Einkaufsliste, die mit der Stadt wächst, und mit Wegen, die man sehen kann.

### Skalierung

| Stufe | Einwohner | Neu im Warenkorb | Fahrtwünsche | Fläche / Bild |
|---|---|---|---|---|
| Dorf | < 1.000 | Nahrung | fast nur Stadt ↔ Stadt und Pendler | ≤ 15×15, 1 Viertel |
| Kleinstadt | 1.000–4.999 | + Bau | erste Busse lohnen sich | 30×30, 2–4 Viertel, Marktplatz |
| Stadt | 5.000–19.999 | + Werkzeug (ab E2 + Benzin) | Gewerbekern zieht Pendler an | 50×50, Industriegebiet am Rand, 3–4 Geschosse |
| Großstadt | 20.000–59.999 | + Konsum/Mobilität (E3) | Ströme zwischen den Vierteln | 75×75, erste Hochhäuser im Kern, Vororte |
| Metropole | ≥ 60.000 | + Elektronik (E4) | Fernverkehr, Flughafen sinnvoll | 100×100, Skyline, Vororte wachsen zusammen |

**Abweichung:** Die Stufe „Metropole“ ab 60.000 Einwohnern ist neu. In tobias.md endete die Liste bei „Großstadt“.

**Wie Wachstum entsteht.** Der Versorgungsgrad V aus tobias.md wird zum **Wachstumswert W** erweitert (Abweichung, ausdrücklich benannt):

**W = 0,6 × Warenversorgung + 0,25 × Personenabdeckung + 0,15 × Arbeitsplätze**

- **Arbeitsplätze:** Anteil der Pendlerwünsche, die eine belieferte Industrie im Umkreis von 25 Feldern erreichen.
- **Wachstum je Spielmonat:** W ≥ 80 %: +2 %; 50–80 %: +0,5 %; 30–50 %: 0 %; unter 30 %: −0,5 %. Die Schwellen bleiben wie in tobias.md.
- **Stufen-Tor:** Bei 95 % der nächsten Schwelle bleibt die Stadt stehen, bis die neue Kategorie zu mindestens 25 % versorgt ist. Das Panel zeigt dann: „Wartet auf Bau, um Kleinstadt zu werden.“
- **Tempo:** Bei Höchstwachstum braucht eine Stadt vom Dorf zur Kleinstadt (800 → 1.000) ca. 12 min und von der Kleinstadt zur Stadt ca. 80 min (passt zu Lenas Meilenstein „Stadt > 5.000“). Eine Großstadt ist ein Ziel ab ca. 3 h.
- **Wo die Stadt wächst:** Neue Häuser entstehen bevorzugt im Einzugsbereich von Haltestellen. Ab der Großstadt entstehen **neue Stadtteile** (Vororte mit 10×10 Feldern) an Bahnhöfen, die bis zu 20 Felder außerhalb liegen. Wer einen Bahnhof baut, legt damit fest, wo die Stadt wächst.

### Auswirkungen

| Folge | Mechanik | Für den Spieler |
|---|---|---|
| Mehr Nachfrage | Bedarf = Einwohner / 100 je Kategorie und min | höhere Erlöse, aber die Sättigung greift weiterhin |
| Mehr Pendler | 1 Fahrtwunsch/min je 100 Einwohner | Personenverkehr skaliert, Industrien kommen in Richtung 110 % |
| Stau | Stadtstraßen haben eine Kapazität von 8 Lkw/min (Land: 12) | Lkw-Verteilung im Kern kippt ab der Stadt, ein Lager am Rand wird nötig |
| Platzmangel | Abriss je Haus 150 $ × Geschosse, Hochhaus 4.000 $; zusätzlich −2 Ruf je Haus | Bahnhöfe früh bauen oder später Durchbrüche teuer bezahlen |
| Lärm | Gleis- oder Straßenabschnitte mit > 6 Fahrzeugen/min in Wohnvierteln: Viertel wächst halb so schnell | Strecken an den Rand legen, Tunnel nutzen |
| Verschmutzung | Schwerindustrie < 10 Felder vom Wohngebiet: −0,5 % Wachstum, Viertel wird grau | Abstand halten, das entspricht dem Cluster-Modell |
| Ruf | 0–100 je Stadt, Start bei 50, in der HQ-Stadt bei 65 | bestimmt Konzessionen und Abrissaufschläge |

**Ruf:** +1/min bei W ≥ 80 %, −1/min je kritischer Meldung „Fahrgäste verfallen“, dazu Abriss und Lärm (siehe Tabelle). Bei Ruf < 30 kostet Abriss das Doppelte und Verträge sind gesperrt. Bei Ruf > 70 gibt es Konzessionen und −25 % Abrisskosten.

### Stadtstruktur

Jede Stadt besteht aus **Vierteln** mit je ca. 10×10 Feldern und drei Typen:

- **Wohnen** (60 %): Hier entstehen die Fahrtwünsche (**Quellen**).
- **Gewerbe/Zentrum** (30 %): Ziel für Arbeit und Einkauf. Hier werden auch Waren abgeliefert.
- **Industrie** (Rand): Ziel der Pendler, verbunden mit Firmen im Umkreis.

**Quelle–Ziel in einem Satz:** *Leute fahren von Wohnvierteln zur Arbeit (Gewerbe oder Industrie) und in Nachbarstädte, sonst nirgendwohin.* Die Aufteilung bleibt wie in tobias.md: 60 % innerorts, 25 % zu Nachbarstädten, 15 % Pendler.

**Müssen Bürger überall hin? Nein.** Jedes Wohnviertel hat höchstens **3 Ziele**: sein nächstes Gewerbezentrum, die nächste Industrie mit Arbeitsplätzen und die größte Nachbarstadt im Umkreis von 90 Feldern. Eine Stadt gilt als **gut abgedeckt**, wenn mindestens 70 % der Einwohner im Haltestellenradius wohnen (Bus 5 Felder, Bahnhof 10 Felder) **und** mindestens 60 % ihrer Fahrtwünsche ein Ziel erreichen. Ohne den Skill „Umsteigeknoten“ (lena.md) zählt nur eine Direktlinie, mit dem Skill ist 1 Umstieg erlaubt.

### Optionen neben Transport

| Option | Kosten | Nutzen | Status |
|---|---|---|---|
| **Stadtlager/Logistikzentrum am Rand** | wie ein Lager, 800 $ | Zug liefert an den Rand, Lkw verteilen in den Kern; umgeht den Stau | Kern |
| **Bahnhof/Busbahnhof ausbauen** (3 Stufen) | 2.000 / 5.000 / 12.000 $ | Gleise bzw. Bussteige +2, Einzugsradius +3, Umsteigen +50 %; Optik wächst mit | Kern |
| **Versorgung lenkt Entwicklung** | keine | Bau-Lieferung lässt Wohnviertel wachsen, Werkzeug das Gewerbe, Pendler-Abdeckung das Industriegebiet | Kern |
| **Stadtvertrag** | keine, Ruf ≥ 50 | z. B. „300 Bretter in 10 min“, +50 % Erlös (tobias.md), +5 Ruf | Kern |
| **Konzession/Exklusivlinie** | 3.000 $ je 10 min, Ruf ≥ 70 | KI-Spediteur darf in der Stadt keine Personenlinien betreiben | optional (mit KI) |
| **Grundstück reservieren** | 50 $ je Feld | Die Stadt baut dort nicht, der Platz bleibt für einen späteren Bahnhof frei | optional |
| **Park&Ride** (ab E2) | 1.500 $ | Dörfer im Umkreis von 15 Feldern zählen als Einzugsgebiet eines Bahnhofs | optional |

### Lesbarkeit

- **Stadt-Panel (Klick auf Stadt):** Zeile 1 zeigt Stufe, Einwohner und einen Trendpfeil **mit Grund**, z. B. „+1,8 %/Monat, weil Nahrung 95 %, Bau 70 %“. Zeile 2 zeigt den Warenkorb als Icon-Reihe mit Füllring und Lieferant (Aylins Format). Zeile 3 zeigt die Abdeckung als Ampel aus zwei Zahlen: „Einwohner erreicht 64 % · Wünsche erfüllt 41 %“.
- **„Was braucht diese Stadt als Nächstes?“:** genau **eine** Empfehlung mit Begründung und Sprungziel, z. B. „Bau liefern → Stufen-Tor Kleinstadt. Nächstes Sägewerk 31 Felder, kaufbar 2.400 $.“
- **Abdeckungs-Heatmap:** unversorgte Häuser grau, versorgte in Firmenfarbe. Viertel, deren Ziele unerreichbar sind, bekommen eine Schraffur.
- **Wunschlinien:** Bögen von Viertel zu Ziel. Bedient wird durchgezogen dargestellt, unbedient gestrichelt, die Dicke entspricht den Fahrgästen. Höchstens 3 Bögen je Viertel.
- **Wartende mit Grund (Hover auf Haltestelle):** „42 warten: 30 → Zentrum (Linie 2 voll, Takt 4 min) · 12 → Kornfeld (keine Linie, verfallen in 1:20).“ Warum hier mehr warten als dort, steht unten: „Einzugsgebiet 1.900 Einwohner, 2 Ziele erreichbar.“
- **Signale in der Welt (Sophie):** Versorgte Viertel bekommen Markisen, Laternen und Baukräne, wenn sie wachsen. Unterversorgte Viertel werden grau, es gibt keine Ruinen. Bei einem Stufen-Tor steht ein Gerüst am Stadtrand. Lärmzonen werden in der Karte als Wellenmuster dargestellt. Nachts zeigen beleuchtete Viertel die Abdeckung. In der Fernansicht trägt der Stadtumriss die Warenkorb-Icons.

### Offene Fragen

1. Reichen drei Ziele je Viertel für Großstädte, oder wirken Metropolen dann zu flach?
2. Ist der Wachstumswert W mit den Gewichten 0,6 / 0,25 / 0,15 für reine Güterspieler zu strafend? Alternative: Die Personenabdeckung wirkt nur als Bonus.
3. Welche Startboni bekommt die HQ-Stadt über den Ruf von 65 hinaus? (Abstimmung mit dem HQ-Konzept)
