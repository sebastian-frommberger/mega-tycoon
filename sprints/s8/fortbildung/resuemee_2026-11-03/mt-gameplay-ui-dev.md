# Mira (Gameplay- und UI-Entwicklung): Resümee (Stand 03.11.2026)

Quellen: Repo `/home/claude/mega-tycoon` (Pfade relativ), Web-URLs im Abschnitt 7. Marken: [Beleg] nachgelesen, [Eindruck] meine Einschätzung.

## 1. Wie ich Spiel und Konzept heute sehe

Ein Verkehrs-Tycoon ab 1820, dessen Reiz in lesbaren Netzen und diagnostizierbaren Linien liegt. Meine Seite ist die Brücke zwischen Sim und Bildschirm. Was trägt: die UI wird in Code gebaut (kein Szenen-Editor-Zwang), Hooks statt Hardcode (z. B. `hq_placement`, Entscheidung D22 "HQ frei platzieren"), und die Eigenbau-Tests mit echter Maus unter xvfb (`warp_mouse`, `push_input`). [Beleg: `slice/main.gd`, `tests/`]

Was noch Papier ist: Die Oberfläche kennt keinen InputMap-Aufbau, keine Fokus-Navigation (nur 2 Fokus-Treffer in `main.gd`, `start_menu.gd` setzt `FOCUS_NONE`, Zeile 71) und keine `tr()`-Lokalisierung. [Beleg: Grep] Und: **Diagnose und Signale sind nicht in der UI verdrahtet**; `slice/core/diagnostics.gd` hängt nur an Sim und Tests. [Beleg]

## 2. Entwicklungsverlauf aus meiner Sicht

- S2 bis S4: Slice-UI wächst in `main.gd`; `set_buffer_interpolated` wird in S4 für Fahrzeuge eingebaut (Zeilen 3484 und 3485). [Beleg]
- S5 bis S6: Fehlerliste BUG-1, BUG-3, BUG-5 aus Abnahmen; Tests gegen Platzhalter-Karte werden rot, als die echte Karte kommt. [Beleg: Retros s6]
- S7: Welt `--welt=s7`, Bastis Feedback 01 bis 11, HQ-Platzierung (D22) und Aufgaben Z-01, W-04, U-03. [Beleg: `sprints/s7/`]
- S8 Design-Sprint: Prototyp-Welt (`slice/proto/*`), Schilder als 2D-Overlay, ProtoSim-Anbindung, Fix-Pass M8. [Beleg: `phase4/`]
- Umfang: `slice/main.gd` hat heute 3.612 Zeilen. [Beleg: `wc -l`] Das ist die größte Last, die ich trage.
- Git: 76 Commits vom 01. bis 03.11. (33/34/9 je Tag). [Beleg]

## 3. Was gut lief (belegt)

1. Hook-Prinzip: Neue Funktionen (HQ-Platzierung, Prefabs per Pfad `res://world/proto_prefabs.gd`) kamen ohne Umbau des Bestands. [Beleg: `phase4/felix_welle2.md`, "Bestandsdateien in Welle 2: keine geändert"]
2. Echt-Maus-Tests fangen Fehler, die Headless nicht sieht (xvfb-Läufe, `proto_mass` 89/89). [Beleg]
3. Fix-Pass M8 hat Bastis Feedbackpunkte abgearbeitet statt neu zu diskutieren. [Beleg: `phase4/fixpass_w2.md`]
4. Aufgabenkarten v1.1 geben klare Abnahmekriterien. [Beleg: `phase4/aufgabenkarten_v1_1.md`]

## 4. Was nicht gut lief, wiederkehrende Kompromisse (mit Zähler)

| Kompromiss | Zähler | Beleg |
|---|---|---|
| Eine einzige `toast_label`-Instanz ohne Queue, Meldungen überschreiben sich | seit S3, Ursache der A-08-Verschiebung (4x) | `slice/main.gd` 192, 1027, 1594 |
| Tests auf Platzhalter-Karte rot bei echter Karte | 2 (S6, S7) | Retros |
| Doku-Drift: Kommentar behauptet, Schilder wüchsen mit der Auflösung, Code deckelt mit `clampf` | mindestens 3 Fälle insgesamt | `proto_schilder.gd` Z. 16 und 479 |
| Test nur durch Basti (D16) | seit S3 | Entscheidungen |
| UI-Logik in `main.gd` statt in eigenen Klassen | wächst jeden Sprint | 3.612 Zeilen |

Ehrlich: Die `toast_label`-Lücke war ein Zwei-Stunden-Thema, das wir viermal vor uns hergeschoben haben. Das ist unsere Verantwortung, nicht Zufall.

## 5. Wo das Spiel oder das Konzept aus meiner Sicht scheitern könnte

1. **Hoch:** `main.gd` wird unwartbar. Jede neue Funktion erhöht das Regressionsrisiko; ein Teil der Tests ist von Eingaben abhängig. [Eindruck, gestützt auf 3.612 Zeilen]
2. **Hoch:** Ohne Fokus-/InputMap-Konzept ist weder Controller noch Tastaturbedienung noch Barrierefreiheit nachrüstbar ohne Umbau. [Eindruck]
3. **Mittel:** Ohne `tr()` wird eine spätere Lokalisierung ein Großumbau (Ziel: deutscher Markt zuerst, englisch später). [Eindruck]
4. **Mittel:** Stretch-Einstellungen stehen (`canvas_items` + `expand`, Basis 1600x900) aber kein Test auf 4:3, 21:9, 4K. [Beleg: `slice/project.godot`; Test fehlt: Eindruck]
5. **Niedrig:** Skalierung der Schilder mit `clampf(vp.y/900)` führt bei 4K zu kleiner Schrift. [Eindruck, rechnerisch]

## 6. Meine drei wichtigsten Empfehlungen an Basti für Sprint 8

1. **Toast-Queue plus Protokoll** (Klasse `ToastQueue`, eine Meldung gleichzeitig, Verlauf einsehbar). Aufwand: ca. 0,5 Tag. Schaltet A-08 frei.
2. **InputMap und Fokus-Reihenfolge einführen**, bevor weitere Dialoge entstehen (Aktionen statt Tastencodes, `FOCUS_ALL` für Buttons). Aufwand: ca. 1 Tag, danach 20 Prozent weniger Nacharbeit pro Dialog. [Eindruck]
3. **`main.gd` aufteilen**: erst HUD und Toast, dann Bau-Werkzeuge in eigene Dateien, mit grünem d07-Regressionslauf nach jedem Schnitt. Aufwand: 2 bis 3 Tage verteilt auf den Sprint. Pilot `gdUnit4` nur als Spike (0,5 Tag), keine Pflicht.

## 7. Recherchen dieser Runde

**R1 Godot-Stretch.** Frage: Was empfiehlt Godot für Desktop-Spiele, die nicht Pixel-Art sind? Quellen: [Godot-Doku multiple_resolutions (Rohdatei .rst)](https://raw.githubusercontent.com/godotengine/godot-docs/master/tutorials/rendering/multiple_resolutions.rst) (HTML-Seite lieferte nur Navigation, daher Rohdatei). Ergebnis: `canvas_items` für nicht-Pixel-Art, `viewport` für Pixel-Art. Das **widerspricht meinem Skill** (A1.6/C2: "keine klare Empfehlung"). Sicherheit: hoch, eine offizielle Quelle. [Beleg]

**R2 Toast-Muster.** Quellen: [SAP Fiori Snackbar](https://www.sap.com/design-system/fiori-design-android/v25-8/components/feedback/snackbar/usage), [WCAG 2.2.1](https://www.w3.org/WAI/WCAG22/Understanding/timing-adjustable.html). Ergebnis: eine Meldung zugleich, 4 bis 10 s, Info muss anderswo bleiben. Sicherheit: mittel. [Beleg]

**R3 gdUnit4.** Quelle: [dev.co zu gdUnit4](https://dev.co/testing/open-source/gdunit4). Ergebnis: reifes Test-Framework, aber nur eine Quelle, kein eigener Pilot. Sicherheit: niedrig, Marker [E]. Kein Wechsel empfohlen.

Lernlog-Zeilen (2026-11-03):
- Situation: Stretch-Aussage im Skill falsch. Lücke: Doku nicht nachgelesen. Gegenmaßnahme: Primärquelle vor Skill-Aussage prüfen.
- Situation: `toast_label` ohne Queue, 4. Verschiebung. Gegenmaßnahme: Queue vor Feature, nicht danach.
- Situation: Kommentar-Drift in `proto_schilder.gd`. Gegenmaßnahme: Kommentar bei Verhaltensänderung im selben Commit anpassen.

## 8. Vorschläge für Skill-Änderungen (nur Vorschläge, nichts geschrieben)

1. `sprints/s8/fortbildung/mt-gameplay-ui-dev/SKILL.md`, Zeilen A1.6 und C2: ersetzen durch "Godot-Doku: `canvas_items` für Nicht-Pixel-Art, `viewport` für Pixel-Art", Marker **[K]**. Quelle: R1.
2. Neuer Punkt "Toast: Queue, eine Meldung zugleich, Protokoll", Marker **[K]**. Quelle: R2.
3. gdUnit4 als **[E]** (Einzelquelle) mit Hinweis "Pilot offen". Quelle: R3.
4. Neue Regel "InputMap und Fokus vor dem dritten Dialog", Marker **[H]**. Quelle: Repo-Befund (`start_menu.gd` Z. 71, nur 2 Fokus-Treffer).
