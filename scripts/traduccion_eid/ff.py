from lupa import lua53
import json
from collections import Counter
R="src/fiendfolio-reloaded_3778123093"
L = lua53.LuaRuntime(unpack_returned_tuples=True)
L.globals().ROOT = R
L.execute(open("harness.lua", encoding="utf-8").read())
L.execute('''
FiendFolio = setmetatable({}, {__index = function(t,k) local s = __S("FiendFolio."..k); rawset(t,k,s); return s end})
__ENV.FiendFolio = FiendFolio
FiendFolio.LoadScripts = function(list) for _, m in ipairs(list) do __ENV.include(m) end end
__ENV.XMLData = {GetEntryById = function() return nil end}
for _, m in ipairs({"ffscripts.constants.constants", "ffscripts.constants.constants_items", "ffscripts.constants.players.golem", "ffscripts.constants.players.friend", "ffscripts.constants.item_descriptions.main"}) do __ENV.include(m) end
''')
rec, errs = L.globals().RUN(L.table_from([]))
out=[dict(r) for r in rec.values()]
print(Counter((r["kind"],r["lang"]) for r in out), [e[:200] for e in list(errs.values())[:5]])
json.dump(out, open("cap_ff.json","w"), ensure_ascii=False, indent=0)
for r in out[:3]: print(r)
