# Prueba del mod traduccion_es_mods fuera del juego (stubs de Isaac y EID).
# Uso: python3 test_mod.py ../../mods_locales/traduccion_es_mods
import sys
from lupa import lua53
L = lua53.LuaRuntime(unpack_returned_tuples=True)
d = sys.argv[1]
g = L.globals()
g.DIR = d
L.execute(r'''
local n = 0
local ids = {}
local function fake(name) if name:find("Nope") then return -1 end if not ids[name] then n = n + 1; ids[name] = 1000 + n end return ids[name] end
Isaac = { GetItemIdByName = fake, GetTrinketIdByName = fake, GetCardIdByName = fake, GetPillEffectByName = fake,
  GetPlayerTypeByName = function(nm, b) return fake(nm .. (b and "B" or "")) end }
ModCallbacks = { MC_POST_GAME_STARTED = 15 }
CB = {}
function RegisterMod(n) return { AddCallback = function(self, c, f) CB[c] = f end } end
function include(p) return dofile(DIR .. "/" .. p .. ".lua") end
EID = { descriptions = { en_us = { custom = {}, pills = {}, birthright = {}, CharacterInfo = {} }, spa = {} }, ItemNames = { spa = {} } }
function EID:CreateDescriptionTableIfMissing(t, l) self.descriptions[l][t] = self.descriptions[l][t] or {} end
-- simulamos un mod con su propia traducción española para un objeto: no se debe pisar
EID.descriptions.spa.custom = { ["5.100.1001"] = { 1001, "X", "PROPIA", "Mod" } }
dofile(DIR .. "/main.lua")
local t0 = os.clock()
for i = 1, 10 do CB[15]() end
print("10 pasadas:", os.clock() - t0, "s")
local c = 0 for k, v in pairs(EID.descriptions.spa.custom) do c = c + 1 end
local p = 0 for k, v in pairs(EID.descriptions.spa.pills) do p = p + 1 end
local b = 0 for k, v in pairs(EID.descriptions.spa.birthright) do b = b + 1 end
local ch = 0 for k, v in pairs(EID.descriptions.spa.CharacterInfo) do ch = ch + 1 end
print("custom", c, "pills", p, "birthright", b, "charinfo", ch)
print(EID.descriptions.spa.custom["5.100.1001"][3])
local bad = 0
for k, v in pairs(EID.descriptions.spa.custom) do if v[3]:find("⟨") or v[3]:find("‹") then bad = bad + 1; print("TOKEN", v[3]) end end
print("con tokens sin resolver:", bad)
local k, v = next(EID.descriptions.spa.custom) print(k, v[3])
''')
L.execute(r'''
-- un mod escribe su propio spa después de nuestra primera pasada: no debe pisarse
local k = "5.100.2017"
EID.descriptions.spa.custom[k] = { 2017, "Y", "PROPIA2", "Mod" }
CB[15]()
print("respeta tardía:", EID.descriptions.spa.custom[k][3])
''')
