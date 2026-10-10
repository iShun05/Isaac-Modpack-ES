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
| **Errores** | Errores de Lua de la **sesión anterior**, agrupados por mod, con cuántas veces fallaron, el primer mensaje y la pila. Botón **Copiar al portapapeles** para pegármelos. |

## Cómo se aplica lo que elijas
Un mod no puede crear los archivos `disable.it` desde dentro del juego, así que el panel **guarda tu elección** (`data/isaac_pack_panel/save*.dat`) y se aplica **al abrir Isaac otra vez**:
- **Mac:** `REPENTOGON.app` ejecuta `isaac_pack.py preparar` antes de abrir: copia mods nuevos, aplica el parche de Job, aplica tu selección y refresca el panel con el estado real y los errores del log anterior.
- **Windows:** cierra Isaac y ejecuta `Aplicar_seleccion.bat` (hace lo mismo con `instalar_windows.ps1 -Rapido`).

> Cierra Isaac del todo antes de aplicar. Las órdenes sueltas por mod ganan a las del pack; los mods marcados «apagado» (Eevee, Missing Costumes, Job original) solo se encienden si los marcas tú.

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
