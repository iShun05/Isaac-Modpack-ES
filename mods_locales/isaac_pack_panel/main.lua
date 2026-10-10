-- Isaac Pack ES (panel) v0.1 · requiere REPENTOGON (menú ImGui).
-- Elige packs y mods; la selección se guarda en data/isaac_pack_panel/save*.dat y se aplica al abrir Isaac con el
-- acceso de REPENTOGON (Mac) o al ejecutar «Aplicar_seleccion» / el instalador (Windows). Desde un mod no se pueden
-- crear los archivos disable.it, por eso la aplicación ocurre fuera del juego.
local mod = RegisterMod("Isaac Pack ES (panel)", 1)
if not (REPENTOGON and ImGui) then return end

local json = require("json")
local okd, D = pcall(require, "panel_datos")
if not okd or type(D) ~= "table" then
	D = { version = "?", generado = "", packs = {}, presets = {}, seleccion = {}, mods = {}, errores = {} }
end

local sel = {}
for k, v in pairs(D.seleccion or {}) do sel[k] = v end
local override = {} -- id de mod -> true/false (anula lo que diga su pack)
local scannerDeseado = (_G.IsaacPackScanner and _G.IsaacPackScanner.activo) and true or false

local function notificar(texto, tipo)
	pcall(ImGui.PushNotification, texto, tipo or ImGuiNotificationType.INFO, 6000)
end

local function guardar()
	local packs, on, off = {}, {}, {}
	for _, p in ipairs(D.packs) do
		if sel[p.k] then packs[#packs + 1] = p.k end
	end
	for id, v in pairs(override) do
		if v then on[#on + 1] = id else off[#off + 1] = id end
	end
	mod:SaveData(json.encode({ packs = packs, on = on, off = off, scanner = scannerDeseado }))
	notificar("Guardado. Se aplica al abrir Isaac con REPENTOGON la próxima vez (cierra el juego del todo).", ImGuiNotificationType.SUCCESS)
end

local function textoErrores()
	if not D.errores or #D.errores == 0 then return "Sin errores en la última sesión." end
	local t = {}
	for _, e in ipairs(D.errores) do
		t[#t + 1] = string.format("[%s] %d vez/veces\n%s\n%s", e.mod, e.n, e.msg or "", e.pila or "")
	end
	return table.concat(t, "\n\n")
end


-- ------------------------------------------------------------------ monitor de rendimiento
local RING = 900 -- ~15 s de fotogramas
local ring, ri, rn = {}, 0, 0
local ultimoT = nil
local ents = { efectos = 0, lagrimas = 0, lasers = 0, proyectiles = 0, enemigos = 0, total = 0 }
local ultimoAviso = -100000
local lentoDesde = nil
local informeTexto = ""
local fallos = 0
local ultimoF = -1

local function estadisticas()
	if rn == 0 then return nil end
	local suma, maxv, tirones = 0, 0, 0
	local copia = {}
	for i = 1, rn do
		local v = ring[i]
		suma = suma + v
		if v > maxv then maxv = v end
		if v > 40 then tirones = tirones + 1 end
		copia[i] = v
	end
	table.sort(copia)
	local media = suma / rn
	return { media = media, fps = 1000 / math.max(media, 1), max = maxv, tirones = tirones, p95 = copia[math.max(1, math.floor(rn * 0.95))], n = rn }
end

local function topMods()
	local S = _G.IsaacPackScanner
	if not (S and S.activo and S.informe and S.frames > 120) then return {} end
	return S.informe()
end

local function pack_de(nombreMod)
	local bajo = string.lower(nombreMod)
	for _, m in ipairs(D.mods) do
		local n = string.lower(m.n)
		if n == bajo or string.find(bajo, n, 1, true) or string.find(n, bajo, 1, true) then return m end
	end
	return nil
end

local function recomendaciones(st, top)
	local r = {}
	if not st then return { "Sin datos todavía: entra en una partida y juega unos segundos." } end
	if st.fps < 45 then r[#r + 1] = string.format("El juego va a %.0f FPS de media (lo normal son 60).", st.fps) end
	if st.tirones > 5 then r[#r + 1] = string.format("Hay %d tirones (fotogramas de más de 40 ms) en los últimos segundos.", st.tirones) end
	if ents.efectos > 150 then r[#r + 1] = string.format("Hay %d efectos en pantalla: es lo que más suele pesar. Prueba los mods del pack Rendimiento (Smart Culling, Potato Cup).", ents.efectos) end
	if ents.lagrimas + ents.proyectiles + ents.lasers > 120 then r[#r + 1] = string.format("Hay %d lágrimas/proyectiles/láseres a la vez: Smart Culling los limita.", ents.lagrimas + ents.proyectiles + ents.lasers) end
	if #top > 0 then
		local t1 = top[1]
		if t1.ms > 2 then
			local info = pack_de(t1.n)
			local extra = info and string.format(" (pack %s, veredicto %s)", info.pn or info.p, info.v) or ""
			r[#r + 1] = string.format("«%s» gasta %.1f ms por fotograma%s; el presupuesto total es 16,6 ms. Es el principal sospechoso: desactívalo en la pestaña Mods y compara.", t1.n, t1.ms, extra)
		end
		local suma = 0
		for i = 1, #top do suma = suma + top[i].ms end
		if suma > 8 then r[#r + 1] = string.format("Entre todos los mods gastan %.1f ms por fotograma: hay demasiados activos. Prueba el preset minimo o clean.", suma) end
	else
		r[#r + 1] = "Para saber QUÉ MOD pesa, marca «Medir cada mod» abajo, pulsa Guardar en la pestaña Packs y reabre el juego."
	end
	for _, e in ipairs(D.errores or {}) do
		if e.n >= 50 then r[#r + 1] = string.format("«%s» falló %d veces en la sesión anterior: eso causa lag. Desactívalo.", e.mod, e.n) end
	end
	if #r == 0 then r[#r + 1] = "Todo en orden: sin tirones ni mods pesados detectados." end
	return r
end

local function construirInforme(st, top, rec)
	local t = { "Informe del escáner — Isaac Pack ES v" .. tostring(D.version) }
	if st then t[#t + 1] = string.format("FPS medios: %.0f · peor fotograma: %d ms · p95: %d ms · tirones >40 ms: %d (últimos %d fotogramas)", st.fps, st.max, st.p95, st.tirones, st.n) end
	t[#t + 1] = string.format("Entidades: %d efectos, %d lágrimas, %d láseres, %d proyectiles, %d enemigos (total %d)", ents.efectos, ents.lagrimas, ents.lasers, ents.proyectiles, ents.enemigos, ents.total)
	if #top > 0 then
		t[#t + 1] = "Mods por coste (ms por fotograma):"
		for i = 1, math.min(10, #top) do t[#t + 1] = string.format("  %d. %s — %.2f ms (máx. %.1f ms, %d llamadas)", i, top[i].n, top[i].ms, top[i].max, top[i].calls) end
	end
	for _, linea in ipairs(rec) do t[#t + 1] = "• " .. linea end
	return table.concat(t, "\n")
end

local function contarEntidades()
	local c = { efectos = 0, lagrimas = 0, lasers = 0, proyectiles = 0, enemigos = 0, total = 0 }
	for _, e in ipairs(Isaac.GetRoomEntities()) do
		c.total = c.total + 1
		local t = e.Type
		if t == 1000 then c.efectos = c.efectos + 1
		elseif t == 2 then c.lagrimas = c.lagrimas + 1
		elseif t == 7 then c.lasers = c.lasers + 1
		elseif t == 9 then c.proyectiles = c.proyectiles + 1
		elseif e:IsEnemy() then c.enemigos = c.enemigos + 1 end
	end
	ents = c
end

local function actualizarEscaner()
	local st, top = estadisticas(), topMods()
	local rec = recomendaciones(st, top)
	informeTexto = construirInforme(st, top, rec)
	if st then
		ImGui.UpdateText("ps_sc_fps", string.format("FPS medios: %.0f   ·   peor fotograma: %d ms   ·   p95: %d ms   ·   tirones (>40 ms): %d", st.fps, st.max, st.p95, st.tirones))
	end
	ImGui.UpdateText("ps_sc_ent", string.format("Ahora mismo: %d efectos · %d lágrimas · %d láseres · %d proyectiles · %d enemigos", ents.efectos, ents.lagrimas, ents.lasers, ents.proyectiles, ents.enemigos))
	for i = 1, 8 do
		local e = top[i]
		ImGui.UpdateText("ps_sc_t" .. i, e and string.format("%d. %s — %.2f ms/fotograma (máx. %.1f ms)%s", i, e.n, e.ms, e.max, e.ms > 2 and "   ⚠" or "") or "")
	end
	ImGui.UpdateText("ps_sc_rec", table.concat(rec, "\n"))
	return st, top, rec
end

local function construir()
	ImGui.CreateMenu("packsESMenu", "\u{f1b3} Packs ES")
	ImGui.AddElement("packsESMenu", "packsESItem", ImGuiElement.MenuItem, "\u{f0c9} Packs y mods (F9)")
	ImGui.CreateWindow("packsESWin", "Isaac Pack ES v" .. tostring(D.version))
	ImGui.LinkWindowToElement("packsESWin", "packsESItem")
	ImGui.SetWindowSize("packsESWin", 560, 460)
	ImGui.AddTabBar("packsESWin", "packsESTabs")

	-- ---------------------------------------------------------- Packs
	ImGui.AddTab("packsESTabs", "psTabPacks", "Packs")
	local inst, act, err = 0, 0, #(D.errores or {})
	for _, m in ipairs(D.mods) do
		if m.i then inst = inst + 1 end
		if m.i and m.a then act = act + 1 end
	end
	ImGui.AddText("psTabPacks", string.format("Mods instalados: %d · activos: %d · con error en la última sesión: %d", inst, act, err), true)
	ImGui.AddText("psTabPacks", "Marca los packs que quieres y pulsa Guardar. Base siempre va activo.", true)
	for _, p in ipairs(D.packs) do
		ImGui.AddCheckbox("psTabPacks", "pp_" .. p.k, string.format("%s (%d/%d activos)", p.n, p.activos, p.total), function(v)
			sel[p.k] = v
			for _, m in ipairs(D.mods) do
				if m.p == p.k then
					override[m.id] = nil
					if m.i then pcall(ImGui.UpdateData, "pm_" .. m.id, ImGuiData.Value, v and not m.ap or false) end
				end
			end
		end, sel[p.k] and true or false)
		ImGui.SetTooltip("pp_" .. p.k, p.d or "")
	end
	ImGui.AddElement("psTabPacks", "", ImGuiElement.Separator)
	for nombre, lista in pairs(D.presets or {}) do
		ImGui.AddButton("psTabPacks", "ps_preset_" .. nombre, "Preset: " .. nombre, function()
			local en = {}
			for _, k in ipairs(lista) do en[k] = true end
			for _, p in ipairs(D.packs) do
				sel[p.k] = en[p.k] and true or false
				pcall(ImGui.UpdateData, "pp_" .. p.k, ImGuiData.Value, sel[p.k])
			end
		end, true)
		ImGui.AddElement("psTabPacks", "", ImGuiElement.SameLine)
	end
	ImGui.AddElement("psTabPacks", "", ImGuiElement.Separator)
	ImGui.AddButton("psTabPacks", "ps_guardar", "Guardar selección", guardar)

	-- ---------------------------------------------------------- Mods
	ImGui.AddTab("packsESTabs", "psTabMods", "Mods")
	ImGui.AddText("psTabMods", "Casilla = el mod estará activo. Los cambios se guardan con «Guardar selección» (pestaña Packs).", true)
	local packActual = nil
	for _, m in ipairs(D.mods) do
		if m.p ~= packActual then
			packActual = m.p
			ImGui.AddElement("psTabMods", "", ImGuiElement.SeparatorText, m.pn or m.p)
		end
		if m.i then
			ImGui.AddCheckbox("psTabMods", "pm_" .. m.id, m.n .. "  [" .. (m.v or "") .. "]" .. (m.rg == "requiere" and " (REPENTOGON)" or ""), function(v)
				override[m.id] = v and true or false
			end, m.a and true or false)
			ImGui.SetTooltip("pm_" .. m.id, m.d or "")
		else
			ImGui.AddText("psTabMods", "(no instalado) " .. m.n, false)
		end
	end

	-- ---------------------------------------------------------- Escáner
	ImGui.AddTab("packsESTabs", "psTabScan", "Escáner")
	ImGui.AddText("psTabScan", "Mide los FPS y las entidades en pantalla mientras juegas y te avisa de qué puede causar lag.", true)
	ImGui.AddText("psTabScan", "Esperando datos…", true, "ps_sc_fps")
	ImGui.AddText("psTabScan", "", true, "ps_sc_ent")
	ImGui.AddElement("psTabScan", "", ImGuiElement.SeparatorText, "Mods por coste")
	local S0 = _G.IsaacPackScanner
	ImGui.AddText("psTabScan", (S0 and S0.activo) and "Escáner por mod ACTIVO (mide cada callback)." or "Escáner por mod apagado: actívalo abajo para ver qué mod pesa.", true)
	for i = 1, 8 do ImGui.AddText("psTabScan", "", false, "ps_sc_t" .. i) end
	ImGui.AddElement("psTabScan", "", ImGuiElement.SeparatorText, "Recomendaciones")
	ImGui.AddText("psTabScan", "", true, "ps_sc_rec")
	ImGui.AddElement("psTabScan", "", ImGuiElement.Separator)
	ImGui.AddCheckbox("psTabScan", "ps_sc_chk", "Medir cada mod (se aplica al reabrir; añade un pequeño coste)", function(v) scannerDeseado = v end, scannerDeseado)
	ImGui.SetTooltip("ps_sc_chk", "Envuelve los callbacks de los mods para medir cuánto tarda cada uno. Pulsa Guardar en la pestaña Packs y reabre Isaac.")
	ImGui.AddButton("psTabScan", "ps_sc_copiar", "Copiar informe", function()
		Isaac.SetClipboard(informeTexto ~= "" and informeTexto or "Sin datos todavía.")
		notificar("Informe copiado al portapapeles.", ImGuiNotificationType.SUCCESS)
	end)
	ImGui.AddElement("psTabScan", "", ImGuiElement.SameLine)
	ImGui.AddButton("psTabScan", "ps_sc_reset", "Reiniciar medidas", function()
		ring, ri, rn = {}, 0, 0
		if S0 and S0.reiniciar then S0.reiniciar() end
		notificar("Medidas reiniciadas.", ImGuiNotificationType.INFO)
	end)

	-- ---------------------------------------------------------- Errores
	ImGui.AddTab("packsESTabs", "psTabErr", "Errores")
	ImGui.AddText("psTabErr", "Errores de Lua de la sesión anterior (se leen del log al preparar el juego). Si un mod falla en bucle, desactívalo.", true)
	ImGui.AddInputTextMultiline("psTabErr", "ps_err_texto", "", nil, textoErrores(), 16)
	ImGui.AddButton("psTabErr", "ps_err_copiar", "Copiar al portapapeles", function()
		Isaac.SetClipboard(textoErrores())
		notificar("Errores copiados al portapapeles.", ImGuiNotificationType.SUCCESS)
	end)
end

local ok, e = pcall(construir)
if not ok then
	Isaac.DebugString("[Isaac Pack ES] no se pudo crear el panel: " .. tostring(e))
	print("[Isaac Pack ES] no se pudo crear el panel: " .. tostring(e))
	return
end

-- F9 abre/cierra el panel
mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
	if Input.IsButtonTriggered(Keyboard.KEY_F9, 0) then
		if ImGui.IsVisible() and ImGui.GetVisible("packsESWin") then
			ImGui.SetVisible("packsESWin", false)
		else
			ImGui.Show()
			ImGui.SetVisible("packsESWin", true)
		end
	end
end)

-- Monitor: tiempo de cada fotograma, entidades y aviso si el juego va lento de forma sostenida
mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
	if fallos >= 3 then return end
	local ahora = Isaac.GetTime()
	if ultimoT then
		local dt = ahora - ultimoT
		if dt > 0 and dt < 1000 then
			ri = ri % RING + 1
			ring[ri] = dt
			if rn < RING then rn = rn + 1 end
		end
	end
	ultimoT = ahora
	local f = Game():GetFrameCount()
	if f % 60 ~= 0 or f == ultimoF then return end
	ultimoF = f
	local ok, st, top = pcall(function()
		if f % 120 == 0 then contarEntidades() end
		return actualizarEscaner()
	end)
	if not ok then
		fallos = fallos + 1
		Isaac.DebugString("[Isaac Pack ES] monitor: " .. tostring(st))
		return
	end
	if st and st.media > 33 then
		lentoDesde = lentoDesde or ahora
		if ahora - lentoDesde > 5000 and ahora - ultimoAviso > 60000 then
			ultimoAviso = ahora
			local msg = "Isaac va lento (" .. string.format("%.0f", st.fps) .. " FPS)."
			if top and top[1] and top[1].ms > 2 then msg = msg .. " Sospechoso: " .. top[1].n .. " (" .. string.format("%.1f", top[1].ms) .. " ms/fotograma)." end
			notificar(msg .. " Abre el panel (F9) → Escáner.", ImGuiNotificationType.WARNING)
		end
	else
		lentoDesde = nil
	end
end)
