# The Binding of Isaac · Pack de mods en español

Catálogo, instalador y traducción automática al español de los **70 mods de Isaac: Repentance+** que uso en macOS (Whisky, botella `steam11`), con una ficha en español de cada mod y una recomendación de cuáles dejar activos para una experiencia limpia.

- **Versión actual:** v0.1
- **Plataforma:** macOS + Whisky (Steam de Windows). Juego: Repentance+ v1.9.7.17.J460 · REPENTOGON 1.1.3
- **Estado:** pendiente de pruebas manuales (idioma `Language=2` y mod de traducción)

## Funciones principales
- **Manifiesto único** (`datos/mods.json`): los 70 mods con id de Workshop, versión, categoría, descripción en español y veredicto (esencial · recomendado · opcional · herramienta · capricho · quitar).
- **Instalación fácil:** `docs/suscribir.html` abre la página de cada mod para suscribirse con un clic; los mods que no son de Workshop (REPENTOGON, el mod local de traducción) se descargan/copian solos.
- **Perfil clean/completo:** `perfil clean` desactiva trucos, caprichos y duplicados con `disable.it`; `perfil completo` lo revierte.
- **Español automático:** reaplica el idioma del juego y de EID y avisa de mods nuevos sin registrar; a demanda con un comando o solo con el vigilante opcional (ver `docs/TRADUCCION.md`).
- **Mod local «Traducción ES (mods)»:** nombres y textos en español de Eevee: Reunited, Icesaac, Mei y Transformer.

## Tecnología
Python 3 (solo biblioteca estándar), Lua (mod local para EID), `launchd` para el vigilante.

## Estructura
```
datos/mods.json            manifiesto de mods
docs/MODS.md               ficha en español de cada mod (generada)
docs/RECOMENDACIONES.md    qué quitar, qué dejar y qué añadir
docs/WEBS.md               webs de mods y herramientas
docs/TRADUCCION.md         cómo funciona el español automático
docs/suscribir.html        lista de suscripción (generada, fondo negro)
mods_locales/              mods propios (no de Workshop)
scripts/isaac_pack.py      estado · instalar · espanol · docs · perfil
scripts/instalar_mac.command   doble clic para instalar
scripts/com.ishun05.isaac-espanol.plist   vigilante de launchd
```

## Instalar
1. Conecta el SanDisk y cierra Isaac.
2. Doble clic en `scripts/instalar_mac.command` (o `python3 scripts/isaac_pack.py instalar`).
3. En la página que se abre, pulsa *Suscribirse* en los mods que falten.
4. Opcional: `python3 scripts/isaac_pack.py perfil clean`.
5. Vigilante automático (opcional, requiere darle Acceso total al disco a `python3`): `docs/TRADUCCION.md`.
6. Abre Isaac **desde Steam** (nunca el `.exe` directo).

## Versiones y código fuente
| Versión | Fecha | Resumen | Código |
|---|---|---|---|
| [`v0.1`](https://github.com/iShun05/Isaac-Modpack-ES/releases/tag/v0.1) **(actual)** | 2026-10-09 | Catálogo de 70 mods, instalador, español automático y recomendaciones | [Ver código](https://github.com/iShun05/Isaac-Modpack-ES/tree/v0.1) · [ZIP](https://github.com/iShun05/Isaac-Modpack-ES/archive/refs/tags/v0.1.zip) |

Volver a una versión: `git checkout v0.1`.

## Contacto
Instagram: [@_shun._05](https://www.instagram.com/_shun._05/)
