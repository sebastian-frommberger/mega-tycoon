# Referenzen: Ökonomie, Wettbewerb, Schwierigkeit (Stand 2026-11-03)

Ich bin Tobias, am Schluss spricht Jonas. Marken: [B] belegt mit Quellenkürzel (Liste unten), [E] aus dem Gedächtnis oder Einzelstimme, [R] eigene Rechnung, [M] im Repo gelesen. Alle [B] aus WebFetch stammen von einem kleinen Modell und sind nicht wörtlich geprüft (WF). Reddit, tt-forums (Anubis) und tt-wiki blieben gesperrt und wurden nicht umgangen; Reddit-Spiegelseiten habe ich bewusst nicht geöffnet.

## 1. Kredit, Zins, Insolvenz

| Spiel | Mechanik / Zahl | Quelle | Marke |
|---|---|---|---|
| OpenTTD | Zins ist Jahressatz, monatlich je 1/12 berechnet; verzinst werden Kredit und negative Kasse; Satz wird bei Spielstart gesetzt und bleibt | Z1, Z4 | [B] |
| OpenTTD | Presets Zins 2/3/4 % p.a. = 0,17/0,25/0,33 % je Monat; Kreditmaximum £300k/150k/100k | Z3 (Archiv-Wiki) | [B], Version unsicher |
| OpenTTD | Lok kostet £8–21k, also deckt der Rahmen 5 bis 37 Loks | Z8 | [B] WF, [R] |
| OpenTTD | Firmenkauf übernimmt den Kredit des Gekauften | Z4 | [B] |
| Transport Fever 2 | fest 1 % p.a. (0,08 % je Monat); Spieler: Kredit „unglaublich billig“, auch auf Hard nie Geldnot | Z9, Z10 | [B] WF, Foren [E] |
| Railroad Tycoon 1 | jeder Bankrott hebt den Satz neuer Anleihen um 1 Punkt, nach mehreren keine Anleihen mehr | Z14 | [B] WF |
| Railroad Tycoon 3 | Anleihe 500.000 $, 2 % Gebühr, Rating mindestens „B“; Bankrott streicht Anleihen, senkt das Rating | Z13 | [B] WF |
| Railway Empire 2 | Anleihen erneuern sich, Zins läuft je Quartal auf, ohne Zinsdeckung Bankrott; Klage: kaum Rückmeldung, Neustart nach 10+ h | Z16 | [B] WF, ein Thread |
| Industry Giant 2, Anno 1800, Railroad Tycoon 2 | keine nutzbare Zinszahl gefunden (Anno-Wiki-Seite „Bank“ nennt keinen Kredit) | Z19 | Lücke |

**Was heißt das für uns?** 3 % je Spielmonat = 36 % p.a. (mit Zinseszins 42,6 %) [R]. Das ist 9- bis 18-fach OpenTTD und 36-fach TF2. Gleich ist die Zahlenfolge 2/3/4 bei unseren geplanten Presets: die Zahl steht, die Einheit hat sich verschoben (Absicht unbekannt). Aussagekräftiger als der Jahressatz ist das Verhältnis zum Ertrag: Unser Break-even liegt bei etwa 12 Spielmonaten, 3 % je Monat fressen also rund ein Drittel der Rendite (Skill: ROI 10 %/min). Zwei Warnungen aus den Quellen: zu billig (TF2) nimmt dem Kredit jede Entscheidung; zu undurchsichtig (RE2) macht Schuld zum Frust. Und: Insolvenz als „Reset mit Narbe“ (RT1, RT3) ist ein Gegenentwurf zum harten Spielende.
**Empfehlung:** Zins 1,5/2/3 % gepaart messen (n = 300, 900 Läufe, Hooks vorhanden), im UI den Satz auch als „je Jahr“ zeigen. Aufwand 0,5 PT.

## 2. Ertrag, Alternativen, Sättigung

| Spiel | Mechanik / Zahl | Quelle | Marke |
|---|---|---|---|
| TF2 | Spielerrechnung Kosten je Kapazität × km/h: Straße 0,31, Schiff 0,36, Luft 0,56, Schiene (Wagen) 0,61; Unterhalt rund 1/6 des Kaufpreises je Jahr | Z11 | [E] Forum WF |
| TF2 | Lkw schlägt Zug bei 1 km, Zug bei 10 km deutlich besser; Straße verstopft bei Masse | Z11 | [E] |
| TF2 | Frühspiel 1850: Schiff am rentabelsten, kurze Schiene schwer profitabel | Z9 | [E] |
| OpenTTD | Lok-Betriebskosten rund 10–13 % des Preises je Jahr | Z8 | [R] aus WF-Tabelle |
| OpenTTD | Stationsbewertung additiv: Tempo (über 85 km/h bis 17 %), Fahrzeugalter (13/8/4 %), Abholabstand (51/37/20/10 %), Wartemenge (16/12/4/0/−14/−35 %), Statue 10 %; Änderung höchstens 2 von 255 je 2,5 Tage | Z5 | [B] WF |
| OpenTTD | Fracht an der Quelle = Rating; unter 50 % Verlust; Kürzung bei Rating ≤ 25 % und über 200 wartend | Z5 | [B] WF |
| OpenTTD | Zahlung hängt an Fracht, Menge, Distanz, Tagen, nicht an der Auslastung des Abnehmers | Z5 | [B] WF |
| Zug:Lkw Community-Zahl | nicht gefunden (Foren gesperrt) | – | Lücke |

**Was heißt das für uns?** Die Kurve „Verfall in Stufen“ gibt es, aber mit **Änderungsrate** (2 Punkte je 2,5 Tage): nichts springt. Unser Sprung 0,4 auf 0,1 bei 150 % hat dort kein Vorbild. OpenTTD hat Sättigung an der Quelle, wir am Abnehmer; das ist eine echte Abweichung, keine Kopie. Zug:Lkw 2,9:1 ist je Fahrzeug gemessen; die Quellen sagen, Schiene gewinnt über Distanz und Menge, nicht je Fahrzeug. Auffällig [R, laut Skill B2]: Lkw-Fixkosten 90 $ auf 400 $ Preis = 22 % je Monat, Referenzen 10–17 % je Jahr. Das ist ein Mietmodell und hält Geld knapp, ist aber nicht mit Referenzen vergleichbar, solange Alter fehlt.
**Empfehlung:** (a) Kante bei 150 % stetig machen (0,4 bei 150 % linear auf 0,1 bei 200 %), 1 Konstante, 0,5 PT. (b) Zug:Lkw zusätzlich als Gewinn je 1.000 $ Invest inkl. Gleis und über Distanzklassen messen, 0,5 PT.

## 3. Konkurrenz und Übernahme

| Spiel | Mechanik | Quelle | Marke |
|---|---|---|---|
| OpenTTD | Bankrotte Firma wird nacheinander den Firmen mit bester Leistungshistorie angeboten (Zeitfenster ein Quartal geteilt durch die Zahl der Bieter, Fahrzeuglimit-Prüfung); Nachschub-KI nach Intervall ±12,5 % | Z6 | [B] WF, Kaufpreis nicht gelesen |
| OpenTTD | Anteile: nur Firmen ab 6 Jahren; KI-Firma ganz kaufbar | Z7 | [B] WF |
| RT1 | Modus „freundlich“ (kein Aufkauf, kein Preiskampf) gegen „Cut-Throat“; Rivale unter 5 $ Kurs wird aufgelöst | Z14 | [B] WF |
| RT3 | Aktienmarkt, Margin-Kauf mit Zins, Short, Fusion über den Aktienbildschirm | Z13 | [B] WF |
| Railway Empire | 100 % Anteile, dann Fusion; Rivale entfällt, Gewinn aus Verkauf seiner Anlagen; früh kaufen, Kurs steigt mit Firmenwert | Z17 | [B] WF |
| Patrician, Industry Giant 2 | keine brauchbare Quelle | – | Lücke |

**Was heißt das für uns?** Interessant machen: sichtbarer Kurs als Gesundheitsanzeige, Zeitfenster („früh kaufen“), geerbter Kredit als Risiko, Wahl freundlich/hart. Nerven: Schuld ohne Rückmeldung (RE2), unsichtbarer Ertragsverlust (Skill K37), KI auf der letzten Quelle (K39 schon geregelt). Aufwand [E, Schätzung, keine Quelle]: Im Slice-Code gibt es keinen Besitzer-Begriff (Grep `owner|besitzer|company_id` in `slice/*.gd`: 0 Treffer [M]). Stufe 0, passiver Marktanteil: steht. Stufe 1, ein geskripteter Rivale mit Insolvenz-Verkauf: 4–6 PT. Stufe 2, Bot als Spielfigur mit Ortswahl und Preiskampf: 15–25 PT.

## 4. Schwierigkeit

| Spiel | Stellschrauben, Presets | Quelle | Marke |
|---|---|---|---|
| OpenTTD Easy/Medium/Hard | Konkurrenten 2/4/7; Kredit £300k/150k/100k; Zins 2/3/4 %; Baukosten niedrig/mittel/hoch; Subventionen ×3/×2/×1,5; Pannen reduziert/normal/normal; Gelände flach/hügelig/gebirgig; Wirtschaft stabil/schwankend/schwankend; Rathaus permissiv/tolerant/feindlich | Z3 | [B] WF, Archiv |
| OpenTTD heute | Defaults: Kredit 300k, Zins 2 (Bereich 2–4), Fahrzeug- und Baukosten 0–2; Presets nicht in der Tabellendatei | Z2 | [B] WF |
| OpenTTD | Rezession (aus): 2–3 je Jahrhundert, 9–12 Monate, Produktion und Passagiere halbiert | Z4 | [B] WF |
| TF2 | Hard: Zins fix, schmalere Margen, Schiffe 2,5-fache Betriebskosten; Spieler: alle Stufen zu leicht; eine Stimme: Unterschied nur Zeit | Z9, Z10, Z12 | [E], widersprüchlich |

**Was heißt das für uns?** OpenTTD koppelt Geld (Kredit ×3, Zins ×2), Kosten und Welt (Gelände, Konkurrenz). Unser Plan hat Kapital ×2 (4.500 bis 9.000 $) und Zins ×2, also schmaler als der Kredithebel dort. TF2-Hard zeigt, dass reine Kostenhebel ohne Zielvorgabe schnell verpuffen. Offizielle TF2-Werte fand ich nicht.
**Empfehlung:** Presets im 500-$-Raster messen (steht), dazu Konkurrenz-Anteil als Preset-Feld (siehe Idee 5). Aufwand 0,2 PT zusätzlich.

## 5. Wartung, Alter, Inflation, Geld-Senken

| Spiel | Senke | Quelle | Marke |
|---|---|---|---|
| OpenTTD | Inflation (aus, 1920–2090): Kosten steigen mit dem Startzins, Fracht etwa 1 Punkt langsamer; Realertrag 61 % (1970), 37 % (2020), 18 % (2090); Kreditrahmen wächst mit | Z4, Z1 | [B] WF |
| OpenTTD | Netz-Unterhalt je Feld (Gleis, Straße, Station), standardmäßig aus; fixe Stationskosten monatlich | Z4, Z1 | [B] WF |
| TF2 | Unterhalt ≈ 1/6 Preis je Jahr; Infrastruktur getrennt; Alter verteuert nicht mehr (durch Emissionen ersetzt), Spieler halten Kosten für zu niedrig | Z10, Z11 | [E] |
| Cities: Skylines II | auslaufende Subvention, exponentielle Meilenstein-XP | Skill A4/A6 | [B] |
| Railway Empire 2 | Anleihen erneuern sich, Zins läuft auf | Z16 | [B] WF |

**Was heißt das für uns?** Kein gelesener Text nennt eine Zielgröße, „wie viel Senke“ nötig ist; das bleibt unsere Messung. Die Referenzen, die das Mittelspiel tragen, skalieren die Kosten mit dem Netz (Unterhalt je Feld) oder mit der Zeit (Inflation), nicht mit dem Fahrzeug. Hypothese [R]: Kassenreserve (Kasse geteilt durch monatliche Fixkosten) über 12 Monate in Minute 120 heißt „Senke fehlt“.
**Empfehlung:** Skriptspieler auf 120 Minuten mit Reservekurve, Gleisunterhalt als Hebel (G-01 Frage 4) in 3 Werten. Aufwand 1 PT.

## 6. Eigene Ideen (Hirnen), mit Jonas' Entscheid

| # | Idee | Zielperson | Kosten | Billigster Test | Risiko | Jonas: Sprint 8? |
|---|---|---|---|---|---|---|
| 1 | Sättigung stetig mit Tail bis 200 % | Tüftler, kleine Orte | 0,5 PT | gepaarter Bot n=300, Slice und Welt | Bankrott bei kleinen Senken steigt | Ja |
| 2 | Zins-/Kapitalraster 1,5/2/3 % × 500-$-Schritte | Einsteiger (Leicht), Profis (Schwer) | 0,5–1 PT | Hooks, 900 Läufe | Bot-Kreditverhalten ≠ Mensch | Ja, nur Messung |
| 3 | Gleisunterhalt je Feld als Senke | Langspieler (41 h) | 1 PT | Skriptspieler 120 min, 3 Werte | Zug:Lkw kippt unter 2:1 | Ja, nur Messung |
| 4 | Mini-Firmenkauf: Rivale pleite, Kauf zum Restwert plus Kreditübernahme | Expansions-Spieler | 4–6 PT [E] | Skript-Event, Bot kauft immer | Schneeballeffekt; Besitzer-Feld fehlt | Nein, Spec |
| 5 | Konkurrenz „freundlich/hart“ als Preset-Feld (0/10/15/20 %) | alle | 0,2 PT | Bot, 4 Stufen | Platzhalter bleibt Platzhalter | Ja, nur Datenfeld |

## Jonas: Umfang

Ideen 1 bis 3 und 5 sind Messungen oder Konstanten und passen in die bestehende Empfehlung 2 und 3 von Tobias (zusammen etwa 3 PT). Der Firmenkauf ist dreimal verschoben (Zähler 3): nach meiner eigenen Regel entscheide ich jetzt. Basti will ihn, also **bauen, aber nur Stufe 1 und erst in S9**, im Tausch gegen einen der Punkte E8/E10/E11/E14/E15, den Basti benennt. In S8 bekommt er nur eine Spezifikation und einen ADR-Eintrag mit Ablaufdatum; ohne Besitzer-Feld ist jede Schätzung höher als 6 PT unsicher.

## Neue Lern-Zeilen

| Datum | Situation | Lücke | Folge |
|---|---|---|---|
| 2026-11-03 | Zinsvergleich | OpenTTD-Zins ist p.a., monatlich 1/12 (Z1), auch negative Kasse | Skill A4 mit Einheiten ergänzen [B] |
| 2026-11-03 | Presets | OpenTTD-Preset-Tabelle nur im Archiv-Wiki (Z3), im Quellcode-Auszug nicht; TF2-Werte fehlen | als [E]/Version unsicher führen |
| 2026-11-03 | Sättigung | OpenTTD: Rating mit Änderungsrate, keine Abnehmer-Sättigung | Idee 1 als Test, nicht als Entscheid |
| 2026-11-03 | Kosten | Lkw-Fixkosten 22 % des Preises je Monat gegen 10–17 % je Jahr | Alter/Unterhalt vor Kalibrierung klären |
| 2026-11-03 | Firmenkauf | Slice kennt keinen Besitzer (Grep, 0 Treffer) | Datenmodell vor jeder Schätzung |
| 2026-11-03 | Zug:Lkw | Community-Verhältnis nicht auffindbar | Messung je 1.000 $ Invest statt Quellenvergleich |

## Vorschläge für Skill-Änderungen (nur Vorschläge)

- A4: Zinsformel (Jahressatz/12, auch negative Kasse) und Tabelle Zins p.a./je Monat aufnehmen; Presets mit „Archiv, Version unsicher“.
- A2/A3: Stationsbewertung (Stufen plus Änderungsrate) als Vorbild für stetige Kurven.
- A9: Punkt „Zug:Lkw auch je 1.000 $ Invest messen“.
- A10: Fehler „Zins ohne Einheit übernommen“ (2/3/4 % p.a. gegen je Monat).
- D: Quellenmarke „WF“ für Kleinmodell-Zusammenfassungen.

## Quellen

Z1 https://raw.githubusercontent.com/OpenTTD/OpenTTD/master/src/economy.cpp · Z2 .../src/table/settings/difficulty_settings.ini · Z3 https://wiki.openttd.org/en/Archive/Manual/Settings/Difficulty · Z4 https://wiki.openttd.org/en/Manual/Economy · Z5 https://wiki.openttd.org/en/Manual/Game%20Mechanics/ · Z6 .../src/company_cmd.cpp (raw, teilweise) · Z7 https://wiki.openttd.org/en/Archive/Manual/Settings/Allow%20shares · Z8 https://wiki.openttd.org/en/Manual/Base%20Set/Trains/Train%20Comparison · Z9 https://gameplay.tips/guides/9066-transport-fever-2.html · Z10 https://steamcommunity.com/app/1066780/discussions/0/1740010344366988160 · Z11 https://steamcommunity.com/app/1066780/discussions/0/3783625216798366301 · Z12 https://steamcommunity.com/app/1066780/discussions/0/1740012510025229119 · Z13 https://strategywiki.org/wiki/Railroad_Tycoon_3/Gameplay · Z14 https://freerails.readthedocs.io/en/latest/specification_rt1.html · Z16 https://steamcommunity.com/app/1644320/discussions/3/3810657811763928745 · Z17 https://www.gamepressure.com/railway-empire-guide/research-bonds-and-acquiring-competitors/z0aa86 · Z19 https://anno1800.fandom.com/wiki/Bank
