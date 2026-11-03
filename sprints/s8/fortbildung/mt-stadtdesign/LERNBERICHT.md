# Lernbericht Stadt-/Level-Designer, 03.11.2026

Zu `SKILL.md` im selben Ordner. Alle Repo-Verweise relativ zu `/home/claude/mega-tycoon/` (`ds/` = `sprints/s8/design-sprint/`).

## 1 Selbstanalyse (Schritt 1): wo Wissen fehlte und wo das Team unsicher war
Gelesen: `ds/charter.md`, `ds/phase2/01_skalen.md`, `03_welt_prinzipien.md`, `04_schwierigkeit.md`, `05_stadtmodell.md`, `06_verteilung.md`, `ds/phase3/11_streitprotokoll.md`, `12_welt_regelwerk_v1.md`, `ds/phase3b/15_regelwerk_v1_1.md`, `ds/phase4/stadt_welle1.md`, `tobias_welle1.md`, `slice/world/data/proto/regelwerk.json` und `proto_orte.json`, `sprints/s8/feedback_02-11/basti_feedback_02-11.md`, `ds/referenzen.md`.

Unsicherheiten im Repo selbst (Zählung der Marker): `01_skalen.md` 45 × [~], `05_stadtmodell.md` 21 × [~] und 12 × [A], `06_verteilung.md` 14 × [~] und 12 × [A], `15_regelwerk_v1_1.md` 11 × [~]. Fast alle Zahlen zu Hierarchie, Eignungsgewichten, Dorfzahlen und Abständen sind also „aus Fachwissen“, nicht gemessen.

Wiederkehrende Unsicherheit mit Beleg:
- Siedlungshierarchie: K1 Annahme (Szenario B+), mit F1 = E6 bestätigt; Zahlen 2/2–3/12–16 aus [~] hergeleitet.
- Marktflecken-Knick K18 und Umland-Modell: Bot-Stichprobe auf 8-Orte-Slice-Karte (`tobias_welle1.md`).
- Generator nie auf der vollen Karte mit 15–21 Knoten gelaufen; Prototyp-Fenster 2×1,6 km (`stadt_welle1.md`).
- Dorf–Kleinstadt-Abstand 1,70 km statt 2,5 km im Prototyp (Abweichung 1).
- Stadt-KI Schritte 3, 5, 6 (Teilung, Gasse, Platz) nicht implementiert und nicht getestet.
- Straßenrichtungen: Sim nur 4 Richtungen (`DIAGONAL_MODE_NEVER`), Regelwerk v1 §7 nennt 8; „Klärung in W-04b“ (`15_regelwerk_v1_1.md` B1).
- Clark-Evans-Band Orte: 1,0–1,6 gegen 1,2–1,7 (`06_verteilung.md`).
- Wasser als Siedlungsfaktor und Floßplätze: Kulisse, Mechanik offen.

## 2 Priorisierte Lernfragen
Status: beantwortet / teilweise / offen. Ort im Skill in Klammern.

1. Wie begründet man die Siedlungshierarchie belastbar? Status: teilweise. Christaller K=3 (Abstände 1,6 → 2,8 → 4,8 → 8,3 km), Rang-Größe (Ränge 1–5 und 12–19 passen), Zahl der Zentren (K=3 gibt 2 : 4 : 12, Regelwerk 2 : 2–3 : 12–16), Lücke Ort-EW 360–670 ohne Klasse (A1, B3). Kein Beleg, dass das Repo K=3 meint.
2. Marktflecken-Mangel und K18: Fehlt eine Zwischenklasse, oder ist der Sprung gewollt? Status: offen. Option „Großdorf 400–700“ als Vorschlag (B12); Wirkung auf Ökonomie siehe `mt-oekonomie` B7.
3. Generator auf voller Karte: Erfüllbarkeit ≥ 18 von 20 Seeds, Laufzeit, Clark-Evans je Seed. Status: offen (B8 Punkt 3).
4. Siedlungsform nach Lage: Haufen/Straße/Anger/Reihendorf. Status: teilweise. Quellenlage zu Formen gut, zu Verbreitung dünn (A2, C5); Gewichte 50/25/15/10 sind Annahme (B5).
5. Eignungsgewichte (+300, +250, −400 …): Wie stark hängt das Ergebnis daran? Status: offen. Gewichte [~]/[A]; Methodik Morris/Latin-Hypercube vorgeschlagen (B12 Punkt 3).
6. Dorfdichte und Ortszahl 1820 (12–16 Dörfer auf 164 km²). Status: offen. Nur Kurmark-Mühlendichte (0,52 ländliche Mühlen je Dorf, 40 % Wasser) als Eichwert; keine Dorfdichtequelle gefunden (A3, C2).
7. Umland-Modell gegen Realität (Gemarkung, ≥ 30 % sichtbar als Weiler/Einzelhöfe). Status: offen; Voronoi der Knoten ist Setzung (B2).
8. Stadtwachstum und Stadt-KI: Reihenfolge Lücke, Upgrade, Teilung, Vorstadt, Gasse, Platz. Status: teilweise. OpenTTD-Muster (Ersetzen durch größere Häuser) stützt „verdichten vor ausdehnen“ (A6); 60-Monate-Lauf fehlt (B6, B12).
9. Wasser als Siedlungsfaktor (Furt, Mühle am Bach, Flößerort, Schwellweiher). Status: teilweise. Mühlenbezug und Flößerort belegt (A3, A7), Furt-Gewicht [~].
10. Straßenführung: 8 oder 4 Richtungen, Bild gegen Sim. Status: offen (B8, A10: Bild darf ±20° und ±8 m abweichen, Empfehlung im Repo).
11. Epochenfolge der Stadtbilder: Altstadtschutz, Raster nur mit Grund, Bahnhofsviertel. Status: teilweise. Entscheide K23/K24 und A4 belegt; keine externe Quelle für Anteile (≥ 30 % Altstadt, ≤ 40 % Raster).
12. Messgröße „konstruiert“: Clark-Evans-Band festlegen. Status: offen. Standardstatistik [~], Band widersprüchlich im Repo (B8 Punkt 4).

## 3 Die fünf wichtigsten Erkenntnisse
1. Die Hierarchie 2 / 2–3 / 12–16 ist plausibel: Abstände folgen grob Christaller K=3 (1,6 → 2,8 → 4,8 → 8,3 km gegen Regelwerk 1,6 / 5 / 7–9), Rang-Größe passt in Rang 1–5 und 12–19; zwischen Rang 6 und 11 (ca. 360–670 Ort-EW) liegt keine Klasse, und die Marktflecken sind knapp (2–3 statt 4 nach K=3). Das ist eigene Rechnung, das Repo zitiert Christaller nicht.
2. Die Regelwerk-Zahlen sind intern konsistent: Siedlungsfläche W1 ≈ 1,8 % (Grenze < 3 %), Ort-EW-Summe ≈ 12.100 (Erwartung ≈ 12.000), Häuserzahl × EW je Haus liegt innerhalb ±15 % der Klassenbänder (B3, B10).
3. Mühlendichte der Kurmark um 1800 (0,52 ländliche Mühlen je Dorf, davon ca. 40 % Wasser) ergibt bei 14 Dörfern etwa 3 Wassermühlen; Regelwerk 3–5 Mühlen passt zur oberen Seite (S12; B3 Punkt 6).
4. Algorithmen: Bridson kennt keine variable Dichte, darum Eignung als Akzeptanzwahrscheinlichkeit und Abstandsmatrix, nicht sättigen; WFC-Erfahrung (Bad North, Townscaper): harte gegen weiche Constraints, Erreichbarkeitsprüfung, Neustart bei Fehler (A5).
5. Der Generator ist im Prototyp-Fenster validiert (58 OK), aber nie auf der vollen Karte; Eignungsgewichte sind [~]; das Clark-Evans-Band steht in zwei Dokumenten verschieden; Straßenrichtungen Sim 4 gegen Regelwerk 8 sind ungeklärt (`stadt_welle1.md`, `06_verteilung.md`, `15_regelwerk_v1_1.md`).

## 4 Was ich künftig anders mache
- Generator zuerst auf der vollen Karte über viele Seeds testen, dann Regeln anpassen.
- Eignungsgewichte mit Sensitivitätsprobe (Morris, Latin Hypercube) absichern.
- Ortsklassen immer mit Rang-Größe-Test und Klassenlücken-Prüfung vorlegen.
- Zahlen mit Markern ([Q]/[A]/[~]) führen, Lagegrund je Ort im Datensatz speichern.
- Doppelte Zahlen in Dokumenten angleichen, bevor ein Validator sie übernimmt.

## 5 Ehrliche Einschränkungen
- Reddit (r/proceduralgeneration, r/CitiesSkylines u. a.) war per WebFetch gesperrt (SITE_BLOCKED) und wurde nicht umgangen. tt-forums.net und wiki.openttdcoop.org nicht lesbar. WebFetch ließ nur URLs aus Suchtreffern zu.
- 26 Quellen im Skill gelistet, mehrere dünn: Christaller (keine km-Zahlen), Haufendorf/Dorf (keine Lage/Dichte 1820), Pfister (nur Zusammenfassung ohne Zahlen für 1800/1850), Wassermühle-Artikel (keine Zahlen), Red Blob (Siedlungsideen vom Abrufwerkzeug), Watabou (Devlog-Meinungen), arXiv 2507.18899 (Vorschlag, qualitativ), Anno-Wiki, Steam-Thread. de.wikipedia Köhlerei und Bevölkerungsentwicklung nicht gefunden.
- Keine Quelle für Dorfdichte 1820 oder Verstädterungsanteil 1800/1850; die Regelwerk-Werte < 3 % Siedlungsfläche sind Setzung.
- Clark-Evans, Christaller-Abstände √K und Rang-Größe-Tabellen sind Standardwissen bzw. eigene Rechnung, in den geöffneten Quellen nicht mit Zahlen belegt.
- Keine Generatorläufe, keine Messungen durch mich; alle Prüfungen sind Papierrechnungen aus den Regelwerkszahlen.
- Die Fortbildung hat nichts im Repo geändert und nichts committet.
