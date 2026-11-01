# L-05 Paper-Prototyp HQ-Start: Material final, Pilot, Stand (20.11.2026)

Lena Hoffmann · Ticketstatus: **Material fertig, Pilot gelaufen (zählt nicht), wartet auf echte Durchführung.** Die 3 Runden mit Nicht-Designern können in dieser Umgebung nicht stattfinden (keine Tester, keine zweite Person, kein Raum). Abschnitt 9 sagt, was dafür fehlt.

Zahlenbasis: Tobias' T-05 (`day1-3/tobias/t05_ergebnis.md`, `t05_modell.py`) unter **D1** (Startkapital Option A 4.500 / 4.500 / 7.000 / 5.000 $, Kaufrabatt −20 % nur einmalig als Belohnung M5b, Kreditrahmen ab Minute 0, Lizenzlaufzeit in Spielminuten). `day4-6/tobias/` enthält am 20.11. nur einen leeren Ordner `f09/`, also keine Änderung an T-05 (Annahme: Zahlen vom 18.11. gelten). Die Takt-Tarife habe ich mit Tobias' Modell unverändert unter D1-Kapital gerechnet (Skript `lena/tarif.py`, Aufruf `simulate(arch, "L"/"K0", C=D1, ai=…)`); das ist eine Rechnung, keine Messung.

## 1. Was gemessen wird (G5, D1)

| Kriterium | Messung | Zählt im Gate |
|---|---|---|
| K1 Stadtwahl mit Kette begründet (≥ 2/3) | Wortlaut bei Frage 1; zählt, wenn ≥ 2 Glieder (Rohstoff / Verarbeiter / Abnehmer) als Grund genannt werden | ja (Bericht) |
| K2 Startkapital reicht für 3 Lizenzen (3/3) | Lizenzen bis Ende Takt 1, Feld „Verzicht wegen Geld“ | **nein, nur protokolliert** (G5: trennt nicht) |
| K3 Kaufwunsch vor Minute 25 (≥ 2/3) | Spieler nennt Kauf einer lizenzierten Firma von sich aus vor Ende Takt 5; Feld „vor/nach Angebotskarte“ | **ja, einziger Messwert (M)** |
| K4 Tabelle 1a–3 liegt vor | Abschnitt 7 | ja |

## 2. Rahmen

3 Runden à 30 min, je 1 Spieler (Nicht-Designer, extern bevorzugt), Spielleitung Lena, Protokoll und Stoppuhr zweite Person (Daniel oder Aylin). Tonaufnahme mit Einwilligung (Text: Katrin, B6). Nur Güter, kein Personenverkehr, kein Stadtwachstum. 6 Takte à 5 Spielminuten. Zeit im Takt 1 pausiert, bis das Startpaket steht.

## 3. Stückliste (final)

| Teil | Stück | Inhalt |
|---|---|---|
| Karte A3 | 1 | 4 Städte, Industrien als Symbole mit Namen, Distanzen in Feldern an den Kettenkanten (Abschnitt 4), Einflussradius als Kreisschablone |
| Stadtkarte A6 | 4 | Abschnitt 4 |
| Industriekarte A7 | 13 | Abschnitt 4, Vorderseite frei, Rückseite Zustand (Lizenz gestrichelt / Eigentum voll) |
| Startpaket-Karte | 4 | Straße + 2 Lkw, Preis je Stadt |
| Tarifkarte (Spielleitung) | 4 | Abschnitt 5 |
| Ereigniskarten | 4 | Mitlizenznehmer (Takt 4), Kaufangebot (Takt 4), Lizenzablauf (Takt 6), Kredit (Regelkarte) |
| Meilensteintabelle A4 | 1 | Abschnitt 7, für den Spieler |
| Takt-Leiste | 1 | 6 Felder, Spielminute 0–30 |
| Spielgeld | 60 | 20 × 1.000, 10 × 500, 20 × 100, 10 × 50 (Maximalstand ≈ 24.000 $, Agrar ohne KI) |
| Marker | 1 Satz | HQ, 4 Lkw, 6 Lizenz, 2 Eigentum |
| Beobachtungsbogen | 3 + 1 Pilot | Abschnitt 8 |

## 4. Karten (Texte)

### Stadtkarten (Vorderseite = Startkarte wie `hq.md` Ablauf 1)

| | **Kornfeld** (Agrar) | **Seehafen** (Hafen) | **Erzberg** (Bergbau) | **Flusskreuz** (Handel) |
|---|---|---|---|---|
| Stadt | Dorf, 900 Einw., Flussebene | Kleinstadt, 3.200 Einw., Küste | Kleinstadt, 2.500 Einw., Gebirgsrand | Stadt, 12.000 Einw., Fluss + Kreuzung |
| **Startkapital (D1)** | **4.500 $** | **4.500 $** | **7.000 $** | **5.000 $** |
| Bedarf der Stadt | Nahrung 9 E/min (zu klein, Abnehmer ist Nachbar-Kleinstadt Mühlau, 25 E/min) | Nahrung + Bau | Nahrung + Bau; Stahl erst ab Stadt (Abnehmer: Werkzeugfabrik, 40 E/min) | Nahrung 120 E/min, Bau |
| Bonus | billigster Bau, Getreide + Vieh nah | Export zu Fixpreis ohne Sättigung, Gratis-Lizenz Export | Erz + Kohle nah | größter Markt, Lager −25 % |
| Malus | kaum Fahrgäste | nur 2 Industrien im Radius | Bau +20 % | Bau ×1,5, nur 5.000 $ |
| Industrien im Radius (Lizenz / Kauf) | Getreidefarm 70 / 1.000 · Mühle 140 / 2.000 · Viehhof 84 / 1.200 | Holzfäller 70 / 1.000 · Sägewerk 140 / 2.000 · Export-Lizenz gratis | Erzmine 126 / 1.800 · Kohlemine 126 / 1.800 · Stahlwerk 280 / 4.000 | Viehhof 84 / 1.200 · Schlachthof 175 / 2.500 · Sägewerk 140 / 2.000 |
| Startpaket | 1.367 $ | 1.460 $ | 1.664 $ | 1.325 $ |
| Kettenlängen (Felder) | 18 / 45 | 15 / 40 | 20 / 40 | 20 / 15 |
| Gratis-Lizenz (hq.md) | 1 Lizenz nach Wahl | Export | 1 nach Wahl | 1 nach Wahl |

Lizenz: 10 % des Kaufpreises, im Radius −30 %, Laufzeit 30 Spielminuten, 50 % der gezahlten Gebühren werden beim Kauf angerechnet. Alle Preise aus T-05 (Tobias' Setzung der Kaufpreisbasis).

### Industriekarten (13)

Getreidefarm, Mühle, Viehhof (Kornfeld) · Holzfäller, Sägewerk, Hafen-Export (Seehafen) · Erzmine, Kohlemine, Stahlwerk, Werkzeugfabrik (Erzberg, Werkzeugfabrik nur Abnehmer) · Viehhof, Schlachthof, Sägewerk (Flusskreuz). Je Karte: Name, Stufe 1 (20 E/min), Lizenz / 30 min, Kaufpreis, Zustand. **Kohlemine:** „Liefert Kohle ans Stahlwerk. Im Papier ohne eigenen Ertrag.“ (Widerspruch 11 offen; wer fragt, wird als Verwirrung notiert.)

### Regel- und Ereigniskarten

| Karte | Wann | Text |
|---|---|---|
| Kredit (D1) | liegt ab Start offen | „Kreditrahmen 1.000 $ ab Minute 0, im Test ohne Zinsen.“ (Setzung; Modell: ≥ 1 Lkw = 400 $) |
| Mitlizenznehmer | Beginn Takt 4 | „Ein anderer Spediteur hat Lizenzen auf eure lizenzierten Firmen. Ihr teilt euch den Zugriff. Tarif ab jetzt: Zeile ‚geteilt‘.“ |
| Kaufangebot (M5b-Gate, Setzung: 10 Spielminuten profitabel beliefert = Takt 2 + 3) | Beginn Takt 4, nach Mitlizenznehmer | „Ihr könnt den Verarbeiter kaufen: Preis X abzüglich Anrechnung Y. Eigentum: exklusiv, Werksmarge, Tarifzeile ‚Besitz‘. Kein Rabatt beim ersten Kauf; Belohnung M5b: −20 % auf den nächsten.“ |
| Lizenzablauf | Beginn Takt 6 | „Eure Lizenzen aus Takt 1 laufen nach diesem Takt ab. Verlängern (gleicher Preis) oder kaufen.“ Verlängerung wird am Ende von Takt 6 bezahlt. |

## 5. Tarifkarten (Spielleitung), netto je Takt (5 Spielminuten), in 50-$-Schritten gerundet

Rechnung mit Tobias' Modell unter D1, Strategie L (3 Lizenzen), Takt 1 = Bau ohne Ertrag. „geteilt“ = KI hält ab Minute 15 Lizenzen auf beiden Firmen und 40 % Marktanteil (Tobias' Annahme); „Besitz“ = Verarbeiter gekauft, Rohstoff lizenziert, KI aktiv. Vor Lizenzgebühren.

| Stadt | Netto / min (allein) | **Takt allein** | Netto / min geteilt | **Takt geteilt** | Netto / min Besitz V | **Takt Besitz** | Mehrertrag Besitz je Takt |
|---|---|---|---|---|---|---|---|
| Kornfeld | 844 $ | **4.200 $** | 332 $ | **1.650 $** | 379 $ | **1.900 $** | +250 $ |
| Seehafen | 627 $ | **3.150 $** | 224 $ | **1.100 $** | 258 $ | **1.300 $** | +200 $ |
| Erzberg | 781 $ | **3.900 $** | 300 $ | **1.500 $** | 340 $ | **1.700 $** | +200 $ |
| Flusskreuz | 399 $ | **2.000 $** | 109 $ | **550 $** | 119 $ | **600 $** | +50 $ |

**Kontostände, die der Bogen erwarten darf** (Strategie L, ohne Kauf): Ende Takt 1 nach Startpaket + 2–3 Lizenzen: Kornfeld 2.783, Seehafen 2.830 (nur 2 bezahlte Lizenzen), Erzberg 4.650, Flusskreuz 3.241 $. Ende Takt 3: + 2 × Takt allein. Danach Takt geteilt. Abweichung des Papiers vom Modell durch Rundung < 1 %.

**Befund aus der Rechnung, der im Protokoll steht:** Der Kauf (1.930–3.860 $ nach Anrechnung) bringt im Papier nur +50 bis +250 $ je Takt. In den 2–3 Takten nach dem Angebot zahlt er sich nie aus. K3 misst also den Wunsch nach Exklusivität und Besitz, nicht eine Rechnung. Das ist mit Tobias' Befund („Kaufwunsch entsteht nicht durch Kapital“) deckungsgleich und steht im Bericht.

## 6. Ablauf (30 min real)

| Min | Schritt | Spielleitung |
|---|---|---|
| 0–3 | Einführung | „Du gründest ein Verkehrsunternehmen. Wähle eine Stadt als Hauptsitz. Sprich laut, was du denkst.“ Karten erklären, nichts über Ketten oder Leiter sagen. |
| 3–8 | Karte erkunden, bis 3 Städte pinnen (Zeit pausiert) | **Frage 1:** „Welche Stadt wählst du, und warum?“ (K1) |
| 8–13 | Takt 1: HQ setzen (1a), Lizenzen (1b), Startpaket | HQ kostenlos. Gratis-Lizenz erklären. Spieler zahlt Lizenzen und Startpaket. Kein Ertrag. Kreditkarte liegt offen. |
| 13–25 | Takt 2–6, je ≈ 2 min | Ertrag laut Tarif auszahlen. Takt 4: Mitlizenznehmer, dann Kaufangebot. Takt 6: Lizenzablauf, Verlängerung oder Kauf am Taktende bezahlen. Beobachter notiert jede Kauf-Äußerung mit Takt, Minute, vor/nach Karte. |
| 25–30 | Interview | (1) Wofür war das Startkapital da? (2) Warum Lizenz oder Kauf, was kostet mehr? (3) Was war unklar? (4) Welche Stadt als Nächstes, warum? (5) Was würdest du bauen, wenn du weiterspielen könntest? |

Neutrale Zwischenfragen, nur diese: „Was denkst du gerade?“ · „Was möchtest du als Nächstes tun?“

## 7. Tabelle Meilensteine 1a–3 (K4), nach D13

| # | Meilenstein | Auslöser | Lernziel | Belohnung | Zielzeit ab HQ (Setzung) |
|---|---|---|---|---|---|
| 1a | HQ gründen | HQ-Marker gesetzt | Stadt legt Startbedingungen und Radius fest | Radius und Lizenzpreise sichtbar | 0 |
| 1b | Erste Lizenz | Lizenz gekauft oder Gratis gesetzt | Laden nur mit Lizenz oder Besitz, Lizenz kostet Laufzeit | +1 Skillpunkt | ≤ 2 min |
| 2 | Lkw-Linie zum Verarbeiter | 1 Lieferung Rohstoff → Verarbeiter | Straße, Linie, Fahrzeug | +1 Skillpunkt Straße | Agrar 4 · Hafen 6 · Bergbau 8 · Handel 6 |
| 3 | **Endprodukt an Abnehmer geliefert (Stadt, Export oder nächste Stufe)** (D13) | 1 Lieferung des Verarbeiterprodukts, Kette nach Fixkosten im Plus | Ertrag nur bei Abgabe an einen Endabnehmer | Stadt-Infopanel | Agrar 6 · Hafen 8 · Bergbau 10 · Handel 8 |

Zielzeiten sind Setzungen; das Papier prüft Reihenfolge und Verständnis, keine Zeit.

## 8. Beobachtungsbogen (ein Blatt je Runde)

Kopf: Runde, Datum, Tester-Code, Gruppe (spielt Tycoon-Genre j/n), Spielleitung, Beobachter, Pilot j/n.

| Feld | Eintrag |
|---|---|
| Gepinnte Städte | 1–3 Namen, Reihenfolge |
| Gewählte Stadt | Name |
| Wortlaut Begründung (K1) | Zitat |
| Glieder genannt | R / V / A ankreuzen; K1 erfüllt j/n |
| Lizenzen Takt 1 | Anzahl, welche, Gratis-Lizenz wohin |
| Verzicht wegen Geld (K2) | j/n, Wortlaut, Takt |
| Kredit genutzt | j/n, Betrag |
| Kontostand Ende Takt 1–6 | 6 Zahlen |
| Erste Kauf-Äußerung (K3) | Takt, Spielminute, **vor / nach Mitlizenznehmer / nach Kaufangebot**, Wortlaut |
| Kauf ausgeführt | j/n, Takt, Preis |
| Reaktion auf Lizenzablauf | verlängert / gekauft / nichts, Wortlaut |
| Verwirrung | Stelle, Wortlaut (z. B. Kohlemine, Anrechnung, Gratis-Lizenz) |
| Zeit je Phase | Einführung / Wahl / Takt 1 / Takte 2–6 / Interview, in min |
| Interview 1–5 | Stichworte |
| Urteil je Kriterium | K1 j/n, K2 j/n, K3 j/n, je mit Beleg |

## 9. Pilot (20.11., Lena allein, **zählt nicht**)

Form: Trockenlauf am Tisch, ich als Spielerin und Spielleitung zugleich, Kontostände mit dem Tarif der Karten gerechnet, keine Stoppuhr (Zeiten je Phase nicht messbar, weil niemand moderiert hat). Ergebnisse sind keine Messwerte, nur Materialprüfung.

**Verlauf:** Gepinnt Seehafen, Kornfeld, Erzberg. Gewählt Seehafen, Begründung „Holz, Sägewerk und Export, Export sättigt nicht“ (ich kenne das Konzept, K1 nicht wertbar). Takt 1: Holzfäller 70, Sägewerk 140, Gratis-Export, Startpaket 1.460 → Rest 2.830 $. Takt 2, 3: je 3.150 → 9.130 $. Takt 4: Mitlizenznehmer, Kaufangebot Sägewerk 2.000 − 70 Anrechnung = 1.930 $; Tarif geteilt 1.100. Takt 5: 11.330 $ ohne Kauf. Takt 6: Lizenzablauf, Verlängerung 210 $. Ende: 12.220 $ ohne Kauf; mit Kauf in Takt 4: 9.130 − 1.930 + 3 × 1.300 − 70 (nur Holzfäller verlängert) = 11.030 $. Der Kauf kostet im Lauf also 1.190 $ netto, der Besitz zahlt ihn erst nach rund 10 Takten zurück. Kauf-Äußerung bei mir nach dem Angebot (nicht wertbar).

**Korrekturen am Material aus dem Pilot (eingearbeitet in Abschnitt 3–8):**
1. **Seehafen hat nur 2 Industrien im Radius.** „3 Lizenzen“ ist dort nur mit der Gratis-Export-Lizenz erreichbar. Regel: die Gratis-Lizenz zählt als dritte; K2 wird protokolliert, zählt ohnehin nicht (G5).
2. **Lizenzablauf lag im Plan in Takt 5.** Lizenzen aus Takt 1 (Spielminute 0–5) laufen 30 Spielminuten, also nach Takt 6. Karte auf Takt 6 verschoben, Verlängerung am Taktende bezahlt. Sonst hätte das Papier den Ablauf 5 Minuten zu früh erzwungen.
3. **Die Ereigniskarte „Mitlizenznehmer“ nannte 60 % für die Verarbeiterstrecke.** Tobias' Modell halbiert den Zugriff auf beide lizenzierten Firmen und sättigt den Markt mit 40 % KI-Anteil; das ergibt 26–39 % des Tarifs, nicht 60 %. Tarifzeilen „geteilt“ und „Besitz“ neu aus dem Modell gerechnet (Abschnitt 5).
4. **Kaufangebot ohne Nutzenangabe** wäre eine Preisfrage. Karte nennt jetzt Exklusivität und die Tarifzeile „Besitz“, nicht aber den Firmenwert (das wäre ein Schubs).
5. **Kreditkarte** fehlte (D1). Ergänzt; im Pilot nicht gebraucht (Rest nach Takt 1 ≥ 2.690 $ in allen vier Städten).
6. Chips: 60 reichen (Höchststand 24.000 $); Stückelung in Abschnitt 3 festgelegt.
7. Beobachtungsbogen: Feld „vor / nach Mitlizenznehmer / nach Kaufangebot“ dreistufig statt zweistufig, sonst ist nicht trennbar, ob die Konkurrenz oder das Angebot den Wunsch auslöst.

**Nicht geprüft im Pilot:** ob 2 min je Takt mit einem fremden Spieler reichen; ob die Einführung ohne Kettenhinweis auskommt; ob die Kohlemine verwirrt. Das kann nur eine echte Runde zeigen.

## 10. Was für die echte Durchführung fehlt (Stand 20.11.)

| Bedarf | Wer | Stand |
|---|---|---|
| 3 Nicht-Designer, extern bevorzugt (Kollegen kennen das Konzept), je 45 min inkl. Einweisung | Katrin (B5, Frist 19.11., 18:00) | **nicht belegt**, keine `day4-6/katrin.md` |
| Zweite Person für Protokoll und Stoppuhr | Daniel oder Aylin | nicht zugesagt |
| Raum, 3 Slots, realistisch 23.–24.11. (Katrins Daily Tag 3) | Katrin | offen |
| Einwilligungstext Ton | Katrin (B6) | offen |
| Druck: A3-Karte, 4 Stadtkarten, 13 Industriekarten, 4 Startpaket, 4 Tarif, 4 Ereignis, Takt-Leiste, 4 Bögen | Lena, 0,25 T | Texte fertig (diese Datei), Layout nicht gesetzt |
| Spielgeld, Marker, Schablone | Lena | nicht besorgt |
| Ergebnis vor 25.11., damit D1 („revidierbar nach L-05“) noch im Sprint entschieden werden kann | Jonas | hängt an den Testern |

**Ticket L-05: „wartet auf echte Durchführung“.** Ohne Tester bis 23.11. ist G5 am 27.11. nur mit der Rechnung (R, 4/4) belegbar und der M-Teil (Kaufwunsch) fehlt. Nach D8 ist ein fehlender Messwert in G1–G5 ein Vertagungsgrund; das sage ich im Daily 20.11., nicht erst am 23.11.
