# Lena Hoffmann, Übersicht Tag 1–5 (Sprint 4)

**L-10 fertig (Regel, keine Quelle).** Datei: `lena/l08_slice_regeln_v2.md`, Abschnitt 5a. Entscheidung:
(a) Die Bau-Kategorie entfällt im Slice-Korb, Wachstum G läuft nur über Nahrung (`slice_build_category_active` = aus).
(b) Das Stufen-Tor Kleinstadt → Stadt öffnet Stahl aus K3 bei ≥ 25 % Versorgung (`gate_unlock_good`), Stahl zählt nicht in G (`gate_good_in_growth_supply` = aus).

**Warum nicht Stahl als Baustoff-Ersatz in G:** Ein Agrar-Spieler ohne K3 bliebe im ¼-Band, also im alten Problem. „Werkzeug“ kann das Tor nicht öffnen: die Werkzeugfabrik ist im Slice reiner Abnehmer. Stahl als Tor hält K3 relevant (Referenz Anno 1800, Bedarfsstufen).

**Rechenwerte (keine Messung):** 1.000 → 5.000 Einwohner: 90 min ohne Bonus, 72 min mit +25 %. Das ist das Fenster 72–90 min. Die 154 min aus T-11 galten für den Slice-Start bei 2.500 Einwohnern im ¼-Band; mit L-10 braucht diese Strecke 39 min. **Offen (Jonas/Lena):** Soll 72–90 min für die Slice-Karte gelten, muss die Start-Einwohnerzahl der Kleinstadt (S-10) auf rund 1.000 sinken.

**L-08 v2, Korrekturen:** Ausbau Stufe 2 = 2.000 $ (D19; Stufe 3/4: 6.000/15.000 $, nicht im Slice). Hafen und Handel nicht im Slice (D18), nur Daten mit Flag. Kredit im Slice aus, ab Sprint 5 (`credit_active_in_slice`); ohne Kredit ist ein Konto unter 0 $ Bankrott. Ketten (D17) und Bergbau 6.000 $ (D20) als bestätigt eingetragen; Abschnitt „Erledigt und offen“ neu.

**Nachweis:** Der Validator liest die Keys aus v2 und meldet 0 Abweichungen (Tobias, `tobias/t06/run_validate.log`).
