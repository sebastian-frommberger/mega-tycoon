# A-07 Kontextdialog: Feldliste je Objekttyp (Aylin Kaya, D15)

Standard: Klick auf das Objekt öffnet ein Panel rechts, **Infos oben, Aktionen unten**, Esc/Klick daneben schließt. Kein eigenes Konzept. Eigen ist nur, was unsere Ökonomie zeigt (Lizenz/Besitz, Warum-Liste). Statusform = Symbol + Text, nie nur Farbe: ● läuft, ▲ Achtung, ■ steht. Zahlen sind Platzhalter aus dem Modell (Tobias t05), nichts gemessen.

| Typ | # Feld (max 8) / Aktion | Inhalt | Referenz |
|---|---|---|---|
| **Industrie** | 1 Name + Stufe | „Mühle, Stufe 1“ | TF2: Titelzeile Industrie |
| | 2 Status | ● läuft / ▲ Input fehlt / ■ steht | OpenTTD: Statussymbol + Text |
| | 3 Produktion | „20 E/min Mehl“ | TF2: Produktion je Ware |
| | 4 Bedarf / Zufluss | „braucht Getreide 20 E/min, kommt 20“ | Anno: Warenbedarf im Info-Panel |
| | 5 Lieferziele | Abnehmer + Entfernung in Feldern | OpenTTD: Lieferung je Ziel |
| | 6 Lizenz / Besitz | „Lizenz 140 $/30 min, Rest 18:20“ oder „Eigentum“ | **eigen (Unterschied)** |
| | 7 Ertrag/min | „+379 $/min“ (nur eigene Lkw) | TF2: Gewinn je Minute |
| | 8 Warum? | Ursache-Liste bei ▲/■ (D9-Codes), sonst ausgeblendet | **eigen (A-08)** |
| | A Lizenz kaufen / verlängern | Preis im Button | eigen |
| | A Firma kaufen | Netto-Preis; gesperrt mit Grund bis Angebot (M5b) | eigen (D12) |
| | A Linie anlegen | startet Bau-Tool mit dieser Firma als Start | OpenTTD: Linie/Route ab Objekt |
| | A Ausbau | Stufe +1, nur Eigentum | Anno: Gebäude ausbauen |
| **Stadt** | 1 Name | „Kornfeld“ | Cities Skylines: Titelzeile |
| | 2 Einwohner + Stufe | „900, Dorf“ | Cities Skylines: Einwohnerzahl |
| | 3 Status Versorgung | ● ausreichend / ▲ knapp / ■ unterversorgt | Anno: Bedarfsampel |
| | 4 Bedarf je Ware | „Nahrung 9 E/min, geliefert 9“ | Anno: Bedarfsliste |
| | 5 Wachstum | „bis Kleinstadt: 6 min bei voller Versorgung“ | Cities Skylines: Wachstumsbalken |
| | 6 Fahrtwünsche | „80/min“ (nur Handel gerechnet, sonst „–“) | OpenTTD: Passagiere/Monat |
| | 7 Lieferanten | Liste Firmen, die liefern | TF2: Lieferantenliste |
| | A HQ hier setzen | nur vor Spielstart | eigen (HQ-Start) |
| | A Linie anlegen | Stadt als Ziel | OpenTTD |
| **Fahrzeug** | 1 Name / Nr | „Lkw 3“ | TF2: Fahrzeugname |
| | 2 Status | ● fährt / ▲ wartet / ■ steht | OpenTTD: Fahrzeugstatus |
| | 3 Ladung | „8/10 Getreide“ | OpenTTD: Ladung/Kapazität |
| | 4 Route | Von → Nach, nächstes Ziel | TF2: Fahrplanzeile |
| | 5 Ertrag/min | „+90 $/min netto“ | OpenTTD: Gewinn dieses Jahr, hier je Minute |
| | 6 Kosten | „90 $/min fix, 0,08 $/Feld“ | OpenTTD: Betriebskosten |
| | 7 Lizenz der Route | Restzeit der Lizenz am Start/Ziel | **eigen** |
| | 8 Warum? | wie Industrie | **eigen (A-08)** |
| | A Fahrzeug ersetzen | gleicher Typ, gleiche Linie | OpenTTD: Fahrzeug ersetzen |
| | A Linie ändern / Verkaufen | | OpenTTD |
| **Station / Lager** | 1 Name | „Lager Nord“ | TF2: Stationsname |
| | 2 Status | ● ok / ▲ voll / ■ leer | OpenTTD: Station Warenstand |
| | 3 Bestand je Ware | „Getreide 40/100“ | OpenTTD: Wartende Fracht |
| | 4 Zufluss / Abfluss | „+20 / −15 E/min“ | Anno: Lager Zu-/Abfluss |
| | 5 Angebundene Firmen | Liste mit Lizenz/Eigentum-Symbol (Laden nur dort, D12) | **eigen (Lager als Hub)** |
| | 6 Linien | Zahl + Liste | TF2: Linien an Station |
| | 7 Kapazität | Gesamt / Ausbaustufe | Anno: Lagerkapazität |
| | A Linie anlegen / Lager ausbauen / Abriss (50 %, F-13) | | OpenTTD / eigen |

**Annahmen:** Feld 4 Stadt „Wachstum“ nutzt T-04 (Lena hq_startwerte), Handel-Fahrtwünsche nur dort belegt. Lager-Details (Kapazität, Ausbaupreis) sind nicht modelliert, Felder bleiben ohne Zahl bis M1. Felix baut direkt (S4, F-15), Rückfragen an mich.
