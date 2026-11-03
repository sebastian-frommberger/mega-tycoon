# Pilot: Lena (Game Design) wendet Schell-Linsen auf drei offene S8-Entscheidungen an

Stand 03.11.2026. Pfade relativ zu `/home/claude/mega-tycoon/`, falls nicht absolut. Marken: [Beleg] = Datei gelesen, [R] = eigene Rechnung, [Annahme] = nicht geprüft. Linsenkatalog: `/tmp/claude-0/gd/lenses/lenses.md`.

Gelesen: `sprints/s8/fortbildung/mt-gamedesign/` (SKILL, LERNLOG, LERNBERICHT), `resuemee_2026-11-03/` (mt-gamedesign, mt-po, mt-oekonomie, mt-ux), `referenzen_2026-11-03/` (alle 6: aufbau, diagnose, fortschritt, oekonomie, welt, zeitreise), `concept/lena.md`, `concept/hq.md`, `concept/industry.md`, `concept/tobias.md` (Ausschnitte), `sprints/s7/block-b/g01_progression.md`, `sprints/s6/block-b/sk01_skilltree_v0.md`, `sprints/s7/refinement/ergebnis.md` (Streitprotokoll), `sprints/s8/design-sprint/phase3b/15_regelwerk_v1_1.md` (A5, D, F7–F9), `slice/economy.gd` (Sättigung, Ertragsformel), `slice/data/economy_constants.json`, `slice/data/economy_slice.json` (Zeit, Sättigung).

---

## (A) Standardtempo, Epochensteuerung, Zwei Uhren vs. Tempostufen

**Stand im Repo.** 12 min je Spieljahr, 206 Jahre ≈ 41 h (`15_regelwerk_v1_1.md` F7). Konzept: 60–120 min je Epoche (`concept/lena.md` Z. 25). E12: Kalendertempo wählbar (`design-sprint/charter.md`). K26: Kalender und Wirtschaft entkoppeln, Feld `spieljahr_min` (Arbeitsannahme, an Basti F7). K21: Welt-Bild folgt dem Kalender, ob Meilensteine Fahrzeuge zusätzlich sperren, ist offen. Referenzen: Tempostufen 12/3/1/0,3 min je Jahr für die ganze Sim mit Rückfall bei Rot (`referenzen_2026-11-03/zeitreise.md` §1, Idee 1) gegen Zwei Uhren, Wirtschaft fix und nur Kalender 1,5/3/6/12 min je Jahr (`fortschritt.md` §1, Idee A). Im Code ist das Jahr fest an den Monat gekoppelt: `spieljahr_ticks: 7200` = 12 × `spielmonat_ticks: 600` (`slice/data/economy_constants.json` Z. 3); `spieljahr_min` gibt es im Code nicht (grep, 0 Treffer in `*.gd`).

| Linse | Was sie zu genau dieser Entscheidung sagt |
|---|---|
| #27 Time (+ Kap. 13 Short vs. Long) | Frage „Was bestimmt die Länge?“: Die Epochenlänge bestimmt nicht der Kalender allein, sondern die **später erfüllte** von zwei Bedingungen (Frühestdatum, Tor). Bei 12 min/Jahr dauert W1 (30 Jahre) 6 h [R]; jedes Tor ist dann längst erfüllt, der Kalender bindet, der Spieler wartet (genau der TF2-Befund in `fortschritt.md` §2). Bei 3 min/Jahr dauert W1 90 min [R], dann kann das Tor binden. Schell trennt außerdem „Zeit anhalten/raffen“ (Komfort) von „Länge über Endbedingungen steuern“ (Design). Übertragen: **Tempostufen sind Komfort (Wanduhr), Zwei Uhren sind Design (Verhältnis Kalender zu Wirtschaft). Das sind zwei Regler, keine Alternativen.** Die Referenzdateien behandeln sie als Konkurrenz. |
| #69 Interest Curve | Höhepunkte unserer Partie sind Epochenwechsel. Bei 41 h liegen sie 6–8 h auseinander, das ist eine flache Kurve ohne Rhythmus. Bei 60–120 min je Epoche entsteht eine verschachtelte Kurve (Minute: G-01-Entscheidung, ~8 min: Auftrag, ~90 min: Epoche). Die Verschachtelung steht schon als „drei Zeitebenen“ im SKILL (A10). **Neu ist nur der Messweg:** Tester zeichnen nach der Sitzung ihre Interessenkurve, wir vergleichen mit unserer Annahme. |
| #48 Simplicity/Complexity | Zwei Uhren sind eingebaute Komplexität, die der Spieler sehen kann: Läuft der Kalender mit 3 min/Jahr, hat ein Kalenderjahr nur 3 Wirtschaftsmonate [R]. Alles, was wir „je Jahr“ anzeigen oder rechnen, wird dann widersprüchlich: Zins als p.a. im UI (Empfehlung in `oekonomie.md` §1), Bestandserneuerung „1 % je Spieljahr“ (K23 in `15_regelwerk_v1_1.md`), Fahrzeuglebensdauer (Einheit in `concept/lena.md` nicht genannt, nicht geprüft). Der Risiko-Hinweis „Preise fühlen sich zeitlos an“ (`fortschritt.md` Idee A) ist verwandt, die Liste der betroffenen Größen fehlt bisher. |
| #63 Feedback | Bei hohen Tempostufen (0,3 min/Jahr = 40-fach) laufen Warnungen schneller durch, als man sie lesen kann. Rückfall auf Standard bei Rot steht schon in `zeitreise.md` §1. Bestätigt, nichts Neues. |
| #47 Punishment | „Nachzügler wird sanft gezogen, alte Nachfrage sinkt“ (`concept/lena.md` Z. 68) ist eine Strafe. Sie ist fair, wenn sie vorher sichtbar ist (Vorschau eine Epoche vorher steht im Konzept). Belohnung statt Strafe (Bonus für vollständigen Pfad) steht schon in `zeitreise.md` §2 (Civ VII, EU4-Aufholbonus). Bestätigt. |
| #21 Flow, #32 Goals | Fragen nach klaren Zielen und Ablenkung: Antwort ist G-01, steht im SKILL (A1, A8). Kein Beitrag zur Tempofrage. |

**Empfehlung Lena.** Zwei Uhren als Modell (K26 umsetzen), **Standard-Kalenderrate 3 min je Jahr** statt 12, damit eine Epoche 60–120 min dauert und das Meilenstein-Tor binden kann; Kalender bleibt Frühestdatum, Tor entscheidet. Dazu einfache Wanduhr-Stufen (Pause, 1×, 2×, 4×) als Komfort, ohne 40-fach. Option „Klassisch 12 min/Jahr“ für Genre-Fans (E12 bleibt erfüllt).
**Gegenargument.** Bei 3 min/Jahr hat jede Epoche nur ein Viertel der Wirtschaftsmonate: Orte bleiben bis zur Moderne kleiner, Fahrzeuge veralten im Verhältnis viermal schneller (so schon in F7 Option B beschrieben). Alle Jahresgrößen müssen auf Wirtschaftsmonate umgestellt oder doppelt angezeigt werden, das kostet UI-Klarheit (D21). Und: Basti hat „wählbar“ entschieden, nicht den Standard; ein Standard ≠ 12 widerspricht der Genre-Norm (OpenTTD 12 min, `fortschritt.md` §1).

**Billig testen.**
| Test | Aufwand |
|---|---|
| Liste aller Größen „je Jahr“ / „je Spieljahr“ in `slice/data/*.json`, Konzept und Regelwerk (grep), mit Vorschlag Wirtschaftsmonat oder Kalenderjahr | 0,25 PT (Lena) |
| Bot-Lauf: Minuten bis W2 und bis Tor (3 von 5) je Kalenderrate 3/6/12 (Idee A aus `fortschritt.md`) | 1 PT (Tobias), Voraussetzung Feld `spieljahr_min` im Code, Aufwand dafür nicht geprüft [Annahme ≈ 0,5 PT] |
| Basti 2 × 45 min (3 und 12 min/Jahr), danach Interessenkurve auf Papier zeichnen lassen, gegen unsere Kurve legen | 0,5 PT inkl. Auswertung (Lena) |

---

## (B) Skillpunkt-Quote

**Stand im Repo.** Quelle entschieden: Meilensteine und G-01-Etappen, keine Transport-XP (`sprints/s7/refinement/ergebnis.md`, Streitprotokoll). G-01: 6 Punkte bis 60 min, 4 bis M7 (`g01_progression.md` §4). Konzept: ~110 Knoten, ~40 Punkte bis Epoche V, 3–4 Knoten je Ast und Epochenstufe (`concept/lena.md` Z. 99, 120). SK-01: Rangknoten +8 % je Rang, keine Stufen unter 5 % (`sk01_skilltree_v0.md`). Offene Frage: verschwindet +8 % im Sättigungsrauschen? (`g01_progression.md` §6 Frage 2, SKILL A9). Referenzvorschlag ≈ 6 Punkte je Epoche (`fortschritt.md` Idee C), Jonas: 110 Knoten auf ≈ 40 für I–II kürzen (`fortschritt.md` §4).

| Linse | Was sie zu genau dieser Entscheidung sagt |
|---|---|
| #35 Expected Value | Zwingt, „+8 %“ in $ zu bewerten. Der Code rechnet Sättigung als **Grenzpreis je Einheit** (`slice/economy.gd` Z. 15–16, Funktion `f_saett_promille` Z. 353–359): bis 100 % Versorgung voller Preis, 100–150 % linear 1,0 → 0,4, darüber 0,1 (`economy_slice.json` Z. 59). Rechnung [R], Mehrertrag eines Rangs „+8 % Ausstoß“ beim Endabnehmer Stadt, bezogen auf den bisherigen Ertrag: bei 80 % Versorgung +8 %, bei 100 % ≈ +7,6 %, bei 120 % ≈ +5,7 %, bei 160 % ≈ +0,9 %. Dagegen wirkt `B_skill` in der Ertragsformel **nach** der Sättigung (`economy.gd` Z. 13, 364; heute 0, Deckel +0,40 in `sprints/s4/day1-5/lena/l08_slice_regeln_v2.md` Z. 62): ein Rang „+8 % Ertrag“ bringt immer +8 %. **Ob ein Rangknoten zählt, hängt also davon ab, welchen Hebel er bedient, nicht von der Zahl 8.** Lieferungen an Industrien werden ohne Sättigung, aber nur bis zum Abnahmedeckel `s_abn_max` je Periode gebucht (Z. 774–785); Mehrausstoß über dem Deckel bringt dort 0. Ob Mehrinput beim Verarbeiter Mehroutput erzeugt, nicht geprüft. |
| #39 Meaningful Choices | Dominante Strategie: Prozentränge wirken auf die Basis. Wer den größten Ertrag hat (Zug, 2,9:1 gegen Lkw, `resuemee/mt-oekonomie.md` §5), bekommt je Punkt am meisten. Ohne Gegenmittel ist „alle Ränge auf die stärkste Kette“ immer richtig, der Baum verstärkt die Zugdominanz, statt sie zu brechen. Teilweise bekannt (Tobias: Skillpunkte „können das verschieben“). |
| #52 Economy | Skillpunkte sind eine Zweitwährung. Ausgeben ist eine Wahl (Ast, Rang, Schlüssel), **Verdienen kaum** (fixe Meilensteine). Die Lenkung „Punkte entstehen, wo man spielt“ ist mit der Ast-XP gestrichen; G-01 §4 ersetzt sie teilweise („Punkt im Ast der Leistung“). Bekannt, kein neuer Hebel. |
| #46 Reward | Gewöhnung: gleich große Belohnungen verlieren Wert, spätere sollten größer sein. Bei uns heißt das: spätere Punkte in Schlüssel-Fähigkeiten statt weiterer +8-%-Ränge. Steht sinngemäß schon in SKILL A9 und `concept/tobias.md` („Fähigkeiten statt Prozente“). Schells zweiter Rat, Belohnungen zufällig zu streuen, passt nicht zu „Etappe geschafft = Punkt“ (D21, Streitprotokoll S7). Verworfen. |
| #27 Time | Die Quote hängt an (A): 40 Punkte über 5 Epochen à 90 min = 7,5 h ≈ 1 Punkt je 11 min [R]; bei 41 h ≈ 1 Punkt je Stunde [R]. Erst Tempo, dann Quote. Bekannt (`resuemee/mt-gamedesign.md` §5.5, `fortschritt.md` §1 Jonas). |
| #48 Simplicity/Complexity | 110 Knoten bei 40 Punkten sind eingebaute Komplexität. Kürzung steht schon bei Jonas. Bestätigt. |
| #55 Visible Progress | Etappe zeigt vorab ihren Punkt: steht in G-01 §4. Bestätigt. |

**Empfehlung Lena.** (1) Quote je Epoche statt je Minute: bis 60 min wie G-01 (6), danach je Epoche 6–7 (Tor 2, drei Etappen je 1, eine Schlüssel-Fähigkeit), ≈ 36–40 bis Epoche V; nur Epoche I–II kalibrieren. (2) Rangknoten, die Ausstoß erhöhen, nur dort, wo Sättigung selten greift (Zwischenstufen), sonst als Ertrags- oder Kostenhebel (über `B_skill` bzw. Betriebskosten) formulieren. (3) Gegen Dominanz: Prozentränge je Ast deckeln (heute global +0,40) und einen Schlüssel-Knoten je Epoche an das schwächere Verkehrsmittel binden.
**Gegenargument.** Kosten- und Ertragsränge verstärken die stärkste Kette genauso (Prozent auf große Basis); Punkt (2) löst das Sättigungsproblem, nicht das Dominanzproblem. Und „+8 % Stahlausbeute“ ist anschaulicher als „+8 % Ertrag“; abstrakte Ertragsboni sind genau das Prozent-Rauschen, das SK-01 vermeiden wollte. Ohne Bot-Messung bleibt jede Quote ein Platzhalter (Muster „Zahlen für Tobias ohne Messpunkt“, Zähler 3 im LERNLOG).

**Billig testen.**
| Test | Aufwand |
|---|---|
| Tabelle: Mehrertrag je Rangknotentyp (Ausstoß, Ertrag, Kosten) bei Versorgung 80/100/120/160 %, Formel aus `economy.gd` | 0,5 PT (Tobias, Lena prüft) |
| Gepaarter Bot (n = 300): `skill_bonus` 0 gegen 80 ‰ und Ausstoß +8 % auf die stärkste Kette; Messgrößen Δ $/min und Zug:Lkw | 1 PT (Tobias); `skill_bonus` ist eine Variable (Z. 75), ein Ausstoß-Hebel existiert nicht, Aufwand dafür nicht geprüft |
| Quotentabelle Epoche I–II mit Punktminuten, Messpunkt im Bot | 0,5 PT (Lena) |

---

## (C) Firmenkauf / Übernahme von Konkurrenzfirmen

**Stand im Repo.** Kein Besitzmodell im Code (Grep `owner|besitzer|company_id`: 0 Treffer, `oekonomie.md` §3; eigener Grep in `slice/*.gd` ebenso ohne Treffer). Lizenzen liegen je Ort als Ablauf-Tick (`s_lic_until`, `economy.gd` Z. 113). Konzept: Besitz-Leiter Lizenz → Kauf, 50 % der Lizenzgebühren angerechnet, freie Firmen wachsen auf Stufe 2 und werden 30 % teurer (`concept/industry.md` Z. 5–21, 72); Firmenkauf ab M5b, Kaufrabatt −20 % (`concept/hq.md`); KI-Spediteur mit Übernahmeangeboten, Verkauf zu 70 % Firmenwert (`concept/tobias.md` Z. 66, 121, 126). G-01 §5: Firmenkauf als Wahlziel neben F4. Dreimal verschoben (`resuemee/mt-po.md` §4). KI-Firmen: kein Code (`15_regelwerk_v1_1.md` D1).

| Linse | Was sie zu genau dieser Entscheidung sagt |
|---|---|
| #2 Essential Experience | Was ist am Erlebnis „Unternehmer baut Firma“ (`resuemee/mt-po.md` §1) unverzichtbar? Das Besitzen und Ausbauen eigener Betriebe, nicht das Schlucken von Rivalen. Das Repo nutzt „Firmenkauf“ für **zwei verschiedene Dinge**: C1 Industrie kaufen (Besitz-Leiter, braucht keine KI) und C2 KI-Firma übernehmen (braucht Konkurrenz, die es nicht gibt). `oekonomie.md` Idee 4 und `zeitreise.md` Idee 5 meinen C2, G-01 §5 und `hq.md` meinen C1. |
| #40 Triangularity | C1 hat schon die gewünschte Form: Lizenz ist sicher und billig, früher Kauf bindet Kapital und lohnt mit Marge, Warten macht den Kauf 30 % teurer (`industry.md` Z. 72). Die Linse fragt, ob der Lohn zum Risiko passt. Antwort: nicht gerechnet, Werksmarge nicht beziffert (nicht geprüft). |
| #35 Expected Value | Für die Entscheidung Lizenz gegen Kauf fehlt eine Rechnung über 60 min (Lizenz 10 % des Kaufpreises je 30 min, Hälfte angerechnet; Kauf 1.000–4.000 $ × Stufe nach `concept/tobias.md` Z. 118). Ohne Margenzahl kein Erwartungswert. |
| #48 Simplicity/Complexity | C1 lässt sich ohne neues Besitzfeld als **unbefristete Lizenz plus Ausbaurecht** abbilden (Ablauf-Tick auf „nie“). Das ist die kleinste Form von Besitz im Einzelspieler. [Annahme: nicht geprüft, ob andere Stellen einen endlichen Ablauf voraussetzen.] C2 braucht dagegen Firmen als Objekte (Kasse, Kredit, Kurs) und ist die eigentliche Komplexität. |
| #47 Punishment | KI-Übernahmeangebote für schwache Spielerfirmen (`concept/tobias.md` Z. 126) sind Strafe; fair nur, wenn die Schwäche vorher sichtbar ist. Steht schon in `oekonomie.md` §3 („Kurs als Gesundheitsanzeige“, „Schuld ohne Rückmeldung“ nervt). Bestätigt. |
| #16 Risk Mitigation | Größtes Risiko ist nicht die Mechanik, sondern der vierte Aufschub (Jonas-Regel: dritter Aufschub = Entscheidung). Bekannt. Beim Lesen fiel auf: Jonas entscheidet in `zeitreise.md` §7 „gestrichen, bis Konkurrenz existiert“, in `oekonomie.md` „Jonas: Umfang“ dagegen „Stufe 1 bauen in S9“. Beide Dateien vom 03.11.; **die Entscheidung ist widersprüchlich dokumentiert** (Fund durch Lesen, nicht durch die Linse). |
| #39 Meaningful Choices | Wahlziel F4 oder Kauf (G-01 §5) ist schon eine bedeutsame Wahl. Bestätigt. |

**Empfehlung Lena.** Trennen. **C1 Industriekauf** gehört zum Kern (M5b, G-01) und wird in S8 als Spec plus Prototyp „unbefristete Lizenz + Ausbau + Firmenwert“ gebaut, ohne KI. **C2 Übernahme von KI-Firmen** bekommt ein ADR mit Ablaufdatum und kommt erst nach einem Konkurrenz-Prototyp (F9 B). Jonas klärt den Widerspruch zwischen den beiden Referenzdateien in einem Satz.
**Gegenargument.** Basti will Übernahmen (`oekonomie.md` Jonas: „Basti will ihn“), die Fantasie Railroad Tycoon hängt an C2. Wer trennt, riskiert, dass C2 dauerhaft verschoben wird (faktisch gestrichen ohne Entscheid, `resuemee/mt-po.md` §4). Ohne Konkurrenz fehlt C1 der Wettlauf; die Zeitkomponente kommt nur aus dem Stufe-2-Aufschlag.

**Billig testen.**
| Test | Aufwand |
|---|---|
| ADR „Firmenkauf = C1, Übernahme = C2“, Widerspruch Jonas auflösen | 0,25 PT (Jonas) |
| EV-Tabelle Lizenz vs. Kauf über 60 min für 3 Industrietypen (Mühle, Sägewerk, Hütte), Werksmarge vorher festlegen | 0,5 PT (Tobias) |
| Prototyp: Kauf = Lizenz ohne Ablauf + Firmenwert-Anzeige, Basti entscheidet bei M5b laut denkend | 1–1,5 PT (Mira/Felix) [Schätzung, nicht geprüft] + 0,25 PT Test |

---

## Nicht geprüft
- Ob Mehrinput an Industrien Mehroutput erzeugt (relevant für den Wert von Ausstoß-Rängen in Zwischenstufen).
- Einheit der Fahrzeuglebensdauer im Code.
- Werksmarge und damit jeder Erwartungswert Lizenz vs. Kauf.
- Ob `s_lic_until` als „unbefristet“ ohne Nebenwirkungen nutzbar ist.
- Alle Referenzzahlen aus `zeitreise.md`/`fortschritt.md` (Civ VII, EU4, OpenTTD) wurden übernommen, nicht neu geprüft.
