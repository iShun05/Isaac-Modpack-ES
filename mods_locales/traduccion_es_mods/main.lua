-- Traducción ES (mods) v1.0: descripciones de EID en español para los mods que solo las traen en inglés.
-- Los textos están en datos_es.lua (generado). Aquí solo se resuelven los ids y se registran en "spa".
-- No toca los mods de Workshop. Coste: una pasada al cargar y otra al empezar partida; nada por frame.
local mod = RegisterMod("Traducción ES (mods)", 1)
local DATOS = include("datos_es")

-- Entradas antiguas a mano (mods sin texto EID propio): { tipo, nombre_en, nombre_es, texto_es }
local MANUALES = {
  -- Eevee: Reunited
  { "c", "Sneak Scarf", "Bufanda sigilosa", "¡Cuidado, no hagas ruido!" },
  { "c", "Shiny Charm", "Amuleto brillante", "Suerte aumentada." },
  { "c", "Black Glasses", "Gafas negras", "Únete a los guays." },
  { "c", "Cookie Jar", "Tarro de galletas", "De una en una, por favor." },
  { "c", "Strange Egg", "Huevo extraño", "¿Debería cuidarlo?" },
  { "c", "Lil Eevee", "Eevee pequeño", "Protege al peque." },
  { "c", "Bad EGG", "Huevo malo", "¡Se oyen ruidos dentro! Eclosionará pronto." },
  { "c", "Wonderous Launcher", "Lanzador prodigioso", "¡Es hora de duelo!" },
  { "c", "Bag of Poke Balls", "Bolsa de Poké Balls", "Reparte bolas." },
  { "c", "Master Ball", "Master Ball", "Captura garantizada." },
  { "c", "Poke Stop", "Poképarada", "Hay que encontrarlos todos…" },
  { "c", "Tail Whip", "Látigo", "Meneo agresivo de cola." },
  { "t", "Lock-On Specs", "Gafas de blanco fijo", "¡Mantén la concentración!" },
  { "t", "Eviolite", "Mineral Evolutivo", "Fiel a tus orígenes." },
  { "t", "Alert Specs", "Gafas de alerta", "¡Quita las zarpas!" },
  { "k", "Poke Ball", "Poké Ball", "Ya conoces el lema." },
  { "k", "Great Ball", "Super Ball", "Para los de nivel superior." },
  { "k", "Ultra Ball", "Ultra Ball", "La de siempre, fiable." },
  -- Icesaac (las descripciones van en datos_es.lua; aquí solo el nombre)
  { "c", "Permafrost", "Permafrost" },
  { "c", "Flurry Fly", "Mosca de ventisca" },
  { "c", "Rag Fly", "Mosca de trapo" },
  -- Mei
  { "c", "Mei's Broken Heart", "Corazón roto de Mei", "Falacia patética." },
  -- Transformer
  { "c", "Transformer", "Transformador", "Uno de cada tres." },
}

local CLAVE = { c = "5.100.", t = "5.350.", k = "5.300." }
local BUSCAR = {
  c = Isaac.GetItemIdByName, t = Isaac.GetTrinketIdByName, k = Isaac.GetCardIdByName,
  p = Isaac.GetPillEffectByName,
}

-- "⟨c:Nombre⟩" -> id del juego; "‹A.B.C›" -> valor de la global del mod. nil si no existe.
local function resolver(tok)
  local tipo, nombre = tok:match("^⟨(%a+):(.*)⟩$")
  local id
  if tipo == "pl" then
    local base = nombre:match("^(.*):B$")
    if base then id = Isaac.GetPlayerTypeByName(base, true) else id = Isaac.GetPlayerTypeByName(nombre, false) end
  elseif tipo and BUSCAR[tipo] then
    id = BUSCAR[tipo](nombre)
  else
    local ruta = tok:match("^‹(.*)›$")
    if ruta then
      local v = _G
      for parte in ruta:gmatch("[^%.]+") do
        if type(v) ~= "table" then v = nil break end
        v = v[parte]
      end
      id = v
    end
  end
  if type(id) == "number" and id >= 0 then return id end
end

local function texto(desc)
  desc = desc:gsub("⟨.-⟩", function(t) local id = resolver(t); return id and tostring(id) end)
  desc = desc:gsub("‹.-›", function(t) local id = resolver(t); return id and tostring(id) end)
  -- iconos cuyo objeto no existe: se quitan para no mostrar basura
  desc = desc:gsub("{{[^{}]-⟨.-⟩[^{}]-}}", ""):gsub("{{[^{}]-‹.-›[^{}]-}}", "")
  return desc
end

-- filas escritas por este mod; si otra fila ocupa su sitio, es una traducción propia del mod y se respeta
local nuestras = {}

local function aplicar()
  if not EID or not EID.descriptions then return end
  EID:CreateDescriptionTableIfMissing("custom", "spa")
  EID:CreateDescriptionTableIfMissing("pills", "spa")
  EID:CreateDescriptionTableIfMissing("horsepills", "spa")
  EID:CreateDescriptionTableIfMissing("birthright", "spa")
  EID:CreateDescriptionTableIfMissing("CharacterInfo", "spa")
  local es, en = EID.descriptions.spa, EID.descriptions.en_us or {}
  EID.ItemNames = EID.ItemNames or {}
  EID.ItemNames.spa = EID.ItemNames.spa or {}

  for _, e in ipairs(DATOS) do
    local tipo, tok, jugador, desc = e[1], e[2], e[3], e[4]
    local id = resolver(tok)
    if id then
      if CLAVE[tipo] then
        local full = CLAVE[tipo] .. id
        if not es.custom[full] or es.custom[full] == nuestras[full] then
          local orig = en.custom and en.custom[full]
          local fila = { id, orig and orig[2] or nil, texto(desc), orig and orig[4] or nil }
          es.custom[full], nuestras[full] = fila, fila
        end
      elseif tipo == "p" then
        local k = "p" .. id
        if not es.pills[id + 1] or es.pills[id + 1] == nuestras[k] then
          local orig = en.pills and en.pills[id + 1]
          local fila = { id, orig and orig[2] or nil, texto(desc), orig and orig[4] or nil }
          if not es.horsepills[id + 1] or es.horsepills[id + 1] == nuestras[k] then es.horsepills[id + 1] = fila end
          es.pills[id + 1], nuestras[k] = fila, fila
        end
      elseif tipo == "b" then
        local k = "b" .. id
        if not es.birthright[id + 1] or es.birthright[id + 1] == nuestras[k] then
          local orig = en.birthright and en.birthright[id + 1]
          local fila = { orig and orig[1] or jugador, "", texto(desc) }
          es.birthright[id + 1], nuestras[k] = fila, fila
        end
      elseif tipo == "ch" then
        local k = "ch" .. id
        if not es.CharacterInfo[id] or es.CharacterInfo[id] == nuestras[k] then
          local orig = en.CharacterInfo and en.CharacterInfo[id]
          local fila = { orig and orig[1] or jugador, texto(desc) }
          es.CharacterInfo[id], nuestras[k] = fila, fila
        end
      end
    end
  end

  for _, e in ipairs(MANUALES) do
    local tipo, nombre_en, nombre, desc = e[1], e[2], e[3], e[4]
    local id = BUSCAR[tipo](nombre_en)
    if id and id > 0 then
      local full = CLAVE[tipo] .. id
      EID.ItemNames.spa[full] = nombre
      local propia_en = en.custom and en.custom[full]
      if desc and not propia_en and (not es.custom[full] or es.custom[full] == nuestras[full]) then
        local fila = { id, nombre, desc, nil }
        es.custom[full], nuestras[full] = fila, fila
      elseif es.custom[full] and es.custom[full] == nuestras[full] then
        es.custom[full][2] = nombre
      end
    end
  end
end

aplicar()
-- Algunos mods registran sus textos de EID tarde: se repite al empezar o continuar partida.
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, aplicar)
