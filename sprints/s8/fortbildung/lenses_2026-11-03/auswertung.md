# Auswertung Pilot Schell-Linsen (Lena, 03.11.2026)

Vergleichsbasis: Gesamtresümee (`sprints/s8/fortbildung/resuemee_2026-11-03/`), Referenzen (`.../referenzen_2026-11-03/`), Skill/Lernlog (`.../mt-gamedesign/`), Konzept und Regelwerk. Pfade relativ zu `/home/claude/mega-tycoon/`. Details: `/tmp/claude-0/gd/lenses/pilot_lena.md`.

| # | Befund | Linse | Schon im Material? | Beleg (Datei) | Wert für Entscheidung |
|---|---|---|---|---|---|
| 1 | Epochenlänge = später erfüllte Bedingung (Frühestdatum oder Tor); bei 12 min/Jahr bindet immer der Kalender (W1 = 6 h), das Tor ist wirkungslos → Wartezwang | #27 | teilweise | `resuemee/mt-gamedesign.md` §5.4 (1,5–4 min/Jahr passend), `referenzen/fortschritt.md` §2 („nie beides als Blockade“) | hoch |
| 2 | Tempostufen (Wanduhr, Komfort) und Zwei Uhren (Kalender zu Wirtschaft, Design) sind zwei Regler, keine Alternativen | #27 | teilweise | `referenzen/zeitreise.md` §1/Idee 1 vs. `referenzen/fortschritt.md` §1/Idee A (als Konkurrenz behandelt); Regelwerk F7 C beschreibt nur Zwei Uhren | hoch |
| 3 | Zwei Uhren ≠ 12 min/Jahr machen alle Jahresgrößen widersprüchlich (Zins p.a. im UI, K23 „1 % je Spieljahr“, Lebensdauer); `spieljahr_ticks` ist im Code fest = 12 Monate | #48, #63 | neu (verwandt: „Preise zeitlos“) | `slice/data/economy_constants.json` Z. 3; `referenzen/oekonomie.md` §1; `15_regelwerk_v1_1.md` K23 | mittel |
| 4 | Interessenkurve von Testern zeichnen lassen und mit Annahme vergleichen | #69 | neu (Methode) | kein Treffer im Material; „drei Zeitebenen“ selbst steht in SKILL A10 | mittel |
| 5 | Nachzügler-Druck ist Strafe; besser Bonus für vollständigen Pfad, Vorwarnung | #47 | ja | `referenzen/zeitreise.md` §2 (Civ VII, EU4); `concept/lena.md` Z. 68–69 | gering |
| 6 | „+8 % Ausstoß“ verliert durch Grenzpreis-Sättigung Wert (≈ +7,6 / +5,7 / +0,9 % bei 100 / 120 / 160 % Versorgung); `B_skill` wirkt nach der Sättigung und bringt immer +8 %; an Industrien kappt der Abnahmedeckel | #35 | neu (Frage war offen, Antwort fehlte) | `slice/economy.gd` Z. 13–16, 75, 353–364, 774–785; offene Frage in `sprints/s7/block-b/g01_progression.md` §6 Frage 2, SKILL A9 | hoch |
| 7 | Prozentränge verstärken die dominante Kette (Zug 2,9:1): „alle Ränge auf die stärkste Kette“ ist dominant | #39 | teilweise | `resuemee/mt-oekonomie.md` §5.4 | mittel |
| 8 | Quote hängt am Tempo: 40 Punkte ≈ 1 je 11 min (7,5 h) oder 1 je Stunde (41 h) → (A) vor (B) entscheiden | #27 | ja | `resuemee/mt-gamedesign.md` §5.5, `referenzen/fortschritt.md` §1 (Jonas) | mittel (bestätigt Reihenfolge) |
| 9 | Spätere Belohnungen größer (Schlüssel-Fähigkeit statt weiterer Ränge) | #46 | ja | SKILL A9, `concept/tobias.md` Z. 136, `referenzen/fortschritt.md` §3 | gering |
| 10 | Variable/zufällige Belohnung | #46 | neu | – | gering, verworfen (widerspricht D21 „Etappe = Punkt“) |
| 11 | Skillpunkte: Ausgeben ist Wahl, Verdienen kaum | #52 | teilweise | `g01_progression.md` §4, Streitprotokoll `sprints/s7/refinement/ergebnis.md` | gering |
| 12 | „Firmenkauf“ meint zwei Dinge: C1 Industrie kaufen (kein KI-Bedarf) und C2 KI-Firma übernehmen | #2 | teilweise | `concept/industry.md` Z. 5–21 (C1) vs. `referenzen/oekonomie.md` Idee 4, `referenzen/zeitreise.md` Idee 5 (C2) | hoch |
| 13 | C1 als unbefristete Lizenz (`s_lic_until`) abbildbar, ohne Besitzfeld | #48 | neu (Annahme, nicht geprüft) | `slice/economy.gd` Z. 113 | mittel |
| 14 | Lizenz→Kauf hat schon Risiko-Lohn-Form, aber keine EV-Rechnung (Werksmarge fehlt) | #40, #35 | teilweise | `concept/industry.md` Z. 19, 72 | mittel |
| 15 | KI-Übernahme eigener Firmen braucht sichtbare Schwäche vorher | #47 | ja | `referenzen/oekonomie.md` §3 | gering |
| 16 | Jonas' Firmenkauf-Entscheid ist widersprüchlich dokumentiert („gestrichen bis Konkurrenz“ vs. „Stufe 1 in S9“) | keine (beim Lesen) | neu | `referenzen/zeitreise.md` §7 vs. `referenzen/oekonomie.md` „Jonas: Umfang“ | hoch |
| 17 | Klare Ziele, kurze/lange Ziele, Wahl mit zwei Optionen, sichtbarer Fortschritt | #21, #32, #39, #55 | ja | SKILL A1, A8, A10; `g01_progression.md` §2, §4 | gering (Leerlauf) |
| 18 | Risiken benennen, Tests mit Leitfrage planen | #16, #103 | ja | LERNLOG („Test mit Menschen vertagt“, Zähler 4), `resuemee/mt-po.md` §6 | gering (Leerlauf) |

Zählung: 18 Befunde; neu 6 (davon 1 verworfen, 1 nicht durch eine Linse, 1 nur Annahme), teilweise 6, schon da 6. Hoher Wert: 5 Befunde (1, 2, 6, 12, 16), davon nur Nr. 6 vollständig neu und linsengetrieben.

## Fazit

1. Die Linsen haben für Lena wenig Neues gebracht: von 18 Befunden waren 12 ganz oder teilweise schon im Resümee, in den Referenzen oder im SKILL, weil dort bereits Flow, Zieldichte, Wahl mit zwei Optionen und „Fähigkeiten statt Prozente“ als Checklisten stehen (SKILL A8–A10).
2. Echten Mehrwert lieferten zwei Linsen, die zum Rechnen oder Zerlegen zwingen: #35 Expected Value beantwortet G-01-Frage 2 rechnerisch aus `economy.gd` (Ausstoß-Ränge verlieren unter Sättigung, `B_skill` nicht), und #27 Time trennt Tempostufen von Zwei Uhren und zeigt, dass bei 12 min/Jahr das Epochen-Tor nie bindet.
3. Leerlauf und Checklisten-Theater waren #21, #32, #55, #16, #103 und #53 (bestätigen nur Bekanntes) sowie #46 mit dem Rat zu zufälligen Belohnungen, der unserem Klarheitsprinzip D21 widerspricht; der wertvollste Fund zu (C), Jonas' widersprüchlicher Entscheid, kam vom Gegenlesen der Dateien, nicht von einer Linse.
4. Ein breites Ausrollen auf alle Rollen lohnt sich nicht; gezielt lohnt es sich für Tobias (Ökonomie) mit #35 Expected Value, #39 Meaningful Choices (dominante Strategie) und #52 Economy, weil diese Linsen in Rechnungen am Code münden, und für Lena nur #27 Time und #69 Interest Curve (mit von Testern gezeichneter Kurve als neuem, billigem Messweg).
5. Für Aylin (UX) und Jonas (PO) erwarte ich keinen Gewinn: #63 Feedback und #16 Risk Mitigation, #103 Playtesting decken sich mit ihrer vorhandenen Diagnose-Recherche und Prozessdisziplin; die Linsen ersetzen weder Bot-Läufe noch Fremdtests, die in vier Sprints vertagt wurden.
