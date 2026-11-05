# setz.py name basis json-overrides  -> legt/aktualisiert kalibrierung_sets[name] in economy_proto.json
import json, collections, sys
p='/tmp/claude-0/gd/s8work/oe3/slice/data/economy_proto.json'
d=json.load(open(p,encoding='utf-8'),object_pairs_hook=collections.OrderedDict)
name, basis, ov = sys.argv[1], sys.argv[2], json.loads(sys.argv[3], object_pairs_hook=collections.OrderedDict)
st=json.loads(json.dumps(d['kalibrierung_sets'][basis]),object_pairs_hook=collections.OrderedDict)
for k,v in ov.items():
    if isinstance(v,dict) and k in st: st[k].update(v)
    else: st[k]=v
d['kalibrierung_sets'][name]=st
open(p,'w',encoding='utf-8').write(json.dumps(d,ensure_ascii=False,indent=2)+"\n")
