# Gegenlesen L-05-Tarifkarten (Lena, `l05_material.md` Abschnitt 5) – Tobias, 23.11.2026

Lenas `tarif.py` importiert mein Modell vom 18.11. (`day1-3/tobias/t05_modell.py`). Mein Finalmodell (`t05_final_modell.py`, 19.11.) rechnet Bergbau mit Kohle-Zufluss. Drei Städte stimmen, Erzberg weicht ab. Takt = 5 Spielminuten, 50-$-Rundung wie bei Lena.

| Stadt | Lena: allein / geteilt / Besitz je Takt | Final: netto/min allein / geteilt / Besitz | Final je Takt | Abweichung |
|---|---|---|---|---|
| Kornfeld (Agrar) | 4.200 / 1.650 / 1.900 $ | 844 / 332 / 379 | 4.200 / 1.650 / 1.900 $ | keine |
| Seehafen (Hafen) | 3.150 / 1.100 / 1.300 $ | 627 / 224 / 258 | 3.150 / 1.100 / 1.300 $ | keine |
| **Erzberg (Bergbau)** | 3.900 / 1.500 / 1.700 $ | **806 / 268 / 308** | **4.050 / 1.350 / 1.550 $** | +150 / −150 / −150 $; Mehrertrag Besitz je Takt bleibt +200 $ |
| Flusskreuz (Handel) | 2.000 / 550 / 600 $ | 399 / 109 / 119 | 2.000 / 550 / 600 $ | keine |

Kontostand Ende Takt 1 (Startpaket + bezahlte Lizenzen, Strategie L): Erzberg **4.230 $** statt 4.650 $ (Startpaket 2.280 $ mit 3 Lkw, Lizenzen Erz 126 + Kohle 84 + Stahlwerk 280 = 490 $). Kornfeld 2.783, Flusskreuz 3.241 unverändert; Seehafen 2.830 bei 2 Lizenzen stimmt.

**Empfehlung an Lena:** Erzberg-Tarifkarte und Erwartungskonto auf die Final-Werte setzen, Kohlemine als dritte Industriekarte (Kaufpreis 1.200 $, Lizenz 84 $, Annahme). Der Befund „Kauf bringt +50 bis +250 $ je Takt, zahlt sich in 2–3 Takten nie aus“ bleibt richtig. Wenn die Karten schon gedruckt sind: Abweichung < 4 % im Takt „allein“, das verfälscht K1–K3 nicht; nur die Erwartungszeile im Bogen (4.650 → 4.230) sollte handschriftlich korrigiert werden, sonst zählt die Spielleitung einen Rechenfehler, der keiner ist.

**Sophie (S-06a, „Güterliste fehlt“):** `f09/data/goods.json` enthält die 10 E1-Güter mit Kategorie; das ist die Liste für U1.
