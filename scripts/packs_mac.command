#!/bin/bash
# Doble clic: elige packs con Isaac cerrado y los aplica.
cd "$(dirname "$0")/.." || exit 1
python3 scripts/isaac_pack.py packs
echo
echo "Escribe los packs, presets o perfiles que quieres ACTIVOS (ej: clean   ·   qol interfaz sinergias contenido)."
read -r -p "> " ELECCION
[ -z "$ELECCION" ] && exit 0
# shellcheck disable=SC2086
python3 scripts/isaac_pack.py aplicar $ELECCION
read -r -p "Pulsa Intro para cerrar…"
