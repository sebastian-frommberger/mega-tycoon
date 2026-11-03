# Lernbericht Aylin (UX/UI), Fortbildung 03.11.2026

Kontext: Basti hat eine Fortbildung angeordnet. Ziel war das Wissensniveau einer Master-Absolventin mit mehreren Jahren Game-UX. Vorgehen: Selbstanalyse am Repo (nur gelesen), Recherche (rund 50 Quellen, Verzeichnis in `SKILL.md` Teil A15), Wissensdatei `SKILL.md`. Marker wie dort: [K] Konsens, [S] Streit, [E] Einzelmeinung oder Setzung, [H] Hypothese oder aus Gedächtnis.

## 1. Wo mir Wissen fehlte
- **Semantic Zoom und Label-LOD:** Stufen 1.500 m und 400 m, Hysterese 8 %, die Nah-Stufe mit weniger Information. Alles als Setzung nach Lesbarkeit entstanden, ohne Genre- oder Literaturbezug. Im Fachstand gilt: mehr Nähe bedeutet mehr Detail, Übergänge weich.
- **Declutter:** Ich kannte keinen Stresstest und keine Flackermetrik. Getestet war mit 3 Orten und 2 Plaketten, S7 hat 12 Städte und 21 Industrien.
- **Kontrast:** Die 11,6:1 habe ich als Beruhigung gelesen. Sie sind der Wert für Text gegen Platte; der echte Engpass ist Platte gegen Umgebung (2,95 bis 3,26:1) und die Plattendeckung.
- **Tooltips:** 0,12 s Verzögerung, nur Maus, kein Esc, nicht hoverbar. Das verletzt die Regeln für Hover-Inhalte (WCAG 1.4.13) und liegt unter dem Wert, ab dem versehentliche Hover öffnen.
- **Skalierung und Textgrößen:** Mein `_scale` aus Fensterhöhe geteilt durch 900 war so gar nicht wirksam. Und 12 bis 14 px liegt unter dem, was Xbox für PC verlangt (18 px bei 1080p), mit anderer Messdefinition als Valve.
- **Playtest-Methodik:** Metriken (Erfolg, Zeit, Fehler) waren für die Aufgabenkarten nicht definiert; die Rolle von Basti als einziger Proband war nie eingeordnet.
- **Onboarding, Controller, Epochen-UI:** nur Konzept oder Plan, keine Quellenbasis. Bei Epochen-UI habe ich auch jetzt keine.

## 2. Wo ich unsicher war und was ich jetzt weiß
| Thema | Vorher | Jetzt |
|---|---|---|
| Schwellen 1.500 m / 400 m | "passt schon" | Setzung; Praxis nutzt Priorität plus Fade plus Stresstest, nicht feste Metergrenzen allein |
| Hysterese 8 % | Gefühl | Technik ist Standard [H], der Wert ist unbelegt |
| Declutter | 0 Überlappungen in 5 Presets | Beweiskraft gering; es braucht 3x Knotenzahl und einen aufgezeichneten Kamerapfad |
| Kontrast 11,6:1 | "sehr gut" | gilt nur für Text gegen Platte bei 88 %; ab etwa 73 % Deckung hält 7:1, bei 70 % sind es nur 6,29:1 (eigene Rechnung) |
| Tooltip-Verzögerung | 0,12 s | 200 bis 300 ms plus Aufwärmfenster [E, Einzelblog]; Godot und Windows 500 ms [K]; der Streit bleibt |
| Skalierung | "Fensterhöhe / 900" | Eigenmessung in Godot 4.7.2: `get_visible_rect()` bleibt bei canvas_items und 16:9 stets 1600 x 900, `_scale` ist daher etwa 1,0 |
| Farbe allein | Formen plus Farbe vorhanden | Konsens bestätigt [K]; Erkennbarkeit bei 12 bis 18 px aber nur von mir beurteilt |
| Tester | Basti allein, synthetisches Panel | Ergebnis ist Expertenreview (n = 1), kein Nutzertest |

## 3. Die fünf wichtigsten Erkenntnisse
1. **11,6:1 ist nicht der Engpass.** Es ist der Kontrast von Schildtext gegen die Platte. Platte gegen Umgebung liegt bei 2,95 bis 3,26:1 (Ziel 3:1 nach WCAG 1.4.11) und hängt an der Deckung von 88 %. Unter 73 % Deckung fällt Text auf Schnee unter 7:1. Konsequenz: beide Kontraste melden, Entscheidung 94 % oder 2 px Rand treffen.
2. **Semantic Zoom heißt mehr Detail bei Nähe.** Unsere Nah-Stufe (nur Name) widerspricht dem Normalfall und ist eine ungeprüfte Setzung. Stufenwechsel sind hart (kein Fade), Flackern ist nicht gemessen. Konsequenz: Fade und Kamerapfad-Test, Nah-Logik mit Basti klären.
3. **Tooltip nur mit Maus nach 0,12 s ist unter dem Standard.** Unter etwa 150 ms öffnen versehentliche Hover; 200 bis 300 ms mit Aufwärmfenster ist plausibel, 500 ms ist Godot- und Windows-Standard. Dazu Esc, hoverbar, Fokus-Weg. Streit über die genaue Zahl bleibt offen.
4. **Skalierung und Textgrößen brauchen eine Messkonvention.** Unter `canvas_items` skaliert die Engine; mein `_scale` ist nahezu wirkungslos. XAG 101 (18 px PC bei 1080p), Valve (9 px Minimum, 12 px empfohlen) und `font_size` sind nicht dasselbe. Konsequenz: eine Konvention, ein UI-Scale-Schalter, Prüfung bei 1280 x 800, 1920 x 1080, 3840 x 2160.
5. **Playtests: Basti allein plus synthetisches Panel ist ein Expertenreview.** Das ist nützlich und billig, aber der Anteil gefundener Probleme pro Person lässt sich nicht auf Neulinge übertragen. Konsequenz: pro Aufgabenkarte Messgröße und Abbruchkriterium vorab, Zeit, Fehlklicks und Abbrüche zählen, Ergebnisse als Expertenreview (n = 1) kennzeichnen.

Zusatzfunde aus dem Repo: Doku und Code weichen ab (Weiler-Name bis 500 m laut `aylin_welle2.md` gegen "nie" laut `fixpass_w2.md` und Code; Ankerhöhen 18/40 m gegen 24/20/14 m); die Regel "Dorf unter 3 km" ist im Prototyp wirkungslos, weil die Kamera nur bis 3.000 m reicht; Esc im Prototyp verlässt sofort; Entwicklertext im Spielermenü; unbekannte Ortsklasse fällt auf "dorf" zurück und eine Klasse "Stadt" fehlt.

## 4. Was ich künftig anders mache
- Jede Schwelle als Datenwert mit Quelle, Messmethode und Status ([K], [S], [E], [H]) ablegen; Setzungen offen als Setzung führen.
- Kontrast immer doppelt melden (Zeichen gegen Platte, Platte gegen Umgebung) und am gerenderten Bild nachmessen.
- Declutter nur mit dem Dreifachen der echten Knotenzahl und aufgezeichnetem Kamerapfad abnehmen; Sichtbarkeitswechsel je Sekunde zählen.
- Hover-Inhalte immer mit Esc und Fokus-Äquivalent entwerfen, auch beim Prototyp.
- Vor jedem Rundgang Aufgabe, Messgröße und Abbruchkriterium schriftlich festlegen; n offen legen.
- Doku und Code nach jedem Fix-Pass gegeneinander prüfen, bevor ich Spezifikationen zitiere.
- Textgrößen nur noch mit benannter Messkonvention angeben.

## 5. Ehrliche Einschränkungen
- **Reddit war nicht lesbar** (WebFetch gesperrt, domainbegrenzte Suche abgelehnt). Redlib-Spiegel habe ich nicht abgerufen. Spielerstimmen aus den genannten Subreddits fehlen; ersetzt durch Steam- und Foren-Threads, die Einzelmeinungen sind.
- GDC Vault nur Abstract (Mitgliederbereich). Einige Quellen dünn: TF3-Vorschauen ohne UI-Details, Factorio FFF-318 nur Forenkommentare, NN/g-Tooltip-Artikel ohne Verzögerungszahl.
- Töpfers Wurzelgesetz und APCA nur aus dem Gedächtnis; als [H] markiert.
- Eigenmessung zur Skalierung nur 16:9 in xvfb; Verhalten bei anderen Seitenverhältnissen nicht belastbar.
- Keine Messung mit echten Menschen, keine Zielhardware, kein Controller. Farbenblind-Tauglichkeit nur berechnet.
- Recherche zu Epochen-UI ohne belastbare Quelle; Teil A12 ist ein Arbeitsprinzip.
- Textgrößen aus XAG und Valve sind anders gemessen als Godot `font_size`; Vergleiche sind Näherungen.
- Das Repo wurde nicht verändert, nichts committet.

Dateien: `/tmp/claude-0/gd/skills/mt-ux/SKILL.md` (306 Zeilen), `/tmp/claude-0/gd/skills/mt-ux/LERNBERICHT.md`.
