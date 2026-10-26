# Panel dentro del juego: packs, mods y errores (Mac y Windows)

Necesita REPENTOGON (usa su menú ImGui, el de la tecla de consola `~`).

## Cómo se abre
- Pulsa `~` (consola de REPENTOGON) y entra en el menú **«Packs ES»** de la barra superior, o
- pulsa **F9** durante una partida.

## Pestañas
| Pestaña | Para qué |
|---|---|
| **Packs** | Marca los packs que quieres (con su contador de mods activos), usa los presets *clean / completo / minimo* y pulsa **Guardar selección**. |
| **Mods** | Lista de todos los mods por pack, con una casilla para activar o desactivar uno suelto (pasa el ratón para ver qué hace). Los no instalados salen aparte. |
| **Escáner** | Mide los FPS y las entidades en pantalla mientras juegas y **te avisa** (notificación) si el juego va lento de forma sostenida. Con «Medir cada mod» activado muestra el **ranking de mods por coste** (ms por fotograma, con ⚠ si pasa de 2 ms) y recomendaciones concretas (qué mod desactivar, qué mods de rendimiento probar). Botones **Copiar informe** y **Reiniciar medidas**. |
| **Errores** | Errores de Lua de la **sesión anterior**, agrupados por mod, con cuántas veces fallaron, el primer mensaje y la pila. Botón **Copiar al portapapeles** para pegármelos. |

## Cómo se aplica lo que elijas
Un mod no puede crear los archivos `disable.it` desde dentro del juego, así que el panel **guarda tu elección** (`data/isaac_pack_panel/save*.dat`) y se aplica **al abrir Isaac otra vez**:
- **Mac:** `REPENTOGON.app` ejecuta `isaac_pack.py preparar` antes de abrir: copia mods nuevos, aplica el parche de Job, aplica tu selección y refresca el panel con el estado real y los errores del log anterior.
- **Windows:** cierra Isaac y ejecuta `Aplicar_seleccion.bat` (hace lo mismo con `instalar_windows.ps1 -Rapido`).

> Cierra Isaac del todo antes de aplicar. Las órdenes sueltas por mod ganan a las del pack; los mods marcados «apagado» solo se encienden si los marcas tú. Son los que cambian la experiencia del juego base: Just Gambling (gacha), Passive Skill Trees, Every Item Stacks!, Golden Brimstone, energypills y los trucos, además de Eevee, Missing Costumes y el Job original.

## Lo mismo en los dos ordenadores
- Las **suscripciones de Workshop son de tu cuenta**: los dos PC tienen los mismos mods descargados.
- Lo que cambia entre PC es **qué mods están activados**: eso es local de cada carpeta de Isaac. Con el mismo preset (o la misma selección del panel) los dos quedan igual.
- El estado y los errores que muestra el panel se calculan igual en Mac (`isaac_pack.py`) y en Windows (`instalar_windows.ps1`).

## Si un mod da error
1. Mira la pestaña **Errores** (o ejecuta `python3 scripts/isaac_pack.py diagnostico` en Mac).
2. Copia el texto con el botón y pégamelo.
3. Mientras tanto, desmárcalo en la pestaña **Mods**, guarda y reabre.

## Qué no hace (todavía)
- No muestra errores de la sesión en curso (Lua no puede leer el log); salen en el panel rojo de REPENTOGON «Error Display» y en la consola.
- No suscribe a mods de Workshop: eso solo lo puede hacer tu cuenta de Steam (ver `DECISION_WORKSHOP.md`).
- **Sin probar dentro del juego.** El código del panel pasa el análisis de `lua-language-server` y usa solo funciones de la documentación oficial de REPENTOGON, pero no lo he podido abrir.

## Escáner de lag
- **Parte ligera (siempre activa con el panel):** FPS medios, peor fotograma, tirones (>40 ms) y cuántos efectos, lágrimas, láseres, proyectiles y enemigos hay. Si el juego va por debajo de 33 ms/fotograma durante 5 s, sale un aviso (como máximo uno por minuto).
- **Parte por mod (opcional):** el mod `!!!isaac_pack_scanner` se carga el primero y envuelve los callbacks de los demás mods para medir cuánto tarda cada uno. Se activa con «Medir cada mod» (pestaña Escáner) + Guardar + reabrir, con `isaac_pack.py escaner on` (Mac) o la casilla de la ventana de Windows. Añade un pequeño coste: apágalo cuando ya no lo necesites.
- **Fuera del juego:** cada ~30 s de juego anota en `log.txt` las líneas `[PackScanner] mod=… avg_ms=…`, y `isaac_pack.py diagnostico` las resume.
- **Cómo se calcula:** 16,6 ms por fotograma es todo el presupuesto de 60 FPS; un mod que gaste más de 2 ms por sí solo es sospechoso.
- Probado con un Lua embebido y APIs simuladas (envoltorio de callbacks: devuelve los mismos valores, quita callbacks bien y propaga errores; monitor: FPS, entidades, recomendaciones y aviso). **No probado dentro de Isaac.**
