# AT-14 Loop-Flow-Spezifikation Welt (Aylin, S8 Block A, 05.11.2026)

Ticket AT-14 (= UX-1). Nur Dokument, kein Code. Grundlage: `refinement/ergebnis.md` (§1 Ziele, §4 Tickets, §5 Szenarien, W19–W21), `ux_art.md` (§5), `design.md` (Zahlen), Fehlertexte-Schema `sprints/s7/block-a/fehlertexte.md`. **Abnahme:** jeder Schritt hat ≥ 1 Erfolgs- und ≥ 1 Fehlerweg mit Text; Mira bestätigt die Umsetzbarkeit bis Tag 3 (offene Punkte A1–A7 am Ende).

**Marken:** (i) = nur in Szenario (i) / gekürzt, (ii) = nur mit zweitem UI-Entwickler (ergebnis §5). Ohne Marke gilt es in beiden. `{x}` = Platzhalter aus dem Spielwert (Test gegen den Spielwert). Zahlen in den Wireframes sind Beispiele, keine Spielwerte. **Messart der Messgrößen:** gemessen/gezählt (Test, Bot, Basti-Karte), nicht heute vorhanden, solange nichts anderes dasteht.

## 1 Grundregeln (gelten für alle Schritte)

| # | Regel | Quelle |
|---|---|---|
| G1 | Fehlertexte: **Ursache + Lösung, ≤ 90 Zeichen, Du-Form**, keine Rohcodes. Diagnose-Toast: Titel = Ort (≤ 30 Z.) + Text (≤ 90 Z.) + **eine** Aktion (≤ 20 Z.) | D21, S7-Fehlertexte, A-08 |
| G2 | **Eine Meldung zugleich**, 4–10 s, danach im Protokoll. Warnungen bleiben stehen, bis die Ursache weg ist. Queue statt Überlappung | AT-11 |
| G3 | **Nie stumm.** Jede abgelehnte Aktion zeigt Text. Kaufknöpfe sind bei Geldmangel grau und nennen den Fehlbetrag im Tooltip | U-03 |
| G4 | **Kein Modal.** Bestätigung inline am Knopf, Folgen daneben (D21: keine grauen Modale) | D21 |
| G5 | Tasten: **1–5 bleiben Kamera**, Leertaste Pause, F folgt Fahrzeug, F12 Stelle. Esc schließt zuerst Modus/Panel, erst ohne offenes Panel kommt die Menü-Abfrage (S0) | W25 |
| G6 | Zustand = **Form + Farbe**: Kreis ok `#48E08A`, Dreieck warn `#FFA640`, Quadrat bad `#FF988A`, Saum `#0F1720`. Nie nur Farbe | `status_shape.gd` |
| G7 | Zeitwörter: Zins und Preise **„je Minute“** (Wirtschaftsuhr), Datum und Alter **in Jahren** (Kalender, 3 min = 1 Jahr). Beides nie ohne Einheit | D5, Zwei Uhren |
| G8 | Schrift ≥ 18 px bei 1080p im Fließtext, Platten ≥ 12 px Minimum; Zahlen im Panel = Spielwert | `mt-ux`, Retro |

## 2 Zustandsfluss

```
 [Menü]--Knopf/P-->[S0 Start: 1×, 6.000 $, keine Linie]
                         | Klick Gut Kuppenhof
                         v
                   [S1 Lizenz] --E-1--> [S2 Linie anlegen (+ erstes Fuhrwerk)]
                                              |
                                              v
        +--------------------------> [S4 BETRIEB: Kasse, Netto, Linienliste, Toasts]
        | zurück nach jeder Aktion       |    |       |         |          |
        |                                |    |       |         |          +-Kasse reicht < 90 s-> [S7a Warnung]
        |             Klick "+ Fuhrwerk" |    |       |         |                                      | Kasse < 0
        |                                v    |       |         |                                      v
        +----------------------- [S3 Fuhrwerk]|       |         |                             [S7b Bankrott] -> Neu / Menü
        |                      ab Min 12      v       |         |
        +----------------------- [S4k Kredit]         |         +- Kasse >= Preis -> [S6 Firmenkauf C1 + Werksausbau]
        |                      Fuhrwerk alt           v
        +----------------------- [S5 Ersetzen] <------+
```

## 3 Wireframes (1600 × 900, Beispielwerte)

**W1 Kopfleiste (AT-09) und Nächster Schritt.** Kasse zuerst (wichtigste Zahl, links), Tempo rechts. Kredit-Knopf grau bis Minute 12.
```
+-----------------------------------------------------------------------------------------------+
| Kasse ● 6.000 $ | Netto ▲ −0 $/min | Fix 0 $/min | Kredit — [Kredit]  |  Mai 1820 | [⏸][1×][2×][4×] |
+-----------------------------------------------------------------------------------------------+
| Nächster Schritt: Lizenz für Gut Kuppenhof holen (0 $)                                       |
+-----------------------------------------------------------------------------------------------+
  Warnzustand der Kasse:  ▲ Kasse 420 $ · reicht ~80 s      ■ Kasse 90 $ · reicht ~20 s
```

**W2 Betrieb-Panel (rechts, 360 px), Farm mit Lizenz-Knopf.**
```
+--------------------------------------+
| Gut Kuppenhof         Getreidefarm [x]|
| ● Bestand 10 E     liefert 20 E/min   |
| Lizenz: keine    [Lizenz kaufen 0 $]  |   <- Knopf grau + Fehlbetrag, wenn Kasse fehlt
| ------------------------------------- |
| Abnehmer in Reichweite:               |
|  Erlenmühle  17 Felder (425 m)  ●     |
| [Linie von hier]                      |   <- nach Lizenzkauf ButtonPrimary
+--------------------------------------+
```
Mühle zusätzlich (S6): Zeile `Durchsatz 20 E/min (Werksstufe 1)`, Zeile `Besitz: gehört nicht dir`, Knopf `[Mühle kaufen 1.600 $]` mit Nebenzeile `Lizenzgebühren angerechnet −70 $ · Unterhalt +{u} $/min` (ii: `Amortisation ca. {t} min`).

**W3 Linienvorschau (unten Mitte), erscheint nach Klick auf das Ziel.**
```
+------------------------------------------------------------------+
| Linie: Gut Kuppenhof → Erlenmühle (Getreide)                      |
| Strecke 505 m · Fahrzeit ~14 s · Ertrag je Fuhre {x} $ · ca. +{y} $/min |
| Fuhrwerk: {p} $ einmalig · Unterhalt {u} $/min                    |
| [Anlegen · {p} $]   [Abbrechen · Esc]                             |
+------------------------------------------------------------------+
```

**W4 Linienliste (links, unter „Linien“).** Netto je Linie, Alter, Sättigung als Form. (ii): Spaltenkopf klickbar (Sortieren).
```
Linie                   Netto/min  Alter  Sättigung
Fuhrwerk 1 Getreide      +12 $     3 J    ●
Fuhrwerk 2 Mehl           −3 $     3 J    ▲ Erlenbach 100 %
[+ Fuhrwerk]  an jeder Zeile
```

**W5 Fahrzeugkarte (Klick auf Zeile oder Fuhrwerk).**
```
+-------------------------------------------+
| Fuhrwerk 1 (Getreide)                  [x] |
| Alter 8 J  [██████████░░] 80 % der Lebensdauer |
| Unterhalt 8,4 $/min (+40 % durch Alter)    |
| Ersetzen: Restwert {r} $ · neu {n} $ · spart {z} $/min |
| [Ersetzen · {n−r} $]        [Behalten]     |
+-------------------------------------------+
```

**W6 Diagnose-Toast (unten rechts, ein Toast zugleich).**
```
+-----------------------------------------+
| ▲ Gut Kuppenhof                      [x] |
| Fuhrwerk 1 wartet 40 s auf Getreide.     |
| Zu viele Fuhrwerke für 20 E/min.         |
| [Zur Linie]                              |
+-----------------------------------------+
```

**W7 Bankrott-Anzeige (Panel über der Welt, Welt dahinter ungefiltert, kein grauer Schleier).**
```
+----------------------------------------------------+
| ■ Bankrott nach 23:40 min                           |
| Größter Verlust: Linie Mühle → Lindenfurt (−42 $/min)|
| Kasse im Verlauf:  ▁▂▄▆▇▅▃▂▁  → 0 $                  |
| Früher Kredit nehmen oder die Linie auflösen.        |
| [Neu starten]            [Zum Menü]                  |
+----------------------------------------------------+
```

## 4 Schritte

### S0 Start
**Zustände:** Menü → Laden (≥ 1 s: Fortschrittstext „Welt wird geladen …“) → Welt (1×, Kasse 6.000 $, 0 Linien, Pause aus). Ohne Fahrzeug fallen 0 $ Fixkosten an, deshalb läuft die Uhr von Anfang an ohne Zeitdruck.
**Erfolgsweg:** Knopf „Welt spielen (Loop S8)“ (Taste P gleichwertig). Willkommens-Toast (einmalig, 10 s): „Erlenbach 1820. Klicke Gut Kuppenhof an, dort beginnt deine erste Linie.“ Zeile „Nächster Schritt“ sagt „Lizenz für Gut Kuppenhof holen“.

| # | Fehlerweg | Text | Anzeige |
|---|---|---|---|
| F0.1 | Esc im laufenden Spiel (Speichern gibt es erst in S9, 45 min wären weg) | „Zurück ins Menü? Dein Spielstand geht verloren, Speichern kommt später.“ | inline, Knöpfe [Weiter spielen] [Zum Menü] |
| F0.2 | Gelände ist Ersatzfläche (HUD „Gelände: Stub …“, RL-0) | „Das Gelände ist nur eine flache Ersatzfläche. Bitte melde das mit einem Foto vom Start.“ | Banner, nur Test-Build |
| F0.3 | Welt lädt nicht | „Die Welt konnte nicht geladen werden. Starte neu oder melde den Fehler ({Code}).“ | Panel + [Zum Menü] |

**Messgröße:** L1 Schritt „Start über den Knopf“ geklappt ja/teils/nein + Minuten bis zur sichtbaren Welt; Feld „Gelände:“ im Formular (RL-0); Ladezeit ≤ 3 s (Test). Zeit bis zur ersten Aktion (Klick auf Gut Kuppenhof): L2, Daniel mit Stoppuhr, (ii) zusätzlich `test_log.csv`.

### S1 Lizenz kaufen
**Zustände Lizenzzeile:** keine · gilt noch {t} min (●) · endet in < 3 min (▲) · abgelaufen (■) · nicht nötig (Dorf, Stadt). Eingang: Klick auf Schild, Plakette oder Gebäude des Betriebs öffnet das Panel (W2).
**Erfolgsweg:** [Lizenz kaufen {x} $] → Kasse sinkt um den Vorschaupreis (±0). Toast: „Lizenz für {Name} gekauft, sie gilt {t} min. Jetzt: Linie von hier anlegen.“ Knopf [Linie von hier] wird ButtonPrimary, Ziel E-1 hakt. Verlängerung: „{Name}: Lizenz verlängert für {x} $.“ (heute ohne Meldung, L11).

| # | Fehlerweg | Text | Anzeige |
|---|---|---|---|
| F1.1 | Kasse reicht nicht, vor Minute 12 | „Lizenz kostet {x}, es fehlen {Δ}. Kredit gibt es erst ab Minute 12.“ | Toast, Knopf grau |
| F1.2 | Kasse reicht nicht, ab Minute 12 | „Lizenz kostet {x}, es fehlen {Δ}. Nimm Kredit oder warte auf Einnahmen.“ | Toast, Knopf grau |
| F1.3 | schon lizenziert | „{Name} ist schon lizenziert, noch {t} min.“ | Toast |
| F1.4 | Betrieb braucht keine Lizenz | „{Name} braucht keine Lizenz. Lege direkt eine Linie dorthin.“ | Toast |
| F1.5 | Lizenz läuft ab (A-08, < 3 min) | „Die Lizenz endet in {t} min. Verlängern kostet {x}, sonst stehen die Fuhrwerke.“ | Diagnose-Toast, Aktion [Verlängern] |
| F1.6 | Lizenz abgelaufen | „Lizenz abgelaufen, die Fuhrwerke warten. Erneuern kostet {x}.“ | Diagnose-Toast, Aktion [Erneuern] |
| F1.7 | sonstige Ablehnung | „Lizenz gerade nicht möglich. Bitte erneut klicken (Meldung an uns: {Code}).“ | Toast |

**Messgröße:** E-1-Minute (Test, `s_lic_until`); L2 Schritt „Lizenz“ geklappt + Minuten; Lizenzknopf **ohne Hilfe** gefunden ja/nein (Beobachtung); Kassenänderung = Vorschaupreis ± 0 (Test AT-07); Lizenz-Ereignis 6 im Bot bei Minute 27–30 (OE-06).

### S2 Linie anlegen
**Zustände:** 2a Modus „Linie von hier“ (Cursor-Hinweis „Klicke das Ziel“, mögliche Ziele Kontur grün, ungültige grau) → 2b Vorschau (W3) → 2c angelegt. Esc bricht in jeder Stufe ohne Text ab.
**Erfolgsweg:** Quelle (Panel) → Ziel (Klick) → [Anlegen]. Annahme A1: Anlegen kauft das **erste Fuhrwerk** mit (Preis in der Vorschau). Toast: „Linie {A} → {B} läuft. Fuhrwerk 1 ist unterwegs.“ Kette Farm → Mühle → Dorf als zwei Linien.

| # | Fehlerweg | Text | Anzeige |
|---|---|---|---|
| F2.1 | keine Verbindung (kein Bau in S8, D3) | „Zwischen {A} und {B} gibt es keine Straße. Wähle ein Ziel am bestehenden Netz.“ | Toast + Ziel rot |
| F2.2 | Quelle liefert nichts | „{Name} liefert nichts. Starte die Linie bei Farm, Mühle oder Lager.“ | Toast |
| F2.3 | Quelle ohne Lizenz | „{Name} hat keine Lizenz. Kaufe sie im Panel (Klick auf das Gebäude).“ | Toast, Panel öffnet |
| F2.4 | Ziel nimmt Ware nicht an | „{Ziel} nimmt {Ware} nicht an. Wähle einen Abnehmer, der sie braucht.“ | Toast |
| F2.5 | Kasse reicht für das Fuhrwerk nicht | „Fuhrwerk kostet {x}, es fehlen {Δ}. Nimm Kredit oder warte auf Einnahmen.“ | Toast, [Anlegen] grau |
| F2.6 | Linie gibt es schon | „Diese Linie gibt es schon. Füge ihr ein Fuhrwerk hinzu (+ Fuhrwerk).“ | Toast |
| F2.7 | Klick ins Leere | „Klicke ein Gebäude an: erst die Quelle, dann das Ziel.“ | leiser Toast, 2 s |
| F2.8 | Start = Ziel | „Start und Ziel sind gleich. Wähle ein anderes Ziel.“ | Toast |

**Messgröße:** Linie in **≤ 4 Klicks** ab Panel; Farm → Mühle → Dorf in **≤ 6 Klicks** (play_welt, AT-08); Vorschau-€/min ±5 % gegen den Messwert nach 5 min (UX-2); **0 stumme Ablehnungen** in den Fehlerfällen F2.1–F2.8; L2 Schritt „Linie anlegen“ geklappt + Minuten.

### S3 Fuhrwerk kaufen / hinzufügen
**Zustände:** Knopf [+ Fuhrwerk] an jeder Linienzeile (W4); „Fuhrhalterei am HQ“ als Panel-Eintrag (ohne Sim-Funktion) mit Zeile „Unterhalt enthält Futter, Knecht, Stellmacher.“
**Erfolgsweg:** Klick → Kasse −{p} (Vorschaupreis ±0), Fuhrwerk erscheint am Ladeplatz. Toast: „Fuhrwerk {n} gekauft: −{p} $, Unterhalt +{u} $/min. Linie bringt jetzt ca. {z} $/min.“

| # | Fehlerweg | Text | Anzeige |
|---|---|---|---|
| F3.1 | Kasse reicht nicht | wie F2.5 | Toast, Knopf grau |
| F3.2 | Quelle liefert zu wenig (Hinweis, Kauf bleibt möglich) | „{Name} liefert nur {x}/min. Ein weiteres Fuhrwerk bringt kaum mehr.“ | ▲ im Knopf-Tooltip + Vorschauzeile |
| F3.3 | Postkutsche gewünscht (W21) | „Postkutschen fahren nur als Kulisse. Passagiere kommen in einer späteren Version.“ | Zeile in der Fuhrhalterei |
| F3.4 | Frachtwagen vor 1830 (nur mit FZ-05) | „Frachtwagen gibt es erst ab 1830. Bis dahin kaufst du das Fuhrwerk.“ | Toast |

**Messgröße:** Kauf in **≤ 2 Klicks** ab Linienzeile; gebuchter Preis = Vorschaupreis ± 0 (Test); L2 Schritt „2. Fuhrwerk“ geklappt + Minuten; Bot: Fuhren/min der Linie steigt nach dem Kauf (außer bei F3.2).
**(i)/(ii):** gleich. F3.4 entfällt, wenn FZ-05 (Kipp, Entscheid Tag 8) nicht kommt.

### S4 Betrieb, Kasse, Kredit
**Zustände:** 4a Beobachten (normal) · 4b Hinweis ▲ (Sättigung ≥ 100 %, Lizenz < 3 min, Fuhrwerk alt) · 4c Alarm ■ (Sättigung ≥ 150 %, Linie mit Verlust) · 4k Kredit offen (Chip „Kredit {x}“ in W1).
**Erfolgsweg Beobachten:** Netto/min je Linie in der Liste (W4); Ladung am Gespann sichtbar, Lade-/Entladebalken (WA-14); Sättigung als Form in der Zeile und am Ort. **Kredit:** [Kredit] in W1 ab Minute 12 aktiv; inline Stufen [500] [1.000] [2.000] mit Zeile „Zins 3 % je Minute“ (nicht „je Jahr“, G7); Toast: „Kredit {x} aufgenommen. Zins {z} $/min, Rahmen noch {r}.“

| # | Fehlerweg / Hinweis | Text | Anzeige |
|---|---|---|---|
| F4.1 | Kredit vor Minute 12 | „Kredit gibt es ab Minute 12. Bis dahin: Einnahmen abwarten.“ | Tooltip + Toast bei Klick |
| F4.2 | Kreditrahmen voll | „Kreditrahmen {x} ist voll. Tilge Schulden oder warte auf Einnahmen.“ | Toast |
| F4.3 | Tilgen: Kasse reicht nicht | „Zum Tilgen fehlen {x} in der Kasse. Warte auf Einnahmen.“ | Toast |
| F4.4 | Sättigung gelb (≥ 100 %, W19) | „{Ort} nimmt bald kein {Ware} mehr ab (100 %). Plane einen zweiten Abnehmer.“ | ▲ in Liste + Ort |
| F4.5 | Sättigung rot (≥ 150 %, W19) | „{Ort} ist mit {Ware} gesättigt ({p} %). Ein zweiter Abnehmer bringt +{x} $/min.“ | ■ in Liste + Ort, Diagnose-Toast |

**Diagnose-Katalog A-08 (AT-11, ≥ 6 Fälle, nur in der Welt):** Ort + Ursache + eine Aktion.

| # | Auslöser | Titel | Text | Aktion |
|---|---|---|---|---|
| D1 | wartet auf Ladung > 30 s | {Quelle} | „Fuhrwerk {n} wartet {t} s auf Ladung. Zu viele Fuhrwerke für {x}/min.“ | [Zur Linie] |
| D2 | Restladung (Annahme A4) | {Ziel} | „{Ziel} nahm nur {a} von {b} E an. Der Ort ist gesättigt, der Rest bleibt auf dem Wagen.“ | [Abnehmer wählen] |
| D3 | gesättigt ≥ 150 % | {Ort} | = F4.5 | [Zum Ort] |
| D4 | Lizenz endet < 3 min | {Betrieb} | = F1.5 | [Verlängern] |
| D5 | Linie mit Verlust über 3 Perioden | Linie {A} → {B} | „Die Linie verliert {x} $/min (Fix {a}, Ertrag {b}). Kürzer fahren oder Fuhrwerk abziehen.“ | [Zur Linie] |
| D6 | Fuhrwerk bei 100 % Lebensdauer (FZ-03) | Fuhrwerk {n} | „{j} Jahre alt: Unterhalt +{p} %. Ersetzen spart {z} $/min.“ | [Ersetzen] |

**Messgröße:** L2 „Gewinn je Linie ablesen“: Basti nennt Linie mit höchstem und niedrigstem Netto (richtig ja/nein); Kredit ab Minute 12 genommen ja/nein + Minute; **L3** Interessenkurve alle 5 min (Skala 1–5), je Toast „verstanden“ ja/nein (Ziel ≥ 80 %), 0 überlappende Toasts, Basti nennt die **Ursache** eines Ertragsrückgangs selbst (UX-4); Bot: Ereignislücke P90 ≤ 3 min, Kassentiefpunkt P50 zwischen Minute 5 und 20 < 2.000 $.
**(i)/(ii):** **(i)** Linienliste ohne Sortieren, Toast ohne Sprung-Klick (Text nennt den Ort), Interessenkurve und „verstanden“ auf Papier mit Uhrzeit (W25). **(ii)** Spalten sortierbar, Toast-Klick springt zur Kamera, Testmodus-Leiste und Toast-Knöpfe (QT-08), Ortsschild-Status (WA-13b) nur Stretch, schwebendes „+x $“ und Ziel-Marker nur Stretch.

### S5 Ersetzen
**Zustände:** Fahrzeugkarte (W5) zeigt Alter, Unterhalt, Ersetzen-Rechnung. Ab 1830 (FZ-05, Kipp): zusätzliche Auswahl „Frachtwagen (+80 % Ladung)“ und Toast „Neu verfügbar: Frachtwagen. Ersetzen lohnt jetzt.“
**Erfolgsweg:** [Ersetzen · {n−r} $] → die Linie läuft ohne Neuanlage weiter. Toast: „Fuhrwerk {n} ersetzt: −{x} $ nach Restwert. Unterhalt jetzt {y} $/min statt {z}.“

| # | Fehlerweg | Text | Anzeige |
|---|---|---|---|
| F5.1 | Kasse reicht nicht | „Ersetzen kostet {x}, es fehlen {Δ}. Warte auf Einnahmen oder nimm Kredit.“ | Toast, Knopf grau |
| F5.2 | Ersetzen spart nichts (Hinweis) | „Ersetzen spart hier nichts ({z} $/min). Behalte das Fuhrwerk.“ | ▲ in der Karte, Ersetzen bleibt möglich |
| F5.3 | Fuhrwerk unterwegs (Annahme A3) | „Fuhrwerk {n} ist unterwegs und wird beim nächsten Halt ersetzt.“ | Toast |
| F5.4 | Frachtwagen noch nicht verfügbar | wie F3.4 | Toast |

**Messgröße:** L3 „Basti ersetzt ein Fahrzeug ohne Hilfe“ ja/nein; jede Zahl der Karte = Sim (Test FZ-04); Restwertformel (Test); Bot: Ersetzen-Ereignis zwischen Minute 28 und 35 (nur mit FZ-05).
**(i)/(ii):** Karte (i) Mira / (ii) N.N. Ohne FZ-05: Fuhrwerk ersetzt Fuhrwerk, F3.4 und der Frachtwagen-Toast entfallen, D6 bleibt.

### S6 Firmenkauf (C1) und Werksausbau
**Zustände:** Betrieb-Panel Block „Besitz“: nicht dein · gehört dir (Pin-Rand voll, FK-05) · Werksstufe 1 / 2. Kauf nur aus Guthaben, **nicht** bei offenem Kredit. Nach dem Kauf: [Werk ausbauen auf 40 E/min · 2.000 $].
**Erfolgsweg:** [Mühle kaufen {x} $] → Kasse −x. **(i)** Der Knopf braucht Schutz gegen Fehlklick (Annahme A6): erster Klick wechselt 3 s auf „Sicher? {x} $“, zweiter kauft. **(ii)** Bestätigung inline mit Folgen: Preis, Anrechnung, Unterhalt, Amortisation. Toast: „Erlenmühle gehört dir. Werksmarge +15 %, Unterhalt {u} $/min. Ausbau auf 40 E/min: {x} $.“ Ausbau-Toast: „Erlenmühle verarbeitet jetzt 40 E/min. Liefere mehr Getreide.“

| # | Fehlerweg | Text | Anzeige |
|---|---|---|---|
| F6.1 | Kasse reicht nicht | „Kauf kostet {x}, es fehlen {Δ}. Gekauft wird nur aus der Kasse, nicht mit Kredit.“ | Toast, Knopf grau |
| F6.2 | Kredit noch offen | „Mit offenem Kredit kaufst du nichts. Tilge zuerst {x} (Knopf Kredit).“ | Toast, Knopf grau |
| F6.3 | Betrieb nicht käuflich | „{Name} steht nicht zum Verkauf. Kaufbar sind Farmen und die Mühle.“ | Toast |
| F6.4 | Ausbau: Kasse reicht nicht | „Ausbau kostet {x}, es fehlen {Δ}. Warte auf Einnahmen.“ | Toast |
| F6.5 | Ausbau vor dem Kauf | „Ausbauen geht erst nach dem Kauf. Kaufe zuerst die Mühle.“ | Toast |

**Messgröße:** Kauf in **≤ 3 Klicks** (FK-03); jede Ablehnung mit Ursache + Lösung (play_welt); Minute des ersten Kaufs (Plan-Bot 14–25, Basti L3 mit Frage „Warum jetzt?“); Amortisation 8–20 min und keine Verdopplung Netto in 10 min nach dem 1. Kauf (Bot); alle Folgezahlen = Sim.
**(i)/(ii):** siehe Zustände. **Rückfall W3:** Ist FK-02 bei Gate C nicht grün, entfällt S6 ganz (Mühle fest 40 E/min, Panel ohne Besitzblock), die Karte L3 streicht die Frage.

### S7 Warnung und Bankrott
**Zustände:** 7a stabil · 7a′ Warnung, wenn die Prognose „Kasse ÷ (Kosten − Einnahmen der letzten 2 min)“ ≤ 90 s ergibt (Design §2.5; die S7-Fehlertexte nannten 60 s, ich folge dem neueren Design) · 7b Bankrott bei Kasse < 0, **sofort**, ohne Gnadenfrist (Slice-Verhalten `main.gd` Z. 3146, [M]).
**Warnung:** Kasse in W1 wird ▲ (≤ 90 s) und ■ (≤ 30 s, [E]); Diagnose-Toast bleibt, bis es stabil ist. **Erfolgsweg (abgefangen):** Entwarnung „Kasse reicht wieder. Behalte {Posten} im Auge.“ **Bankrott:** W7, Welt dahinter sichtbar, mit dem größten Posten und dem Kassenverlauf.

| # | Fall | Text | Anzeige |
|---|---|---|---|
| F7.1 | Warnung vor Minute 12 | „Kasse reicht noch ~{t}. Größter Verlust: {Posten} (−{x}/min). Löse die Linie auf.“ | Diagnose-Toast, persistent, Aktion [Zur Linie] |
| F7.2 | Warnung ab Minute 12, Kredit frei | „Kasse reicht noch ~{t}. Größter Verlust: {Posten}. Nimm Kredit oder löse die Linie auf.“ | wie F7.1, Aktion [Kredit] |
| F7.3 | Warnung, Kreditrahmen voll | „Kasse reicht noch ~{t}, der Kredit ist voll. Löse {Posten} auf oder verkaufe ein Fuhrwerk.“ | wie F7.1 |
| F7.4 | Kauf würde die Kasse knapp machen (Hinweis, [E]) | „Nach dem Kauf reicht die Kasse nur noch ~{t}. Trotzdem kaufen?“ | inline am Kaufknopf |
| F7.5 | Bankrott | „Bankrott nach {t}: {Posten} kostete {x}/min, die Kasse war leer. Nimm früher Kredit.“ | W7 |

**Messgröße:** Bot (n = 300, Wilson): Bankrott **naiv 10–30 %, Plan ≤ 5 %**; Test: **0 Bankrotte ohne vorherige Warnung**, soweit der Verlauf ≥ 90 s Vorlauf lässt; L3 „verstanden“ ja/nein für die Warnung; Basti nennt nach Warnung/Bankrott die richtige Ursache (Schlussfrage); Reaktionszeit Warnung → erste Handlung ((ii) `test_log.csv`, (i) Daniel mit Stoppuhr).
**(i)/(ii):** (ii) Toast-Klick springt zum Posten, (i) nur Text mit Name.

## 5 Szenario (i) gegen (ii) auf einen Blick (ergebnis §5)

| Funktion | (i) gekürzt | (ii) |
|---|---|---|
| Toast-Klick springt zur Kamera (Fokus-Klick) | nein, Text nennt den Ort | ja |
| Linienliste sortierbar | nein | ja |
| Ortsschild-Status WA-13b, Ziel-Marker, schwebendes „+x $“ | nein | nur Stretch |
| Testmodus (Interessenleiste, Toast-Knöpfe, `test_log.csv`) | Papierformular mit Uhrzeit | QT-08 |
| C1-Kauf | Knopf + Fehlklick-Schutz + Toast | inline Bestätigung, Amortisation, Pin |
| Fahrzeugkarte / Linienliste (FZ-04, AT-10) | Mira | N.N. |
| Skillpunkt-Toast, Skilltree-Panel | entfällt (nur Konzept) | SK-03 |
| Schritte S0–S3, S5 (Kern), S7 | gleich | gleich |

## 6 Annahmen und offene Punkte (Mira bis Tag 3, danach Jonas)

| # | Punkt | Vorschlag | Wenn anders |
|---|---|---|---|
| A1 | Anlegen kauft das erste Fuhrwerk mit | ja (Slice-Muster, spart einen Klick und den Zustand „Linie ohne Fahrzeug“) | leere Linie + Kauf: +1 Klick, extra Warntext „Linie hat kein Fuhrwerk“ |
| A2 | Esc fragt nach (F0.1) | ja, ca. 0,1 T; heute verlässt Esc die Welt sofort, ohne Speichern verlöre Basti bis zu 45 min | ohne: Fehlklick kostet die Sitzung |
| A3 | Ersetzen eines Fuhrwerks unterwegs | wird beim nächsten Halt wirksam | sofort: Ladung muss entschieden werden (Sim-Verhalten, Felix) |
| A4 | Restladung (D2): Verhalten der Sim bei gesättigtem Abnehmer | Text vorläufig, **Sim-Verhalten ungeklärt** (Felix/Tobias) | D2 entfällt, Katalog bleibt bei 5 + Kassenwarnung |
| A5 | Warnschwelle 90 s statt 60 s | 90 s (Design §2.5) | 60 s: F7.x unverändert |
| A6 | Kaufschutz bei C1 in (i) (Sicher?-Klick) | ja, Kauf ist unumkehrbar | ohne: Fehlklick kostet ~1.600 $ |
| A7 | Das gewählte Tempo k fehlt im HUD | Anzeige „k=4“ in der HUD-Zeile „Tempo“, ca. 0,1 T (Mira) | ohne: Basti kann in L1 nicht prüfen, welche Variante läuft |

**Texte-Check:** Alle 89 Textstellen in „…“ sind ≤ 90 Zeichen, gezählt per Skript am 05.11.2026 **mit den Platzhaltern als Text** (`{Posten}` zählt 8). Mit eingesetzten Werten (Ortsnamen, Beträge) können einzelne Texte länger werden; AT-12 prüft das gegen die echten Werte beim Übernehmen in `ui/fehlertexte.gd`.
