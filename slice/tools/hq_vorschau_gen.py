"""T-14b (Sprint 6, Tobias): erzeugt data/hq_vorschau.json aus der eingefrorenen slice_map.json und economy_slice.json.
Aufruf: python3 -I tools/hq_vorschau_gen.py [slice_dir]    (Modellrechnung; nur lesend auf Karte und Oekonomie)
Regeln: Distanz = Luftlinie Stadtmitte -> Objekt (Felder), kaufmaennisch gerundet. Holzfaeller zaehlen nicht als Lizenzindustrie.
Lizenzfaktor = Groessenfaktor x (im Radius 1 - 0,30, sonst 1 + 0,03 x Felder ueber Radius), fuer die naechste Industrie.
Groessenfaktoren (Dorf 0,90 / Kleinstadt 1,00 / Stadt 1,20) sind Lenas Annahme (L-12), nicht im JSON."""
import hashlib, json, math, os, sys

BASE = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = os.path.join(BASE, "data")
raw = open(os.path.join(DATA, "slice_map.json"), "rb").read()
M = json.loads(raw)
E = json.load(open(os.path.join(DATA, "economy_slice.json"), encoding="utf-8"))
MD5 = hashlib.md5(raw).hexdigest()

RADIUS = {"dorf": E["hq"]["hq_radius_village_felder"], "kleinstadt": E["hq"]["hq_radius_town_felder"], "stadt": E["hq"]["hq_radius_city_felder"]}
GROESSE = {"dorf": 0.90, "kleinstadt": 1.00, "stadt": 1.20}          # Lena L-12 Annahme
STUFE = {"dorf": "Dorf", "kleinstadt": "Kleinstadt", "stadt": "Stadt"}
RABATT = E["lizenz"]["licence_discount_in_radius_promille"] / 1000    # 0,30 -> Faktor 0,70
AUFSCHLAG = E["lizenz"]["licence_surcharge_per_field_promille"] / 1000
BERG_X = E["bau_kosten"]["berg_faktor_promille"] / 1000
FLUSS_MAX = 120      # Fluss nur nennen, wenn Mittellinie naeher als so viele Felder an der Stadt (Setzung, wie Lenas Texte)
WALD_MIN = 3.0       # Wald nur ab diesem Anteil (%) des Radius
NAME = {"getreidefarm": "Farm", "muehle": "Mühle", "kohlemine": "Kohle", "erzmine": "Erzmine", "kraftwerk": "Kraftwerk",
        "stahlwerk": "Stahlwerk", "werkzeugfabrik": "Werkzeugfabrik"}
KURZ = dict(NAME, erzmine="Erz", stahlwerk="Stahl")                 # Kettenzeilen im Ton von Lenas Texten
RICHTUNG = ["östlich", "südöstlich", "südlich", "südwestlich", "westlich", "nordwestlich", "nördlich", "nordöstlich"]   # y zeigt nach Sueden

IND = {i["id"]: i for i in M["industrien"] if i["typ"] != "holzfaeller"}
CITY = {s["id"]: s for s in M["staedte"]}
FLUSS = M["fluesse"][0]["linie"]


def r0(x):
    return int(math.floor(x + 0.5))


def de(n):
    return f"{n:,}".replace(",", ".")


def zahl(x, nd=2):
    return f"{x:.{nd}f}".replace(".", ",")


def dist(c, i):
    return math.hypot(i["x_felder"] - c["x_felder"], i["y_felder"] - c["y_felder"])


def inside(pt, poly):
    x, y = pt
    c = False
    for (x1, y1), (x2, y2) in zip(poly, poly[1:] + poly[:1]):
        if (y1 > y) != (y2 > y) and x < (x2 - x1) * (y - y1) / (y2 - y1) + x1:
            c = not c
    return c


def seg_dist(p, a, b):
    dx, dy = b[0] - a[0], b[1] - a[1]
    t = max(0, min(1, ((p[0] - a[0]) * dx + (p[1] - a[1]) * dy) / (dx * dx + dy * dy)))
    return math.hypot(p[0] - a[0] - t * dx, p[1] - a[1] - t * dy)


def kreuzt_fluss(a, b):
    """Luftlinie a-b schneidet die Flussmittellinie (Segmentschnitt)."""
    def ccw(p, q, r):
        return (r[1] - p[1]) * (q[0] - p[0]) - (q[1] - p[1]) * (r[0] - p[0])
    for p, q in zip(FLUSS, FLUSS[1:]):
        if ccw(a, p, q) * ccw(b, p, q) < 0 and ccw(a, b, p) * ccw(a, b, q) < 0:
            return True
    return False


def gelaende_anteile(c, r):
    """Flaechenanteile (%) der Typen im Kreis um die Stadt, Raster 0,25 Felder; dazu Schwerpunkt des Gebirges."""
    n = 0
    cnt, sx, sy = {}, 0.0, 0.0
    for ix in range(-4 * r, 4 * r + 1):
        for iy in range(-4 * r, 4 * r + 1):
            x, y = ix / 4, iy / 4
            if x * x + y * y > r * r:
                continue
            n += 1
            pt = (c["x_felder"] + x, c["y_felder"] + y)
            if not (0 <= pt[0] < M["karte"]["breite_felder"] and 0 <= pt[1] < M["karte"]["hoehe_felder"]):
                continue
            for g in M["gelaende"]:
                if inside(pt, g["polygon"]):
                    cnt[g["typ"]] = cnt.get(g["typ"], 0) + 1
                    if g["typ"] == "gebirge":
                        sx += x
                        sy += y
    anteil = {k: 100.0 * v / n for k, v in cnt.items()}
    ang = None
    if cnt.get("gebirge"):
        ang = math.atan2(sy / cnt["gebirge"], sx / cnt["gebirge"])
    return anteil, ang


def richtung(ang):
    return RICHTUNG[int(((ang + math.pi / 8) % (2 * math.pi)) // (math.pi / 4))]


def kette_text(c, r, ids, label, extra=""):  # Namen wie Lena: Erz, Stahl, Werkzeugfabrik
    t = {}
    for i in ids:
        t.setdefault(IND[i]["typ"], []).append(r0(dist(c, IND[i])))
    teile = []
    for typ in ("getreidefarm", "muehle", "kohlemine", "erzmine", "kraftwerk", "stahlwerk", "werkzeugfabrik"):
        if typ in t:
            v = sorted(t[typ])
            teile.append(KURZ[typ] + " " + (" und ".join(str(x) for x in v) if len(v) <= 2 else ", ".join(str(x) for x in v)))
    return label + ": " + ", ".join(teile) + " Felder" + extra


def bauen(sid):
    c = CITY[sid]
    stufe = c["stufe"]
    r = RADIUS[stufe]
    d = {i: dist(c, IND[i]) for i in IND}
    im_r = {i for i, v in d.items() if v <= r}                     # Radius inklusive (L-12 Regel 6)
    nah = min(d, key=d.get)
    # Nachfrage: Einwohner / 100 x demand_per_100 x Stufenmultiplikator
    nachfrage = c["einwohner_anzahl"] / 100 * E["saettigung"]["demand_per_100_inhabitants_einheiten_pro_periode"] * E["saettigung"]["demand_mult_promille_je_stufe"][stufe] / 1000
    # Lizenzfaktor
    if d[nah] <= r:
        faktor = GROESSE[stufe] * (1 - RABATT)
        liz = f"Lizenzfaktor x{zahl(faktor)} ({NAME[IND[nah]['typ']]}, im Radius" + (f"; Stadtfaktor {zahl(GROESSE[stufe])}" if stufe == "stadt" else "") + ")"
    else:
        faktor = GROESSE[stufe] * (1 + AUFSCHLAG * (d[nah] - r))
        liz = f"Lizenzfaktor x{zahl(faktor, 1)} ({NAME[IND[nah]['typ']]}, {r0(d[nah])} Felder)"
    # Ketten
    ketten = []
    k1 = {"farm_1", "farm_2", "farm_3", "muehle_1", "muehle_2"} & im_r
    k2 = {"kohle_1", "kraftwerk_1"} & im_r
    k3 = {"erz_1", "stahl_1", "werkzeug_1"} & im_r      # Kohle steht schon in Kette 2
    if k1:
        if sid == "mittelfurt":
            rand = " (am Ringrand)" if max(d[i] for i in k1) > r - 3 else ""
            ketten.append(kette_text(c, r, k1, "Kette 1 Getreide, Mehl", rand + ". Absatz: die Stadt selbst."))
        else:
            ketten.append(kette_text(c, r, k1, "Kette 1 Getreide, Mehl", f". Absatz Mittelfurt {r0(dist(c, CITY['mittelfurt']))} Felder."))
    if k2:
        ketten.append(kette_text(c, r, k2, "Kette 2 Kohle, Kraftwerk"))
    if k3:
        wf = IND["werkzeug_1"]
        ketten.append(kette_text(c, r, k3, "Kette 3 Erz, Kohle, Stahl, Werkzeug", f". Absatz Mittelfurt fern, {r0(dist(CITY['mittelfurt'], wf))} Felder."))
    if sid == "mittelfurt":
        wf = r0(dist(c, IND["werkzeug_1"]))
        ketten.append(f"Kette 3: Werkzeugfabrik außerhalb des Radius ({wf} Felder)")
    hinweis = ""
    if not im_r:
        ids = {}
        for i in sorted(d, key=d.get):                             # nächste je Typ, die 3 nächsten Typen
            ids.setdefault(IND[i]["typ"], i)
        top = sorted(ids.values(), key=d.get)[:3]
        ketten.append("Kein Rohstoff im Radius. Nächste " + ", ".join(f"{NAME[IND[i]['typ']]} {r0(d[i])}" for i in top) + " Felder.")
        hinweis = "Im Slice nicht balanciert." if stufe == "kleinstadt" else "Kette nur über Fernlizenzen erreichbar. Im Slice nicht balanciert."
    # Gelaende
    anteil, ang = gelaende_anteile(c, r)
    fl = min(seg_dist((c["x_felder"], c["y_felder"]), FLUSS[i], FLUSS[i + 1]) for i in range(len(FLUSS) - 1))
    teile = []
    if anteil.get("meer"):
        teile.append(f"Küste: Meer {r0(anteil['meer'])} % des Radius, Hafen im Slice nicht verfügbar")
    elif fl <= FLUSS_MAX:
        t = f"Fluss {r0(fl)} Felder entfernt"
        quer = [(i, a) for i in im_r for a in im_r if IND[i]["typ"] == "getreidefarm" and IND[a]["typ"] == "muehle" and kreuzt_fluss((IND[i]["x_felder"], IND[i]["y_felder"]), (IND[a]["x_felder"], IND[a]["y_felder"]))]
        if quer:
            farmen = {i for i, _ in quer}
            t += (", trennt Farmen und Mühle" if len(farmen) > 1 else ", liegt zwischen Farm und Mühle") + ": Brücke nötig"
        teile.append(t)
    if anteil.get("gebirge"):
        teile.append(f"Gebirge {richtung(ang)}, {r0(anteil['gebirge'])} % des Radius: Gleis dort x{r0(BERG_X)}")
    if anteil.get("wald", 0) >= WALD_MIN:
        teile.append(f"Wald {r0(anteil['wald'])} %")
    if not anteil.get("meer"):
        fehlt = [n for n, ok in (("Fluss", fl <= FLUSS_MAX), ("Gebirge", bool(anteil.get("gebirge")))) if not ok]
        if fehlt and len(fehlt) == 2:
            teile.append("kein Fluss und kein Gebirge im Radius")
    gel = "; ".join(teile)
    return {"radius": f"Radius {r} Felder", "ketten": ketten,
            "groesse": f"{STUFE[stufe]}, {de(c['einwohner_anzahl'])} Einwohner, Nachfrage {r0(nachfrage)} E/min" + (" (größter Absatz)" if c["einwohner_anzahl"] == max(x["einwohner_anzahl"] for x in M["staedte"]) else ""),
            "lizenzfaktor": liz, "gelaende": gel, "hinweis": hinweis}


ORDER = ["haberau", "kohlberg", "mittelfurt", "steinbach", "eichwald", "lindach", "weidenau", "seehafen"]
out = {"quelle": f"T-14b Tobias (Modellrechnung), erzeugt aus slice_map.json md5 {MD5} und economy_slice.json durch tools/hq_vorschau_gen.py", "staedte": {s: bauen(s) for s in ORDER}}
for s, v in out["staedte"].items():
    n = 4 + len(v["ketten"]) - 1 + (1 if v["hinweis"] else 0)
    assert n <= 6, (s, n)
with open(os.path.join(DATA, "hq_vorschau.json"), "w", encoding="utf-8") as f:
    json.dump(out, f, ensure_ascii=False, indent=2)
    f.write("\n")
for s, v in out["staedte"].items():
    print(s, "|", v["radius"], "|", *v["ketten"], "|", v["groesse"], "|", v["lizenzfaktor"], "|", v["gelaende"], "|", v["hinweis"], sep="\n   ")
