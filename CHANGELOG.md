# Registro de cambios

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
