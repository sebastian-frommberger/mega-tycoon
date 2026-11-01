# Position UX und ART (Aylin, Sophie), Refinement Sprint 6

Leitlinie: D22 ist der Sprint. Alles, was der erste Klick im Spiel nicht berührt, ist verhandelbar. Basti-Feedback kann kommen, deshalb ca. 1 T Puffer je Person.

## Kandidaten
| ID | Votum | Tage | Harte Akzeptanz |
|---|---|---|---|
| F-20 | rein, Pin-Vergleich raus | 5 (statt 5 + Pin) | Startdialog weg; Karte bleibt bedienbar; Vorschau ≤ 150 ms nach Hover; Ring ≤ 0,4 s, bei Reduced Motion sofort; Zustände mit Icon + Text; Kontrast ≥ 4,5:1; Esc bricht ab; Panel ≤ 380 px |
| L-12 | rein, **vor** F-20-Bau (Tag 1–2) | 1,5 | 6 Vorschau-Texte fertig, Wagnis-Text ohne Rot, vier Jonas-Fragen entschieden |
| T-14 | rein | 3 | Zahlen an Sophie bis Tag 2, sonst blockiert S-12 |
| S-12 | rein | 2 | check_s10 grün, NO/SW bleiben unter Grenze (liegen heute exakt am Rand), Fluss-Schnitt-Test grün |
| U-02b | **kleiner** | 2 (statt 4) | Zielpfeil frei von Labels; Haberau-Label im Nahzoom sichtbar; Linienliste ≤ 340 px (Zeile kürzen, nicht verbreitern) |
| A-08 | **kleiner**, nur Toast | 2 (statt 3) | Ursache + Ort + 1 Aktion, 1 Meldung, kein Modal; Chip am Fahrzeug erst R2 |
| S-13 | **kleiner**, nicht raus | 2,5 (statt 4) | HQ-Gebäude + Props für 3 Kandidaten; Gras-Kontrast ≥ 3:1 am Marker bleibt; Bäume ohne Schatten |
| SK-01 | schieben | 0 | siehe Widerspruch 3 |
| D-08 | rein, erweitern | 5 | Platzierung: Hover, Ghost, Abbruch, Umsetzen; Screenshot je Standorttyp |
| K-10 | rein, 1 T | 1 | Tech-Art ablehnen: Sophie trägt Kenney-Props selbst |

Begründung U-02b: Mira hat in S5 Tempo-Leiste, Label-Größe/LOD, Startdialog-Blur und Linienliste schon gebaut. Übrig ist der Rest der Spec.

## D22-Platzierung ohne Modal (Vorbild: Civ-Siedler, Panel-Logik Anno/Cities)
1. **Start, Zeit pausiert.** Karte voll sichtbar, Hinweisleiste „Wo gründest du?“, Kopfleiste zeigt Kasse 6.000 $. Kein Dialog.
2. **Hover (150 ms).** Radiusring wächst, Industrien im Ring leuchten mit Luftlinie, der Rest bleibt gedämpft. Die Vorschau erscheint **im rechten Kontextpanel-Slot** (angedockt, 380 px), nicht am Cursor: Der Ring bleibt frei, es ist dasselbe Muster wie später.
3. **Vorschau zeigt (max. 6 Zeilen):** Stadt, Größe, Nachfrage; Kettenstatus (vollständig/teilweise/keine, Icon + Text); nächste Industrien mit Entfernung; ein Lizenzfaktor, Aufschlüsselung auf Tipp; Gelände (Fluss, Berg) in einer Zeile. Wagnis sachlich: „Kein Rohstoff im Radius. Nächste Farm 121 Felder, Lizenz ×3,9.“
4. **Klick** setzt den Ghost an den Stadtrand (weiß = baubar). Knopf „HQ hier gründen“ im Panel, Esc oder Klick auf andere Stadt wechselt. Kein Bestätigungsdialog.
5. **Zeit startet.** Ring bleibt als dünne Linie, Preise erscheinen an den Industrien, Toast „HQ verschieben möglich (1:40)“.

## Widersprüche
1. **S-13 verteidigen (Sophie, gegen Kürzung auf null).** Die Platzierung ist der erste Eindruck, und leere Industrien im Ring wären ein Armutszeugnis gegen D21. Wasser/Gelände dagegen schiebt Sophie selbst, Aylin geht mit. **Uneinig:** Aylin würde auch das HQ-Gebäude auf R2 schieben, ein Marker genüge. Sophie: Ghost ohne Gebäude ist kein „Gründen“.
2. **A-08 gegen U-02b-Umfang (Aylin).** Der HUD-Bau ist halb erledigt, die Spec ist nicht mehr 4 T wert. Mira soll die 2 gewonnenen Tage in A-08 stecken: „Lkw steht“ war der größte Lesbarkeitsmangel in D-07. Widerspruch an Felix/Mira, die HUD-Pflege vor Diagnose setzen.
3. **SK-01 zu früh (Aylin und Sophie einig).** Ohne Bastis Feedback und ohne UI wird das Paper Spekulation. Aber: M1b vergibt +1 Skillpunkt, der heute ins Leere geht. Lösung: Kopfleiste zeigt „Skillpunkt gespart“ als ruhige Zeile, SK-01 wartet auf R1-Feedback.
4. **Pin-Vergleich (Aylin dafür, Sophie dagegen).** Civ zeigt Erträge per Hover, nicht per Anpinnen. Wir streichen Pin aus S6 (Layoutaufwand zweiter Slot). Aylin merkt es für R2 vor.
5. **Wagnis erlauben (gegen Sperren).** Civ sperrt Gründung nie. Die Vorschau erklärt das Risiko, das ist ehrlicher als Verbot.
