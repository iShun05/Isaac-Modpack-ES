-- Traducción ES (mods) v0.1: nombres y texto de objetos de mods que solo vienen en inglés.
-- Se muestra mediante External Item Descriptions (EID); no toca los archivos de los mods de Workshop.
-- Para añadir un mod: copiar una línea de la tabla y poner el nombre EXACTO en inglés del items.xml del mod.
local mod = RegisterMod("Traducción ES (mods)", 1)

-- { tipo, nombre_en_inglés, nombre_es, texto_es }   tipo: "c" objeto, "t" baratija, "k" carta
local ENTRADAS = {
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
  -- Icesaac
  { "c", "Permafrost", "Permafrost", "Resbaladizo." },
  { "c", "Flurry Fly", "Mosca de ventisca", "Amigo congelado." },
  { "c", "Rag Fly", "Mosca de trapo", "Escudo orbital." },
  -- Mei
  { "c", "Mei's Broken Heart", "Corazón roto de Mei", "Falacia patética." },
  -- Transformer
  { "c", "Transformer", "Transformador", "Uno de cada tres." },
}

local function aplicar()
  if not EID then return end
  local ids = { c = "GetItemIdByName", t = "GetTrinketIdByName", k = "GetCardIdByName" }
  local clave = { c = "5.100.", t = "5.350.", k = "5.300." }
  local alta = { c = "addCollectible", t = "addTrinket", k = "addCard" }
  EID.ItemNames = EID.ItemNames or {}
  EID.ItemNames.spa = EID.ItemNames.spa or {}
  for _, e in ipairs(ENTRADAS) do
    local tipo, en, nombre, texto = e[1], e[2], e[3], e[4]
    local id = Isaac[ids[tipo]](en)
    if id and id > 0 then
      local full = clave[tipo] .. id
      local propia = EID.descriptions and EID.descriptions.en_us and EID.descriptions.en_us.custom
        and EID.descriptions.en_us.custom[full]
      if propia then
        EID.ItemNames.spa[full] = nombre -- el mod ya trae su descripción: solo traducimos el nombre
      else
        EID[alta[tipo]](EID, id, texto, nombre, "spa")
      end
    end
  end
end

aplicar()
