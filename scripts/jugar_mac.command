#!/bin/bash
# Doble clic: prepara los mods (nuevos, parches y lo elegido en el panel) y abre Isaac con REPENTOGON en Sikarugir.
cd "$(dirname "$0")/.." || exit 1
python3 scripts/isaac_pack.py jugar
sleep 3
