# Entscheidungen PO nach Block A (Sprint 6)
- D23: Das T-12-Band "Agrar-Kasse nach 30 min ×1,5–2,0" stammt aus der Archetyp-Zeit. Mit D22 (kein Archetyp) und Dorfnachfrage ×2 (nötig für Haberaus Bankrottband) liegt der Skriptlauf bei ×2,27. Maßstab ist jetzt T-14 (Bankrott 10–30 %, M7 35–50 min ±15 %, 300 Läufe je Standort). Der Slice-Test wird auf ×1,5–2,5 gesetzt; Daniel ersetzt ihn in D-08 durch den 100-Seed-Bankrottlauf.
- Karte S-12 eingefroren. Die alten Archetyp-Startkapitale in hq_optionen sind entfernt (Code ignorierte sie). md5 slice_map.json: d99eb305afc23db4832bcb7ce6c857e0.
- p95-Fix (RENDER_SPLIT) bleibt an; Fahrzeuge erscheinen 100 ms verzögert. Neuer Bench-Lauf auf dem Zielrechner, sobald Basti Zeit hat (keine Pflicht für diesen Sprint).
- Lenas Annahmen bestätigt: Uhr und 2-min-Zähler stehen im Umsetzen-Modus, die Gratislizenz zählt als erste Lizenz, Radius inklusive.
- D24 (Block B): Freeze-Ausnahme für werkzeug_1 → (133,216): Stahl→Werkzeug 34 F., Kohlberg 33 F.; Kohlberg-M7 im Modell 36–38 min (vorher 24). md5 slice_map.json: 718e062cd554b6a3c80460b33f088c8a. Schema: startkapital_cent aus hq_optionen entfernt.
- B-1 (Tag 10): Die Vorschau zeigt den Lizenzfaktor, den das Spiel rechnet (im Radius 0,70, außerhalb 1 + 0,03 je Feld), und nennt nur lizenzierbare Industrien. Größenfaktor im Lizenzpreis = R2-Kandidat (Tobias' Modell rechnet ihn schon; Neumessung nötig).
- B-4: Mittelfurt-Startkette k1. md5 slice_map.json jetzt 48278cd3a0c2adb8be81634ee17c29f4.
- Mittelfurt-Vorschau behält die Zeile „Kette 3: Werkzeugfabrik außerhalb des Radius“ als Information.
