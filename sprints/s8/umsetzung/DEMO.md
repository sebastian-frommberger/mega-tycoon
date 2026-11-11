# DEMO: 30-Minuten-Demo Mega Tycoon (Bericht des Demo-Sprints, 10.11.2026)

Branch `s8-demo` (gemergt nach `s8`). Start: `play_demo.bat` (Windows), `tools/play_demo.sh`, oder Startmenü „Demo spielen“ (Taste D). Anleitung: `DEMO_ANLEITUNG.md`. Plan: `DEMO_PLAN.md`.

## 00 Teil 4 (12.11.): Straßen- und Gleisbau neu

Nach Bastis Feedback („Feedback beim Ziehen seltsam, keine richtigen Kurven, Planungsmodus wäre gut“). Vorbild Transport Fever 2 / Cities: Skylines. Nur Demo-Modus. Einzelheiten und Vorher/Nachher je Befund: `DEMO_STRASSENBAU_BEFUND.md`.

**So baut man jetzt**
1. **B** (Straße) oder **G** (Gleis). Unter der Maus zeigt eine Marke, woran der Start einrastet; das Schild an der Maus sagt es in Worten.
2. **Klick** setzt den Start. Ab da liegt die Trasse bis zur Maus als Band da, mit Länge und Preis am Schild.
3. Weitere **Klicks** setzen Punkte. **C** wechselt Kurve (tangentiale Kreisbögen) und gerade (ausgerundete Ecken). Fehler sind nur an der Stelle rot.
4. **Enter** oder Doppelklick baut genau das Gezeigte. **Rechtsklick** nimmt einen Punkt zurück. Das Werkzeug bleibt an.
5. **P** schaltet auf Planen: Abschnitte werden als Blaupause abgelegt, „Plan bauen“ baut alles oder die Auswahl, wenn das Geld reicht.

| Größe | Wert |
|---|---|
| gebaute Mittellinie gegen Vorschau | höchstens 0,97 m Abweichung (gerade), 0,96 m (Kurve) |
| Kurve | Kreisbogen 73 m Radius im Beispiel, größter Knick zwischen zwei Punkten 5,8°; Mindestradius Straße 12 m, Gleis 55 m |
| Kreuzung | vom neuen Ende zum gekreuzten Knoten 86 m über das Netz, vorher 366 m |
| Fehler lokal | See: 22 von 41 Punkten rot; Gleisbogen zu eng: 17 von 24 |
| Schild an der Maus | 29 px neben der Maus, vorher 444 px bis zur Karte |
| Plan | 3 Abschnitte geplant ohne Geld, 1 verworfen, 2 für 250 $ gebaut |
| `demo_sim_test` | 94/94 (T1–T7 neu: Bogen, Fehler mit Ort, exakter Bau, Kreuzung, Planende, Fahrzeug fährt über die Kurve) |
| `demo_ui_test` | 65/65 (B1–B9 neu) |
| Bot n = 40, 30 min (baut jetzt über das neue Werkzeug) | Bankrott 0/40, 0 Fenster ohne Aktion, voller Bogen 40/40, Meilensteine P50 13, Ertrag letzte Minute P50 3.667 $, 0 Sim-Fehler, Determinismus gleich |
| `regress_fast` | GRÜN, 216 s (Ziel < 300 s) |
| d07 voll | GRÜN, 811 s |
| d08 `--n=20` CSV md5 | `5cce648a53c1c2f3246147abcaca0988`, unverändert (Slice-Parität) |

**Was die Tests über welchen Weg prüfen:** `demo_bau_befund.gd` (xvfb) fährt die Maus wirklich (Bewegung, Klick links und rechts, Tasten). `demo_ui_test.gd` (headless, läuft in der Regression) schickt Klicks und Tasten als Ereignisse; die Mausposition über der Welt setzt es direkt, weil es headless keinen Mauszeiger gibt.

**Nicht gemacht:** Ziehen mit gehaltener Maustaste, kleinere Seesperre, Bahnübergänge, Abreißen in der Welt, Parallelversatz, Tunnel. **Nicht geprüft:** Spielgefühl, Steigungsfehler im Durchspiel, Bildrate der Vorschau auf echter GPU, Windows.

Bilder: `demo_shots/28` Plan · `29` Kurve · `30` Fehler lokal · `07` Straße mit Schild · `bau/n1` bis `n11` (nachher), `bau/b*` (vorher).

## 0 Teil 3 (11.11.): Linien- und Fahrzeugverwaltung neu

Nach Bastis Spieltest umgebaut, Vorbild Transport Fever 2. Dieser Abschnitt ist der aktuelle Stand; wo er den Abschnitten 1b bis 5 widerspricht, gilt er.

**Der neue Ablauf in fünf Schritten**
1. **Firmensitz setzen** (Taste H). Er bringt den Fuhrhof mit, das erste Depot.
2. **Linie anlegen** (Taste L → Neue Linie → Art): Halte in der Welt anklicken, Enter. Die Linie hat kein Fahrzeug und kostet nichts.
3. **Im Depot kaufen:** Depot anklicken oder „Zum Depot“. Katalog mit Preis, Ladung, Unterhalt und Stückzahl. Gekaufte Fahrzeuge stehen im Depot.
4. **Zuweisen:** Fahrzeuge auswählen (Klick, Umschalt+Klick für einen Bereich, Alle/Keine), Klick auf die Linie. Sie rücken vom Depot zum ersten Halt aus.
5. **Verwalten** (Taste U): alle Fahrzeuge mit Filter nach Linie, Art, „im Depot“; Sammelaktionen Zuweisen, Ins Depot, Ersetzen, Überholen, Verkaufen.

**Was sich geändert hat**
| Punkt | Stand |
|---|---|
| Altes Muster | Im Demo-Modus nicht mehr erreichbar: kein „Linie von hier → Ziel → kaufen“, kein „+ Fuhrwerk“. Das Betriebspanel zeigt Infos, „Linie hier beginnen“ und die Linien, die dort halten. Ohne `--demo` unverändert |
| Fenster „Verkehr“ | ein Fenster, vier Reiter: Linien (Liste links, Detail rechts: Halte mit Ladeauftrag, Fahrzeuge, Ertrag/min, Auslastung, Linienfarbe), Fahrzeuge, Depots, Strecken. `slice/proto/ui_verkehr.gd` |
| Depot | einziger Kaufort. Fuhrhof am Firmensitz gratis; Betriebshof (Straße) und Lokschuppen (Gleis) für 250 $ und 5 $/min. Depot in der Welt anklickbar. Kein Depotrabatt mehr. Fahrzeuge im Depot: ein Viertel Unterhalt, kein Ertrag |
| Auswahl | genau eine: Betrieb/Ort, Depot, Firmensitz oder Linie. Pulsierender Ring, goldener Rahmen am Schild, gewählte Linie als farbige Route. Hover-Ring und Zeigehand über allem Anklickbaren. Esc und Klick ins Leere heben auf |
| Modus | Banner oben mittig in jedem Modus (Firmensitz, Straße, Gleis, Depot, Halte anklicken) mit Text, Zähler und „Esc bricht ab“. Gültige Halte mit Ring und Rahmen, ungültige abgedunkelt, Verbotszeiger. Ein Modus beendet den anderen |
| Hilfen | Startbild, „Nächster Schritt“ (nennt, was im Ablauf offen ist: Linie fehlt, Fahrzeuge im Depot, Lizenz fehlt), Meilenstein-Tipps, Fehlertexte, `DEMO_ANLEITUNG.md` |
| Straßenbau | nicht umgebaut. Befund mit 13 Punkten und Bildern: `DEMO_STRASSENBAU_BEFUND.md` |

**Gemessen (11.11., Sandbox, 2 vCPU, headless)**
| Größe | Wert | vor dem Umbau |
|---|---|---|
| Bot n = 40, 30 min: Bankrott | 0/40 | 0/40 |
| 60-s-Fenster ohne bezahlbare Aktion | 0 | 0 |
| längste Zeit ohne Angebot | P50 5 s, Max 10 s | P50 5 s, Max 10 s |
| voller Bogen (Linie ohne Fahrzeug, Kauf im Depot, Sammelzuweisung, Linie mit 3 Halten, ins Depot und Verkauf, Personenzug, Güterzug, Stadtverkehr) | 40/40 | 40/40 (ohne die drei neuen Kriterien) |
| Meilensteine | P50 12 von 14 (min 10) | P50 13 (min 11) |
| Ertrag letzte Minute | P50 3.507 $ (1.488–6.688) | P50 5.293 $ (1.762–10.338) |
| Kasse Minute 30 | P50 1.439 $ (404–4.180) | P50 2.510 $ (923–9.142) |
| Fahrzeuge / ersetzt / Verträge erfüllt (P50) | 27 / 3 / 6 | 28 / 6 / 7 |
| gebaute Depots je Lauf | 3 (Betriebshof, 2 Lokschuppen), dazu der geschenkte Fuhrhof | 2 |
| Sim-Fehler, API-Ablehnungen, Determinismus | 0, 0, gleich | 0, 0, gleich |
| `demo_sim_test` | 86/86 | 81/81 |
| `demo_ui_test` | 58/58 | 44/44 |
| regress_fast | GRÜN, 240 s (Ziel < 300 s) | GRÜN, 196 s |
| d07 voll | GRÜN, 842 s, 43 Zeilen | GRÜN, 802 s |
| d08 `--n=20` CSV md5 | 5cce648a53c1c2f3246147abcaca0988, unverändert | derselbe |

**Die Wirtschaft ist mit dem neuen Ablauf enger geworden.** Der Bot verdient in Minute 30 im Median rund ein Drittel weniger. Was ich dazu gemessen habe:
- Die Linienmechanik selbst ist gleich schnell: derselbe Aufbau (5 bzw. 6 Fuhrwerke, 12 bis 15 Minuten) bringt alt 4.282 $ und neu 4.457 $, mit Lindenfurt-Linie alt 7.725 $ und neu 8.426 $.
- Depots sind jetzt Pflicht je Gleisnetz: Der Bot baut 3 statt 2 je Lauf. Mit 600 $ je Depot schafften nur 32/40 Läufe den vollen Bogen, mit 250 $ 39/40, mit Vorrang für den Personenzug im Bot 40/40.
- Neue Fahrzeuge fahren erst vom Depot zum ersten Halt. Bei fernem Firmensitz kommt das erste Geld später (0 $ statt 629 $ nach drei Minuten, nach zwölf Minuten ausgeglichen).
- Der Bot ersetzt halb so oft (P50 3 statt 6), weil seine Kassenschwelle öfter verfehlt wird; das zieht Ertrag nach.
Welcher dieser Punkte wie viel ausmacht, habe ich nicht getrennt gemessen. Nachkalibriert ist nur der Depotpreis.

**Tests über den echten Maus-/Tastenweg** (`demo_ui_test`, Ereignisse durch den Viewport): Kauf im Depot ohne Linie (A8), Mehrfachauswahl mit Umschalt+Klick (A9), Sammelzuweisung per Klick auf die Linie (A10, A11), Ring sichtbar und weg (A1, A2), Hover und Mauszeiger (A3), altes Muster nicht erreichbar (A4, U28b), Banner in jedem Modus und Esc beendet jeden (A16), ein Modus beendet den anderen (A15).

**Nicht geprüft in Teil 3**
- Ob Basti mit dem neuen Ablauf zurechtkommt. Die Tests zeigen, dass der Weg funktioniert und nichts hängen bleibt, nicht, dass er sich gut anfühlt.
- Windows, echte GPU, echte Maus: alles lief auf llvmpipe unter xvfb und headless.
- Rahmenauswahl mit der Maus und Strg+Klick gibt es nicht (nur Klick, Umschalt+Klick, Alle/Keine).
- Der Kegel über der Auswahl ist in den Bildern nicht zu sehen (vermutlich hinter dem Schild); Ring und Rahmen sind es.
- Fuhrhof-Umzug mit dem Firmensitz ist nur in der Sim getestet, nicht in der Oberfläche.
- Schwierigkeit: siehe oben, nur der Depotpreis ist nachgezogen.

**Abweichungen vom Vorbild** (Begründung im Entscheidungslog): Keine simulierte Rückfahrt ins Depot („Ins Depot“ wirkt sofort, die Ladung verfällt), weil der Sim-Kern ein Linienfahrzeug nicht mitten auf der Route umleiten kann. Der Fuhrhof ist geschenkt, damit Minute 1 keine Hürde hat.

Bilder: `demo_shots/20` Auswahl mit Ring · `21` Banner „Halte anklicken“ · `22` Linie ohne Fahrzeug · `23` Depot mit Mehrfachauswahl · `24` Reiter Fahrzeuge · `25` Reiter Linien · `26` Linie in der Welt · `27` Reiter Depots · `18` Reiter Strecken · `17` Depot in der Welt · `10` Ersetzen in der Fahrzeugliste · `bau/` Straßenbau-Befund.

## 1 Was die Demo kann
| Wunsch | Stand | Wo |
|---|---|---|
| 1 Ketten verknüpft | 3 Ketten, 8 Güter, 9 Betriebe, 2 Orte. Getreide → Mehl; Holz → Bretter; Kohle + Erz → Eisen → Werkzeug. Jedes Gut hat Quelle und Abnehmer (Validator, 0 Verstöße) | `data/demo_welt.json`, `economy.apply_demo` |
| 2 Straße und Gleis bauen | Linienzug aus Klickpunkten, rastet an Netzknoten, Betrieben und Bahnhöfen ein; Vorschau mit Länge, Preis, Brücke; 14 Fehlerfälle mit Text. Vier Betriebe liegen abseits: ohne Bauen keine Kette. Gleis ab 1824, Züge fahren nur auf Gleis | `demo_sim.gd` (bau_angebot, bauen), `ui_demo.gd` |
| 3 Fahrzeug-Generationen | Fuhrwerk 1820 → Planwagen 1822 → Frachtwagen 1826; Pferdebahn 1824 → Dampfzug 1828. Ersetzen behält Linie und Ladung, zeigt Restwert, Preis, Ladung, Unterhalt (+ % durch Alter) | `demo_welt.json` fahrzeuge |
| 4 Verträge | Angebot alle 2 min (Ort oder Betrieb, Gut, Menge, Frist, Prämie, Strafe, jeder dritte mit +20 % Preisbonus), annehmen/ablehnen, Fortschrittsbalken, Ruf verändert Prämien | Taste V |
| 5 Firmensitz | frei platzierbar in Erlenbach, Lindenfurt, Hasenwinkel; Vorschau: Betriebe im Radius, Lizenzpreis je Betrieb, Heimatbonus. 3 Stufen, 3 Anbauten, Umzug | Taste H |
| 6 Skilltree | 3 Äste × 5 Knoten, Punkte nur aus 14 Meilensteinen, Respec frei; jede Wirkung gegen den Spielwert getestet | Taste K |
| Dazu | Startbild mit 6 Schritten, Zeile „Jetzt möglich“, Esc-Abfrage, Bilanzkarte bei Minute 30, kompakte Linienliste | |

Bilder: `demo_shots/01` bis `27` (xvfb, llvmpipe, 1600 × 900), alle am 11.11. neu aufgenommen.

## 1b Erweiterung (Punkte 7–11), Stand 10.11.
Zeilen 7 und 9 sind durch Abschnitt 0 ersetzt (Fuhrpark und Linienplaner gibt es nicht mehr, Depotrabatt entfällt).
| Wunsch | Stand | Wo |
|---|---|---|
| 7 Fahrzeugmanagement, Depots | Fuhrpark (Taste U): Liste aller Fahrzeuge mit Linie, Zustand, Alter, Unterhalt (+ % durch Alter), Restwert; Karte, Überholen, Verkaufen (Restwert W20) je Zeile. Depots (Betriebshof an der Straße, Lokschuppen am Gleis): Kauf im Depot 8 % billiger, Überholung, Liste der versorgten Fahrzeuge | `demo_sim.gd` Teil 2, `ui_demo.gd` |
| 8 Strecken kaufen/verkaufen | Reiter „Strecken“: eigene Trassen mit Länge, Unterhalt, Nutzung; Verkauf (Abbau, 50 % zurück, gesperrt solange befahren). Staatschaussee: Chausseegeld 15 ¢/Feld, kaufbar für 2.800 $ (dann mautfrei, Unterhalt), wieder verkaufbar | |
| 9 Routenplanung | Linienplaner (Taste L): Modell wählen, Halte in der Welt anklicken, 2–8 Halte, Reihenfolge ändern, Halt dazu/weg, Ladeauftrag je Halt (voll / mitnehmen / nur abladen), Fahrzeuge kaufen und zwischen Linien umsetzen | |
| 10 Stadtverkehr | 5 Haltestellen (Erlenbach Ostend, Kirchgasse; Lindenfurt Tor, Hintergasse; Hasenwinkel) plus die beiden Orte; Fahrgäste entstehen aus Einwohnern. Stadtkutsche 1820, Pferdeomnibus 1825, Pferdestraßenbahn 1824 (auf Gleis) | `demo_welt.json` personen |
| 11 Güter- und Personenzüge | Güter: Pferdebahn 1824, Güterzug (Dampf) 1828. Personen: Pferdestraßenbahn 1824, Personenzug (Dampf, 80 Plätze) 1828. Fracht wird geprüft (Personenwagen nur an Orten/Haltestellen, Güterwagen nur ab Betrieben) | |

## 2 Gemessen am 10.11., vor Teil 3 (aktuelle Zahlen: Abschnitt 0)
**Demo-Bot `tests/demo_bot.gd`, Strategie plan, 30 Spielminuten, k = 8, Satz k8d, n = 40 (Seeds 1–40), Endstand mit allen elf Punkten:**
| Größe | Wert |
|---|---|
| Bankrott | 0/40 |
| 60-s-Fenster ohne bezahlbare Aktion | 0 (Summe über alle Läufe) |
| längste Zeit ohne Angebot | P50 5 s, Max 10 s |
| dasselbe ohne „Fahrzeug nachkaufen“ und „Ersetzen“ (strenge Lesart) | P50 5 s, Max 10 s |
| verschiedene Aktionsarten zugleich im Angebot | Mittel 6,6 (6,1–7,4) |
| ausgeführte Aktionen je Lauf | P50 81 (53–104): Skill 13,2 · Lizenz 8,9 · Fahrzeug 21,5 · Vertrag 8,7 · Ersetzen 7,0 · Gleis 3 · Zug 3 · Personenzug 1 · Linienplan 2 · Depot 2 · Kauf im Depot 1 · Verkauf 1 · Straße 2 · Firma 2,0 · Werksausbau 1,9 · HQ-Anbau 1,7 · HQ-Ausbau 0,8 · Streckenkauf 0,1 |
| **Erweiterung vollständig** (Linie mit 3 Halten befahren, Kauf im Depot, Verkauf, Personenzug, Güterzug, Stadtverkehr mit Fahrgästen) | **40/40 Läufe** |
| Fahrgäste befördert | P50 799 (734–907) |
| Meilensteine erreicht | P50 13 von 14 (min 11) |
| Meilenstein-Minuten P50 | Firmensitz 0,2 · Mehl 1,4 · Fahrgäste 3,7 · Vertrag 3,9 · Linie mit 3 Halten 4,8 · Straße 6,0 · Bretter 7,7 · 3 Verträge 11,9 · 1.500 $/min 12,0 · Werk 13,4 (37/40) · Zug 15,0 · Werkzeug 21,3 (39/40) · Dampf 26,4 (21/40) · Handelshaus 27,5 (27/40) |
| Verträge | erfüllt P50 7 (4–11), verfehlt P50 0 (max 1) |
| Generationswechsel | 7 Freischaltungen je Lauf (Minute 6, 12, 12, 15, 18, 24, 24); ersetzt P50 6 Fahrzeuge (1–16) |
| Kasse Minute 30 | P50 2.510 $ (923–9.142) |
| Ertrag letzte Minute | P50 5.293 $ (1.762–10.338) |
| Sim-Fehler (`ps.fehler`), API-Ablehnungen | 0, 0 |
| Determinismus (Seed zweimal) | gleich (Zeile und Prüfsumme) |
| Laufzeit | 211 s für 41 Läufe |

Der Bot überholt kein Fahrzeug (er ersetzt vorher) und verkauft keine Strecke; Streckenkauf nur in 3 von 40 Läufen. Diese drei Wege sind durch Tests belegt (M12, M15–M17, V9), nicht durch den Bot.
Strategie „faul“ (nur Kette 1), n = 20, Stand vor der Erweiterung: Bankrott 0/20, Angebotslücke max 5 s, Kasse P50 12.617 $.
Rohdaten: `demo_messung/demo_bot_plan_n40.csv`, `demo_bot_faul_n20.csv`.

**Tests:** `demo_sim_test` 81/81 (B Ketten, C Bauen, D Firmensitz/Skills/Verträge, E Fahrzeuge, **M1–M21** Fahrgäste, Linienpläne, Depots, Strecken, Güter- und Personenzüge, P Parität). `demo_ui_test` 44/44 (Anzeige = Spielwert, 44 Fehlercodes mit Text, echter Tasten- und Mausweg, alle 16 Stationspanels, **V1–V10** Linienplaner, Fuhrpark, Depot, Strecken, Personenzug).

## 3 Abnahme A–H und Ergänzung
| | Kriterium | Ergebnis |
|---|---|---|
| A | 30-min-Bot, Aktion in jedem Fenster, kein Bankrott, 0 stille Fehler, n ≥ 20 | **erfüllt**, n = 40 |
| B | Ketten-Validator, 0 Verstöße | **erfüllt** (B1–B4: 8 Güter, 9 Betriebe, 12 Kanten, 2 davon zusätzlich per Gleis) |
| C | Straße und Gleis bauen, anschließen, befahren; klare Fehler | **erfüllt** (C1–C18) |
| D | Verträge, HQ, Skilltree: Tests, Bot nutzt alle drei, Prüfsumme | **erfüllt** (D1–D28, P1) |
| E | ≥ 2 Generationswechsel, Ersetzen-Angebot, Kosten/Kapazität/Verschleiß sichtbar | **erfüllt** (E1–E7, U24–U25) |
| F | regress_fast < 300 s grün, d07 voll grün, d08 md5 | **erfüllt** (Endstand): regress_fast GRÜN 196 s, d07 GRÜN 802 s (43 Zeilen), d08 `--n=20` md5 5cce648a53c1c2f3246147abcaca0988 unverändert |
| G | Screenshots der Schlüsselmomente | **erfüllt** (19 Bilder; 14 Linienplaner, 15 Stadtverkehr, 16 Fahrzeugliste, 17 Depot, 18 Strecken, 19 Personenzug) |
| H | Startskripte, Startbild, Anleitung | **erfüllt, Windows-Start ungetestet** |
| + | Bot: Mehrpunkt-Linie anlegen und befahren, im Depot kaufen und verkaufen, Personenzug und Güterzug, Stadtverkehr | **erfüllt**, 40/40 Läufe |

## 4 Nicht geprüft
- **Spielgefühl.** Der Bot zählt, ob eine Aktion verfügbar und bezahlbar ist. Ob sie sich lohnt, ob Bauen sich gut anfühlt, ob 30 Minuten tragen, weiß nur Basti. Der Bot wartet wegen seiner Reserve (800 $) bis zu 240 s zwischen zwei eigenen Aktionen (P50 150 s), obwohl etwas im Angebot war.
- **GPU und Bildrate auf Bastis Rechner.** Alles lief auf llvmpipe. Jede gebaute Trasse ist ein eigenes Mesh, ein Gleis drei.
- **Windows:** `.bat`, Schriftbild, Maus/Tastatur auf echtem Fenster.
- **Menschen-Klicks im Baumodus** (Einrasten, Kamera schwenken während des Bauens). Getestet ist der Weg Taste → Klick → Geländepunkt (Abweichung 0,0 m), nicht die Bedienbarkeit.
- **Schwierigkeit.** Die Demo-Ökonomie ist gesetzt, nicht kalibriert (siehe 5).
- Easing-Tests (proto_easing_test) decken Züge nicht ab.

## 5 Bekannte Schwächen
1. **Wenig Druck.** Wer nur Kette 1 fährt, hat nach 30 min 12.600 $ (faul-Bot). Die Demo ist auf „alles ausprobieren können“ gesetzt, nicht auf Knappheit.
2. **Züge blockieren sich nicht** (keine Signale, keine Weichenlogik). Mehrere Züge fahren durcheinander hindurch.
3. **Trassen prüfen nur Wasser, See, Steigung, Knick.** Sie können durch Häuser, Felder und Bäume laufen; Abreißen gibt es nicht. Gebaute Straßen enden stumpf am Netzknoten (kein Kreuzungsstück).
4. **Platzhalter:** Forsthaus, Gruben, Hütte, Bahnhof und Firmensitz aus vorhandenen Bausteinen; Pferdebahn nutzt das Fuhrwerk-Modell; Schilder der neuen Betriebe ohne Icon.
5. **Vertragsangebote** können Güter betreffen, die der Spieler noch nicht fährt (ab der Minute, ab der das Gut erreichbar ist). Ablehnen kostet nichts.
6. **Jahre im Zeitraffer** (Pferdebahn 1824, Dampfzug 1828): historisch falsch.
7. **Kein Speichern.** Esc fragt nach, mehr nicht.
8. „Nächster Schritt“ nennt den ersten offenen Meilenstein in Listenreihenfolge, nicht den naheliegendsten.
9. **Linienpläne:** Eine Planänderung setzt alle Fahrzeuge der Linie an den ersten Halt (Ladung verfällt). Fahrgäste steigen am nächsten Halt aus, der sie annimmt; es gibt keine Wunschziele.
10. **Stadtverkehr trägt sich innerorts nur knapp** (kurze Wege, 6-Felder-Mindestdistanz). Lohnend wird Personenverkehr zwischen den Orten und per Zug.
11. **Depot:** Fahrzeuge rücken physisch aus, fahren aber nicht physisch zurück („Ins Depot“ wirkt sofort).
12. **Streckenkauf** gibt es nur für die Staatschaussee (kein anderer Besitzer in der Welt). Verkaufte Trassen verschwinden, das Gelände bleibt unverändert.
13. Haltestellen und Depots sind Platzhalter (Pfosten, Schuppen); Stadtkutsche und Omnibus nutzen das Postkutschen-Modell, die Pferdestraßenbahn das Fuhrwerk-Modell.
14. Offene S8-Punkte unverändert: Wagenrad-Rotation bei k > 1, GPU-Frametime, Naiv-Band.

## 6 Entscheidungen für Basti
1. **Tempo:** Die Demo fährt k = 8. Passt das Fahrtempo, oder k = 6 bzw. 4 (dann neuer Satz nötig)?
2. **Ökonomie:** großzügig wie jetzt (alles in 30 min erreichbar) oder knapper (k8d-Kosten)?
3. **Zeit:** Zeitraffer-Jahre behalten, oder kürzere Jahre bzw. längere Partie, damit Gleis 1835 historisch stimmt?
4. **Übernahme:** Sollen Bauen, Verträge, Firmensitz und Skilltree aus dem Demo-Modus in die Standard-Welt (S9)? Dann fällt W10.
5. **Als Nächstes:** Signale für Züge, Abreißen/Kollision beim Bauen, Speichern oder eigene Modelle: was zuerst?

## 7 Dateien
Neu: `slice/proto/demo_sim.gd`, `slice/proto/ui_demo.gd`, `slice/data/demo_welt.json`, `slice/tests/demo_sim_test.gd`, `demo_ui_test.gd`, `demo_bot.gd`, `tools/play_demo.sh`, `play_demo.bat`, `sprints/s8/umsetzung/DEMO*.md`, `demo_shots/`, `demo_messung/`.
Geändert (Haken, Standardverhalten gleich): `slice/economy.gd`, `slice/proto/proto_sim.gd`, `proto_strassenband.gd`, `prototyp_welt.gd`, `ui_welt.gd`, `slice/start_menu.gd`, `slice/world/proto_prefabs.gd`, `slice/tests/regress_fast.sh`, `d07_regression.sh`.
