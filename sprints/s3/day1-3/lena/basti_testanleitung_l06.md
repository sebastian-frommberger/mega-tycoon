# Testanleitung L-06: Versteht man, warum ein Zug steht?

Wir testen nur eines: Liest ein Spieler aus der „Warum?“-Liste den eigentlichen Grund ab (Regel D15).

## Vorbereitung (einmal, ca. 20 min)
1. Build und Bogen am 01.12. abholen. Godot 4.7.2, Monitor 1920×1080.
2. Projektordner: der **F-06-Ordner** (bei Felix `spike/`). Pfad trägt Felix bei der Übergabe ein: ________. `f04-signal` nur, wenn Felix es sagt.
3. Ordner `C:\L06\logs` anlegen. Start je Tester: `godot --path <Ordner> -- --tester=T1 --logdir=C:/L06/logs` (Nummer anpassen). Oder F5 im Editor (immer T1).
4. **Pro Tester neu starten.** (Fehler 3 löst sich nach 35 min von selbst.)
5. Stoppuhr, Stift, 8 Bögen. Probelauf allein. Absturz: Felix.

## Rekrutierung
6 Bekannte, nicht aus der Spielebranche, Szenario nie gesehen. **T1–T3 Genre-Kenner** (ab 20 h Transport Fever, OpenTTD, Railway Empire o. Ä.). **T4–T6 Neulinge** (spielen digital, kein Aufbauspiel). 2 Reserve.

Reihenfolge der Züge: T1 4-5-10 · T2 5-10-4 · T3 10-4-5 · T4 4-10-5 · T5 10-5-4 · T6 5-4-10.

## Einwilligung (vorlesen)
„Wir testen ein Spiel, nicht dich; du kannst nichts falsch machen und jederzeit abbrechen. Ich nehme Bildschirm und Ton auf; das sehen nur ich und das Spieleteam, dein Name wird nirgends notiert. Bist du einverstanden?“ (Text nicht juristisch geprüft)

## Ablauf je Tester (max. 15 min)
0–2 Einwilligung · 2–4 Beispiel · 4–12 drei Aufgaben (je max. 2 min) · 12–15 Fragen.

**Beispiel (zeigen, nichts erklären):** Meldung „Zug 1 steht seit 0:50 min“ anklicken, Liste lesen, Zeile anklicken, Kamera springt.

**Vorab sagen:** „Sprich bitte laut. Wenn du die Ursache kennst, sag ‚Das ist die Ursache‘ und in einem Satz, was es ist.“

**Aufgabentext (wörtlich, nur die Zugnummer wechselt):** „In deinem Netz steht **Zug <Nr>** schon seit einigen Minuten. Du bist die Verkehrsleiterin. Finde heraus, **warum er steht**. Öffne dafür die Meldung zu diesem Zug. Sage laut, sobald du die Ursache kennst.“

Erlaubt sind nur: „Was siehst du gerade?“ (nach 15 s Schweigen) und „Was denkst du?“ Jeder Hinweis = Nichttreffer. Nach 120 s: „Danke, wir gehen zur nächsten Aufgabe.“ Nach jeder Nennung: „Was würdest du jetzt als Erstes bauen oder ändern?“ (notieren, zählt nicht).

## Was gemessen wird
Stoppuhr **starten** beim ersten Klick auf die Meldung, **stoppen** beim ersten Wort von „Das ist die Ursache“. **Treffer** = Grund benannt (Tabelle) **und** unter 60 s (genau 60 s zählt nicht). Erste festgelegte Aussage zählt.

| Zug | Der Grund | Zählt | Zählt nicht | Unsicher: aufschreiben |
|---|---|---|---|---|
| 4 | nur ein Gleis und Gegenzug, oder Ausweichgleis fehlt | „Nur ein Gleis, und Zug 2 kommt entgegen.“ | „Zug 4 wartet am Signal.“ | „Die Strecke ist zu eng.“ |
| 5 | Züge blockieren sich im Kreis | „Die blockieren sich alle gegenseitig.“ | „5 wartet auf 8, 8 auf 6.“ (ohne Schluss) | „Die hängen zusammen.“ |
| 10 | Lager bekommt zu wenig Ware, nur 1 Lkw liefert | „Nur ein Lkw beliefert das Lager.“ | „Zug 7 wartet auf Ladung.“ | „Lager leer, weil die Produktion fehlt.“ (falsch) |

## Bogen (je Tester ein Blatt)
Tester-Code ___ · Datum ___ · Kenner / Neuling · Ton ja / nein

| Zug | Sekunden | Wortlaut | Wertung (Grund / Symptom / falsch / keine) | Treffer <60 s | Hilfe j/n | Schwierigkeit 1–7 | Was bauen? |
|---|---|---|---|---|---|---|---|
| | | | | | | | |
| | | | | | | | |
| | | | | | | | |

Am Ende: Welches Wort oder welche Zeile war unklar? ______

**Abgabe bis 02.12., 12 Uhr an Lena:** Bögen (Foto), Ordner `C:\L06\logs`, Aufnahmen.
