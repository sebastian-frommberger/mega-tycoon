# Felix – Sprint 4, Tag 1–5: F-16 Ökonomie-Kern

**Stand:** `felix/core/economy.gd` lädt alle Werte aus T-06-JSON (Güter, K1–K3, Industrien, Lizenz, Sättigung, Startkapital). Ertrag nur beim Endabnehmer, Herkunftsstempel bleibt im Lager, Distanz = Luftlinie Ursprung→Abnehmer, Cent-Ganzzahl mit einer Division. 8× nur bis 5.000 Fahrzeuge (Konstante). Kein Kredit. Übergabe: `felix/f16_uebergabe.md`.

**Tests** (`run_smoke.sh`, Sandbox): `test_runner` Exit 0, `f06_smoke` Exit 0, 0 Script-Fehler. 147 OK: 102 alt (Diagnose, Deadlock, B8, K8) plus 45 neu. Alte Prüfsummen bitgleich.

| Test | Ergebnis |
|---|---|
| Ertrag nur Endabnehmer | Farm 0 $, Mühle/Stadt exakt nach Formel |
| Lager-Pingpong | 125 Fahrten, 1.250 E umgeschlagen, 0 $ |
| Umweg 1,5× | gleicher Ertrag je Einheit (40 Felder), gesamt nicht höher |
| Sättigung | Kennlinie 1000/700/400/100 ‰, 50 Mehl bei Bedarf 25: −31 % |
| Lizenz-API | Mühle 140 $ (= F-09-Probe), 30 min, 900 $/Monat, Gratis, Verlängerung |
| Determinismus | 3 Läufe identisch (Prüfsumme + Kasse) |

**Bench (SANDBOX, 2-Kern-Xeon, Editor-Build, keine Zielrechner-Werte):** 10k mit Ökonomie Median 3,15 / 3,40 / 3,53 ms, also unter 4 ms. p95 liegt bei 6,0–6,4 ms, 25–33 % der Ticks über 4 ms. Ohne Ökonomie: Median 2,2 ms. Die Bench-Welt ist ein Worst Case mit 1 Standort je Fahrzeug, jede Entladung wird gebucht. Unterwegs zwei Kern-Fixes, Prüfsummen unverändert.

**Ehrlich offen:**
- Der sichtbare Button „Lizenz kaufen“ ist nicht gebaut, nur die API.
- Fahrzeug-/Unterhaltskosten fehlen, damit gibt es keinen Bankrott. Das blockiert T-12.
- Sechs Annahmen in der Übergabe (u. a. 1:1-Verarbeitung) sind nicht bestätigt.
- Zielrechner-Bench steht aus.
