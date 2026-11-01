# Panel-Durchlauf 1 – Diagnose-Test F-06 (synthetisch, 6 Personas, Haiku)
Material: Meldungstexte v1 (D11, ohne Vorschlag) + ein Screenshot des Testbuilds (F2 aufgeklappt). Aufgabe identisch. Ausgang laut Persona; Zählung nach Lenas Regel (benannte Wurzelursache zählt, Handlung nicht) vom Koordinator vorgenommen, nicht von Lena gegengezeichnet.

| Persona | Fehler | Ausgang (Persona) | Wurzel benannt (Zählregel) | Hauptproblem |
|---|---|---|---|---|
| 1 Jens (TF2) | F1 eingleisig | Abbruch | ja ("Strecke eingleisig") | wollte Signal umschalten (TF2-Gewohnheit), keine Handlung/Gleisbau-Stelle |
| 2 Mara (OpenTTD) | F2 Kreis | gelöst mit Umweg | ja (Ring aus 4 Zügen) | Abschnittsnummern fehlen auf Karte, Zeiten inkonsistent |
| 3 Klaus (RE) | F3 Ladung | Abbruch, falsche Ursache | nein (Gleisblockade = Symptom) | überliest Wirtschaftszeilen, "Hafen-Ost" auf Karte nicht auffindbar |
| 4 Tim (Casual) | F1 eingleisig | Abbruch | Grenzfall ("zu wenig Gleis") | Begriffe, keine Handlung |
| 5 Lea (Zuschauerin) | F2 Kreis | Abbruch | ja ("warten im Kreis") | keine Handlung, Fachbegriffe |
| 6 Sven (Rot-Grün) | F3 Ladung | gelöst mit Umweg | ja (zu wenig Ware) | Statusfarben nicht unterscheidbar, Screenshot passt nicht zur Meldung |

Synthetisches Ergebnis: Wurzel benannt 4/6 sicher + 1 Grenzfall; die Kette scheint lesbar. Zeitmessung (<60 s) nicht möglich.
Wiederkehrende Befunde (>= 2 Personas):
1. Keine Handlung: 3–4 Personas brechen ab, weil nicht klar ist, was zu tun ist (Vorschlag im Test nach D11 bewusst ausgeblendet) → für den Test korrekt, fürs Produkt der wichtigste Befund.
2. Orte nicht auffindbar: Abschnittsnummern und Ortsnamen ("Hafen-Ost", "Abschnitt 31–34") stehen nicht auf der Karte (2 Personas).
3. Inkonsistente Zeiten zwischen Text (1:40 / 2:10) und Build (2:05 / 2:07) (4 Personas) → Material-Fehler, vor echtem Test angleichen.
4. Wurzelzeile im Screenshot sichtbar als "Wurzelursache" markiert → verrät die Antwort; prüfen, ob das im echten Build so gewollt ist.
5. Statusfarben für Rot-Grün-Schwäche nicht unterscheidbar; Statusformen (S-05) fehlen im Testbuild (1 Persona, aber passt zu Daniels Farbcheck).
Grenzen: Haiku-Personas, nur Text + 1 Screenshot statt interaktivem Build, Selbstauskunft statt Beobachtung. Zählt nicht für G1.
