# REPENTOGON en Whisky: el lanzador que se cerraba (2026-10-09)

**Síntoma:** al abrir `REPENTOGON.app` (o el acceso anclado en Whisky) salía «Program Error: REPENTOGONLauncher.exe has encountered a serious problem» y Wine Debugger. El juego quedaba parado o arrancaba sin REPENTOGON, y Lazy MattPack decía «REPENTOGON REQUIRED».

**Causa (comprobada):** el paquete de datos del lanzador (`REPENTOGONLauncher/launcher-data.bin` y la carpeta `launcher-data/`, que contiene `REPENTOGONLauncherApp.dll`) era de la versión 0.3.12-beta, mientras que `REPENTOGONLauncher.exe` era el oficial 0.4.8-beta. El ejecutable nuevo con la parte de ventana vieja fallaba justo después de enganchar REPENTOGON al juego. Se reproducía con y sin `--stealth-mode` y con un Wine limpio (sin variables de Whisky), así que no dependía de Whisky ni de los mods.

**Arreglo:** copia previa en `Juegos/mods/The_Binding_of_Isaac/respaldos/REPENTOGONLauncher_antes_0.4.8_2026-10-09/`; se puso el `launcher-data.bin` del release oficial v0.4.8-beta (hash de la release verificado) y se borró la carpeta `launcher-data/` para que el ejecutable la regenere. El `REPENTOGONLauncher.exe` ya era idéntico al oficial.

**Resultado:** `RemoteThread completed with exit code 0`, el juego arranca con REPENTOGON (`Binding of Isaac: Repentance+ v1.9.7.12.J273` en el log, que es la copia compatible que prepara el lanzador) y carga los 116 mods.

**Cómo abrir Isaac:** con Steam abierto, desde el acceso **REPENTOGON** (anclado en Whisky o `/Applications/REPENTOGON.app`). Abrirlo desde Steam lo arranca sin REPENTOGON.

**Si vuelve a pasar:** `python3 scripts/isaac_pack.py estado` no lo detecta; comprueba que `REPENTOGONLauncher/launcher-data/launcher.txt` y la versión del `.exe` (primera línea de `launcher.log`) coinciden.
