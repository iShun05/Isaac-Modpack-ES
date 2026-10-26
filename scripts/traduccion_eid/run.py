import sys, json
from lupa import lua53
def run(root, files=None, srcs=None, pre=""):
    L = lua53.LuaRuntime(unpack_returned_tuples=True)
    L.globals().ROOT = root
    L.execute(open("harness.lua", encoding="utf-8").read())
    if pre: L.execute(pre)
    rec = errs = None
    if files:
        rec, errs = L.globals().RUN(L.table_from(files))
    for s in (srcs or []):
        rec, errs = L.globals().RUNSRC(s)
    out = [dict(r) for r in rec.values()]
    return out, list(errs.values()), L
if __name__ == "__main__":
    root = sys.argv[1]; files = sys.argv[2:]
    out, errs, _ = run(root, files)
    print(len(out), "registros;", "errores:", errs[:5])
    from collections import Counter
    print(Counter((r["kind"], r["lang"]) for r in out))
    for r in out[:3]: print(r)
