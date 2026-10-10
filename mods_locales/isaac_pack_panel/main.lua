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
	mod:SaveData(json.encode({ packs = packs, on = on, off = off }))
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
