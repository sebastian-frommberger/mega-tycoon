# Position DESIGN (Lena Hoffmann, Tobias Brandt, Stadt-/Level-Design; Scope-Blick Jonas), Refinement S8

Stand 04.11.2026. Repo nur gelesen. Pfade relativ zu `/home/claude/mega-tycoon/`. Marken: [M] im Code/Repo nachgesehen, [R] aus Repo-Zahlen gerechnet, [E] Einzelschätzung. Alle Minuten- und Geldwerte zum Loop sind Überschläge [R], **nichts ist in Godot gelaufen**. Rahmen nach Scope-Änderung vom 04.11. 00:27: **15 Arbeitstage, 12 T je Person**, Firmenkauf und Skilltree laufen parallel zum Loop.

## 0 Kurzposition
1. Der Loop trägt 45 min nur, wenn **die Mühle der Engpass wird**. Heute deckelt sie hart auf 20 E/min (`economy.gd` Z. 450, nur Stufe 1, kein Ausbau im Code [M]). Eine zweite Farm bringt ohne Mühlen-Ausbau nichts. Der Ausbau kommt am billigsten über **Firmenkauf C1 (Mühle kaufen, Stufe 2)**. Damit hängt der parallele Firmenkauf-Strang direkt am Loop, und das ist gut so.
2. Das Tempo k ist **kein reiner Ausgleichsregler, sondern der Anti-Exploit-Hebel**. Bei 150 m/s ist die Fahrzeit gegen 200 Ticks Laden fast null, deshalb wächst der Ertrag je Fuhrwerk linear mit der Luftlinie. Bei k = 8 kippt das (Rechnung §2.3). Einen vollen Ertragsausgleich ×k lehnen wir ab, weil er den Exploit zurückholt. Ebenso lehnen wir „Bedarf ÷ k“ aus dem Entwurf ab (§2.4).
3. Der Lebenszyklus der Fuhrwerke ist **nur mit Zwei Uhren (3 min/Jahr) sichtbar**. Bei 12 min/Jahr altert ein Fuhrwerk in 45 min nur 3,75 Jahre, und es erscheint kein Folgemodell.
4. Mit 15 Tagen passen Loop, C1-Firmenkauf und Skilltree v1 (2 Äste, 6 Knoten). **C2 (bankrotte Rivalenfirma) passt nicht** und kommt nur als Spezifikation und ADR in S8, gebaut wird sie in S9. Den Stichweg P3 setzen wir aus Designsicht auf Stretch, weil Basti Straßenbau nicht verlangt hat und alle Betriebe bereits am Netz liegen.

## Kandidaten (Urteil der Gruppe)
| ID | Urteil | Begründung kurz |
|---|---|---|
| Z1 Ziele + F1/F2 | **rein** | Kern gegen das Plateau. Schwellen kommen aus dem Bot, nicht aus Gefühl (Muster „Platzhalter für Tobias“, Zähler 3) |
| E1 Fixkosten/Kredit/Bankrott in ProtoSim | **rein** | `credit.gd` ist schon ein eigenes Modul (`setup(eco)`, Z. 1–40) [M]. Die Laufkosten in `main.gd` umfassen ~10 Zeilen (Z. 3110–3147) [M], das Risiko ist also kleiner als im Entwurf angenommen |
| E3/T2 Tempo + Kalibrierung | **rein, neu zugeschnitten** (§2) | ohne Ausgleich ×k |
| F2/F3/F4/F5 Lebenszyklus | **rein**: Kauf, Alterung, Ersetzen, Folgemodell; **raus**: Depot, Ausfall | Basti fragt ausdrücklich nach Folgemodellen |
| W4 Welt-Inhalt | **rein, größer als im Entwurf** | braucht Code in ProtoSim, nicht nur Daten (§5) |
| F-22 C1 Industrie kaufen | **rein (parallel)** | Loop-Schritt „Mühle ausbauen“ |
| F-22 C2 Rivale pleite | **Spec in S8, Bau S9** | Besitzerfeld fehlt, Rivale fehlt; 4–6 PT laut `referenzen/oekonomie.md` Z. 83 |
| SK-02 v1 | **rein, klein** (6 Knoten) | Punkte aus den Loop-Zielen |
| D7 Eigenversorgung | **nicht in S8**; Platzhalter Kulisse (Stretch) + Datenfeld 0 | §6 |
| P3 Stichweg | **Stretch** (Design-Sicht) | §7 |

---

## 1 Loop-Ziele für 45 min ohne Plateau

### 1.1 Ziele mit Messgröße (alle aus ProtoSim-Feldern ablesbar)
| # | Ziel | Messgröße (Datenquelle) | Bot-Messpunkt |
|---|---|---|---|
| E-1 | Erste Lizenz: Gut Kuppenhof | `s_lic_until[farm] > tick` (`economy.gd` Z. 509) | Tick der Lizenz |
| E-2 | Linie Farm → Mühle mit Fuhrwerk | Fahrzeug mit `src_k` Farm, `dst_k` Mühle existiert | Tick |
| E-3 | Erste Getreidelieferung an die Mühle | `lieferungen` mit Gut `getreide` an der Mühlen-Site ≥ 1 (`proto_sim.gd` Z. 437) | Tick |
| E-4 | Mehl nach Erlenbach | ≥ 10 E `mehl` an Erlenbach geliefert | Tick |
| E-5 | Zweites Fuhrwerk auf einer Linie | ≥ 2 Fahrzeuge mit gleichem Quell-/Ziel-Paar | Tick |
| E-6 | Linie trägt sich | Liniengewinn (Ertrag − Fahr- − Fixkosten) > 0 über 3 Perioden am Stück | Tick |
| **F1** | Zweiter Ort versorgt | Versorgungsgrad V = geliefert Nahrung / Nachfrage, gemittelt über 3 Perioden, **≥ 500 ‰ in Erlenbach und Lindenfurt** | Minute erfüllt (P25/50/75) |
| **F2** | Gewinn tragfähig | Netto €/min (alle Einnahmen − alle Ausgaben inkl. Zins) **≥ X über 5 Perioden, Kredit = 0**. X = gerundeter P50 des Plan-Bots zu Minute 30 × 0,8. Startwert [R]: 600 $/min bei k = 6. Die 1.000 $/min aus G-01 sind mit einer Mühle auf Stufe 1 nicht erreichbar (§2.2) | Minute erfüllt |
| F3 (Stretch) | Ort wächst durch dich | Stufen-Tor (Wachstum Variante B), Code fehlt | – |

### 1.2 Leerlauf-Regel, operationalisiert
**Entscheidungsereignis** = ein Zustand, der dem Spieler sichtbar ≥ 2 Handlungen mit unterschiedlichem Preis anbietet. Katalog (8 Typen, jeder vom Bot zählbar):
1. Ziel erfüllt, nächstes Ziel mit Preis („Nächster Schritt“).
2. Sättigungswarnung an einem Ort (V > 1.200 ‰). Wahl: zweiter Abnehmer oder Fahrzeug abziehen.
3. „Fuhrwerk wartet auf Ladung“ > 1 Periode. Wahl: Fahrzeug abziehen oder Quelle erweitern.
4. Kasse ≥ Preis des günstigsten sinnvollen Kaufs (Fuhrwerk, Lizenz, Kauf) zum ersten Mal.
5. Kredit frei (Tick 7.200 = Minute 12).
6. Lizenzablauf in ≤ 3 min (Laufzeit 18.000 Ticks = 30 min, `economy_constants.json lizenz`) [M].
7. Mühle am Durchsatzdeckel (Eingangspuffer voll > 2 Perioden). Wahl: kaufen und ausbauen (C1) oder Getreide umleiten.
8. Fuhrwerk erreicht Alterungsschwelle (Unterhalt ≥ +40 %) oder Folgemodell verfügbar. Wahl: ersetzen oder weiterfahren.

**Regel:** Beim Plan-Bot liegt im P90 aller Läufe zwischen zwei Ereignissen ≤ 3 min, von Minute 2 bis 45. Für Menschen gilt: Interessenkurve alle 5 min (1–5) auf Bastis Karte L3, kein Abschnitt ≤ 2 über 10 min.

### 1.3 Entscheidungsfahrplan (welche Entscheidung sieht der Spieler wann)
Annahmen: k = 6, Kalender 3 min/Jahr, EW wie in §5 vorgeschlagen. Alle Minuten [R], sie werden vom Bot ersetzt.

| Minute | Lage | Entscheidung (Optionen) |
|---|---|---|
| 0–3 | 6.000 $, HQ Erlenbach | Welche Farm lizenzieren? Kuppenhof (17 Felder zur Mühle, gratis) oder Farm 2 (weiter, teurer) |
| 3–6 | Getreide kommt an | Mehl nach Erlenbach (15 Felder, kurz, wenig Ertrag) oder gleich Lindenfurt (72 Felder, mehr Ertrag, 3–4× so viele Fuhrwerke) |
| 6–10 | Fuhrwerk wartet oder Lager voll | 2. bzw. 3. Fuhrwerk auf die richtige Linie (Ereignis 3/4) |
| 10–14 | Erlenbach gesättigt (Mühle 20 E/min gegen Nachfrage 10 E/min = 200 %) | Lindenfurt anbinden (→ F1) oder Fuhrwerk abziehen. Ab Minute 12 Kredit |
| 14–20 | Mühle am Deckel 20 E/min | **Mühle kaufen und ausbauen (C1, ca. 2.000 $ + Kauf)**, mit oder ohne Kredit. Erst dann lohnt sich Farm 2 |
| 20–30 | Farm 2 + Ausbau laufen | Skillpunkt aus F1 setzen. Lizenz Kuppenhof läuft bei Minute 30 ab: verlängern oder kaufen |
| 24–33 | Kalender 1828–1831, Unterhalt der ersten Fuhrwerke +40 % | **Frachtwagen ab 1830**: ersetzen (Restwert) oder alt weiterfahren |
| 30–40 | F2 in Reichweite, Kredit offen | Kredit tilgen (F2 verlangt Kredit = 0) oder weiter investieren |
| 40–45 | Sättigung Lindenfurt | Feinschliff, Linien umlegen, 2. Skillpunkt aus F2. (C2-Rivale wäre hier das Fernziel, S9) |

**Wichtig:** Gleis gibt es laut W1-Regel ab 1835 (`gleis_ab_jahr`). Bei 3 min/Jahr ist das Minute 45. In S8 muss Gleis in der Welt deshalb **gesperrt bleiben**, sonst taucht am Ende des Loops eine Freischaltung auf, die ins Leere läuft.

### Tickets Punkt 1
| ID | Ticket | Owner T | Akzeptanz messbar | Folge/Abhängigkeit | Marke |
|---|---|---|---|---|---|
| Z1a | Ziel-Spezifikation E-1–E-6, F1, F2 + Ereigniskatalog 1–8 + Fahrplan als Daten (`ziele_welt.json`) | Lena 1,5, Tobias 0,25 | Jedes Ziel nennt Feld, Schwelle und Bot-Messpunkt. 8 Ereignistypen mit Auslöserformel. Daniel prüft: 0 Ziele ohne Messgröße | Grundlage für Z1b, Q2 | [E] |
| Z1b | Ziele + „Nächster Schritt“ in der Welt (Bau) | Mira 1,5, Lena 0,5 | Je Ziel ein Test „hakt nur bei Messgröße“ (Lehre „Ziel hakt falsch“). Ziel 6 hakt nicht, solange eine Linie Verlust macht | hängt an E1, P1/U2 | [R] Entwurf Z1 1,5–2 |
| Q2 | Loop-Bot headless auf ProtoSim mit 3 Strategien (naiv/gierig/plan), Ereigniszähler, n = 300 je Variante, Wilson-Intervall | Tobias 2, Felix 0,5 | CSV je Lauf: Bankrott j/n + Minute, Minute E-1…F2, größte Ereignislücke. Lauf ≤ 10 min headless (schnelle Stufe nur n = 30) | hängt an E1, W4b; Grundlage für E3a/E3b | [E] |
| Z1c | F2-Schwelle aus Bot setzen | Tobias 0,25 | X = P50(Plan, Min 30) × 0,8, im JSON mit Messdatum | hängt an Q2, D2 | [R] |

**Risiko:** Der Bot ist ein Proxy (Goodhart, `resuemee/mt-po.md` §5). Der Plan-Bot spielt den Fahrplan nach, den wir selbst geschrieben haben. **Testweg:** Bot plus Bastis Interessenkurve (L3). Weichen sie ab, gilt Basti.

---

## 2 Ökonomie auf der Welt

### 2.1 Ist-Stand, im Code geprüft
- ProtoSim bucht nur variable Fahrkosten (`proto_sim.gd` Z. 431–434) [M]. Fixkosten, Zins und Bankrott fehlen. Die Postkutsche fährt leer und kostet nur variabel (Z. 416) [M].
- **Fahrzeugtempo in ProtoSim kommt nicht aus `vehicles.json`**, sondern aus `regelwerk.json fahrzeug_easing.kategorien.<kat>.sim_felder_je_tick_promille` (`proto_easing.gd` Z. 64, `proto_sim.gd` Z. 306) [M]. Kosten und Kapazität kommen aus `lkw_e1` (`_lkw()`, Z. 321–330) [M].
- Ertrag = Einheiten × Preis × D_eff(Luftlinie Ursprung → Endabnehmer) × F_zeit × F_sätt (`economy.gd` Z. 11, 335–364) [M]. Getreide wird schon **an der Mühle** vergütet (Endabnehmer Verarbeiter, Z. 772–785) [M].
- Lizenzverlängerung kostet den **gleichen Preis** (`_renew_licences` Z. 602–623) [M]. Den Zuschlag von +10 % aus G-01 gibt es nicht.
- Bankrott tritt im Slice bei Kasse < 0 sofort ein (`main.gd` Z. 3146) [M]. Ein Zwangsverkauf ist nicht implementiert: 0 Treffer für `forced_sale|zwangs` in `main.gd`, `credit.gd`, `economy.gd`, und `credit_forced_sale_active_flag` steht auf false [M]. Tobias' Resümee §1 („nach 10 Minuten zwangsverkauft“) trifft also nicht zu.
- Lizenzpreise in der Welt sind klein: Farm 70 $ (erste gratis), Mühle 140 $, weil HQ Erlenbach im Radius 55 Felder liegt (`_licence_cost` Z. 514) [R]. **Die Lizenz ist im Loop heute keine Entscheidung.**

### 2.2 Was 6.000 $ und eine Mühle hergeben (Überschlag [R])
- Angebotsgrenze: Farm 20 E/min, Mühle 20 E/min (`economy_slice.json industrien`, `fabrik`). Brutto bei voller Abnahme: Getreide 20 × 0,28 × 17 ≈ 95 $/min. Mehl nach Erlenbach (15 Felder) ≈ 210 $/min, nach Lindenfurt (72 Felder, D_eff 66) ≈ 924 $/min.
- **Mit einer Mühle liegt das Bruttomaximum bei ≈ 1.000 $/min, und zwar unabhängig von k.** G-01 F2 „Netto ≥ 1.000 $/min“ ist damit unerreichbar. Erst mit Mühlen-Ausbau auf 40 E/min und Farm 2 kommen ≈ 1.400 $/min brutto zusammen, netto je nach k ≈ 440 (k = 8) bis 860 $/min (k = 4) mit den heutigen Kosten von `lkw_e1`.
- 6.000 $ reichen bei k = 8 für ≈ 5 Fuhrwerke der ersten Kette (1.500–2.000 $). Der Rest ist Polster, der Kredit ab Minute 12 hätte dann keinen Grund. **Startkapital im Bot variieren: 3.000 / 4.500 / 6.000 $.** 6.000 $ bleibt nur, wenn beim Plan-Bot der Kassentiefpunkt zwischen Minute 5 und 20 unter 2.000 $ fällt. D22 (6.000 $ für alle) wurde auf dem Slice kalibriert und gilt hier nicht automatisch.

### 2.3 Entfernungs-Exploit: Rechnung und Prüfung
Kosten je Einheit und Feld Luftlinie (Hin + Rück): **s = (Fix/Tick × 2/v + 2 × var) / Kap**, v in Feldern/Tick. Mit `lkw_e1` (Fix 15 ¢/Tick, var 8 ¢, Kap 10) [R]:

| k | v (Felder/Tick) | s (¢/E/Feld) | Mehl 70 ¢ unter / über Knick (35 ¢) | Getreide 28 ¢ unter / über (14 ¢) |
|---|---|---|---|---|
| 1 (heute) | 0,6 | 6,6 | +63 / +28 → **weiter ist immer besser** | +21 / +7 |
| 4 | 0,15 | 21,6 | +48 / +13 → jenseits des Knicks noch positiv | +6 / −8 |
| 8 | 0,075 | 41,6 | +28 / −7 → **Optimum am Knick** | −14 / −28 → Getreide-Linie verliert |

Dazu kommt F_zeit: Für Mehl gilt eine Frist von 600 Ticks (`zeitfaktor fresh_grace_ticks`). Bei k = 1 sind das 9 km Fahrt, die Frist greift also nie. Bei k = 8 reicht sie für ≈ 1,1 km, Lindenfurt bekommt dann ≈ F_zeit 0,73 [R]. **Die Frist darf deshalb nicht mit k skaliert werden**, sonst ist sie wieder wirkungslos.

**Designregel (messbar):** Je Gut liegt das Netto je Einheit am Maximum zwischen 40 und 80 Feldern (1–2 km). Bei 150 Feldern liegt es bei ≤ 80 % des Maximums. Jedes Gut ist zwischen 15 und 40 Feldern ≥ 0. Daraus folgt für die Konstanten: 0,5 × c_Mehl < s < 0,9 × c_Mehl und s ≤ c_Getreide. Mit einem Fahrzeugtyp ist das nur erfüllbar, wenn Getreide relativ teurer wird (Preisverhältnis heute 2,5 : 1) oder Fix sinkt. Das ist Tobias' Kalibrierarbeit.

**Prüfung im Bot (X1–X3, Teil von E3a):**
- X1 Distanz-Sweep: synthetische gerade Strecke mit `testlinie()` (`proto_sim.gd` Z. 342), d ∈ {10, 20, 40, 60, 80, 100, 150} Felder, Mehl und Getreide, ohne Sättigung, Flottengröße optimal. Ausgabe: Netto je Einheit und je Fuhrwerk-Minute.
- X2 Umweg: Pfad/Luftlinie 1,0 gegen 1,6 → Netto sinkt um ≥ 20 %.
- X3 Weltkarte: Wählt der Plan-Bot Lindenfurt, dann nur wegen Sättigung, nicht weil die weite Fahrt immer gewinnt (Gegenprobe: Erlenbach-Nachfrage auf 999 setzen, dann darf Lindenfurt nicht dominieren).

**Konstanten, die sich ändern können:** `sim_felder_je_tick_promille` (fuhrwerk, regelwerk), Preise Getreide/Mehl, `fix_cent_pro_periode`, `variabel_cent_pro_feld`, `kapazitaet_einheiten`, `dist_slope_beyond_promille` (500 → 250 als Kandidat), `dist_knee_felder` 60 (nur wenn X1 rot), `load_ticks` 100, `startkapital_cent`, Kreditrahmen. **Nicht ändern:** `fresh_grace/decay_ticks`, Nachfrage je 100 EW.

### 2.4 Kalibrierung nach Tempo-Änderung (k = 4–8): wie genau
- **Abgelehnt: Ertrag ×k mit Bedarf ÷k (Entwurf T2/§2.2).** Bedarf ÷k lässt die Sättigung k-mal früher greifen, während die Produktion gleich bleibt. Das ergibt Überangebot und Einbruch statt Ausgleich. Ein voller Ertrag ×k stellt außerdem das Verhältnis c/s von k = 1 wieder her, und damit den Exploit.
- **Vorschlag:** Nachfrage, Produktion und Fristen bleiben. Zwei Regler, zwei Bedingungen. Ein globaler Ertragsfaktor `ertrag.tempo_ausgleich_promille` = a (Startwert 1.000) wird per Bisektion so gesetzt, dass der P50 des Plan-Bots zu Minute 30 netto im Zielband liegt (Ziel: F2 bei Minute 25 ± 5). Danach wird Fix/Kap des Fuhrwerks so gesetzt, dass die Designregel aus §2.3 mit Preis × a hält. Als erste Prüfung reichen 2 k-Werte (4, 8) × 3 Varianten × n = 300.
- **„€/min kippt nicht“, messbar:** Netto-€/min P50 (Plan, Min 30) bei k = 4 und k = 8 nach Kalibrierung ± 15 % gleich. Bankrott-Band hält in beiden.

### 2.5 Bankrott-Zielband (Welt)
Naiv-Bot 10–30 % (S7-Band), Plan-Bot ≤ 5 %, jeweils mit Wilson-Intervall, n = 300. Vorwarnung 90 s bleibt (U-03). Der Zwangsverkauf bleibt aus, er ist nicht im Code (§2.1).

### 2.6 Sättigung sichtbar
Am Ort und in der Linienliste ab V > 1.000 ‰ gelb („gesättigt, +x $/min nur mit neuem Abnehmer“), ab 1.500 ‰ rot (Kante 0,4 → 0,1, `economy.gd` Z. 353). x = Ertrag dieser Linie bei V = 1.000 minus Ist, gerechnet mit derselben Funktion (Retro S7: Spiel und Anzeige rechnen dieselbe Regel). UI-Owner ist Aylin/Mira, hier steht nur die Formel.

### Tickets Punkt 2
| ID | Ticket | Owner T | Akzeptanz messbar | Folge/Abhängigkeit | Marke |
|---|---|---|---|---|---|
| E1 | ProtoSim: Fixkosten je Fahrzeug/Periode (Logik `_recompute_running_cost`), Kredit über `credit.gd`, Bankrott Kasse < 0, Lizenzkauf per Aufruf | Felix 1,5, Tobias 0,5 (Spec + Gegenprobe) | Paritätstest: identische Kette auf Slice-Logik und ProtoSim ergibt gleiche Kasse ± 0 ¢ über 6.000 Ticks. `proto_sim_test` 11/11 bleibt grün | Grundlage für Q2, Z1b, F-22 | [R] Entwurf 2–3, wegen `credit.gd` eher unteres Ende |
| E3a | Tempo-Kalibrierung: X1–X3, Faktor a, Fix/Kap Fuhrwerk | Tobias 2 | Designregel §2.3 grün für Mehl und Getreide. Netto P50 ± 15 % zwischen k = 4 und 8 | hängt an D2, Q2, F3 | [E] |
| E3b | Bankrott-Band + Startkapital-Variation auf der Welt | Tobias 1,5 | Naiv 10–30 %, Plan ≤ 5 % (n = 300, Wilson). Startkapital-Entscheid mit Tiefpunkt-Kriterium §2.2 | hängt an E3a | [R] Entwurf 1,5–2 |
| E2s | Sättigungsformel für die Anzeige (x $/min) als Funktion in `economy.gd`, mit Test | Tobias 0,25 (+ Mira/Aylin UI im UX-Beitrag) | Anzeige = Formelwert, Test gegen 3 Sättigungsstufen | U4/U5 | [E] |
| E6 | Lizenz im Loop zur Entscheidung machen: Verlängerung +x % oder kürzere Laufzeit, oder bewusst „gleicher Preis“ als ADR | Tobias 0,25, Lena 0,25 | Entscheid im JSON. Bot zeigt Ereignis 6 bei Minute 27–30 | Z1a | [E] |

**Risiko:** hoch. Jede k-Wahl macht T-15/T-16 ungültig (Zähler „Slice-Kalibrierung“ 5). **Testweg:** Bot auf der Welt, kein weiterer Slice-Lauf. d08 bleibt nur als Regression für den Slice.

---

## 3 Fahrzeug-Lebenszyklus (Bastis Fragen)

### 3.1 Antworten in einem Satz je Frage
- **Wo kauft man sie?** In S8 im Linienpanel („Linie anlegen“ kauft das erste Fuhrwerk, „+ Fuhrwerk“ weitere), wie im Slice. Das Fahrzeug erscheint am Startknoten. Eine Fuhrhalterei/Stellmacherei im HQ-Ort gibt es nur als Kulisse ohne Funktion. Ein echtes Depot mit Ausfahrt verlangt einen Eingriff in `sim_world` (Pendellinie) und bleibt draußen.
- **Wo werden sie gewartet?** Abstrahiert: Unterhalt (Futter, Knecht, Stellmacher) steckt im Fixbetrag je Periode und steigt mit dem Alter. Depotbesuche gibt es nicht.
- **Kapazität/Kosten/Verschleiß:** siehe Datensatz. Verschleiß = Unterhalt +5 % je Kalenderjahr (Feld vorhanden, wird nicht gelesen [M]: 0 Treffer außerhalb der Tests).
- **Folgemodell nach X Jahren und wie viel besser:** Frachtwagen (4 Pferde) ab 1830, also nach 10 Jahren = Minute 30 bei 3 min/Jahr. +80 % Kapazität, ≈ −13 % Kosten je Einheit und Feld bei k = 8, Kaufpreis +83 %.

### 3.2 Datensatz-Vorschlag (Startwerte [R], kalibriert in E3a)
| Feld | `fuhrwerk_e1` (2 Pferde) | `frachtwagen_e1` (4 Pferde) | Begründung |
|---|---|---|---|
| kauf_cent | 30.000 (300 $) | 55.000 | Bei k = 8 braucht es 2–3× so viele Fahrzeuge wie Lkw im Slice |
| fix_cent_pro_periode | 6.000 | 9.500 | s(k = 8) = 27,5 bzw. 24 ¢/E/Feld, in der Mitte des Bands aus §2.3 |
| variabel_cent_pro_feld | 4 | 5 | |
| kapazitaet_einheiten | 10 | 18 | +80 % |
| Tempo (`sim_felder_je_tick_promille`) | 600/k | gleich (Option: +10 % nur auf Chaussee, nicht S8) | Tempo als Vorteil erst ab Chaussee |
| lebensdauer | 15 Kalenderjahre | 20 Kalenderjahre | **neu in Kalenderjahren** statt `lebensdauer_ticks` |
| alterung_unterhalt_bp_pro_jahr | 500 (linear) | 400 | nach 10 Jahren +50 % |
| verfuegbar_ab_jahr | 1820 | 1830 | |
| Restwert beim Ersetzen | 50 % × max(0,2; 1 − Alter/Lebensdauer) | gleich | Heute erstattet `remove_line` pauschal 50 % (`main.gd` Z. 2693–2726) [M] |
| Postkutsche | **nicht kaufbar in S8** | – | ohne Passagiere eine reine Geldsenke; als Kulisse siehe D7 |

Nebenbefund: Alt gegen neu bei k = 8: Ein 10 Jahre altes Fuhrwerk kostet ≈ 40 ¢/E/Feld, ein neuer Frachtwagen 24 ¢. **Das Ersetzen ist um Minute 30 eine echte Rechnung.** Restwert ≈ 50–75 $ gegen 550 $ Kauf.

### 3.3 Was bei 3 min/Jahr (D5) sichtbar wird
Das Datum im HUD springt alle 15 s um einen Monat, 1820 → 1835 in 45 min. Der Unterhalt in der Linienliste steigt alle 3 min um 5 %. Bei 1830 kommt der Toast „Frachtwagen verfügbar“. Die Lizenzlaufzeit von 30 min entspricht 10 Kalenderjahren. Der Zins beträgt 3 % **je Minute** und muss im UI so heißen, weil er je Kalenderjahr ≈ 9 % wäre und je Wirtschaftsjahr ≈ 36 %. Das ist der Widerspruch Zwei Uhren (`lenses…/auswertung.md` Befund 3). **Ohne D5** (12 min/Jahr) sind es 3,75 Jahre: Unterhalt +19 %, kein Folgemodell. Für Basti ist dann nichts zu sehen.

### 3.4 Aufwand je Stufe
| Stufe | Aufwand | Urteil |
|---|---|---|
| Kauf (Linienpanel, +Fuhrwerk) | in P2 enthalten, + 0,25 Mira für „+ Fuhrwerk“ | rein |
| Alterung (Kalenderjahre, Unterhalt) | Felix 0,5, Tobias 0,25 | rein, hängt an D5 / T3 |
| Ersetzen (Restwert, Linie bleibt) | Mira 0,5, Felix 0,25 | rein |
| Folgemodell (Datensatz, Freischaltung nach Jahr, Kaufwahl 2 Typen) | Felix 0,5, Mira 0,5, Tobias 0,25 | rein, wenn D5 ja |
| Depot/Fuhrhalterei mit Ausfahrt | 2–3 [E] (Entwurf F1) | raus |
| Ausfall/Zuverlässigkeit + Diagnose | 1,5–2,5 [E] (Entwurf F2) | raus |

### Tickets Punkt 3
| ID | Ticket | Owner T | Akzeptanz messbar | Folge/Abhängigkeit | Marke |
|---|---|---|---|---|---|
| F3 | `fuhrwerk_e1` und `frachtwagen_e1` in `vehicles.json`. ProtoSim liest Kosten/Kap je Kategorie statt `lkw_e1`. Tempo bleibt in `regelwerk.json` (eine Quelle, Doku) | Felix 0,5, Tobias 0,5 | Test: Fuhrwerk-Linie bucht 60 $/Periode Fix und 10 E Kap. Slice-Regression unverändert (md5) | hängt an E1; Werte aus E3a | [E] |
| F2 | Alterung: Alter in Kalenderjahren, Unterhalt + bp je Jahr, Anzeige in der Linienliste | Felix 0,5, Tobias 0,25, Mira 0,25 | Nach 10 Kalenderjahren Fix = 150 % (Test). Liste zeigt Alter und Unterhalt | **hängt an D5** (Alternative ohne T3: Alterung in Wirtschaftsjahren, im Test unsichtbar; Δ −1 T bei T3) | [E] |
| F5 | Ersetzen mit Restwert, Fahrzeug bleibt auf der Linie | Mira 0,5, Felix 0,25 | Restwertformel im Test. Linie läuft ohne Neuanlage weiter | F2 | [E] |
| F4 | Folgemodell Frachtwagen ab 1830, Kaufwahl bei 2 Typen, Toast | Felix 0,5, Mira 0,5, Tobias 0,25 | Bei 3 min/Jahr ab Minute 30 kaufbar (Test mit Zeitsprung). Bot: Ersetzen-Ereignis zwischen Minute 28 und 35 | hängt an D5, F3 | [E] |

**Risiko:** mittel. Zwei Uhren machen alle Jahresgrößen mehrdeutig. **Testweg:** Zeitsprung-Test (Kalender ×20) plus Bot-Ereignis 8, dazu Aufgabe auf Bastis Karte: „Ersetze dein ältestes Fuhrwerk, wenn es sich lohnt, und sag, woran du es gesehen hast.“

---

## 4 Lieferung und Übergabe

**Ist:** Der Halteknoten wird automatisch gewählt: Wegende oder Kreuzung ≤ 40 m am Gebäude, sonst der nächste Knoten (`knoten_halt`, `proto_sim.gd` Z. 187–199) [M]. Für Orte gilt die Kreuzung nächst der Ortsmitte im Radius `r_m` (Z. 382). Im Bild ist das unsichtbar.

**Regeln (Vorschlag, Stadt-/Level-Design):**
1. **Jeder Betrieb hat genau einen festen Ladeplatz** (Hoftor/Rampe) als Datenpunkt `ladeplatz: {x, z}` in `proto_orte.json`. Er liegt am Netz (Abstand ≤ 8 m zum Netzknoten), sonst schlägt der Validator an. Der Ladeplatz ist sichtbar: Hofplatz-Textur 12 × 8 m, kleines Schild, Fuhrwerk hält dort.
2. **Orte:** Der Ladeplatz ist der Marktplatz oder Anger (Dorfmitte), wie heute die „Kreuzung nächst Ortsmitte“, nur mit Datenpunkt und sichtbarer Fläche. Ein Ort hat einen Ladeplatz für alle Güter.
3. **Übergabe:** An der Industrie geht die Ware in den Eingangspuffer, Ertrag bei Abgabe (`on_unload` K_INDUSTRIE). Am Ort Ertrag bei Abgabe mit Grenzpreis-Sättigung. Was nicht angenommen wird, bleibt auf dem Wagen, und ein Wagen mit Restladung lädt nicht nach (`economy.gd` Kopf Z. 25–26, `load_gate` Z. 708) [M]. Das muss als Diagnose erscheinen („Mehl bleibt auf dem Wagen: Mühle voll“), sonst wirkt es wie ein Fehler.
4. **Lager:** nicht im S8-Loop (Stretch P4). Der Loop braucht kein Umladen. Das Lager (200 E, 800 $, Ertrag 0, Stempel bleibt) ist im Slice vorhanden und kommt mit Bündeln aus 2 Farmen (Genossenschaft) in S9.
5. **Was Fuhrwerke tragen:** jedes Gut, keine Güterklassen (`economy.gd` Z. 26) [M]. Für S8 reicht das: Getreide und Mehl sind Sackware. Güterklassen (Langholz, Erz, Flüssiges) kommen mit der zweiten Kette.

| ID | Ticket | Owner T | Akzeptanz messbar | Folge/Abhängigkeit | Marke |
|---|---|---|---|---|---|
| L1 | Ladeplatz-Regel + Datenpunkt je Betrieb/Ort, Validatorregel, ProtoSim nutzt `ladeplatz` statt Suche | Stadt/Level 1, Felix 0,25 | Validator: 0 Ladeplätze > 8 m vom Netz. Alle Halte = Ladeplatz (Test) | W4a; Bild: TA 0,5 (im UX-/Art-Beitrag) | [E] |
| L2 | Diagnose-Texte „Restladung“ und „wartet auf Ladung“ (Inhalt) | Lena 0,25 (+ A-08 UX) | 2 Texte mit Ort, Ursache, Aktion | U4/A-08 | [E] |

---

## 5 Welt-Inhalt für den Loop (W4)

### 5.1 Befund
- Proto heute: 1 Farm, 1 Mühle, Erlenbach (Dorf, **244 Ort-EW**), Lindenfurt (Klasse kleinstadt, **387 Ort-EW**), Hasenwinkel (Weiler) (`proto_orte.json`) [M].
- **ProtoSim ignoriert diese EW.** Erlenbach wird fest auf `dorf_agrar` (900 EW) gesetzt, Lindenfurt auf `kleinstadt_a` (2.500 EW) (`proto_sim.gd` Z. 392/395) [M]. Die Nachfrage beträgt damit 18 bzw. 25 E/min (`city_demand`, Dorf ×2) [R]. Die 59 % „< 15/min“ aus dem Entwurf beziehen sich auf die Generatorwelt Welle 1, **nicht auf die ProtoSim-Kette**.
- Mit den echten Ort-EW wären es 4,9 und 3,9 E/min, also weit unter der Mühle (20). Mit Sim-EW nach Regelwerk (Dorf 400–900, Kleinstadt 2.400–4.700, `ortsklassen`) [M] liegt es dazwischen.
- Lindenfurt mit 387 Ort-EW verletzt die eigene Klassenregel (Kleinstadt Ort-EW 2.000–4.000) [M].
- `kette_aufbauen` nimmt die **erste** Farm und den ersten Ort jeder Klasse (Z. 365–376) [M]. Eine 2. Farm in den Daten bleibt ohne Code-Änderung wirkungslos.
- Der Warenkorb ist geprüft: Kleinstadt und Dorf nehmen `nahrung`, Mehl ist `nahrung` (`economy_slice.json saettigung.basket_by_stage`) [M]. Der Punkt „nicht geprüft“ im Entwurf ist damit geschlossen.
- Distanzen [R]: Farm–Mühle 17 Felder, Mühle–Erlenbach 15, Mühle–Lindenfurt 72 (jenseits des Knicks, also gut als Exploit-Probe), Hasenwinkel–Mühle 36.

### 5.2 Änderungen
1. **Daten (`proto_orte.json`):** Farm 2 („Hof Hasenwinkel“) 35–50 Felder von der Mühle, auf Ebene/Aue (Regel R1), mit Ladeplatz. Damit ist die Farmwahl nah/billig gegen weit/zweite Lizenz eine echte Wahl. Lindenfurt bekommt Ort-EW in der Klasse (≥ 2.000) oder wird als Marktflecken geführt (Ort-EW 800–1.300, Sim-Stufe kleinstadt).
2. **Ökonomie-Daten:** eigene Stadt-Einträge je Proto-Ort mit Sim-EW, Vorschlag Erlenbach 500 (→ 10 E/min), Lindenfurt 2.400 (→ 24 E/min), in einer **eigenen** `economy_proto.json` oder als Overlay. So bleibt die Slice-Regression unberührt.
3. **Code (ProtoSim):** alle Industrien und Orte als Sites registrieren, Stadt-ID aus den Daten statt fest verdrahtet.
4. **Mühle:** Ausbau Stufe 2 (40 E/min) über C1 (§A). Fallback ohne C1: Durchsatz der Wassermühle in den Daten auf 40 (0 PT, aber kein Kaufmoment). Dann muss Farm 2 als Lizenz-Wahl tragen.

**Wirkung auf die Nachfrage [R]:** Erlenbach 10 gegen Mühle 20 ergibt 200 % Sättigung ab der ersten vollen Mühle. Der Druck zum zweiten Abnehmer setzt also bei Minute ≈ 10 ein (F1). Lindenfurt 24 + Erlenbach 10 = 34 < 40 (Mühle Stufe 2), das heißt nach dem Ausbau entsteht leichter Überdruck, und der hält die Optimierung bis Minute 45 offen. Die Bankrott-Gefahr bei kleinen Senken (`tobias_welle1.md`: 27–35 %) misst E3b für genau diese Werte.

### 5.3 Level-Design-Regeln
- **Kartentyp Flusstal (S8-Standard):** Hauptfluss 60–100 m, Wasseranteil 3–5 % (`regelwerk.json gewaesser_kartentyp.flusstal`) [M].
- **Erwartungsregel (Basti 03.11.):** Großes Gewässer = nutzbar. Vorschlag für die Schwelle: **stehendes Gewässer ≥ 300 m Äquivalentdurchmesser braucht sichtbare Nutzung** (passt zu V-W2/V-W3 „Nutzung ab 300 m“). Unter 150 m ist es ein Teich/Weiher ohne Erwartung. 150–300 m nur mit Kulisse (Steg).
- **Widerspruch im Regelwerk:** Flusstal erlaubt heute Seen mit 300–800 m Durchmesser. Laut Basti stehen bei breitem Fluss aber nur kleine Teiche. Deshalb `flusstal.see_durchmesser_m` auf [0, 150] setzen. Größere Seen gibt es nur in Seenplatte/Seenreich mit Nutzung.
- **Binsensee im Proto: Äquivalentdurchmesser 494 m** (`proto_see.json`) [M], liegt also über der Schwelle. Empfehlung für den S8-Loop: auf ≤ 150 m verkleinern (Flusstal-Karte). Fischerei als Kette ist nicht geschätzt und nicht in S8.

| ID | Ticket | Owner T | Akzeptanz messbar | Folge/Abhängigkeit | Marke |
|---|---|---|---|---|---|
| W4a | Welt-Daten: Farm 2 mit Ladeplatz, Lindenfurt klassenkonform, Sim-EW je Ort in `economy_proto.json` | Stadt/Level 1, Tobias 0,5 | Validator 0 Verstöße. Nachfrage Erlenbach 10 ± 2, Lindenfurt 24 ± 3 E/min (Test). Slice md5 unverändert | E3b nutzt die Werte | [E] |
| W4b | ProtoSim: generische Site-Registrierung (alle Farmen/Mühlen/Orte), Stadt-ID aus Daten | Felix 0,75 | 2 Farmen, 1 Mühle, 2 Orte als Sites. `proto_sim_test` grün + neuer Test „2. Farm liefert“ | hängt an W4a; Grundlage Q2 | [E] (Entwurf hatte W4 nur als Daten) |
| LD1 | Regel Gewässer je Kartentyp ins Regelwerk (Schwelle 150/300 m), Binsensee ≤ 150 m | Stadt/Level 0,5, TA 0,5–1 | `regelwerk.json` geändert, Validator prüft die Schwelle. Proto-See ≤ 150 m oder mit Nutzung | Bastis Entscheid T-W1 | [E] |
| W3 | Gebäude-Placement an Bastis Stellen | Stadt/Level 1,5 | je gemeldete Stelle vorher/nachher-Shot, Abnahme Basti | hängt an Bastis Screenshots | [E] Entwurf 1–2 |

**Risiko:** Die Nachfrage-Werte machen die Kette knapp (Bankrott-Band). **Testweg:** E3b mit genau diesen EW. Fällt sie aus dem Band, wird nur `demand_per_100` oder die Sim-EW angepasst (Regel `kalibrierung.falls_ausserhalb`).

---

## 6 D7: Eigenversorgung und Reisende ohne Spieler

| Option | Inhalt | Wirkung auf die Kalibrierung | Aufwand |
|---|---|---|---|
| O0 | nichts (heute) | keine | 0 |
| O1 Kulisse | Fremd-Fuhrwerke und Postkutsche als Leerläufer auf den Wegen (`testlinie(..., leave_empty)` gibt es schon, Z. 342) [M], ohne Kasse, ohne Ertrag. Wirkt als Belebung | keine (Sim-Kasse unberührt, aber Fahrzeugzahl und Perf zählen) | Felix 0,5, Stadt/Level 0,25 [E] |
| O2 Grundversorgung | Ort deckt x % seiner Nachfrage selbst. Effektive Nachfrage × (1 − x). Gleicher Mechanismus wie „Konkurrenz passiv“ (Datenfeld 0/10/15/20 %, `referenzen/oekonomie.md` Idee 5) | senkt die Nachfrage, bei kleinen Senken steigt der Bankrott. Muss im Bot als Variante laufen | Tobias 0,25 (Datenfeld + Bot-Variante) |
| O3 Personen-Sim | Reisende mit Quelle/Ziel, Postkutsche mit Ertrag | neue Ertragsart, Neukalibrierung | nicht geschätzt, > 5 PT [E] |

**Empfehlung:** S8 mit O2 als Datenfeld, Standard 0, nur als Bot-Variante gemessen, plus O1 als Stretch (Postkutsche fährt als Kulisse Dorf ↔ Lindenfurt, wie heute schon in `kette_aufbauen` Z. 416). Basti entscheidet O2 in S9 am Messwert. O3 frühestens mit Bus/Passagieren. Passt zu E7 („Orte ohne Versorgung stabil“): Stabilität ohne Versorgung heißt implizit schon Eigenversorgung, O2 macht das nur zahlenmäßig.

| ID | Ticket | Owner T | Akzeptanz messbar | Folge/Abhängigkeit | Marke |
|---|---|---|---|---|---|
| D7-O2 | Datenfeld `eigenversorgung_promille` je Ort/Preset, Standard 0, Bot-Variante 150 | Tobias 0,25 | Bot-Tabelle 0/150 ‰: Bankrott, F1-Minute | E3b | [E] |
| D7-O1 (Stretch) | Belebung: 2–3 Leerläufer + Postkutsche als Kulisse | Felix 0,5, Stadt/Level 0,25 | Kasse mit/ohne Kulisse gleich (Prüfsumme Eco). Perf-Gate hält | nach Q2 grün | [E] |

---

## A Firmenkauf (F-22), parallel

### A.1 Begriff trennen (löst den Widerspruch)
`referenzen/oekonomie.md` Z. 83/88 („bauen, nur Stufe 1, erst in S9“) und `referenzen/zeitreise.md` Z. 79/82 („gestrichen, bis Konkurrenz existiert“) meinen **beide C2: eine bankrotte Rivalenfirma kaufen**. Sie widersprechen sich also direkt (`lenses…/auswertung.md` Befund 16). C1 („Industrie kaufen“, Besitz-Leiter Lizenz → Kauf, `concept/industry.md`) braucht weder KI noch Konkurrenz (Befund 12).
**Vorschlag an Jonas:** C1 kommt in S8 parallel (Bastis Vorgabe), C2 bekommt in S8 Spezifikation + ADR mit Ablaufdatum S9-Refinement. „Konkurrenz existiert“ ist erfüllt, sobald ein **geskripteter Rivale** läuft (Konkurrenz-Stufe 1). Beide Jonas-Sätze sind damit aufgelöst: C2 kommt in S9 als Stufe 1, nicht gestrichen.

### A.2 Kleinste testbare Stufe: C1 „Mühle kaufen und ausbauen“
- Preis = `kaufpreis_stufe1` × Stufe × (1 + 30 ‰ je Feld außerhalb HQ-Radius) − 50 % der gezahlten Lizenzgebühren. Der erste Kauf ist −20 % billiger (`economy_slice.json kauf`) [M]. Mühle in Erlenbach ≈ 1.600 $ [R], Kauf nur aus Guthaben (`buy_only_from_balance_flag`, `credit_blocks_company_buy_flag`) [M]. **Folge:** Kredit tilgen und dann kaufen ist eine echte Wahl um Minute 15–20.
- Ausbau Stufe 2: 2.000 $, Durchsatz 40 E/min (`fabrik`) [M]. Im Code fehlt das (Z. 450 nur L1).
- Werksmarge 15 % auf Erträge aus Ware mit Ursprung im eigenen Werk (ohne KI-Abholer = Preisbonus auf eigenes Mehl). Unterhalt 20 $/min × Stufe.
- **Besitzer-Datenmodell (minimal):** `s_owner[site]` (0 frei, 1 Spieler, ≥ 2 KI/Rivale, reserviert). Gekauft heißt Lizenz unbefristet (`s_lic_until = -2`, Annahme aus Befund 13, nicht geprüft) + Owner 1. Kein Besitzfeld an Fahrzeugen und Linien in S8.
- **Schneeballeffekt:** Marge + Ausbau verzinsen sich. In der Proto-Welt deckelt die Karte (3 kaufbare Betriebe). Auf der Vollkarte wäre das offen. **Schutz:** Kaufpreis +25 % je bereits besessenem Werk [E]. Messen auf Slice-Karte und Welt.

### A.3 C2 (Spezifikation in S8)
Ein Skript-Rivale hält die Lizenz an Farm 2 (Fremd-Fuhrwerke = O1-Kulisse) und verliert deterministisch Geld. Bei Minute ≈ 30 bietet er die Insolvenz an. **Preis = Restwert:** Fahrzeuge zum Restwert (Formel §3.2) + Lizenzrestlaufzeit anteilig + Werk zum Buchwert × 0,5. **Kreditübernahme:** Der geerbte Kredit kommt zum eigenen dazu. Liegt die Summe über dem Rahmen von 2.000 $, ist der Kauf gesperrt, mit Text. Zeitfenster 3 min, sonst bekommt er „ein anderer“ (OpenTTD-Muster, `referenzen/oekonomie.md`). KI-Platzhalter Konkurrenz: Datenfeld Nachfrageanteil 0/10/15/20 % (= O2-Mechanismus).

| ID | Ticket | Owner T | Akzeptanz messbar | Folge/Abhängigkeit | Marke |
|---|---|---|---|---|---|
| F22-0 | ADR C1/C2 + Besitzerfeld-Spezifikation, Ablaufdatum | Jonas 0,25, Tobias 0,5, Felix 0,25 | ADR mit „revidierbar bis S9-Refinement“. Feldliste ≤ 1 Seite | – | [E] |
| F22-1 | C1: Kauf + Ausbau Stufe 2 + Marge + Unterhalt in `economy.gd`, Panel-Knopf „Entwicklung“ | Tobias 1, Felix 1,5, Mira 1,5, Aylin 0,5 | Bot: Kauf amortisiert sich in 8–20 min. Plan-Bot kauft die Mühle zwischen Minute 14 und 25. Schneeball: im Slice-Bot keine Verdopplung von Netto-€/min schneller als alle 10 min nach dem 1. Kauf. Slice-Regression grün | hängt an E1, P1-Panel; liefert W4-Schritt Mühle 40 E/min | [E]; `referenzen` nennen für C2 4–6 PT, C1 ohne Rivale kleiner |
| F22-2 | C2: Spezifikation (Restwert, Kreditübernahme, Zeitfenster) | Tobias 0,5, Lena 0,5 | 1 Seite mit Formeln und Bot-Testfall | Bau S9 (Tobias 1, Felix 1,5, Mira 1, Lena 0,5 ≈ 4 T [R]) | [E] |
| F22-K | Konkurrenz-Platzhalter: Datenfeld Nachfrageanteil je Preset | Tobias 0,2 | Bot-Variante 0/15 % in E3b | = D7-O2-Mechanik | [R] `referenzen/oekonomie.md` Idee 5 |

**Risiko:** mittel bis hoch. Ohne Besitzerfeld ist jede Schätzung über 6 PT unsicher (Jonas). Mira ist der Engpass. **Testweg:** Bot plus Karte L3 „Kaufe die Mühle, wenn sie am Deckel läuft. Woran hast du das gemerkt?“

---

## B Skilltree (SK-02), parallel

- **Punktequelle:** Seit S7 entschieden: Meilensteine und Etappen, **keine Ast-XP** (`s7/refinement/ergebnis.md` Streitprotokoll) [M]. `sk01_skilltree_v0.md` §2 und `concept/lena.md` führen die Ast-XP noch, das ist Konzeptdrift (Zähler 4) und wird nachgezogen. Lenas Restwunsch „Dauerspiel ohne Fortschritt“ deckt der Kalender ab (Etappen je Epoche).
- **Quote:** im 45-min-Loop **4 Punkte**: Start/E-1 (M1b), E-6, F1, F2, also ≈ 1 je 10–12 min. Je Epoche ≈ 6 Punkte (`referenzen/fortschritt.md` §4). W1 = 1820–1850 = 90 min bei 3 min/Jahr ergibt ≈ 1 je 15 min. Das passt, ist aber nur für 3 min/Jahr gerechnet (D5).
- **Ausstoß-Ränge unter Sättigung:** +8 % Output bringt bei 100/120/160 % Versorgung nur +7,6/+5,7/+0,9 % (`lenses…/auswertung.md` Befund 6). Im Loop kommt hinzu: Farm-Output verpufft, solange die Mühle auf 20 E/min deckelt. **Ausstoß-Ränge sind deshalb raus aus v1.**
- **Dominante Strategie:** `skill_bonus` (B_skill) wirkt nach der Sättigung und bringt immer seine volle Höhe (`economy.gd` Z. 364) [M]. Damit ist „alle Punkte auf Preis“ dominant. Außerdem ist `skill_bonus` ein globaler Wert, nicht je Gut oder Ast (Z. 75) [M]. Ein Preisknoten je Gutkategorie braucht also Code. In v1 gibt es höchstens einen Preisknoten (3 Ränge × 8 % = 24 %, Deckel 40 %).
- **Knoten v1 (6):** *Straße & Logistik*: Ausspann (−15 % Ladezeit an eigenen Ladeplätzen, 1/1), Fuhrhalterei (−10 % Unterhalt Fuhrwerke, 1/3), Schlüssel **Frachtwagen-Patent** (Folgemodell 5 Kalenderjahre früher, verknüpft F4). *Agrar & Nahrung*: Marktstand (+8 % Preis Nahrung, 1/3), Kornspeicher (Mehl-Frischefrist +50 %, 1/1; schwächt die Exploit-Bremse und muss deshalb in X1 mitgemessen werden), Schlüssel **Mahlrecht** (+10 E/min an einer lizenzierten, nicht gekauften Mühle; Alternative zu C1, damit Kauf und Skill eine Wahl sind).
- **Respec:** in S8 kostenlos und unbegrenzt (Testbarkeit). Jeder Respec wird geloggt. Respec-Kosten erst, wenn Bot oder Basti einen Missbrauch zeigen.

| ID | Ticket | Owner T | Akzeptanz messbar | Folge/Abhängigkeit | Marke |
|---|---|---|---|---|---|
| SK-02a | Konzept v1: Quelle, Quote, 6 Knoten mit Zahlen, Respec. `sk01`, `lena.md` nachziehen | Lena 1,5, Tobias 0,75 | 1 Seite. Jeder Knoten zeigt Wirkung in Zahlen und „wirkt auf“. 0 Ast-XP-Erwähnungen in Konzeptdateien | Punkte aus Z1a | [E] |
| SK-02b | Bau v1: Punktestand, Baum-Panel 2 Äste, 6 Knoten wirksam in ProtoSim, Respec | Mira 2, Felix 0,75, Aylin 0,5 | Je Knoten ein Test (Wirkung = Zahl im Tooltip). 4 Punkte im Plan-Bot bis Minute 45 | hängt an Z1b, E1; Knoten Frachtwagen-Patent an F4, Mahlrecht an W4b | [E] |
| SK-02c | Dominanz-Check per Bot | Tobias 0,5 | Δ Netto €/min (Min 45) je Knoten: keiner > 2 × Median, keiner < 0,3 × Median | SK-02b | [E] |

**Risiko:** Mira ist schon mit Loop-UI voll belegt. **Testweg:** Bot + Bastis Frage „Welchen Knoten hast du warum gewählt?“

---

## 7 Schnitt (Aufwand gegen Wirkung, Jonas-Blick)

**Sprintziel (Vorschlag):** Basti startet die Welt aus dem Menü und spielt 45 min am Stück: Fuhrwerke mit gewähltem Tempo (D2), 2 Farmen, 1 Mühle, 2 Orte, Lizenz, Linie, Fuhrwerk kaufen, ersetzen, Frachtwagen ab 1830 (3 min/Jahr), Kredit, Bankrott mit Vorwarnung, Ziele E-1–E-6 + F1/F2, sichtbare Sättigung, Mühle kaufen und ausbauen (C1), Skilltree v1 mit 6 Knoten. Der Loop-Bot zeigt: Bankrott naiv 10–30 %, Plan ≤ 5 %, Ereignislücke P90 ≤ 3 min, Exploit-Regel X1 grün. Bodentextur an Bastis Stellen (Tech Art, separat).

| Gruppe | Inhalt |
|---|---|
| **Ziel (MUSS)** | Z1a/b/c, Q2, E1, E3a, E3b, E2s, E6, F3, F2, F5, F4 (wenn D5 ja), L1, W4a, W4b, LD1, F22-0, F22-1, SK-02a/b/c, D7-O2, F22-K |
| **Stretch** | P3 Stichweg (Design: Basti verlangt keinen Straßenbau, alle Betriebe am Netz; spart Felix 2–3 T), D7-O1 Belebung, F3 Stadtwachstum, P4 Lager, W3 nur soweit Screenshots kommen, C2-Bau falls F22-1 bis Tag 10 grün |
| **Raus (S9+)** | C2-Bau (Spec bleibt), Depot, Ausfall, Postkutsche kaufbar/Passagiere, zweite Kette, Gleis in der Welt, Ausstoß-Skillränge, Ast-XP, Fischerei/Seenutzung, Generator Vollkarte |

**Kapazität Designgruppe (12 T, Plan ≤ 10,5)**
| Person | Plan | Belegung |
|---|---|---|
| Lena | 6,75 | Z1a 1,5, Z1b 0,5, E6 0,25, L2 0,25, F22-2 0,5, SK-02a 1,5, Karten L1–L3 mit Aylin 1, Auswertung Interessenkurve/Review 1,25 |
| Tobias | 10,95 | Z1a 0,25, Q2 2, Z1c 0,25, E1 0,5, E3a 2, E3b 1,5, E2s 0,25, E6 0,25, F3 0,5, F2 0,25, F4 0,25, W4a 0,5, D7-O2 0,25, F22-0 0,5, F22-1 1, F22-2 0,5, F22-K 0,2, SK-02a 0,75, SK-02c 0,5 → **über Plan, Puffer 1,05.** Schnittkandidat: F22-2 an Lena |
| Stadt/Level | 4,5 | W4a 1, L1 1, LD1 0,5, W3 1,5, D7-O1 0,25 (Stretch). Freier Rest: Validator auf Ladeplatz/Gewässer, Abnahme, oder Stadt-KI 60 Monate (eigene Empfehlung, Stretch 2 T) |

Fremdlast aus unseren Tickets: **Felix ≈ 8,25 T** (E1 1,5, Q2 0,5, F3 0,5, F2 0,5, F5 0,25, F4 0,5, L1 0,25, W4b 0,75, F22-0 0,25, F22-1 1,5, SK-02b 0,75, + T2 Tempo-Code aus dem Tech-Beitrag) und **Mira ≈ 6,75 T** (Z1b 1,5, F2 0,25, F5 0,5, F4 0,5, F22-1 1,5, SK-02b 2, + „+ Fuhrwerk“ 0,25, ohne P1/P2/U1–U4 ≈ 6–9 T aus dem Entwurf). **Mira liegt damit bei ≈ 13–16 T gegen 12 T Kapazität. Das passt nicht.** Schnitt-Reihenfolge, falls keine zweite UI-Kraft kommt: (1) SK-02b auf 1 Ast/3 Knoten (−1 T), (2) F22-1-Panel nur als Knopf im bestehenden Panel (−0,75 T), (3) F4 Kaufwahl als Ersetzen-Dialog statt Menü (−0,25 T). P3 bleibt in jedem Fall Stretch.

**Sprintlänge:** 15 Tage halten wir für richtig. 10 Tage trügen nur den Loop ohne F-22/SK-02. Mehr als 15 Tage verschiebt Bastis 45-min-Test zu weit nach hinten. Meilenstein: **Karte L2 (20 min Kette selbst betreiben) an Tag 7**, L3 an Tag 13, Tag 14–15 Abnahme, Regression, Review/Retro.

## Rollen und Kompetenzen, die uns fehlen
1. **Zweite Gameplay-/UI-Entwicklung** (Panels, Listen, Baum-UI). Ohne sie trägt Mira Loop-UI, Firmenkauf-UI und Skilltree-UI, also ≈ 13–16 T. Das ist die größte Lücke.
2. **Simulations-/Tools-Entwicklung** (Bot-Harness auf ProtoSim, Regressionsstufen, headless-Läufe). Tobias schreibt Strategien, Felix ist Engpass für den Kern. Heute fällt das zwischen die Stühle (Zähler „Slice-Kalibrierung“ 5).
3. **3–5 Fremdtester** für die 45 min (Jonas R1: ein Tester findet ≈ 31 %). Für die Interessenkurve ist das Basti allein, n = 1.
4. Kein neuer Designkopf nötig. Stadt-/Level-Design hat freie Kapazität und übernimmt Validator und Abnahme.

## Widersprüche zum Entwurf `loop_s8_2026-11-04.md` (im Code geprüft)
1. **Tempoquelle:** Der Entwurf sagt „Fuhrwerk = Datensatz `lkw_e1`, `tempo_mm_pro_tick` 600“ (Z. 10, T2). In ProtoSim kommt das Tempo aber aus `regelwerk.json fahrzeug_easing.kategorien.fuhrwerk.sim_felder_je_tick_promille` (`proto_easing.gd` Z. 64, `proto_sim.gd` Z. 306). Nur Kosten und Kapazität kommen aus `lkw_e1`. Der Zahlenwert 150 m/s stimmt, aber T2 muss im Regelwerk ansetzen, nicht in `vehicles.json`.
2. **Umlaufrechnung §2.2:** 200 Getreide in 6.000 Ticks ist die **Produktionsgrenze** (20 E/Periode × 10 Perioden), kein Fahrzeugmaß. Aus dieser Zahl lässt sich kein Umlauf von 300 Ticks zurückrechnen. Der eigene Überschlag Farm–Mühle liegt bei ≈ 270 Ticks (k = 1) bzw. ≈ 730 Ticks (k = 8), nicht bei 1.000.
3. **Ausgleich „Ertrag × k, Bedarf ÷ k“** (§2.2, T2) ist ohne Produktion ÷ k unvollständig, und ein voller Ausgleich holt den Entfernungs-Exploit zurück (§2.3/2.4).
4. **W4 „nur Weltdaten“:** ProtoSim nimmt die erste Farm und feste Stadt-IDs (`proto_sim.gd` Z. 365–395). Eine 2. Farm braucht Code (W4b). Außerdem deckelt die Mühle auf 20 E/min (`economy.gd` Z. 450), ein Ausbau fehlt im Code. Ohne Ausbau ist Farm 2 wirkungslos.
5. **Nachfrage-Risiko W4:** Die „59 % < 15/min“ gelten für die Generatorwelt. Die ProtoSim-Kette rechnet mit Slice-EW 900/2.500 (18/25 E/min), nicht mit den Proto-EW 244/387.
6. **Offen gelassene Punkte, die geprüft sind:** Kleinstadt nimmt Mehl (Warenkorb `nahrung`). `remove_line` erstattet 50 % (`main.gd` Z. 2693–2726).
7. **E1-Risiko überzeichnet:** `credit.gd` ist ein eigenständiges Modul, und die Laufkosten in `main.gd` sind ~10 Zeilen. Kopieren oder Auslagern ist kleiner als „Panel-Code“.
8. **D5 „45 min = 15 Jahre = eine Lebensdauer“** gilt nur, wenn die Lebensdauer auf Kalenderjahre umgestellt wird. `lebensdauer_ticks` 108.000 zählt in Wirtschaftsticks und bliebe bei 180 min.
9. **G-01-Annahmen gegen Code:** Lizenzverlängerung +10 % ist nicht im Code (gleicher Preis). F2 „1.000 $/min netto“ ist mit einer Mühle (Brutto-Maximum ≈ 1.000 $/min) nicht erreichbar.
10. **Gleis ab 1835** ist bei 3 min/Jahr Minute 45. Die Streichliste begründet „kein Gleis“ mit 180 min (12 min/Jahr). Unter D5 stimmt diese Begründung nicht mehr, Gleis muss aktiv gesperrt werden.

Nicht geprüft: alles Laufzeitverhalten (kein Godot-Lauf). Ob `s_lic_until = -2` als „unbefristet“ ohne Nebenwirkung geht. Pfadlängen im Proto-Netz (nur Luftlinie gerechnet). Lindenfurts Rolle im Kartenbild nach einer EW-Änderung.
