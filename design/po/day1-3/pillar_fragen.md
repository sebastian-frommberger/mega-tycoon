# Pfeiler-Fragen für das Gate M0 (J-05, Stand 18.11.2026)

Quelle der Pfeiler: concept/jonas.md (identisch in leitplanken-Linie). Regel: Rot = Frage mit Nein beantwortet. Fehlt der Messwert, ist die Frage "offen" und gilt nie stillschweigend als Ja.
Gültiger Messwert = am echten Spike-Build gemessen (nicht Fake-Feed, nicht präparierte Saves ohne F-04, nicht Rechenmodell, nicht Entwicklerrechner statt Zielrechner, nicht Selbstaussage des Ticket-Owners).

| # | Pfeiler | Prüfbare Ja/Nein-Frage | Beantwortet durch | Ja (Grün) | Gelb | Nein (Rot) |
|---|---|---|---|---|---|---|
| 1 | Lesbare Komplexität | Finden mindestens 4 von 6 Testern die laut benannte Wurzelursache von mind. 2 der 3 Testfehler in < 60 s nach Klick auf die Meldung? | **L-06** (Build F-06, Feed A-05, Daten F-04), Rohdaten 25.11. | ≥ 4/6 | 3/6 | ≤ 2/6 |
| 2 | Bauen fühlt sich gut an | Setzt Jonas 10 Gleissegmente per Ziehen mit Snap in < 60 s ohne ungültige Platzierung, und würde er danach weiterbauen? | **F-07** (Stretch, 25.–26.11.) | 10 Segmente < 60 s, 0 ungültig, "weiterbauen" = ja | 60–90 s oder 1–2 ungültige | > 90 s oder ≥ 3 ungültige oder "nein" |
| 3 | Jedes Verkehrsmittel hat einen Job | Nennt jeder von 3 Testern im Paper-Prototyp unaufgefordert eine eigene Rolle für Lkw und Zug (sammeln/verteilen vs. Hauptstrecke)? | **Kein Ticket in S2.** Vorschlag: eine Zusatzfrage in der L-05-Nachbefragung (Lena, 0 PT Felix, nicht im Commitment) | 3/3 | 2/3 | ≤ 1/3 |
| 4 | Spezialisierung prägt den Run | Ist die Schlüssel-Fähigkeit der beiden VS-Äste (Schwerindustrie, Agrar & Nahrung) eine neue Spielmöglichkeit statt eines Prozentwerts? | **Kein Spieltest in S2.** Nur Dokumentenprüfung concept/lena.md (Spezialisierung, Genossenschaft); echte Prüfung in M1 "Skilltree-Slice abnehmen" (12.02.) | beide neue Möglichkeit | eine nur Prozent-Variante | keine |
| 5 | Druck kommt aus dem Netz | Entsteht jeder der 3 Testfehler ohne Zufallselement allein aus dem Netzzustand und wird er in allen 3 Seeds mit gleichem Wurzelursache-Typ erklärt? | **D-04** (3 Szenarien × 3 Seeds) und F-06-Smoke-Test (3/3 auslösbar) | 9/9 Läufe | 7–8/9 | ≤ 6/9 |

## Zählregeln
- Frage 1: nur die laut benannte Wurzelursache zählt, nicht das Symptom (Lenas Regel). Mit F-04 nicht lieferbar = Fehler zählt nicht als "gefunden".
- Frage 1 mit Plan B (Fake-Feed): misst nur die UI-Seite. Dann max. Gelb, weil F-04 und D-04 einzeln belegt werden müssen, und der Test wird als "Plan B" im Gate genannt.
- Frage 1 mit < 6 gültigen Testern: nicht hochrechnen, Frage bleibt offen.
- Frage 2: Jonas ist Kriterienautor und Tester zugleich. Daniel oder Katrin protokollieren die Zeit, die Replay-Datei wird abgelegt.

## Ehrliche Lücken
1. **Pfeiler 3 und 4 lassen sich in S2 nicht mit einem Test beantworten.** Kein S2-Ticket spielt Verkehrsmittelnischen oder einen Skilltree. Wer hier "Grün" meldet, belegt es nicht. Im Gate stehen sie als "nicht geprüft, Risiko für M1".
2. **Pfeiler 5 ist nur zur Hälfte abgedeckt.** Der Satz "findet und behebt den Fehler selbst" enthält das Beheben. L-06 misst nur das Finden. Vorschlag an Aylin (Testskript, nicht in der Messgröße gezählt): Nach der Wurzelursache fragen "Was würdest du bauen?" und mitschreiben.
3. **Pfeiler 2 hängt am Stretch.** F-07 startet nur, wenn F-06 am 24.11. abgenommen ist, und bekommt 1 T aus dem Puffer. Ohne F-07 ist das "Bau-Gefühl" am 27.11. nicht nachgewiesen.
4. **Pfeiler 1 ist ein 6-Personen-Test.** Er sagt "Diagnose ist plausibel auffindbar", keine Statistik.
