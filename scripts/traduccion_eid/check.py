import json,re,sys
def toks(s):
    return sorted(re.findall(r"\{\{[^}]*\}\}|⟨[^⟩]*⟩|‹[^›]*›", s))
def nums(s):
    return sorted(re.findall(r"\d+(?:\.\d+)?", re.sub(r"\{\{[^}]*\}\}|⟨[^⟩]*⟩|‹[^›]*›","",s)))
def load(n):
    src=json.load(open(f"chunks/seg_{n}.json"))
    tr={}
    for line in open(f"es/{n}.txt",encoding="utf-8"):
        line=line.rstrip("\n")
        if not line.strip(): continue
        i,t=line.split("\t",1); tr[int(i)]=t
    return src,tr
if __name__=="__main__":
    for n in sys.argv[1:]:
        src,tr=load(n)
        miss=[i for i in range(len(src)) if i not in tr]
        if miss: print(n,"faltan",miss)
        for i,s in enumerate(src):
            t=tr.get(i)
            if t is None: continue
            if toks(s)!=toks(t): print(n,i,"TOKENS",toks(s),toks(t))
            elif nums(s)!=nums(t): print(n,i,"NUMS",nums(s),nums(t),"|",s,"|",t)
