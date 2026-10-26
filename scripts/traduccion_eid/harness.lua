-- Arnés: ejecuta código de EID de un mod con stubs y registra las llamadas EID:add*
local REC = {}
local ERRS = {}
local STUBMT = {}
local function S(path)
  return setmetatable({__path = path}, STUBMT)
end
local function tok(x)
  if type(x) == "table" and getmetatable(x) == STUBMT then return "‹" .. rawget(x, "__path") .. "›" end
  return tostring(x)
end
STUBMT.__index = function(t, k)
  if type(k) == "number" then return nil end
  if k == "__path" then return nil end
  local s = S(rawget(t, "__path") .. "." .. tostring(k))
  rawset(t, k, s)
  return s
end
STUBMT.__call = function(t, ...) return S(rawget(t, "__path") .. "()") end
STUBMT.__concat = function(a, b) return tok(a) .. tok(b) end
STUBMT.__tostring = function(t) return tok(t) end
for _, op in ipairs({"__add","__sub","__mul","__div","__mod","__pow","__unm","__idiv","__band","__bor","__bxor","__shl","__shr","__bnot"}) do
  STUBMT[op] = function(a, b) return S("op") end
end
STUBMT.__lt = function() return false end
STUBMT.__le = function() return false end
STUBMT.__len = function() return 0 end

ROOT = ROOT or "."
do -- aritmética sobre fichas de texto (p. ej. GetItemIdByName(..) + 1): conserva la ficha
  local smt = getmetatable("")
  for _, op in ipairs({"__add","__sub","__mul","__div","__mod","__idiv","__unm"}) do
    smt[op] = function(a, b) if type(a) == "string" and a:find("⟨") then return a end if type(b) == "string" and b:find("⟨") then return b end return 0 end
  end
end
local function readfile(p)
  local f = io.open(p, "rb"); if not f then return nil end
  local s = f:read("a"); f:close()
  if s:sub(1,3) == "\239\187\191" then s = s:sub(4) end
  return s
end

local env
local loaded = {}
local function loadmod(name)
  if loaded[name] ~= nil then return loaded[name] end
  local rel = tostring(name):gsub("%.lua$", ""):gsub("%.", "/")
  local src, path
  for _, c in ipairs({ROOT .. "/" .. rel .. ".lua", ROOT .. "/" .. rel .. "/init.lua"}) do
    src = readfile(c); if src then path = c; break end
  end
  if not src then
    if name == "json" then loaded[name] = {encode=function() return "{}" end, decode=function() return {} end}; return loaded[name] end
    loaded[name] = S("mod:" .. name); return loaded[name]
  end
  loaded[name] = true
  local fn, err = load(src, "@" .. path, "t", env)
  if not fn then table.insert(ERRS, "carga " .. name .. ": " .. err); loaded[name] = S("mod:" .. name); return loaded[name] end
  local ok, res = pcall(fn)
  if not ok then table.insert(ERRS, "ejec " .. name .. ": " .. tostring(res)); res = nil end
  if res == nil then res = S("ret:" .. name) end
  loaded[name] = res
  return res
end

local function rec(kind)
  return function(self, id, desc, name, lang)
    if type(self) ~= "table" or self ~= env.EID then id, desc, name, lang = self, id, desc, name end
    table.insert(REC, {kind = kind, id = tok(id), desc = desc ~= nil and tok(desc) or nil, name = name ~= nil and tok(name) or nil, lang = lang ~= nil and tok(lang) or "en_us"})
  end
end

local EIDT = setmetatable({
  addCollectible = rec("c"), addTrinket = rec("t"), addCard = rec("k"), addPill = rec("p"),
  addBirthright = rec("b"), addCharacterInfo = rec("ch"),
  descriptions = setmetatable({}, {__index = function(t, k) local v = setmetatable({}, {__index = function(t2, k2) local v2 = {}; rawset(t2, k2, v2); return v2 end}); rawset(t, k, v); return v end}),
  ItemNames = {}, getLanguage = function() return "en_us" end,
}, {__index = function(t, k) return S("EID." .. k) end})

local IsaacT = setmetatable({
  GetItemIdByName = function(n) return "⟨c:" .. tok(n) .. "⟩" end,
  GetTrinketIdByName = function(n) return "⟨t:" .. tok(n) .. "⟩" end,
  GetCardIdByName = function(n) return "⟨k:" .. tok(n) .. "⟩" end,
  GetPillEffectByName = function(n) return "⟨p:" .. tok(n) .. "⟩" end,
  GetPlayerTypeByName = function(n, b) return "⟨pl:" .. tok(n) .. (b and ":B" or "") .. "⟩" end,
  GetEntityTypeByName = function(n) return "⟨e:" .. tok(n) .. "⟩" end,
  GetEntityVariantByName = function(n) return "⟨ev:" .. tok(n) .. "⟩" end,
  GetMusicIdByName = function() return 0 end, GetSoundIdByName = function() return 0 end,
  GetCostumeIdByPath = function() return 0 end, GetCurseIdByName = function() return 0 end,
  GetChallengeIdByName = function() return 0 end, GetNullItemIdByName = function() return 0 end,
}, {__index = function(t, k) return S("Isaac." .. k) end})

env = setmetatable({}, {__index = function(t, k)
  local v = rawget(_G, k)
  if v ~= nil and k ~= "require" and k ~= "include" and k ~= "dofile" then return v end
  return S(k)
end})
env.EID = EIDT
env.Isaac = IsaacT
env._G = env
env.require = loadmod
env.include = loadmod
env.RegisterMod = function(name) return setmetatable({Name = name, AddCallback = function() end, AddPriorityCallback = function() end, HasData = function() return false end, LoadData = function() return "{}" end, SaveData = function() end, RemoveCallback = function() end}, {__index = function(t, k) return S("mod." .. k) end}) end
env.Sprite = S("Sprite")
env.Vector = S("Vector")
env.Color = S("Color")
env.KColor = S("KColor")
env.REPENTOGON = true
env.REPENTANCE = true
env.REPENTANCE_PLUS = true
env.Game = function() return S("Game()") end
env.print = function() end
env.math = math; env.string = string; env.table = table; env.pairs = pairs; env.ipairs = ipairs
env.Encyclopedia = nil
env.ModConfigMenu = nil
env.MinimapAPI = nil

__ENV = env
__S = S
__tok = tok
function RUN(files)
  for _, f in ipairs(files) do loadmod(f) end
  return REC, ERRS
end
function RUNSRC(path)
  local src = readfile(path)
  local fn, err = load(src, "@" .. path, "t", env)
  if not fn then table.insert(ERRS, err) return REC, ERRS end
  local ok, e = pcall(fn); if not ok then table.insert(ERRS, tostring(e)) end
  return REC, ERRS
end
