# Refinement Sprint 8 – Briefing (Stand 04.11.2026)

Repo /home/claude/mega-tycoon ist NUR LESEN. Du schreibst nur nach /tmp/claude-0/gd/s8ref/. Deutsch, knapp, mit Belegen (Pfad + Zeile oder Befehl). Nichts erfinden; Ungeprüftes als "nicht geprüft" markieren. Aufwände als Schätzung mit Marke [E] Einzelschätzung / [R] aus Repo abgeleitet / [M] gemessen.

## Auftrag
Sprint 8 wird neu zugeschnitten. Ursprünglich geplant (charter.md): Firmenkauf, Skilltree, Progression nach M7. Auftraggeber Basti hat nach seinem Rundgang durch den Prototyp "Welt" (Phase 5) entschieden: Sprint 8 soll **einen wirklich testbaren Loop** liefern (er spielt 30–45 min am Stück, mit Fuhrwerken/Kutschen, Lizenz, Linien, Kredit, Zielen) und **Bodentexturen verbessern**. Firmenkauf/Skilltree/F4–F7 sind damit nicht gesetzt.

Dieses Dokument ist der Rahmen für die Refinement-Runde im Format von Sprint 7 (`sprints/s7/refinement/brief.md`, `design.md`, `tech.md`, `ux_art.md`, `ergebnis.md`): je Rollengruppe ein Beitrag, danach fasst PO Jonas zu einem Sprint-Backlog zusammen. Lies das Format in `sprints/s7/refinement/ergebnis.md` (Sprintziel, Tickets ID | Ticket | Owner T | Akzeptanz | Folge, Arbeitsblöcke mit Merge-Gates, Kapazität je Person, Stretch, Puffer).

## Pflichtlektüre
1. `sprints/s8/planung/loop_s8_2026-11-04.md` – Bestandsaufnahme + Muss/Soll/Kann + Etappen + Streichliste + Entscheidungen D1–D6 (Entwurf eines Recherche-Agenten, NICHT refined, nicht vom Team bestätigt). Prüfe seine Aussagen stichprobenartig gegen den Code.
2. `sprints/s8/feedback_03-11/basti_feedback_03-11.md` – Bastis Rückmeldung, Auftraggeber-Vorgabe.
3. `sprints/s8/design-sprint/charter.md`, `sprints/s8/fortbildung/resuemee_2026-11-03/` (alle für deine Rollen), `sprints/s8/fortbildung/referenzen_2026-11-03/`, `sprints/s8/fortbildung/lenses_2026-11-03/`.
4. `sprints/s7/refinement/ergebnis.md` + `sprints/s7/review_retro.md` (Format, Kapazität, Lehren: Schätzungen waren zu optimistisch, Retro-Muster).

## Weitere Vorgaben von Basti aus dem Chat (04.11.)
- Alles muss ins Agile/Scrum-Setup des Teams eingebettet werden (Refinement, Backlog, Sprintziel, Definition of Done, Review, Retro).
- Kutschen "richtig" testen: Wo kauft man sie, wo werden sie gewartet, Kapazität/Kosten/Verschleiß, erste neue Modelle nach X Jahren und wie viel besser.
- Wie werden Waren geliefert (Verladestelle?), wie an Produktion/Städte übergeben.
- Lange Strecken dürfen kein Exploit sein (Ertrag = Luftlinie, Zeitfaktor; bei 150 m/s fast wirkungslos).
- Sind Städte teilweise selbstversorgend, reisen Menschen auch ohne uns? (Heute: nein, nicht modelliert.) Siehe D7.
- Fahrzeuge fahren bei 1x 150 m/s: viel zu schnell. See = Kulisse (Kartentyp Flusstal), Gewässer je Kartentyp Level-Design-Entscheidung.
- Bodentexturen: Basti will, dass daran geschraubt wird; Stellen mit Screenshots stehen noch aus.

## Annahmen bis Basti entscheidet (Empfehlungen aus dem Entwurf; markiere Tickets, die an einer Entscheidung hängen, mit "hängt an D<n>" und gib die Alternative mit Aufwandsdelta an)
D1 Loop läuft auf Welt-Prototyp + ProtoSim · D2 Fahrzeugtempo k=4–8 im A/B mit Ertragsausgleich · D3 Bauumfang: Lizenz, Linie, Halt, gerader Stichweg auf festem Netz · D4 erst ohne zweite Kette · D5 Kutschen-Lebenszyklus: Kauf, Unterhalt, Alterung, Ersetzen; Test-Kalender 3 min/Jahr (Zwei Uhren) · D6 Bodentextur parallel durch Tech Art, 2 PT, an Bastis Stellen · D7 Eigenversorgung der Dörfer nicht in S8.

## Rahmen
- Kapazität 8 T je Person und Sprint (10 Arbeitstage), Puffer einplanen; Engpässe Mira, Felix. Rollen: Jonas (PO), Lena (Game Design), Tobias (Ökonomie), Aylin (UX), Sophie (Art/Art Direction), Technical Artist (TEAM-02), Stadt-/Level-Design, Felix (Lead Dev), Mira (Gameplay/UI), Daniel (QA), Katrin (Produktion).
- Definition of Ready je Ticket: Akzeptanz messbar, Abhängigkeit benannt, Schätzung mit Marke, Test-/Messweg. Definition of Done: Regression grün (Stufen: schnell < 5 min, voll nachts), Abnahme durch die benannte Rolle, Doku/Lernlog-Zeile, für Basti prüfbarer Stand mit Aufgabenkarte.
- Keine Schönfärberei. Wenn etwas nicht in einen Sprint passt, sag es und schlage einen Schnitt vor.
