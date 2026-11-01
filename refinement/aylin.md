# Refinement S2 – Aylin Kaya (UX/UI)

## Meine Tickets

**A-04 Problem-Feed mit Ursachenkette (Spike, 3 T)**
Leitfrage: Finden Spieler über Feed und aufklappbare Kette die Wurzelursache schneller als über die Karte allein?
- Figma-Klickprototyp mit 4 statt 6 Szenarien: Signal-Wartezeit, Deadlock, Lager voll, Stadt unterversorgt. „Lkw halb leer“ und „Firma kaufbar“ schiebe ich nach S3.
- Im Playtest finden 4 von 6 die Wurzelursache in < 60 s, Feed-Variante im Median ≥ 30 % schneller als die Variante ohne Feed.
- Fehlklicks bis zur Ursache im Median ≤ 2, jede Meldung hat Ort, Ursache und Vorschlag.
- Abhängigkeiten: Felix' Kettenstruktur aus F-04 (nur das Format). Fertig bis 18.11., damit der Testbuild darauf aufsetzen kann.

**A-05 Diagnose-Datenvertrag (Spike, 1,5 T)**
Leitfrage: Welche Felder braucht eine Meldung, damit Feed, Kette und Sprung zur Karte ohne Umbau funktionieren?
- Spezifikation auf einer Seite plus Textvorlagen für die 4 Szenarien, nicht für alle VS-Meldungen.
- Felix bestätigt, dass `get_wait_chain()` jedes Feld liefert oder markiert, welches fehlt.
- Abhängigkeiten: F-04, Daniels Ereignisformat. Das ist **keine** Arbeit nach F-04: Ich setze mich am 17.11. für einen halben Tag zu Felix, solange die API noch formbar ist.

**A-06 Bau-Tool-Spike UX (Spike, 0,5 T, Rest geschoben)**
Leitfrage: Passen Ghost-Zustände und Grund-Texte zu dem, was die Gültigkeitsprüfung technisch liefern kann?
- Ich liefere nur eine Liste der Grund-Strings und die Ghost-Farbregel (baubar/nicht baubar plus Grund am Cursor), bevor Felix anfängt.
- Mockups für Magnet-Radius und Erreichbarkeits-Label schiebe ich in die finale Bau-Spezifikation in M1.

## Einwände

1. **F-06 Testbuild: „Debug-Overlay mit Ursachenkette als Text“.** Damit testen wir die Lesbarkeit eines Debug-Logs und nicht unseren USP. Mein Vorschlag: Felix baut im Testbuild nur Meldung, Kette als Liste und den Sprung zur Karte nach meinem Mini-Entwurf vom 18.11. Grau reicht.
2. **L-06 / Daniels Playtest / mein „Mitgestalten“: dreimal derselbe Test.** Lena plant 5 Fehler, Felix baut 3, Daniel präpariert 3 Spielstände. Mein Vorschlag: ein einziges Ticket L-06 mit fester Rollenverteilung. Lena macht das Szenario, ich Aufgaben und Messgrößen, Daniel Durchführung und Protokoll. Wir nehmen die 3 Fehler, die Felix wirklich baut, und Lena setzt ihre 5 auf 3 herunter.
3. **L-03 Meilensteinleiste: Mich nach Platzbedarf im Ziele-Panel zu fragen, ist zu spät.** Mein Vorschlag: Ich gebe vor dem Start 0,25 T Rahmen vor (max. 3 Ziele, ≤ 60 Zeichen), und L-03 schiebt nach S3.
4. **S-05 Farbatlas / Farbsehschwäche doppelt mit Daniels Prüfverfahren.** Mein Vorschlag: Daniel liefert die Checkliste, Sophie prüft damit einmal, und ich bringe die Schweregrad-Farben rot/gelb/blau des Feeds mit ein. Spart rund 1 T.
5. **F-07 Bau-Spike ohne meine Grund-Texte.** „Gültigkeitsprüfung mit Grund-String“ heißt sonst „ERR_SLOPE“. Mein Vorschlag: Meine Liste aus A-06 ist Eingangsbedingung für F-07. Falls Felix ihn wegen Überlast streicht, bin ich einverstanden.
6. **T-07 Headless-Sim in S2.** Blockiert Felix über die SimWorld-Schnittstelle, fürs Gate reicht das Tabellenmodell. Nach S3 schieben.

## Meine Kapazität und Forderung

| Ticket | Tage |
|---|---|
| A-04 Feed-Prototyp | 3 |
| A-05 Datenvertrag (inkl. halber Tag mit Felix) | 1,5 |
| L-06 Aufgaben, Messgrößen, Co-Beobachtung, Auswertung | 2 |
| A-06 Grund-Strings + Ghost-Regel | 0,5 |
| UX-Entscheidungsvorlage fürs Gate | 0,75 |
| Rahmen Ziele-Panel für Lena | 0,25 |
| **Summe** | **8** |

Meine Forderung: Der Diagnose-Playtest ist das Sprintziel. Darum hat alles, was ihn speist, Vorrang vor Look-Test und Benchmark-Feinschliff: F-04 als Ketten-API, F-06 mit echter Feed-Struktur und A-04. Ich verlange einen festen halben Tag mit Felix am 17.11. Außerdem will ich, dass jedes Ticket mit Spieler-UI ab sofort UX als Eingangsbedingung hat und nicht als „braucht Aylin“ irgendwo am Ende steht. Ohne Feed-Antwort am Gate ist der USP nicht getestet.
