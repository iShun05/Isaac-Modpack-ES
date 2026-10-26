# The Binding of Isaac · Pack de mods en español

Catálogo, packs, instalador y traducción automática al español de **Isaac: Repentance+** para macOS con Sikarugir y Windows 10/11. El manifiesto y los perfiles de mods son compartidos entre plataformas; los pasos propios de Mac se limitan al envoltorio de Wine (Sikarugir) y a cómo se abre el juego.

## Descargar e instalar

Descarga el [instalador de Windows 10/11](https://github.com/iShun05/Isaac-Modpack-ES/releases/latest/download/Isaac_Pack_ES_Windows.zip), descomprímelo y ejecuta `Instalar_Windows.bat`. Elige un perfil y pulsa **JUGAR**. Si falta REPENTOGON, el Launcher se abre para completar la instalación; después el instalador abre Steam si hace falta y verifica desde qué carpeta se inició Isaac.

- **Versión actual:** v2.3
- **Plataformas:** macOS + Sikarugir y **Windows 10/11** (instalador en la release). Juego: Repentance+ v1.9.7.17.J460 · REPENTOGON 1.1.3
- **Verificación:** en macOS con Sikarugir, Isaac abre con REPENTOGON 1.1.3 desde `Isaac.app`. En v2.2 el instalador de Windows aplica los mismos parches que el Mac (`datos/parches.json`), probado con PowerShell 7 sobre una carpeta de prueba.

## Funciones principales
- **Manifiesto único** (`datos/mods.json`): catálogo compartido con id de Workshop, pack, descripción en español y veredicto (esencial · recomendado · opcional · herramienta · capricho · quitar).
- **Selector de mods:** presets Clean, Completo y Mínimo (ninguno activa modos que cambien las reglas, como el gacha, el RPG o los trucos: esos se marcan a mano); packs y mods individuales con descripción, estado de REPENTOGON y filtro de **Contenido grande** para probar las expansiones por separado. En Mac, el mismo manifiesto alimenta `aplicar` y el panel del juego.
- **Mods nuevos recomendados:** `docs/RECOMENDADOS.md` con el nombre exacto de Workshop, suscriptores y fecha (incluye Lazy MattPack, objetos de calidad 5).
- **Instalación fácil:** `docs/suscribir.html` abre la página de cada mod para suscribirse con un clic; el instalador prepara el Launcher y guía la primera instalación o reparación de REPENTOGON.
- **Respaldo:** `respaldo` guarda un zip de `mods/` en `mods/The_Binding_of_Isaac/respaldos/` (Documentos/Juegos.nosync).
- **Español automático:** reaplica el idioma del juego y de EID y avisa de mods nuevos sin registrar; a demanda con un comando o solo con el vigilante opcional (ver `docs/TRADUCCION.md`).
- **Mod local «Traducción ES (mods)»:** 1287 descripciones de EID en español para Fiend Folio, Revelations, Andromeda, Job, MattPack, Repentance+, Passive Skill Trees, Icesaac y Agatha, más Eevee: Reunited, Mei y Transformer. Respeta las traducciones que ya traiga cada mod (herramienta en `scripts/traduccion_eid/`).
- **Copias corregidas de mods con errores** (`datos/parches.json`, igual en Mac y Windows): Job 2.5 y Angels Drop Items. El mod de Workshop original no se edita; se desactiva y se usa la copia.

## Tecnología
Python 3 (biblioteca estándar), PowerShell y Windows Forms para el instalador, Lua para el mod local de EID, `launchd` para el vigilante de macOS y Sikarugir (Wine) para jugar en Mac.

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
docs/PANEL.md              panel dentro del juego y cómo se aplica
docs/PUBLICAR.md           pasos para publicar una versión (main, etiqueta, release y ZIP)
docs/suscribir.html        lo que falta por suscribir (generada, fondo negro)
docs/suscribir_todo.js     suscripción en bloque desde steamcommunity.com (generada)
mods_locales/              mods propios (no de Workshop)
Instalar_Windows.bat       instalador de Windows con ventana (windows/instalar_gui.ps1 + windows/lib.ps1)
Instalar_Windows_consola.bat   el mismo instalador en consola
scripts/isaac_pack.py      estado · packs · aplicar · guardar · sincronizar · espanol · docs · respaldo · empaquetar · parches · diagnostico · instalar · jugar
scripts/jugar_mac.command  doble clic para preparar los mods y abrir Isaac con REPENTOGON
scripts/packs_mac.command  doble clic para elegir packs
scripts/instalar_mac.command   doble clic para instalar
scripts/com.ishun05.isaac-espanol.plist   vigilante de launchd
```

## Instalar en Windows 10/11 (otro equipo)
1. Descarga [Isaac_Pack_ES_Windows.zip](https://github.com/iShun05/Isaac-Modpack-ES/releases/latest/download/Isaac_Pack_ES_Windows.zip) y descomprímelo entero.
2. Doble clic en **`Instalar_Windows.bat`**: se abre una ventana (si SmartScreen avisa: *Más información → Ejecutar de todas formas*; si no abre, usa `Instalar_Windows_consola.bat`).
3. Elige Clean, Completo o Mínimo y pulsa **Preparar / actualizar**. Si faltan mods, usa **Suscribirme a lo que falta**.
4. Si REPENTOGON no está instalado, selecciona `isaac-ng.exe` en la configuración inicial del Launcher y elige **Update/Repair Installation → Re-install/Repair REPENTOGON**.
5. Pulsa **▶ JUGAR**; el instalador abre Steam si hace falta y verifica que Isaac se inició desde la carpeta de REPENTOGON.
6. Para elegir mods sueltos, usa el filtro de la lista: **Contenido grande** los separa y la ficha inferior explica cada mod. Prueba una sola expansión grande por vez.

## Instalar en Mac (Sikarugir)
Requisitos: [Sikarugir](https://github.com/Sikarugir-App/Sikarugir) con el envoltorio `/Applications/Sikarugir/Steam Windows 11.app` (motor **WS12WineSikarugir10.0**: con el 11.0 Steam sale en negro) y el acceso `/Applications/Sikarugir/Isaac.app`. Detalles en `docs/REPENTOGON_LANZADOR.md`. Otra ruta de botella: variable `ISAAC_PACK_BOTELLA`.
1. Cierra Isaac (y Steam con **Steam → Salir**).
2. Doble clic en `scripts/instalar_mac.command` (o `python3 scripts/isaac_pack.py instalar`).
3. Suscríbete a lo que falte: `docs/suscribir.html` (un clic por mod) o `docs/suscribir_todo.js` (todo de golpe; ver `docs/DECISION_WORKSHOP.md`).
4. Elige packs: doble clic en `scripts/packs_mac.command` o `python3 scripts/isaac_pack.py aplicar clean`.
5. Vigilante automático (opcional, requiere darle Acceso total al disco a `python3`): `docs/TRADUCCION.md`.
6. Juega: doble clic en `scripts/jugar_mac.command` (`python3 scripts/isaac_pack.py jugar`) o abre **Isaac** en `/Applications/Sikarugir/`. Nunca el `.exe` directo.

## Versiones y código fuente
| Versión | Fecha | Resumen | Código |
|---|---|---|---|
| [`v2.3`](https://github.com/iShun05/Isaac-Modpack-ES/releases/tag/v2.3) **(actual)** | 2026-10-26 | Por defecto, experiencia del juego base: Completo ya no activa caprichos ni trucos, y los modos (gacha, RPG, trucos) se activan a mano | [Ver código](https://github.com/iShun05/Isaac-Modpack-ES/tree/v2.3) · [ZIP](https://github.com/iShun05/Isaac-Modpack-ES/archive/refs/tags/v2.3.zip) |
| [`v2.2`](https://github.com/iShun05/Isaac-Modpack-ES/releases/tag/v2.2) | 2026-10-26 | Corrige Angels Drop Items (error y tirones al disparar), traduce 1287 descripciones de mods y el escáner guarda errores por mod | [Ver código](https://github.com/iShun05/Isaac-Modpack-ES/tree/v2.2) · [ZIP](https://github.com/iShun05/Isaac-Modpack-ES/archive/refs/tags/v2.2.zip) |
| [`v2.1`](https://github.com/iShun05/Isaac-Modpack-ES/releases/tag/v2.1) | 2026-10-21 | Repositorio y mods pasan del SanDisk a Documentos (`Juegos.nosync`); respaldos con rutas relativas | [Ver código](https://github.com/iShun05/Isaac-Modpack-ES/tree/v2.1) · [ZIP](https://github.com/iShun05/Isaac-Modpack-ES/archive/refs/tags/v2.1.zip) |
| [`v2.0`](https://github.com/iShun05/Isaac-Modpack-ES/releases/tag/v2.0) | 2026-10-21 | En Mac pasa de Whisky a Sikarugir y añade `jugar` para abrir Isaac con REPENTOGON | [Ver código](https://github.com/iShun05/Isaac-Modpack-ES/tree/v2.0) · [ZIP](https://github.com/iShun05/Isaac-Modpack-ES/archive/refs/tags/v2.0.zip) |
| [`v1.9`](https://github.com/iShun05/Isaac-Modpack-ES/releases/tag/v1.9) | 2026-10-16 | Guía la reparación de REPENTOGON y separa el contenido grande con fichas por mod | [Ver código](https://github.com/iShun05/Isaac-Modpack-ES/tree/v1.9) · [ZIP](https://github.com/iShun05/Isaac-Modpack-ES/archive/refs/tags/v1.9.zip) |
| [`v1.8`](https://github.com/iShun05/Isaac-Modpack-ES/releases/tag/v1.8) | 2026-10-16 | Arregla la ruta y doble instancia de REPENTOGON en Windows; restaura animaciones y efectos originales por defecto | [Ver código](https://github.com/iShun05/Isaac-Modpack-ES/tree/v1.8) · [ZIP](https://github.com/iShun05/Isaac-Modpack-ES/archive/refs/tags/v1.8.zip) |
| [`v1.7`](https://github.com/iShun05/Isaac-Modpack-ES/releases/tag/v1.7) | 2026-10-10 | Escáner de lag dentro del juego (avisa y señala al mod sospechoso) | [Ver código](https://github.com/iShun05/Isaac-Modpack-ES/tree/v1.7) · [ZIP](https://github.com/iShun05/Isaac-Modpack-ES/archive/refs/tags/v1.7.zip) |
| [`v1.6`](https://github.com/iShun05/Isaac-Modpack-ES/releases/tag/v1.6) | 2026-10-10 | Botón JUGAR en la ventana de Windows (todo en un clic) | [Ver código](https://github.com/iShun05/Isaac-Modpack-ES/tree/v1.6) · [ZIP](https://github.com/iShun05/Isaac-Modpack-ES/archive/refs/tags/v1.6.zip) |
| [`v1.5`](https://github.com/iShun05/Isaac-Modpack-ES/releases/tag/v1.5) | 2026-10-10 | Instalador de Windows con ventana oscura | [Ver código](https://github.com/iShun05/Isaac-Modpack-ES/tree/v1.5) · [ZIP](https://github.com/iShun05/Isaac-Modpack-ES/archive/refs/tags/v1.5.zip) |
| [`v1.4`](https://github.com/iShun05/Isaac-Modpack-ES/releases/tag/v1.4) | 2026-10-10 | Corrige el código de idioma (español = 4) y fija el español en Windows | [Ver código](https://github.com/iShun05/Isaac-Modpack-ES/tree/v1.4) · [ZIP](https://github.com/iShun05/Isaac-Modpack-ES/archive/refs/tags/v1.4.zip) |
| [`v1.3`](https://github.com/iShun05/Isaac-Modpack-ES/releases/tag/v1.3) | 2026-10-10 | Panel dentro del juego (packs, mods y errores) y paridad Mac/Windows | [Ver código](https://github.com/iShun05/Isaac-Modpack-ES/tree/v1.3) · [ZIP](https://github.com/iShun05/Isaac-Modpack-ES/archive/refs/tags/v1.3.zip) |
| [`v1.2`](https://github.com/iShun05/Isaac-Modpack-ES/releases/tag/v1.2) | 2026-10-10 | Copia corregida de Job (sin el error de arranque) y comando `parches` | [Ver código](https://github.com/iShun05/Isaac-Modpack-ES/tree/v1.2) · [ZIP](https://github.com/iShun05/Isaac-Modpack-ES/archive/refs/tags/v1.2.zip) |
| [`v1.1`](https://github.com/iShun05/Isaac-Modpack-ES/releases/tag/v1.1) | 2026-10-10 | REPENTOGON.app no abre un segundo Steam si Isaac ya está abierto | [Ver código](https://github.com/iShun05/Isaac-Modpack-ES/tree/v1.1) · [ZIP](https://github.com/iShun05/Isaac-Modpack-ES/archive/refs/tags/v1.1.zip) |
| [`v1.0`](https://github.com/iShun05/Isaac-Modpack-ES/releases/tag/v1.0) | 2026-10-10 | REPENTOGON.app abre Steam antes (evita el aviso «REPENTOGON REQUIRED») | [Ver código](https://github.com/iShun05/Isaac-Modpack-ES/tree/v1.0) · [ZIP](https://github.com/iShun05/Isaac-Modpack-ES/archive/refs/tags/v1.0.zip) |
| [`v0.9`](https://github.com/iShun05/Isaac-Modpack-ES/releases/tag/v0.9) | 2026-10-10 | Corrige el lag (Eevee fallaba en cada fotograma) y añade `diagnostico` | [Ver código](https://github.com/iShun05/Isaac-Modpack-ES/tree/v0.9) · [ZIP](https://github.com/iShun05/Isaac-Modpack-ES/archive/refs/tags/v0.9.zip) |
| [`v0.8`](https://github.com/iShun05/Isaac-Modpack-ES/releases/tag/v0.8) | 2026-10-09 | Instalador de Windows 10/11 (con ZIP en la release) | [Ver código](https://github.com/iShun05/Isaac-Modpack-ES/tree/v0.8) · [ZIP](https://github.com/iShun05/Isaac-Modpack-ES/archive/refs/tags/v0.8.zip) |
| [`v0.7`](https://github.com/iShun05/Isaac-Modpack-ES/releases/tag/v0.7) | 2026-10-09 | Arreglado el lanzador de REPENTOGON que se cerraba en Wine | [Ver código](https://github.com/iShun05/Isaac-Modpack-ES/tree/v0.7) · [ZIP](https://github.com/iShun05/Isaac-Modpack-ES/archive/refs/tags/v0.7.zip) |
| [`v0.6`](https://github.com/iShun05/Isaac-Modpack-ES/releases/tag/v0.6) | 2026-10-09 | Mods de rendimiento suscritos y copiados; docs al día | [Ver código](https://github.com/iShun05/Isaac-Modpack-ES/tree/v0.6) · [ZIP](https://github.com/iShun05/Isaac-Modpack-ES/archive/refs/tags/v0.6.zip) |
| [`v0.5`](https://github.com/iShun05/Isaac-Modpack-ES/releases/tag/v0.5) | 2026-10-09 | `disable.it` sin seguir enlaces simbólicos | [Ver código](https://github.com/iShun05/Isaac-Modpack-ES/tree/v0.5) · [ZIP](https://github.com/iShun05/Isaac-Modpack-ES/archive/refs/tags/v0.5.zip) |
| [`v0.4`](https://github.com/iShun05/Isaac-Modpack-ES/releases/tag/v0.4) | 2026-10-09 | Corrección de seguridad en `sincronizar` (nombres de carpeta) | [Ver código](https://github.com/iShun05/Isaac-Modpack-ES/tree/v0.4) · [ZIP](https://github.com/iShun05/Isaac-Modpack-ES/archive/refs/tags/v0.4.zip) |
| [`v0.3`](https://github.com/iShun05/Isaac-Modpack-ES/releases/tag/v0.3) | 2026-10-09 | Pack de rendimiento, `sincronizar` y 42 mods copiados a mods/ | [Ver código](https://github.com/iShun05/Isaac-Modpack-ES/tree/v0.3) · [ZIP](https://github.com/iShun05/Isaac-Modpack-ES/archive/refs/tags/v0.3.zip) |
| [`v0.2`](https://github.com/iShun05/Isaac-Modpack-ES/releases/tag/v0.2) | 2026-10-09 | Packs con valoración y perfiles, 43 mods recomendados, suscripción en bloque y respaldo | [Ver código](https://github.com/iShun05/Isaac-Modpack-ES/tree/v0.2) · [ZIP](https://github.com/iShun05/Isaac-Modpack-ES/archive/refs/tags/v0.2.zip) |
| [`v0.1`](https://github.com/iShun05/Isaac-Modpack-ES/releases/tag/v0.1) | 2026-10-09 | Catálogo de 70 mods, instalador, español automático y recomendaciones | [Ver código](https://github.com/iShun05/Isaac-Modpack-ES/tree/v0.1) · [ZIP](https://github.com/iShun05/Isaac-Modpack-ES/archive/refs/tags/v0.1.zip) |

Volver a una versión: `git checkout v2.3`.

## Contacto
Instagram: [@_shun._05](https://www.instagram.com/_shun._05/)
