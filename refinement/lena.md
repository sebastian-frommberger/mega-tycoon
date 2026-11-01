# Refinement S2 – Lena (Lead Game Design)

## Meine Tickets

**L-06 Diagnose-Playtest – Spike, 5 Tage, unverhandelbar.**
Leitfrage: Finden Spieler in einem kaputten Netz die Wurzelursache selbst, oder nur das Symptom? Wenn das nicht trägt, brauchen wir kein Gate.
- 5 Fehler eingebaut, je Fehler Wurzelursache und Zielzeit dokumentiert (2,5 T bis 19.11.)
- Mit 5 Testern durchgeführt am 25.11.: ≥ 3 von 5 finden mind. 3 von 5 Fehlern, Median ≤ 3 min je Fund
- Bei ≥ 3 von 5 Testern liegt die Ursache nach dem Fund richtig, nicht nur das Symptom (Laut-Denken-Protokoll)
- Auswertung bis 26.11. mit Go/No-Go-Empfehlung
- Abhängig: F-04 (nur Diagnose-Teil), F-06, Daniel, Aylin

**L-05 Paper-Prototyp HQ-Start – Spike, 1,5 Tage, bleibt drin.** Kostet Felix null.
Leitfrage: Verstehen Spieler die Stadtwahl, und entsteht der Kaufwunsch?
- 3 Runden à 30 min mit Leuten außerhalb Design
- ≥ 2 von 3 begründen ihre Stadtwahl über die Ketten
- ≥ 2 von 3 wollen vor Minute 25 eine Firma kaufen
- Abhängig: T-05 Startwerte bis 16.11., sonst nehme ich Platzhalter

**L-03 Meilensteinleiste – runter auf 1 Tag, als Spike.** Nur 1a–3, gerade so viel, wie der Paper-Prototyp braucht. Ergebnis: Tabelle mit Auslöser, Lernziel, Zielzeit. Den Rest mache ich in S3 zusammen mit den Specs.

**L-04 Skilltree-Datentabelle – schiebe ich nach S3.** Das ist Produktionsarbeit, für das Gate egal. Dann brauchen wir auch F-09 nicht jetzt.

## Einwände

1. **F-07 Bau-Spike, 5 SP.** Das ist neben F-04 und F-05 der dritte große Felix-Block, und er liegt zeitlich genau vor meinem Playtest. Gegenvorschlag: Timebox 2 Tage, nur 45°-Raster ohne Kurvenglättung, als Stretch-Ziel. Wenn F-04 wackelt, fliegt F-07 zuerst raus, A-06 gleich mit.

2. **S-03 Look-Test braucht die MultiMesh-Szene.** Sophie wartet sonst bis 20.11. auf Felix. Gegenvorschlag: Look-Test auf Basis ihrer Maßstabsband-Szene plus Paintover, MultiMesh wird erst in S3 nachgezogen. Und S-06 Silhouetten auf 3 Tage kürzen, die Industrieliste ist eh nicht final.

3. **T-07 Headless-Sim, 5 SP.** Hängt an der SimWorld-Schnittstelle und beantwortet keine Gate-Frage. Gegenvorschlag: nach S3 verschieben, Tobias rechnet dafür T-05 sauber durch, das brauche ich direkt.

4. **K-06 doppelt sich mit L-06 und Daniel.** Drei Leute organisieren denselben Test. Gegenvorschlag: K-06 auf 0,5 Tage – Raum, Termin, Tester-Gutscheine. Testleitfaden und Durchführung liegen bei mir und Daniel.

5. **D-04 mit eigenen 6 Deadlock-Szenarien.** Gegenvorschlag: Daniel testet F-04 mit meinen Playtest-Fehlern 1 und 2 plus 2 eigenen. Dann ist D-04 gleich die Abnahme des Testbuilds, das spart einen Tag.

6. **A-04 und A-05 getrennt.** Gegenvorschlag: Datenvertrag nur für die 5 Testfehler, zusammen mit dem Klickprototyp. Was der Feed im Playtest nicht anzeigt, brauchen wir jetzt auch nicht zu spezifizieren.

## Meine Kapazität und Forderung

| Ticket | Tage |
|---|---|
| L-06 Szenario | 2,5 |
| L-06 Durchführung + Auswertung | 2,5 |
| L-05 Paper-Prototyp | 1,5 |
| L-03 Leiste 1a–3 | 1 |
| Puffer Gate-Input | 0,5 |
| **Summe** | **8** |

Meine Forderungen:
- **Felix priorisiert so:** F-04 (nur Diagnose-relevant) → F-06 → F-05. Danach erst F-07 und F-08. Build-Freeze am 23.11., Playtest am 25.11.
- **Fallback, falls F-04 am 20.11. nicht steht:** Der Playtest läuft trotzdem, dann mit präparierten Saves und einem geskripteten Fake-Feed. Ich teste die Lesbarkeit der Diagnose, nicht die Signallogik. Das kommt so ins Ticket, damit am 21.11. keiner darüber diskutiert.
- **Sprintziel:** Der Bau-Spike kommt raus aus dem Ziel und wird Stretch. Das Ziel heißt dann: „Diagnose-Playtest gelaufen und ausgewertet, Benchmark liegt vor.“
- Tobias liefert Startwerte bis 16.11., Daniel rekrutiert 2 Neulinge und 3 TF/OpenTTD-Spieler bis 20.11.
