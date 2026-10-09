# ¿Todo fuera de Workshop con un script, o Workshop + algo fuera?

## Recomendación: Workshop para todo lo que esté en Workshop; fuera solo lo que no pueda estar
Es la mezcla que ya tienes, y es la mejor para una experiencia sin problemas.

| | Todo fuera + script | Workshop + externo mínimo (elegida) |
|---|---|---|
| Actualizaciones | A mano: el script tendría que vigilar 110 mods | Steam las instala solo |
| Duplicados y guardados | Riesgo real: ya pasó con Fiend Folio (versión manual + Workshop = guardado corrupto) y se purgó el 2026-09-27 | Una sola copia por mod |
| Descarga automática | Steam no deja bajar mods de Workshop sin tu sesión; habría que re-publicar copias ajenas | Una suscripción por mod (o `suscribir_todo.js`) |
| Dependencias | Hay que mantener el orden y las versiones a mano | Steam las resuelve |
| Copia de seguridad | La copia es el propio mod | `isaac_pack.py respaldo` guarda un zip de `mods/` en el SanDisk |

**Fuera de Workshop solo van:** REPENTOGON (no es un mod normal; el script lo descarga de GitHub) y el mod local «Traducción ES (mods)». Los mods que no existan en Workshop se meterían en `mods_locales/` y el script los instalaría; hoy no hay ninguno que lo necesite.

## Cómo suscribirte a todo de una vez
1. Abre `steamcommunity.com` con tu sesión iniciada.
2. Abre la consola del navegador y pega `docs/suscribir_todo.js` (hace lo mismo que pulsar «Suscribirse», mod a mod).
3. Abre Steam (en Whisky) y deja que descargue. Luego `python3 scripts/isaac_pack.py estado`.

> No he podido suscribirte yo: requiere tu sesión de Steam y no tengo acceso a ella. El script usa la petición `/sharedfiles/subscribe` de la web de Steam y **no está probado**; si falla, usa `docs/suscribir.html` (un clic por mod).

## Qué pasa después de suscribirte (comprobado el 2026-10-09)
- Steam descarga el mod a `workshop/content/250900/<id>/`, pero **no lo copia a `mods/`**: el lanzador de REPENTOGON tiene `SkipUpdateMods = 1` (`Documents/My Games/repentogon_launcher.ini`) y salta esa copia. Por eso un mod recién suscrito no carga solo.
- `python3 scripts/isaac_pack.py sincronizar` hace esa copia (carpeta `<directory>_<id>`, igual que el juego; comprobado con los 69 mods ya instalados) y deja **desactivados** los nuevos de contenido grande, caprichos y trucos.
- Antes de sincronizar, `respaldo` guarda un zip de `mods/` (hecho hoy: `respaldos/mods_2026-10-09.zip`).
