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
| 6 Skilltree | 3 Äste × 4 Knoten, Punkte nur aus 12 Meilensteinen, Respec frei; jede Wirkung gegen den Spielwert getestet | Taste K |
| Dazu | Startbild mit 6 Schritten, Zeile „Jetzt möglich“, Esc-Abfrage, Bilanzkarte bei Minute 30, kompakte Linienliste | |

Bilder: `demo_shots/01` bis `13` (headless, llvmpipe, 1600 × 900).

## 2 Gemessen (Sandbox, 2 vCPU, headless)
**Demo-Bot `tests/demo_bot.gd`, Strategie plan, 30 Spielminuten, k = 8, Satz k8d, n = 40 (Seeds 1–40):**
| Größe | Wert |
|---|---|
| Bankrott | 0/40 |
| 60-s-Fenster ohne bezahlbare Aktion | 0 (Summe über alle Läufe) |
| längste Zeit ohne Angebot | P50 5 s, Max 30 s |
| dasselbe ohne „Fahrzeug nachkaufen“ und „Ersetzen“ (strenge Lesart) | P50 35 s, Max 60 s |
| verschiedene Aktionsarten zugleich im Angebot | Mittel 5,1 (4,6–5,8) |
| ausgeführte Aktionen je Lauf | P50 74 (60–94): Skill 11,8 · Lizenz 9 · Fahrzeug 21,8 · Vertrag 8,7 · Ersetzen 8,9 · Straße 2 · Gleis 2 · Zug 3 · Firma 2,4 · Werksausbau 2,3 · HQ-Anbau 2,1 · HQ-Ausbau 1,1 |
| Meilensteine erreicht | P50 12 von 12 (min 10) |
| Meilenstein-Minuten P50 | Firmensitz 0,2 · Mehl 1,4 · Vertrag 3,9 · Straße 6,0 · Bretter 7,7 · 3 Verträge 11,9 · Werk 12,6 · 1.500 $/min 13,0 · Zug 14,9 · Werkzeug 21,4 · Handelshaus 25,6 (35/40) · Dampf 25,6 (34/40) |
| Verträge | erfüllt P50 7 (4–12), verfehlt P50 0 (max 1) |
| Generationswechsel | 4 in jedem Lauf (Minute 6, 12, 18, 24); ersetzt P50 8 Fahrzeuge (1–20) |
| Kasse Minute 30 | P50 2.387 $ (633–15.631) |
| Ertrag letzte Minute | P50 5.593 $ (1.527–9.727) |
| Sim-Fehler (`ps.fehler`), API-Ablehnungen | 0, 0 |
| Determinismus (Seed zweimal) | gleich (Zeile und Prüfsumme) |
| Laufzeit | 150 s für 41 Läufe |

Strategie „faul“ (nur Kette 1, nichts sonst), n = 20: Bankrott 0/20, Angebotslücke max 5 s, im Mittel 6,8 Aktionsarten im Angebot, Kasse P50 12.617 $.
Rohdaten: `demo_messung/demo_bot_plan_n40.csv`, `demo_bot_faul_n20.csv`.

**Tests:** `demo_sim_test` 60/60 (B0–B4 Ketten, C1–C18 Bauen, D1–D28 Firmensitz/Skills/Verträge, E1–E7 Fahrzeuge, P1–P2 Parität). `demo_ui_test` 34/34 (Anzeige = Spielwert, 26 Fehlercodes mit Text, echter Tasten- und Mausweg, alle 11 Stationspanels).

**Regression:** siehe Abschnitt 3 F.

## 3 Abnahme A–H
| | Kriterium | Ergebnis |
|---|---|---|
| A | 30-min-Bot, Aktion in jedem Fenster, kein Bankrott, 0 stille Fehler, n ≥ 20 | **erfüllt**, n = 40 (Tabelle oben) |
| B | Ketten-Validator, 0 Verstöße | **erfüllt** (B1–B4: 8 Güter, 9 Betriebe, 12 Kanten, 2 davon zusätzlich per Gleis) |
| C | Straße und Gleis bauen, anschließen, befahren; klare Fehler | **erfüllt** (C1–C18; Fuhrwerk auf eigener Straße, Pferdebahn auf eigenem Gleis, Brücke über die Rotach) |
| D | Verträge, HQ, Skilltree: Tests, Bot nutzt alle drei, Prüfsumme | **erfüllt** (D1–D28, Bot siehe oben, P1) |
| E | ≥ 2 Generationswechsel, Ersetzen-Angebot, Kosten/Kapazität/Verschleiß sichtbar | **erfüllt** (E1–E7, U24–U25) |
| F | regress_fast < 300 s grün, d07 voll grün, d08 md5 | **erfüllt** für Stand Punkte 1–6: regress_fast GRÜN 184 s, d07 GRÜN 771 s (43 Zeilen), d08 `--n=20` md5 5cce648a53c1c2f3246147abcaca0988 |
| G | Screenshots der Schlüsselmomente | **erfüllt** (13 Bilder) |
| H | Startskripte, Startbild, Anleitung | **erfüllt, Windows-Start ungetestet** (`play_demo.bat` lief auf keinem Windows) |

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
9. Offene S8-Punkte unverändert: Wagenrad-Rotation bei k > 1, GPU-Frametime, Naiv-Band.

## 6 Entscheidungen für Basti
1. **Tempo:** Die Demo fährt k = 8. Passt das Fahrtempo, oder k = 6 bzw. 4 (dann neuer Satz nötig)?
2. **Ökonomie:** großzügig wie jetzt (alles in 30 min erreichbar) oder knapper (k8d-Kosten)?
3. **Zeit:** Zeitraffer-Jahre behalten, oder kürzere Jahre bzw. längere Partie, damit Gleis 1835 historisch stimmt?
4. **Übernahme:** Sollen Bauen, Verträge, Firmensitz und Skilltree aus dem Demo-Modus in die Standard-Welt (S9)? Dann fällt W10.
5. **Als Nächstes:** Signale für Züge, Abreißen/Kollision beim Bauen, Speichern oder eigene Modelle: was zuerst?

## 7 Dateien
Neu: `slice/proto/demo_sim.gd`, `slice/proto/ui_demo.gd`, `slice/data/demo_welt.json`, `slice/tests/demo_sim_test.gd`, `demo_ui_test.gd`, `demo_bot.gd`, `tools/play_demo.sh`, `play_demo.bat`, `sprints/s8/umsetzung/DEMO*.md`, `demo_shots/`, `demo_messung/`.
Geändert (Haken, Standardverhalten gleich): `slice/economy.gd`, `slice/proto/proto_sim.gd`, `proto_strassenband.gd`, `prototyp_welt.gd`, `ui_welt.gd`, `slice/start_menu.gd`, `slice/world/proto_prefabs.gd`, `slice/tests/regress_fast.sh`, `d07_regression.sh`.
