# A-09 Unser Unterschied: HQ-Start und Lizenz→Kauf-Leiter (Aylin Kaya)

**Stand:** Entwurf, 7 Screens. Beispiel durchgängig **Agrar / Kornfeld** (Zahlen Tobias `t05_final.md`, `uebergabe_lena.md`; Modellrechnung, nichts gemessen). Je Archetyp tauschen nur die Zahlen (Tabelle am Ende).
**Abgleich Lena L-08:** `/tmp/claude-0/gd/sprint3/day4-7/lena/l08_slice_regeln.md` existiert noch nicht. Alles mit **[ANNAHME L-08]** übernehme ich aus Lenas Sprint-2-Dateien (`hq_startwerte.md`, `l05_material.md`) und gleiche ab, sobald L-08 liegt.
**Standard (D15), nicht neu erfunden:** Karte/Kamera, Panel-Layout, Kontextdialog (siehe A-07), Geld oben rechts, Benachrichtigungsliste wie OpenTTD/TF2. Dieser Flow beschreibt nur: HQ-Wahl, Lizenz, Timer, Kaufangebot, Anrechnung, Ausbau.

## Gemeinsame UI-Regeln
- Geld immer sichtbar (HUD oben rechts, `Label`), Kredit daneben: „Kredit 0 / 2.000 $“ (D1; Zins 1 %/min; Firmenkauf, Ausbau, HQ-Ausbau nur aus Guthaben).
- Status = Form + Text (● läuft, ▲ Achtung, ■ steht).
- Preise im Button („Lizenz kaufen 140 $“). Gesperrter Button zeigt den Grund als Tooltip und als Zeile darunter, nie stumm grau.
- Alle Panels: `PanelContainer` mit `MarginContainer` (16 px) → `VBoxContainer`. Aktionsleiste unten als `HBoxContainer`. Theme-Typen: `PanelDialog`, `ButtonPrimary`, `ButtonSecondary`, `LabelMuted`.

## Flow
S1 HQ setzen → S2 Lizenz → S3 Lieferung + Timer → S4 Kaufangebot → S5 Kauf → S6 Eigentum + Belohnung → S7 Ausbau

---
## S1 HQ-Platzierung mit Archetyp-Vorschau
**Zweck:** Spieler wählt Stadt (Archetyp) und setzt das HQ. Entscheidung 1, vor Minute 0: *Welche Stadt, welche Kette.*
**Sichtbar:** Karte mit 4 markierten Städten; rechts Vorschau-Panel der gewählten Stadt:
```
+-------------------------------+
| Kornfeld  (Agrar)             |
| Dorf, 900 Einw.  Fluss/Ebene  |
|-------------------------------|
| Start:  4.500 $               |
| Ketten: Getreidefarm > Mühle  |
|         (+ Viehhof im Radius) |
| Bedarf Stadt: 9 E/min         |
| Erste Kette: ca. 844 $/min    |
| Ziel: erste Gewinnkette 6 min |
| Stärke: schnell, klein        |
| Schwäche: Stadt zu klein      |
|-------------------------------|
|  [HQ hier setzen 0 $]  [Zurück]|
+-------------------------------+
```
**Zahlen:** Start 4.500 / 4.500 / 7.000 / 5.000 $; Einkommen 844 / 627 / 806 / 399 $/min (Tobias); Zielzeit 6 / 8 / 10 / 8 min **[ANNAHME L-08, Setzung Lena]**; Stärke/Schwäche-Texte: Lena (hq.md, Ausgleich nicht belegt, daher nur qualitativ).
**Aktionen:** Stadt klicken (Vorschau wechselt), „HQ hier setzen“, Hover Industrie zeigt Name.
**Godot:** `Control`(Full Rect) → `MapView` (Standardkarte) + `PanelContainer`(Anker rechts, 320 px) → `VBoxContainer`: `Label`(Titel), `Label`(Untertitel), `HSeparator`, `GridContainer`(2 Spalten, Schlüssel/Wert), `RichTextLabel`(Stärke/Schwäche), `HBoxContainer`(`Button` primär, `Button` sekundär). Vier Stadtmarker `TextureButton` mit Signal `pressed(city_id)`.
**Texte:** Titel „Wo startest du?“ · Button „HQ hier setzen“ · Hinweis „Das HQ kostet nichts. Kapital und Kette hängen an der Stadt.“

## S2 Erste Lizenz im Kontextdialog einer Fabrik
**Zweck:** Spieler erwirbt die erste Lizenz und versteht: Lizenz = leihen, Kauf kommt später. Entscheidung 2, Minute 0–2: *Welche Firmen lizenziere ich.*
**Sichtbar:** Kontextdialog Mühle (Feldliste A-07), Lizenzblock hervorgehoben:
```
+-------------------------------+
| Mühle, Stufe 1                |
| Status  ■ ohne Lizenz         |
| Produktion 20 E/min Mehl      |
|-------------------------------|
| LIZENZ                        |
|  Leihen: 140 $ / 30 min       |
|  (im Radius -30 % schon drin) |
|  Kaufen: 2.000 $              |
|   gesperrt: erst nach 10 min  |
|   Lieferung, dann Angebot     |
|-------------------------------|
| [Lizenz kaufen 140 $]         |
+-------------------------------+
```
Daneben Getreidefarm: „Gratis-Lizenz 30 min“ **[ANNAHME L-08: Gratis auf der Nicht-Ziel-Firma, hier Getreidefarm; Tobias nennt „eine Nicht-Ziel-Firma der Startkette“]**.
**Zahlen:** Lizenz 70 / 140 $ (Getreidefarm / Mühle), Kaufpreis 1.000 / 2.000 $, Laufzeit 30 Spielminuten, Auto-Verlängerung zum gleichen Preis. Startpaket Straße + 2 Lkw 1.367 $. Kontostand danach: 4.500 − 140 = 4.360 $ (vor Startpaket).
**Aktionen:** „Lizenz kaufen“ (aktiv), „Firma kaufen“ (gesperrt, Grund sichtbar, D12), „Linie anlegen“ (aktiv nach Lizenz).
**Godot:** Dialog aus A-07; Lizenzblock `PanelContainer` mit `StyleBoxFlat` (Akzentrahmen) → `VBoxContainer`: `Label`, `Label` (Leihen), `Label` (Kaufen), `Label`(LabelMuted, Sperrgrund). `Button.disabled = true` plus `tooltip_text` mit Sperrgrund.
**Texte:** „Leihen: 140 $ für 30 Min.“ · „Kaufen ab Angebot“ · Sperrgrund „Erst 10 Min. Lieferung, dann bekommst du ein Angebot.“

## S3 Lieferung läuft, Lizenz-Timer
**Zweck:** Zeigt, dass die Kette Geld bringt (Meilenstein 3) und wie lange die Lizenz noch läuft. Entscheidung 3, Minute 3–15: *Lizenz verlängern lassen, zweite Linie bauen oder warten.*
**Sichtbar:** HUD-Leiste links unten „Lizenzen“ (Restzeit je Firma), Einkommen oben.
```
+--------------------------------------+
| Lizenzen                             |
| Mühle        ● 22:10 [=====>----]    |
| Getreidefarm ● 22:10 [=====>----]    |
|--------------------------------------|
| Kette Kornfeld   ● läuft  +844 $/min |
| Angebot in 6:30 Min. (Lieferung)     |
+--------------------------------------+
```
Zustand **Ablauf:** unter 5 Min. Restzeit wechselt ● zu ▲, Text „läuft in 4:10 ab, verlängert 140 $“ (Auto-Verlängerung, Kreditrahmen erlaubt, siehe Tobias).
**Zahlen:** Einkommen 844 $/min (Modell ohne Bauzeit, im Spiel niedriger bis Linie voll); Gate „10 Spielminuten profitabel beliefert“ **[ANNAHME L-08, Lenas Setzung, Tobias: nicht gerechnet]**. Break-even Kauf vs. Lizenz Agrar ab Minute 17 (18 mit KI-Teilung), das steht **nicht** auf dem Screen, es steckt im Angebot (S4).
**Aktionen:** Klick Zeile öffnet Industriedialog (A-07), Schalter „Auto-Verlängerung“ je Lizenz an/aus (Standard an) **[ANNAHME L-08]**.
**Godot:** `PanelContainer`(Anker unten links) → `VBoxContainer` → je Lizenz `HBoxContainer`: `Label`(Statusform), `Label`(Name), `ProgressBar`(`show_percentage=false`, `max_value`=1800 s, `value`=Rest), `Label`(Zeit). Timer-Anzeige per `Timer`-Node 1 s (Spielzeit, nicht Echtzeit). Angebotshinweis `Label`.
**Texte:** „Lizenzen“ · „Angebot in 6:30 Min.“ · „Läuft in 4:10 ab, verlängert 140 $“.

## S4 Kaufangebot mit Anrechnung und Nutzenangabe
**Zweck:** Das Spiel macht das Angebot, der Spieler erkennt Preis, Anrechnung und Gewinn. Entscheidung 4, ab Minute ca. 13 (nach 10 Min. profitabler Lieferung): *Kaufen, später, weiter leihen.* Zielwert: Entscheidung ≤3 Min. nach Einblendung (A-09-Kriterium).
**Sichtbar:** Toast oben „Angebot: Mühle kaufen“, Klick öffnet Dialog:
```
+---------------------------------+
| Angebot: Mühle kaufen           |
|---------------------------------|
| Preis                 2.000 $   |
| Angerechnet (50 %    - 70 $     |
|  deiner Gebühren: 140 $)        |
| Du zahlst             1.930 $   |
|---------------------------------|
| Danach gehört sie dir:          |
|  + keine Lizenzgebühr (140/30m) |
|  + Mehrertrag ca. +50 $/min     |
|  + niemand kann sie mitnutzen   |
|  - Unterhalt 20 $/min           |
|---------------------------------|
| Dein Geld: 3.100 $  >  1.170 $  |
| [Kaufen 1.930 $] [Später] [Leihen]|
+---------------------------------+
```
**Zahlen:** Preis 2.000 $; Anrechnung 50 % aller bisher gezahlten Gebühren dieser Firma (Tobias): nach 1 Laufzeit 70 $, Netto 1.930 $ (1,035 × Kaufpreis inkl. Gebühr); **kein Rabatt beim ersten Kauf**, Belohnung −20 % erst ab M5b (S6). Mehrertrag Agrar +250 $/Takt = +50 $/min (Lena `l05_material`, Tarifkarte geteilt→Besitz). Unterhalt 20 $/min × Stufe, Werksmarge 15 % auf eigenen Transportertrag (Tobias). Beispielkonto 3.100 $ ist illustrativ.
**Offen (Tobias/Lena):** Ob der Mehrertrag +50 $/min vor oder nach Unterhalt 20 $/min gilt, ist nicht geklärt; ich zeige beide Zahlen getrennt und rechne **keinen** Nettowert. Die Amortisation (Netto 1.930 $ bei +50 $/min wäre sehr lang) sagt der Screen nicht, das ist eine Designfrage für Lena (Sprint-2-Befund: Kauf lohnt über wegfallende Gebühr und Exklusivität, nicht über Rendite).
**Aktionen:** „Kaufen“ (aktiv, wenn Guthaben ≥ Netto; Kredit zählt nicht), „Später“ (Angebot bleibt in der Benachrichtigungsliste), „Leihen“ (verlängert Lizenz).
**Godot:** `Window`/`PopupPanel` (modal nein, Spiel läuft weiter, Pause optional per Schalter) → `VBoxContainer`: `Label`(Titel), `GridContainer`(2 Sp.: Preis, Anrechnung, Du zahlst, fett), `HSeparator`, `RichTextLabel`(Nutzenliste, + / - als Symbole), `Label`(Kontostand vorher > nachher), `HBoxContainer`(3 `Button`). Toast `PanelContainer` oben mit `Button`.
**Texte:** „Du zahlst 1.930 $“ · „Danach gehört sie dir“ · „Später“ · Gesperrt: „Dir fehlen 830 $. Kredit gilt nicht für Käufe.“

## S5 Kauf
**Zweck:** Bestätigung und sichtbare Folge, damit der Kauf als Entscheidung statt Zufallsklick empfunden wird. Entscheidung 5: *Sicher kaufen.*
**Sichtbar:** Ein Klick kauft (kein zweiter Bestätigungsdialog, Standard wie OpenTTD). Kurzes Feedback 3 s:
```
+---------------------------------+
| Mühle gehört dir                |
| -1.930 $    Konto 1.170 $       |
| Lizenz endet. Gebühr entfällt.  |
|            [Mühle ansehen]      |
+---------------------------------+
```
**Fehlerzustand** Guthaben < 1.930 $: Button gesperrt wie in S4, Zeile „Dir fehlen X $“; Kredit-Zeile „Käufe nur mit eigenem Geld“.
**Zahlen:** Abbuchung 1.930 $, Lizenz der Mühle endet sofort, Getreidefarm bleibt lizenziert.
**Aktionen:** „Mühle ansehen“ öffnet Dialog (S6). Sonst nichts.
**Godot:** `PopupPanel` (3 s, `Timer`, ausblendbar per `Tween`), `Label` x3, `Button`. Signal `purchase_confirmed(firm_id, price)`.
**Texte:** „Mühle gehört dir“ · „Gebühr entfällt“.

## S6 Eigentum und Belohnung
**Zweck:** Zeigt den neuen Besitzstatus und die M5b-Belohnung. Entscheidung 6: *Nächsten Kauf, Ausbau oder erst Geld sammeln.*
**Sichtbar:** Industriedialog (A-07) im Zustand Eigentum:
```
+-------------------------------+
| Mühle, Stufe 1                |
| Status   ● läuft              |
| Besitz   Eigentum (seit 14:00)|
| Ertrag   +379 $/min           |
| Unterhalt 20 $/min            |
|-------------------------------|
| Belohnung: -20 % auf den      |
| nächsten Firmenkauf (1 x)     |
|-------------------------------|
| [Ausbau Stufe 2 ...] [Nächste |
|  Firma: Getreidefarm 1.000 $] |
+-------------------------------+
```
**Zahlen:** Ertrag mit Besitz 379 $/min (Lena Tarifkarte Kornfeld, 5 min × 1.900 $ Takt), Rabatt −20 % einmalig (D1, M5b), Beispiel nächste Firma Getreidefarm 1.000 $ → 800 $ [Rechnung 1.000 × 0,8; Anrechnung auf Getreidefarm-Gebühren käme dazu, hier nicht gerechnet].
**Aktionen:** „Ausbau“, „Firma kaufen“ (Rabatt im Preis sichtbar, durchgestrichen 1.000 → 800), „Linie anlegen“.
**Godot:** wie A-07-Dialog; neues `Label` „Besitz“ mit Statusform; Rabatt als `PanelContainer` (Akzentton) mit `Label`. Preisbutton mit `RichTextLabel` (durchgestrichen via `[s]`).
**Texte:** „Eigentum“ · „-20 % auf deinen nächsten Kauf“.

## S7 Ausbau
**Zweck:** Letzte Sprosse der Leiter im Slice: Ausbau der gekauften Firma (und später HQ), das Ziel von M7 „HQ-Stufe 2 nach 35–50 min“ (D13). Entscheidung 7: *Wohin investiere ich zuerst.*
**Sichtbar:** Ausbau-Panel:
```
+-------------------------------+
| Ausbau: Mühle                 |
|  Stufe 1 > Stufe 2            |
|  Produktion 20 > [__] E/min   |
|  Preis       [Preis M1] $     |
|  Nur Eigentum, nur aus Geld   |
|-------------------------------|
| HQ-Stufe 2: [Preis M1] $      |
| [Ausbauen]        [Abbrechen] |
+-------------------------------+
```
**Zahlen: bewusst offen.** Ausbaupfad Stufe 2–4 ist nicht berechnet (D13: Zahl erst M1; Tobias „nicht geliefert“, Lena nannte 2.000 / 6.000 / 15.000 $ ohne Beleg). Im Prototyp Platzhalter aus Datenfeld, Felix liest aus T-06-JSON.
**Aktionen:** „Ausbauen“ (nur Eigentum, Guthaben nötig, kein Kredit), „Abbrechen“.
**Godot:** `PanelContainer` → `GridContainer` (Stufe alt/neu, Werte als `Label`), `Button`. Werte aus `FirmData.upgrade_cost[level]`, Fehlwert zeigt „–“.
**Texte:** „Nur für eigene Firmen“ · Sperrgrund „Dir fehlen X $. Ausbau nutzt keinen Kredit.“

---
## Zahlen je Archetyp (Austausch in S1–S6)
| | Agrar | Hafen | Bergbau | Handel |
|---|---|---|---|---|
| Start | 4.500 | 4.500 | 7.000 | 5.000 |
| Verarbeiter / Lizenz | Mühle 2.000 / 140 | Sägewerk 2.000 / 140 | Stahlwerk 4.000 / 280 | Schlachthof 2.500 / 175 |
| Lizenzen am Start | Farm + Mühle | Holzfäller + Sägewerk | Erz, Kohle, Stahlwerk | Viehhof + Schlachthof |
| Einkommen erste Kette | 844 | 627 | 806 | 399 $/min |
| Kauf lohnt ab (Standard) | 17 min | 22 min | 35 min | 56 min |
| Mehrertrag Besitz | +50 $/min | +40 $/min | +40 $/min | nicht vorhanden |

Hafen/Bergbau Mehrertrag aus Lenas Tarifkarten (+200 $/Takt), Handel hat in den Quellen keinen Wert (Zeile nicht gesehen), deshalb offen. Bergbau knapp: Kapital nach Direktkauf nur 720 $, Kredit relevant.

## Offene Punkte
1. **L-08 fehlt:** Gratis-Lizenz-Ziel, Gate 10 Min., Auto-Verlängerung Standard, Angebot erneut nach „Später“. Bitte Lena bestätigen.
2. **Kaufnutzen:** Mehrertrag +50 $/min gegen Unterhalt 20 $/min und lange Amortisation: der Kauf ist über Zahlen allein schwach. Zeigen wir Exklusivität (S4) prominenter? Entscheid Lena/Tobias.
3. **AK „5 von 6 kaufen ≤3 min“:** nach D16 testet Basti allein, die Quote ist nicht erhebbar. Vorschlag: Basti notiert Zeit Angebot-Einblendung bis Klick bei jeder Runde.
4. Ausbau-Zahlen (D13): M1.
