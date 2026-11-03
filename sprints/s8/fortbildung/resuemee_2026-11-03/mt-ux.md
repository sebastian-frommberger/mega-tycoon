# Aylin (UX/UI): Resümee (Stand 03.11.2026)

Quellen: Repo `/home/claude/mega-tycoon` (relativ angegeben), Web-URLs im Abschnitt 7. Marken: [Beleg] = im Repo oder in einer Quelle nachgelesen, [Eindruck] = meine Einschätzung.

## 1. Wie ich Spiel und Konzept heute sehe

Der Kern ist ein Verkehrs-Tycoon ab 1820, bei dem der Spieler seine Linien **diagnostiziert, statt zu raten**: Warum steht der Wagen, wo fehlt Ladung, was kostet die Strecke. Das ist der USP aus `concept/aylin.md` und `concept/leitplanken.md` (Charter E1 bis E15: nichts übertreiben, Start 1820). [Beleg]

Was trägt: die Lesbarkeit der Welt. Semantischer Zoom mit Label-LOD, Hysterese 8 % (`slice/proto/proto_schilder.gd`, `HYSTERESE`), Mindestschrift 12 px, ein Kontrast-Gate (7:1 Text, 3:1 Grafik) und Entscheidung D21 "UI mit Liebe, keine grauen Modals". [Beleg]

Was noch Papier ist: **Die Diagnose und die Signale sind im spielbaren Slice nicht in der Oberfläche.** `slice/core/diagnostics.gd` wird nur von `core/sim_world` und Tests benutzt, nicht von `slice/main.gd`. Der USP ist heute für Basti nicht erlebbar. [Beleg] Das ist mein größtes Eingeständnis.

## 2. Entwicklungsverlauf aus meiner Sicht

- S2 bis S3: Konzept und Plan (`concept/aylin.md`, `plan/aylin.md`). Die Diagnose-Meldung A-08 wird eingeplant, in S3 nicht gebaut. [Beleg: Sprint-Reviews s3]
- S4: A-08 gestrichen zugunsten anderer Arbeit. [Beleg]
- S6: A-08 als Stretch geführt, nicht gebaut. [Beleg]
- S7: Welt-Variante `--welt=s7` (1 Feld = 25 m), Bastis Feedback 01 bis 11 (`sprints/s7/basti_feedback_01-11.md`); A-08 nach S8 verschoben. [Beleg]
- S8: Design-Sprint mit Prototyp-Welt und Schildern als 2D-Overlay; Fix-Pass M8 nimmt den Weiler-Kompromiss zurück (`WEILER_NAH_BIS_M = 0.0`). [Beleg]
- Zeitrahmen: Git zeigt 76 Commits vom 01. bis 03.11.2026; die Sprint-Daten in den Dokumenten sind nominal. [Beleg]

## 3. Was gut lief (belegt)

1. Das Schilder-System ist technisch sauber: Hysterese, Deckelung der Skalierung (`_scale = clampf(vp.y / 900.0, ...)`, Zeile 479), Mindestschrift. [Beleg: `slice/proto/proto_schilder.gd`]
2. Messbare Kontraste statt Geschmack: Gate mit 7:1 und 3:1 steht im Regelwerk und wird getestet. [Beleg: `tests/`, Charter]
3. Die Weiler-Korrektur in M8 zeigt, dass wir einen Kompromiss auch zurückdrehen. [Beleg: Fix-Pass-Dokument `phase4/fixpass_w2.md`]
4. Abnahme durch Basti war nach jedem Sprint real (Feedback-Dateien s7 und s8). [Beleg]

## 4. Was nicht gut lief, wiederkehrende Kompromisse (mit Zähler)

| Kompromiss | Zähler | Beleg |
|---|---|---|
| A-08 Diagnose-Toast verschoben | **mindestens 4** (S3 nicht gebaut, S4 gestrichen, S6 Stretch, S7 nach S8) | Sprint-Reviews s3 bis s7 |
| Test nur durch Basti oder Experten-Review (D16), n=1 | seit S3 jedes Mal | Entscheidungen D16, Retros |
| Tests auf Platzhalter-Karte werden rot, wenn die echte Karte kommt | 2 (S6, S7) | Retros s6, s7 |
| Doku-Drift gegenüber Code | mindestens 3 | `phase4/integration_w2.md`, Header-Kommentar in `proto_schilder.gd` Zeile 16 behauptet noch "wächst mit der Auflösung mit", Code deckelt |
| Einzelnes Toast-Label ohne Queue | 1 Fund, aber Ursache der A-08-Verschiebung | `slice/main.gd` Zeilen 192, 1027, 1594 (ein `toast_label`) |

Konkret zu mir: Das Schild liegt gegen seine Umgebung bei **2,95:1**, also unter unserem eigenen 3:1-Grafik-Gate. [Beleg: Kontrast-Messung im Phase-4-Stand] Das haben wir im Fließtext als "knapp" geführt. Ehrlich: es ist durchgefallen.

## 5. Wo das Spiel oder das Konzept aus meiner Sicht scheitern könnte

1. **Hoch:** Der USP bleibt unsichtbar. Wenn bis zum nächsten Playtest keine Signale in der Oberfläche stehen, spielt Basti einen hübschen Zug-Simulator ohne Alleinstellung. [Eindruck, gestützt auf `diagnostics.gd`-Befund]
2. **Hoch:** Wir testen mit n=1 (Basti). Er kennt das Konzept. Jede Verständlichkeitsaussage ist ungeprüft. [Beleg: D16]
3. **Mittel:** Tooltip-Verzögerung (heute 0,12 s) ist unbelegt und kann bei Dichte zu Flackern führen (`proto_schilder.gd` Zeile 675). [Beleg für Wert, Eindruck für Folge]
4. **Mittel:** Textgröße. 12 px Mindestschrift ist für 1080p knapp; Branchenwerte liegen bei 18 px (PC) bis 28 px (TV-Herkunft). [Beleg, siehe 7]
5. **Niedrig:** Schilder-Überfüllung bei großen Netzen; Declutter ist nur im Prototyp geprüft. [Eindruck]

## 6. Meine drei wichtigsten Empfehlungen an Basti für Sprint 8

1. **A-08 und eine erste Signal-Anzeige in `main.gd` einbauen, mit Toast-Queue** (eine Meldung zugleich, 4 bis 10 s, Inhalt zusätzlich in einem Protokoll). Aufwand: ca. 1 bis 1,5 Tage mit Mira. Ohne das gibt es keinen USP zum Testen.
2. **Ein Test mit 3 Personen, die das Konzept nicht kennen** (D16 aufbrechen). Aufwand: 0,5 Tag Vorbereitung, 1 Tag Sitzungen. Beobachten, nicht erklären.
3. **Schild-Kontrast auf mindestens 3:1 anheben und Schriftminimum festlegen** (Vorschlag 18 px bei 1080p, Tooltip-Verzögerung 0,4 bis 0,5 s als zu testender Wert). Aufwand: 0,5 Tag.

## 7. Recherchen dieser Runde

**R1 Textgröße.** Frage: Welche Mindestgröße ist üblich? Quellen: [GAG 28 px bei 1080p](https://gameaccessibilityguidelines.com/ensure-that-all-text-is-set-to-a-minimum-of-28px-at-1080p/), [Game Developer / EA zu Schriftlesbarkeit](https://gamedeveloper.com/design/legible-font-still-one-of-the-biggest-accessibility-issues-in-games), Xbox Accessibility Guidelines (18 px PC). Ergebnis: 28 px stammt aus dem TV-Kontext, 18 px für PC. Sicherheit: mittel. [Beleg]

**R2 Label-Fade.** Frage: Ist 300 ms Überblendung üblich? Quelle: [MapLibre MapOptions](https://maplibre.org/maplibre-gl-js/docs/API/type-aliases/MapOptions/), `fadeDuration` Standard 300. Ergebnis: bestätigt. Sicherheit: mittel bis hoch. [Beleg]

**R3 Toast und Meldungen.** Quellen: [SAP Fiori Snackbar](https://www.sap.com/design-system/fiori-design-android/v25-8/components/feedback/snackbar/usage) (eine zur Zeit, mehrere Sekunden), [WCAG 2.2.1 Timing Adjustable](https://www.w3.org/WAI/WCAG22/Understanding/timing-adjustable.html) (flüchtige Hinweise nur, wenn die Information anderswo bleibt). Ergebnis: Queue plus Protokoll. Sicherheit: mittel. [Beleg] Material 3 Tooltips und Snackbars waren nicht abrufbar (blockiert), daher nicht verwertet.

**R4 Tooltip-Verzögerung.** Offen. [Microsoft Fluent Tooltips](https://learn.microsoft.com/en-us/windows/apps/design/controls/tooltips) nennt keinen Wert; WPF dokumentiert nur das Aufwärm-Fenster. Windows- und Qt-Zahlen nicht aus Primärquelle erhalten. Mein 0,12 s bleibt **[Eindruck]**, Sicherheit niedrig. Nicht geraten.

Lernlog-Zeilen (2026-11-03):
- Situation: Tooltip 0,12 s im Skill als Wert geführt. Lücke: unbelegt. Gegenmaßnahme: als [H] markieren, im Test variieren.
- Situation: A-08 viermal verschoben. Kompromiss-Zähler 4. Gegenmaßnahme: A-08 wird Sprint-Ziel mit Abnahmekriterium, nicht Stretch.
- Situation: Schild 2,95:1 gegen eigenes Gate 3:1. Lücke: als "knapp" verbucht. Gegenmaßnahme: Gate-Verfehlung wird als Fail geführt.

## 8. Vorschläge für Skill-Änderungen (nur Vorschläge, nichts geschrieben)

1. Zeile "Tooltip 0,12 s" in `sprints/s8/fortbildung/mt-ux/SKILL.md`: Marker von bisherigem Wert auf **[H]** ändern. Quelle: R4, kein Primärbeleg.
2. Zeile zur Mindestschrift: ergänzen "28 px bei 1080p (GAG, TV-Herkunft), 18 px PC (XAG)", Marker **[S]**. Quelle: R1.
3. Neue Regel unter Toasts: "eine Meldung zugleich, 4 bis 10 s, Inhalt bleibt im Protokoll", Marker **[K]**. Quelle: R3 (SAP, WCAG 2.2.1).
4. Label-Fade 300 ms als Richtwert mit **[E]**, Quelle R2.
