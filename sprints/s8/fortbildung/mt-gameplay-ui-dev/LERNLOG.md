# Lernlog mt-gameplay-ui-dev

Zweck: Kompromisse, Workarounds und "wusste ich nicht"-Momente zählen (Lern-Routine, Punkt 5). Zähler 2 für dasselbe Thema löst eine Recherche aus (Trigger b). Geschlossene Lücken wandern in den Skill, dann hier als erledigt markieren.

| Datum | Situation | Kompromiss / Lücke | Zähler | Folge (Recherche, Quelle, Skill-Eintrag) |
|---|---|---|---|---|
| 2026-11-03 | Einführung der Routine | (noch kein Eintrag) | 0 | |
| 2026-11-03 | Recherche | Skill: 'Godot gibt keine Stretch-Empfehlung' | 1 | Falsch laut Doku: canvas_items für Nicht-Pixel-Art. Skill-Korrektur vorgeschlagen |
| 2026-11-03 | S8 | toast_label ohne Queue (Ursache der A-08-Verschiebung) | 4 | Queue vor Feature |
| 2026-11-03 | Phase 4 | Kommentar in proto_schilder.gd weicht vom Code ab | 3 | Kommentar im selben Commit anpassen |
| 2026-11-05 | AT-07–09 | Panel-Neuaufbau alle 0,25 s verschluckte gehaltene Klicks (BUG-1-Muster, jetzt in proto/ui_welt.gd): nur 2 von 8 echten Klicks kamen an | 2 | Trigger b: Muster „Refresh baut Knöpfe neu“ zum 2. Mal. Fix: kein Neuaufbau bei gehaltener Taste; besser: Werte in vorhandene Labels schreiben (Skill-Eintrag vorschlagen) |
| 2026-11-05 | AT-07–09 | Fehlertexte in eigener Datei (FT_WELT) statt ui/fehlertexte.gd, weil die Datei Aylin gehört | 1 | AT-12 übernimmt |
| 2026-11-05 | AT-08 | Darstellung der Fahrzeuge nach jedem Kauf neu gebaut (proto_fahrzeuge kennt keine nachträglichen Fahrzeuge) | 1 | API-Anforderung an Felix |
| 2026-11-05 | AT-08 xvfb | warp_mouse unter X11: Bewegung kommt verzögert, nach dem gepushten Drücken = Ziehen. 2 Frames nach warp warten [V] | 1 | Skill-Zeile „Echte Maus“ ergänzen |
| 2026-11-05 | AT-07 | regress_fast lief, während ich unter slice/ editiert habe: 6 rote Schritte durch Zwischenstand | 1 | Während Regression nur außerhalb slice/ schreiben |
