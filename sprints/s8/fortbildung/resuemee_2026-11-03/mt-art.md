# Artist: Resümee (Stand 03.11.2026)

Pfade relativ zu `/home/claude/mega-tycoon/`. [Beleg] = im Repo oder in der Quelle nachgelesen/nachgerechnet, [Eindruck] = meine Einschätzung.

## 1. Wie ich Spiel und Konzept heute sehe

Kern: Ein Transport-Tycoon ab 1820 auf 512² Feldern à 25 m (12,8 km), gelesen aus der Vogel- bis Stadtperspektive. Die Charta-Regel E1 "nichts überzeichnet" gilt: fahrzeuge 0,9-1,2x real. [Beleg: `sprints/s8/design-sprint/charter*`, `concept/leitplanken.md`]

Was trägt: Kenney-Kit plus Eigenbau, ein Prefab = ein Mesh/eine Surface/ein Material, Import-Faktor je ROLLE (`faktor_szene = Ziel_m / Modell_u / 25`), geteilte Palette (20 Klassen x 5 Stufen). [Beleg: `sprints/s3/` S-07, `sprints/s4/` S-08, `sprints/s8/design-sprint/phase3/14*`] Die Dorfansicht in `phase4/bilder` liest sich: Häuser, Wald, Acker unterscheidbar. [Eindruck]

Was noch Papier ist: alle Assets für Epoche W2/W3 (Pack-Check frühestens S9), das Pferd, Ersatzneubau-Varianten (K23). [Beleg: `sprints/s8/design-sprint/asset_audit*`]

## 2. Entwicklungsverlauf S2-S8

- S2: erste Kenney-Messung, Kit-Faktor als Notlösung (Zähler 1). [Beleg: `design/art/day4-6/kenney_messung.md`]
- S3: S-07 Kenney-Import, zweiter Kit-Faktor. [Beleg: `sprints/s3/`]
- S4: S-08 Palette-Token; Marker #FFC21A, Ghost weiß mit Saum #0F1720. [Beleg]
- S6: S-13 Props x1,25-2,4 gestreckt; SP-03-Spike. [Beleg: `sprints/s6/zocken/sophie_sp03.md`]
- S7: Basti-Feedback 01-11, Maßstab erneut Thema. [Beleg: `sprints/s7/`]
- S8: Design-Sprint, Welle 1/2, Fixpass W2, Aufgabenkarten v1.1. [Beleg: `phase4/`]

## 3. Was gut lief

- Rollen-Faktor + Prefab-Regeln R1-R6 beenden das "pro Modell neu schätzen". [Beleg: `phase3/14*`]
- Palette-Tokens: Marker/Ghost mit Saum bleiben auf allen Untergründen lesbar. [Beleg: S-08]
- Messen statt Raten: `kenney_messung.md` hat die Kit-Maße belegt, bevor wir gebaut haben. [Beleg]

## 4. Was nicht gut lief (Kompromisse mit Zähler)

| Kompromiss | Zähler | Beleg |
|---|---|---|
| Maßstab-Überhöhung (Props, Fahrzeuge) | 3 (S2, S6, S7) | S-13, Feedback |
| Kit-Faktor statt Eigenbau | 2 (S2, S3) | s2/s3 |
| Kenney-Teil passt nicht, Eigenbau nötig (Steg, Boot, Floß, Marktstand, Mühlrad, Turmhelm, B3/B4/B5/B7) | mindestens 7 | `phase4/ta_welle2*` |
| Pferd als Kenney-Block-Behelf | 3+ | asset_audit |
| Gebäude einfärben statt neu modellieren | 2 | phase4 |
| 25-m-Raster-Treppen sichtbar | mindestens 5 | phase4/bilder |
| Lok-Längsfaktor 1,341 (9,04 m, 1,19x) | 1 | s. u. |

Konkreter Widerspruch im Repo: Die Lok bekommt Längsfaktor 1,341 (9,04 m, 1,19x real). K10 sagt 1,13 (7,6 m), `10_asset_mapping` R2 ebenso, und ich selbst hatte "Kessel oval" eingewandt. [Beleg: `phase2/10*`, `phase4/ta_welle2*`] Das ist ein Zahlendreher zwischen Rollen, kein Geschmacksthema.

Widerspruch zu den anderen Rollen: Als Artist halte ich die Lok-Streckung und den Pferd-Behelf für vertretbar, solange die Silhouette trägt. Die Art Direction misst strikt an E1 (1,19x ist am Rand der Toleranz, nicht darunter), und die Technik würde jede Streckung lieber über den Import-Faktor als per Hand lösen. Ich halte dagegen: Eine saubere Silhouette schlägt 5 % Maßtreue, solange wir es offen als Kompromiss führen (Zähler oben). [Eindruck]

## 5. Risiken (nach Eintrittswahrscheinlichkeit)

1. Asset-Lücke W2/W3: Der Pack-Check kommt erst S9; bis dahin wissen wir nicht, ob Epochen-Look überhaupt stimmt. Sehr wahrscheinlich. [Beleg: asset_audit]
2. Weitere Kenney-Teile passen nicht: Trend steigt (7+). [Beleg]
3. Pferd bleibt Behelf und fällt in der Nahsicht auf. [Eindruck]
4. Lizenzklärung Quaternius bleibt offen. [Beleg: Web blockiert, s. 7]
5. Farbkontrast nur gerechnet, nicht getestet. [Beleg: `aylin_kontrast_g3_wasser.csv`]

## 6. Drei Empfehlungen für Sprint 8

1. **Lok-Längsfaktor entscheiden** (1,341 vs. 1,13): ein Maß am Modell nachmessen, Entscheidung in `decisions` schreiben. Aufwand 0,5 h Messung + 0,5 h Anpassung.
2. **Pferd lösen**: Quaternius-Pferd (CC0, laut Repo-Notiz) einbauen oder bewusst als Ersatz streichen. Aufwand 0,5-1 Tag inkl. Import nach R1-R6.
3. **Pack-Check W2/W3 vorziehen**: Liste "Pflichtteile pro Epoche" und Abgleich gegen vorhandene Packs. Aufwand 1 Tag; vermeidet, dass S9 mit leerer Hand startet.

## 7. Recherchen dieser Runde und Lernlog

**Quaternius-Lizenz (Pferd).** Frage: Ist das Pferd-Modell CC0 und kommerziell nutzbar? Quellen: quaternius.com Packseite, vom Abruf-Tool geblockt (PROVENANCE_REQUIRED), nicht umgangen; Aussage "CC0" nur aus Repo-Notiz. Ergebnis: ungeprüft im Web. Konfidenz: mittel (nur Repo-Beleg). [Beleg: asset_audit]

**Gang-Phase und Halbfloat** (zusammen mit TA): INSTANCE_CUSTOM.x ist in Compat Halbfloat, die Gangphase über 240 m springt sichtbar (bis 17° Beinphase). Folge für mich: Animations-Pivots (UV2 part*100+pivot) bleiben, aber die Phase muss anders kodiert werden. Quelle: Godot MultiMesh-Doku; Rechnung im TA-Resümee. Konfidenz: hoch (Rechnung), mittel (Sichtbarkeit, nicht in Godot getestet, keine Engine im Sandkasten). [Eindruck]

Nicht recherchiert (Zeitbudget): Colormap vs. Vertex-Color, Kitbash-Regeln (offene Lücken C2).

Lernlog-Zeilen:
- 2026-11-03 | Lok-Längsfaktor 1,341 gegen K10 1,13 übernommen ohne Gegenmessung | Lücke: Rolle-Faktor ohne zweite Quelle | Zähler 1
- 2026-11-03 | Pferd als Block-Behelf akzeptiert | Kompromiss: Platzhalter statt Modell | Zähler 3+
- 2026-11-03 | Kenney-Teil passt nicht, Eigenbau | Kompromiss | Zähler 7+

## 8. Vorschläge für Skill-Änderungen (nur Vorschläge)

Zeilennummern habe ich nicht gesichert; Verortung nach Abschnitt in `sprints/s8/fortbildung/mt-art/SKILL.md`.

1. Abschnitt C2 (offene Lücken): Pferd-Eintrag ergänzen "Quaternius-Pferd geplant, Lizenz nur aus Repo, Web ungeprüft" [~], Quelle: asset_audit.
2. Regelabschnitt Maßstab: "Lok-Faktor immer gegen K10/R2 gegenprüfen, Abweichung >5 % melden" [M], Quelle: `phase4/ta_welle2*` vs. `phase2/10*`.
3. Lernlog-Regel: Kompromiss-Zähler ab 3 automatisch als Entscheidungsvorlage an Basti, Quelle: Tabelle oben [Eindruck].
