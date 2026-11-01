# L-12 D22 Regeln final (Lena Hoffmann, Sprint 6, Tag 1-2)

Ersetzt die offenen Fragen aus `d22_hq_platzierung.md` (S5). Alle Zahlen sind Modellrechnung, Luftlinie aus `slice_map.json` plus Sophies S-12-Werte (Werkzeugfabrik ~40 F. an Kohlberg, Mühle Mittelfurt ~45 F., Dorfnachfrage x2). Finale Werte kommen mit T-14b nach Karten-Freeze Tag 4.

## 1. Finale Regeln

1. **Wagnis erlaubt:** alle 8 Städte sind gründbar. Kein Sperren, kein Rot, kein Bestätigungsdialog (D15, D21). Gemessen werden nur Mittelfurt, Haberau, Kohlberg.
2. **Umsetzen:** kostenlos und unbegrenzt oft, bis die erste Lizenz erworben ist (die Gratislizenz zählt mit) oder 2 min Spielzeit seit Gründung vergangen sind, was zuerst eintritt. Ein Klick auf Toast oder Ring. Danach ist das HQ fest, weil sonst die Lizenz im Radius (x0,70) zum Preisexploit wird.
3. **Kleinstadt = 2.500 Einwohner** (Kohlberg). Stufen unverändert: Kleinstadt ab 1.000, Stadt ab 5.000.
4. **Zeit pausiert bis zur Gründung.** Annahme: Auch im Umsetzen-Modus steht die Uhr samt 2-min-Zähler, bis der neue Standort bestätigt oder Esc gedrückt ist. Felix bitte bestätigen.
5. **Ein Startkapital 6.000 $**, HQ-Gründung 0 $.
6. **Radius inklusive:** Industrie bei Abstand <= Radius liegt im Radius. Mittelfurts Mühle (~45) sitzt exakt am Ring, Sophie bitte <= 44 setzen, sonst wackelt der Faktor.
7. **Lizenzfaktor in der Vorschau** = Stadtgröße (Dorf 0,90, Kleinstadt 1,00, Stadt 1,20; Annahme) x (im Radius 0,70, sonst 1 + 0,03 x Felder über Radius), gezeigt für die nächste Industrie. Aufschlüsselung auf Tipp ist geschoben.

## 2. Vorschau-Texte (je max. 6 Zeilen, Titel zählt nicht)

**Haberau** (Dorf)
- Radius 55 Felder
- Kette 1 Getreide, Mehl: Farm 19 und 35, Mühle 25 Felder. Absatz Mittelfurt 150 Felder.
- Dorf, 900 Einwohner, Nachfrage 18 E/min
- Lizenzfaktor x0,63 (Mühle, im Radius)
- Fluss 9 Felder entfernt, trennt Farmen und Mühle: Brücke nötig

**Kohlberg** (Kleinstadt)
- Radius 50 Felder
- Kette 2 Kohle, Kraftwerk: Kohle 49, Kraftwerk 28 Felder
- Kette 3 Erz, Kohle, Stahl, Werkzeug: Erz 45, Stahl 30, Werkzeugfabrik ~40 Felder. Absatz Mittelfurt fern.
- Kleinstadt, 2.500 Einwohner, Nachfrage 25 E/min
- Lizenzfaktor x0,70 (im Radius)
- Gebirge nördlich, 8 % des Radius: Gleis dort x3

**Mittelfurt** (Stadt)
- Radius 45 Felder
- Kette 1 Getreide, Mehl: Farm 44, Mühle ~45 (am Ringrand). Absatz: die Stadt selbst.
- Kette 3: Werkzeugfabrik außerhalb des Radius
- Stadt, 12.000 Einwohner, Nachfrage 120 E/min (größter Absatz)
- Lizenzfaktor x0,84 (Farm, im Radius; Stadtfaktor 1,20)
- Fluss 6 Felder entfernt, liegt zwischen Farm und Mühle: Brücke nötig

**Steinbach** (Dorf, Wagnis)
- Radius 55 Felder
- Kein Rohstoff im Radius. Nächste Farm 81, Mühle 133, Werkzeugfabrik 140 Felder.
- Dorf, 550 Einwohner, Nachfrage 11 E/min
- Lizenzfaktor x1,6 (Farm, 81 Felder)
- Gebirge Ost am Rand (3 %), Fluss 101 Felder entfernt
- Kette nur über Fernlizenzen erreichbar.

**Eichwald** (Dorf, Wagnis)
- Radius 55 Felder
- Kein Rohstoff im Radius. Nächste Werkzeugfabrik 100, Mühle 170, Kohle 182 Felder.
- Dorf, 600 Einwohner, Nachfrage 12 E/min
- Lizenzfaktor x2,1 (Werkzeugfabrik, 100 Felder)
- Fluss 14 Felder entfernt, Wald 4 %
- Kette nur über Fernlizenzen erreichbar.

**Lindach** (Dorf, Wagnis)
- Radius 55 Felder
- Kein Rohstoff im Radius. Nächste Erzmine 139, Stahlwerk 142 Felder.
- Dorf, 500 Einwohner, Nachfrage 10 E/min
- Lizenzfaktor x3,2 (Erzmine, 139 Felder)
- Wald 9 %, kein Fluss und kein Gebirge im Radius
- Kette nur über Fernlizenzen erreichbar.

**Weidenau** (Dorf, Wagnis)
- Radius 55 Felder
- Kein Rohstoff im Radius. Nächstes Kraftwerk 197, Stahlwerk 199 Felder.
- Dorf, 700 Einwohner, Nachfrage 14 E/min
- Lizenzfaktor x4,7 (Kraftwerk, 197 Felder)
- Wald 8 %, kein Fluss und kein Gebirge im Radius
- Kette nur über Fernlizenzen erreichbar. Im Slice nicht balanciert.

**Seehafen** (Kleinstadt, Wagnis)
- Radius 50 Felder
- Kein Rohstoff im Radius. Nächste Mühle 198, Farm 204 Felder.
- Kleinstadt, 3.200 Einwohner, Nachfrage 32 E/min
- Lizenzfaktor x5,4 (Mühle, 198 Felder)
- Küste: Meer 32 % des Radius, Hafen im Slice nicht verfügbar
- Kein Rohstoff im Radius. Im Slice nicht balanciert.

## 3. Toast- und Ringtexte (Zustand immer Icon + Text, kein Rot)

| Moment | Ort | Text |
|---|---|---|
| Panel-Knopf | Panel | "HQ hier gründen" (beim Umsetzen: "HQ hierher umsetzen") |
| Gründung | Toast | "HQ in {stadt} gegründet. Umsetzen kostenlos bis zur ersten Lizenz, höchstens noch 2:00 min." |
| Ring (dünne Linie, Hover) | Ring-Label | "Umsetzen möglich, noch {m:ss}" |
| Umsetzen angeklickt | Hinweisleiste | "Neuen Standort wählen. Esc: HQ bleibt in {stadt}." |
| Umsetzen erfolgt | Toast | "HQ nach {stadt} umgesetzt. Noch {m:ss} Umsetzen frei." |
| Abbruch (Esc) | Toast | "Umsetzen abgebrochen. HQ bleibt in {stadt}." |
| Letzte 20 s | Ring-Label | "Umsetzen noch {s} s" |
| Ablauf der Zeit | Toast | "HQ in {stadt} ist jetzt fest." |
| Erste Lizenz gekauft | Toast | "Erste Lizenz erworben. HQ in {stadt} ist jetzt fest." |

Reduced Motion: Ring und Zähler ohne Animation, Text sofort.

## 4. JSON für Mira (Platzhalter, Quelle später T-14b)

```json
{
  "haberau": {
    "radius": "Radius 55 Felder",
    "ketten": ["Kette 1 Getreide, Mehl: Farm 19 und 35, Mühle 25 Felder. Absatz Mittelfurt 150 Felder."],
    "groesse": "Dorf, 900 Einwohner, Nachfrage 18 E/min",
    "lizenzfaktor": "Lizenzfaktor x0,63 (Mühle, im Radius)",
    "gelaende": "Fluss 9 Felder entfernt, trennt Farmen und Mühle: Brücke nötig",
    "hinweis": ""
  },
  "kohlberg": {
    "radius": "Radius 50 Felder",
    "ketten": ["Kette 2 Kohle, Kraftwerk: Kohle 49, Kraftwerk 28 Felder", "Kette 3 Erz, Kohle, Stahl, Werkzeug: Erz 45, Stahl 30, Werkzeugfabrik ~40 Felder. Absatz Mittelfurt fern."],
    "groesse": "Kleinstadt, 2.500 Einwohner, Nachfrage 25 E/min",
    "lizenzfaktor": "Lizenzfaktor x0,70 (im Radius)",
    "gelaende": "Gebirge nördlich, 8 % des Radius: Gleis dort x3",
    "hinweis": ""
  },
  "mittelfurt": {
    "radius": "Radius 45 Felder",
    "ketten": ["Kette 1 Getreide, Mehl: Farm 44, Mühle ~45 (am Ringrand). Absatz: die Stadt selbst.", "Kette 3: Werkzeugfabrik außerhalb des Radius"],
    "groesse": "Stadt, 12.000 Einwohner, Nachfrage 120 E/min (größter Absatz)",
    "lizenzfaktor": "Lizenzfaktor x0,84 (Farm, im Radius; Stadtfaktor 1,20)",
    "gelaende": "Fluss 6 Felder entfernt, liegt zwischen Farm und Mühle: Brücke nötig",
    "hinweis": ""
  },
  "steinbach": {
    "radius": "Radius 55 Felder",
    "ketten": ["Kein Rohstoff im Radius. Nächste Farm 81, Mühle 133, Werkzeugfabrik 140 Felder."],
    "groesse": "Dorf, 550 Einwohner, Nachfrage 11 E/min",
    "lizenzfaktor": "Lizenzfaktor x1,6 (Farm, 81 Felder)",
    "gelaende": "Gebirge Ost am Rand (3 %), Fluss 101 Felder entfernt",
    "hinweis": "Kette nur über Fernlizenzen erreichbar."
  },
  "eichwald": {
    "radius": "Radius 55 Felder",
    "ketten": ["Kein Rohstoff im Radius. Nächste Werkzeugfabrik 100, Mühle 170, Kohle 182 Felder."],
    "groesse": "Dorf, 600 Einwohner, Nachfrage 12 E/min",
    "lizenzfaktor": "Lizenzfaktor x2,1 (Werkzeugfabrik, 100 Felder)",
    "gelaende": "Fluss 14 Felder entfernt, Wald 4 %",
    "hinweis": "Kette nur über Fernlizenzen erreichbar."
  },
  "lindach": {
    "radius": "Radius 55 Felder",
    "ketten": ["Kein Rohstoff im Radius. Nächste Erzmine 139, Stahlwerk 142 Felder."],
    "groesse": "Dorf, 500 Einwohner, Nachfrage 10 E/min",
    "lizenzfaktor": "Lizenzfaktor x3,2 (Erzmine, 139 Felder)",
    "gelaende": "Wald 9 %, kein Fluss und kein Gebirge im Radius",
    "hinweis": "Kette nur über Fernlizenzen erreichbar."
  },
  "weidenau": {
    "radius": "Radius 55 Felder",
    "ketten": ["Kein Rohstoff im Radius. Nächstes Kraftwerk 197, Stahlwerk 199 Felder."],
    "groesse": "Dorf, 700 Einwohner, Nachfrage 14 E/min",
    "lizenzfaktor": "Lizenzfaktor x4,7 (Kraftwerk, 197 Felder)",
    "gelaende": "Wald 8 %, kein Fluss und kein Gebirge im Radius",
    "hinweis": "Kette nur über Fernlizenzen erreichbar. Im Slice nicht balanciert."
  },
  "seehafen": {
    "radius": "Radius 50 Felder",
    "ketten": ["Kein Rohstoff im Radius. Nächste Mühle 198, Farm 204 Felder."],
    "groesse": "Kleinstadt, 3.200 Einwohner, Nachfrage 32 E/min",
    "lizenzfaktor": "Lizenzfaktor x5,4 (Mühle, 198 Felder)",
    "gelaende": "Küste: Meer 32 % des Radius, Hafen im Slice nicht verfügbar",
    "hinweis": "Kein Rohstoff im Radius. Im Slice nicht balanciert."
  }
}
```

Zeilenzahl je Stadt = radius + ketten[] + groesse + lizenzfaktor + gelaende + hinweis (falls nicht leer), maximal 6.

## 5. Offen / Abhängigkeiten
- Werkzeugfabrik-Abstände (Kohlberg ~40, Mittelfurt "außerhalb") und Mühle Mittelfurt ~45 sind S-12-Platzhalter. Nach Karten-Freeze (Tag 4) liefert T-14b die echten Werte, Texte dann abgleichen.
- Haberau-Nachfrage 18 setzt Dorf x2 voraus. Tobias prüft, ob K1 dadurch Haberau-HQ nicht dominant macht.
