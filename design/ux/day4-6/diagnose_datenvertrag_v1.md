# Diagnose-Datenvertrag "Meldung" v1 (A-05, nach D9)

Autorin: Aylin Kaya · Stand 19.11.2026, nach Pairing-Termin 10:00 · ersetzt `day1-3/aylin/diagnose_datenvertrag.md` (v0.1).

**Quellenlage, ehrlich:** `day4-6/felix/pairing_antworten.md` und `day4-6/felix.md` existieren nicht. Felix' Antwort liegt stattdessen als Code vor: `day4-6/felix/spike/` (Kopfkommentar "Stand 19.11. (D9)") setzt D9 um und ändert `diagnostics.gd`, `sim_world.gd`, `scenarios.gd`; `test_output.txt` ist ein echter Lauf (Godot 4.4.1, Exit 0) mit Validator-Zeilen. Die Spalte "Stand" unten ist **aus diesem Code und der Testausgabe gelesen**, nicht von Felix per Datei bestätigt. Jede Zeile trägt **geliefert** (im Code, in `test_output.txt` sichtbar), **fehlt** (nicht im Code) oder **Annahme** (mein Vorschlag, Felix bestätigt bis 20.11., 12:00 laut D9). Lenas `l06_fehler_final.md` wurde gegen den alten Spike geschrieben (sie vermerkt "byte-identisch"); wo sie und der neue Spike auseinanderliegen, steht es in Abschnitt 4.

Geltung: Spike F-04, Testbuild F-06, Playtest L-06, drei Testfehler. Nicht enthalten (D9): Geld, Nachfrage, Bündelung, Schweregrad-Logik, klickbare Vorschläge.

## 1. Grundregeln (geändert gegenüber v0.1)

1. **Ein Namensraum für Ursache-Codes = Felix' Sim-Enum** (D9): `DEADLOCK`, `EINGLEISIG_GEGENVERKEHR`, `WARTEN_AUF_LADUNG`, `BLOCK_BELEGT_UNTERWEGS`, `KEINE`. Meine Codes aus v0.1 (`KREIS_BLOCKIERUNG`, `ZULIEFERUNG_ZU_GERING`) sind gestrichen. Die UI leitet Typ, Textschlüssel und Vorschlag per Tabelle ab (Abschnitt 3).
2. **Die Sim liefert Codes, IDs, Namen und Parameter, keine Texte.** Texte: `textvorlagen_testfehler_v1.md`.
3. **Kanonischer Ort (D9):** `root_pos == links[-1].pos`. Das letzte Glied ist seit 19.11. ein eigenes Glied `kind = URSACHE`, `rolle = WURZEL`, mit `pos = root_pos`, `code`, `params`. Für einen Zyklus ist `root_pos` für alle Mitglieder (und Auffahrer dahinter) gleich (Felix `cycle_root()`, belegt in `test_output.txt` S2b: "alle 6 Mitglieder: gleicher root_pos").
4. **Schnappschuss:** Die UI ruft `get_wait_chain(vehicle_id)` beim Öffnen der Meldung einmal auf und friert das Ergebnis bis zum Schließen ein. Pull-API reicht. Dass der Stillstand ≥ 120 s bestehen bleibt, ist Sache der Testszene (Lena, Abschnitt 3 ihres Szenarios).
5. **Zeit in Ticks, 10 Hz** (`SimWorld.TICK_HZ`), UI rechnet in `m:ss` um. **1 Feld = 10 m** (`Diagnostics.FELD_MM = 10000`, Sophies Maßstabsband).
6. **Koordinaten:** `Vector2i` in mm, laut Felix' Kopfkommentar "x und z der Karte" (`pos.y` ist die Karten-Z-Achse). Meine v0.1-Schreibweise `(x, z)` ist damit bestätigt.
7. **Pflichtfeld fehlt = Meldung wird nicht angezeigt, Vertragsfehler ins Klick-Log.** Sim-seitig gibt es jetzt `Diagnostics.validate(chain)` (leeres Array = gültig); die UI ruft ihn vor jeder Anzeige auf.

## 2. Feldtabelle: Rückgabe von `get_wait_chain()` und Zusatzfelder

| UI-Feld (v0.1) | Sim-Feld (Felix' Namen, 19.11.) | Typ | P/O | Stand | Beleg / Annahme |
|---|---|---|---|---|---|
| `meldung_id` | vergibt die UI (laufende Nummer je Session) | int | P | UI | nicht Sim |
| `symptom_typ` | immer `FAHRZEUG_STEHT` | – | – | UI | jede Meldung ist ein stehendes Fahrzeug |
| `ort.objekt_id` | `vehicle_id` | int | P | **geliefert** | `diagnostics.gd` |
| `ort.pos` | `links[0].pos` | Vector2i | P | **geliefert** | Glied 0 = `FAHRZEUG`, `role=ANFRAGE`, `rolle=SYMPTOM`; Validator V4 prüft es |
| Anzeigename Fahrzeug, Lager, Knoten | `links[i].name`, `graph.nodes[id].name` | String | P | **geliefert, Testnamen teilweise** | S3 heißt jetzt "Zug 7", "Zug 10", "Lkw 1", "Lager Hafen-Ost" (`scenarios.gd`). S1 ("Zug 1/2", Knoten A–D) und S2 ("Zug 0–3", N0–N3) tragen noch Spike-Namen. **Annahme:** Umbenennung auf Zug 4/2 und Zug 5/8/6/9 in der F-06-Szene. |
| Streckenname (F1, `{strecke}`) | – | String | P bei F1 | **fehlt** | Kanten haben in `net_graph.gd` keinen Namen. **Annahme:** UI bildet "{Knoten a}–{Knoten b}" aus `params.kanten[0]`; F-06-Szene nennt die Knoten "Mühlbach" und "Kornfeld". |
| `seit_tick` | `wait_since_tick` | int | P | **geliefert** | neu am 19.11.; `wait_ticks` zusätzlich |
| `erstellt_tick` | `sim.tick_count` beim Aufruf | int | P | **geliefert** | UI liest ihn beim Schnappschuss |
| `ursache.code` | `root_cause` | Enum (5) | P | **geliefert** | |
| `ursache.typ` | abgeleitet (Abschnitt 3a) | – | – | UI | D9 |
| `ursache.pos` | `root_pos` | Vector2i | P | **geliefert, kanonisch** | `test_output.txt` S1: Zug 1 und Zug 2 beide (400000,0); S2b alle 6 gleich. Validator "V3/D9" grün. Regel: ganzzahliger Mittelpunkt der umkämpften Block-Mitten (Abschnitt 4). |
| `ursache.objekt_typ`, `.objekt_id` | `root_obj.kind`, `.id` (= `links[-1].obj_kind`, `.id`) | Enum, int | P | **geliefert** | BLOCK mit kleinster ID bei Zyklen, LAGER bei Ladung |
| `kette` | `links` | Array | P | **geliefert** | 4 bis 19 Glieder in den Testfällen, letztes immer `URSACHE` |
| `kette[i].objekt_typ` | `links[i].kind` ∈ FAHRZEUG, SIGNAL, BLOCK, LAGER, INDUSTRIE, URSACHE | Enum | P | **geliefert** | ABSCHNITT = BLOCK, STRECKE = Kante |
| `kette[i].objekt_id`, `.pos` | `links[i].id`, `.pos` | int, Vector2i | P | **geliefert** | V7 im Sim-Validator |
| `kette[i].rolle` | `links[i].rolle` ∈ SYMPTOM, ZWISCHEN, WURZEL | Enum | P | **geliefert** | neu am 19.11., V2 prüft es |
| `kette[i].relation` | abgeleitet aus Glied-Abfolge (Abschnitt 3b) | – | – | UI | kein Sim-Feld nötig |
| Gegenrichtung je Block | `links[BLOCK].holder_fwd`, `.wanted_fwd` | bool | P bei F1 | **geliefert** | unterscheidet `R_HALTER` von `R_HALTER_GEGEN` |
| `kette_kreis` | `is_deadlock` | bool | P | **geliefert** | |
| Mitglieder des Kreises | `cycle` | Array[int] | P bei Kreis | **geliefert** | V5: jedes Mitglied in `links` |
| `kette_kreis_zurueck_zu` | Index des ersten Glieds mit `id == cycle[0]` | int | P bei Kreis | UI | aus `cycle` und `links` |
| `in_cycle` | `in_cycle` | bool | O | **geliefert** | false = Auffahrer (S1b, D3) |
| **`params.fuell_ist`** | `params.fuell_ist` (= `stock`) | int | P bei F3 | **geliefert** | `test_output.txt` S3: `fuell_ist: 2` bei Tick ~300; der Wert wächst durch den Lkw (1 Einheit je ~100 Ticks). Lenas "12" ist Platzhalter; bei ≥ 120 s Stillstand liegt er im Spike-Layout rechnerisch um 12, das ist keine Messung. |
| **`params.fuell_soll`** | `params.fuell_soll` (= `cargo_cap` des wartenden Zugs, 40) | int | P bei F3 | **geliefert** | Bedeutung: Abfahrmenge des Zugs, nicht Lagerkapazität |
| **`params.n_lkw`** | `params.n_lkw` (+ `lkw_ids`) | int | P bei F3 | **geliefert** | `sim_world.gd station_suppliers()`: Fahrzeuge mit `unload_nodes` am Lager; S3 hat einen echten Lkw-Zulieferer (`n_lkw: 1`). Lenas "geskriptet reicht" ist damit übererfüllt. |
| Produktionsrate | `params.produce_every`, `.produce_amount` | int | O | **geliefert** | nur für die Positivkontrolle |
| **Streckenlänge** | `params.strecke_mm`, `params.strecke_felder` | int | P bei F1 | **geliefert** | Summe der umkämpften Kanten: S1 400.000 mm = 40 Felder (Blöcke 2 und 3). Lenas "14 Felder" ist Platzhalter. **Hinweis:** gezählt wird die umkämpfte Strecke, nicht die ganze eingleisige Strecke A–D (600 m). Für die Wurzelzeile reicht das. |
| **`params.gleiszahl`** | `params.gleiszahl` | int | P bei F1 | **geliefert** | 1 wenn eine umkämpfte Kante `single` ist |
| `params.n_fahrzeuge`, `bloecke`, `kanten` | wie benannt | int, Array | O | **geliefert** | `{n}` in `W_KREIS` = `n_fahrzeuge` (= `cycle.size()`) |
| `suggestion_id` | `suggestion_id` | String | O | **geliefert**, im Test ungenutzt (D11) | Produkt-Mapping Abschnitt 3a |
| Validator | `Diagnostics.validate(chain)` | Array[String] | P | **geliefert** | V1–V5, V7, D9-Params; im Runner grün für S1, S2, S3, S1b, S2b |
| Prüfsumme | `sim.checksum()` | – | O | **geliefert** | Daniel S5, nicht UI |
| `schweregrad`, `buendel_key` | – | – | O | **fehlt**, bewusst | nicht im Sprint |
| Replay / Klick-Log | – | – | P (L-06) | **fehlt** | gehört zu F-06, Spezifikation in `f06_panel_spezifikation.md` Abschnitt 5 |
| Ereignis "Meldung entsteht" | `deadlock_events` (Pull) | Array | O | **geliefert (Pull)** | Entstehungsregel in Abschnitt 3a |

**Bilanz:** 0 Pflichtfelder fehlen auf Sim-Seite. Offen sind nur Streckennamen und die Umbenennung in S1/S2 (Szenenaufbau F-06), das Klick-Log (UI, F-06) und die Entstehungsregel für Ladungsmeldungen (Annahme).

## 3. Ableitungstabelle (D9): Sim-Enum → UI

### 3a. Ursache-Code → Typ, Wurzelzeile, Vorschlag, Meldung

| `root_cause` | UI-Typ | Wurzel-Textschlüssel | Parameter der Wurzelzeile | Produkt-Vorschlag (`suggestion_id` → Schlüssel) | Erzeugt Meldung? |
|---|---|---|---|---|---|
| `EINGLEISIG_GEGENVERKEHR` | INFRASTRUKTUR | `W_EINGLEISIG` | `strecke` (Name, Annahme), `felder` = `strecke_felder` | `AUSWEICHGLEIS_BAUEN` → `V_AUSWEICH` | ja, sobald `is_deadlock` (Sim bestätigt nach 5 Ticks) |
| `DEADLOCK` | INFRASTRUKTUR | `W_KREIS` | `n` = `n_fahrzeuge` | `SIGNALE_UMBAUEN_KREIS_AUFLOESEN` → `V_KREUZUNG` | ja, wie oben |
| `WARTEN_AUF_LADUNG` | LADUNG | `W_ZULIEFERUNG` | `lager`, `n` = `n_lkw`, `ist`, `soll` | `ZULIEFERUNG_ERHOEHEN` → `V_LKW` | ja, wenn `wait_ticks ≥ 600` (60 s). **Annahme**, damit normales Laden keine Meldung auslöst. Lena/Felix bestätigen. |
| `BLOCK_BELEGT_UNTERWEGS` | – | – | – | – | **nein.** Vorübergehend (Halter fährt). Kontrollzüge erzeugen das, es darf nicht im Feed erscheinen. |
| `KEINE` | – | – | – | – | nein |

### 3b. Verdichtung: `links` → Kettenzeilen der UI

Je wartendem Fahrzeug liefert die Sim (FAHRZEUG, SIGNAL, BLOCK) oder (FAHRZEUG, LAGER, INDUSTRIE), am Ende URSACHE. Jede UI-Zeile behält das `pos` genau eines Glieds als Sprungziel:

| Muster in `links` | UI-Zeile | Sprungziel |
|---|---|---|
| `FAHRZEUG rolle=SYMPTOM` | `T_STEHT` (Zeile 1) | dieses Fahrzeug |
| `SIGNAL`, `BLOCK` direkt nach dem Symptom-Fahrzeug | `R_SIGNAL` ({signal} = Signal-ID, {abs} = Block-ID) | SIGNAL |
| `FAHRZEUG role=HALTER` + folgender `BLOCK` mit `single` und `holder_fwd != wanted_fwd` | `R_HALTER_GEGEN` | HALTER |
| `FAHRZEUG role=HALTER` + folgender `BLOCK` (sonst), außerhalb Kreis | `R_HALTER` | HALTER |
| bei `is_deadlock` mit `n_fahrzeuge ≥ 3`: je Mitglied im Kreis | `R_WARTET_ZUG` ({zug} = Mitglied, {zug2} = nächstes, {abs} = dessen `wait_block`) | Mitglied |
| `LAGER` nach einem Fahrzeug | `R_LADUNG` ({ist} = `fuell_ist`, {soll} = `fuell_soll`) | LAGER |
| `URSACHE` (immer letztes Glied) | Wurzelzeile nach 3a | `root_pos` |

Ergebnis: S1 (7 Glieder) → 4 Zeilen; S2 (13 Glieder) → 6 Zeilen; S3 (7 Glieder) → 5 Zeilen; S1b Auffahrer (10 Glieder) → 5 Zeilen (ein zusätzliches `R_HALTER`); S2b Ring 6 (19 Glieder) → 8 Zeilen. Das entspricht Lenas Soll-Ketten für F1–F3.

## 4. Kanonischer Ort: Stand und Abweichung zu Lena

Felix' Regel (`cycle_root()`): Mitglieder sortiert, `root_pos` = ganzzahliger Mittelpunkt der Mitten aller umkämpften Blöcke, `root_obj` = umkämpfter Block mit kleinster ID. Belegt: S1 beide Züge (400000,0), S2 alle vier (100000,100000), S2b alle sechs (200000,199999), S1b Auffahrer gleich wie der Zyklus.

Lenas `l06_fehler_final.md` erwartet für F1 "Block B–C (Abschnitt 13)" und für F2 "Block, den der Halter des angeklickten Zuges hält (Abschnitt 32)". Das war gegen den alten Spike geschrieben. **Ich übernehme Felix' Regel**, weil sie fahrzeugunabhängig ist (D9) und für D-04/G4 (9 Wiederholungen) gebraucht wird. Für den Tester ändert sich nur das Sprungziel der Wurzelzeile: F1 landet zwischen den beiden umkämpften Abschnitten, F2 in der Mitte der Kreuzung Südfeld. Beides ist für die Aufgabe eher besser als ein einzelner Abschnitt. **Lena bitte Tabelle 1 anpassen.**

## 5. Rückfall ohne `n_lkw`

Entfällt. `n_lkw` ist im Spike geliefert (S3, `station_suppliers`). Bleibt nur das Smoke-Test-Risiko, dass die F-06-Szene den Zulieferer nicht enthält; dann ist es ein Build-Fehler (Daniel: "Zeile 5 bei F3 vorhanden").

## 6. Prüfregeln (Validator)

Sim-seitig vorhanden (`Diagnostics.validate`): V1 Kette ≥ 2, `pos`, `rolle` je Glied · V2 Glied 0 SYMPTOM, letztes WURZEL und URSACHE · V3 `links[-1].id == root_obj.id` und `links[-1].pos == root_pos` (D9) · V4 Glied 0 = angefragtes Fahrzeug · V5 Zyklusmitglieder in der Kette · V7 jedes Glied `pos` · D9-Params je Code (`strecke_mm`, `strecke_felder`, `gleiszahl`, `n_fahrzeuge` / `n_fahrzeuge`, `bloecke` / `fuell_ist`, `fuell_soll`, `n_lkw` / `halter_id`).

UI-seitig zusätzlich: V8 `root_cause ∈ {BLOCK_BELEGT_UNTERWEGS, KEINE}` erzeugt keine Meldung · V9 Anzeigename je Glied vorhanden (sonst `vertragsfehler`, nicht anzeigen) · V10 jede verdichtete Zeile ≤ 60 Zeichen (sonst Umbruch, Log-Warnung). V6 (Vorschläge) aus v0.1 ist durch D11 gestrichen.

## 7. Beispiel Fehler 3 im Sim-Format (Zielzustand mit Testnamen; Zahlen Platzhalter, nicht gemessen)

```
{
  "vehicle_id": 10, "root_cause": "WARTEN_AUF_LADUNG", "is_deadlock": false, "in_cycle": false,
  "root_pos": Vector2i(655000, 301200), "root_obj": {"kind": "LAGER", "id": 9},
  "params": {"fuell_ist": 12, "fuell_soll": 40, "n_lkw": 1, "lkw_ids": [3],
             "produce_every": 0, "produce_amount": 1, "lager_id": 9},
  "cycle": [], "suggestion_id": "ZULIEFERUNG_ERHOEHEN", "wait_ticks": 1300, "wait_since_tick": 890,
  "links": [
    {"kind": "FAHRZEUG", "id": 10, "role": "ANFRAGE", "rolle": "SYMPTOM", "name": "Zug 10", "pos": Vector2i(498200, 240100)},
    {"kind": "SIGNAL", "id": 21, "rolle": "ZWISCHEN", "pos": Vector2i(501000, 241000)},
    {"kind": "BLOCK", "id": 22, "rolle": "ZWISCHEN", "pos": Vector2i(520000, 244000), "single": true, "holder": 7, "holder_fwd": true, "wanted_fwd": true},
    {"kind": "FAHRZEUG", "id": 7, "role": "HALTER", "rolle": "ZWISCHEN", "name": "Zug 7", "pos": Vector2i(600000, 290000)},
    {"kind": "LAGER", "id": 9, "rolle": "ZWISCHEN", "name": "Lager Hafen-Ost", "pos": Vector2i(655000, 301200), "stock": 12, "needed": 40},
    {"kind": "INDUSTRIE", "id": 9, "rolle": "ZWISCHEN", "pos": Vector2i(655000, 301200), "produce_every": 0, "produce_amount": 1},
    {"kind": "URSACHE", "id": 9, "obj_kind": "LAGER", "rolle": "WURZEL", "pos": Vector2i(655000, 301200), "code": "WARTEN_AUF_LADUNG", "params": {"fuell_ist": 12, "fuell_soll": 40, "n_lkw": 1}}
  ]
}
```

Daraus entstehen die 5 Zeilen aus `textvorlagen_testfehler_v1.md`, Fehler 3.

## 8. Offen (Namen, Termine)

| Nr | Frage | An | Bis |
|---|---|---|---|
| 1 | Stand-Spalte per Datei bestätigen (`pairing_antworten.md` oder `felix.md`); insbesondere Koordinatenachse `pos.y` = Karten-Z | Felix | 20.11., 12:00 (D9) |
| 2 | Streckennamen (Knoten "Mühlbach"/"Kornfeld") und Umbenennung S1/S2 in der F-06-Szene | Felix | 23.11. |
| 3 | Kanonischer Ort nach Felix' Regel in Tabelle 1 übernehmen (F1 Mitte der umkämpften Abschnitte, F2 Kreuzungsmitte) | Lena | 20.11. |
| 4 | Entstehungsregel `WARTEN_AUF_LADUNG` ab 60 s Wartezeit | Lena, Felix | 20.11. |
| 5 | Smoke-Test: `validate()` muss für alle drei Meldungen leer sein, Zulieferer-Lkw in der Szene vorhanden | Daniel | 24.11. |
