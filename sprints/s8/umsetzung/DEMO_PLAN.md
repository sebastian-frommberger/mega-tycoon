# DEMO_PLAN: Demo-Sprint "30 Minuten am Stück" (Lead, 10.11.2026)

Ziel: Basti startet `--demo`, spielt 30 min (1820 → 1830, 3 min je Jahr) und hat in jeder Minute eine sinnvolle, bezahlbare Aktion.
Alles Neue läuft nur im Demo-Modus (`proto/demo_sim.gd` erbt von `proto_sim.gd`, Daten `data/demo_welt.json`); Slice und die S8-Welt ohne `--demo` bleiben bitgleich.

## Entscheidungen (Details im entscheidungslog.md)
- **Tempo k = 8, Satz k8d** (6.000 $ Start; OE-03: Plan-Bankrott 0/100, Kassentief 1.432 $). k = 4 braucht 4.000 $ Start und war 4/20 bankrott ohne Satz; k = 6 hat keinen gemessenen Satz.
- **Kalender bleibt 3 min/Jahr.** Die Demo zieht Freischaltungen vor ("Demo-Zeitraffer", historisch falsch, im UI so benannt): Planwagen 1822, Pferdebahn + Gleis 1824, Frachtwagen 1826, Dampflok 1828.
- **Drei Ketten** auf der Proto-Karte, 6 neue Betriebe: Nahrung (Bestand), Holz → Sägemühle → Bretter, Kohle + Erz → Eisenhütte → Eisen → Hammerschmiede → Werkzeug. Jedes Gut hat Quelle und ≥ 1 Abnehmer.
- **Bauen**: Straße (Feldweg) und Gleis als Linienzug aus Klickpunkten; Enden rasten an Netzknoten, Betriebe (Anschlusspunkt) bzw. Bahnhöfe ein. Vier der neuen Betriebe liegen abseits des Netzes: ohne Bauen keine Kette.
- **HQ**: zuerst platzieren (frei innerhalb eines Orts, Vorschau: Betriebe im Radius, Lizenzpreise, Heimatort-Bonus), 3 Stufen + 3 Anbauten.
- **Skilltree**: 3 Äste × 4 Knoten, Punkte nur aus Meilensteinen (12 Meilensteine, im Plan ca. 9–10 Punkte in 30 min), Respec frei.
- **Verträge**: alle ~2 min ein Angebot (Ort/Betrieb, Gut, Menge, Frist, Prämie, Strafe), max. 3 aktiv, Ruf verändert Prämien.

## Spielbogen (Plan, Minute = Spielminute bei 1×)
| Min | Jahr | Was Basti tun kann | Schaltet frei / Punkte |
|---|---|---|---|
| 0 | 1820 | Startbild, **Firmensitz platzieren** (Erlenbach, Lindenfurt oder Hasenwinkel), Gratis-Lizenz | M1 HQ +1 SP |
| 0–3 | | Lizenz Gut Kuppenhof, Linie Farm → Mühle → Erlenbach, erster Skill | M2 erste Mehl-Lieferung +1 |
| 2–6 | 1821 | erstes Vertragsangebot (Mehl Erlenbach), 2. Fuhrwerk, Lindenfurt anbinden | M3 erster Vertrag erfüllt +1 |
| 5–9 | 1822 | **Straße bauen** zum Forsthaus, Holz → Sägemühle → Bretter; **Planwagen** (Ersetzen) | M4 erste Straße +1, M5 Bretter +1 |
| 9–12 | 1823 | Hof Hasenwinkel, HQ-Anbau (Remise/Kontor/Stall), Verträge Bretter | M6 3 Verträge +1 |
| 12–15 | 1824 | **Gleis frei**: Kohlegrube → Eisenhütte per Pferdebahn; Kredit ab Min 12 | M7 erster Zug +1 |
| 14–18 | 1825 | Mühle kaufen (C1), Werksausbau; Erzgrube per Gleis; Eisen → Schmiede | M8 Firmenkauf +1 |
| 18–22 | 1826 | **Frachtwagen** (Ersetzen), Werkzeug → Lindenfurt, HQ Stufe 2 | M9 Werkzeug +1, M10 HQ 2 +1 |
| 22–26 | 1827 | Sägemühle/Hütte kaufen, zweite Abnehmer gegen Sättigung, große Verträge | M11 Netto ≥ 800 $/min +1 |
| 24–30 | 1828 | **Dampflok** ersetzt Pferdebahn, Gleis verlängern, HQ Stufe 3, letzter Skill | M12 Dampflok +1 |

## Aktionsbudget (Zählweise des Demo-Bots)
Aktion = Bauen (Straße/Gleis), Kaufen (Lizenz, Fahrzeug, Firma), Ausbau (Werk, HQ, Anbau), Vertrag (annehmen), Skill (setzen), Ersetzen.
Gate A: in jedem 60-s-Fenster ≥ 1 Aktion "verfügbar und bezahlbar" (Kasse ≥ Preis, Voraussetzung erfüllt, bringt etwas), kein Fenster > 2 min ohne.
Erwartung: ~45–60 ausgeführte Aktionen in 30 min (Bot), also 1,5–2 je Minute.

## Abhängigkeiten und Reihenfolge
1. Daten + `economy.apply_demo` (Güter, Betriebe, Körbe) → 2. `demo_sim.gd` (Start, HQ, Bau, Zug, Generationen, Verträge, Skills, Meilensteine) → 3. Tests + Ketten-Validator → 4. Demo-Bot + Kalibrierung → 5. UI (`ui_demo.gd`: Werkzeugleiste, Baumodus, HQ-Vorschau, Vertragskarten, Skillbaum, Startbild) → 6. Screenshots, Regression, Anleitung, Merge.

## Schnitt (nicht in der Demo)
Speichern, Signale/Blockstrecken (ein Zug je Fahrt, Züge blockieren sich nicht), Personen, Konkurrenz, freier Abriss, Weichenbild, Brückenwahl (Brücke entsteht automatisch über Wasser, teurer), Esc-Bestätigung nur falls blockierend.

## Nachtrag 10.11.: Erweiterung um Punkte 7–11
Reihenfolge: (1) Fahrgäste + Haltestellen, (2) Linienpläne mit mehreren Halten, (3) Depots, Fahrzeugliste, Verkauf, (4) Personenzüge und Stadtfahrzeuge, (5) Streckenhandel. Im Spielbogen: Stadtlinie ab Minute 2–4 (Stadtkutsche), Depot ab Minute 7, Omnibus Minute 15, Personenzug ab Minute 19 (Gleis Erlenbach – Hasenwinkel), Chaussee-Kauf spät (2.800 $). Entscheidungen im Entscheidungslog, Messung in DEMO.md.
