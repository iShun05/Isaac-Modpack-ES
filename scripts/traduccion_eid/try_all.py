import os, sys, json
from collections import Counter
from run import run
S="src"
res={}
for d in sorted(os.listdir(S)):
    if not os.path.exists(f"{S}/{d}/main.lua"): continue
    try:
        out, errs, _ = run(f"{S}/{d}", srcs=[f"{S}/{d}/main.lua"])
    except Exception as e:
        print(d, "EXC", str(e)[:200]); continue
    c=Counter((r["kind"], r["lang"]) for r in out)
    en={k:v for k,v in c.items() if k[1]=="en_us"}; es={k:v for k,v in c.items() if k[1]=="spa"}
    print(f"{d}: en={en} spa={es} errs={[e[:150] for e in errs[:3]]}")
    res[d]=out
json.dump(res, open("captura_main.json","w"), ensure_ascii=False, indent=0)
