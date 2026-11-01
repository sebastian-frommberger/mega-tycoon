# Position DESIGN (Lena Hoffmann, Tobias Brandt), Refinement S7

## Kandidaten
| ID | Urteil | Tage | Messbare Akzeptanz |
|---|---|---|---|
| W-05 Lage-Logik | **rein** (Kern von S7) | L2 T2 S1 | Karte aus Regeln: 0 Regelverstöße im Validator, je Industrie-Typ 3–6 Instanzen, keine Stadt hat >1 Typ im 1,5-km-Umkreis als "Spezialität" (Gini der Typ-Verteilung je Stadt < 0,5) |
| W-06 Generator | **kleiner**: nur Validator + Seed-Reproduzierbarkeit, kein Editor | F1,5 T1 | Gleicher Seed = identische Karte; 20 Seeds, 0 unlösbare Karten |
| W-01 Maßstab | **rein**, Sim bleibt in Feldern (s. u.) | F2 T0,5 S1 | Bench- und Regressionswerte unverändert (13/13 grün), nur Darstellung skaliert |
| T-15 Balance | **rein, kleiner** (E1 schließen, Zins, Lkw/Zug) | T2 | Proxy-M7 Kohlberg 30–40 min auch mit Mehlast; Zug : Lkw je Strecke max. 3:1 |
| G-01 Progression | **rein** (Konzept 2 T + 1 T Umsetzung in SK-02) | L2 | Playtest: nach M7 mindestens 3 offene Ziele, kein Leerlauf >3 min ohne Entscheidung |
| W-02 Terrain | **kleiner**: Heightmap + Rand + Kamera, Höhe in Sim **raus** | F1 S3 | Kamera sieht bei Max-Zoom nie Himmelskante; Ladezeit ≤ 3 s (vorgebacken) |
| W-03 Städte | **raus** aus S7 (S8), nur Radien-Daten | L0,5 | Radien je Stufe in Daten, Nachfrageformel unverändert |
| F-22 Firmenkauf | **raus** (S8) | – | – |
| SK-02 | **kleiner**: Punktequelle entscheiden, Anzeige, 1 Ast | L1 M2 | Punkte sichtbar, 1 Ast kaufbar |

## Lage-Logik (Skizze, Entfernungen TF2-artig, 25 m/Feld, Stadt = Zentrum)
1. Farm: Ebene/Aue, Steigung < 3 %, 1,5–4 km von der nächsten Stadt, 300 m Mindestabstand zum Fluss-Hauptbett.
2. Mühle: Fluss oder Stadtrand, 0,8–2 km von einer Stadt, 2–5 km von mindestens einer Farm.
3. Kohle/Erz: Gebirgsfuß (Steigung 8–20 %), 3–6 km von jeder Stadt; Kohle und Erz mindestens 1,5 km auseinander.
4. Stahlwerk/Kraftwerk: Flachland nahe Kohle (2–5 km), nie im Gebirge.
5. Werkzeugfabrik: Stadtrand einer Stadt ab 8.000 EW, 1–2 km.
6. Holz/Sägewerk (später): Waldrand, Hang < 12 %.
7. Mindestabstand Industrie–Industrie gleichen Typs 4 km; kein Typ-Cluster größer als 2 Instanzen in 5 km (gegen "Bergbau-Ecke").
8. Jede Stadt hat 2 verschiedene Zulieferer-Typen in 6 km, aber nie alle.

## Maßstab der Ökonomie
**Distanzen bleiben in Feldern.** Lizenz, Fernzuschlag, Mindestdistanz, A*-Gitter, Bench: unverändert. Nur Meter pro Feld ändert sich; Fahrzeiten pro Feld bleiben (Spielzeit ist gestaucht, wie bei RE). Sichtbar fahren Fahrzeuge dann real schneller, das akzeptieren wir. Eine Neuskalierung wäre ein halber Balance-Sprint ohne Spielerwert.

## Skilltree-Punktequelle (Dissens)
- **Lena:** Meilensteine plus Transport-XP (Tonnenkilometer), sonst hat Dauerspiel keinen Fortschritt.
- **Tobias:** nur Meilensteine; XP aus Transport belohnt Lkw-Masse (E4) und ist exploitbar.
- Kompromissvorschlag an Jonas: Meilensteine, dazu XP gedeckelt je Zeitfenster.

## Progression in 3 Sätzen
Nach M7 kommen Szenarien-Etappen (z. B. 100k bis Minute X, Stadt auf 20.000 EW bringen) als Fernziele bis 60 min. Druck entsteht über Stadtwachstum und Nachfrage, die ohne Belieferung sinkt, sowie Lizenzverlängerung mit Preisanstieg. Das Gegengewicht zum Zug: Gleisunterhalt und Brückenkosten, der Lkw bekommt die Kurzstrecken-Rolle.

## Widersprüche zu anderen Disziplinen
1. **Firmenkauf jetzt vs. Welt-Fundament:** Basti sagt ja zu F-22 in R2, wir sagen S8. Ohne neue Kartenlogik wäre jeder Firmenpreis auf Wegwerf-Industrien kalibriert.
2. **Terrain-Höhe in der Sim:** Felix/Sophie wollen Steigung und Tunnel in W-02. Wir sagen raus: Höhe nur Optik, bis Distanzen und Lage-Logik stabil sind. Sonst verschiebt sich jede Balance-Zahl doppelt.
3. **Kleinbugs/Stadtanschluss (Z-01) vs. Neubau W-04:** Z-01 sofort fixen, nicht auf neue Straßen warten; Aylins Ziel hing daran.
4. **Industrie-Größe:** Sophie will 150–300 m Fläche; wir wollen, dass Lage lesbar ist (Icons in der Übersicht ab 2 km) und keine Kartenfläche pro Industrie belegt wird.

## Vorschlag Sprintziel
Eine neue 25-m-Karte mit Heightmap-Rand und regelbasierter, validierter Industrie-Verteilung ist spielbar, die Balance-Exploits sind geschlossen, und nach M7 gibt es Fernziele bis 60 Minuten.
