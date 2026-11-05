# regress_fast (2026-11-05, Godot 4.7.2.stable.official.ed1daf0bf, Sandbox, Wanduhr)

| Schritt | Ergebnis | Sekunden | Detail |
|---|---|---|---|
| slice_test_soa | OK | 5.7 | 74/74 Prüfungen OK, Laufzeit 5.4 s (Sandbox) |
| slice_test_alt | OK | 5.7 | 74/74 Prüfungen OK, Laufzeit 5.1 s (Sandbox) |
| parity_test | OK | 5.5 | 8/8 Paritätsprüfungen OK |
| s11_test | OK | 0.7 | 16/16 Prüfungen OK |
| d07_abnahme_ui | OK | 16.2 | 31/31 Abnahmeprüfungen OK, Laufzeit 15.6 s (Sandbox) |
| d07_abnahme_kredit | OK | 5.4 | 17/17 Abnahmeprüfungen OK, Laufzeit 4.8 s (Sandbox) |
| d07_abnahme_parity | OK | 4.8 | 12/12 Abnahmeprüfungen OK, Laufzeit 4.2 s (Sandbox) |
| d07_abnahme_lager | OK | 4.3 | 2/2 Abnahmeprüfungen OK, Laufzeit 3.8 s (Sandbox) |
| d07_abnahme_hq | OK | 2.0 | 30/30 Abnahmeprüfungen OK, Laufzeit 1.5 s (Sandbox) |
| d08_lizenzfaktor | OK | 1.5 | Exit 0 |
| s7_boot_default | OK | 2.3 | 39/39 Prüfungen OK, Laufzeit 1.8 s (Sandbox) |
| s7_boot_arg | OK | 1.7 | 29/29 Prüfungen OK, Laufzeit 1.2 s (Sandbox) |
| proto_terrain_test | OK | 0.6 | Exit 0 |
| ta_import_test | OK | 0.2 | Exit 0 |
| proto_epochen_test | OK | 0.2 | Prüfungen OK: 17, FAIL: 0 |
| proto_strassenband_test | OK | 0.3 | Prüfungen OK: 36, FAIL: 0 |
| proto_welt_test | OK | 22.6 | Prüfungen OK: 61, FAIL: 0 |
| proto_sim_test | OK | 4.4 | Prüfungen OK: 58, FAIL: 0 |
| proto_band_hoehe_test | OK | 1.3 | Prüfungen OK: 2, FAIL: 0 |
| proto_schilder_test | OK | 1.4 | Exit 0 |
| proto_fixpass_test | OK | 1.4 | Exit 0 |
| proto_licht_test | OK | 1.4 | Prüfungen OK: 19, FAIL: 0 |
| proto_ui_welt_test | OK | 8.5 | Prüfungen OK: 161, FAIL: 0 |
| s8_fk02_test | OK | 2.8 | 27/27 Prüfungen OK |
| proto_easing_test | OK | 7.3 | Prüfungen OK: 20, FAIL: 0, Abweichungen (bewusst, offen): 1 |
| proto_mass | OK | 1.6 | Exit 0 |
| s8_bot_smoke | OK | 18.3 | Prüfungen OK: 6/6 |
| s8_exploit_smoke | OK | 4.2 | Prüfungen OK: 6/6 |
| static_kasse (cash_cent +=/-=, Allowlist) | OK | 0.0 | Kasse: 10 Treffer ausserhalb tests/, 2 Allowlist-Einträge genutzt, Verstöße: 0; |
| static_tempo (W1: kein Tempofeld in fuhrwerk_e1/frachtwagen_e1) | OK | 0.0 | Tempo: Einträge gefunden ['fuhrwerk_e1', 'frachtwagen_e1'], Tempofelder: keine; |

Gesamt: GRÜN, Laufzeit 133 s (Ziel < 300 s).
