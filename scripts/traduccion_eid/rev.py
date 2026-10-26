from run import run
import json
from collections import Counter
R="src/revelations_2880387531"
pre = '''
REVEL = setmetatable({}, {__index = function(t,k) return __S("REVEL."..k) end})
__ENV.REVEL = REVEL
REVEL.registerItem = function(_, name) return {id = "⟨c:"..name.."⟩"} end
REVEL.registerTrinket = function(_, name) return {id = "⟨t:"..name.."⟩"} end
REVEL.registerSound = function() return 0 end
'''
post = '''
for _, m in ipairs({"scripts.revelations.definitions.revItems", "scripts.revelations.definitions.revPocketItems", "scripts.revelations.common.core.modcompat.eid"}) do
  local f = __ENV.require(m)
  if type(f) == "function" then local ok, e = pcall(f); if not ok then print("ERR", m, e) end end
end
local ok, e = pcall(REVEL.LoadEID); if not ok then print("ERR LoadEID", e) end
'''
from lupa import lua53
L = lua53.LuaRuntime(unpack_returned_tuples=True)
L.globals().ROOT = R
L.execute(open("harness.lua", encoding="utf-8").read())
L.execute(pre); L.execute(post)
rec, errs = L.globals().RUN(L.table_from([]))
out=[dict(r) for r in rec.values()]
print(Counter((r["kind"],r["lang"]) for r in out), list(errs.values())[:3])
json.dump(out, open("cap_revelations.json","w"), ensure_ascii=False, indent=0)
print(out[:2])
