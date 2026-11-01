# Position DESIGN (Lena Hoffmann, Tobias Brandt) - Refinement Sprint 6

Alle Zahlen Modellrechnung (Tobias, 300 Läufe je Standort), nichts an Spielern gemessen. Basti-Feedback kann den Sprint verschieben: wir planen 6,5 von 8 T je Person, Rest Puffer.

## Kandidaten

| Ticket | Votum | T | Harte Akzeptanz |
|---|---|---|---|
| L-12 | rein, **zuerst** (Tag 1-2, blockiert F-20) | 1,5 | Wagnis-/Umsetzregel und alle Vorschau-Texte final; jede der 8 Städte hat Text für Radius, Kette, Größe, Lizenzfaktor, Gelände |
| T-14 | rein | 3 | 3 Standorte (Mittelfurt, Haberau, Kohlberg) je 300 Läufe: Bankrott 10-30 %, M7 35-50 min ±15 %; Zug schlägt Lkw ab ≤ 33 E/min bei 25 Feldern; Übergabe an Sophie bis Tag 3 |
| S-12 | rein, **Pflicht** | 2 | Werkzeugfabrik 40 F., Mühle Mittelfurt 45 F., Dorfnachfrage ×2; Validator Exit 0; D-07 weiter 8/8; mindestens 3 Städte mit vollständiger Kette (heute 2) |
| F-20 | rein | 5 | Platzierung in ≤ 5 Klicks ab Kartenstart; Hover-Karte 150 ms ±50; 8 von 8 Städten zeigen Karte; kein Modal; Reduced-Motion ohne Ringanimation; Startdialog entfernt, D-07 8/8 |
| SK-01 | **kleiner**, nach T-14 | 1 (nur Lena) | Eine Seite: Slots, Punktefluss ab M1b, max. 3 Beispieläste mit Wirkung in Prozent. Kein Bau |
| F-21 | Lager-Fix rein, 10k-Vorbereitung raus | -2 | Lager-Fix mit Regressionstest, sonst Bankrottmessung verzerrt |
| S-13 | **kleiner** auf 2,5 T | -1,5 | Nur HQ-Gebäude und Industrie-Props für Mittelfurt, Haberau, Kohlberg; Wasser/Gelände nach R2 |
| U-02b | kleiner: Zielpfeil + Linienlisten-Breite | -1 | Label-Kanten schieben |
| A-08 | schieben | - | Wird erst nach F-20 gebraucht |

## Antworten auf die offenen D22-Fragen

1. **Wagnis-Standorte: erlauben, mit ruhigem Hinweis.** Lena: Civ-Freiheit ist der Kern von D22; Sperren macht aus der Platzierung eine Auswahl durch die Hintertür. Tobias widerspricht teilweise: Seehafen und Weidenau sind Fallen ohne Lerneffekt (kein Hafen im Slice, Kraftwerk 197 Felder), und wir messen nur 3 Standorte. Er will beide im Slice sperren, weil Basti allein testet (D16) und nach Bankrott in Minute 20 dem Spiel misstraut. Kompromissvorschlag an Jonas: alle 8 erlaubt, Seehafen/Weidenau mit deutlichem Text „im Slice nicht balanciert“.
2. **HQ in den ersten 2 min frei umsetzen: ja, aber bis zum Kauf der ersten Lizenz** (oder 2 min Spielzeit, was zuerst eintritt). Begründung: Die Vorschau ist Information, kein Vorteil; nach dem Lizenzkauf wäre Umsetzen ein Preisexploit (Lizenz im Radius ×0,70).
3. **Kleinstadt bleibt bei 2.500.** Das Wachstumsfenster 2.500 auf 5.000 (39 min) ist gerechnet; bei 1.000 fiele die Nachfrage von 25 auf 10 E/min, also Dorfniveau, und alles wäre neu zu rechnen. Kohlbergs Problem ist die ferne Werkzeugfabrik, nicht die Größe.

## Bewusster Widerspruch zu anderen Disziplinen

- **Look vs. Spielbarkeit (gegen Sophie, S-13):** 4 T Look gegen 2,5 T. Argument: Bastis Feedback ist der größte Unsicherheitsfaktor; ein hübsches Wasser rettet keine leere Hover-Karte. Props nur dort, wo Basti im Platzierungsmodus hinschaut.
- **S-12 vor allem anderen (gegen Aylin/Mira, die F-20 zuerst bauen wollen):** Ohne Kartenpaket sind 6 von 8 Hover-Karten leer, F-20 wäre technisch fertig und spielerisch tot.
- **Skilltree jetzt oder später (Lena und Tobias uneinig).** Lena: Skillpunkt ab M1b ohne Ziel ist ein Bruch in D22 („Spezialisierung über Skilltree“), also v0 jetzt. Tobias: raus, denn Skill-Wirkung lässt sich ohne Firmenkauf und Profil-Entscheid (J-09, SP-01 in R2) nicht balancieren; seine 1 T gehört T-14. Einigung: 1 T Lena, Tobias 0.
- **Diagnose (A-08) schieben (gegen Aylin):** Eine Diagnose-Aktion hilft nur, wenn Bankrottquote und Lager stimmen; erst T-14 und Lager-Fix.

## Sprintziel (Vorschlag)

Basti wählt sein HQ per Hover-Vorschau auf einer Karte, auf der mindestens drei Standorte eine vollständige Kette haben, und startet mit einem Kapital (6.000 $), das in 10-30 % der Läufe zum Bankrott führt.
