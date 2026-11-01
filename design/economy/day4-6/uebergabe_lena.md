# Übergabe T-05 an Lena für die L-05-Karten (Tobias, 19.11.2026)

Alle Zahlen sind Modellrechnung (`t05_final_modell.py`), Stand nach D1. Nichts ist an Spielern gemessen. Was du auf die Karten druckst, ist eine Testannahme, revidierbar nach L-05 (25.11.).

## 1. Startwerte je Karte (Option A, D1)

| | Agrar | Hafen | Bergbau | Handelsknoten |
|---|---|---|---|---|
| **Startkapital** | **4.500 $** | **4.500 $** | **7.000 $** | **5.000 $** |
| Kaufpreis Rohstoff-Firma | Getreidefarm 1.000 $ | Holzfäller 1.000 $ | Erzmine 1.800 $, Kohlemine 1.200 $ (Annahme) | Viehhof 1.200 $ |
| Kaufpreis Verarbeiter | Mühle 2.000 $ | Sägewerk 2.000 $ | Stahlwerk 4.000 $ | Schlachthof 2.500 $ |
| Lizenz je 30 Spielminuten (im Radius) | 70 / 140 $ | 70 / 140 $ | 126 (Erz) / 84 (Kohle) / 280 $ | 84 / 175 $ |
| Lizenz außerhalb Radius | +3 % je Feld auf den Kaufpreis, kein Radius-Rabatt (12 Felder: Mühle 272 $) | | | |
| Gratis-Lizenz | eine Nicht-Ziel-Firma der Startkette, Laufzeit 30 min | | | |
| Startpaket Straße + Lkw | 1.367 $ (567 + 2 Lkw) | 1.460 $ (660 + 2 Lkw) | 2.280 $ (1.080 + 3 Lkw) | 1.325 $ (525 + 2 Lkw) |
| Lkw | 400 $ Kauf, 90 $/min fix, 0,08 $/Feld, 10 Einheiten, 6 Felder/s | | | |
| Rest nach Direktkauf Verarbeiter + Startpaket | 1.133 $ | 1.040 $ | **720 $** (knappster Fall) | 1.175 $ |
| Rest nach Startpaket + 3 bezahlten Lizenzen | 2.783 $ | 2.690 $ | 4.230 $ | 3.241 $ |
| Einkommen der ersten Kette, Stufe 1 (Modell, ohne Bauzeit) | 844 $/min | 627 $/min | 806 $/min | 399 $/min |

## 2. Regeln, die auf die Karte gehören

1. **Lizenz:** 10 % des Kaufpreises je 30 Spielminuten, im Radius −30 %. Auto-Verlängerung zum gleichen Preis. Beim Kauf werden 50 % aller bisher gezahlten Gebühren dieser Firma angerechnet.
2. **Kaufrabatt −20 % nur einmalig** als Belohnung für Meilenstein 5b auf den nächsten Kauf (D1). Keine Dauerregel. Rechenbeispiel Mühle nach 1 Laufzeit: mit Rabatt 1.530 $ netto (gesamt 1.670 $ = 0,835 × Kaufpreis), ohne Rabatt 1.930 $ netto (1,035 ×).
3. **Kreditrahmen ab Minute 0 (D1), Vorschlag an Felix:** 2.000 $ für alle Archetypen. Zins 1 % je Spielminute auf den gezogenen Betrag (voll gezogen 20 $/min). Sperre: Firmenkauf, Ausbau und HQ-Ausbau nur aus Guthaben, nicht auf Kredit. Straße, Fahrzeuge, Lizenzverlängerung dürfen den Rahmen nutzen. Im Paper-Test: Spielleitung erlaubt bis −2.000 $, streicht 1 %/min, verweigert Kauf im Minus. Details `antwort_felix_kredit.md`.
4. **Werksmarge 15 %** nur für gekaufte Firmen, auf den Transportertrag eigener Fahrzeuge ab Werk (Lesart aus T-05; Widersprüche 9 noch nicht entschieden).
5. **Unterhalt gekaufte Firma:** 20 $/min × Stufe.
6. **Kaufangebot-Gate M5b:** dein Vorschlag „10 Spielminuten profitabel beliefert“ ist für mich in Ordnung, ich habe ihn nicht gerechnet. Es ist deine Setzung, der Paper-Test prüft sie.

## 3. Was die Rechnung für den Test bedeutet

- **Lizenz-Zeitfenster (Kauf lohnt erst ab Minute …, Standardfall Verarbeiter):** Agrar 17, Hafen 22, Bergbau 35, Handel 56 min. Mit KI-Teilung ab Minute 15: 18 / 31 / 61 / >120. Rohstoff-Firmen lohnen nie im Test-Horizont (Agrar, Hafen, Bergbau >120 min; Handel 91 min).
- Folge für das Kriterium „Kaufwunsch vor Minute 25“: In Agrar und Hafen ist er wirtschaftlich begründbar, in Bergbau und Handel misst er den Wunsch, nicht die Wirtschaftlichkeit. Bitte wie bei dir vorgesehen ins Protokoll.
- **„Kapital reicht für 3 Lizenzen“** ist unter A immer erfüllt (350–490 $ von 4.500–7.000 $) und trennt nicht (Katrin E1). Protokollieren, nicht werten.
- **Kauf ab Minute 1 bezahlbar** in allen vier Karten. Das Kapital erzeugt keine Reihenfolge; die Reihenfolge entsteht aus angezeigtem Mehrertrag (Verarbeiter 44–120 $/min) und dem Angebots-Gate. Wenn Tester trotzdem sofort kaufen, ist das ein Befund, kein Fehler im Material.

## 4. Abweichungen zu deiner Datei `hq_startwerte.md`

- **Bergbau mit Kohle:** Startpaket 2.280 statt 1.664 $, dritte Lizenz (Kohlemine 84 $), Einkommen 806 statt 781 $/min. Deine **Untergrenze 6.000 $** hält „Linie voll ab Minute 1“ damit nur noch mit Kreditrahmen (ohne: Minute 6). Vorschlag: Untergrenze 6.500 $ oder Kreditrahmen als feste Regel auf der Karte. Empfehlung 7.000 $ bleibt.
- Rest nach Startpaket + 3 Lizenzen in Kaufpreisen: 1,39 / 1,34 / **1,06** / 1,30 (dein Satz „1,2 bis 1,4“ wird zu „1,1 bis 1,4“).
- Alles andere identisch, weil du meine Setzungen übernommen hast. Das ist keine Bestätigung durch eine zweite Quelle.

## 5. Nicht geliefert

Ausbaupfad Stufe 2–4 (M7, D13: Zahl erst M1), Fahrgäste Handelsknoten, Bauzeit, Lager, Zug. 60-k-Erfahrenenstart und HQ-Ausbau-Skala: M1 (D1).
