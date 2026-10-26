# Traducción de las descripciones EID de los mods

Herramienta con la que se generó `mods_locales/traduccion_es_mods/datos_es.lua` (1287 descripciones de 9 mods).
Ejecuta el código Lua de cada mod con *stubs* de Isaac y EID (Python + `lupa`, Lua 5.3) y captura
cada `EID:add*` en inglés; los ids se guardan como nombre (`⟨c:Nombre⟩`) y el mod los resuelve en partida.

Requisitos: `python3 -m pip install lupa`.

## Actualizar tras una actualización de un mod

1. Copia los `.lua`/`.xml` de los mods a `src/<carpeta_del_mod>/` (no se sube al repositorio).
2. `python3 try_all.py`, `python3 rev.py` y `python3 ff.py` → capturas; `python3 collect.py` → `entries.json`
   (solo las entradas que el mod no trae ya en español).
3. `python3 segmentos.py` → crea `chunks/seg_NN.json` con las frases nuevas. Tradúcelas en `es/NN.txt`
   (una línea `índice<TAB>texto`, respetando `{{iconos}}`, `⟨…⟩`, `‹…›` y números).
4. `python3 check.py NN` → comprueba iconos, tokens y números.
5. `python3 build.py` → regenera `datos_es.lua`; `python3 test_mod.py ../../mods_locales/traduccion_es_mods` lo prueba.

Glosario: Lágrimas, Cadencia, Daño, Alcance, Velocidad de tiro, Velocidad, Suerte; recolectable, baratija,
fuego fatuo, charco; corazón de alma / negro / roto / de hueso / inmoral / mórbido / podrido / eterno;
sala del tesoro / jefe / diablo / ángel, trato con el diablo, piso, Planetario; magullar, condenar, adormecer,
enfurecer, cosido, hemorragia, sobrecargado; objeto consumible (FF «object»), contaminado (Tainted).
Los nombres propios de objetos se dejan en inglés (como los muestra el juego).
