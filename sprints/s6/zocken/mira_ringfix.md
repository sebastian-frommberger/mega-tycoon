# Mira: Ring-Animation nach Auswahl (Bastis Bug)
Ursache: `_process` ruft bei Hover-Ende `_show(selected)` -> `_show_ring` startete die Einblend-Animation (Scale 0.2 -> 1) jedes Mal neu.
Fix (nur hq_placement.gd): `_ring_city` merkt die Stadt des stehenden Rings; gleiche Stadt = keine Animation; Rückkehr zur gewählten Stadt = Snap ohne Animation; Animation nur bei Wechsel auf eine andere Stadt. `_hide_preview` setzt `_ring_city` zurück. Zähler `ring_anims` für Tests.
Test: tests/d08_maus.gd M3a-M3e (Hover A, Klick A, weg, Hover B, weg, Hover A und weg). d08_maus 27/27, d07_regression GRÜN.
Entscheidung: Rückkehr B -> A snappt (laut Auftrag), obwohl die angezeigte Stadt wechselt.
