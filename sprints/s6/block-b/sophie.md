# Sophie, Sprint 6, S-13 Look klein

Arbeitskopie `sophie/slice/`, Shots `sophie/shots/` (vorher_/nachher_ kohlberg, mittelfurt, haberau; hq_ghost_gesetzt.png). Regression d07 GRÜN (238 s, 0 SCRIPT ERROR), Sandbox, keine FPS-Aussage.

**Neu:** `props/hq_building.gd` (`spawn(parent,pos,ghost)`, Ghost weiß/transparent mit Saum-Sockel, gesetzt Firmenfarbe = Palette-Token marker #FFC21A, Fahne), `props/industry_props.gd` (Farm, Mühle, Kohlemine, Erzmine, Kraftwerk, Stahl, Werkzeugfabrik, Holzfäller; Kenney City Kit Industrial + Primitive, dunkle Bodenplatte), `props/label_declutter.gd`, Kenney-GLBs + Textures/colormap.png unter props/kenney/, Tests `tests/s13_*.gd`.
**Geändert:** `building.gd` (2 Stellen: Props statt Grey-Box, Lizenz-Fähnchen über Prop-Oberkante). main.gd unberührt.
**Kontrast:** Bodenplatten gegen Gras 4,3 bis 5,5:1 (Rechnung WCAG, Palette gras 115/148/92). Bäume weiter ohne Schatten; Props ca. 10 Teile je Gebäude, geteilte Meshes/Materialien, keine Schatten an Kleinteilen.
**Label:** Declutter-Knoten (hängt sich selbst an, process_priority 100) schiebt überlappende Labels nach unten, Städte zuerst. Werkzeugfabrik/Kohlberg frei.
**Offen:** Props sind überhöht (x1,25 bis 2,4), weil ein 3x3-Gebäude im Standardzoom nur ca. 30 px misst; Minen bleiben dort klein. Export: GLBs werden per GLTFDocument von Platte gelesen, Export-include_filter enthält kein props/kenney/*.glb: für die Bench-.exe ergänzen, sonst fehlen die Kenney-Teile (Primitive bleiben). HQ-Hook (Platzierung, Wechsel, free des Knotens) liegt bei Mira. Messlauf Zielrechner steht aus, S-13 erst danach erledigt.
