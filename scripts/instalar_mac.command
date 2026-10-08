#!/bin/bash
# Doble clic: comprueba mods, descarga lo que falte, aplica el español y abre la lista de suscripciones.
cd "$(dirname "$0")/.." || exit 1
python3 scripts/isaac_pack.py instalar
open docs/suscribir.html
read -r -p "Pulsa Intro para cerrar…"
