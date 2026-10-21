#!/bin/bash
# Devuelve el slot 3 de Isaac a la plantilla Dead God (INFINITY %). Solo toca el slot 3.
# Requisitos: Steam e Isaac de Sikarugir CERRADOS (Steam → Salir). Hay copia previa en respaldos/saves_2026-10-09/.
set -euo pipefail
if pgrep -f 'steam.exe|isaac-ng' >/dev/null; then echo "Cierra Steam (Steam → Salir) e Isaac de Sikarugir primero."; exit 1; fi
B="/Applications/Sikarugir/Steam Windows 11.app/Contents/SharedSupport/prefix/drive_c"
U="$B/Program Files (x86)/Steam/userdata/1053668664/250900"; R="$U/remote"
D="$B/users/david/Documents/My Games/Binding of Isaac Repentance+"; TPL="$D/rep+persistentgamedata1.dat"
[ "$(md5 -q "$TPL")" = "7605ab6c23a73237eb41866e1339cf6f" ] || { echo "La plantilla no es la esperada: no toco nada."; exit 1; }
cp -p "$TPL" "$R/rep+persistentgamedata3.dat"
cp "$TPL" "$D/rep+persistentgamedata3.dat"
cp "$TPL" "$D/save_backups/$(date +%Y%m%d).rep+persistentgamedata3.dat"
SHA=$(shasum -a 1 "$R/rep+persistentgamedata3.dat" | cut -d' ' -f1); SZ=$(stat -f%z "$R/rep+persistentgamedata3.dat"); NOW=$(date +%s)
python3 - "$U/remotecache.vdf" "$SHA" "$SZ" "$NOW" <<'E'
import sys, re
p, sha, sz, now = sys.argv[1:]
t = open(p, encoding="utf-8").read()
m = re.search(r'("rep\+persistentgamedata3\.dat"\s*\{)(.*?)(\})', t, re.S)
b = m.group(2)
b = re.sub(r'("size"\s*")\d+(")', r'\g<1>%s\2' % sz, b)
b = re.sub(r'("sha"\s*")[0-9a-f]+(")', r'\g<1>%s\2' % sha, b)
for k in ("localtime", "time", "remotetime"):
    b = re.sub(r'("%s"\s*")\d+(")' % k, r'\g<1>%s\2' % now, b)
open(p, "w", encoding="utf-8").write(t[:m.start(2)] + b + t[m.end(2):])
E
echo "Slot 3 restaurado: $(stat -f%z "$R/rep+persistentgamedata3.dat") bytes. Abre Steam y comprueba File 3."
