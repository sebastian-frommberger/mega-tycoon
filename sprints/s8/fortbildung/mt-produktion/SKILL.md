---
name: mt-produktion
description: Nutze dieses Skill, wenn Katrin (Produktion/Scrum Master) bei Mega Tycoon Sprints plant, Gates und DoD definiert, schätzt, Risiken steuert, Retros fährt, Aufgabenkarten und Verträge für KI-Agenten schreibt oder Merges und Messungen absichert.
---

# mt-produktion: Katrin, Fachwissen und Projektwissen

Stand: 03.11.2026. Kennzeichnung: [Konsens] viele Quellen, [Streit] Quellen widersprechen sich, [Einzel] eine Quelle oder Blogmeinung. Projektwissen (Teil B) nennt Repo-Quellen relativ zu /home/claude/mega-tycoon. Was nicht lesbar war, steht am Ende von Teil A. Teil C zuerst lesen, wenn eine Entscheidung auf diesem Skill beruht.

---

# TEIL A: Allgemeines Fachwissen

## A1. Scrum und Kanban für kleine Teams

- Scrum Guide: Sprints sind Events fester Länge von höchstens einem Monat. Das Sprint Goal ist "das eine Ziel des Sprints". Scrum Team typisch höchstens 10 Personen. Nur der PO kann einen Sprint abbrechen. Die Retro plant Wege zu mehr Qualität und Wirksamkeit; die wirkungsvollsten Verbesserungen kommen so früh wie möglich ins nächste Sprint Backlog. Der Guide nennt Burn-down, Burn-up und Cumulative Flow als Prognosehilfen, aber "sie ersetzen nicht Empirie". Eine Definition of Ready nennt er nicht. Velocity auch nicht. [Konsens]
  https://scrumguides.org/scrum-guide.html
- Kanban Guide: drei Praktiken (Workflow definieren und visualisieren; Items aktiv steuern; Workflow verbessern). Flow-Metriken: WIP, Throughput, Work Item Age, Cycle Time. Service Level Expectation als Prognose, Beispiel "85 % innerhalb von 8 Tagen", gestützt auf historische Cycle Time oder erste Schätzung. WIP-Limit erzeugt ein Pull-System; Überschreiten soll "selten und ausdrücklich" in der Definition of Workflow stehen. [Konsens]
  https://kanbanguides.org/fr/the-kanban-guide/2020.7/
- Hybrid (Scrum für Technik, Kanban für Kunst, Meilensteine auf Makroebene) ist verbreitet, die Quelle belegt es nicht. [Einzel]
  https://kindatechnical.com/game-development/project-management-for-game-studios.html
- Konsequenz für uns: Kunst-Kanban mit WIP-Limit pro Person und Alter des Items sichtbar machen; Sprint-Technik mit Sprint Goal und Schnittlinie.

## A2. Definition of Ready und Definition of Done

- Definition of Done: formale Beschreibung des Inkrement-Zustands bei Erfüllung der Qualitätsmaße. Arbeit zählt nur, wenn sie die DoD erfüllt. [Konsens]
  https://scrumguides.org/scrum-guide.html
- Definition of Ready: [Streit]. Cohn: eine DoR mit 100-%-Pflicht ist "ein großer Schritt zu einem sequentiellen Stage-Gate-Ansatz", also Wasserfall; Überlappung von Arbeit sei ein Kennzeichen agiler Teams. Er empfiehlt Richtlinien statt Regeln (Beispiel: Mockups "begonnen und weit genug", dass offene Fragen im Sprint geklärt werden können). Ausnahmen: harte Abhängigkeit von anderem Team oder Lieferant; Größenobergrenze. Er hat nichts dagegen, wenn ein Team eine leichte Liste nutzt.
  https://mountaingoatsoftware.com/blog/the-dangers-of-a-definition-of-ready
  Gegenseite (Pichler u. a.): Seite war nicht abrufbar, daher nicht belegt. Eigene Einordnung: Bei KI-Agenten ohne Rückfragemöglichkeit ist eine "Ready"-Prüfung (Aufgabenkarte vollständig) fast Pflicht, weil der Agent nicht nachfragt (A8).

Prüfliste "leichte Ready-Richtlinie" (statt Gate):
1. Akzeptanzkriterium mit Zahl und Messart.
2. Abhängigkeit von anderem Team als Datei vorhanden oder als Annahme markiert.
3. Eigentümer der Dateien benannt.
4. Größe unter einer Obergrenze (bei uns: unter 1 Sprint-Tag je Karte als Richtwert, nicht aus Quelle).

## A3. Gates und Exit-Kriterien

- Kriterien vor der Messung festlegen; Schwellen im Gate nicht verhandeln. [Konsens, eigene Praxis belegt in B3]
- Beispiel-Exit-Kriterien aus Blog (unbelegt): Beta "unter 10 B-Bugs", Gold "keine bekannten Ship-Blocker", Pre-Production-Exit "alle großen technischen Risiken gelöst". Das sind Beispiele, kein Industriestandard. [Einzel]
  https://kindatechnical.com/game-development/project-management-for-game-studios.html
- Meilensteine mit dem Auftraggeber definieren, sonst droht monatelanger polierter Vertical Slice und "Demo Hell". [Einzel, oft zitiert]
  https://gamedeveloper.com/production/do-you-have-a-firm-definition-of-your-milestones-
- Cohns Kritik an starren Gates (A2) gilt für Fertigstellungs-Gates zwischen Arbeitsphasen, nicht für Qualitäts-Gates mit Messwert. Unterschied: Ein Gate, das Information liefert (Go/No-Go/Vertagen), blockiert nicht den Fluss.

Gate-Regeln, die sich bewährt haben (Projekt, B3): Belegstufen M/V/R/O; Plan B = Gelb-Deckel; drei Gelb = Vertagen, kein No-Go.

## A4. Schätzen und seine Grenzen

- Cone of Uncertainty (McConnell/Construx 2010): Schätzung im Initial Concept kann um Faktor 4 zu hoch oder 4 zu niedrig liegen (Spanne 16x); mit kurzen Iterationen sinkt die Variabilität von 4x auf 1,6x; nach UI-Design auf etwa +/-25 %. "Der Kegel verengt sich nur, wenn Entscheidungen Variabilität eliminieren." Die Zuordnung der Multiplikatoren zu Meilensteinen ließ sich im PDF nicht auslesen. [Konsens]
  https://www.construx.com/wp-content/uploads/2019/02/CxWhitePaper_ConeOfUncertainty.pdf
  Folge: Unsere +/-25 %-Maßtoleranz im Prototyp ist eine Messtoleranz, nicht dieselbe Größe wie Aufwandsunsicherheit.
- Planungsfehlschluss (Buehler/Griffin/Ross 1994, laut Wikipedia): 37 Psychologiestudenten schätzten die Abschlussarbeit im Mittel auf 33,9 Tage, "alles läuft optimal" 27,4, "schlimmster Fall" 48,6; tatsächlich im Mittel 55,5 Tage; etwa 30 % wurden in der geschätzten Zeit fertig. Gegenmittel: Referenzklassen (Basisraten ähnlicher Vorhaben), Segmentierung (aber kognitiv teuer), Implementation Intentions (konkretes Wann/Wo/Wie). Brooks' Gesetz: Mehr Personal in verspätetem Projekt verspätet eher mehr. [Konsens bei der Psychologie, Wikipedia als Sekundärquelle]
  https://en.wikipedia.org/wiki/Planning_fallacy
- Faustregel "Schätzung mal 2" aus einem gesponserten Blog ist unbelegt. [Einzel]
  https://www.wayline.io/blog/best-workflow-cutting-game-features
- Story Points zu Stunden: die Quelle erklärt die Umrechnung nicht. [Einzel]
- Prognose aus Flow-Daten (Cycle Time, SLE) ersetzt Schätzen teilweise. [Streit: #NoEstimates-Lager gegen Schätz-Lager; hier nicht vertieft gelesen]

Do:
- Referenzklasse nutzen: Wie lang brauchte ein ähnlicher Block in S5/S6/S7? (Daten im Repo, B2.)
- Puffer in Kapazität (80 %), nicht in Einzelschätzungen verstecken.
- Spike mit Leitfrage und Timebox statt Schätzung von Unbekanntem.

Don't:
- Wenige Tage "Aufwand" ohne Messart für die Genauigkeit angeben.
- Annehmen, dass KI-Agenten Aufwand in Personentagen haben. Der Engpass sind Tokens, Limits und Wartezeit (A8, B6).

## A5. Risikosteuerung

- Premortem (Klein, HBR 2007): Team nimmt an, das Projekt sei gescheitert, und sammelt plausible Gründe; Bedenkenträger können früh sprechen. Die HBR-Seite nennt keine Zahl und keine Schritte. Die oft zitierte "30 % mehr Gründe" ließ sich dort nicht bestätigen und wird hier nicht verwendet. [Einzel]
  https://hbr.org/2007/09/performing-a-project-premortem
- Postmortems: häufige Fehler sind Scope und Umfang, zu späte Inhalte, Kommunikationslücken. Gegenmittel: früh kürzen; Freigabeprozess für Dokumente (Iron Lore: Produzent, Lead Designer, Technikleiter, Publisher-Kreativchef zeichnen; verlangsamte etwas); "Szenario vor der Vollproduktion festnageln". [Konsens über viele Postmortems]
  https://www.gamedeveloper.com/business/what-went-wrong-learning-from-past-postmortems
- Scope Creep 52 % der Projekte (PMI Pulse 2018; vor 5 Jahren 43 %); Gegenmittel: Grenzen früh, Änderungsverfahren, Backlog je Sprint pflegen, Lessons Learned. [Einzel, Erhebung]
  https://www.pmi.org/learning/library/scope-creep-rising-11308
- Integrationsfehler zwischen Disziplinen nennt ein Blog "häufigste Fehlerart" (unbelegt). [Einzel]

Risikoregister-Minimum: Risiko, Auslöser mit Datum, Owner, Gegenmaßnahme, Rückfallplan, letzter Check. Auslöser sind Daten (z. B. "20.11. Alternativplan-Skelett"), keine Stimmungen.

## A6. Retro-Formate und Wirksamkeit

- Retromat: Retros verfallen, wenn sie nie zu Änderung führen; Teams "lernen schnell, Retros zu verachten". Neue Phase von etwa 5 Minuten nach "Set the Stage": Stand der letzten Vereinbarungen prüfen. Ein Team schrieb alle Aktionen mit Revisit-Datum (2, 4 oder 6 Wochen) auf Flipchart; erfolgreiche Änderungen wurden dauerhaft, der Rest geändert oder gestrichen. Dauer 20 bis 30 der 60 Minuten. Nicht anklagend fragen; geringe Umsetzung ist ein Systemsignal. [Konsens in der Retro-Praxis, hier eine Quelle]
  https://retromat.org/blog/13-following-up-on-action-items-new-phase/
- Scrum Guide: wichtigste Verbesserung darf direkt ins Sprint Backlog (A1).
- Faustregel: höchstens 3 Maßnahmen je Retro, je mit Owner, Termin und Wirkungsprüfung.

## A7. Branches, Merge, Integration

- Trunk-based Development: Branches unter 24 Stunden; Integrationskosten "praktisch null" unter 24 h und danach nichtlinear wachsend; nach etwa einer Woche koste Integration so viel wie das Feature. Die Seite schreibt 24 h DORA zu, nennt aber keinen Bericht; Kurve ist Eigenaussage der Seite. [Einzel; DORA-Zuordnung unverifiziert]
  https://mergify.com/learn/trunk-based-development/short-lived-branches
- DORA 2025: KI ist ein Verstärker, der Stärken guter und Schwächen schlechter Organisationen vergrößert; rund 90 % der Fachleute nutzen KI (fast 5.000 Befragte); die Instabilität der Auslieferung steigt weiter; "fail fast, fix fast" wurde nicht bestätigt. Kleine Batch-Größe wird in der gelesenen Zusammenfassung nicht erwähnt. [Einzel, Zusammenfassung durch InfoQ]
  https://www.infoq.com/news/2025/09/dora-state-of-ai-in-dev-2025
- Für uns: Ein Branch pro Ticket plus Merge nach Review ist kurz genug, wenn Tickets klein bleiben. Konfliktquelle bleiben gemeinsam genutzte Dateien (B5).

## A8. Arbeit mit KI-Agenten

Aufgabenkarten und Delegation:
- Gute Delegation nennt Ziel, Ausgabeformat, Werkzeug- und Quellenhinweise, klare Grenzen. Vage Aufträge ("recherchiere X") führten zu Doppelarbeit und Missverständnissen; frühe Systeme starteten 50 Subagenten für einfache Fragen. Aufwandsregeln in den Prompt (einfach: 1 Agent mit 3 bis 10 Werkzeugaufrufen; Vergleich: 2 bis 4 Subagenten mit je 10 bis 15; komplex: über 10). [Einzel, Hersteller-Engineering]
  https://www.anthropic.com/engineering/multi-agent-research-system
- Kosten: Agenten verbrauchen etwa 4x, Multi-Agent etwa 15x so viele Tokens wie Chat; Multi-Agent lohnt sich nur für wertvolle Aufgaben; Token-Menge erklärte 80 % der Varianz bei BrowseComp; Opus-Lead mit Sonnet-Subagenten schlug Einzel-Opus um 90,2 % (interne Auswertung). [Einzel, Herstellerzahlen]
  https://www.anthropic.com/engineering/multi-agent-research-system
- Einfach anfangen, Komplexität nur, wenn sie nachweislich hilft; Werkzeugbeschreibung wie Docstring für Junior; Fehler schwer machen (absolute Pfade statt relative eliminierten eine Fehlerklasse). Evaluator-Optimizer passt, wenn Kriterien klar sind. [Konsens in der Praxis, Einzelquelle]
  https://www.anthropic.com/engineering/building-effective-agents
- Streit: Cognition (12.06.2025) rät von parallelen Subagenten ab, weil "Aktionen implizite Entscheidungen tragen und widersprüchliche Entscheidungen schlechte Ergebnisse"; Alternative: ein linearer Agent mit voller Historie. Cognition (22.04.2026) räumt ein: Schreibzugriffe einthreadig halten, schreibgeschützte Subagenten und Reviewer mit frischem Kontext funktionieren; Devin Review fand im Mittel 2 Bugs je PR, davon etwa 58 % schwer; unstrukturierte Schwärme seien "meist eine Ablenkung". [Streit, jüngere Quelle relativiert die ältere]
  https://cognition.com/blog/dont-build-multi-agents
  https://cognition.com/blog/multi-agents-working
  Unsere Auflösung: Parallel arbeiten nur mit disjunkten Dateibesitzern (VERTRAG, B5) und einer einzigen Merge-Instanz.

Prüfung und Review:
- Claude-Code-Doku: "Gib Claude eine Prüfung, die es selbst ausführen kann", sonst wird der Mensch zur Prüfschleife; Beweise (Testausgabe) statt Behauptung; Reviewer in frischem Kontext ("Writer/Reviewer"), weil der Autor am eigenen Code voreingenommen ist; ein Reviewer, der Lücken finden soll, meldet meist welche, selbst wenn die Arbeit gut ist, also nur Korrektheit und genannte Anforderungen melden lassen. Nach zwei erfolglosen Korrekturen: Kontext leeren und besser neu briefen. Lange CLAUDE.md-Dateien werden teilweise ignoriert. Kontextfenster ist die knappe Ressource. [Einzel, Hersteller-Doku]
  https://code.claude.com/docs/en/best-practices.md
- METR (Juli 2025): 16 erfahrene Open-Source-Entwickler, 246 Issues, mit KI 19 % länger; erwartet 24 % schneller, hinterher geglaubt 20 % schneller. Kleine Stichprobe, Frühjahr 2025, METR hält die Aussage für überholt (Update Februar 2026). Lehre: Selbstwahrnehmung von Tempo ist unzuverlässig, messen. [Einzel, mit Einschränkung]
  https://metr.org/blog/2025-07-10-early-2025-ai-experienced-os-dev-study/

Do:
- Task Card: Ziel, Dateien mit Eigentümer, Schnittstelle, Zahlen, Nicht-Ziele, Prüfkommando, Abgabeformat.
- Unabhängige Review mit frischem Kontext, Befunde als Beweis (Befehl und Ausgabe).
- Handback strukturiert: gebaut, Kennzahlen, Abweichungen, offene Punkte (VERTRAG).

Don't:
- Einen Agenten seine eigene Abnahme schreiben lassen.
- Tokens und Limits ignorieren: Kapazität in Agentenarbeit hat ein Ratenlimit (B6).

## A9. Dokumentation, die gelesen wird

- Nygard: "Große Dokumente werden nie aktuell gehalten; kleine, modulare haben eine Chance"; Entscheidungsdokumente ein bis zwei Seiten; Ersetzen statt Überschreiben. [Einzel, in der Praxis verbreitet]
  https://www.cognitect.com/blog/2011/11/15/documenting-architecture-decisions
- Claude-Code-Doku: Alles, was der Agent aus dem Code ableiten kann, nicht in die Dauer-Anweisung; nur Dinge, deren Fehlen Fehler verursacht; Skills für seltenes Domänenwissen laden bei Bedarf. [Einzel]
  https://code.claude.com/docs/en/best-practices.md
- Prinzip "eine Quelle der Wahrheit": Kopien von Daten in Docs und im Spiel driften. Im Projekt belegt (B7).

## A10. Messhygiene

- Goodhart: Ein Maß, das zum Ziel wird, taugt nicht mehr als Maß. Mehrere Metriken, qualitativ prüfen. [Konsens]
  https://www.kdnuggets.com/2020/10/goodharts-law-data-science-measure-target.html
- Flaky Tests: Google-Blogartikel (2016) ließ sich nur über Kommentare lesen; Zahlen fehlen. Lesbar war nur: Google zählt nicht, wie oft Flaky Tests echte Bugs maskieren, Wiederholung läuft nur für als flaky markierte Tests. [Einzel]
  https://testing.googleblog.com/2016/05/flaky-tests-at-google-and-how-we.html
- Godot-Doku zu get_rendering_info und Dummy-Renderer: Seite war nicht abrufbar; Aussagen dazu stammen aus unseren Messungen (B4), nicht aus der Doku.
- Regel: Jede Messung nennt Messart (gezählt, live, berechnet), Last (Rechner), Stichprobe n, Wiederholungen.

## A11. Quellenübersicht und Grenzen

Lesbar und genutzt: Scrum Guide, Kanban Guide, Cohn DoR, Construx Cone of Uncertainty, Wikipedia Planungsfehlschluss, HBR Premortem (ohne Zahl), Game Developer Postmortems, PMI Scope Creep, Retromat Follow-up, Mergify Branches, DORA-Zusammenfassung InfoQ, Anthropic (2), Cognition (2), METR, Claude-Code-Doku, Nygard ADR, KDnuggets Goodhart, Blogs kindatechnical und Wayline (als Meinung).
Nicht lesbar oder nicht nutzbar: Reddit (WebFetch gesperrt, Suche nur Spiegel-Titel, nicht umgangen); Pichler DoR, McConnell-Originalseite und Bezos-Primärbrief (Fetch gesperrt); SAFe WSJF-Details (Login); Google Flaky-Blog (kein Text); Godot-RenderingServer-Doku (Abruf fehlgeschlagen); Construx Meilenstein-Zuordnung (PDF nicht auslesbar); DORA-Vollbericht (nur InfoQ-Zusammenfassung); Retromat-Buch, Derby/Larsen (nur Suchtreffer). "Hersteller-Doku" (Anthropic, Cognition) ist Eigeninteresse, entsprechend vorsichtig lesen.

---

# TEIL B: Wissen für Mega Tycoon

Pfade relativ zu /home/claude/mega-tycoon (Ausnahme: VERTRAG.md liegt unter /tmp/claude-0/gd/designsprint/p4/).

## B1. Rhythmus und Regeln

- Scrum nach Clinton Keith, Refinement ersetzt Planning, Spikes mit Leitfrage und Timebox, Kunst läuft Kanban, ein Branch pro Ticket, Merge nach QA-Review (README.md).
- Asset-Karten (Art/Audio) laufen auf dem Kanban-Board (Briefing, Blockout, Modell, Textur/Material, Import, Abnahme) mit WIP-Limit 2 je Person und zählen nicht zum Sprint-Commitment (refinement/brief.md, refinement/ergebnis.md, refinement/sophie.md).
- Sprint 10 Arbeitstage, Plan bei 80 % Kapazität (etwa 8 T je Person), Schnittlinie, Feature Freeze (S6 Tag 7, S7 Tag 8), "Stretch nur aus Puffer".
- Regel: Ohne Zahl im Akzeptanzkriterium kommt kein Ticket in den Sprint (sprints/s2/refinement/ergebnis.md).
- Rollen kommen gestaffelt, neue Rolle nur mit Begründung (sprints/s6/refinement/brief.md). TEAM-02 (TA/Level Designer) ab S8, begründet durch die Pipeline aus S7 (sprints/s7/review_retro.md).
- Planung: plan/rahmen.md (M0 02.11. bis 27.11.2026, M1 Vertical Slice 30.11.2026 bis 26.03.2027), plan/katrin.md (To-do-Liste), plan/<rolle>.md.

## B2. Kapazität und Fehlschätzungen (Referenzklasse)

- S2: Katrins Kapazitätsanalyse und kritische Pfade (sprints/s2/design/production/day1-3/sprintziel_check.md), Auslöser 20.11. und 24.11. Bilanz: 8 erledigt, 8 nicht erledigt, 1 abgebrochen (sprints/s2/day7-10/gate/review_s2.md). Felix' Puffer war durch F-06 und F-05 verbraucht, Reviews blieben liegen (retro_s2.md).
- S3: Felix als Engpass, Entscheidungen kamen spät (03.12.); T-11 verfehlt Ziel; D-06, J-06, K-08 blieben liegen (sprints/s3/day8-10/review/retro_s3.md).
- S6: Sprintziel erreicht; Stretch (A-08, Label-Kanten, Pin-Vergleich) nicht (sprints/s6/review_retro.md).
- S7: Sprintziel mit Auflagen; verschoben: F-22 Firmenkauf, SK-02, A-08, Terrain-LOD, Stadtbrücken u. a. (sprints/s7/review_retro.md).
- Es gibt keine geführte Velocity im Repo (nicht belegt). Eine Referenzklasse aus S5 bis S7 ist möglich, aber nicht erstellt.
- Kosten: "Acht parallel arbeitende Rollen erzeugten Doppelarbeit und Nacharbeit" -> in S3 weniger Rollen gleichzeitig, Übergabe vor Start; teure Modelle nur für Code (retro_s2.md).

## B3. Gate-Logik

- Belegstufen M gemessen, V Voraussetzung/synthetisch, R Rechnung, O offen; "synthetisch zählt nicht" (D7; sprints/s2/design/production/day1-3/k07_gate_geruest.md).
- Gate-Kriterien G1 bis G9 und H1: sprints/s2/design/po/day1-3/gate_kriterien.md.
- Go-Regel (D8): Go = kein Rot in G1 bis G6, Messwerte G1 bis G5 vorhanden, höchstens 2 Gelb in G1 bis G3; drei Gelb in G1 bis G3 = Vertagen, kein No-Go; No-Go bei G1 Rot, G3 Rot, G2 Rot ohne Alternativplan. Plan B ist Gelb-Deckel (sprints/s2/decisions_19-11.md).
- Ergebnis Gate M0: Vertagen auf 02.12. (sprints/s2/day7-10/gate/gate_m0.md).
- G2: Median pro Tick, 10k x 1x, Release-Export, p95 Pflicht, Warnschwelle 6 ms (D7).
- Perf-Gate S7/S8: Übersicht höchstens 1,0 M Dreiecke und 300 Draw Calls, Stadt nah höchstens 2,9 M, Ladezeit höchstens 3 s (S7-Sandkasten höchstens 6 s), +10 % = rot. Nur Zählwerte, "keine FPS" (S7-Review).
- Prototyp-Abnahme: Maße +/-25 % (Fahrzeuge höchstens 1,2x real), VERTRAG.md Messregeln.

## B4. Messhygiene: was schiefging

1. 1,6 M Dreiecke (S8 Welle 2): gezählter Wert ohne Culling. 70 Baum-MultiMeshes mit 1,49 M Dreiecken werden jenseits visibility_range_end 1,8 km nicht gezeichnet; live höchstens etwa 0,62 M und 136 DC; 92 % der gezählten Dreiecke sind Bäume (phase4/felix_perf_aufschluesselung.md, ta_welle2.md).
2. Prototyp-Übersicht: live 145.702 Dreiecke / 111 DC gegen 565.902 gezählt (phase4/integration_w2.md, Tabelle, I12 "headless vs live perf"). Regel: Live-Messung per RenderingServer unter xvfb mit opengl3; der Headless-Dummy-Renderer hält keine MultiMesh-Transformationen. (Aussage stammt aus dem Repo, nicht aus der Godot-Doku.)
3. S7 Perf-Messfehler Faktor 2,5: durch Nachrechnen entdeckt, nicht durch Kürzen (sprints/s7/review_retro.md).
4. Tests auf Platzhalterkarte wurden rot, als die echte Karte kam (s7_city, s7_industrie, play.sh) (S7-Retro).
5. S6 B-1: Vorschau rechnete einen Faktor, den das Spiel nicht kennt; Kenney-Loader las von Platte (B-2), erste Zielrechner-Messung ohne Look (S6-Retro). Maßnahme: Jede sichtbare Zahl bekommt einen Test gegen den Spielwert (Vorbild d08_lizenzfaktor).
6. Repo-Drift: Skript-Spieler B ergibt M7 36,0 min heute gegen 30,4 min bei T-15, Ursache nicht untersucht (phase4/tobias_welle1.md).
7. Lastabhängigkeit: Ladezeit ProtoTerrain 0,48 bis 0,84 s, Spitze 1,7 s bei parallel ausgelasteter Maschine (phase4/ta_welle1.md, offener Punkt O8); Bot-Läufe n = 150 statt 300 wegen Maschinenlast (tobias_welle1.md).
8. Daniels Harness-Fehler zu B8 fiel auf (retro_s2.md); Daniels Vorabläufe zählen nicht, nur Abnahmeläufe.
9. Regression d07 (21 Suiten, 1.361 bis 1.565 s) nach Welle 2 nicht erneut gelaufen (integration_w2.md; ta_welle2.md P7).

## B5. KI-Agenten-Betrieb im Design Sprint

Vertrag: /tmp/claude-0/gd/designsprint/p4/VERTRAG.md (Stand 03.11.2026 06:50, Nachträge 07:05 und Welle 2 08:30).
- Variante schlank, kein Fable, nichts committen, nichts ins Repo schreiben: jede Rolle arbeitet nur in der Arbeitskopie /tmp/claude-0/gd/designsprint/p4/<rolle>/ (Welle 2: p4/w2/<rolle>/). Die Hauptsitzung merged dreiseitig.
- Dateieigentümer: nur der Eigentümer schreibt (Tabelle je Datei, z. B. TA: Heightmap/Fluss/Boden/Bach/See; Stadt: Orte/Instanzen/Wege).
- Bestehendes (Slice, S7-Welt, Sim, Tests) bleibt unberührt; Prototyp hinter eigener Szene; Änderungen an Bestehendem im Handback nennen und minimal halten.
- Eigene Doku je Rolle: phase4/<rolle>_welle1.md (gebaut, Kennzahlen, Abweichungen, offene Punkte).
- Godot-API gegen die installierte Engine prüfen (Skill godot-umsetzung); Bilder über xvfb und opengl3; .uid-Dateien gehören ins Repo.
- Messregeln: Maße gegen 12_regelwerk_v1_1.json (+/-25 %, Fahrzeuge 0,9 bis 1,2x real); Perf-Gate.
Fundstellen für Konflikte und Doppelbelegung:
- Doppelte INSTANCE_CUSTOM-Nutzung entfernt, ein Shader (I6) (integration_w2.md).
- "Felix' Hook gewinnt beim Merge" bei Hooks in fremden Dateien (ta_welle2.md).
- Vertragsänderung bei Test M8 "Weiler: nie ein Schild" bewusst (fixpass_w2.md).
- Zwei Kopien des Regelwerks existieren: sprints/s8/design-sprint/phase3b/12_regelwerk_v1_1.json und slice/world/data/proto/regelwerk.json (heute byte-identisch laut cmp am 03.11.2026; Drift-Risiko bleibt, solange es zwei Kopien gibt).
- Review-Befunde M1 bis M10 aus visueller Inspektion (Räder neben Pfad, Schildpositionen, Ackernähte u. a.) (integration_w2.md).

## B6. Token- und Limit-Realität

- Zwei Agenten liefen in S7 ins 5-Stunden-Limit; Fable-Läufe verbrauchen es sehr schnell. Regel: kein Fable ohne Basti-Freigabe; Opus/Sonnet für Standardarbeit; Sprint-Takt an das Limit anpassen (sprints/s7/review_retro.md).
- Charter-Risiko Token-Limit (sprints/s8/design-sprint/charter.md).

## B7. Dokumente und Quellen der Wahrheit

- Etwa 15.300 Zeilen Markdown im Repo (eigene Zählung). Unsicherheitswörter: "offen" etwa 398, "Annahme" etwa 302, "Platzhalter" etwa 116, "ABW" etwa 116, "Abweichung" etwa 88, "Proxy" etwa 57, "Auflage" etwa 54.
- Zahlen gehören in JSON-Daten (z. B. economy_constants.json mit `annahme`-Markierung, D17), Prosa verweist darauf.
- referenzen.md: viele Zahlen mit [~] (unbelegt) markiert (sprints/s8/design-sprint/referenzen.md). Nie als Messwert zitieren.

## B8. Retro-Maßnahmen und ihre Wirkung (Evidenz)

- S2 -> S3: (1) Dateien erst lesen, wenn vorhanden; (2) Pairing als Datei; (3) Zielrechner und Tester früh (retro_s2.md). Wirkung laut retro_s3.md: Übergaben "überwiegend" umgesetzt, Pairing "nicht belegt", Zielrechner "teilweise" (Export-Templates fehlten trotzdem spät).
- S3 -> S4: Blocker-Check an Tag 1; Übergabe-Gegenzeichnung; Pairing konkret mit zwei Felix-Daniel-Slots pro Woche (retro_s3.md). Wirkung: im Repo nicht belegt.
- S6: Test gegen Spielwert je sichtbarer Zahl; Export-Check (--export-pack) in die Regression; Screenshots früher an Daniel (s6/review_retro.md).
- S7: Tests auf echter Karte; Spiel und Validator rechnen dieselbe Regel; kein Fable ohne Basti (s7/review_retro.md).
- Muster: Maßnahmen kehren wieder (Pairing, Zielrechner), ohne dass ihre Wirkung später geprüft wurde. Das ist die Lücke, die Retromats Follow-up-Phase schließt.

## B9. Aufgabenkarten, Abnahmen, Playtests

- Abnahmen: Daniels Berichte (z. B. sprints/s7/abnahme/daniel_d09.md): H1 bis H3, H4, M1; 11 Regressionslücken; Standard bleibt opt-in.
- Spielen auf echter Karte findet, was Suiten nicht finden (S7-Retro; s6/zocken/tagebuch_daniel.md Z-01 bis Z-07, T-01 bis T-08 Werkzeugfehler).
- Aufgabenkarten für Basti: s6/l13_aufgabenkarten.md; s8/design-sprint/phase4/aufgabenkarten_v1_1.md (A1 bis A11, mit ehrlicher Lückenliste).
- Basti testet selbst (D16): Es gibt keine externen Tester; Zeiten und Beobachtungen als Datei sammeln.

## B10. Kommunikation mit Basti (Produktion)

- Knapp und praktisch, Deutsch. Bei Zeitdruck: Stand, Risiko, Entscheidung nötig? (ja/nein), Frist.
- Terminbuchung für Tests früh (retro_s2.md: "Tester und Zielrechner zu spät organisiert").
- Nachtbetrieb ohne Basti: Entscheidungen trifft Jonas, nichts Irreversibles (sprints/s7/refinement/brief.md). Arbeitsweise über Nacht: Blöcke mit Merge, Regression, Push nach jedem Block; neue Welt hinter Schalter oder mit grüner Regression.

---

# TEIL C: Eigene Lücken und Lernstand

Konfidenz: hoch = Repo oder mehrere Quellen; mittel = eine gute Quelle plus Folgerung; niedrig = Meinung, Analogie oder Herstellerinteresse.

## C1. Was wir jetzt wissen

| Aussage | Konfidenz |
|---|---|
| Kriterien, Messart und Schwellen vor der Messung festlegen verhindert stilles Schönrechnen (Gate M0) | hoch (Repo) |
| Gezählte Dreiecke ohne Culling sind kein Liveergebnis; Gate muss den erlebten Wert messen | hoch (Repo, felix_perf_aufschluesselung) |
| Maßnahmen aus Retros brauchen Owner, Datum und Wirkungsprüfung (Retromat), sonst kehren sie wieder | mittel (Retromat + Repo-Muster) |
| Kapazität bei 80 % plus Spikes statt Schätzung von Unbekanntem | mittel (Cone, Planungsfehlschluss) |
| Parallel arbeitende KI-Agenten brauchen disjunkte Dateieigentümer und eine Merge-Instanz | mittel (Cognition 2026 + VERTRAG-Erfahrung) |
| Frischer Reviewer-Kontext verbessert Review, meldet aber auch bei guter Arbeit Lücken | mittel (Claude-Doku, Cognition) |
| Kleine Branches, kurze Lebensdauer reduzieren Integrationskosten (24 h als Richtwert unverifiziert) | niedrig bis mittel |
| Cohn: Ready-Pflicht wirkt wie Stage-Gate; für Agenten-Aufgabenkarten brauchen wir trotzdem Vollständigkeit | niedrig (Einordnung) |

## C2. Was unsicher bleibt

- DoR ja oder nein: [Streit]. Wir verwenden eine leichte Richtlinie, kein hartes Gate. Test: Wie viele Rückläufer je Karte mit und ohne Richtlinie? (Daten nicht erhoben.)
- Ob Schätzen in Personentagen für KI-Agenten sinnvoll ist: keine Quelle gelesen, die es belegt. Wir messen stattdessen Durchlaufzeit je Karte (Datum Start/Ende) und Token-/Limitverbrauch.
- Ob Multi-Agent-Betrieb bei uns netto Zeit spart: Anthropic nennt 15x Tokens; Cognition rät ab; unser Merge-Aufwand wurde nicht gemessen. Konfidenz niedrig.
- Wirkung des Pairings: im Repo "nicht belegt". Offen, ob Pairing überhaupt Sinn hat, wenn Rollen KI-Agenten sind.
- Flaky-Test-Rate der 21 Suiten: nicht erhoben. Lastabhängige Zeiten wurden beobachtet, nicht ausgewertet.
- Ob die 24-h-Branch-Regel bei uns (Branch pro Ticket mit Review) einhaltbar ist: unklar.
- DORA-Kernaussage (Verstärker) stammt aus einer Zusammenfassung, nicht aus dem Bericht.
- Reddit-Praxiswissen (r/agile, r/projectmanagement, r/gamedev, r/IndieDev) fehlt, weil nicht lesbar.

## C3. Lernfragen Katrin (priorisiert) und Stand

1. Schätzen und Grenzen: Stand: 80 %-Kapazität, S2 8 von 17; keine Referenzklasse. Maßnahme: Referenzklasse aus S5 bis S7 bauen.
2. DoR/DoD und Gates: Stand: Gate-Regeln gut, DoD je Ticket uneinheitlich. Maßnahme: leichte Ready-Richtlinie für Agentenkarten, DoD-Liste im Repo.
3. Messhygiene: Stand: Fehlalarm erklärt (1,6 M), Drift M7 ungeklärt. Maßnahme: Messprotokoll (Art, Last, n, Wiederholung) in jedem Gate.
4. KI-Agenten: Stand: VERTRAG funktioniert, Hooks in fremden Dateien bleiben Risiko. Maßnahme: Hook-Stellen als Schnittstelle im Vertrag, unabhängige Review mit frischem Kontext.
5. Übergaben und Retro-Wirksamkeit: Stand: Maßnahmen wiederholen sich. Maßnahme: Follow-up-Phase mit Revisit-Datum.
6. Risikosteuerung: Stand: Auslöser mit Datum (S2), Blocker spät (Export-Templates). Maßnahme: Premortem zu Sprintstart, Blocker-Check Tag 1.
7. Scrum/Kanban und WIP: Stand: Kunst-Kanban mit WIP 2 je Person vorhanden; Alter der Items und Cycle Time werden nicht erfasst. Maßnahme: Start-/Enddatum und Alter je Karte, Limit auch für Technik-Spikes prüfen.
8. Änderungssteuerung und Freeze: Stand: Freeze-Termine vorhanden, D24 als belegte Ausnahme. Maßnahme: Ausnahme nur mit Eintrag und Md5/Beleg.
9. Dokumentation: Stand: etwa 15.300 Zeilen, Kopien von Daten. Maßnahme: eine Quelle je Zahl, Kopien markieren oder löschen.
10. Regression/CI: Stand: 21 Suiten, 1.361 bis 1.565 s, lastabhängig. Maßnahme: Pflichtlauf vor Abnahme, Dauer protokollieren, Flaky-Liste.
11. Onboarding neuer Rollen und Engpässe: Stand: Felix, Mira, Sophie als Engpässe (S3, S7). Maßnahme: TA entlastet Sophie; Engpass-Check im Refinement.
12. Flow-Metriken: Stand: keine. Maßnahme: Start-/Enddatum je Karte, Cycle Time und Alter als erste Zahlen.

## C4. Was wir ab sofort anders machen (Katrin)

- Retro-Maßnahme = Owner + Datum + Wirkungsprüfung; Revisit-Phase am Retro-Anfang.
- Jedes Gate nennt Messart, Last, n und Wiederholungen; gezählte und Live-Werte getrennt.
- Aufgabenkarten für Agenten: Ziel, Dateieigentümer, Zahlen, Nicht-Ziele, Prüfkommando, Handback-Format.
- Review durch frischen Kontext, Befunde mit Beweis; Reviewer meldet nur Korrektheit und Anforderungen.
- Blocker-Check an Tag 1 (Export, Tools, Zielrechner, Limit).
- Erst die echte Karte oder echte Daten, dann Tests schreiben.

## D. Lern-Routine (verbindlich, seit 2026-11-03)
**1. Wissenscheck** vor jeder fachlichen Antwort/Entscheidung: Steht sie hier mit Marke [K]/[V]/[R]? Ja: anwenden. Nein, oder nur [E]/[W]/niedrige Konfidenz: weiter mit 2.
**2. Recherche-Trigger** (einer genügt; laut sagen: "Wissenslücke: <Frage>, ich recherchiere"): a) Ich weiß es nicht oder rate. b) Derselbe Kompromiss/Workaround zum 2. Mal ("wieder X statt Y"). c) Eintrag unter Offene Lücken oder [E]/[W]/niedrig, und die Entscheidung hängt daran. d) Skill, Repo, Doku oder Messung widersprechen sich. e) Engine/Tool/Version neuer als der Skill-Stand. f) Basti korrigiert oder eine Entscheidung wird zurückgenommen. g) Teure oder unumkehrbare Entscheidung bei Konfidenz unter mittel. h) Derselbe Fix scheitert 2x.
Rollen-Trigger: Schätzung reißt 2x um mehr als 30 %; unbekannte Abhängigkeit; Prozess (Scrum/Design Sprint) nur angenommen.
Erst prüfen statt recherchieren, wenn billig messbar (Test, Doku-grep, Mini-Versuch). Geschmack klärt Prototyp oder Basti, nicht das Web.
**3. Ablauf**: Frage in einem Satz; Primärquellen zuerst (Doku, Issues, Forum, Postmortems; Reddit blockiert, nicht umgehen); 2 unabhängige Quellen; wenn möglich Eigenversuch [V]; Ergebnis mit Quelle, Datum, Marke. Budget 15 min, mehr nur als Agent. Unbeantwortet: Lücke eintragen, Basti/Team fragen, nie raten.
**4. Insight aufnehmen**, wenn alle vier stimmen: wiederverwendbar (2x gebraucht oder über 1 h Aufwand), belegt, noch nicht drin, kein Tagesstand (der gehört in Repo-Doku). Sofort bei Basti-Korrektur, Fehler im Skill oder Engine-Falle mit Repro, sonst gesammelt zum Sprintende. Eine Zeile mit Marke, Datum, Quelle; Widerspruch ersetzt den alten Eintrag; geschlossene Lücke streichen; Skill bleibt ca. 10.000 Zeichen. Im Account nur per Vorschlagskarte an Basti.
**5. Kompromisslog**: jeden Kompromiss, Workaround, jedes "wusste ich nicht" mit Datum in `sprints/s8/fortbildung/mt-produktion/LERNLOG.md` zählen; Zähler 2 löst Trigger b aus; Auswertung in der Sprint-Retro.
