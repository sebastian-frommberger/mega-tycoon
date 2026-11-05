# FZ-04 UI Fahrzeugkarte (Mira, S8 Block C, 05.11.2026)

**Ergebnis: grün.** Commit 3294777. Die Sim/API stammt von Felix (`FZ-03-05.md`).

## Was (`proto/ui_welt.gd`)
- Karte W5 im rechten Panel (`auswahl = "#vid"`). Öffnet über die Knöpfe [F1] [F2] … unter jeder Linie im Panel der Quelle (später auch aus der Linienliste AT-10). [x] führt zurück zum Panel der Quelle.
- Inhalt:
  - Kopf: Name (Gut), Modell, Linie A → B.
  - Alter: „Alter j J von L J · p %“ plus Balken (ProgressBar), Farbe ▲ ab 80 %, ■ ab 100 %.
  - Unterhalt: „Unterhalt x $/min (+y % durch Alter)“ aus `fix_eff`.
  - Je verfügbares Modell eine Zeile „Ersetzen durch {Modell}: Restwert r · neu n · spart z/min“ aus `ersetzen_angebot` und Knopf [Ersetzen · netto $]. Ab 1830 zusätzlich [Ersetzen durch Frachtwagen · …] (FZ-05).
  - F5.2-Hinweis ▲, wenn Ersetzen nichts spart.
  - [Verkaufen · +Restwert] mit Rückfrage inline („Verkaufen? Die Ladung verfällt.“ [Verkaufen] [Behalten]).
- Ersetzen über `fahrzeug_ersetzen`: Die Linie läuft weiter (gleicher Slot), es gibt keinen Neuaufbau der Darstellung (gleiche Kategorie).
- Texte: Erfolg Ersetzen/Verkaufen, F5.1 (Geld), F5.2 (spart nichts), F5.4 (Frachtwagen vor 1830), `ladung_zu_gross`, Sammeltext mit Code.

## Messwerte (gemessen, headless, `proto_ui_welt_test -- --nur=fz04`: 16/16)
| Prüfung | Ergebnis |
|---|---|
| Karte bei Kauf | Alter 0 J, Unterhalt 60 $/min = `fix_eff` |
| Nach 18.000 Ticks (1830) | Alter 10 J (66 %), Unterhalt 90 $/min (+50 %) = `fix_eff`; Restwert 50 $, spart 30 $/min = `ersetzen_angebot`; Frachtwagen angeboten |
| F5.1 (Kasse 1 $) | Text, Fix unverändert |
| Ersetzen | Kasse −24.990 ¢ = Vorschau netto ± 0; Unterhalt 60 $/min, Alter 0 |
| Linie läuft weiter | 4 Lieferungen in 1.200 Ticks danach, nicht verkauft |
| Klicks | Karte + Ersetzen = 2 ab Panel (3 im Test mit Fehlversuch) |
| Verkaufen | 1. Klick fragt nach, 2. Klick +14.340 ¢ = Restwert, Karte „Verkauft, steht still.“ |
Gesamtsuite 115/115.

## Regression
`regress_fast` nach Commit 3294777: GRÜN, 142 s, 28/28 Schritte.

## Abweichungen / offen
- W5 sagt „Klick auf Zeile oder Fuhrwerk“. Klick auf das fahrende Fuhrwerk in der Welt ist nicht gebaut (Picking bewegter MultiMesh-Instanzen); Einstieg ist die Linie.
- A3 bleibt wie im AT-09-Bericht: Ersetzen wirkt sofort, Ladung bleibt. Ist die Ladung größer als die neue Kapazität, lehnt die API ab (Text vorhanden).
- Kaufwahl bei 2 Modellen gibt es nur beim Ersetzen. Neukauf (+ Fuhrwerk, Anlegen) nimmt weiter `def_fuer("fuhrwerk")` = Fuhrwerk → Anforderung: Modellwahl in der Vorschau (Aylin: wie viel UI?).
