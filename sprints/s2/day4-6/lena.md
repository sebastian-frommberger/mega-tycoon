# Lena – Sprint 2, Tag 4–6
(Tageseinträge sind Arbeitsreihenfolge, keine gemessenen Kalendertage. Nichts hier ist an Testern gemessen.)

## Daily Tag 4 (19.11.)
Gestern: Entscheidungsrunde D1–D14. Heute: drei L-06-Fehler final gegen D9/D11, Felix' Spike-Felder geprüft. Blocker: `day4-6/felix/spike/` ist byte-identisch mit Tag 1–3, keine `felix.md`; D9-Felder (`n_lkw`, Streckenlänge in Feldern, kanonischer Ort) sind beschlossen, nicht geliefert.

## Daily Tag 5 (20.11.)
Gestern: Fehlerdoku. Heute: L-05-Material final unter D1, Takt-Tarife mit Tobias' Modell neu gerechnet, Pilot mit mir allein. Blocker: keine Tester (B5 nicht belegt, keine `katrin.md`), keine zweite Person, kein Raum. 3 echte Runden hier nicht möglich.

## Daily Tag 6 (23.11.)
Gestern: Pilot-Korrekturen. Heute: D12/D13 in `concept/lena.md` und `leitplanken.md`, Widerspruchsliste aktualisiert. Blocker: keiner; Freigabe des Leitplanken-Eintrags durch Jonas offen.

## Ergebnisse
- **L-06 Fehlerdoku: fertig aus Design-Sicht, Gegenzeichnung offen.** `lena/l06_fehler_final.md`. AK „3 Fehler mit Wurzelursache bis 19.11.“: **ja** (Wurzelursache, Soll-Kette, Zählregel, Titel `T_STEHT`, Produkttitel dokumentiert, kanonischer Ort je Fehler). F3 ist mit `fuell_ist/soll` + `n_lkw` lösbar, ohne `n_lkw` ein Build-Fehler. **Annahme:** Felder nach D9, Spike hat `stock`/`needed`/`length`/`single`, kein `n_lkw`.
- **L-05 Material: fertig; Durchführung: wartet auf echte Tester.** `lena/l05_material.md`. AK „3 Runden, ≥ 2/3 Kette, 3/3 Kapital, ≥ 2/3 Kaufwunsch“: **nein** (0 Runden, nur Pilot „zählt nicht“). Pilot fand 7 Materialfehler (Hafen nur 2 Industrien, Lizenzablauf in Takt 6 statt 5, Mitlizenznehmer-Tarif falsch, Kaufangebot ohne Nutzen, Kreditkarte fehlte, Chips, Bogenfeld), alle korrigiert. Befund aus Rechnung: Kauf bringt +50 bis +250 $/Takt, zahlt sich im Lauf nie aus; K3 misst Wunsch, nicht Rechnung.
- **Konzept D12/D13: fertig.** `concept/lena.md` (Meta-Loop 1, Phase 1, Meilensteine 1a/1b, 3, 5b, 7, Stufen-Tor, 60-k-Hinweis), `concept/leitplanken.md` (Start-Satz), alle datiert. `city.md`/`hq.md`/`industry.md` bis GDD offen.
- **Widersprüche:** `day1-3/lena/widersprueche.md` Kopf: 12 entschieden, 1 vertagt, 1 teilweise, 2 im Material gelöst, 8 offen (keiner gate-relevant).

## Annahmen und offene Fragen an andere (mit Namen)
- **Felix:** `n_lkw` je Lager (geskriptet reicht), `fuell_soll` = 40, Länge in Feldern, Gleiszahl, `ursache.pos == kette[-1].pos` bei F1/F2 im Code. Fehler ≥ 120 s sichtbar.
- **Aylin:** F2 auf 4 Züge (6 Zeilen), F6 streichen, Validator V3 auf `pos`.
- **Daniel:** Soll-Tabelle ersetzen, Smoke-Prüfpunkt „Zeile 5 bei F3“.
- **Katrin:** 3 Nicht-Designer, Raum, Einwilligung, zweite Person für L-05. Ohne Tester bis 23.11. fehlt der G5-Messwert.
- **Tobias:** Takt-Tarife (Abschnitt 5 in `l05_material.md`) gegenlesen, `day4-6/tobias/` war leer. Annahme: T-05 vom 18.11. gilt.
- **Jonas:** Leitplanken-Eintrag freigeben.

## Risiko für das Sprintziel
G5 hat am 27.11. nur den Rechenteil (R, 4/4), der M-Teil (Kaufwunsch) fehlt ohne Tester; nach D8 ist ein fehlender Messwert in G1–G5 ein Vertagungsgrund. G1 hängt an Feldern, die Felix bis 20.11., 12:00 liefern soll und am 19.11. nicht im Spike sind; ohne `n_lkw` ist F3 unlösbar und der Test misst 2 statt 3 Fehler.
