# SK-01 Skilltree-Konzept v0 (Lena Hoffmann, Papier, keine Balance)

Basis: `concept/lena.md` (Skilltree = Technik-Unlocks, ein System), `hq.md`, D22. Zahlen sind Platzhalter für Tobias, nichts gemessen.

## 1. Struktur
- **6 Äste** wie im Konzept (Stadtverkehr, Agrar & Nahrung, Schwerindustrie, Schiene, Straße & Logistik, Wasser). In R1 nur **3 Äste mit je 1 Stufe** sichtbar, passend zu den drei gemessenen Startorten (Agrar, Schwerindustrie, Straße & Logistik). Der Rest ist ausgegraut mit Vorschau.
- **Knotentypen:** Rangknoten (1/3 oder 1/5, Prozent) und **Schlüssel-Fähigkeit** (1 Punkt, neue Möglichkeit, größer gezeichnet, ein Satz Nutzen).
- **Slots:** keine Ausrüstungsslots. Der Baum ist Besitz, kein Loadout. Einzige Begrenzung ist der Punktevorrat. Pro Epoche ist 1 Schlüssel-Fähigkeit aus 2 benachbarten Ästen wählbar (Konzeptregel).
- Skilltree und Technik sind **ein** System: Fahrzeuge sind Knoten im Ast.

## 2. Punktefluss
| Quelle | Punkte |
|---|---|
| **M1b** (erste Lizenz) | 1 freier Punkt, in jeden Ast setzbar. Empfehlung des Spiels: Ast der Startstadt |
| Tutorial-Meilensteine M2 bis M7 | je 1 freier Punkt oder 1 Astpunkt (wie Meilensteintabelle) |
| Epoch-Meilensteine | je 1 freier Punkt |
| Ast-XP aus tatsächlichem Transport | alle 1.000 XP 1 Punkt nur für diesen Ast |
| **Nie** | Geld. Punkte lassen sich nicht kaufen |

Kopfleiste zeigt ruhig "Skillpunkt gespart" (U-02b), bis er gesetzt ist. Kein Pop-up, kein Zwang.

## 3. Beispieläste (Wirkung Platzhalter)
**Agrar & Nahrung**
- Ertragsfelder 1/5: +8 % Output lizenzierter Farmen je Rang
- Marktstand 1/3: +6 % Preis Nahrung je Rang
- Schlüssel **Genossenschaft**: Farmen im Umkreis 15 Felder liefern automatisch ans eigene Lager

**Straße & Logistik**
- Sammeltour 1/5: +5 % Lkw-Kapazität je Rang
- Kurzstrecke 1/3: -20 % Lkw-Unterhalt unter 15 Feldern
- Schlüssel **Verteilzentrum**: ein Lager beliefert alle Abnehmer im Radius

**Schwerindustrie (ex SP-01 Spezialisierung, als Skillast)**
- Hochofen 1/5: +8 % Stahlausbeute je Rang
- Massengutrabatt 1/3: -10 % Umschlagzeit Erz/Kohle
- Schlüssel **Spezialisierung**: eine Industrie auf ein Produkt festlegen (+30 % Output, -1 Inputgut). Wirkt in R1 auf lizenzierte Betriebe, ab R2 auch auf gekaufte

## 4. Spezialisierung: Lizenzen + Skilltree
- **Lizenz sagt, was ich laden darf** (Ort, Radius, Kette). **Skill sagt, wie gut ich es kann.** Ein Skill ohne passende Lizenz wirkt nirgends, und das Spiel zeigt das im Tooltip ("wirkt auf: Mühle Mittelfurt").
- Die erste Lizenz plus der M1b-Punkt legen die Startrichtung fest, ohne Rolle: eine Entscheidung durch Spielen, kein Archetyp-Dialog (D22). Wer später anders lizenziert, setzt die nächsten Punkte um oder nutzt Respec.
- Run-Bilanz benennt das Profil ("gestartet als Mühle, gespielt 58 % Schiene"). Das ist die Wiederspiel-Spur, kein Siegtyp.
- Betriebsprofile (SP-01/02) bleiben draußen. Ihr Rest lebt nur als Schlüssel-Fähigkeit mit **einmaliger** Wahl, nicht als Schalter pro Betrieb.

## 5. Abgrenzung: gehört nicht in den Baum
- **Keine Mikro-Schalter:** nichts, was pro Betrieb, Linie oder Fahrzeug einzustellen ist (Profilwechsel, Fahrplanfeinheiten). Skills wirken global je Ast, nie je Objekt.
- **Kein Geldersatz:** keine Boni auf Kapital, kein "Rabatt auf Skills".
- **Keine Pflicht-Skills:** Grundfunktionen (Lader, Signale, Diagnose) sind nie hinter Punkten. Lesbare Diagnose ist kein Unlock.
- **Keine versteckten Wirkungen:** jeder Knoten zeigt vorab Wirkung in Zahlen und "wirkt auf".
- **Keine Mini-Stufen unter 5 %** und keine Ketten aus 10 Prozentknoten (Spreadsheet-Gefahr, Factorio-Forschung ist hier das Gegenbeispiel).
- Deckel laut Konzept: Skill-Erlös maximal +40 %, Produktion gesamt maximal x1,6.

## 6. Offene Fragen für Tobias (Balance)
1. Meilensteine allein (Tobias-Konzept) oder zusätzlich Ast-XP (Lena)? Beides gleichzeitig kann den Punktevorrat sprengen.
2. Wie viele Punkte bis M7 (35 bis 50 min) sind für die Startorte neutral? Mein Gefühl: 3 bis 4, ungemessen.
3. Trägt ein einzelner Rang +8 % auf einem Lizenzbetrieb schon sichtbar, oder verschwindet er im Rauschen der Sättigung?
4. Respec-Kosten (25 % Ast-XP) in R1 sinnvoll oder erst später?
5. Schlüssel-Spezialisierung vor dem Firmenkauf: überbewertet sie Lizenzbetriebe gegenüber dem Kauf in R2?
