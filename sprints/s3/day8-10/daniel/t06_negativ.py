import json, os, shutil, subprocess, sys, tempfile, re
SRC = "/tmp/claude-0/gd/sprint3/day8-10/daniel/work"
def run(mut, fname="economy_slice.json"):
    t = tempfile.mkdtemp()
    shutil.copytree(SRC, t + "/w")
    base = t + "/w/tobias/t06"
    p = base + "/data/" + fname
    raw = open(p, encoding="utf-8").read()
    d = json.loads(raw)
    new = mut(d)
    if isinstance(new, str):
        open(p, "w", encoding="utf-8").write(new)
    else:
        open(p, "w", encoding="utf-8").write(json.dumps(d, indent=1))
    out = []
    for flag in ([], ["--fallback"]):
        r = subprocess.run([sys.executable, "-I", base + "/validate.py"] + flag, capture_output=True, text=True)
        err = [l.strip() for l in r.stdout.splitlines() if l.startswith("    ")][:2]
        out.append((r.returncode, err))
    shutil.rmtree(t)
    return out

def setp(path, val):
    def f(d):
        n = d
        ks = path.split("/")
        for k in ks[:-1]: n = n[int(k)] if isinstance(n, list) else n[k]
        n[ks[-1]] = val
    return f
def delp(path):
    def f(d):
        n = d
        ks = path.split("/")
        for k in ks[:-1]: n = n[k]
        del n[ks[-1]]
    return f
def textrep(a, b):
    def f(d):
        s = json.dumps(d, indent=1)
        assert a in s, a
        return s.replace(a, b, 1)
    return f

cases = [
 ("N1 negativer Preis: hq/start_capital_agrar_cent = -450000", setp("hq/start_capital_agrar_cent", -450000)),
 ("N2 negativer Preis: kauf/buy_price_base_min_cent = -1", setp("kauf/buy_price_base_min_cent", -1)),
 ("N3 fehlender Key: hq/start_capital_mining_cent entfernt", delp("hq/start_capital_mining_cent")),
 ("N4 fehlender Key: lizenz/licence_duration_ticks entfernt", delp("lizenz/licence_duration_ticks")),
 ("N5 Float statt Cent: start_capital_agrar_cent = 4500.5", setp("hq/start_capital_agrar_cent", 4500.5)),
 ("N6 Float 1.0 statt Ganzzahl: licence_cost_share_promille = 100.0", textrep('"licence_cost_share_promille": 100,', '"licence_cost_share_promille": 100.0,')),
 ("N7 String statt Zahl: start_capital_agrar_cent = \"450000\"", setp("hq/start_capital_agrar_cent", "450000")),
 ("N8 null statt Zahl: start_capital_trade_cent = null", setp("hq/start_capital_trade_cent", None)),
 ("N9 Ueberlauf >2^53: start_capital_agrar_cent = 9007199254740992", setp("hq/start_capital_agrar_cent", 9007199254740992)),
 ("N10 Promille ueber 1000: licence_cost_share_promille = 1500", setp("lizenz/licence_cost_share_promille", 1500)),
 ("N11 Tippfehler-Key: hq_found_cost_dollar zusaetzlich", setp("hq/hq_found_cost_dollar", 0)),
 ("N12 Flag als String: licence_auto_renew_flag = \"true\"", setp("lizenz/licence_auto_renew_flag", "true")),
 ("N13 Ticks negativ: licence_duration_ticks = -18000", setp("lizenz/licence_duration_ticks", -18000)),
 ("N14 Kaputtes JSON (fehlende Klammer)", lambda d: json.dumps(d)[:-1]),
 ("N15 NaN-Literal als Wert", textrep('"start_capital_agrar_cent": 450000', '"start_capital_agrar_cent": NaN')),
 ("N16 Doppelter Key (zweiter gewinnt)", textrep('"start_capital_agrar_cent": 450000', '"start_capital_agrar_cent": 450000,\n "start_capital_agrar_cent": -1')),
]
print("%-70s %s" % ("Fall", "auto(jsonschema) | fallback"))
res = []
for name, m in cases:
    try:
        r = run(m)
    except AssertionError as e:
        r = [("ERR", ["Fixture-Text nicht gefunden"])]*2
    st = ["erkannt" if x[0] == 1 else ("NICHT ERKANNT (Exit %s)" % x[0]) for x in r]
    print("%-70s %s | %s   %s" % (name, st[0], st[1], (r[0][1] or [""])[0][:90]))
