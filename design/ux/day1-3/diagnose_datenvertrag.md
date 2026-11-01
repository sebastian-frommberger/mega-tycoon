# Diagnose-Datenvertrag "Meldung" v0.1 (Spike A-05)

Autorin: Aylin Kaya · Stand: Entwurf · **Nicht von Felix bestätigt.** Die Spalte "Felix" ist eine Annahme aus `concept/felix.md` und `plan/felix.md`, bis das Pairing (17.11. vormittags) stattgefunden hat. In `day1-3/felix.md` und `day1-3/felix/` lag beim Schreiben nichts.

Geltung: nur Spike und Playtest-Build (F-04, F-06), 3 Testfehler. Nicht enthalten: Bündelung, Schweregrad-Logik, klickbare Vorschlags-Aktionen, Live-Aktualisierung.

## Grundregeln

1. **Die Sim liefert IDs, Codes und Parameter, keine Texte.** Die Texte stehen in `textvorlagen_testfehler.md` und gehören der UI (Lokalisierung, +30 % Platz für EN).
2. **Die Meldung ist ein Schnappschuss** (`erstellt_tick`). Sie ändert sich nicht, während der Tester sie liest. Das macht die Messung stabil. Im Produkt wird sie live.
3. **Zeit in Ticks** (10 Hz laut Felix). Die UI rechnet in mm:ss um: `(jetzt_tick - seit_tick) / 10`.
4. **Reihenfolge der Kette:** Symptom zuerst, Wurzelursache zuletzt. Jedes Glied hat einen Ort.
5. **Pflichtfeld fehlt = Meldung wird nicht angezeigt und ein Vertragsfehler ins Log geschrieben.** Das setzt "Ort, Ursache, Vorschlag oder keine Meldung" technisch durch.

## Feldtabelle

P = Pflicht, O = optional. Koordinaten: Annahme ganze Millimeter (x, z) wie die Sim-Position, die UI rechnet um. Das ist eine Frage an Felix.

| Feld | Typ | P/O | Beispielwert | Felix (Annahme) |
|---|---|---|---|---|
| **Rahmen** | | | | |
| `meldung_id` | int | P | `17` | liefert |
| `symptom_typ` | enum `FAHRZEUG_STEHT` | P | `"FAHRZEUG_STEHT"` | liefert |
| `seit_tick` | int | P | `12060` (Beginn des Stillstands) | liefert, ist abgeleitet |
| `erstellt_tick` | int | P | `12190` | liefert |
| `schweregrad` | enum `KRITISCH`/`WARNUNG`/`HINWEIS` | O (Spike: nicht angezeigt) | `"KRITISCH"` | fehlt wahrscheinlich, UI kann aus Wartezeit ableiten |
| `buendel_key` | string | O (Spike: ungenutzt) | `"LINIE_4:LADUNG"` | fehlt, kommt mit S3 |
| **ORT** (Sprungziel der Meldung) | | | | |
| `ort.pos` | `[int x, int z]` mm | P | `[412000, 118500]` | liefert (F-04: "Koordinaten") |
| `ort.objekt_typ` | enum `ZUG`/`SIGNAL`/`ABSCHNITT`/`STRECKE`/`LAGER`/`HALT` | P | `"ZUG"` | liefert |
| `ort.objekt_id` | int | P | `4` | liefert |
| `ort.kante_id` + `ort.kante_offset_mm` | int, int | O | `233`, `5400` | liefert (Sim kennt Kante und Fortschritt) |
| Regel | `ort` ist gleich `kette[0]` (Symptom-Ort), der Validator prüft das | | | |
| **URSACHE** (Wurzelursache) | | | | |
| `ursache.typ` | enum `LADUNG`/`INFRASTRUKTUR`/`GELD`/`NACHFRAGE` | P | `"LADUNG"` | liefert (F-04: "Wurzelursache-Typ"); Kategorien aus `concept/aylin.md`, **offen bei Tobias** |
| `ursache.code` | enum, siehe unten | P | `"ZULIEFERUNG_ZU_GERING"` | liefert für die 3 Testfehler, sonst offen |
| `ursache.objekt_typ`, `ursache.objekt_id` | enum, int | P | `"LAGER"`, `9` | liefert |
| `ursache.pos` | `[int, int]` mm | P | `[655000, 301200]` | liefert |
| `ursache.params` | Dictionary | P je Code | `{"fuell_ist":12,"fuell_soll":40,"n_lkw":1}` | **offen:** Lagerfüllung und Lkw-Anzahl sind Wirtschaftsdaten, kein Netz |
| **KETTE** | | | | |
| `kette` | Array von Gliedern, 2 bis 8 | P | siehe Beispiel | liefert (`get_wait_chain()`) |
| `kette[i].rolle` | enum `SYMPTOM`/`ZWISCHEN`/`WURZEL` | P | `"ZWISCHEN"` | liefert (Erster ist Symptom, Letzter Wurzel) |
| `kette[i].relation` | enum, siehe unten | P | `"ABSCHNITT_BELEGT_VON"` | liefert (Signal, Block, Halter) |
| `kette[i].objekt_typ`, `.objekt_id` | enum, int | P | `"ZUG"`, `7` | liefert |
| `kette[i].pos` | `[int, int]` mm | P | `[498200, 240100]` | liefert |
| `kette[i].params` | Dictionary | O | `{"signal":21,"abschnitt":22}` | liefert |
| `kette_kreis` | bool | P | `false` | liefert (Zykluserkennung) |
| `kette_kreis_zurueck_zu` | int (Index) | P, wenn `kette_kreis` | `0` | liefert |
| `kette_stand_tick` | int | P | `12190` | liefert |
| `kette_gekuerzt` | bool | O | `false` | fehlt, bei max. 8 Gliedern nicht nötig |
| **VORSCHLAG** | | | | |
| `vorschlaege` | Array von 1 bis 3 | P (mind. 1) | siehe Beispiel | **fehlt:** Sim kennt keine Aktionen. Im Spike ordnet die UI per Tabelle `ursache.code` zu Aktion zu. |
| `vorschlaege[i].aktion` | enum `AUSWEICHGLEIS_BAUEN`/`LKW_HINZUFUEGEN`/`MINDESTBELADUNG_SENKEN`/`ZUG_UMLEITEN`/`SIGNAL_SETZEN` | P | `"LKW_HINZUFUEGEN"` | UI |
| `vorschlaege[i].ziel_objekt_typ`, `.ziel_objekt_id`, `.ziel_pos` | enum, int, `[int,int]` | O | `"LAGER"`, `9` | liefert über `ursache` |

**Codes `ursache.code` (Testfehler):** `EINGLEISIG_GEGENVERKEHR` (Typ INFRASTRUKTUR) · `KREIS_BLOCKIERUNG` (Typ INFRASTRUKTUR, `kette_kreis=true`) · `ZULIEFERUNG_ZU_GERING` (Typ LADUNG).

**Relationen `kette[i].relation`:** `STEHT` (nur Glied 0) · `WARTET_AN_SIGNAL` · `ABSCHNITT_BELEGT_VON` · `ABSCHNITT_BELEGT_VON_GEGENZUG` · `WARTET_AUF_ZUG` · `WARTET_AUF_LADUNG` · `WIRD_BELIEFERT_VON` · `STRECKE_EINGLEISIG` · `KREIS_SCHLUSS`.

## Prüfregeln (Vertragsvalidator, Vorschlag für F-04-Headless-Test)

V1 Alle P-Felder vorhanden und typrichtig · V2 `kette[0].rolle=SYMPTOM`, `kette[-1].rolle=WURZEL` · V3 `kette[-1].objekt_id == ursache.objekt_id` · V4 `ort == kette[0]` · V5 bei `kette_kreis` liegt `kette_kreis_zurueck_zu` im Indexbereich · V6 `vorschlaege` hat mindestens 1 Eintrag · V7 jedes Glied hat `pos`.

## Beispiel (Fehler 3, Warten auf Ladung)

```json
{
  "meldung_id": 17, "symptom_typ": "FAHRZEUG_STEHT",
  "seit_tick": 12060, "erstellt_tick": 12190,
  "ort": {"pos": [498200, 240100], "objekt_typ": "ZUG", "objekt_id": 10},
  "ursache": {"typ": "LADUNG", "code": "ZULIEFERUNG_ZU_GERING",
              "objekt_typ": "LAGER", "objekt_id": 9, "pos": [655000, 301200],
              "params": {"fuell_ist": 12, "fuell_soll": 40, "n_lkw": 1}},
  "kette": [
    {"rolle":"SYMPTOM","relation":"STEHT","objekt_typ":"ZUG","objekt_id":10,"pos":[498200,240100]},
    {"rolle":"ZWISCHEN","relation":"WARTET_AN_SIGNAL","objekt_typ":"SIGNAL","objekt_id":21,"pos":[501000,241000],"params":{"abschnitt":22}},
    {"rolle":"ZWISCHEN","relation":"ABSCHNITT_BELEGT_VON","objekt_typ":"ZUG","objekt_id":7,"pos":[520000,244000],"params":{"abschnitt":22}},
    {"rolle":"ZWISCHEN","relation":"WARTET_AUF_LADUNG","objekt_typ":"LAGER","objekt_id":9,"pos":[655000,301200],"params":{"fuell_ist":12,"fuell_soll":40}},
    {"rolle":"WURZEL","relation":"WIRD_BELIEFERT_VON","objekt_typ":"LAGER","objekt_id":9,"pos":[655000,301200],"params":{"n_lkw":1}}
  ],
  "kette_kreis": false, "kette_stand_tick": 12190,
  "vorschlaege": [
    {"aktion":"LKW_HINZUFUEGEN","ziel_objekt_typ":"LAGER","ziel_objekt_id":9},
    {"aktion":"MINDESTBELADUNG_SENKEN","ziel_objekt_typ":"ZUG","ziel_objekt_id":7}
  ]
}
```

Alle Zahlen sind erfundene Beispielwerte zur Illustration, keine Messwerte.

## Pairing-Checkliste für Felix (17.11. vormittags, ca. 3 h)

Ziel: je Zeile der Feldtabelle `liefert` / `fehlt` / `liefert anders`, eingetragen in die Spalte "Felix". Ohne Antwort bleibt die Zeile "Annahme".

| Nr | Frage | Antwort Felix |
|---|---|---|
| 1 | Liefert `get_wait_chain(vehicle_id)` pro Glied Objekttyp, ID und Position, wie in der Tabelle? | |
| 2 | Koordinatenformat: ganze mm (x, z) oder Kante plus Offset? Welches kann die UI direkt für den Kamerasprung nutzen? | |
| 3 | Wie sieht der Kreis aus: eine Liste der Mitglieder plus Rückverweis, oder ein eigenes Objekt? | |
| 4 | Wo steckt `Ladung` (Lagerfüllung ist/soll, Anzahl Lkw je Lager): in `get_wait_chain()` oder eine zweite Abfrage? Reicht das für die Wurzelursache? | |
| 5 | Wer liefert Anzeigenamen (Zug 4, Lager Hafen-Ost, Strecke Mühlbach–Kornfeld)? Annahme: eine Namenstabelle in der Testszene, Schlüssel ist die `objekt_id`. | |
| 6 | Beginn des Stillstands (`seit_tick`) abfragbar? | |
| 7 | Schnappschuss bei Klick ausreichend und bis zum Schließen stabil? | |
| 8 | UI-Klicks ins Log (Meldung geöffnet, Zeile geklickt, Sprung, jeder andere Klick mit Ziel, jeweils Zeit in ms): im Replay oder als eigene Datei? Der Replay enthält sonst nur Sim-Befehle. | |
| 9 | Kann der Validator V1 bis V7 im Headless-Test laufen (Exit 0)? | |
| 10 | Dauer des Stillstands: bleibt jeder der 3 Fehler mindestens 120 s sichtbar stehen? (Fehler 1 löst sich im Normalfall von selbst, das Szenario muss das verhindern.) | |
