# Registro de cambios

## v1.0 — 2026-10-10
### Corregido
- **«REPENTOGON REQUIRED» tras abrir con el acceso de REPENTOGON.** Con Steam cerrado, el juego salía con código `0x35` y Steam lo relanzaba sin REPENTOGON. `/Applications/REPENTOGON.app` ahora abre Steam antes y espera (detalle en `docs/REPENTOGON_LANZADOR.md`).
### Archivos y pruebas
- `REPENTOGON.app` (fuera del repo), `docs/REPENTOGON_LANZADOR.md`. Sintaxis del script comprobada; **no probado abriendo con Steam cerrado**.

## v0.9 — 2026-10-10
### Añadido
- Comando **`diagnostico`**: lee el `log.txt` del juego y señala mods que fallan en bucle, avisos que se repiten miles de veces y la memoria de Lua.
### Corregido
- **Lag extremo en Isaac.** Medido en el log de una partida (137.441 líneas, 9,4 MB): **Eevee: Reunited (demo)** fallaba **15.013 veces** (una por fotograma, error `nil value (field 'MomsHeart')` en `petVee.lua`), cada una con volcado de pila. Desactivado (`disable.it`) y marcado `apagado` en el manifiesto para que ni `sincronizar` ni el instalador de Windows lo reactiven.
### Pendiente / sin resolver
- **41.362 avisos «Sound 837/846 has no samples»** desde la sala inicial: no he identificado qué los origina. Hipótesis sin comprobar: el lanzador ejecuta una copia v1.9.7.12 del juego con recursos de la v1.9.7.17.
- **InvEdit** escupe 1.020 avisos `AnmCache` (herramienta de trucos activa).
- Memoria Lua normal (57 MB): descartada como causa.
### Archivos y pruebas
- `scripts/isaac_pack.py`, `datos/mods.json`. Falta que el usuario juegue un rato y se vuelva a ejecutar `diagnostico` para confirmar la mejora. Sin medir FPS reales.

## v0.8 — 2026-10-09
### Añadido
- **Instalador de Windows 10/11** (`Instalar_Windows.bat` + `windows/instalar_windows.ps1`), listo para otros equipos: localiza Isaac en Steam (registro y `libraryfolders.vdf`), instala lo que no es de Workshop (lanzador oficial de REPENTOGON con hash verificado y acceso directo en el Escritorio, mod local de traducción), detecta qué mods de Workshop faltan y ofrece suscribirse a todos de golpe (script copiado al portapapeles para la consola de steamcommunity.com) o abrir cada página en la aplicación de Steam, y activa los packs elegidos con `disable.it` (clean, completo o mínimo). Se puede ejecutar varias veces.
- Comando `empaquetar`: genera `dist/Isaac_Pack_ES_Windows_v<versión>.zip`, adjunto a la release.
### Cambiado
- Versiones del manifiesto refrescadas con las instaladas (50 mods).
### Archivos y pruebas
- Comprobado en la botella: 115 mods registrados e instalados, ninguno sin registrar ni sin copiar a `mods/`, 10 desactivados a propósito. **El instalador de Windows NO está probado**: aquí no hay PowerShell ni Windows; solo revisé equilibrio de llaves y los casos conocidos de PowerShell 5.1. Steam no permite suscribirse sin tu sesión, por eso ese paso es semiautomático.

## v0.7 — 2026-10-09
### Corregido
- **El lanzador de REPENTOGON se cerraba en Wine** (Program Error / Wine Debugger) y el juego arrancaba sin REPENTOGON. Causa: `launcher-data` era 0.3.12-beta con el `.exe` en 0.4.8-beta. Sustituido por el paquete oficial 0.4.8-beta (hash verificado) con copia previa. Detalle en `docs/REPENTOGON_LANZADOR.md`.
### Archivos y pruebas
- Probado dos veces con un Wine limpio: el hilo remoto termina con código 0, el juego sigue abierto y el log muestra REPENTOGON detectado (Encyclopedia) y 116 mods cargados.
- Pendiente: probar el acceso desde Whisky (con su configuración) y los mods que requieren REPENTOGON.

## v0.6 — 2026-10-09
### Añadido
- Los 4 mods de rendimiento (Smart Culling, AntiCrash, Potato Cup, Clear Tears) ya están suscritos (115 suscripciones, comprobado releyendo la lista de Steam) y copiados a `mods/` con `sincronizar`. Ya no queda nada por suscribir.
### Cambiado
- Docs regenerados con el estado real: 115 mods instalados, 10 desactivados a propósito.
### Archivos y pruebas
- `docs/*`. Sin cambios de código. Sin probar en el juego.

## v0.5 — 2026-10-09
### Corregido
- **Seguridad:** `disable.it` ya no se crea siguiendo un enlace simbólico (un mod ajeno podría traerlo como enlace y hacer que `touch` escribiera fuera de `mods/`). Nueva función `marcar()` usada por `aplicar` y `sincronizar`.
### Archivos y pruebas
- `scripts/isaac_pack.py`. Probado con un enlace simbólico de prueba en una carpeta temporal: el enlace se elimina, el archivo destino queda intacto. El aviso automático no traía detalles; esta es la única escritura sobre rutas de mods ajenos que podía seguir enlaces.

## v0.4 — 2026-10-09
### Corregido
- **Seguridad (path traversal) en `sincronizar`:** el nombre de carpeta salía del `<directory>` del `metadata.xml` de cada mod, que es un dato ajeno. Ahora solo se acepta un nombre simple (sin barras ni `..`), la ruta final debe quedar dentro de `mods/` y la copia no sigue enlaces simbólicos. Detectado por la revisión automática de seguridad.
### Archivos y pruebas
- `scripts/isaac_pack.py`. Probado el filtro con `../x`, `a/b`, `..`, `a\\b` y vacío (rechazados) y con las carpetas reales de los 111 mods (todas aceptadas).

## v0.3 — 2026-10-09
### Añadido
- **Pack «Rendimiento y estabilidad»** (entra en los presets `minimo` y `clean`): Mod Error Container, **Smart Culling** (3726132245, sin REPENTOGON), **AntiCrash** (2784448102), Potato Cup (2902768955) y Clear Tears/Antilag (2758700407). Elegidos con datos de la API de Steam; descartados `fpsup`, `lowfx` (2018, experimentales), **Mod Compatibility Hack** (obsoleto y puede empeorar el rendimiento) y **FPS Enhancer** (hace lo mismo que Smart Culling; usar uno solo). **High FPS** (3776277093) requiere instalar un componente nativo a mano: no se toca sin tu visto bueno.
- Comando **`sincronizar`**: copia a `mods/` lo que Steam ya descargó. Comprobado que el lanzador de REPENTOGON (`SkipUpdateMods = 1`) no lo hace. Los nuevos de contenido grande, caprichos, trucos y Missing Costumes entran desactivados.
- [Q5] Golden Brimstone (3007108843) catalogado como capricho, no suscrito.
### Cambiado
- `instalar` ahora también sincroniza. `juego_abierto()` ya no confunde el Steam de Whisky con el juego (antes bloqueaba `aplicar` con Steam abierto).
### Corregido
- Tras suscribirte a los 42 mods en v0.2, ninguno cargaba: seguían en `workshop/content` sin copiarse a `mods/`. Ahora están los 111 en `mods/` (10 desactivados a propósito).
### Archivos y pruebas
- Verificado: manifiesto sin ids duplicados ni descripciones vacías, regla de carpetas `<directory>_<id>` contra 69/69 mods, sintaxis de Python y JS, copia de seguridad previa, 10 `disable.it` esperados. Hallazgo: el juego volvió a escribir `Language=0` tras jugar (ver `docs/TRADUCCION.md`). **Sin probar el juego con los 111 mods**; las pruebas de fiabilidad las hace el usuario más adelante.
- Pendiente: suscribir los 4 mods de rendimiento (la sesión de Steam en Chrome se cerró).

## v0.2 — 2026-10-09
### Añadido
- **Packs temáticos** (Base, Calidad de vida, Interfaz, Sinergias, Contenido grande, Personajes, Visual y audio, Caprichos, Trucos) y comando `aplicar` que deja activos solo los elegidos con `disable.it` (reversible), más presets `minimo`, `clean`, `completo` y **perfiles guardados** (`guardar`).
- **Valoración de combinaciones** 🟢🟠🔴 (Epiphany con otro contenido, 3+ expansiones, REPENTOGON ausente, 4+ personajes, más de 60 mods). Criterio propio, **sin probar en el juego**.
- **43 mods recomendados nuevos** con nombre exacto de Workshop, suscriptores y fecha leídos de la API de Steam: Mod Config Menu - Impure, Mod Error Container, Faster Animations, Encyclopedia, Unlocks Reminder, **Lazy MattPack** (objetos de calidad 5), nueve mods de sinergias, Repentance Plus!, Reshaken, Fiend Folio Reloaded, Epiphany, Revelations Ch. 2, Andromeda, Job 2.5 y más (`docs/RECOMENDADOS.md`).
- `docs/PACKS.md`, `docs/DECISION_WORKSHOP.md` (recomendación Workshop vs todo fuera), `docs/suscribir_todo.js` (suscripción en bloque, **no probado**) y `scripts/packs_mac.command`.
- Comando `respaldo`: zip de `mods/` en `/Volumes/SanDisk/Juegos/mods/The_Binding_of_Isaac/respaldos/`.
### Cambiado
- `perfil clean|completo` (v0.1) sustituido por `aplicar clean|completo`. `docs/suscribir.html` ahora lista solo lo que falta, por pack. `estado` resume cada pack.
### Corregido
- **Mod Config Menu:** en v0.1 recomendé «Pure», que ya no existe en Workshop; la versión mantenida es **Impure** (3701683951).
### Archivos y pruebas
- Tocados: `scripts/isaac_pack.py` (reescrito), `datos/mods.json` (113 entradas), `docs/*`, `README.md`. Verificado: el CLI genera docs y estado sin errores y la sintaxis de `suscribir_todo.js`. **Sin probar en el juego**; las pruebas de fiabilidad quedan para más adelante a petición del usuario. No se ha aplicado ningún pack: tus 70 mods siguen como estaban.

## v0.1 — 2026-10-09
### Añadido
- **Manifiesto `datos/mods.json`** con los 70 mods de Workshop instalados: id, versión, categoría, descripción en español y veredicto.
- **`scripts/isaac_pack.py`** con `estado`, `instalar`, `espanol`, `docs` y `perfil clean|completo`.
- **Documentación en español:** `docs/MODS.md`, `RECOMENDACIONES.md`, `WEBS.md`, `TRADUCCION.md` y `suscribir.html` (fondo negro, responsive).
- **Mod local «Traducción ES (mods)»** con nombres y textos de Eevee: Reunited, Icesaac, Mei y Transformer para EID.
- **Vigilante `launchd` opcional** (`scripts/com.ishun05.isaac-espanol.plist`) que reaplica el español cuando cambian los mods o Steam actualiza. **No está instalado:** macOS le niega el acceso al SanDisk hasta que se dé *Acceso total al disco* a `python3`.
- **Descarga automática de REPENTOGON** (no es de Workshop) a `/Volumes/SanDisk/Juegos/mods/The_Binding_of_Isaac/externos/` si hay versión nueva.
### Cambiado
- El idioma ya no se fija editando las carpetas de Workshop (Steam las pisa): se guarda en `options.ini` y en `data/external item descriptions/`.
### Archivos y pruebas
- Verificado: el manifiesto cuadra con la carpeta `mods/` (70/70), REPENTOGON 1.1.3 al día, el script `estado` y la generación de docs. **Pendiente de prueba en el juego:** idioma y mod de traducción (no hay Lua local para validar la sintaxis).
