## Fabriken und Industrien

*Tobias Brandt (Economy, Federführung) mit Lena Hoffmann, Aylin Kaya und Sophie Martin. Zahlen sind Startwerte für den Vertical Slice.*

### Besitz-Leiter: erst Lizenz, dann Kauf

**Abweichung, ausdrücklich:** Diese Leiter ersetzt den „Start durch Firmenkauf“ aus den Leitplanken. Die Regel „Laden nur bei eigenen Firmen“ wird zu „Laden nur mit Lizenz oder Besitz“. Lenas Meilenstein 1 heißt jetzt „Erste Transportlizenz“, der Firmenkauf rückt auf Meilenstein 5.

| | Stufe 0: keine | Stufe 1: Transportlizenz | Stufe 2: Firma kaufen |
|---|---|---|---|
| Kosten | – | 10 % des Kaufpreises (100–400 $ × Stufe), Laufzeit 30 min, Verlängerung zum gleichen Preis | Kaufpreis (Tobias), **50 % der gezahlten Lizenzgebühren werden angerechnet** |
| Laden | nein | ja | ja |
| Beliefern | ja | ja | ja |
| Einnahme | Transportertrag bei Abgabe | Transportertrag | Transportertrag **+ Werksmarge 15 %** auf alles, was Abholer (auch die KI) damit verdienen, minus Unterhalt 20 $/min × Stufe |
| Exklusiv | – | geteilt (max. 2 Lizenznehmer, Output 50/50); exklusiv für ×2,5 Preis | immer exklusiv, bestehende Fremdlizenzen werden mit Restlaufzeit ausgezahlt |
| Hebel | – | keine | Ausbau, Spezialisierung, Modernisieren, Umrüsten, Anbindung |
| Einfluss | – | halber Radius | voller Radius |

**Start:** Das Startkapital reicht für 3 Lizenzen oder knapp 1 Kauf. Casuals schließen damit die erste Kette ohne Kapitalbindung, und eine Fehlwahl kostet nur eine Laufzeit. Veteranen kaufen früh, weil die Werksmarge Zinseszins ist. Eine Lizenz läuft 3 min vor Ablauf als Hinweis im Feed auf. Mit „Auto-Verlängern“ (Standard an) gibt es kein Micromanagement.

**Konkurrenz:** Die KI kauft ebenfalls Lizenzen. Eine geteilte Lizenz bedeutet also, dass dieselbe Ware gemeinsam abgeholt wird. Wer die Firma kauft, verdrängt sie. Wer eine Firma besitzt, die die KI beliefert oder abholt, verdient über die Marge mit. Konkurrenz wird so lesbar als Wettlauf um Besitz und nicht um Sabotage.

### Skalierung: Ausbaustufen (nur Stufe 2 der Leiter)

| Stufe | Durchsatz (E/min) | Fläche | Puffer Ein/Aus | Ladestellen | Personal | Voraussetzung |
|---|---|---|---|---|---|---|
| 1 | 20 | 8×8 | 40/40 | 1 Rampe | 20 | – |
| 2 | 40 | 10×10 | 80/80 | 2 Rampen | 40 | Straßenanschluss |
| 3 | 70 | 12×12 | 150/150 | 3 Rampen/Werksbahnhof | 70 | Stadt ≥ 2.000 EW im 25-Felder-Radius oder Werkssiedlung |
| 4 | 110 | 15×15 | 250/250 | Werksbahnhof/Kai | 110 | einmalig 50 Maschinen (E1: 100 Werkzeug) |

Eine Rampe schafft 2 E/s. Ab Stufe 3 übersteigt der Output, was Lkw sinnvoll abholen (Straßenlimit ca. 12 Lkw/min). Das System lenkt so zu Zug und Lager. Der Input wächst 1:1 mit.

**Personal (Abweichung von Tobias' 80/110-Regel ab Stufe 3):** Bis Stufe 2 gilt sie weiter. Ab Stufe 3 gilt: Arbeitsfaktor = 0,5 + 0,6 × Pendlerdeckung. Große Werke im Nirgendwo laufen, aber schlecht.

### Produktionslogik, lesbar

**Rate = Stufendurchsatz × Arbeitsfaktor × Energiebonus**, begrenzt durch den knappsten Inputpuffer und freien Outputplatz (Deckel ×1,6 bleibt).

| Zustand | Welt | Panel-Satz |
|---|---|---|
| Läuft (≥ 90 %) | Rauch voll, Förderband animiert | „Läuft: 66/70 E/min“ |
| Gedrosselt | Rauch halb, gelbes Dreieck | „31/70 – nur 45 % Arbeiter“ |
| Input fehlt | Halde weg, Icon ausgegraut | „Kohle fehlt – Linie Kohle-Süd liefert 30 statt 70“ |
| Output voll | Hof voller Ware, rotes Achteck | „Lager voll – 3 Lkw zu wenig oder Werkslager bauen“ |
| Kein Strom | Fenster dunkel | nur Chemie/Chips: „Strom 52 % < 80 %“ |

Für normale Werke ist Strom nur ein fehlender Bonus, und Arbeitermangel drosselt, stoppt aber nie. Jeder Zustand landet mit Ursachenkette in Aylins Problem-Feed.

### Auswirkungen auf die Umgebung

- **Arbeitsplätze:** Eine Stadt mit Fabrik im Pendlerradius und ≥ 50 % Pendlerdeckung bekommt +0,5 %/Monat Wachstum. Pendlerlinien zahlen also doppelt.
- **Belastung:** Lärm und Schmutz wirken im Radius 6 Felder (Schwerindustrie 10). Die Viertel dort wachsen nicht und werden grauer, die Zufriedenheit sinkt um −5 % je Viertel. „Effizienz“ halbiert den Radius.
- **Werkssiedlung (optional):** ab Stufe 3, 6.000 $, 200 Einwohner, deckt 60 Arbeitsplätze und hat einen eigenen Warenkorb (Nahrung). Aus dem Werk wird ein neuer Kunde.
- **Industriegebiet:** Werke im Abstand ≤ 10 Felder teilen sich einen Werksbahnhof, ihre Belastung addiert sich nicht, und Lenas „Werksbahn“ greift.

### Optionen und Drei-Hebel-Regel

**Kern:** Lizenz, Kauf/Verkauf, Ausbau, Spezialisierung, Werksanschluss (1.200 $, 4 E/s direkt am Werk). **Epochal:** Modernisieren, Umrüsten (Tobias). **Optional:** Werkslager (500 $, +200 Outputpuffer, kein Ertrag), Produktionsschwerpunkt bei 2 Outputs ab Raffinerie (70/30 · 50/50 · 30/70), Liefervertrag (feste Menge für 20 min, +20 % Preis, sättigungsfrei bis zur Vertragsmenge, −10 % bei Unterlieferung), Werkssiedlung.

Das Firmenpanel zeigt immer genau **drei Knöpfe**:
- **Entwicklung:** jeweils der sinnvolle Schritt (Lizenz → Kauf → Ausbau/Modernisierung/Umrüstung)
- **Ausrichtung:** Spezialisierung, Schwerpunkt
- **Anbindung:** Anschluss, Werkslager, Siedlung

Verträge stehen im Auftragspanel. Jede Entscheidung hält mindestens 10 min.

**Abweichung zu Lena:** Die Schlüssel-Fähigkeit „Spezialisierung“ wird zur vierten Ausrichtung **„Fokus“** (+30 % Output, −1 Inputgut), damit es keinen Namenskonflikt gibt.

### Fremde Firmen

- **Freie Firmen** produzieren auf Stufe 1 mit 50 %, mit mindestens einer Lizenz zu 100 %. Beliefern darf man sie immer, mit vollem Ertrag als Endabnehmer. Bei ≥ 80 % Inputversorgung über 10 min wachsen sie auf Stufe 2, und Kaufpreis und Lizenz werden 30 % teurer. Daraus ergibt sich die Wahl: billig kaufen oder erst als Kunden mästen?
- **Gegen „konstruiert verteilt“:** Rohstoffe liegen nach Geologie. Bleibt eine Stadtkategorie 20 min ungedeckt, kündigt der Feed eine **Gewerbefläche** am Stadtrand für einen passenden Verarbeiter an. Verarbeiter folgen der Nachfrage.
- **KI-Firmen** laufen voll und bauen selbst aus. Der Spieler kann sie beliefern und dort eine geteilte Lizenz kaufen, sofern die KI keine Exklusivität hält. Bei 3 Verlustmonaten der KI-Firma nimmt die KI ein Übernahmegebot zu 130 % des Firmenwerts an.

### Lesbarkeit

- **Fabrik-Panel:** Kopf mit Besitzstufe, Lizenz-Restlaufzeit und Mitlizenznehmer. Links stehen die Eingänge mit Pufferbalken, in der Mitte die Rate mit **einem** Engpass in Klartext (Klick springt zur Linie), rechts die Ausgänge mit Abnehmern. Darunter: Überschuss/min, Werksmarge, Firmenwert, Trend.
- **Welt-Icons:** Pin mit Ausgangsgut und Füllring, 1–4 Stufenpunkte, Zustandsform. Der Pin-Rand zeigt die Besitzstufe: gestrichelt in Firmenfarbe für die Lizenz, voll für Besitz.
- **Silhouette (Sophie):** Stufe 1 ist der Kern, Stufe 2 bringt eine zweite Halle, Stufe 3 Förderband und Werksgleis, Stufe 4 Schornstein und Turm. Jeder Anbau entsteht im Material seiner Epoche, die Fabrik zeigt also ihre Biografie. Eine lizenzierte Fabrik trägt nur ein Firmenschild am Tor.

### Offene Fragen

1. Lizenzlaufzeit in Spielminuten (30) oder in Spieljahren, damit sie bei Zeitraffer stabil bleibt?
2. Ist Stufe 4 mit Werksbahnhof-Pflicht zu hart für reine Straßen-Runs (Alternative: Lager in ≤ 5 Feldern)?
3. Epochenzählung vereinheitlichen: Tobias nutzt E1–E4, Lena fünf Epochen. Diese Datei folgt Tobias, Jonas entscheidet.
