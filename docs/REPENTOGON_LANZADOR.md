# REPENTOGON en Mac: lanzador y arranque

## Mac con Sikarugir (v2.0, 2026-10-21)
Desde la v2.0 el pack usa en Mac **Sikarugir** (envoltorios de Wine en `/Applications/Sikarugir/`, disco interno). Whisky se retiró el 2026-10-21.

- **Steam:** envoltorio `/Applications/Sikarugir/Steam Windows 11.app`. Solo funciona con un motor **WS12WineSikarugir10.0** (con el 11.0 la interfaz de Steam sale en negro; lo indica el mantenedor en la incidencia #186 de `Sikarugir-App/Sikarugir`). `Program Flags`: `-cef-disable-gpu -cef-disable-gpu-compositing`.
- **Opción de lanzamiento de Isaac en Steam** (en `userdata/<id>/config/localconfig.vdf`, bloque `250900`, con Steam cerrado):
  `"C:\Program Files (x86)\Steam\steamapps\common\The Binding of Isaac Rebirth\REPENTOGONLauncher\REPENTOGONLauncher.exe" --isaac=%command%`
  Así **Jugar** abre Isaac con REPENTOGON (método oficial de REPENTOGON para Wine).
- **`/Applications/Sikarugir/Isaac.app`:** envoltorio ligero (7 MB) cuyos `Contents/Frameworks` y `SharedSupport/{prefix,wine,renderer}` son enlaces simbólicos al de Steam, con `Program Flags` `-cef-disable-gpu -cef-disable-gpu-compositing -applaunch 250900`. Abre Steam y lanza Isaac sin pasar por la interfaz. Es lo que usa `python3 scripts/isaac_pack.py jugar` y `scripts/jugar_mac.command`.
- **Comprobar que cargó REPENTOGON:** la ventana dice `Repentance+ v1.9.7.12 (REPENTOGON 1.1.3)` y el proceso es `Repentogon\isaac-ng.exe`.
- **Cerrar:** la X de Steam solo lo oculta; usa **Steam → Salir** antes de tocar la botella (slot 3, `localconfig.vdf`).
- **No lances Wine desde fuera del envoltorio** (terminal o AppleScript con el mismo entorno): sale sin ejecutar nada.

---

## Historial (Whisky, retirado el 2026-10-21)

### El lanzador que se cerraba (2026-10-09)

**Síntoma:** al abrir `REPENTOGON.app` (o el acceso anclado en Whisky) salía «Program Error: REPENTOGONLauncher.exe has encountered a serious problem» y Wine Debugger. El juego quedaba parado o arrancaba sin REPENTOGON, y Lazy MattPack decía «REPENTOGON REQUIRED».

**Causa (comprobada):** el paquete de datos del lanzador (`REPENTOGONLauncher/launcher-data.bin` y la carpeta `launcher-data/`, que contiene `REPENTOGONLauncherApp.dll`) era de la versión 0.3.12-beta, mientras que `REPENTOGONLauncher.exe` era el oficial 0.4.8-beta. El ejecutable nuevo con la parte de ventana vieja fallaba justo después de enganchar REPENTOGON al juego. Se reproducía con y sin `--stealth-mode` y con un Wine limpio (sin variables de Whisky), así que no dependía de Whisky ni de los mods.

**Arreglo:** copia previa en `Juegos/mods/The_Binding_of_Isaac/respaldos/REPENTOGONLauncher_antes_0.4.8_2026-10-09/`; se puso el `launcher-data.bin` del release oficial v0.4.8-beta (hash de la release verificado) y se borró la carpeta `launcher-data/` para que el ejecutable la regenere. El `REPENTOGONLauncher.exe` ya era idéntico al oficial.

**Resultado:** `RemoteThread completed with exit code 0`, el juego arranca con REPENTOGON (`Binding of Isaac: Repentance+ v1.9.7.12.J273` en el log, que es la copia compatible que prepara el lanzador) y carga los 116 mods.

**Cómo abrir Isaac:** con Steam abierto, desde el acceso **REPENTOGON** (anclado en Whisky o `/Applications/REPENTOGON.app`). Abrirlo desde Steam lo arranca sin REPENTOGON.

**Si vuelve a pasar:** `python3 scripts/isaac_pack.py estado` no lo detecta; comprueba que `REPENTOGONLauncher/launcher-data/launcher.txt` y la versión del `.exe` (primera línea de `launcher.log`) coinciden.

### Segundo fallo: «REPENTOGON REQUIRED» aunque el lanzador funcione (2026-10-10)
**Síntoma:** Isaac abre y Lazy MattPack dice «REPENTOGON REQUIRED». La barra del juego pone `v1.9.7.17` a secas.
**Causa (comprobada en `launcher.log`):** el lanzador arrancó, pero `isaac-ng.exe` salió al instante con código `0x35` porque **Steam estaba cerrado**. Isaac se relanza entonces a través de Steam, y Steam abre la versión normal, sin REPENTOGON.
**Arreglo:** `/Applications/REPENTOGON.app` ahora abre Steam antes (en silencio), espera a que esté listo y después lanza el lanzador. Copia del script anterior en `Juegos/mods/The_Binding_of_Isaac/respaldos/`.
**Si usas el acceso anclado dentro de Whisky:** abre Steam primero y espera a que cargue.

### Error de ruta al pulsar JUGAR desde Whisky o Windows (2026-10-16)

**Síntoma:** REPENTOGON informa que no encuentra una instalación válida de Isaac. Si se vuelve a pulsar el acceso mientras el Launcher sigue abierto, también puede avisar que ya hay otra instancia.

**Causa observada en Whisky:** el perfil de la tarjeta pasaba `--isaac="C:\\Program Files ..."`; Whisky/Wine entregaba una ruta deformada (`C:\\Programm Files ...isaac-ng.exe"`). La instalación y el ejecutable sí estaban presentes.

**Corrección en Isaac Pack ES v1.8:** el botón JUGAR guarda la ruta verificada en `Documents\\My Games\\repentogon_launcher.ini` y arranca el Launcher con `--stealth-mode`, sin pasar `--isaac` con espacios. También evita iniciar otra instancia del mismo Launcher. El instalador de Windows incluye este flujo. En Whisky se corrigieron los perfiles de la botella a `--stealth-mode`; ese ajuste local no forma parte del paquete Windows.

**Verificación disponible:** en la botella se validaron los ejecutables vanilla y REPENTOGON y el registro confirmó la creación y reanudación del proceso. El flujo nativo de Windows no se ha probado en un PC Windows.

### Tercer fallo: «segundo Steam» al pulsar el acceso varias veces (2026-10-10)
**Síntoma:** cada vez que se pulsa `REPENTOGON.app` aparece otro Steam en el Dock y el juego sale sin REPENTOGON.
**Causa (comprobada en `launcher.log` y en la lista de procesos):** había un Isaac normal abierto (lanzado por Steam tras el primer `0x35`). Con Isaac ya en marcha, Steam rechaza otro: el juego sale con `0x35`, se relanza `steam.exe steam://run/250900`, y eso es el «segundo Steam». Además, tras cerrar a la fuerza quedaron `steam.exe` colgados que Steam seguía contando como juego en marcha.
**Arreglo:** `REPENTOGON.app` no hace nada si Isaac ya está abierto (avisa). Probado desde un estado limpio (se paró todo con `kill -9`): un solo Steam (`-silent`), el lanzador engancha, y el juego queda corriendo como `Repentogon\isaac-ng.exe` (v1.9.7.12.J273), sin `0x35`.
**Regla:** una sola vez por sesión. Si ves el Isaac normal («REPENTOGON REQUIRED»), ciérralo del todo (Cmd+Q) antes de volver a pulsar el acceso. Si Isaac no abre ni así, cierra Steam y vuelve a probar.
