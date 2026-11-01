# Mira, Sprint 6 Tag 3–7: F-20 D22 HQ-Platzierung
Arbeitskopie `/tmp/claude-0/gd/sprint6/b/mira/slice` (nicht im Repo). Godot 4.7.2 headless/xvfb. Alle Zeiten sind Sandbox-Zeiten.

## Gebaut
- **`hq_placement.gd` (neu, 700 Zeilen):**
  - **Start:** Das Spiel beginnt direkt auf der Karte im Platzierungsmodus, mit Übersicht über alle 8 Städte. Die Zeit steht. Die Kopfleiste zeigt schon 6.000 $. Die Hinweisleiste fragt „Wo gründest du?“.
  - **Hover über einer Stadt:**
    - Vorschau im rechten angedockten Panel (PanelDock, 380 px, Theme), ≤ 6 Zeilen aus `data/hq_vorschau.json`. Das Format `{"quelle","staedte":{id:{radius,ketten[],groesse,lizenzfaktor,gelaende,hinweis}}}` passt zu Tobias' T-14b.
    - Zustand mit Icon und Text: Kreis „Kette im Radius“ oder Dreieck „Wagnis: kein Rohstoff im Radius“, nie Rot.
    - HQ-Radiusring wächst in 0,35 s auf den Radius, bei Reduced Motion (`--reduced-motion` bzw. Projektsetting `mega_tycoon/reduced_motion`) sofort.
    - Industrien im Ring bekommen ein Label mit der Luftlinie („44 F.“).
  - **Klick und Gründung:**
    - Klick auf eine Stadt wählt sie aus: Ghost am Stadtrand, Primärknopf „HQ hier gründen“ wird aktiv. Klick auf eine andere Stadt wechselt, Esc oder Rechtsklick hebt die Wahl auf.
    - Der Knopf ruft `economy.start_company_at` auf: 6.000 $, 2 Gratis-Lkw, Zeit 1×, Toast laut Lena.
    - Ab Kartenstart sind es 2 Klicks. Kein Modal.
  - **Umsetzen (L-12 / D22-2):**
    - Ausgelöst durch Klick auf den Ring (±2,5 Felder), auf das HQ-Gebäude oder auf den Gründungs- bzw. Umsetz-Toast.
    - Im Umsetzen-Modus stehen Uhr und 2-min-Zähler (`time_frozen()` blockt `sim_tick`).
    - Esc bricht mit Lenas Toast ab. „HQ hierher umsetzen“ kostet nichts, Kasse und Lizenzen bleiben.
    - Das HQ ist fest, sobald die erste Lizenz gekauft ist (die Gratislizenz zählt) oder 2 min Spielzeit vergangen sind.
    - Ring-Label „Umsetzen möglich, noch m:ss“, in den letzten 20 s „Umsetzen noch N s“. Alle Toast- und Ringtexte wörtlich aus L-12 §3.
  - **Meilensteine ohne Archetyp:** `start_targets(stadt)` liefert Quelle, Verarbeiter und M3 aus `hq_optionen` (Industrien im Radius, Startkette) bzw. aus den `ketten` der Karte. Endabnehmer werden zuerst gewählt, daher Kohlberg: Kohle → Kraftwerk. Das gilt für alle 8 Städte, auch Wagnis. **Index 1 bleibt „Lizenz für … kaufen“** (M1b, für Felix' U-02b-Zeile).
  - **S-13-Hook `_spawn_hq_building(city, as_ghost)`:**
    - Nutzt `props/hq_building.gd` `spawn(parent, pos, ghost)`, sobald Sophies Datei da ist (`ResourceLoader.exists`).
    - Bis dahin Platzhalter: Ghost weißer Quader, gesetzt Holz mit Bernstein-Dach.
    - Der Ghost läuft ebenfalls über den Hook. Entfernen per `free()`.
- **`economy.gd`:**
  - Neu `move_hq_to(node, stage)`: nur Ort und Radius. `start_company_at` nutzt die Funktion.
  - Wrapper `start_company(archetyp, …)` und `var archetyp` entfernt.
- **Entfernt:**
  - Startdialog (`_setup_start_dialog`, `_start_head_box`, `_archetype_tile`), `ARCH`, `archetyp`, `start_game`, `_hq_option`, `_show_influence`.
  - Kamerafahrt/Blur im Hintergrund, Datei `ui/start_backdrop.gd` gelöscht.

## main.gd-Bilanz: 3136 → 2980 Zeilen (netto −156; 183 raus, 27 rein)
- **Hooks (wenige Stellen, Kopfleiste, Linienliste und Zielpfeil nicht angefasst):**
  - Preload `HqPlacement`, `var hq`, Aufbau in `_setup_ui` samt Vorschau-Datencheck in `map_missing_ids`.
  - `place_hq(id)` als Testeinstieg.
  - Erste Zeile in `_unhandled_input`: `hq.handle_input`.
  - `sim_tick`: `or hq.time_frozen()`.
  - `_update_hint`: `hq.hint()`.
  - `_init_milestones(A)` bekommt die Ziele als Parameter.
  - Meldungen in `_check_ids` nennen die Stadt statt des Archetyps.
- **Bugfix `_toast` (+4 Zeilen, `_fit_toast` sofort und deferred):** Lange Toasts wurden mit der Höhe aus der alten Labelbreite gemessen (Panel 2314 px hoch, Text außerhalb des Bilds). Das betraf schon den alten Start-Toast. Jetzt 74 px.
- **Merge-Hinweis für Felix:** Die Konflikte liegen nur an den Hook-Zeilen oben, in `_toast` und in den entfernten Startdialog-Blöcken.

## Tests
- **Neue Suite `d07_abnahme --only=hq`, 30/30, echte Eingabeereignisse.** Weltklicks laufen per `push_input` mit Zielfeld aus `sim_hover`, Knöpfe und Toast per `real_click`, Esc als Key-Event. Geprüft:
  - Start pausiert, Kopfleiste zeigt 6.000 $, kein Archetyp im Quelltext.
  - 8/8 Städte mit Vorschau, ≤ 6 Zeilen, Panel ≤ 380 px.
  - Vorschau-Latenz max 42 ms. Kontrast min 5,20:1. Wagnis als „warn“ ohne Rot.
  - Ring 0,35 s, Reduced Motion sofort.
  - Ghost, Wechsel, Esc, kein Modal. Gründung per Klick in 4 Klicks inkl. Wechsel und Esc-Probe (Minimum 2). Toast, Gebäude, Ring.
  - Meilensteine, Index 1 = erste Lizenz.
  - Umsetzen über Ring (Uhr und Zähler stehen), Esc, Toast-Klick, Umsetzen nach Haberau ohne Kosten.
  - Gratislizenz macht das HQ fest. 20-s-Label, nach 1199 Ticks noch frei, nach 1200 fest. Seehafen gründbar.
- **Bestehende Suiten auf den neuen Einstieg umgestellt, nicht abgeschwächt:**
  - `start_game("agrar"/"bergbau")` → `place_hq("haberau"/"kohlberg")` in slice_test, parity_test, s11_test, d07_abnahme, allen Shot-Skripten und bench.gd.
  - Die Prüfung „Startdialog sichtbar“ ist jetzt „Platzierungsmodus, kein StartDialog-Knoten, Zeit pausiert“. A4 prüft „Vorschau nach Gründung unsichtbar“, A1b „auch vor der Gründung keine zentrierte Fläche“.
  - Format-Bug in einer slice_test-Meldung behoben („10–30 %%“), er erzeugte vorher ein ERROR im Log.
- **`d07_regression.sh`:** Block `hq` ergänzt. Lauf aus slice/ ist **GRÜN**:
  - slice_test soa/alt 72/72, parity 8/8, s11 15/15
  - Abnahme: ui 31/31, kredit 16/16, parity 12/12, lager 2/2, hq 30/30
  - Spikes sim-core und f04 grün, statische Prüfungen grün
  - **0 SCRIPT ERROR**, Laufzeit 132 s
- **Hinweis:** Zwei xvfb-run-Läufe gleichzeitig (`-a`) haben sich einmal gegenseitig blockiert. Shots und Regression nacheinander starten.

## Screenshots (`/tmp/claude-0/gd/sprint6/b/mira/shots/`, Skript `tests/f20_shots.gd`)
- f20_1_hover_mittelfurt
- f20_2_hover_wagnis_steinbach
- f20_3_gewaehlt_ghost_mittelfurt
- f20_4_nach_gruendung_mittelfurt (Toast, Ring mit Label, Platzhalter-HQ)

## Kürzungen / offen
- Nichts aus der Kürzungsliste gestrichen: Geländezeile, Ring-Animation und Wechsel sind drin. Die Geländezeile fällt automatisch weg, wenn eine Stadt mehr als 6 Zeilen hätte. Mit den L-12-Daten passiert das nicht.
- Pin-Vergleich und Tipp-Aufschlüsselung sind wie geplant nicht gebaut.
- Industrien „leuchten“ nicht, sie bekommen nur ein Distanz-Label.
- Die Vorschau zeigt Lenas Platzhalter. T-14b einfach als `data/hq_vorschau.json` ersetzen.
- Daten-Nit für Lena: Bei Seehafen steht „Kein Rohstoff im Radius“ doppelt (Kette und Hinweis).
- Kenney-Schrift: Im Knopf liest sich „HQ“ fast wie „HO“ (Glyphe Q). Aylin/Sophie bitte ansehen.
- Merge: Sophies `props/hq_building.gd` und Felix' U-02b. Nach dem Merge Regression erneut laufen lassen.
