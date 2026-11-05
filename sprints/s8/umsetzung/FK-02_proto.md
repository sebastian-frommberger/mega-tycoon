# FK-02 Verdrahtung in ProtoSim + API für die UI (Felix, S8, 05.11.2026)

**Ergebnis: grün.** Branch `s8-fx2` (von s8 8f9fb6f). Den Ökonomie-Teil hat Tobias geliefert (`FK-02.md`).

## Was (`proto/proto_sim.gd`)
- `oeko_laden()` ruft nach `load_from` `eco.apply_proto(data/economy_proto.json)` auf: Mühlen-Eingangspuffer 2 Perioden, Aufschlag +25 % je Werk, Rückfall W3 (aus). Das gilt **nur in der Welt**, der Slice ruft das nie.
- `_fix_neu()`: Laufende Kosten = Σ fix_eff der Fahrzeuge + `eco.works_upkeep_cent_pro_periode()` (Werksunterhalt), gebucht über `konto.fix_neu`/`konto.tick`. Keine direkte `cash_cent`-Buchung, der W12-Check bleibt grün.
- Kauf und Ausbau geben `konto` und `credit` an `eco.buy_site`/`eco.upgrade_site` weiter. Kreditgeld kauft keine Firma, die Regel liegt bei Tobias in `economy.gd` (`cash − loan`).

## API für Mira (Ort = Stationsname aus `proto_orte.json`, wie bei `lizenz_kaufen`/`linie_anlegen`)
| Funktion | Rückgabe |
|---|---|
| `kauf_angebot(name)` | Vorschau = `eco.buy_quote` (`preis_cent`, `werkspreis_cent`, `anrechnung_cent`, `lizenz_gezahlt_cent`, `rabatt_erster_kauf`, `felder_hq`, `faktor_entfernung_promille`, `faktor_werke_promille`, `besitzer`) **plus** die Folgen: `unterhalt_neu_cent_pro_periode`, `marge_promille` (150), `lizenz_entfaellt` (true), `guthaben_ohne_kredit_cent`, `kaufbar` (bool), `grund` (`""`, `schon_gekauft`, `besitzer_reserviert`, `kasse_im_minus`, `kredit_sperrt_firmenkauf`, `guthaben_reicht_nicht`) |
| `firma_kaufen(name)` | `eco.buy_site` → `{ok, bezahlt_cent, guthaben_cent, werke}` oder `{ok: false, fehler}` |
| `ausbau_angebot(name)` | `eco.upgrade_quote` → `{ok, stufe_neu, kosten_cent, durchsatz_neu, unterhalt_neu_cent_pro_periode}` oder `fehler` (`nicht_im_besitz`, `nur_verarbeiter`, `hoechste_stufe`) |
| `werk_ausbauen(name)` | `eco.upgrade_site` → `{ok, bezahlt_cent, stufe, durchsatz, guthaben_cent}` |
| `werksunterhalt_cent_pro_periode()` | Σ Werksunterhalt (für HUD Fix/min) |
Nach `bankrott` oder ohne Firma liefern alle Funktionen `{ok: false, fehler: "bankrott" / "keine_firma"}`. Freischaltung `ms_5b` (`buy_unlock_milestone_id`) prüft die API nicht; das ist Sache der Ziel-/UI-Schicht (FK-02.md Offen 4).

## Tests (gemessen, headless Godot 4.7.2)
proto_sim_test 48/48, neu:
- **Prüfsumme der festen Kette ohne Kauf unverändert:** -6753726287387273337. Vorher auf s8 8f9fb6f gemessen, jetzt fest im Test (`FEST_PRUEFSUMME`, nur bei k = 1). Der Mühlendeckel greift auf der festen Kette nicht (1 Fuhrwerk, Eingang < 40 E).
- Kauf Mühle: Vorschau 153.000 ¢ (Werk 200.000, Anrechnung 7.000, Erstrabatt), Kasse 525.048 → 372.048 ¢, **Δ = Vorschau ± 0**.
- Werksunterhalt 2.000 ¢/Periode: Eine Periode bucht 14.000 ¢ = Fahrzeuge 12.000 + Werk 2.000.
- Ausbau auf Stufe 2: 200.000 ¢ (= Vorschau), Durchsatz 40, Unterhalt 4.000 ¢; Periode gebucht 16.000 ¢.
- Zweiter Kauf: abgelehnt (`schon_gekauft`).
- Kreditgeld: Kasse 154.000 ¢ ≥ Preis, aber Kredit 200.000 ¢ → Vorschau und Kauf `kredit_sperrt_firmenkauf`, Kasse unverändert.

`s8_fk02_test` (Tobias) ist jetzt in `regress_fast.sh` aufgenommen (Proto-Schleife), 27/27. **Änderung an seinem Test:** `_puffer_lauf` setzt den Deckel jetzt immer ausdrücklich, „ohne“ also mit 0. Vorher verließ sich der Test darauf, dass ProtoSim das Overlay nicht anwendet; E1 wurde dadurch rot (ohne Deckel = 40 E). Werte danach wie in FK-02.md: ohne 283 E / 580 bezahlt, mit 40 E / 339, voll ab Tick 1.625.

## Regression (gemessen)
- `regress_fast.sh`, 1. Lauf: grün bis auf E1 (oben behoben).
- 2. Lauf: 2 FAIL mit **Wanduhr-Bezug**: `d07_abnahme_ui` A21 Slide-in 216 ms (Grenze 150 + 1 Frame) und `proto_easing_test` E8 p95. Die Maschine war belastet (load average 3,7, andere Agenten). Je zwei Einzel-Nachläufe waren grün: A21 152/153 ms, E8 p95 0,118 ms. Beide Tests sind Wanduhr-abhängig → Flake-Hinweis an Daniel.
- d08 n = 20: md5 5cce648a53c1c2f3246147abcaca0988 (Slice unverändert). static_kasse 0 Verstöße, static_tempo grün.
