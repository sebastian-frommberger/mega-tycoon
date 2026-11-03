# Lernbericht Jonas (Product Owner), 03.11.2026

Basis: Selbstanalyse aus dem Repo (/home/claude/mega-tycoon, read-only) und Recherche mit rund 20 lesbaren Quellen (URLs in /tmp/claude-0/gd/skills/mt-po/SKILL.md, Teil A). Reddit war nicht lesbar.

## Lücken (was uns fehlte)
- Pillars: Fünf Pfeiler, aber nur zwei (1 und 5) waren gate-getestet; Pfeiler 3 und 4 ausdrücklich nicht testbar in S2 (pillar_fragen.md). Kein belegter Fall "wegen Pillar X gestrichen".
- Priorisierung: PO-Urteil plus Streitprotokoll, keine explizite Tabelle (Wert, Risiko, Größe, Konfidenz). Wir wussten nicht, dass RICE und WSJF ohne Nutzerzahlen Scheingenauigkeit liefern können und dass Reihenfolge Abhängigkeiten schlägt.
- Scope: "verschoben nach S8" wächst (S7-Review); Bastis Entscheidungen E8, E10, E11, E14, E15 erweitern den Umfang, ohne dass die Kapazitätswirkung bewertet wurde.
- Entscheidungslog: gut (D1 bis D24 mit Spalte "Revidierbar"), aber ohne ADR-Disziplin "ersetzt statt überschrieben" und mit Namenskollision der E-Nummern (S2 Katrins E1 bis E7, S8 Bastis E1 bis E15).
- Prototyp "fertig": Kriterien da, aber "ABW bewusst" (E6/I11) ohne Ablaufdatum; Leitfrage je Welle nicht ausdrücklich.
- Feedback und Testvalidität: Ein Tester (Basti, D16) findet statistisch etwa ein Drittel der Probleme (NN/g, L = 31 %) und ist zugleich Auftraggeber.

## Unsicherheiten (bleiben offen)
- RICE/WSJF gegen PO-Urteil: Streit, nicht entscheidbar aus den Quellen; Probe nötig.
- Design-Sprint-Format für Simulationsspiele: Anpassung ist eigene Folgerung, nicht belegt.
- 3 oder 5 Pillars: Quellen sagen etwa 3, wir haben 5.
- Bot-Zielband (Bankrott 10 bis 30 %) ist ein Proxy; Goodhart-Risiko.
- Wirkung der neuen Umfangsentscheidungen auf Kapazität und Termin.

## Top-5-Erkenntnisse
1. Ein Pillar zählt erst, wenn er ein Feature abgelehnt hat (Raspberry Pi/Wireframe: ca. 3 Aussagen, Spielergefühl statt Feature, Vorschläge als great/neutral/bad bewerten). [Konsens]
2. Scope-Kontrolle heißt Tausch und Streichen: 52 % der Projekte erleben Scope Creep (PMI 2018); Postmortems sagen übereinstimmend: früh kürzen. [Konsens]
3. Entscheidungen brauchen Typ (schwer/leicht umkehrbar) und Status (entschieden, Annahme, an Basti); Revision als neue Nummer, nicht still überschrieben (Nygard, Bezos sekundär). [Konsens in der Praxis]
4. Hinter Feedback steht ein Problem, nicht eine Lösung (Darrah, Valve); wir sortieren in Fehler, Design, Parameter, Look und geben Basti Optionen mit Empfehlung. [Konsens]
5. Jede Abnahmezahl braucht die Messart (gemessen, gezählt, berechnet, Annahme); der 1,6-M-Fehlalarm war ein Zählwert ohne Culling, live nur etwa 0,62 M. [Repo, hoch]

## Was wir ab sofort anders machen
1. Jede Entscheidung: Zeile "revidierbar bis/durch"; Änderung = neue Nummer mit Verweis; Namensraum nennt Sprint (S2-E3 gegen S8-E3).
2. Pillar-Check im Refinement: Was haben wir wegen eines Pillars abgelehnt oder gestrichen? Ohne Antwort ist der Pillar ein Poster.
3. Leichte Priorisierungstabelle (Wert gegen Pillar, Risiko, Größe in Tagen, Konfidenz) neben dem PO-Urteil, danach Vergleich.
4. "Bewusst offen" und "ABW bewusst" nur mit Ablaufdatum und Rücknahmebedingung; Prototyp-Welle mit Leitfrage und Nicht-Beweis-Liste.
5. Vor jedem Asset-Auftrag: Maßstab und Einheit in die Aufgabenkarte (Lehre aus 10 m gegen 25 m je Feld).
6. Blog- und Presseaussagen in Entscheidungen als Meinung kennzeichnen.

## Einschränkungen der Recherche
Reddit nicht lesbar (nicht umgangen). Bezos-Primärbrief, Pichler DoR, McConnell-Originalseite gesperrt. WSJF-Details hinter Login. Klein-Premortem "30 %" nicht bestätigt. Mehrere Quellen sind Blogmeinung (Wayline, kindatechnical). Zahlen in referenzen.md mit [~] sind unbelegt.
