# Positionen Refinement Sprint 3: Felix Novak und Daniel Richter

## Felix Novak (einziger Programmierer, 8 T)

**Ich will im Sprint (8,0 T):** F-12 Export 1,0 (zuerst, 02.12. hängt daran) · F-10 SoA 4,0 · F-11 Deadlock-Prüfung 1,0 (als Hook direkt in F-10 gebaut) · F-13 Bau-Tool 2,0.

**Raus oder kleiner:** F-14 Slice-Karte raus nach S4, sie braucht stabilen SoA-Kern und Bau-Tool. Sophie bereitet über S-07 die Assets vor. F-11 von 1,5 auf 1,0. F-13 von 3 auf 2: Ziehen, 45°-Snap, Ghost weiß/rot, Kosten am Cursor, Abriss, Undo nur einstufig. Für F-09b gebe ich höchstens 0,25 T Abzeichnung, ohne Review-Schleifen. Ich habe null Puffer: Jeder Zusatz verdrängt F-10.

**Einwand gegen A-07 (Aylin, 2 T Spezifikation):** Der Klick-Dialog ist TF2/OpenTTD-Standard, D15 gilt. Zwei Tage Spec sind genau die Spec-Schleife, die wir abgeschafft haben. Ich brauche eine halbe Seite mit Feldern je Objekttyp und baue den Dialog in S4 direkt. Dasselbe gilt für A-08: erst bauen, dann Texte feilen. Dafür fordere ich L-08 (Lena) als Einseiter bis 03.12., sonst kann ich T-06 und F-14 nicht anschließen.

**Akzeptanzkriterium F-10:** Der SoA-Kern mit 10.000 Fahrzeugen läuft im Release-Export am Zielrechner (5800X3D, Godot 4.7.2) mit aktiver ereignisgesteuerter Deadlock-Prüfung im Mittel mit höchstens 4,0 ms/Tick (p99 höchstens 6 ms) über 5.000 Ticks. Die Prüfsumme nach Tick 5.000 ist in 3 Läufen bit-identisch.

## Daniel Richter (QA, 8 T)

**Ich will im Sprint (8,0 T):** F-12 Messung und Abnahme 1,0 · D-06 Automatisierung 2,0 · T-07 Exploit-Katalog 0,5 · Testfälle und Abnahme F-10/F-11 1,5 (Prüfsummen-Vergleich, Wende-Deadlock = DEADLOCK) · Abnahme F-13 1,0 · Gate-Probelauf mit Release-Build 0,5 · Nachtest-Puffer 1,5.

**Raus oder kleiner:** F-13 nur mit Abriss-Erstattung höchstens 50 %, sonst ist Abriss ein Geld-Exploit; Undo bleibt einstufig. T-07 von 1 auf 0,5 für mich, Tobias liefert die Regeln.

**Einwand gegen S-08 (Sophie, 3 T Licht/Palette):** Renderänderungen vor dem G2-Nachweis verfälschen die Messung am Zielrechner. S-08 nach 02.12. verschieben, auf 1,5 T kürzen. Gegen Felix: F-10 braucht am Tag 2 einen Zwischenstand mit Prüfsumme, nicht erst am Ende.

**Akzeptanzkriterium F-12:** Der Release-Export (Windows) läuft am Zielrechner 30 Minuten Dauerlauf mit 10.000 Fahrzeugen und aktiver Deadlock-Prüfung mit 0 Abstürzen, 0 Prüfsummen-Abweichungen in 3 Läufen, Tick im Mittel höchstens 4 ms und mindestens 60 FPS (1-%-Low).
