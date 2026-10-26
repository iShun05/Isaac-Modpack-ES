import json, re
from collections import Counter, OrderedDict
from run import run
S="src"
caps={}
cm=json.load(open("captura_main.json"))
for k in ["andromeda_2722017893","job_2567634705","mattpack_3408993906","icesaac_2955792897","agatha_2928402913","passive skill trees_3305869734","repentanceplus_2627014611"]:
    caps[k]=cm[k]
caps["revelations_2880387531"]=json.load(open("cap_revelations.json"))
caps["fiendfolio-reloaded_3778123093"]=json.load(open("cap_ff.json"))
entries=[]
for mod,recs in caps.items():
    spa={(r["kind"],r["id"]) for r in recs if r["lang"]=="spa"}
    seen=set()
    for r in recs:
        if r["lang"]!="en_us" or r.get("desc") is None: continue
        key=(r["kind"],r["id"])
        if key in spa: continue
        if key in seen: continue  # primera aparición
        seen.add(key)
        entries.append({"mod":mod,"kind":r["kind"],"id":r["id"],"name":r.get("name"),"desc":r["desc"]})
bad=[e for e in entries if "‹" in e["id"] or "‹" in e["desc"]]
print(len(entries), "entradas; con stub:", len(bad))
for b in bad[:15]: print(b["mod"], b["id"], re.findall("‹[^›]*›", b["desc"])[:3])
print(Counter(e["mod"] for e in entries))
segs=Counter()
for e in entries:
    for s in e["desc"].split("#"):
        if s.strip(): segs[s]+=1
print("segmentos únicos:", len(segs), "caracteres:", sum(len(s) for s in segs))
json.dump(entries, open("entries.json","w"), ensure_ascii=False, indent=0)
