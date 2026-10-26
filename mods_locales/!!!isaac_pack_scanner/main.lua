-- Isaac Pack ES (escáner) v0.2: mide cuánto tarda cada mod en sus callbacks para encontrar el que causa lag,
-- y anota los errores Lua de cada mod (callback y primer mensaje) sin cambiar su comportamiento.
-- Además del log.txt, guarda el informe en data/!!!isaac_pack_scanner/save1.dat (se puede leer sin abrir el juego).
-- Se carga el PRIMERO (el nombre de carpeta empieza por «!!!») para envolver los callbacks de los demás mods.
-- Solo mide si config.lua dice activo = true (lo escribe el instalador / isaac_pack.py). Si no, no toca nada.
local mod = RegisterMod("Isaac Pack ES (escáner)", 1)

local okc, cfg = pcall(require, "config")
local activo = okc and type(cfg) == "table" and cfg.activo == true

local S = { activo = activo, mods = {}, frames = 0, sinMedir = 0, errores = {} }
_G.IsaacPackScanner = S
if not activo then return end

-- reloj: os.clock (microsegundos) si existe; si no, Isaac.GetTime (milisegundos)
local reloj = os.clock
if type(reloj) ~= "function" or not pcall(reloj) then
	reloj = function() return Isaac.GetTime() / 1000 end
end

local envueltas = setmetatable({}, { __mode = "k" }) -- función original -> función envuelta (para poder quitar callbacks)

-- nombre de cada id de callback (para el informe de errores)
local nombreCb = {}
for k, v in pairs(ModCallbacks) do nombreCb[v] = k end

local function anotarError(nombre, id, msg)
	local clave = nombre .. "|" .. tostring(nombreCb[id] or id)
	local e = S.errores[clave]
	if not e then
		e = { mod = nombre, cb = tostring(nombreCb[id] or id), n = 0, msg = tostring(msg):sub(1, 300) }
		S.errores[clave] = e
	end
	e.n = e.n + 1
end

local function medir(nombre, fn, id)
	if type(fn) ~= "function" then return fn end
	if envueltas[fn] then return envueltas[fn] end
	local rec = S.mods[nombre]
	if not rec then
		rec = { t = 0, n = 0, max = 0 }
		S.mods[nombre] = rec
	end
	local function fin(t0, ok, a, b, c, d)
		local dt = reloj() - t0
		rec.t = rec.t + dt
		rec.n = rec.n + 1
		if dt > rec.max then rec.max = dt end
		if not ok then
			anotarError(nombre, id, a)
			error(a, 0) -- se relanza igual: el juego lo trata como siempre
		end
		return a, b, c, d
	end
	local function envuelta(...)
		return fin(reloj(), pcall(fn, ...))
	end
	envueltas[fn] = envuelta
	return envuelta
end

-- Cada mod que se registre a partir de ahora tendrá sus callbacks medidos.
local RegisterModOriginal = RegisterMod
local function RegisterModMedido(nombre, ...)
	local m = RegisterModOriginal(nombre, ...)
	local ok = pcall(function()
		local add, addp, rem = m.AddCallback, m.AddPriorityCallback, m.RemoveCallback
		if type(add) == "function" then
			m.AddCallback = function(self, id, fn, ...) return add(self, id, medir(nombre, fn, id), ...) end
		end
		if type(addp) == "function" then
			m.AddPriorityCallback = function(self, id, prio, fn, ...) return addp(self, id, prio, medir(nombre, fn, id), ...) end
		end
		if type(rem) == "function" then
			m.RemoveCallback = function(self, id, fn) return rem(self, id, envueltas[fn] or fn) end
		end
	end)
	if not ok then S.sinMedir = S.sinMedir + 1 end
	return m
end
if not pcall(function() RegisterMod = RegisterModMedido end) then
	Isaac.DebugString("[PackScanner] no se pudo sustituir RegisterMod: el escáner no medirá nada")
	return
end

-- informe ordenado: ms por fotograma de render de cada mod
function S.informe()
	local lista = {}
	for nombre, r in pairs(S.mods) do
		if r.n > 0 then lista[#lista + 1] = { n = nombre, ms = r.t * 1000 / math.max(S.frames, 1), max = r.max * 1000, calls = r.n } end
	end
	table.sort(lista, function(a, b) return a.ms > b.ms end)
	return lista
end

function S.reiniciar()
	for _, r in pairs(S.mods) do r.t, r.n, r.max = 0, 0, 0 end
	S.frames = 0
end

local function volcarLog()
	local lista = S.informe()
	for i = 1, math.min(8, #lista) do
		local e = lista[i]
		Isaac.DebugString(string.format("[PackScanner] mod=%s avg_ms=%.3f max_ms=%.2f calls=%d frames=%d", e.n, e.ms, e.max, e.calls, S.frames))
	end
end

-- informe legible desde fuera del juego: data/!!!isaac_pack_scanner/save1.dat
local okj, json = pcall(require, "json")
local function guardar()
	if not okj then return end
	local errs = {}
	for _, e in pairs(S.errores) do errs[#errs + 1] = e end
	table.sort(errs, function(a, b) return a.n > b.n end)
	local top = {}
	for i, e in ipairs(S.informe()) do
		if i > 15 then break end
		top[i] = { mod = e.n, ms = math.floor(e.ms * 1000) / 1000, max_ms = math.floor(e.max * 100) / 100, llamadas = e.calls }
	end
	pcall(function() mod:SaveData(json.encode({ version = "0.2", frames = S.frames, mods = top, errores = errs })) end)
end

mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
	S.frames = S.frames + 1
	if S.frames % 1800 == 0 then volcarLog(); guardar() end -- cada ~30 s de juego
end)
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, guardar)
