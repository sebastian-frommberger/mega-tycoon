# Lernbericht Tobias (Ökonomie und Balancing), 03.11.2026

Zu `SKILL.md` im selben Ordner. Schreibt die Selbstanalyse, die Lernfragen, die Kernerkenntnisse und die Grenzen der Fortbildung fest. Alle Repo-Verweise relativ zu `/home/claude/mega-tycoon/`.

## 1 Selbstanalyse (Schritt 1): wo Wissen fehlte und wo das Team unsicher war
Gelesen: `design/economy/`, `sprints/s7/block-b/tobias.md`, `g01_progression.md`, `sprints/s8/design-sprint/` (charter, phase2 01–06, phase3 11–14, phase3b 15, phase4 `tobias_welle1.md` samt Daten, `stadt_welle1.md`), `concept/tobias.md`, `slice/data/economy_constants.json` und `economy_slice.json`, `slice/economy.gd` (Sättigung, Lieferung), `refinement/tobias.md`.

Muster der Unsicherheit im Repo (jeweils mit Beleg):
- K18 Marktflecken-Knick: „unverändert, an Tobias S8“ (`phase3/11_streitprotokoll.md` K18). Wirkung gemessen und groß (`tobias_welle1.md` §1, §5).
- Umland-Nachfragemodell: nur auf der 8-Orte-Slice-Karte mit dem Bot gemessen, kein Wachstum im Slice-Code (`tobias_welle1.md` §2.1, §7 Punkt 1 und 7).
- Kredit/Zins/Bankrott: kalibriert auf Slice-Karte (T-15/T-16); Entwurf T-05 sagt „ab Minute 0, 1 %/min“, Slice sagt „ab Minute 12, 3 %/min“ (`design/economy/day4-6/t05_final.md` §3, `slice/data/economy_constants.json`).
- Schwierigkeitsstufen: Preset-Zahlen Schätzung ohne Lauf (`tobias_welle1.md` §6.3), Entscheid S8.
- Konkurrenz-Bot: kein Code, 15 % passiv und Startminuten 45/35/20 Platzhalter (`g01_progression.md` §6 Frage 5, `15_regelwerk_v1_1.md` §D).
- Epochen-Skalierung: zwei Epochentabellen, Ökonomie späterer Epochen „eigener Sprint“ (`15_regelwerk_v1_1.md` A3).
- Siedlungshierarchie: aus [~]-Fachwissen abgeleitet, Generator lief nicht auf der echten Welt (`stadt_welle1.md`).
- Skilltree/Progression nach M7: G-01 mit sechs offenen Fragen an Tobias, keine Zahl kalibriert.
- Wasser/Floß: Mechanik offen (F10, E15), Tobias: „Schiffe sind eine eigene Kette mit Kalibrierung“ (K34).
- Fahrzeug-Easing: nur Darstellung, damit T-15 unberührt (K27).

Nicht in der Tiefe gelesen: `refinement/` außer Tobias, `concept/industry.md`, `concept/hq.md`, `design/ux`, `design/qa`, `design/art`.

## 2 Priorisierte Lernfragen (Rangfolge nach Wirkung auf das Spiel mal Unsicherheit)
Status: beantwortet / teilweise / offen. Ort der Antwort im Skill in Klammern.

1. K18 und Nachfragemonotonie: Wie bekommt man eine Nachfragefunktion, die mit Einwohnern und Klasse nie fällt? Status: teilweise. Neu: Sättigung wird je Einheit gerechnet (`slice/economy.gd:353–357`, `:780–800`); eine Stufe-1-Verarbeiterlinie mit 20 E/min verliert bei Nachfrage 12 etwa 19 % Erlös, bei 8 etwa 44 % (Skill B12). Offen: Multiplikator Marktflecken ≥ 1,5 oder gleitender Übergang, Entscheid S8 (B7).
2. Umland-Nachfragemodell: Trägt Sim-EW = Ort-EW + Umland-EW auf der echten Welt (15–21 Knoten, Spieler wählt Senke)? Status: teilweise (Bot-Obergrenze des Schadens; Mindestnachfrage 18/min oder k = 1,25/1,5, B8). Offen: Messung auf Generator-Welt.
3. Kredit, Zins, Bankrott: Welche Regel ist bei Referenzspielen üblich? Status: offen. Keine geprüfte Quelle (OpenTTD-Bankrottregel nur [~]), Konflikt t05/Slice (B5).
4. Schwierigkeits-Presets: Sind die Stufen messbar? Status: teilweise. Hebel extrem steil (500 $ von 16,9 % auf 1,1 %); in 500-$-Schritten messen (B9, A9 Punkt 6).
5. Konkurrenz als Bot-Spielfigur: Wie rechnet man Marktanteil und Preiskampf? Status: offen. Nur Nachfrageverlust-Modell (Dorf-Senken 3–15 % Ertrag), keine Ortswahl durch KI (B9). Quelle: OpenTTD-KI-Einstellungen geben Rahmen, keine Zahlen (A5).
6. Stadtwachstum ökonomisch: Trägt Variante B (180 bp/Monat, Bänder 80/50/30 %)? Status: offen. Konstanten „ungetestet“ und im Slice nicht verdrahtet (B4); Referenz OpenTTD-Wachstumsintervalle (A3). Zielzeiten Dorf → Kleinstadt 12 min, → Stadt 80 min nur auf Slice-Takt (Skill gamedesign B10).
7. Skillpunkt-Quelle und Progression: Welche Punktquote hält Plateau und Exploit-Freiheit? Status: offen. Zwei Konzepte (G-01 Meilensteine, `concept/lena.md` Ast-XP), keine Zahl.
8. Epochen-Ökonomie: Nachfrage einer 100k-Stadt ist 5× die einer 20k-Stadt. Status: offen, eigener Sprint (`15_regelwerk_v1_1.md` A3).
9. Kettendurchsätze 1820 (Mühle, Hütte, Meiler): Welche Mengen sind historisch plausibel? Status: offen. Mühlendichte belegt (0,52 ländliche Mühlen/Dorf), Mahlleistung fehlt, Holzkohleausbeute widersprüchlich (A8 [S]).
10. Floß/Wasserkette: Einbahn-Wandler kalibrieren. Status: offen. Reale Größen belegt (A8), Rückreise nicht belegt.
11. Methodik: Wie misst man zuverlässig mit einem Bot? Status: beantwortet (A7: OAT-Grenze, Morris/Sobol/LHS, Intervalle je n, gepaarte Seeds, Hub-Artefakt, zwei Messpunkte).
12. Sättigungskurve bei 150 %: Der Sprung von 0,4 auf 0,1 ist eine Unstetigkeit; gewollt? Status: offen, neu gefunden (B12), keine Datei begründet sie.

## 3 Die fünf wichtigsten Erkenntnisse
1. Sättigung wirkt je gelieferter Einheit und je Periode. Rechnung aus dem Code: Dorf 900 EW (18/min) lässt eine 20-E/min-Kette bei 99 % Erlös, Dorf 650 EW (13/min) bei 86 %, Marktflecken 1.200 EW (12/min) bei 81 %, Dorf 400 EW (8/min) bei 56 %; mit doppeltem Angebot sinkt der Anteil auf 63/48/45/33 %. Das erklärt die Bot-Befunde unter 15/min und den K18-Knick (`slice/economy.gd`, `tobias_welle1.md`).
2. Die Gesamtquote täuscht: Bankrott@30 gesamt 17,8 % (n = 2.700, im Band), aber 27–35 % bei Senken unter etwa 15/min; Gegenmittel: `demand_per_100` ×1,25 bis ×1,5 oder Mindestnachfrage 18/min (`tobias_welle1.md` §1, §4).
3. Presets sind steil: 500 $ Startkapital verschieben Normal von 16,9 % auf 1,1 %; Preise nur in 500-$-Schritten messen, nicht schätzen (`tobias_welle1.md` §6.1).
4. Bot-Messung ist nur so gut wie n und Design: ±7 Punkte bei n = 100, 9 Läufe lösen 15 % nicht auf; gepaarte Seeds, zwei Zeitpunkte (@30/@60), Hub-Artefakt beachten; Bot ist für kleine Senken pessimistisch (A7, B6).
5. Externe Referenzen liefern Vergleichswerte, aber keine Bankrottregel: OpenTTD-Frachtbasis und Zeitfenster (S1), Wachstumsintervalle (S5), Presets 2/4/7 Konkurrenten, 300k/150k/100k Kredit, 2/3/4 % Zins (S14) sind belegt; die Bankrottregel bleibt [~].

## 4 Was ich künftig anders mache
- Jede Ökonomie-Änderung als gepaarter Bot-Lauf mit Kontrollkette und Intervall, vorher Zielgröße und Zeitpunkt festlegen.
- Preset-Preise erst messen (500-$-Raster), dann schreiben.
- Eine Epochentabelle, eine Skillpunkt-Quelle und eine Kreditregel (Minute 0 oder 12) einfordern, bevor kalibriert wird.
- Fan-Dokumentation (TTDpatch, TTWiki) als „Original-TTD“ kennzeichnen, nicht als aktuelles OpenTTD.
- Die Sättigungskurve auf Stetigkeit und Grenznutzen prüfen, bevor Preise angepasst werden.

## 5 Ehrliche Einschränkungen
- Reddit war per WebFetch gesperrt (SITE_BLOCKED) und wurde nicht umgangen; es gibt keine Reddit-Quellen. tt-forums.net (Anubis) und wiki.openttdcoop.org (robots) ebenfalls nicht lesbar. WebFetch ließ nur URLs aus Suchtreffern zu.
- 38 Quellen im Skill gelistet, aber einige dünn: GDC Vault Albion (nur Beschreibung), Routledge Game Balance (nur Inhalt), Pfister (Zusammenfassung ohne Zahlen für 1800/1850), Anno-Wiki (keine Verbrauchszahlen), gameplay.tips und dedoimedo (Einzelmeinungen), Steam-Thread (Forenstand 2023).
- OpenTTD-Frachtformel steht im Wiki nur als Bild: Formelform [~], nur die Tabellenwerte sind belegt. Simutrans-Formel nicht abrufbar. OpenTTD-Bankrottregel nicht belegt.
- Historische Mengenparameter (Mahlleistung, Köhlerausbeute) widersprüchlich oder fehlend.
- Eigene Rechnungen ([R]) sind Plausibilitäten aus den Konstanten, keine neuen Bot-Messungen. Die Sättigungstabelle (B12) nimmt gleichmäßige Lieferung und ein Angebot von 20/40 E/min an und lässt Preis, Zeitfaktor und Kredit weg.
- Die Fortbildung hat nichts im Repo geändert und nichts committet.
