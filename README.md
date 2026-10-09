# The Binding of Isaac · Pack de mods en español

Catálogo, packs, instalador y traducción automática al español de los mods de **Isaac: Repentance+** en macOS (Whisky, botella `steam11`): **111 instalados (10 desactivados a propósito)** y más recomendados, cada uno con ficha en español, agrupados en packs para activar solo lo que quieras.

- **Versión actual:** v0.4
- **Plataforma:** macOS + Whisky (Steam de Windows). Juego: Repentance+ v1.9.7.17.J460 · REPENTOGON 1.1.3
- **Estado:** pendiente de pruebas manuales (idioma `Language=2`, mod de traducción, packs y combinaciones). Las pruebas de fiabilidad las hace el usuario más adelante

## Funciones principales
- **Manifiesto único** (`datos/mods.json`): 113 mods con id de Workshop, pack, descripción en español y veredicto (esencial · recomendado · opcional · herramienta · capricho · quitar).
- **Packs como en el pack de Balatro:** Base · Calidad de vida · Interfaz · Rendimiento · Sinergias · Contenido grande · Personajes · Visual y audio · Caprichos · Trucos. `aplicar` deja activos solo los que elijas, con **valoración** de la combinación (🟢🟠🔴) y **perfiles guardados**.
- **Mods nuevos recomendados:** `docs/RECOMENDADOS.md` con el nombre exacto de Workshop, suscriptores y fecha (incluye Lazy MattPack, objetos de calidad 5).
- **Instalación fácil:** `docs/suscribir.html` abre la página de cada mod para suscribirse con un clic; los mods que no son de Workshop (REPENTOGON, el mod local de traducción) se descargan/copian solos.
- **Respaldo:** `respaldo` guarda un zip de `mods/` en el SanDisk.
- **Español automático:** reaplica el idioma del juego y de EID y avisa de mods nuevos sin registrar; a demanda con un comando o solo con el vigilante opcional (ver `docs/TRADUCCION.md`).
- **Mod local «Traducción ES (mods)»:** nombres y textos en español de Eevee: Reunited, Icesaac, Mei y Transformer.

## Tecnología
Python 3 (solo biblioteca estándar), Lua (mod local para EID), `launchd` para el vigilante.

## Estructura
```
datos/mods.json            manifiesto de mods
docs/MODS.md               ficha de los mods instalados (generada)
docs/RECOMENDADOS.md       mods por instalar, por pack (generada)
docs/PACKS.md              qué trae cada pack y valoración de combinaciones (generada)
docs/DECISION_WORKSHOP.md  Workshop vs todo fuera, y cómo suscribirse a todo
docs/RECOMENDACIONES.md    qué quitar, qué dejar y qué añadir
docs/WEBS.md               webs de mods y herramientas
docs/TRADUCCION.md         cómo funciona el español automático
docs/suscribir.html        lo que falta por suscribir (generada, fondo negro)
docs/suscribir_todo.js     suscripción en bloque desde steamcommunity.com (generada)
mods_locales/              mods propios (no de Workshop)
scripts/isaac_pack.py      estado · packs · aplicar · guardar · sincronizar · espanol · docs · respaldo · instalar
scripts/packs_mac.command  doble clic para elegir packs
scripts/instalar_mac.command   doble clic para instalar
scripts/com.ishun05.isaac-espanol.plist   vigilante de launchd
```

## Instalar
1. Conecta el SanDisk y cierra Isaac.
2. Doble clic en `scripts/instalar_mac.command` (o `python3 scripts/isaac_pack.py instalar`).
3. Suscríbete a lo que falte: `docs/suscribir.html` (un clic por mod) o `docs/suscribir_todo.js` (todo de golpe; ver `docs/DECISION_WORKSHOP.md`).
4. Elige packs: doble clic en `scripts/packs_mac.command` o `python3 scripts/isaac_pack.py aplicar clean`.
5. Vigilante automático (opcional, requiere darle Acceso total al disco a `python3`): `docs/TRADUCCION.md`.
6. Abre Isaac **desde Steam** (nunca el `.exe` directo).

## Versiones y código fuente
| Versión | Fecha | Resumen | Código |
|---|---|---|---|
| [`v0.4`](https://github.com/iShun05/Isaac-Modpack-ES/releases/tag/v0.4) **(actual)** | 2026-10-09 | Corrección de seguridad en `sincronizar` (nombres de carpeta) | [Ver código](https://github.com/iShun05/Isaac-Modpack-ES/tree/v0.4) · [ZIP](https://github.com/iShun05/Isaac-Modpack-ES/archive/refs/tags/v0.4.zip) |
| [`v0.3`](https://github.com/iShun05/Isaac-Modpack-ES/releases/tag/v0.3) | 2026-10-09 | Pack de rendimiento, `sincronizar` y 42 mods copiados a mods/ | [Ver código](https://github.com/iShun05/Isaac-Modpack-ES/tree/v0.3) · [ZIP](https://github.com/iShun05/Isaac-Modpack-ES/archive/refs/tags/v0.3.zip) |
| [`v0.2`](https://github.com/iShun05/Isaac-Modpack-ES/releases/tag/v0.2) | 2026-10-09 | Packs con valoración y perfiles, 43 mods recomendados, suscripción en bloque y respaldo | [Ver código](https://github.com/iShun05/Isaac-Modpack-ES/tree/v0.2) · [ZIP](https://github.com/iShun05/Isaac-Modpack-ES/archive/refs/tags/v0.2.zip) |
| [`v0.1`](https://github.com/iShun05/Isaac-Modpack-ES/releases/tag/v0.1) | 2026-10-09 | Catálogo de 70 mods, instalador, español automático y recomendaciones | [Ver código](https://github.com/iShun05/Isaac-Modpack-ES/tree/v0.1) · [ZIP](https://github.com/iShun05/Isaac-Modpack-ES/archive/refs/tags/v0.1.zip) |

Volver a una versión: `git checkout v0.4`.

## Contacto
Instagram: [@_shun._05](https://www.instagram.com/_shun._05/)
