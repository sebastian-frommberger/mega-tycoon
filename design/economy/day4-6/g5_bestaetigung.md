# G5 „Lizenz/Kauf-Leiter konsistent“ – Bestätigung durch Tobias (20.11.2026, verspätet)

**Frist laut D14: 19.11., 18:00. Diese Bestätigung kommt am 20.11.** Begründung, ohne Ausrede: Am 19.11. hatte ich zwei feste Termine, die Zahlen für Lenas Karten (Pflichttermin aus dem Brief, L-05 hängt daran) und die Gegenrechnung mit Kohle-Zufluss und Kreditrahmen, die ich vor einer Bestätigung sehen wollte. Ich habe den D14-Termin dahinter eingeordnet und das nicht im Daily gesagt. Laut D14 gelten die Schwellen seit 19.11., 18:00 ohnehin. Was hier steht, ist also **Bestätigung mit Protokollhinweisen, kein Widerspruch**; ein Widerspruch wäre jetzt ein Änderungsantrag an Jonas und würde das Gate belasten.

## Was ich bestätige

| Teil | Schwelle (gate_kriterien.md) | Stand Rechnung 19.11. | Beleg |
|---|---|---|---|
| (R) Archetypen von 4 mit ≥ 1 Startfall, Lizenzroute vor Kauf im Break-even, unter Option A | Grün 4/4, Gelb 3/4, Rot ≤ 2/4 | **4/4** (Agrar F4, F5 · Hafen F2, F4, F5 · Bergbau alle · Handel alle), mit Kohle im Bergbau unverändert | `t05_final_breakeven.csv`, `t05_final.md` Abschnitt 2 |
| Decision Record DR-T05-01 bestätigt | Grün: DR da | durch D1 bestätigt, aktualisiert | `t05_final.md` Abschnitt 4 |
| (M) L-05 Kaufwunsch vor Minute 25 in ≥ 2/3 Runden | Grün ≥ 2/3 | **0 von 3 Runden**, Material bei Lena, keine Tester belegt | Lena, nicht ich |
| „Kapital reicht für 3 Lizenzen“ | protokolliert, zählt nicht | unter A immer erfüllt (350–490 $) | `t05_final_startkapital.csv` |

Ich bestätige die Schwellen 4/4 – 3/4 – ≤ 2/4 und die Definition „Lizenzroute vorn = Break-even Cash > 30 min (eine Lizenzperiode)“.

## Drei Hinweise fürs Gate-Protokoll (keine Schwellenänderung)

1. **4/4 ist bei Agrar dünn.** Die beiden tragenden Startfälle sind die Rohstoff-Firma (Getreidefarm, Besitz lohnt nie) und der Dorf-Markt mit 9 E/min. Beim Verarbeiter im Standardfall liegt der Kauf nach 17 min vorn. Würde das Gate nur Verarbeiter-Startfälle zählen, wäre G5 (R) **3/4 = Gelb**. Ich empfehle, diesen Satz in die Ampel-Begründung zu schreiben, damit „Grün“ nicht als „Agrar-Leiter funktioniert“ gelesen wird.
2. **R ist Konstruktion.** Startkapital ist per Formel so gesetzt, dass der Satz stimmt; Preisbasen, KI-Anteil 40 %, Schwelle 30 min und Kohle-Parameter sind meine Setzungen. Lenas Nachrechnung nutzt mein Modell. Der R-Teil belegt Konsistenz der Regeln untereinander, nicht Spielgefühl. Trennschärfe nur über (M).
3. **Bergbau:** Mit Kohle-Zufluss ergibt meine Formel 8.000 $, D1 setzt 7.000 $. Die Kauf-Route läuft trotzdem ab Minute 1 (Rest 720 $). Kein Einfluss auf 4/4, aber Lenas Untergrenze 6.000 $ braucht den Kreditrahmen.

## Belegstufe nach Katrins Gerüst

R-Teil: **R (Rechnung), vorhanden.** M-Teil: **O (offen)**, 0/3 Runden. Nach Go-Regel D8: ohne M-Wert ist G5 „Messwert fehlt“ → Vertagen, unabhängig von meiner Rechnung. Das ist Lenas und Katrins Pfad (Tester, Termin), nicht meiner.

## Annahme

Ergebnisse anderer aus Tag 4–6 lagen bei Abfassung nicht vor (`day4-6/` enthält nur meinen Ordner). Ob Felix und Daniel ihre Schwellen bestätigt haben, weiß ich nicht.
