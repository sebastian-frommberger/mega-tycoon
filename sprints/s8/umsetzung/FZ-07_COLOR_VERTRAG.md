## COLOR-Belegung Fahrzeuge (FZ-07, nur Vertrag; TEAM-02 TA, 2026-11-05)

Abschnitt für `VERTRAG.md` (die Datei liegt nicht im Git, sondern unter `/tmp/claude-0/gd/designsprint/p4/VERTRAG.md`; dort ist derselbe Text angehängt). Kein Shader-Code, keine Verhaltensänderung: der Shader `proto_prefab.gdshader` liest `COLOR` heute gar nicht [M], `proto_fahrzeuge.gd` schreibt Weiß [M].

**Geltungsbereich.** Alle Fahrzeug-MultiMeshes (`proto_fahrzeuge.gd`, Material `proto_prefab.gdshader`). Frei ist nur `COLOR` (Instanzfarbe); `INSTANCE_CUSTOM` bleibt voll belegt: `x` Gang, `y` Variante, `z` Nicken, `w` Wanken (`integration_w2.md` I7). Neue Zwecke bekommen keinen weiteren Kanal, sondern gehen über diesen Vertrag.

| Kanal | Bedeutung | Wertebereich | Neutralwert |
|---|---|---|---|
| `COLOR.rgb` | Firmenfarbe der Besitzerfirma (Plane/Kasten) | 0..1 je Kanal | (1, 1, 1) = unbefärbt, Prefab-Palette bleibt |
| `COLOR.a` | Alter des Fahrzeugs, normiert | 0..1, geklemmt; **0 = neu, 1 = alt** | 0 = neu |

Regeln:
1. **Ein Writer.** `set_instance_color` für Fahrzeuge steht nur in `proto_fahrzeuge.gd` (Felix). Der Reader ist ausschließlich `proto_prefab.gdshader` (TA, Besitz laut `ux_art.md`). Änderung der Belegung nur mit Eintrag hier.
2. **Neutralwert aller Bestandswerte ist rgb = Weiß.** Firmenfarben dürfen deshalb nie exakt Weiß sein. Die Palette (Spieler + 3 KI, nicht Rot/Grün/Gelb, ΔE2000 ≥ 20) kommt in S9 mit C2; bis dahin gibt es nur den Neutralwert.
3. **Falle Alpha.** `Color.WHITE` und jeder Godot-Standard hat `a = 1`, das hieße nach diesem Vertrag „voll alt“. Der Writer muss `a` deshalb immer ausdrücklich setzen (Neutral `a = 0`: `Color(1, 1, 1, 0)`); sobald der Shader `a` liest (Patina, Block C), ist ein vergessenes `a` sichtbar als alter Wagen. Alternative, falls das zu fehleranfällig ist: `a = Frische` (1 = neu). Entscheidung revidierbar bis zum ersten Shader-Merge, danach nur mit Eintrag.
4. **Abbildung Alter → `a`** legt die Sim-Seite fest (FZ-02, Zwei Uhren; D5 „+5 %/Kalenderjahr“), Vertrag: monoton, 0..1, geklemmt. Stufen für Tests und UI: neu `a < 0,34`, gebraucht `0,34 ≤ a < 0,67`, alt `a ≥ 0,67`. Der Shader blendet kontinuierlich (Patina: Sättigung −, Ton dunkler, Planenflecken), die Stufen sind nur Prüfgrenzen (FZ-07-Test: 5 Personen, neu/alt aus 80 m, ≥ 4/5).
5. **MultiMesh-Pflicht (Compat, 4.7.2).** `use_colors = true` setzen, **bevor** `instance_count` gesetzt wird (Setzen von `instance_count` löscht die Daten), und jede Instanz initial beschreiben; ohne Instanzfarbe kam `COLOR` im Shader schwarz an (`proto_fahrzeuge.gd`, Kommentar zu Z. 42) [M].
6. **Kein Mehraufwand.** Ein Material, ein MultiMesh je Kategorie, keine zusätzlichen Texturzugriffe: Draw Calls bleiben unverändert (Akzeptanz FZ-07).
7. **Gleiche Belegung für Besitzmarken** (FK-05: Pin-Rand, Hofschild): `rgb` = Firma; `a` dort ungenutzt (0).

Ungeprüft [Annahme]: ob `COLOR` im Shader als lineare Zahl ankommt (dann Hex-Firmenfarben mit `srgb_to_linear()` schreiben) oder konvertiert wird. Vor dem ersten Shader-Merge mit einem Ein-Pixel-Versuch klären (5 Minuten), Ergebnis hier eintragen.
