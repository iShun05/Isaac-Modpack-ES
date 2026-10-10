# Isaac en español y cómo se mantiene solo

## Qué cubre cada capa
| Capa | Cómo está en español | Se mantiene sola |
|---|---|---|
| Juego base (Repentance+ v1.9.7.17.J460) | Traducción oficial (`packed/repentance_es.a`), activada con `Language=4` en `options.ini` | Al ejecutar `espanol` (o con el vigilante opcional) se reaplica si Steam o el juego lo vuelven a inglés |
| Objetos, baratijas, cartas, píldoras (EID) | EID trae `spa`; se fija `Language: spa` y nombres traducidos en `data/external item descriptions/save*.dat` (no en la carpeta de Workshop, que Steam pisa) | Igual que arriba |
| Mods con textos propios solo en inglés | Mod local **Traducción ES (mods)** (`mods_locales/traduccion_es_mods`): Eevee: Reunited, Icesaac, Mei, Transformer | Detecta mods nuevos y los apunta en `auto_espanol.log`; la traducción de sus textos se añade a la tabla del mod |
| Descripciones de Workshop (`metadata.xml`) | No se tocan (Steam las sobrescribe y el juego no las muestra); su resumen en español está en `docs/MODS.md` | — |

## Qué pasa cuando se añade un mod nuevo
1. (Con el vigilante activado) Un `LaunchAgent` (`com.ishun05.isaac-espanol`) vigila la carpeta `mods/` y `appmanifest_250900.acf`, y cada hora ejecuta `isaac_pack.py espanol --auto`.
2. El script reaplica el idioma, actualiza el mod de traducción y compara con `datos/mods.json`.
3. Si hay mods sin registrar, los apunta en `auto_espanol.log` («Mods nuevos sin registrar/traducir»).
4. Pídele a Claude «traduce los mods nuevos de Isaac»: añade su ficha a `mods.json`, sus nombres a la tabla del mod local y regenera `docs/`.

> La traducción de **textos nuevos** no puede hacerla un script sin un traductor: el script detecta y avisa, y la traducción la hace Claude con ese aviso.

## Instalar/quitar el vigilante (NO instalado: necesita un permiso tuyo)
macOS bloquea que un proceso de `launchd` lea el SanDisk (`Operation not permitted`, comprobado el 2026-10-09). Para activarlo, una sola vez: *Ajustes del Sistema → Privacidad y seguridad → Acceso total al disco* → añade `/usr/bin/python3` (o `python3` de Xcode) y luego ejecuta los comandos de abajo. Mientras tanto, el mismo trabajo se hace a demanda con `scripts/instalar_mac.command` o `python3 scripts/isaac_pack.py espanol`.
```bash
cp scripts/com.ishun05.isaac-espanol.plist ~/Library/LaunchAgents/
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.ishun05.isaac-espanol.plist
# quitar:
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.ishun05.isaac-espanol.plist && rm ~/Library/LaunchAgents/com.ishun05.isaac-espanol.plist
```

## Idioma del juego: cómo se fija de verdad (corregido 2026-10-10)
- El código de español en `options.ini` es **`Language=4`** (SPANISH, según la documentación oficial de REPENTOGON). En v0.1–v1.3 se escribía `2`, que es **japonés**: era un error mío, copiado de un registro antiguo sin comprobar.
- El juego vuelve a escribir el idioma según el de **Steam**: en Steam, clic derecho en Isaac → Propiedades → Idioma → Español. Es lo que de verdad lo deja en español en Windows.
- Con REPENTOGON también se puede elegir en su lanzador: «Change Game Options».

## Dudas honestas
- **Comprobado el 2026-10-09:** tras jugar, el juego volvió a escribir `Language=0` en `options.ini`. El valor 2 no se mantiene. El lanzador de REPENTOGON tiene su propio ajuste de idioma («Change Game Options», novedad de REPENTOGON 1.1.2e): úsalo para fijar el español y dime si el juego sale en español.
- `Language=4` es el índice de español descubierto en `isaac-ng.exe` (registro 2026-09-28). El juego lo había vuelto a `0` tras las últimas sesiones; si tras aplicarlo sigue en inglés, el culpable es el idioma que informa Steam y habrá que revisarlo.
