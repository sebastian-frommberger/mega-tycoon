# Aufgabenkarten v1.1 für Bastis Rundgang durch den Prototyp „Welt“ (Aylin, Phase 4 Welle 2)

Hallo Basti, das hier dauert gut 25 Minuten und ist kein Test mit Prüfung: Du läufst durch eine kleine Welt (2 × 1,6 km, ein Dorf, ein Weiler, eine Kleinstadt, ein Gutshof, eine Mühle, Fluss, Bach, See) und sagst uns, ob sie sich nach Transport Fever / Railway Empire anfühlt. Es gibt kein Richtig oder Falsch. Was dich stört, ist unser Fehler. Notier Stichworte, am besten mit Screenshot (Windows + Shift + S). Die Karten bauen nicht aufeinander auf, du kannst eine überspringen.

Dies ist ein Prototyp zum Anschauen und Messen, kein Spiel: Du baust nichts, du kaufst nichts, es gibt kein Geld.

## Start (ca. 2 min)
1. Godot öffnen, Ordner `C:\Dev\mega-tycoon\slice` laden (Projektmanager → Importieren).
2. Play (F5). Das Startmenü öffnet sich. **Taste P** startet den Prototyp (an der Weltzeile steht „· P Prototyp Welt“). Alternative: Projekt → Projekteinstellungen → Editor → Run → **Main Run Args** auf `-- --proto` setzen, dann geht F5 direkt in die Welt.
3. Das Laden dauert unter 3 Sekunden. Oben links steht ein dunkles Feld mit Ansicht, Abstand und Schaltern.
4. Zurück ins Menü: **Esc**. Main Run Args danach wieder löschen.

**Steuerung**

| Taste | Was passiert |
|---|---|
| W A S D oder Pfeiltasten | Kamera schieben |
| Q / E | Kamera drehen |
| Mausrad | Zoom, von 40 m bis 3 km Abstand |
| Linke Maustaste ziehen | schieben |
| Rechte oder mittlere Maustaste ziehen | drehen |
| **1 2 3 4 5** | feste Ansichten: 1 Übersicht (3 km), 2 Dorf, 3 Markt in der Kleinstadt, 4 Fluss mit Brücke, 5 See |
| **V** | Wasser A / B umschalten (zwei Looks) |
| **G** | Easing an / aus (Fahrzeug-Bewegung: Anfahren, Bremsen, Kurven, Wippen) |
| **M** | Modelle aus / an (dann bleiben nur Gelände, Wege und Schilder) |
| **H** | dunkles Feld oben links aus / an |
| Maus auf ein Schild | Tooltip „Einzugsgebiet“ (kein Klick nötig) |

## Was du noch nicht siehst (ehrlich vorweg)
- **Der Markt-Ausschnitt in der Kleinstadt ist klein:** Markt 60 × 80 m, Stadtkirche, ein Tor, eine Gasse, rund 38 Gebäude. Die Stadt „setzt sich nach Westen fort“, aber dort ist nichts gebaut. Die 387 auf dem Schild sind nur die Häuser im Ausschnitt. Ein voller Stadtsektor kommt erst in Sprint 8.
- **Das Pferd ist ein Block-Pferd** (Kenney), im schlechtesten Fall ein Würfel; ein richtiges Pferdemodell (Quaternius) ist nicht eingebaut. Die Gangart zeigt nur die Beinphase grob. Uns geht es um Tempo und Bewegung, nicht um das Aussehen.
- **Häuser und Hofstellen sind Platzhalter oder einfache Kit-Modelle in der richtigen Größe**, ohne Feinschliff bei Farben und Dächern. Etwas knallig Rosa ist ein Platzhalter ohne Modell: bitte nur kurz melden.
- **Belebung ist dünn:** kaum Hofleben, keine Menschen. Wir wollen von dir wissen, was dir am meisten fehlt.
- **Wachstum (A10) ist ein Bild**, keine laufende Simulation.
- **Schilder:** Der Trendpfeil steht auf „gleich“ und der Bedarf auf „wird gebraucht“, weil der Prototyp noch nicht an die Wirtschaft angeschlossen ist. Das Einzugsgebiet von Lindenfurt (2.950) ist eine Annahme, bei Erlenbach (650) stammen die Zahlen aus dem Generator.
- **Wasser:** Flussufer können noch leicht treppig wirken, der Dorfteich ist eckig, der Bach ist aus der Nähe kaum als Graben zu erkennen.
- Es gibt keine Lkw, keine Züge im Betrieb und keine späteren Epochen im Bild.

## Karte A1: Von oben (ca. 2 min)
**Aufgabe:** Taste **1**. Finde Dorf (Erlenbach), Kleinstadt (Lindenfurt) und die Mühle (Erlenmühle), ohne etwas anzuklicken. Dreh die Karte einmal mit Q / E.
**Du siehst:** kleine Schilder mit Symbol und Name über den Orten. Das Gutshof- und das Mühlen-Zeichen sind farbig (gelb mit Weizen, weiß mit Mühlenrad), die Gebäude darunter bleiben neutral. Der Weiler hat aus der Ferne kein Schild. Die Orte sind kleine Cluster in einer großen Landschaft.
**Laut denken:** Hast du alles ohne Suchen gefunden? Wirken die Orte wie Inseln in der Landschaft oder wie Spielzeug? Fehlt dir aus der Ferne Information (z. B. Einwohner)?

## Karte A2: Zeichen ohne Modelle (ca. 1 min)
**Aufgabe:** In der Übersicht **M** drücken (Modelle aus), dann wieder **M**.
**Du siehst:** nur Gelände, Wege, Wasser und die Schilder.
**Laut denken:** Reichen Schild, Symbol und Wegelinie, um alles zuzuordnen? Siehst du Wege und Bach auch ohne Häuser?

## Karte A3: Proportionen auf der Dorfstraße (ca. 2 min)
**Aufgabe:** Taste **2**, dann mit dem Mausrad auf etwa 60 m an die Dorfstraße heranzoomen. Schau auf Haus, Straße, Zaun und, wenn eines vorbeikommt, das Fuhrwerk.
**Du siehst:** ein Bauernhaus ist etwa 12 m lang, die Dorfstraße 6 m breit, ein Fuhrwerk etwa 9,5 m lang. Das Schild schrumpft zu einem kleinen Namensfeld (nur Name), damit es nicht stört.
**Laut denken:** Stimmt das Verhältnis Haus : Straße : Fuhrwerk? Wirkt irgendetwas zu groß oder zu klein (Zaun, Tür, Pferd)? Fühlst du dich „klein“ in der Welt oder wie ein Riese?

## Karte A4: Durchs Dorf (ca. 2 min)
**Aufgabe:** In der Dorf-Ansicht langsam durch Erlenbach schieben, Abstand zwischen 40 und 200 m.
**Du siehst:** rund 35 Wohnhäuser, Kirche, Gasthaus, Schmiede, Höfe mit Gärten und Bäumen, die Kreuzung, den Bach am Rand. Aus der Nähe zeigt das Schild nur den Namen. Zoom zwischendurch auf 500 bis 800 m: dann stehen Name, Einwohner (244), Trend und Bedarf (Mehl, Fleisch) darauf. Fahr mit der Maus darauf.
**Laut denken:** Wirkt das wie ein Dorf um 1820? Ist in den Höfen etwas los? Was fehlt dir zuerst? Versteht der Tooltip „Einzugsgebiet“ (Ort, Umland, Zusammen), oder ist er zu viel Text?

## Karte A5: Kleinstadt (ca. 2 min)
**Aufgabe:** Taste **3**. Schau auf Markt, Stadtkirche, Tor, Gasse und den Bogen der alten Mauer. Zoom einmal heraus, bis das Fernzeichen (Stadt-Symbol + Name) erscheint.
**Du siehst:** einen kleinen Ausschnitt (siehe „Was du noch nicht siehst“). Das Schild von Lindenfurt ist größer als das von Erlenbach.
**Laut denken:** Wirkt der Ort wie eine Kleinstadt um 1820? Ist er zu geometrisch (zu gerade, zu gleichmäßig)? Zu groß oder zu klein gegenüber dem Dorf? Reicht der Ausschnitt für dein Urteil, oder fehlt dir die Stadt außen herum?

## Karte A6: Gutshof und Mühle (ca. 2 min)
**Aufgabe:** Zoom zum Gutshof (Gut Kuppenhof, im Südosten, gelbes Zeichen) und zur Erlenmühle (Mühlteich am Bach) aus 100 m, dann aus 2 km.
**Du siehst:** neutrale Gebäude. Farbig sind nur das runde Zeichen und der Name; darunter eine kleine Kette: Gutshof liefert Getreide, die Mühle macht aus Getreide Mehl, das Mehl geht ins Dorf.
**Laut denken:** Erkennst du beide, ohne dass das Gebäude farbig ist? Passt die Größe zu den Häusern (Gutshof 40 × 40 m, Mühle 12 × 12 m)? Verstehst du die Kette Getreide → Mehl auf einen Blick?

## Karte A7: Fahren (ca. 3 min)
**Aufgabe:** Such das Fuhrwerk (Gutshof → Mühle → Dorf) und die Postkutsche (Dorf ↔ Lindenfurt auf der Chaussee). Folge einem Fahrzeug durch die Kreuzung im Dorf und um eine Kurve. Dann **G** drücken (Easing aus) und dieselbe Stelle noch einmal ansehen, danach wieder **G**.
**Du siehst:** mit Easing: sanftes Anfahren und Bremsen, Tempo in der Kurve zurückgenommen, leichtes Wippen, die Spur etwas rechts der Mitte, Beinphase beim Pferd. Ohne Easing: wie die bisherige Darstellung (springt von Ort zu Ort). Die Simulation rechnet in beiden Fällen gleich, nur die Darstellung ändert sich. Das Pferd ist ein Block-Pferd.
**Laut denken:** Fährt noch etwas „wie ein Schuhkarton“ (gleitet, ruckt, dreht auf der Stelle)? Wirken Anfahren, Bremsen und Gangart richtig? Passt das Tempo zur Entfernung? Ist der Unterschied zwischen G an und aus sofort zu sehen oder erst beim genauen Hinsehen?

## Karte A8: Wasser und See (ca. 3 min)
**Aufgabe:** Taste **4**: der Fluss (Rotach) mit der Steinbogenbrücke. Zoom heraus und wieder hinein, folge dem Bach (Erlenbach) bis auf 1 km Abstand. Dann Taste **5**: der See (Binsensee), Zoom auf das Nordostufer, dort steht der **Steg** mit **Fischerhütte** und **Ruderboot** (ein zweites Boot fährt langsam eine Runde, vielleicht auch ein Floß). Zwischendurch mehrmals **V** (Wasser A / B).
**Du siehst:** ruhiges, undurchsichtiges Wasser mit Tiefenverlauf und hellem Ufersaum; einen Fischerpfad vom Steg zur Chaussee.
**Laut denken:** Siehst du, wozu der See da ist (ohne dass wir es erklären)? Reicht das ruhige Wasser, oder fehlt Bewegung? Welcher Look gefällt dir, A oder B? Ist der Bach aus der Ferne noch da? Wirken die Ufer treppig?

## Karte A9: Gelände (ca. 1 min)
**Aufgabe:** Über die Hügel nach Süden zur Kuppe schieben. Dann die zwei Bilder ansehen: `sprints/s8/design-sprint/phase2/bilder/08_relief_vergleich_karte.png` und `08_relief_ds_gebirge_massiv.png` (altes Gebirge gegen neues Profil).
**Du siehst:** Hügelland, Wald-Wiesen-Mosaik, Äcker in hellem und dunklem Gelb. Das Gebirge ist nur als Bild zu sehen, der Ausschnitt reicht nicht dorthin.
**Laut denken:** Ist das Gelände abwechslungsreich genug? Wirkt das Gebirge im Bild ruhig genug, oder soll es kleiner sein?

## Karte A10: Wachstum (ca. 2 min)
**Aufgabe:** Die zwei Bilder ansehen: `sprints/s8/design-sprint/phase4/bilder/stadt/bild_dorf_vorher_nachher.jpg` (Erlenbach nach 12 Monaten mit Versorgung) und `bild_dorf_monat12_ohne_versorgung.jpg`.
**Du siehst:** Monat 0: 244 Einwohner, 7 Baulücken. Mit Versorgung nach 12 Monaten: 307 Einwohner, Lücken gefüllt, drei Höfe zu Großhöfen, ein Hof in der Vorstadt, eine Kate zum Handwerkerhaus. Ohne Versorgung: das Dorf bleibt, wie es ist.
**Laut denken:** Wächst das Dorf glaubwürdig (Lücken zuerst, Umbau, dann erst Vorstadt)? Erkennst du den Unterschied am Schild (Einwohner, Trendpfeil nach oben)? Wäre dir „bleibt stehen, wenn nicht versorgt wird“ klar?

## Karte A11: Freie Fahrt (ca. 1,5 min)
**Aufgabe:** Bewege dich frei durch die Welt. Mach, was dich interessiert.
**Laut denken:** Wo bleibst du hängen? Was würdest du als Erstes ändern? Wäre das hier eine Grundlage für den Generator in Sprint 8?

## Karte A12: Kartentyp (entfällt in dieser Variante)
Die drei Übersichtsbilder Flusstal / Seenplatte / Seenreich gehören zur vollen Variante und liegen nicht vor. Frage trotzdem, falls Zeit bleibt: Welche Landschaft würdest du als Standard wollen?

## Fünf Fragen zum Schluss (ca. 2 min)
1. **Proportionen:** Stimmt Haus : Straße : Fahrzeug (12 : 6 : 9,5 m)? Wo wirkt die Welt noch wie eine Miniatur, wo schon echt?
2. **Dorfgröße 1820:** Ist ein Dorf mit rund 35 Wohnhäusern und 244 Einwohnern (Radius etwa 190 m) die richtige Größe? Zu klein, zu groß, oder genau der Eindruck, den du wolltest?
3. **Wasser:** Fluss, Bach, Teiche und See: stimmt der Look (A oder B)? Was fehlt?
4. **Fahrzeugverhalten:** Fahren Fuhrwerk und Postkutsche glaubwürdig? Mit Easing besser als ohne?
5. **Was zuerst ändern?** Nenn die eine Sache, die du vor Sprint 8 anfassen würdest, und eine, die du auf keinen Fall ändern willst.

## Rückmeldung zum Ausfüllen
Note: 1 = passt gar nicht, 5 = passt genau.

| Karte | Geklappt (ja/teils/nein) | Note 1–5 | Minuten | Screenshot | Stichwort |
|---|---|---|---|---|---|
| A1 Von oben | | | | | |
| A2 Zeichen ohne Modelle | | | | | |
| A3 Proportionen | | | | | |
| A4 Durchs Dorf | | | | | |
| A5 Kleinstadt | | | | | |
| A6 Gutshof und Mühle | | | | | |
| A7 Fahren (G an/aus) | | | | | |
| A8 Wasser und See | | | | | |
| A9 Gelände | | | | | |
| A10 Wachstum | | | | | |
| A11 Freie Fahrt | | | | | |
| Schlussfragen 1–5 | | | | | |

## Für uns (nicht für Basti)
- **Rollen:** Daniel protokolliert (Zeit je Karte, Screenshots), Aylin beobachtet, wo Basti sucht (A1, A6, A8 „Wozu ist der See da?“), Lena kann die Kette Farm → Mühle → Dorf erklären, falls er fragt.
- **Voraussetzungen aus Welle 2:** Fahrzeuge mit Easing-Schalter (A7), See-Nutzung mit Steg, Fischerhütte, Boot (A8), Wachstums-Bilder aus `phase4/bilder/stadt/` (A10), Schilder per `ProtoSchilder.bauen(...)` in der Szene (A1, A2, A4, A6). Fehlt etwas davon, die Karte streichen und im Protokoll vermerken, nicht aus dem Gedächtnis erklären.
- **Was jede Karte prüft:** A1 P2, P4, Schilder · A2 P2, E1 · A3 V1, V2 (Bastis Punkt 2) · A4 P3, P6 (Punkt 4) · A5 P3, bekannte Lücke Markt-Ausschnitt (Punkt 4/7) · A6 V7, G1 neutrale Industrie (Punkt 3/5) · A7 E9 (Easing, „Schuhkarton“) · A8 E2, E10, V-W3 (See zeigt seine Nutzung) · A9 K15 (Punkt 6/9) · A10 Stadt-KI, F2, E7 · A11 Freigabe W-03/W-05/W-06.
- **Bekannte Lücken, die er voraussichtlich nennt:** Markt-Ausschnitt klein, Pferd als Block, Belebung dünn, Platzhalter-Häuser. Bei Nennung nur notieren, nicht verteidigen.
- **Ergebnis Phase 5:** Bewertungstabelle, Antworten auf die fünf Schlussfragen (F1–F6 aus dem Charter), Liste „Feinschliff vor S8“, Freigabe ja/nein.
- **Beobachtung Schilder:** Hat er den Tooltip von allein entdeckt? Hat er Trend und Bedarf gelesen? Hat er die Fernzeichen vermisst oder als Last empfunden? Das ist die Rückmeldung für das Schild-Konzept (`aylin_welle2.md`).
