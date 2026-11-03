---
name: mt-po
description: Nutze dieses Skill, wenn Jonas (Product Owner) bei Mega Tycoon Backlog ordnet, Scope schneidet, Entscheidungen protokolliert, Gates und Prototyp-Abnahmen definiert oder Bastis Feedback in Tickets und Fragen übersetzt.
---

# mt-po: Product Owner Jonas, Fachwissen und Projektwissen

Stand: 03.11.2026. Alle Zahlen mit URL sind im Teil A belegt. Projektwissen (Teil B) nennt Repo-Quellen relativ zu /home/claude/mega-tycoon. Kennzeichnung der Aussagen: [Konsens] viele unabhängige Quellen, [Streit] Quellen widersprechen sich, [Einzel] eine Quelle oder Blogmeinung. Nicht lesbare Quellen stehen am Ende von Teil A.

Lies zuerst Teil C (Lücken), bevor du eine Entscheidung auf diesem Skill aufbaust.

---

# TEIL A: Allgemeines Fachwissen

## A1. Vision und Pillars

Was gilt:
- Pillars beschreiben Spielerlebnis und Gefühl, nicht Features. [Konsens: Raspberry Pi/Wireframe, Game Developer Tarczykowski]
- Etwa drei Kernaussagen, je höchstens ein Satz, als Regel formuliert, positiv, mit Begründung ("warum"). Mehrere Ideen in eine lange Aussage zu pressen ist laut Quelle "cheating". [Einzel, aber mit dem Konsens zu 2 bis 5 Pillars vereinbar]
  https://www.raspberrypi.com/news/how-pillars-and-triangles-can-focus-your-game-design/
- Vorschlag bewerten als "great / neutral / bad" gegen die Pillars; abgelehnte Ideen nicht "schlecht" nennen, sondern für ein anderes Spiel notieren. Pillars dienen zum Schneiden, nicht zum Ideenfinden (dafür Jams, Recherche, Prototypen). [Einzel] (gleiche Quelle)
- Pillars kommen vor dem Prototyp, ein volles GDD ist vorher nicht nötig; das GDD darf nicht zum Flaschenhals werden. [Einzel]
  https://gamedeveloper.com/business/agile-game-development-part-2-design-pillars
- Vier schlanke Dokumente reichen oft: Vision, Pillars, Loops, Ressourcenfluss (GDC 2025, Ian Schreiber, nur Zusammenfassung gelesen). [Einzel]
  https://gdcvault.com/play/1035510/The-Four-One-Page-Design

Typische Fehler:
- Pillar als Feature ("2D-Plattformer") oder als Allgemeinplatz ("Spaß").
- Pillars, gegen die nie ein Feature abgelehnt wurde. Dann sind es Poster, keine Pillars.
- Pillars ohne Gegenposition und ohne Test. Test: Welche zwei Features würden wir deshalb streichen?

Prüfliste "Pillar-Qualität":
1. Ein Satz, aktiv, Spielergefühl.
2. Es gibt eine Ja/Nein-Frage, die ein Playtest oder Messwert beantwortet.
3. Es gibt mindestens ein Beispiel, das wir wegen dieses Pillars gestrichen haben.
4. Es gibt eine ehrliche Aussage, welche Pillars noch nicht testbar sind.

## A2. Backlog und Priorisierung

- Scrum Guide: Der PO ist verantwortlich für Product Goal, klare Backlog-Einträge, Reihenfolge und Transparenz; Delegation ist erlaubt, Verantwortung bleibt. Nur der PO darf einen Sprint abbrechen. [Konsens]
  https://scrumguides.org/scrum-guide.html
- RICE = Reach, Impact, Confidence, Effort. Impact-Skala 3 / 2 / 1 / 0,5 / 0,25; Confidence 100 % / 80 % / 50 %, unter 50 % gilt als "Moonshot". Eigene Quellenkritik: Impact ist schwer zu messen, Reach braucht Nutzerzahlen. Bei einem Spiel ohne Nutzer vor Release fehlt die Reach-Basis; RICE liefert dann Scheingenauigkeit. [Einzel zur Skala, Streit zur Eignung für Spiele]
  https://www.productplan.com/glossary/rice-scoring-model
- WSJF = relative Cost of Delay geteilt durch relative Dauer; Komponenten Wert, Zeitkritikalität, Risikoreduktion/Enabler, Größe. Die Quelle sagt, Reihenfolge schlägt Einzelrang nach theoretischem ROI und Prioritäten müssen laufend neu gesetzt werden. Skala und Details lagen hinter Login (nicht gelesen). [Einzel]
  https://framework.scaledagile.com/wsjf
- Fazit [Streit]: Score-Modelle helfen beim Gespräch, ersetzen aber keine Abhängigkeiten. Für ein Team von 9 bis 12 simulierten Rollen ohne Nutzerzahlen ist eine leichte Variante sinnvoll: Wert (Pillar-Bezug), Risiko (was lernen wir), Größe in Tagen, Abhängigkeit. Zahlen sind Gesprächsstoff, keine Wahrheit.
- MoSCoW (Must/Should/Could/Won't) als "Kill List"; Won't wirklich aus der Roadmap nehmen; Should nicht heimlich zu Must hochstufen. [Einzel: Blog, aber verbreitet]
  https://www.wayline.io/blog/best-workflow-cutting-game-features (gesponserter Blog, Meinung)
- Faustregeln des Blogs ("One Month"-Regel, Schätzung mal 2) sind unbelegt. Nur als Denkanstoß verwenden. [Einzel]

Do:
- Reihenfolge schlägt Score: erst Abhängigkeiten und Risiko, dann Wert.
- Jedes Ticket hat eine Zahl im Akzeptanzkriterium (Projektregel S2).
- Backlog-Einträge nennen das Problem, nicht nur die Lösung.

Don't:
- Score ohne Konfidenz. Eine Zahl mit 50 % Konfidenz darf nicht wie eine mit 100 % behandelt werden.
- Ein Backlog, das sich nur vergrößert: "verschoben nach S8" ist keine Entscheidung, solange nichts gestrichen wird.

## A3. Scope-Kontrolle

- PMI Pulse of the Profession 2018: 52 % der in 12 Monaten abgeschlossenen Projekte erlebten Scope Creep (vor 5 Jahren 43 %). [Einzel, aber Industrie-Erhebung]
  https://www.pmi.org/learning/library/scope-creep-rising-11308
  Gegenmittel dort: Grenzen früh setzen, "out of scope" mit Auftraggeber definieren, Backlog je Sprint pflegen, Änderungen zeitlich bewerten, bevor getauscht wird, Änderungsverfahren vertraglich, Lessons Learned nach Scope Creep.
- Postmortems (Game Developer "What went wrong"): Scope und Umfang früh kürzen (Stranglehold: ein Jahr früher kürzen hätte Missionsvielfalt und Politur gebracht); Inhalte zu spät geliefert verschlechtern alles Abhängige (Titan Quest: 25 Designdokumente zu spät; BioShock: Erzähldetails in letzter Minute). [Konsens über viele Postmortems, hier eine Sammlung]
  https://www.gamedeveloper.com/business/what-went-wrong-learning-from-past-postmortems
- Iron Triangle (Qualität, Zeit, Geld): nur zwei der drei sind steuerbar; wer alle drei zu steuern behauptet, ist eine "rote Warnung". [Konsens]
  https://www.raspberrypi.com/news/how-pillars-and-triangles-can-focus-your-game-design/

Checkliste "neuer Wunsch":
1. Welcher Pillar? Welche Spielerfahrung ändert sich messbar?
2. Was fliegt dafür raus (Tausch statt Zufügen)?
3. Kostet es Basis (Tools, Sim, Daten) oder nur Oberfläche? Basis zuerst.
4. Ist es umkehrbar? Wenn nein, geht es an den Auftraggeber (A4).
5. Wo steht es danach: im Sprint, in der Schnittlinie, im "nie im Prototyp"-Block?

## A4. Entscheidungen und Entscheidungslogs

- ADR (Nygard 2011): kurze Substantivtitel, Kontext (Kräfte, als Fakten), Entscheidung (volle Sätze, aktiv), Status (vorgeschlagen/angenommen, später ersetzt), Konsequenzen (alle, nicht nur positive). Ein bis zwei Seiten. Nummern werden nicht wiederverwendet; revidierte Entscheidungen bleiben als "ersetzt" stehen, statt umgeschrieben zu werden. [Konsens in der Praxis, Einzelquelle hier]
  https://www.cognitect.com/blog/2011/11/15/documenting-architecture-decisions
- Typ 1 / Typ 2 (Bezos, 2016): schwer umkehrbare Entscheidungen ("Einbahntür") langsam und sorgfältig, umkehrbare ("Zweiweg-Tür") schnell und klein entscheiden. 70-%-Regel: mit ungefähr 70 % der gewünschten Information entscheiden. "Disagree and commit"; fundamentale Zielkonflikte früh eskalieren, sonst entscheidet Ausdauer. Gelesen nur über Sekundärquelle (Pollock), Primärbrief nicht abrufbar. [Einzel/Meinung, im Management weit verbreitet]
  https://rufuspollock.com/post/jeff-bezos-fast-high-quality-decision-making
- Gute Entscheidungsvorlage: Optionen, Empfehlung, Arbeitsannahme falls keine Antwort kommt, Frist, Kosten der Rücknahme.

Do:
- Pro Entscheidung eine Zeile "revidierbar bis wann / durch was".
- Änderung einer Entscheidung als neue Nummer mit Verweis, nicht still überschreiben.
- Annahme klar von Entscheidung trennen (Status: entschieden / Annahme / an Auftraggeber).

Don't:
- Tests oder Verträge stillschweigend ändern, damit grün wird. Wenn es sein muss, als bewusste Vertragsänderung mit Begründung (siehe B6, M8).

## A5. Wann ist ein Prototyp fertig

- Prototyp dient einer Frage. Houde und Hill (zitiert in einer MIT-Arbeit): drei Fragetypen: Rolle (Was bedeutet das im Leben des Nutzers), Look and Feel, Implementierung (Wie lässt es sich bauen). Der Integrations-Prototyp beantwortet alle drei zusammen. Vor dem Bau festlegen, welche Frage er beantwortet. [Konsens in HCI; hier Sekundärquelle]
  https://dspace.mit.edu/bitstream/handle/1721.1/68841/772609684-MIT.pdf?sequence=2
- Church, Formal Abstract Design Tools: Absicht des Spielers und wahrnehmbare Konsequenz als Prüffragen ("führen Handlungen zu Ergebnissen, die der Spieler versteht?"). Sekundärquelle. [Einzel]
  https://creatinggames.press.plymouth.edu/?p=97
- Meilenstein-Definitionen früh mit Auftraggeber vereinbaren (Manuel, Sony). Gefahr: monatelang polierter Vertical Slice, der Produktionszeit frisst und in "Demo Hell" führt. [Einzel, aber oft zitiert]
  https://gamedeveloper.com/production/do-you-have-a-firm-definition-of-your-milestones-
- Beispielkriterien (Blog, unbelegt): Alpha = Features komplett, Beta = Inhalt komplett; Pre-Production-Exit = "alle großen technischen Risiken gelöst". [Einzel]
  https://kindatechnical.com/game-development/project-management-for-game-studios.html

Prüfliste "Prototyp fertig":
1. Die Leitfrage ist benannt und beantwortet (ja/nein/teilweise mit Beleg).
2. Jede Abnahmezahl hat Messart (gemessen, gezählt, berechnet, Annahme).
3. Abweichungen sind einzeln benannt, mit Begründung und Ablaufdatum ("ABW bewusst" ohne Datum ist Dauerabweichung).
4. Was der Prototyp nicht beweist, steht ausdrücklich drin.
5. Regression des Bestandsspiels ist gelaufen (nicht "nicht erneut gelaufen").

## A6. Stakeholder mit Meinungen steuern

- Spieler und Auftraggeber erkennen Probleme gut, Lösungen schlecht (Darrah, ehem. BioWare). Beschwerde ist ein Symptom, kein Rezept; alle Spielergruppen gewichten, nicht nur die lauten. [Konsens in Playtest-Literatur; hier Einzelquelle Presse]
  https://mp1st.com/news/bioware-producer-players-good-identifying-problems-not-solutions
- Valve (GDC 2009): Beobachtetes Verhalten schlägt Aussage; "Leute wissen nicht, warum sie tun, was sie tun"; Spielentwürfe sind Hypothesen, Playtests Experimente. Die Folien nennen keine Stichprobengrößen. [Konsens]
  https://cdn.fastly.steamstatic.com/apps/valve/2009/GDC2009_ValvesApproachToPlaytesting.pdf
- Nielsen/Landauer: mit L = 31 % Problemen pro Nutzer findet 1 Nutzer 31 %, 3 Nutzer etwa 67 %, 5 Nutzer etwa 84 bis 85 %; für alle Probleme etwa 15 Nutzer; mehrere kleine Runden schlagen eine große; bei unterschiedlichen Gruppen 3 bis 4 pro Gruppe; ein einzelner Tester kann irreführen, mindestens 3 für Verhaltensvielfalt. L ist ein Mittelwert aus Projekten, keine Konstante. [Konsens für Usability, Streit bei Spielen]
  https://www.nngroup.com/articles/why-you-only-need-to-test-with-5-users/
  Folge für uns: Ein einziger Tester (Basti) findet im Mittel etwa ein Drittel der Probleme und ist zugleich Auftraggeber. Das ist eine Entscheidung (D16), kein Qualitätsnachweis.
- Goodhart: Wird ein Maß zum Ziel, taugt es nicht mehr als Maß. Gegenmittel: Prinzipien vorab, mehrere Metriken, qualitativ gegenprüfen, Konflikte als Anlass zum Revidieren. [Konsens]
  https://www.kdnuggets.com/2020/10/goodharts-law-data-science-measure-target.html

Do:
- Feedback in vier Klassen sortieren: Fehler, Design, Parameter, Look (bewährt im Projekt, B5).
- Hinter dem Wunsch das Problem suchen; Lösung als Option zurückgeben.
- Bei Auftraggeber-Entscheidungen: eine Frage, zwei bis drei Optionen, Empfehlung, Arbeitsannahme, Frist.

Don't:
- Bot-Zielband (z. B. Bankrottquote) zum einzigen Erfolgsmaß machen.
- Eine Aussage von Basti als Messung ausgeben.

## A7. Design Sprint für Games adaptieren

- Klassische Struktur (UXPin-Zusammenfassung des Sprint-Buchs): Tag 1 Map, 2 Sketch, 3 Decide, 4 Prototype, 5 Test; Team höchstens 7; ein "Decider" wählt per Supervote; Prototyp = ein Nutzerfluss; fünf Tester. [Einzel; die Quelle nennt keine Ausschlusskriterien]
  https://www.uxpin.com/studio/blog/design-sprints/
- Für Games passt es schlecht, wo Spielgefühl über Zeit entsteht (Sim, Wirtschaft): ein 5-Tage-Prototyp zeigt Lesbarkeit, nicht Langzeitbalance. [Einzel, eigene Folgerung, nicht belegt]
- Unsere Anpassung (Charter S8): 5 Phasen (Verstehen, Skizzieren, Entscheiden, Prototyp, Test), Streitprotokoll statt Supervote, Basti als Entscheider, Wellen statt Tagen. Siehe B4.

## A8. Quellen mit Datum und Einschränkung (Teil A, PO)

| Thema | Quelle | Anmerkung |
|---|---|---|
| Pillars | raspberrypi.com (Dransfield, 15.07.2021) | Wireframe-Feature, Meinung |
| Pillars | gamedeveloper.com (Tarczykowski, 16.09.2020) | kurz, anekdotisch, keine Methodik |
| 4 Ein-Seiten-Dokumente | gdcvault.com 1035510 | nur Abstract |
| Priorisierung | productplan.com RICE; framework.scaledagile.com WSJF | WSJF-Details hinter Login |
| Scope | pmi.org Scope Creep 52 % / 43 % | Zahl aus PMI Pulse 2018 zitiert |
| Scope | gamedeveloper.com What went wrong | Sammlung von Postmortems |
| Scope | wayline.io Kill-List | gesponserter Blog |
| Entscheidungen | cognitect.com ADR; rufuspollock.com (Bezos) | Bezos nur Sekundärquelle |
| Prototyp | dspace.mit.edu; plymouth.edu Church | beide sekundär |
| Meilensteine | gamedeveloper.com Manuel (2012) | alt, aber Kernaussage stabil |
| Feedback | mp1st.com Darrah; Valve GDC 2009 PDF; nngroup.com 5 Users | Darrah nur Presse |
| Metriken | kdnuggets.com Goodhart | |
| Design Sprint | uxpin.com | Sprint-Buch selbst nicht gelesen |
| Prozess | scrumguides.org; kindatechnical.com | letzterer unbelegt |

Nicht lesbar oder nicht nutzbar: Reddit (WebFetch "SITE_BLOCKED"; Suche lieferte nur Spiegel-Titel ohne Text, nicht umgangen); Bezos-Primärbrief (Fetch gesperrt); bugnet.io Vertical-Slice-Artikel (nur Index); Klein/HBR "30 % mehr Gründe" (auf der Seite nicht bestätigt, daher nicht zitiert); Roman Pichler DoR und McConnell-Originalseite (Fetch gesperrt).

---

# TEIL B: Wissen für Mega Tycoon

Pfade relativ zu /home/claude/mega-tycoon. Nur Belegtes. Wo etwas fehlt, steht "nicht im Repo".

## B1. Rolle und Arbeitsweise

- Jonas Weber ist PO. Team: Lena (Design), Tobias (Ökonomie), Aylin (UX), Felix (Tech), Sophie (Art), Daniel (QA), Katrin (Produktion/SM), Mira (UI-Programmierung). Neue Rollen ab S8: Art Director, TA (TEAM-02), Stadt-/Level-Designer. (README.md; sprints/s7/review_retro.md; sprints/s8/design-sprint/charter.md)
- Scrum nach Clinton Keith, Refinement ersetzt Planning, Spikes mit Leitfrage und Timebox, Kunst läuft Kanban, ein Branch pro Ticket, Merge nach QA-Review. (README.md)
- Sprint = 10 Arbeitstage, Planung mit 80 % Kapazität (etwa 8 T je Person). Schnittlinie ("Cut Line") und Feature Freeze (S6 Tag 7, S7 Tag 8); "Stretch nur aus Puffer". (sprints/s2/refinement/ergebnis.md; sprints/s6/refinement/ergebnis.md; sprints/s7/refinement/ergebnis.md)
- Regel S2: "Ohne Zahl im Akzeptanzkriterium kommt kein Ticket in den Sprint." (sprints/s2/refinement/ergebnis.md)
- Streitprotokoll: Positionen, Kosten, PO-Entscheid, Begründung (K1 bis K37 über mehrere Sprints). (sprints/s8/design-sprint/phase3/11_streitprotokoll.md; phase3b/15_regelwerk_v1_1.md)

## B2. Vision, Pillars, Leitplanken

- Vision, 5 Designpfeiler mit "Im Zweifel ...": concept/jonas.md. Leitplanken: concept/leitplanken.md (D12 änderte sie: Start mit HQ und Lizenzen, Firmenkauf ab M5b; sprints/s2/decisions_19-11.md).
- Pfeiler als Ja/Nein-Fragen gegen das Gate: sprints/s2/design/po/day1-3/pillar_fragen.md. Ehrliche Lücke dort: Pfeiler 3 und 4 in S2 nicht testbar. Gate-getestet waren nur 1 und 5 (aus Selbstanalyse, belegt in pillar_fragen.md und gate_kriterien.md).
- Designprinzipien des Design Sprints P1 bis P7, je mit Test und Gegenposition: sprints/s8/design-sprint/phase2/02_designprinzipien.md.

## B3. Entscheidungslog (Auszug, belegt)

S2 (sprints/s2/decisions_19-11.md, Spalte "Revidierbar"):
- D1 Startkapital Option A (4.500/4.500/7.000/5.000 $) als Testannahme, Kreditrahmen ab Minute 0, revidierbar nach L-05.
- D2 Messgröße L-06 wörtlich, G1 = "Kette in 3 bekannten Fällen lesbar", kein "USP belegt".
- D3 G3 neu: nur Darstellbares prüfen; ausdrücklich Nicht-Geprüftes benannt (Weiche ohne Signal, Kurven, Pfadsignale).
- D4 Wachstum Variante B 1,8 %/Monat, "Ungetestet, Grey-Box Januar".
- D5 Kartenziel Vertical Slice 512², 1.024² erst M2, Rückfallregel an 5.000 Fahrzeuge.
- D6 F-07 gestrichen, G8 "nicht nachgewiesen", Auflage Bau-Spike.
- D7 Messwert-Regel (Belegstufen M/V/R/O, "synthetisch zählt nicht"); Plan B = Gelb-Deckel, nicht Rot.
- D8 Go-Regel: Go = kein Rot in G1 bis G6, Messwerte G1 bis G5 vorhanden, höchstens 2 Gelb in G1 bis G3; drei Gelb in G1 bis G3 = Vertagen (02.12.), kein No-Go.
- D9 bis D14: Ursache-Codes (ein Namensraum), Ghost weiß = baubar, einheitlicher Testtitel, Leitplanke geändert, Meilensteine M3/M7 umdefiniert, Akzeptanz "Figma" durch "Textspezifikation" ersetzt.
Gate M0: Ergebnis "Vertagen auf 02.12." (sprints/s2/day7-10/gate/gate_m0.md, review_s2.md: 8 erledigt / 8 nicht erledigt / 1 abgebrochen).

Auftraggeber-Regeln (Basti):
- D15: Genre-Standards übernehmen (TF2, OpenTTD, Railway Empire, Cities Skylines, Anno), Arbeit in die eigenen Unterschiede. Wirkung: A-07 von 2 T auf 0,5 T, Bau-Tool/Kontextdialog nicht neu spezifiziert (sprints/s3/refinement/brief.md; lena_tobias.md).
- D16: Basti testet selbst, keine externen Tester. Folge: Akzeptanzkriterien wie "5 von 6 kaufen in höchstens 3 min" nicht erhebbar; Ersatz: Basti notiert Zeiten (sprints/s3/day4-7/aylin/a09_lizenz_kauf_flow.md).
- D17 bis D20 (sprints/s3/decisions_04-12.md): Ketten K1 bis K3 bestätigt; Hafen und Handel aus dem Slice; Ausbaukosten Stufe 2 = 2.000 $; Bergbau-Untergrenze 6.000 $ mit Kredit 2.000 $.
- D21: UI mit Liebe (Theme, angedockte Panels, Übergänge höchstens 150 ms, Klick-Sounds, keine grauen Modale). (sprints/s5/brief_day1-5.md)
- D22: Start wie Civ, HQ frei platzieren, keine Archetyp-Auswahl, Spezialisierung über erste Lizenzen und Skilltree. (sprints/s5/vorgemerkt.md; s6/refinement/brief.md)
- D23: Das Band "Agrar-Kasse nach 30 min x1,5 bis 2,0" aus der Archetypzeit wird durch T-14 ersetzt (Bankrott 10 bis 30 %, M7 35 bis 50 min). (sprints/s6/block-a/entscheidungen_jonas.md)
- D24: Freeze-Ausnahme: Werkzeugfabrik verschoben, Kohlberg-M7 im Modell 36 bis 38 min. (sprints/s6/block-a/entscheidungen_jonas.md; s6/block-b/karte.md)
- S6-Antworten Bastis (01.11.): Firmenkauf in R2 ja, Bench-Exe, Bankrottband 10 bis 30 % (sprints/s6/refinement/ergebnis.md).

## B4. Design Sprint "Welt" (S8)

Quelle: sprints/s8/design-sprint/charter.md (5 Phasen: Verstehen, Skizzieren, Entscheiden, Prototyp, Test).
Bastis Entscheidungen E1 bis E15 (Achtung Namenskollision: in S2 hießen Katrins Entscheidungsvorlagen ebenfalls E1 bis E7; bei Verweisen immer Sprint nennen):
- E1 nichts übertrieben, alles in Proportion; Fahrzeuge höchstens 1,2x.
- E2 einfacher Wasser-Shader.
- E3 Siedlungszahl folgt aus Prinzipien.
- E4 Start 1820, später wählbar.
- E5 Schwierigkeitsstufen.
- E6 Frage F1 Option B: gestaffelte Siedlungsordnung (2 Kleinstädte, Marktflecken, viele Dörfer).
- E7 F2 Option C: Siedlungen ohne Versorgung stabil, wachsen nur mit Versorgung.
- E8 Spiel läuft bis heute (Moderne).
- E9 F4 Option A plus Fahrzeug-Easing je Kategorie.
- E10 F5 Option C: Gewässer mit sichtbarer Nutzung.
- E11 F6 Option B plus Parameter "Konkurrenz".
- E12 Kalendertempo wählbar.
- E13 Kartengröße bleibt.
- E14 Konkurrenz Standard an, sichtbar, abschaltbar.
- E15 Flöße als frühes Wasserfahrzeug.
Risiken im Charter: Epoche und Assets laufen auseinander; Regelwerk bleibt Papier (Prototyp ist Pflicht); Token-Limit (Agenten auf Opus/Sonnet, kein Fable).
Fragen an Basti F1 bis F6 mit Optionen, Empfehlung, Arbeitsannahme: sprints/s8/design-sprint/phase3/13_fragen_an_basti.md. Offen: F7 bis F10 (phase3b/15_regelwerk_v1_1.md).
Prototypplan: 16_prototyp_plan_v1_1.md (schlanke Variante 13,5 PT, Wellen 0 bis 4, Liste "nie im Prototyp", Abnahmekriterien 1 bis 6).
Prototyp-DoD: Prototypszene mit +/-25 % Maßtoleranz gemessen, Fahrzeuge höchstens 1,2x (charter.md).

Beobachtung zur Eigenkritik: E8 (Moderne), E10 (Wasser), E15 (Floß), E11/E14 (Konkurrenz) erweitern den Umfang, die Kapazität wurde nicht angepasst. Belegt ist die Erweiterung (charter.md), die Kapazitätswirkung ist nicht im Repo bewertet.

## B5. Bastis Feedback richtig behandeln

- Zwei Feedbackrunden: sprints/s7/basti_feedback_01-11.md (9 Punkte nach S6: Proportionen, Straßen, Railway-Empire-Referenz, Ring-Bug, Miniatur-Wirkung, Industrieverteilung, echter Maßstab, Kartenrand wie TF2, Gelände) und sprints/s8/feedback_02-11/basti_feedback_02-11.md (10 Punkte, Klassifikation Fehler/Design/Parameter/Look).
- Grundursache aus der zweiten Runde: Modelle im alten Maßstab 10 m/Feld, Welt aber 25 m/Feld; Generator erzeugt Raster. Lehre: Ein Maßstab ist eine Entscheidung mit Wirkung auf Modelle, Welt, Sim und Tests, kein Parameter.
- Kommunikation: knapp, praktisch, deutsch. Eine Frage, Empfehlung, Arbeitsannahme.
- Über Nacht arbeitet das Team ohne Basti: "Entscheidungen trifft Jonas, nichts Irreversibles" (sprints/s7/refinement/brief.md Z. 3). Konkretes Beispiel: Default-Wechsel auf die neue Welt wurde als "einzige schwer umkehrbare Nachtentscheidung" nicht getroffen; Basti entscheidet nach eigenem Test (sprints/s7/refinement/ergebnis.md, Streitprotokoll). Der Satz "nichts Unumkehrbares" steht so nicht wörtlich im Repo; die Regel ergibt sich aus brief.md und diesem Entscheid.
- Drei Fragen an Basti im S7-Refinement, Kapazitätstabelle: sprints/s7/refinement/ergebnis.md.

## B6. Gates, Messwerte, Zahlen

- Beleg-Stufen: M gemessen, V Voraussetzung/synthetisch, R Rechnung, O offen. "Synthetisch zählt nicht." (D7; sprints/s2/design/production/day1-3/k07_gate_geruest.md)
- Gates G1 bis G9 und H1 (sprints/s2/design/po/day1-3/gate_kriterien.md).
- Perf-Gate S7: Übersicht höchstens 1,0 M Dreiecke und 300 Draw Calls, Stadt nah höchstens 2,9 M, Ladezeit höchstens 3 s (S7: höchstens 6 s im Sandkasten wegen Last), +10 % = rot. Ergebnis S7: 0,76 M / 250 DC, Stadt nah 1,15 M, Ladezeit 2,0 bis 2,2 s (sprints/s7/review_retro.md; sprints/s7/refinement/ergebnis.md). "Gemessen sind Zählwerte, keine FPS."
- Fehlalarm 1,6 M Dreiecke: gezählter Wert ohne Culling. 70 Baum-MultiMeshes mit 1,49 M Dreiecken werden jenseits visibility_range_end 1,8 km nicht gezeichnet; live höchstens etwa 0,62 M / 136 DC; 92 % der gezählten Dreiecke sind Bäume (phase4/felix_perf_aufschluesselung.md; phase4/ta_welle2.md). Prototyp-Übersicht live 145.702 Dreiecke / 111 DC gegen 565.902 gezählt (phase4/integration_w2.md).
- Sim-Parität: Sim rechnet in Feldern, 1 Feld = 25 m (S7-Maßstab), Easing nur Anzeige, Prüfsumme an = aus (sprints/s7/refinement/ergebnis.md; phase4/felix_welle2.md).
- Ökonomie-Bot: Bankrottquote 10 bis 30 %, Zug:Lkw 2,9:1, Kredit ab Minute 12, Zins 3 %/min, M7-Ziel 35 bis 50 min (S6/S7 Review; phase4/tobias_welle1.md).
- Lage-Regeln R1 bis R8 und Stadtstufen (Dorf 9 Felder/225 m, Kleinstadt 18/450 m, Stadt 32/800 m): sprints/s7/block-a/rules_s7.md. (Review nennt Dorf 228 m, gerundet.)

## B7. Bekannte Stolpersteine und Gegenmittel

1. Vorschau rechnet anders als das Spiel (S6 B-1): Jede sichtbare Zahl bekommt einen Test gegen den Spielwert (sprints/s6/review_retro.md). S7 H3: HQ-Vorschau nennt 9 von 12 Städten "Wagnis" (sprints/s7/abnahme/daniel_d09.md). Regel: Spiel und Validator rechnen dieselbe Regel.
2. Tests auf Platzhalterkarte werden rot, sobald die echte Karte kommt (S7 Retro). Tests auf echten Daten schreiben.
3. Gezählt gegen live gemessen (1,6 M). Immer Messart im Gate nennen und Gate auf dem Wert definieren, den der Spieler erlebt.
4. Widersprüchliche Profilwerte zwischen Rollen (E5/E6 in Felix' Easing rot; Lösung per PO-Entscheid I9/I10; phase4/integration_w2.md, felix_welle1.md). PO-Entscheidung kommt als Zahl mit Begründung, sonst blockiert der Streit den Test.
5. "ABW bewusst" (I11: A 1,30x, B 1,38x bei W/2-Toleranz) ist keine Abnahme. Ablaufdatum und Rücknahmebedingung nennen.
6. Bewusste Vertragsänderung (M8, Siedlungsschild "Weiler: nie ein Schild") nur mit Eintrag im Entscheidungslog (phase4/fixpass_w2.md).
7. Bot-Ergebnisse sind Annäherungen: Marktflecken-Knick K18 (Nachfrage Kleinstadt x1,0 niedriger als Dorf x2), Bot passiv, Slice-Karte mit 8 Orten, n = 150 statt 300 wegen Last, Repo-Drift (Skript-Spieler M7 36,0 min statt 30,4 min bei T-15, Ursache nicht untersucht) (phase4/tobias_welle1.md).
8. Regression d07 (21 Suiten, 1.361 bis 1.565 s) nach Welle 2 nicht erneut gelaufen (integration_w2.md; ta_welle2.md P7). Vor Abnahme erzwingen.
9. Agenten-Limit: zwei Agenten liefen in S7 ins 5-Stunden-Limit; kein Fable ohne Basti-Freigabe (sprints/s7/review_retro.md).
10. Exporttemplates fehlten spät (S3, F-12; sprints/s3/day8-10/review/retro_s3.md).

## B8. Vorlagen

Entscheidungseintrag (aus S2-Praxis):
| # | Entscheidung (eine Zeile mit Zahl) | Begründung | Konsequenz/Owner | Revidierbar bis/durch |

Frage an Basti:
- Frage in einem Satz. Optionen A/B/C je mit Kosten. Empfehlung. Arbeitsannahme bis Antwort. Status: entschieden / Annahme / an Basti.

Aufgabenkarte für Basti (sprints/s8/design-sprint/phase4/aufgabenkarten_v1_1.md): 11 Karten A1 bis A11, mit ehrlicher Liste bekannter Lücken (Marktausschnitt klein, Blockpferd, wenig Leben, Platzhalterhäuser).

---

# TEIL C: Eigene Lücken und Lernstand

Konfidenz: hoch = mehrere Quellen oder direkt aus Repo belegt; mittel = eine gute Quelle plus Folgerung; niedrig = Meinung oder Analogie.

## C1. Was wir jetzt wissen

| Aussage | Konfidenz |
|---|---|
| Pillars müssen Features ablehnen können; wir haben nur für zwei Pfeiler (1, 5) Gate-Tests | hoch (Repo) / mittel (Quellen) |
| Eine Zahl im Akzeptanzkriterium plus Messart ist die wirksamste Regel gegen Messstreit | hoch (S2, S7 Repo) |
| Revidierbarkeit pro Entscheidung festhalten; Ersetzen statt Überschreiben | mittel (Nygard) |
| Basti als einziger Tester liefert Richtung, keine Abdeckung | mittel (NN/g: 1 Nutzer etwa 31 %) |
| Feedback in Fehler/Design/Parameter/Look sortieren, hinter den Wunsch auf das Problem schauen | mittel (Darrah, Valve, Projektpraxis) |
| Scope Creep trifft über die Hälfte der Projekte (52 % PMI 2018) | mittel (eine Erhebung, 2018) |
| Prototyp braucht Leitfrage und Nicht-Beweis-Liste | mittel (Houde/Hill sekundär) |
| Bot-Zielband (Bankrott 10 bis 30 %) ist ein Proxy und kann Goodhart auslösen | mittel |

## C2. Was unsicher bleibt

- Ob RICE oder WSJF für ein Team ohne Nutzerzahlen mehr nützt als gute Reihenfolge und Abhängigkeitsdenken: [Streit], nicht entscheidbar aus den gelesenen Quellen. Probe: eine Refinement-Runde mit leichter Wert/Risiko/Größe-Tabelle neben dem PO-Urteil, danach vergleichen.
- Ob das Design-Sprint-Format für Simulation mit langer Wirkungskette taugt: nur eine Einzelquelle zum Standardformat, Anpassung ist eigene Folgerung. Konfidenz niedrig.
- Ob 3 Pillars oder 5 richtig sind: Quellen sagen etwa 3, wir haben 5. Nicht entschieden; Test: wie oft hat jeder Pfeiler ein Feature abgelehnt.
- Wie sich die Kapazität durch E8, E10, E11, E14, E15 verändert hat: im Repo nicht bewertet.
- "ABW bewusst" bei E6 und die Frage, ob Maßtoleranz +/-25 % als Abnahmekriterium trägt: Messung liegt vor, Akzeptanz durch Basti steht aus.
- Wie viel der etwa 15.300 Markdown-Zeilen gelesen werden: nicht gemessen. (Unsicherheitswörter im Repo: "offen" etwa 398, "Annahme" etwa 302, "Platzhalter" etwa 116, "ABW" etwa 116.)
- Reddit-Praxiswissen (r/gamedev, r/gamedesign, r/IndieDev, r/agile, r/projectmanagement) fehlt komplett, weil nicht lesbar. Aussagen aus Foren-Erfahrung sind in diesem Skill nicht enthalten.

## C3. Lernfragen PO (priorisiert) und Stand

1. Schneiden unsere Pillars wirklich Features? Stand: nur 2 von 5 getestet. Offen. Maßnahme: je Sprint ein Pillar-Check im Refinement mit "Was haben wir wegen X abgelehnt?".
2. Wie priorisieren wir explizit? Stand: PO-Urteil plus Streitprotokoll. Maßnahme: leichte Tabelle (Wert, Risiko, Größe, Konfidenz) als Gesprächsgrundlage.
3. Wie kontrollieren wir Scope und "geschoben nach S8"? Stand: Schnittlinie vorhanden, Liste wächst (S7-Review). Maßnahme: je verschobenes Ticket Tausch benennen oder streichen.
4. Entscheidungslog und Umkehrbarkeit: Stand gut (D1 bis D24 mit Spalte), Lücke: Überschreibungen ohne neue Nummer (M8 war bewusst, aber nicht alle). Maßnahme: ersetzt/Verweis.
5. Wann ist ein Prototyp fertig? Stand: Kriterien 1 bis 6 vorhanden, aber ABW ohne Ablaufdatum. Maßnahme: Leitfrage und Nicht-Beweis-Liste je Welle.
6. Basti steuern: Stand: Triage und Fragenformat bewährt. Lücke: Maßstabsfehler (10 vs 25 m/Feld) wurde erst durch Feedback sichtbar. Maßnahme: Skalen-Check vor jedem Asset-Auftrag.
7. Design-Sprint-Adaption: Stand: Charter vorhanden, kein Test mit mehr als einem Tester möglich (D16).
8. Testvalidität mit einem Tester und Bot: Stand: bekannt, nicht lösbar, nur benennen. Maßnahme: jede Aussage "belegt" nur mit Messart.
9. Genre-Standard gegen Eigenes (D15): Stand klar. Offen: Wo endet "Standard" (E8 Moderne? E10 Wasser?).
10. Vertical Slice und Meilenstein-Definition, "Demo Hell": Stand: M0/M1 definiert (plan/rahmen.md), keine Polierfalle belegt. Offen, Beobachtung bleibt.
11. Epoche und Umfang (1820 bis heute, E8): Risiko im Charter benannt, Wirkung nicht bewertet.

## C4. Was wir ab sofort anders machen (Jonas)

- Jede Entscheidung bekommt "revidierbar bis/durch" und bei Änderung eine neue Nummer.
- Jede Abnahmezahl nennt die Messart (gemessen, gezählt, berechnet, Annahme).
- Jeder "bewusst offen" bekommt Datum und Rücknahmebedingung.
- Pillar-Check im Refinement: Was wurde wegen eines Pillars abgelehnt?
- Vor Asset-Aufträgen: Maßstab und Einheit in der Aufgabenkarte.
- Aussagen aus Blogs oder Foren sind in Entscheidungen als Meinung zu kennzeichnen.

## D. Lern-Routine (verbindlich, seit 2026-11-03)
**1. Wissenscheck** vor jeder fachlichen Antwort/Entscheidung: Steht sie hier mit Marke [K]/[V]/[R]? Ja: anwenden. Nein, oder nur [E]/[W]/niedrige Konfidenz: weiter mit 2.
**2. Recherche-Trigger** (einer genügt; laut sagen: "Wissenslücke: <Frage>, ich recherchiere"): a) Ich weiß es nicht oder rate. b) Derselbe Kompromiss/Workaround zum 2. Mal ("wieder X statt Y"). c) Eintrag unter Offene Lücken oder [E]/[W]/niedrig, und die Entscheidung hängt daran. d) Skill, Repo, Doku oder Messung widersprechen sich. e) Engine/Tool/Version neuer als der Skill-Stand. f) Basti korrigiert oder eine Entscheidung wird zurückgenommen. g) Teure oder unumkehrbare Entscheidung bei Konfidenz unter mittel. h) Derselbe Fix scheitert 2x.
Rollen-Trigger: Priorisierung ohne Aufwand-/Wirkungsdaten; derselbe Scope-Streit zum 2. Mal; Basti-Feedback widerspricht dem Backlog.
Erst prüfen statt recherchieren, wenn billig messbar (Test, Doku-grep, Mini-Versuch). Geschmack klärt Prototyp oder Basti, nicht das Web.
**3. Ablauf**: Frage in einem Satz; Primärquellen zuerst (Doku, Issues, Forum, Postmortems; Reddit blockiert, nicht umgehen); 2 unabhängige Quellen; wenn möglich Eigenversuch [V]; Ergebnis mit Quelle, Datum, Marke. Budget 15 min, mehr nur als Agent. Unbeantwortet: Lücke eintragen, Basti/Team fragen, nie raten.
**4. Insight aufnehmen**, wenn alle vier stimmen: wiederverwendbar (2x gebraucht oder über 1 h Aufwand), belegt, noch nicht drin, kein Tagesstand (der gehört in Repo-Doku). Sofort bei Basti-Korrektur, Fehler im Skill oder Engine-Falle mit Repro, sonst gesammelt zum Sprintende. Eine Zeile mit Marke, Datum, Quelle; Widerspruch ersetzt den alten Eintrag; geschlossene Lücke streichen; Skill bleibt ca. 10.000 Zeichen. Im Account nur per Vorschlagskarte an Basti.
**5. Kompromisslog**: jeden Kompromiss, Workaround, jedes "wusste ich nicht" mit Datum in `sprints/s8/fortbildung/mt-po/LERNLOG.md` zählen; Zähler 2 löst Trigger b aus; Auswertung in der Sprint-Retro.
