# ADR OE-06: Lizenzverlängerung zum gleichen Preis bleibt in S8

Stand 05.11.2026, Lena (Owner), Tobias (Gegenprobe). Status: **angenommen, revidierbar bis S9-Refinement** (durch Lena/Tobias am Bot-Wert von Ereignis 6). Marken: [M] Code, [R] gerechnet, [E] Schätzung.

## Kontext
- `_renew_licences(t)` (`slice/economy.gd` Z. 602–623) [M]: Mit `licence_auto_renew_flag = true` (`economy_slice.json lizenz`) wird jede Lizenz, deren `s_lic_until[site] <= t` ist, **automatisch** um `lic_duration` (18.000 Ticks = 30 min) verlängert. Preis ist `_licence_cost(site)`, also dieselbe Formel wie beim Kauf (Z. 514–518). Reicht die Kasse nicht, gilt `s_lic_until = -1`, die Lizenz fällt weg, und es entsteht ein `lic_events`-Eintrag mit `ok: false`.
- Nebenbefunde [M]:
  1. Bei der Verlängerung wird **kein Gratis-Kontingent** geprüft. Die erste Lizenz (gratis beim Kauf) kostet also beim Verlängern den vollen Preis: Kuppenhof ≈ 70 $, Mühle ≈ 140 $ [R, design.md §2.1].
  2. Die Verlängerung zieht nur aus Guthaben (`cash_cent >= cost`), den Kredit nutzt sie nicht. Ohne Lizenz gibt `load_gate` `L_WAIT` zurück (Z. 713). Die Linie steht dann still.
  3. Die Toasts zu `lic_events` setzt nur `main.gd` Z. 3151–3180 ab (Slice). In der Welt fehlt ein Leser (AT-11/A-08).
  4. `lizenz.hinweis_vor_ablauf_ticks` (1.800, `economy_constants.json`) liest keine `.gd`-Datei.
- G-01 sah +10 % je Verlängerung vor. `design.md` E6 bot an: Zuschlag, kürzere Laufzeit oder bewusst „gleicher Preis“.

## Entscheidung
In S8 bleibt die Verlängerung **automatisch und zum gleichen Preis** (`_licence_cost`). Kein Zuschlag, keine kürzere Laufzeit, keine neue Konstante. `economy.gd` bleibt unberührt. Ereignis 6 (Lizenzablauf in ≤ 3 min) bleibt im Katalog (`ziele_welt.json`) und hat zwei Optionen: laufen lassen (Verlängerung ≈ 70/140 $) oder den Betrieb kaufen (C1, 50 % der gezahlten Lizenzgebühren angerechnet).

## Begründung
1. **Die Lizenz ist im Loop keine Geldentscheidung** (Preis 70/140 $ gegen 6.000 $ Start) [R]. Ein Zuschlag von +10 % bringt 7–14 $. Das wäre Rauschen, und es käme eine Zahl dazu, die erklärt werden muss.
2. **Den Druck um Minute 30 liefert C1:** Kaufen beendet die Verlängerungen und rechnet 50 % der Gebühren an. Die Entscheidung ist also „mieten oder kaufen“, nicht „teurer mieten“.
3. **Kein Eingriff in `economy.gd` in Block A** (Dateibesitz §6: niemand). Der Slice bleibt bitgleich, d08 und `d08_lizenzfaktor` bleiben gültig.
4. Fairness-Regel (Lena-Skill Kernregel 8): Eine angebotene Handlung (Lizenz) wird nicht nachträglich bestraft.

## Folgen
- **Bot (QT-03):** Er zählt Ereignis 6 mit `s_lic_until[site] - tick <= 1800`. Soll: Minute 27–30 für die erste Farmlizenz (Kauf Minute 0–3 → Ablauf 30–33) [R]. Dazu loggt er die Verlängerung (`lic_events ok`) und den Wegfall (`ok: false`).
- **Anzeige (AT-11, Fall „Lizenz läuft ab“):** Der Text nennt den Preis der Verlängerung und die Kaufoption. Er braucht einen Leser für `hinweis_vor_ablauf_ticks` (Mira, ohne `economy.gd`-Änderung über `licence_quote`).
- **Risiko:** Der Wegfall bei zu wenig Guthaben stoppt still eine Linie. → Diagnose in AT-11 (Ort + Ursache + Aktion), sonst wirkt es wie ein Fehler.

## OFFEN
- Wird die Gratis-Lizenz wie oben (Nebenbefund 1) beim Verlängern bezahlt? Das ist beabsichtigt oder ein Altfehler, und kein Dokument sagt, welches von beiden. Es bleibt in S8, wie es ist, und ist zu benennen (Toast mit Preis).
- Basiert die Anrechnung von 50 % beim Kauf auf den Gebühren **dieser** Site? `licence_paid_total` ist global (Z. 138) [M]. Siehe FK-01.

## Revision
Revidierbar bis S9-Refinement. **Auslöser für eine Revision:** (a) Der Bot zeigt Ereignis 6 als einziges Ereignis zwischen Minute 27 und 33, und das ohne Kaufoption (FK-02 nicht grün). (b) Basti nennt in L3 die Lizenz „bedeutungslos“. Dann prüfen: Zuschlag je Verlängerung als eigene Konstante in `economy_proto.json` (nur Welt).
