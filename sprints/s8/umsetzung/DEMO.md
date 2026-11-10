# DEMO: 30-Minuten-Demo Mega Tycoon (Bericht des Demo-Sprints, 10.11.2026)

Branch `s8-demo` (gemergt nach `s8`). Start: `play_demo.bat` (Windows), `tools/play_demo.sh`, oder Startmenü „Demo spielen“ (Taste D). Anleitung: `DEMO_ANLEITUNG.md`. Plan: `DEMO_PLAN.md`.

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

Bilder: `demo_shots/01` bis `19` (headless, llvmpipe, 1600 × 900).

## 1b Erweiterung (Punkte 7–11)
| Wunsch | Stand | Wo |
|---|---|---|
| 7 Fahrzeugmanagement, Depots | Fuhrpark (Taste U): Liste aller Fahrzeuge mit Linie, Zustand, Alter, Unterhalt (+ % durch Alter), Restwert; Karte, Überholen, Verkaufen (Restwert W20) je Zeile. Depots (Betriebshof an der Straße, Lokschuppen am Gleis): Kauf im Depot 8 % billiger, Überholung, Liste der versorgten Fahrzeuge | `demo_sim.gd` Teil 2, `ui_demo.gd` |
| 8 Strecken kaufen/verkaufen | Reiter „Strecken“: eigene Trassen mit Länge, Unterhalt, Nutzung; Verkauf (Abbau, 50 % zurück, gesperrt solange befahren). Staatschaussee: Chausseegeld 15 ¢/Feld, kaufbar für 2.800 $ (dann mautfrei, Unterhalt), wieder verkaufbar | |
| 9 Routenplanung | Linienplaner (Taste L): Modell wählen, Halte in der Welt anklicken, 2–8 Halte, Reihenfolge ändern, Halt dazu/weg, Ladeauftrag je Halt (voll / mitnehmen / nur abladen), Fahrzeuge kaufen und zwischen Linien umsetzen | |
| 10 Stadtverkehr | 5 Haltestellen (Erlenbach Ostend, Kirchgasse; Lindenfurt Tor, Hintergasse; Hasenwinkel) plus die beiden Orte; Fahrgäste entstehen aus Einwohnern. Stadtkutsche 1820, Pferdeomnibus 1825, Pferdestraßenbahn 1824 (auf Gleis) | `demo_welt.json` personen |
| 11 Güter- und Personenzüge | Güter: Pferdebahn 1824, Güterzug (Dampf) 1828. Personen: Pferdestraßenbahn 1824, Personenzug (Dampf, 80 Plätze) 1828. Fracht wird geprüft (Personenwagen nur an Orten/Haltestellen, Güterwagen nur ab Betrieben) | |

## 2 Gemessen (Sandbox, 2 vCPU, headless)
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
11. **Depot** ist ein Punkt im Netz mit Rabatt und Überholung; Fahrzeuge fahren nicht physisch ins Depot.
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
