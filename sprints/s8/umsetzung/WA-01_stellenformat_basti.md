# Stellen melden: Boden und Gebäude (eine Seite für Basti)

Stand 05.11.2026 (Aylin, WA-01). Zum Ausfüllen und Zurückgeben. Dauer: ca. 15 min, verteilt über die nächsten Tage.

**Wofür?** Du hast gesagt: Boden stellenweise „echt krude“, Gebäude an manchen Stellen „off“. Wir finden die Stellen nicht von allein. Du zeigst sie uns, wir bessern nach und zeigen dir am Tag 9 Vorher/Nachher an genau diesen Stellen.

**Wie viele?** Bis zu deinem Test an Tag 4 mindestens **5 Stellen**, gern bis zu 15. Fünf reichen, wenn es nicht mehr sind. Kommt nichts, nehmen wir 8 eigene Stellen, und du bewertest nur noch das Ergebnis.

## So meldest du eine Stelle

**Weg 1: Taste F12 „Stelle merken“ (ab Tag 3, ab dem Test-Build).**
1. Kamera so stellen, dass du das Problem siehst (so nah, wie es dich stört).
2. **F12** drücken. Das Spiel speichert ein Bild und merkt sich die Kameraposition. So finden wir die Stelle auf den Meter genau.
3. Dazu eine Zeile in die Tabelle unten (Nummer, was stört, Note).
4. Die Dateien liegen im Ordner `stellen`: In Godot **Projekt → Benutzerdatenordner öffnen**, dort `stellen`. Ohne Editor: im Explorer `%APPDATA%\Godot\app_userdata\Mega Tycoon Slice\stellen` eintippen. Zip davon zurückgeben.

**Weg 2: Screenshot (geht sofort, auch wenn F12 noch nicht reagiert).**
1. Taste **H** so einstellen, dass das dunkle Feld oben links zu sehen ist (dort stehen Ansicht und Abstand).
2. **Windows + Shift + S**, ganzes Fenster aufnehmen, als `S8_boden_<Nr>_<Stichwort>.png` speichern.
3. Eine Zeile in die Tabelle. Das Feld oben links hilft uns, die Stelle wiederzufinden.

## Deine Stellen

Nur ein Satz pro Stelle: **Was stört?** (Beispiele: „Acker am Fluss sieht wie ein Farbfleck aus“, „Haus steht schief zur Straße“, „Ufer hat Treppen“.) Note: 1 = stört sehr, 5 = passt.

| Nr | Boden oder Gebäude? | Was stört? (ein Satz) | Note 1–5 | Datei |
|---|---|---|---|---|
| 1 | | | | |
| 2 | | | | |
| 3 | | | | |
| 4 | | | | |
| 5 | | | | |
| 6 | | | | |

## Eine kleine Prüfung noch: Ist echtes Gelände geladen?

Du hast „keine Hügel“ gesehen. Es kann an der Welt liegen, oder bei dir wird nur eine **flache Ersatzwelt** geladen. Das sehen wir an einer Zeile.
1. Welt starten (Knopf „Welt spielen (Loop S8)“), **nichts anklicken**.
2. Screenshot wie in Weg 2, das dunkle Feld oben links muss komplett drauf sein.
3. Trag hier ein, was hinter **„Gelände:“** steht:

**Gelände: ____________**  (erwartet: `TA`. Steht dort `Stub (flach)` oder `Stub (TA-Fehler)`, liegt es an uns, nicht an der Welt. Dann sag es uns sofort, das hat Vorrang vor allem anderen.)

## Rückgabe
Diese Seite, den Screenshot und den Ordner `stellen` (gezippt) wie bisher in den Chat.

---
*Für uns:* Vorlage Tag 1 bei Basti (WA-01). Ziel ≥ 5 Stellen bis Tag 4; sonst 8 eigene Standorte (5 Presets, Markt-Ufer, 2 Ackerränder). F12 ist Ticket WA-02 (TA), Stand 05.11.: noch nicht im Build. RL-0: „Gelände: Stub“ → Bug an Felix, höchste Priorität (`prototyp_welt.gd`, Zeile „Gelände: %s“ im HUD, ca. Z. 599; die frühere Angabe Z. 562 ist nach AT-05 verrutscht).
