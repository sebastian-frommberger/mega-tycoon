# Leitplanken für das Game Concept „Mega Tycoon“

## Team (Studio)
- Jonas Weber – Creative Director
- Lena Hoffmann – Lead Game Designer
- Tobias Brandt – Systems & Economy Designer
- Aylin Kaya – UX/UI Designerin
- Felix Novak – Technical Lead (Godot 4)
- Sophie Martin – Art Director / Technical Artist
- Daniel Richter – QA Lead
- Katrin Vogel – Producer

## Positionierung (vom Ideengeber, verbindlich)
Es geht NICHT darum, nur „besser“ oder „anders“ als Transport Fever zu sein. Die bewährte Transport-Tycoon-Formel (Netz bauen, Güter- und Personentransport, Ketten, Städte, Fahrzeugepochen) wird **angereichert und verbessert**:
- Onboarding, Signale, Interface/Diagnose klar verbessern (lesbare Komplexität: jedes Problem sichtbar, lokalisierbar, erklärbar).
- **Epochen** als historischer Rahmen.
- **Skilltree mit Fähigkeiten und Unlocks**, der dem Spiel eine Richtung gibt, sodass ein nächster Run anders verläuft. NICHT wie Civ (Militär/Wissenschaft/Kultur), sondern spielstil-orientiert: z. B. „Ich baue lieber Personennahverkehr in Städten aus → Skill ‚Stadtticket‘ Rang 1/5: +10 % Ticketerlöse bei Personentransport in Städten“. Dasselbe für Industrien (z. B. Getreidekette, Schwerindustrie, Massengut, Schiene, Straße, Logistik/Lager).
- Personen- UND Gütertransport sind Teil des Spiels (Prototyp hatte nur Güter).

## Bereits getroffene Richtungsentscheidungen
- Kernspaß: Bauen und Optimieren; Druck vor allem logistisch.
- Cluster-Modell: Ketten logisch in vernünftiger Reichweite, Distanz zwischen Ketten und Städten.
- Start mit HQ und Lizenzen, Firmenkauf ab Meilenstein 5b (keine Rollenwahl). Laden bei lizenzierten und eigenen Firmen und eigenen Lagern. Ausbreitung von innen nach außen über Einfluss. *(Geändert 23.11.2026 nach D12, eingetragen von Lena; vorher: „Start durch Firmenkauf. Laden nur bei eigenen Firmen und Lagern.“ Freigabe Jonas.)*
- Fokussierter Start für Casuals, schnelle Öffnung für Veteranen; Meilensteine statt Zeit.
- Energie: Grundversorgung immer da, belieferte Kraftwerke = Produktivitäts-Multiplikator im Umkreis (mit Bremse gegen Spirale).
- Industrien bleiben über Epochen, werden erweitert/spezialisiert; spätere Epochen bringen neue Ketten (z. B. Chips), die Strom brauchen.
- Lager als expliziter Umschlagpunkt; jedes Verkehrsmittel braucht eine Nische (Lkw sammelt/verteilt, Zug Hauptstrecke, Schiff Massengut).
- Skilltree und Technik-Freischaltung sind EIN System (keine zwei konkurrierenden Bäume).
- Nicht-lineare Skills, Fähigkeiten/neue Möglichkeiten statt nur Prozente, aber Rangstufen mit Prozenten sind ausdrücklich gewünscht (Mischung).

## Ideengeber-Schmerzpunkte mit Transport Fever 2 (lösen!)
Industrieverteilung wirkt konstruiert; Industrien nicht beeinflussbar; Städte brauchen „genau zwei Dinge“; unklar warum Züge stehen (Signale); Nahverkehr unlesbar (Abdeckung, Wartende, Ziele); Industrien ohne Arbeiter; Schiffe sinnlos; Lkw vs. Zug unklar; keine Konkurrenz; keine Skills; Technik nur Warten ohne Vorschau; Straßen-/Schienenbau fühlt sich schlecht an (Railway Empire besser); Knotenpunkte/Lager unsichtbar; keine Energie.

## Team-Feedback zum Prototyp (Kurzfassung)
- Stark: Firmenkauf + nur eigene Firmen laden; Gewinn/min je Linie.
- USP ungetestet: im Prototyp kann nichts klemmen (keine Signale, Staus, Engpässe).
- Kein Gegendruck (unbegrenzte Nachfrage, Ertrag nur nach Distanz, Minus folgenlos) → Idle-Kurve.
- Exploit Lager-Pingpong; Soft-Lock (nichts abreißen); Züge ohne Gleis durch Städte.
- Tech: Netz als Graph statt Bool-Gitter, fester Sim-Tick, MultiMesh-Fahrzeuge; Ziel 10.000 Fahrzeuge < 4 ms.
- Art: Maßstab widersprüchlich; Industrien ohne Silhouette; Karte vs. Diorama entscheiden.
- UX: „Keine Verbindung“ ohne Ort; Ghost-Farben missverständlich; Label-LOD fehlt.
- Producer: Vertical Slice ca. 3–4 Monate, 4–5 Leute; Kern = Bau-Tool, Diagnose/Signale, Verkehrsmittel-Nischen über Lager, wachsender Warenkorb.

## Weitere Unterlagen
- Recherche + Schmerzpunkt-Tabelle + Team-Feedback: siehe Briefing /tmp/claude-0/gd/briefing.md
- Prototyp-Code: /tmp/claude-0/gd/proto/
