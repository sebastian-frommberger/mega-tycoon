# Mega Tycoon – Prototyp „Start-Simulation“ (v3)

Godot 4.2 oder neuer. project.godot in Godot importieren, F5.

## Karte (192 × 192 Felder)
- 5 Städte aus Straßenraster und Häusern: Kornfeld, Nordheim, Metropole, Bergstadt, Küstenhaven – jede mit eigenem Bedarf.
- 5 Ketten: Getreide → Mühle → Mehl · Vieh → Schlachthof → Fleisch · Öl → Raffinerie → Benzin ·
  Holz → Sägewerk → Bretter · Erz → Stahlwerk → Stahl → Werkzeugfabrik → Werkzeug (3 Stufen).
- Fluss und Küste: Bauen über Wasser = Brücke, 6× so teuer. Berge: 3× so teuer. Wälder werden beim Bauen gerodet.

## Ablauf
1. [B] Firma kaufen – ohne eigene Firma geht nichts. Laden nur bei eigenen Firmen und Lagern.
2. [1] Straße / [2] Gleis: wie OpenTTD ziehen (Maustaste halten, loslassen = bauen; erst gerade, dann 45°).
   Weiß = baubar, rot schraffiert = nicht baubar, Grund und Kosten am Cursor. Rechtsklick/Esc = abbrechen.
   Wasser: Brücke nur gerade, Land an beiden Enden, max. 8 Felder (wie OpenTTD).
   [X] Abriss: Rechteck über eigene Straßen/Gleise ziehen, 50 % des bezahlten Preises zurück.
   Test: godot --headless --path . -s res://tests/f13_test.gd (Exit 0).
3. [3] Lager: Umschlagpunkt, nimmt alles an und gibt alles ab.
4. [4] Lkw-Linie / [5] Zug-Linie: Quelle, dann Ziel.
5. Linienliste oben links: Gewinn pro Minute nach Unterhalt.

Kamera: WASD, Q/E drehen, Mausrad zoomen (weit raus für den Kartenüberblick).

## Stellschrauben (oben in main.gd)
START_MONEY, ROAD_COST, RAIL_COST, WATER_FACTOR, MOUNTAIN_FACTOR, WAREHOUSE_COST, OWNED_RADIUS,
OPEN_THRESHOLD, PAY_PER_UNIT_FIELD, PRODUCT_FACTOR, VEHICLES. Städte und Industrien in _create_map().
