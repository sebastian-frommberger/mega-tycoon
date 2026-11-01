# Entscheidungen vor T-06 (Jonas Weber, PO, 03.12.2026)

Zu Lenas vier offenen Punkten aus `day4-7/lena/l08_slice_regeln.md`. Alle vier gelten für den Vertical Slice und sind nach der Grey-Box im Januar revidierbar.

**D17 Ketten:** K1 (Getreide → Mühle → Mehl → Stadt), K2 (Kohle → Kraftwerk) und K3 (Erz + Kohle → Stahlwerk → Stahl → Werkzeugfabrik) sind bestätigt, Kohle teilt sich auf K2 und K3. Die Werkzeugfabrik mit 40 E/min und die Kraftwerks-Abnahme bleiben Annahmen, Tobias markiert sie im JSON als `annahme`.

**D18 Archetypen:** Hafen und Handel fliegen aus dem Slice, es bleiben Agrar (K1) und Bergbau (K2/K3). Eine Holz-/Hafen-Kette wäre die vierte Kette, und Sophies Kapazität trägt nach der Entscheidung vom 27.11. drei; die Startwerte von Hafen und Handel bleiben als Daten im JSON, aber mit Flag "nicht im Slice".

**D19 Ausbaukosten:** Die Zuordnung folgt der Quelle (`hq_startwerte.md`, "Stufe 2–4: 2.000 / 6.000 / 15.000 $"): Ausbau auf Stufe 2 kostet 2.000 $, auf Stufe 3 6.000 $, auf Stufe 4 15.000 $; im Slice gibt es nur Stufe 2. Lenas Wert 6.000 $ für Stufe 2 war eine Fehlzuordnung und wird in L-08 korrigiert (`factory_upgrade_cost_l2` = 2.000 $); passend dazu stehen die Stufen schon so in Tobias' `economy_constants.json`.

**D20 Bergbau-Untergrenze:** Es bleibt bei 6.000 $ mit Kreditrahmen 2.000 $ als Pflichtregel ab Minute 0, 6.500 $ gibt es nicht; das Startkapital von 7.000 $ (D1) bleibt unverändert. Begründung: Mit Kredit hat die Kauf-Route laut `t05_final.md` keinen Soft-Lock mehr (Zinsen 4–9 $), und eine höhere Untergrenze würde den knappsten Archetyp nur künstlich weicher machen, bevor L-05 etwas misst.
