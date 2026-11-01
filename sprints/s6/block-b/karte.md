# Sophie, Sprint 6 Block B: D24 Werkzeugfabrik-Verschiebung (Freeze-Ausnahme Jonas)
Arbeitskopie: karte/slice (Kopie vor Änderung: karte/slice_map.before_d24.json). Messungen sind Modellrechnung.

## Karte
- werkzeug_1: (193,258) -> **(133,216)**, Quadrant SW -> NW. Nur diese Zeilen geändert: x/y, Kette stahl_1->werkzeug_1 60 -> **34**, werkzeug_1->mittelfurt 204 -> **259**, status.version "+D24", status.hinweis ergänzt. hq_optionen unverändert (werkzeug_1 steht schon bei Kohlberg). Zeilenweise editiert, restliche Formatierung identisch.
- Distanzen: Stahlwerk 33,8 (Soll <= 35), Kohlberg 33,0 (Soll <= 42, HQ-Radius 50), Kraftwerk 49,0, Mittelfurt 259.
- Warum NW: Stahlwerk <= 35 Felder liegt zwangsläufig nördlich der Quadrantengrenze y=256 (Stahl y=205). Quadranten jetzt NW 6 / NO 5 / SW 4 / SO 5 = 30/25/20/25 %, check_s10 grün (Rand der Toleranz 20-30 %, wie in S-10).
- Position gewählt gegen Label-Überlappung (Zoom 9, Screenshots karte/shots/d24c_kohlberg.png): (195,216) ergab Überlappung mit Kraftwerk-Label, (138,221) Berührung mit Kohlberg-Symbol; (133,216) frei, Label endet knapp vor dem Kohlberg-Symbol. Gelände (Gebirge/Wald/Meer/Fluss) nicht betroffen.

## Prüfungen
- Validator Exit 0 (jsonschema + Fallback), check_s10 Exit 0, Fluss-Schnitt (s11_test) grün, s11_test 16/16.
- ACHTUNG Validator: slice_map.schema.json verlangt noch hq_optionen[].startkapital_cent, die Karte (md5 d99eb305, Felix' Merge) hat das Feld nicht mehr; Validator war schon vor D24 rot (Exit 1). Ich habe das Schema nur im Prüfwerkzeug (karte/tools/) angepasst, slice/data/slice_map.schema.json NICHT. Coordinator: Schema im Repo nachziehen.
- tests/s11_test.gd angepasst: "Werkzeugfabrik 38-42 von Kohlberg" -> "<= 42" plus neue Prüfung Stahlwerk->Werkzeugfabrik <= 35.

## Nachmessung (6.000 $, Kredit-Mix, je 300 Läufe, Seeds 1-300 / 301-600; Skript karte/t14d24/t14d24_nachmessung.py, Log t14d24_log.txt)
| Standort | Bankrott | M7 Median (Quartile) | Urteil |
|---|---|---|---|
| Kohlberg (Stahl->Werkzeug 34) | 11,3 / 13,7 % | 38 / 36 min (25-55) | ja / im Band 35-50 (vorher 24 min) |
| Haberau | 10,7 / 13,3 % | 49 / 48 min | ja / im Band |
| Mittelfurt (Farm 28) | 14,0 / 15,0 % | 52 / 52 min | ja / Toleranzband (<= 57,5), unverändert zu T-14b; Kontrolle Farm 78: 19,3 %, 43 min |
Sweep Kohlberg Stahl->Werkzeug 30/34/35/42: M7 43/37/37/31 min. Das Modell nutzt nur Stahl->Werkzeug, nicht Werkzeug->Kohlberg.

## hq_vorschau
Neu erzeugt (md5 953b00d3de5bd2c8f5b0bc92f451f5cb). Abweichungen zu vorher: Quellen-md5; Kohlberg Werkzeugfabrik 33 (vorher 40), Absatz Mittelfurt 259 (204); Mittelfurt Werkzeug 259; Lindach nächste Werkzeugfabrik 111, Lizenzfaktor x2,4 (Werkzeugfabrik) statt x3,2 (Erzmine); Weidenau Werkzeugfabrik 176, x4,2 (173, x4,1); Seehafen Werkzeug fällt aus den ersten drei (Kraftwerk 245 statt Werkzeugfabrik 204).

## Regression und md5
- d07_regression.sh: **GRÜN**, Exit 0 (slice_test soa/alt 72/72, parity 8/8, ui 30/30, kredit 16/16, parity 12/12, lager 2/2, Spikes, statisch). Zwei frühere Läufe rot nur durch Sandbox-Last (parity Sim-Tick 3,7 ms, A21 Slide 230 ms, andere Agenten liefen parallel); Wiederholung grün.
- **data/slice_map.json md5 718e062cd554b6a3c80460b33f088c8a** (vorher d99eb305afc23db4832bcb7ce6c857e0). data/hq_vorschau.json md5 953b00d3de5bd2c8f5b0bc92f451f5cb.
