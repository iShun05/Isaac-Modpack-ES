# Registro de cambios

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
