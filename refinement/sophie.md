# Refinement S2 – Sophie (Art / Tech Art)

## Meine Tickets

**S-03 Look-Test Diorama vs. Karte – Spike, 4 T (statt 5)**
Leitfrage: Bleibt das Netz bei > 800 m als Karte lesbar, und bis zu welcher Kartengröße trägt das noch? Ergebnis: Entscheidung „Zoom-Blend ja/nein“ und eine Lesbarkeitsgrenze, die in F-08 einfließt.
- Testszene: 1 Stadt, 2 Industrien, Strecke, 200 MultiMesh-Quader, `map_blend` über drei Zoomstufen, kein Popping
- 4 von 6 Kollegen finden Stadt, Industrie und Strecke in der Kartenstufe in < 10 s
- 2-Minuten-Video plus eine Seite Entscheidung im Wiki bis 20.11.
- Abhängigkeit: Ich baue die MultiMesh-Szene selbst, von Felix brauche ich nur 0,5 h Review zu `visibility_range`. Damit ist sein Blocker weg.

**S-04 Kamera, Nebel, Licht – teilen**
Kamerakurve 30°→70° und Höhennebel kommen in S-03 rein, weil der Look-Test ohne die nichts aussagt. SSAO-Vergleich und `.tres`-Environment werden Kanban-Karte, Start nach dem Gate. Im Sprint: 0 T extra.

**S-05 Farbatlas und Farbsehschwäche – Kanban-Asset, 1,5 T**
Ergebnis: Palette v1 mit Statusfarben und Formen Kreis/Dreieck/Achteck.
- Statusfarben und -formen bis 21.11. im Testbuild-Overlay (F-06)
- Simulator-Check Deut/Prot/Trit für die Statusfarben, Protokoll der Kollisionen
- Güterfarben für alle 7 Familien erst dann, wenn Tobias die Liste hat → ohne Liste bleibt die Karte in „Briefing“.

**S-06 – teilen**
- *Asset-Liste Vertical Slice*: Sprint, 1,5 T, weil sie Gate-Input für Katrin (K-07) ist. AK: alle VS-Assets mit Polybudget, LOD, Owner, PT; mit Katrin abgestimmt bis 25.11.
- *Silhouetten-Sheet*: Kanban, 1 T, nur die 6 VS-Industrien. Blindtest ≥ 90 % mit 5 Leuten. Die restlichen 5 Typen **schiebe** ich auf R2, die Industrieliste ist eh noch nicht final.

## Einwände

1. **F-08 Kartengröße entscheidet Felix allein.** Nein. 1.024² ist auch eine Lesbarkeitsfrage, nicht nur eine Frage von Speicher und float32. *Gegenvorschlag:* F-08 schließt am 20.11. gemeinsam ab, Felix liefert die Tech-Zahlen, mein S-03 die Lesbarkeitsgrenze. Das gehört so ins Sprintziel.
2. **Diagnose-Playtest ist fünfmal geplant**: L-06, K-06, Daniels, Aylins und Jonas' Ticket. Das sind zusammen über 10 Personentage für einen Test. *Gegenvorschlag:* Ein Ticket L-06, Owner Lena. Katrin nur Logistik mit 1 T, Daniel protokolliert, Jonas beobachtet ohne eigenes Ticket. Ein Szenario, nicht 3, 5 und 3 Fehler parallel.
3. **F-05/F-07 wollen Platzhalter-Meshes von mir.** Spikes sind Wegwerfcode. *Gegenvorschlag:* Im Bau-Spike reichen Grauboxen, das Gleisprofil kommt im Spline-Termin KW 49. Für den Benchmark gebe ich nur das Ziel-Polybudget (Lkw 300 Tris) als Zahl vor, damit die 2 ms realistisch gemessen werden.
4. **L-04 Skilltree-Tabelle und L-05 Paper-Prototyp** tragen nichts zum Go/No-Go bei. *Gegenvorschlag:* Beide auf S3 schieben, Lena gewinnt 5 SP für L-06.
5. **T-07 Headless-Sim** hängt an Felix' SimWorld, und Felix ist schon über 100 %. *Gegenvorschlag:* Auf S3 schieben, Tobias validiert in der Tabelle weiter.
6. **J-05 reviewt nur drei Spikes, Look kommt nicht vor.** Damit ist Art wieder Nebensache. *Gegenvorschlag:* S-03 wird vierter Review-Gegenstand, kostet Jonas 0,5 T.

## Meine Kapazität und Forderung

| Ticket | Typ | Tage |
|---|---|---|
| S-03 Look-Test inkl. Kamera und Nebel | Spike | 4 |
| S-06a Asset-Liste VS | Sprint (Gate) | 1,5 |
| S-05 Statusfarben und Palette v1 | Kanban | 1,5 |
| S-06b Silhouetten 6 VS-Industrien | Kanban | 1 |
| **Summe** | | **8** |

Im Sprint-Commitment stehen nur 5,5 T, der Rest läuft auf Kanban mit WIP 2.

**Ich fordere:**
- Das Sprintziel bekommt den Zusatz: „… und der Look-Test hat die Kartengröße mitentschieden.“
- F-08 wird erst nach S-03 final.
- Katrin gibt die 3D-Artist-Stelle diese Woche frei. Sonst steht das Kanban-Board ab Januar leer, und der Vertical Slice hat keine Assets.
