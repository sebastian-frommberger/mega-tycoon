# Tagebuch Aylin – Zocker-Session Haberau (Sprint 6)

Stand: ~20 Läufe, Spielzeit 13:00 (von 45 min). Ergebnis: **6/7 Ziele**, Ziel 7 „Endprodukt an einen Abnehmer (M3)“ nicht erreichbar, festgesteckt (siehe unten). Screenshots: `tagebuch_aylin_1_farm_linie.png` (5:00, Kette läuft), `tagebuch_aylin_2_mittelfurt_lager.png` (Lager am Stadtrand, Straße endet im Nichts), `spiel_aylin/sess_b/shot.png` (Farm-1-Panel beim Bestätigen des Fundes).

## Verlauf
| Spielzeit | Was ich tat | Was ich dachte |
|---|---|---|
| 0:00 | Karte, Haberau über Vorschau gewählt | Ring gelb, Panel „Kette im Radius“ grün = gut. Aber: Zahlen „25 F. / 35 F. / 19 F.“ am Ring und „Farm 19 und 35, Mühle 25 Felder“ sagen mir als Erstspielerin nichts („F.“ = Felder? Entfernung wovon?). |
| 0:00 | HQ gegründet | Ziele-Liste links, Pfeil + „Nächster Schritt“ sehr hilfreich. „Umsetzen möglich, noch 2:00“ schwebt unvermittelt über der Karte, unklar was „Umsetzen“ bedeutet. |
| 0:00 | Farm 2 angeklickt, Lizenz „gratis“ gekauft | Knopf „LIZENZ KAUFEN · GRATIS / Ertrag ca. 145 $/Monat“: „Monat“ gibt es im Spiel nicht (Zeit läuft in min, Lizenz 30:00 Spielzeit). Das Pfeil-Symbol und das Label „Getreidefarm 2“ lagen im ersten Bild weit auseinander (Label unter der Farm, Pfeil über der anderen) – ich war unsicher, ob der Pfeil die richtige Farm meint. |
| 0:00 | Straße Farm 2 → Mühle 1 | **Fehlschlag**: „Wasser ohne Brücke: Brücken nur gerade, nicht diagonal“. Der Fluss liegt zwischen Farm und Mühle, Farm 2 liegt diagonal. Als Spielerin kann ich nur Start/Ziel ziehen, nicht Zwischenpunkte; die Meldung sagt nicht, was ich stattdessen tun soll. Drei weitere Versuche (Farm 2 → Haberau, Mühle → Farm 2) bauten **kommentarlos nichts** (kein Toast). |
| 0:00 | „festgesteckt“ – einmal `list` | Koordinaten gesehen: Farm 1 (380,335) liegt auf gleicher Höhe wie Mühle 1 (352,335) -> gerade Brücke möglich. |
| 0:00 | Straße Farm 1 → Mühle 1 (440 $), dann Farm 2 → Farm 1 (180 $) | Erst nach der zweiten Straße hakte das Ziel „Straße Farm 2 → Mühle 1“ (Netz verbunden, keine Direktstraße). Das ist ein Umweg, den kein Hinweis nahelegt. |
| 0:00 | Lkw-Linie Farm 2 → Mühle 1 | Ging sofort, Lkw gratis. Hinweis „Tempo 2× oder 4× oben **links**“ – die Knöpfe sind oben **rechts**. |
| 5:00 | 8 Lieferungen, Ziele 6/7 | Oben „Einnahmen 502 $“, aber „Kosten 90 $/min“ und die Linie zeigt „−2 $/min, Verlust“, während das Ziel „3 Lieferungen **mit Gewinn**“ schon abgehakt ist. Widerspruch. Kasse dümpelt (5.380 → 5.365). Mühle zeigt „ohne Lizenz“ und produziert trotzdem Mehl 69. |
| 5:00 | Mühle-1-Lizenz 140 $ gekauft | „Nächster Schritt“ sagt weiter „Lizenz für Mühle 1 kaufen …“ obwohl gekauft (stale). |
| 5:00 | Straße/Gleis Mühle 1 → Mittelfurt | „Gebäude im Weg: Mittelfurt“ (Zielort ist die Stadtmitte). Umgekehrt: „Brücke zu lang (max. 8 Felder)“ (Fluss läuft durch Mittelfurt). Haberau ebenso „Gebäude im Weg“. Das Spiel sagt „Straße bis Mittelfurt bauen“, aber ich finde keinen Weg, eine Straße an eine Stadt anzuschließen. |
| 5:00 | Lager (800 $) neben Mittelfurt, Straße Mühle → Lager (1.320 $), Lkw-Linie Mühle → Lager | Verzweiflungsversuch: Lager-Toast erklärt „bezahlt wird erst beim Endabnehmer“. Ergebnis: Linie **−109 $/min**, Kasse 6.000 → ~1.900. Von Lager zu Mittelfurt: „Keine Straßenverbindung“, zweites Lager: „Hier ist kein Platz“. |
| 13:00 | Abbruch | Ziel 7 nicht erreichbar, Geld verbrannt. |

## Zögern / Festhängen
1. **Straße über den Fluss (0:00)**. Ursache: Diagonale über Wasser, Meldung ohne Handlungsanweisung, Drag-Weg nicht beeinflussbar. Vorschlag: Straßen-Drag als Knickpfad (erst gerade bis Ufer, Brücke gerade, dann weiter) oder automatisches Brücken-Routing; mindestens Toast „Brücke geht nur geradeaus – ziehe zuerst bis zum Fluss“ und gelbe Vorschau-Linie mit Fehlerstelle in Rot.
2. **Stille Fehlschläge** (kein Toast bei Straße Farm 2 → Haberau): Jede Ablehnung braucht eine Meldung.
3. **Stadtanschluss (5:00)**: Es ist nicht erkennbar, wo eine Straße an eine Stadt andocken darf. Vorschlag: Stadt-Anschlussfeld am Rand markieren (Pfeil/„Abnahmepunkt“), Drag auf Stadtfläche = Anschluss am nächsten Randfeld.
4. **Ziel 7 gibt kein Feedback** über Voraussetzungen: „Nächster Schritt“ ist stale und schlägt einen 1.300-$-Weg vor, ohne Preis/Warnung.
5. Zielbezeichnung vs. Pfeil/Label an den Farmen (Farm 1/2 liegen dicht, Label sitzt unter dem Gebäude).

## Textliste „unklar → besser“
| Ort | Jetzt | Besser |
|---|---|---|
| Vorschau-Panel | „Kette 1 Getreide, Mehl: Farm 19 und 35, Mühle 25 Felder. Absatz Mittelfurt 150 Felder.“ | „Kette: 2 Farmen (19 und 35 Felder entfernt) → 1 Mühle (25) → Mittelfurt (150 Felder weit)“ |
| Ring-Labels | „25 F.“ „35 F.“ „19 F.“ | Name + Entfernung: „Mühle · 25 Felder“ |
| Lizenzknopf | „Ertrag ca. 145 $/Monat“ | „Ertrag ca. 145 $ pro 30 min Lizenzzeit“ (oder /min) |
| Hinweis nach Linie | „Tempo 2× oder 4× oben links“ | „… oben rechts“ |
| Brückenfehler | „Brücken nur gerade, nicht diagonal“ | „Hier ist eine Brücke nötig, die geht nur geradeaus. Baue die Straße in zwei Teilen (bis zum Ufer, dann gerade rüber).“ |
| Stadt-Fehler | „Gebäude im Weg: Mittelfurt“ | „Die Straße muss am Stadtrand enden – ziehe bis an die Häuser, nicht in die Mitte.“ |
| Nächster Schritt (nach Lizenz) | „Lizenz für Mühle 1 kaufen, Straße bis Mittelfurt …“ | Nur noch offene Teile zeigen: „Straße bis Mittelfurt bauen (ca. 1.300 $), dann Linie Mühle 1 › Mittelfurt“ |
| „Umsetzen möglich, noch 2:00“ | schwebt über Karte | „HQ noch 2:00 min kostenlos verschiebbar (Ring anklicken)“ |
| Top-Leiste | „1 Skillpunkt gespart“ | Erklären oder entfernen (nie verstanden, springt die Leiste breiter) |
| Linienliste | „Gewinn −2 $/min“ bei Ziel „Lieferungen mit Gewinn“ | Ziel „3 Lieferungen mit Ertrag“ oder Linie als Gewinn rechnen |
| Lager-Toast | „bezahlt wird erst beim Endabnehmer“ | Vor dem Bau warnen: „Lager bringt allein keine Einnahmen“ |

## Bekannter Fund (bestätigt)
Ziele nennen „Getreidefarm 2“, aber `buy_licence farm_1` hakt „Lizenz für Getreidefarm 2 kaufen“ ebenfalls ab (Gegenprobe in frischer Session, Nachweis `sess_b/shot.png`). Zusatz: bei Straße/Linie gilt es nicht – dort zählt Farm 2, die Straße-Zielerfüllung kommt auch über ein verbundenes Netz (Farm 2 → Farm 1 → Mühle).

## Bugs
| # | Schwere | Befehlsfolge | Beschreibung |
|---|---|---|---|
| 1 | hoch | `…found_hq`, `road getreidefarm_2 muehle_1` | Diagonale über Fluss abgelehnt. Fahrbar nur mit Umweg über Farm 1. Spielbarkeit: Pflichtziel schwer lösbar. |
| 2 | hoch | `road muehle_1 mittelfurt` / `road mittelfurt muehle_1` / `rail muehle_1 mittelfurt` | „Gebäude im Weg: Mittelfurt“ bzw. „Brücke zu lang (max. 8 Felder)“ – Straße an die Stadt nicht baubar, Ziel 7 (M3) blockiert. Haberau identisch. Evtl. nur Tool-Zielpunkt (Stadtmitte), dann Hinweis fürs Spiel: Stadtanschluss nicht erklärt. |
| 3 | mittel | `road getreidefarm_2 haberau` | „nichts gebaut“, aber kein Toast. |
| 4 | mittel | nach `truck_line muehle_1 mittelfurt` ohne Straße | state.md meldet „Fehler: keiner“, im Toast steht „Keine Straßenverbindung“. |
| 5 | niedrig | nach `buy_licence muehle_1` | „Nächster Schritt“ unverändert (stale). |
| 6 | niedrig | `truck_line farm_2 muehle_1`, 5 min | Linie „Verlust −2 $/min“, Ziel „3 Lieferungen mit Gewinn“ trotzdem abgehakt; Kosten 90 $/min in Kopfleiste unplausibel zu Linien-Anzeige. |
| 7 | niedrig | Start | Hinweis „oben links“ statt rechts; Mühle „ohne Lizenz“ verarbeitet trotzdem. |
| 8 | niedrig | `warehouse 392 226` | „Hier ist kein Platz für ein Lager“ neben der Stadt – nicht erkennbar warum. |

## Top-5 UX-Verbesserungen für Sprint 7
1. **Straßen-/Brücken-Routing**: Knickpfad oder Auto-Brücke; farbige Bauvorschau mit Fehlstelle und Preis vor dem Loslassen.
2. **Stadtanschluss klar machen**: Abnahmepunkt am Stadtrand markieren, Drag auf die Stadt dockt am Rand an; Ziel 7 muss damit lösbar sein.
3. **Fehlermeldungen mit Lösung** und nie stumm (Brücke, Gebäude im Weg, kein Platz, keine Verbindung).
4. **„Nächster Schritt“ live halten** (stale Lizenz-Hinweis), mit Preis, und Ziele eindeutig auf das Objekt zeigen lassen (Pfeil + Label direkt über der Farm; Farm 1/2 unterscheidbar; Ziel-ID = Pfeilobjekt).
5. **Zahlen verständlich**: Ring-Labels mit Namen, „Monat“ durch Spielzeit-Einheit ersetzen, Gewinn/Verlust-Anzeige konsistent zu Zielen; Lager-Warnung vor dem Bau; „Skillpunkt gespart“ erklären.

## Gesamturteil
Die ersten zwei Minuten (Vorschau, Ziele, Pfeil, Lizenz, Lkw-Linie) führen mich sauber an der Hand, danach kippt es an Fluss und Stadtanschluss in Trial-and-Error ohne Anleitung – das Endziel M3 blieb für mich unerreichbar und kostete 4.000 $.

## Lieblos (D21)
- Fehlermeldungen als nackte Systemtexte ohne Handlung; stille Fehler.
- Ring-Labels „25 F.“ ohne Einheit/Name, Karten-Label „Umsetzen möglich“ ohne Rahmen.
- Kopfleiste „1 Skillpunkt gespart“ ohne Icon/Erklärung; Kopfleiste verschiebt sich beim Auftauchen.
- Lager als Pseudo-Gebäude ohne Panel-Erklärung; Stadt als bunter Klotz ohne sichtbaren Andockpunkt.
