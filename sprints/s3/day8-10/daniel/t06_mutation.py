import json, shutil, subprocess, sys, tempfile, os, time, copy
SRC = "/tmp/claude-0/gd/sprint3/day8-10/daniel/work"
t = tempfile.mkdtemp(); W = t + "/w"; shutil.copytree(SRC, W)
base = W + "/tobias/t06"; p = base + "/data/economy_slice.json"
orig = json.load(open(p))
def leaves(o, path=()):
    if isinstance(o, dict):
        for k, v in o.items(): yield from leaves(v, path + (k,))
    elif isinstance(o, list):
        for i, v in enumerate(o): yield from leaves(v, path + (i,))
    else: yield path, o
def apply(d, path, op):
    n = d
    for k in path[:-1]: n = n[k]
    k = path[-1]
    if op == "del":
        if isinstance(n, list): return False
        del n[k]
    elif op == "neg": n[k] = -1 if not isinstance(n[k], bool) else "x"
    elif op == "float": n[k] = n[k] + 0.5
    return True
def validate():
    r = subprocess.run([sys.executable, "-I", base + "/validate.py", "--fallback"], capture_output=True, text=True)
    return r.returncode
L = list(leaves(orig))
res = {"del": [0, 0, []], "neg": [0, 0, []], "float": [0, 0, []]}
for path, v in L:
    for op in ("del", "neg", "float"):
        if op == "float" and (isinstance(v, bool) or not isinstance(v, (int, float))): continue
        if op == "neg" and isinstance(v, str): continue
        d = copy.deepcopy(orig)
        if not apply(d, path, op): continue
        json.dump(d, open(p, "w"), indent=1)
        rc = validate()
        res[op][0] += 1
        if rc == 1: res[op][1] += 1
        else: res[op][2].append("/".join(map(str, path)))
json.dump(orig, open(p, "w"), indent=1)
for op, (n, hit, miss) in res.items():
    print(op, "Mutationen", n, "erkannt", hit, "NICHT erkannt", len(miss))
    for m in miss[:40]: print("   ", m)
shutil.rmtree(t)
