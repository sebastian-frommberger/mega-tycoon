# Lernlog mt-oekonomie

Zweck: Kompromisse, Workarounds und "wusste ich nicht"-Momente zählen (Lern-Routine, Punkt 5). Zähler 2 für dasselbe Thema löst eine Recherche aus (Trigger b). Geschlossene Lücken wandern in den Skill, dann hier als erledigt markieren.

| Datum | Situation | Kompromiss / Lücke | Zähler | Folge (Recherche, Quelle, Skill-Eintrag) |
|---|---|---|---|---|
| 2026-11-03 | Einführung der Routine | (noch kein Eintrag) | 0 | |
| 2026-11-03 | S6 bis S8 | Kalibrierung auf der Slice-Karte statt Zielkarte | 5 | Prozessänderung: Bot auf Generator-Welt |
| 2026-11-03 | S6/S7 | Platzhalter-Parameter ohne Messung; zu kleines n | 3 | Messpunkt je Parameter, n >= 300 |
| 2026-11-03 | Recherche | Zins nie in Jahreswerten verglichen | 1 | 3 % je Spielmonat = etwa 36 % p.a.; Referenzwerte im Skill nicht neu geprüft |
| 2026-11-03 | Recherche | Holzkohle 6,75 Zentner/Rm im Skill | 1 | Etwa 20 % Masse, etwa 100 kg je Rm (zwei Quellen, Einheiten uneinheitlich); Korrektur vorgeschlagen |
| 2026-11-05 | FK-02 Werksunterhalt | economy.gd liefert `works_upkeep_cent_pro_periode()`, gebucht wird beim Aufrufer über konto (ProtoSim noch nicht verdrahtet, Felix); im Skript-Szenario per `konto.charge` je Periode | 1 | Felix FK-02-Anteil (konto/proto) |
| 2026-11-05 | FK-02 Schneeball | Kriterium "keine Verdopplung Netto in 10 min nach 1. Kauf" ohne Bezugsbasis: vor dem Kauf ist Netto klein (42 $/min, k = 1), Faktor 19,7 sagt nichts; auch OHNE Kauf ×7 | 1 | Vorschlag: Bezug KAUF gegen OHNE-Variante gleicher Seeds (QT-03) |
| 2026-11-05 | FK-02 Platzhalter | Puffer-Deckel 2 Perioden und +25 % je Werk ohne Messung (Thema Zeile 3, damit Zähler 4) | 4 | Bot-Messung QT-03; Trigger b erreicht: Recherche "Eingangslager-Deckel in OpenTTD/TF2" offen |
| 2026-11-05 | OE-02 Kalibrierung | Zeitabhängiger Fix kann X1 bei k = 4 nicht halten, ohne die kurze Getreidestrecke negativ zu machen (Ladekosten c0 ≈ 15·s); Ausweg Fahrkosten je Feld. Modell N(d) = p·D_eff·F − s·d − c0 trifft die Sim auf ±1 % bei vollen Ladungen | 1 | Skill-Kandidat: X1-Fenster 0,56·p ≤ s ≤ p − c0/20 [R+M] |
| 2026-11-05 | OE-02 Messwerkzeug | Seit FX3 zählt der Bot den Firmenkauf in netto_op doppelt; Amortisation/Schneeball aus qt03b_auswerten.py sind für neue Läufe Artefakte; eigene Korrektur in amort.py | 1 | Daniel QT-03c |
| 2026-11-05 | OE-02 Naiv-Band | Band 10–30 % mit S8-Naiv-Bot nicht erreichbar (Bestand und Set gleich 55 % bei gleichen Schaltern); nicht auf das Band hin gedreht | 1 | Jonas/Daniel: Band oder Definition |
