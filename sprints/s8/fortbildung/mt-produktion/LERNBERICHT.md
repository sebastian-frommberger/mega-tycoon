# Lernbericht Katrin (Produktion/Scrum Master), 03.11.2026

Basis: Selbstanalyse aus dem Repo (/home/claude/mega-tycoon, read-only) und Recherche mit rund 19 lesbaren Quellen (URLs in /tmp/claude-0/gd/skills/mt-produktion/SKILL.md, Teil A). Reddit war nicht lesbar.

## Lücken (was uns fehlte)
- Schätzen: S2 endete mit 8 erledigt, 8 nicht erledigt, 1 abgebrochen; Felix' Puffer war verbraucht. Keine Velocity, keine Referenzklasse, obwohl Daten aus S5 bis S7 existieren. Planungsfehlschluss und Cone of Uncertainty waren nicht Teil unserer Praxis.
- DoR/DoD: Gate-Regeln stark (D7/D8), aber DoD je Ticket uneinheitlich; Streit um DoR (Cohn) war uns nicht bekannt.
- Messhygiene: 1,6 M Dreiecke war ein gezählter Wert ohne Culling (live etwa 0,62 M); S7-Messfehler Faktor 2,5; Repo-Drift beim Bot (M7 36,0 statt 30,4 min) ungeklärt; Ladezeit lastabhängig (0,48 bis 1,7 s).
- KI-Agenten: VERTRAG.md funktioniert (Eigentümer, Arbeitskopien, dreiseitiger Merge), aber Hooks in fremden Dateien, doppelte INSTANCE_CUSTOM-Nutzung und Vertragsänderung M8 zeigen Schnittstellenlücken; kein Messwert, ob Parallelbetrieb netto Zeit spart.
- Retro-Wirksamkeit: Pairing und Zielrechner-Messung kehren in S2 und S3 wieder; Wirkung "nicht belegt" (retro_s3.md).
- Blocker: Export-Templates erst spät aufgefallen (S3); Tests auf Platzhalterkarte wurden rot (S7).

## Unsicherheiten (bleiben offen)
- DoR ja oder nein: Streit; wir nutzen eine leichte Richtlinie, kein Gate.
- Schätzen von KI-Agentenarbeit: keine belegte Methode gefunden; Tokens und Limits sind der Engpass (zwei Agenten im 5-Stunden-Limit, S7).
- Multi-Agent: Anthropic nennt etwa 15x Tokens gegenüber Chat, Cognition rät bei parallelen Schreibern ab; unser Nutzen ist nicht gemessen.
- Flaky-Rate der 21 Suiten (1.361 bis 1.565 s) nicht erhoben.
- 24-h-Branch-Regel (Mergify, DORA-Zuordnung unverifiziert) passt vielleicht nicht zu Review-Zyklen.

## Top-5-Erkenntnisse
1. Retro-Maßnahmen brauchen Owner, Revisit-Datum (2/4/6 Wochen) und eine Prüfphase am Retro-Anfang (Retromat); sonst kehren sie wieder, wie Pairing in S2/S3. [Konsens in der Retro-Praxis]
2. Der Kegel der Unsicherheit verengt sich nur durch Entscheidungen (Faktor 4 auf 1,6 auf etwa +/-25 %); Spikes und Referenzklassen statt Einzelschätzung; Planungsfehlschluss: im Mittel 55,5 statt 33,9 Tage, nur etwa 30 % im Plan. [Konsens]
3. Gate-Information schlägt Gate-Blockade: Kriterien, Messart und Schwellen vor der Messung; Go/No-Go/Vertagen (D8) hat stilles Schönrechnen verhindert. Cohns Stage-Gate-Kritik gilt nicht für Qualitäts-Gates mit Messwert. [Streit zur DoR, Konsens zu Vorab-Kriterien]
4. KI-Agenten: Prüfung, die der Agent selbst ausführen kann; Reviewer mit frischem Kontext; Schreibzugriff einthreadig oder mit disjunkten Dateieigentümern (Anthropic, Cognition 2026, Claude-Doku). METR: Selbstwahrnehmung von Tempo trügt (gefühlt 20 % schneller, real 19 % langsamer, 2025, überholt). [Einzel/Streit]
5. Gezählt gegen live: Jede Messung nennt Messart, Last, n und Wiederholungen; Zahlen, die der Spieler sieht, bekommen einen Test gegen den Spielwert. [Repo, hoch]

## Was wir ab sofort anders machen
1. Retro: Revisit-Phase mit Datum je Maßnahme; höchstens 3 Maßnahmen, je Owner und Wirkungsprüfung.
2. Gate-Protokoll: Messart, Last, n, Wiederholungen; gezählte und Live-Werte getrennt; keine "nicht erneut gelaufen"-Regression vor Abnahme.
3. Aufgabenkarte für Agenten: Ziel, Dateieigentümer, Zahlen, Nicht-Ziele, Prüfkommando, Handback; Hook-Stellen in fremden Dateien im Vertrag festlegen.
4. Referenzklasse aus S5 bis S7 bauen; Cycle Time und Alter je Karte erfassen (Start-/Enddatum); Token- und Limitverbrauch mitführen.
5. Blocker-Check am Tag 1 (Export-Templates, Tools, Zielrechner, Limit) und Premortem zu Sprintstart.
6. Erst echte Karte oder echte Daten, dann Tests; eine Quelle der Wahrheit je Zahl, Kopien kennzeichnen.

## Einschränkungen der Recherche
Reddit nicht lesbar (nicht umgangen). Pichler DoR, McConnell-Originalseite gesperrt. Google-Flaky-Blog ohne Text. Godot-RenderingServer-Doku nicht abrufbar; Aussagen zu Dummy-Renderer und Live-Messung stammen aus Repo-Messungen. DORA nur als InfoQ-Zusammenfassung. Hersteller-Quellen (Anthropic, Cognition) haben Eigeninteresse. Klein-Premortem "30 %" nicht bestätigt.
