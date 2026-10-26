# Publicar una versión nueva

Norma general en `agent-rules` → *Versiones y GitHub*. Aquí van solo los pasos propios de este repositorio.

Una versión **no está terminada** hasta que `main`, la etiqueta, la release y el ZIP de Windows existen. Mientras el trabajo siga en una rama, en GitHub se sigue viendo la versión anterior.

## 1. En el commit de la versión
- `VERSION` con el número nuevo.
- `CHANGELOG.md`: entrada `## vX.X — AAAA-MM-DD` con las secciones que apliquen (Añadido · Mejorado · Cambiado · Corregido · Eliminado · Archivos y pruebas). «Archivos y pruebas» dice qué se probó en Mac y en Windows.
- `README.md`: línea «Versión actual», fila nueva (la primera) en «Versiones y código fuente» marcada **(actual)**, la marca quitada de la anterior, y `git checkout vX.X` actualizado.
- Si cambian funciones, mods o requisitos: también *Funciones principales*, *Tecnología* y *Estructura*.

## 2. A `main`
Desde una sesión en la nube: pull request y merge, sin esperar a que lo pidan.

## 3. Etiqueta, release y ZIP (en el Mac)
`docs/MODS.md`, `docs/PACKS.md`, `docs/RECOMENDADOS.md` y `docs/suscribir.html` se generan con los mods realmente instalados, así que el empaquetado se hace en el Mac; desde la nube saldrían vacíos.

```bash
cd ~/Documents/Juegos.nosync/mods/Isaac_Pack_ES
git checkout main && git pull
python3 scripts/isaac_pack.py empaquetar     # regenera docs/ y crea dist/Isaac_Pack_ES_Windows_vX.X.zip
git add -A && git commit -m "docs: regenerados para vX.X" && git push origin main

TOKEN=$(cat ~/.config/github_token)
VERSION="vX.X"
git tag -a "$VERSION" -m "$VERSION" && git push "https://$TOKEN@github.com/iShun05/Isaac-Modpack-ES.git" "$VERSION"

# Release con las notas del CHANGELOG
NOTAS=$(awk -v v="## $VERSION " 'index($0,v)==1{f=1;next} /^## /{f=0} f' CHANGELOG.md)
python3 -c 'import json,sys; print(json.dumps({"tag_name":sys.argv[1],"name":sys.argv[1]+" — "+sys.argv[2],"body":sys.argv[3],"draft":False,"prerelease":False,"make_latest":"true"}))' \
  "$VERSION" "<resumen>" "$NOTAS" > /tmp/release.json
curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.github+json" \
  https://api.github.com/repos/iShun05/Isaac-Modpack-ES/releases -d @/tmp/release.json | grep -m1 '"id"'
```

Sube **dos adjuntos** a esa release (el mismo archivo con dos nombres):
- `Isaac_Pack_ES_Windows.zip` — nombre fijo, para que el enlace de descarga del README apunte siempre a la última versión.
- `Isaac_Pack_ES_Windows_vX.X.zip` — con versión, para conservar cada una.

## 4. Comprobar
- `https://github.com/iShun05/Isaac-Modpack-ES/releases/latest/download/Isaac_Pack_ES_Windows.zip` descarga.
- El ZIP trae `Instalar_Windows.bat`, `windows/`, `datos/mods.json`, `datos/parches.json` y `mods_locales/`.
- La fila del README enlaza a la release y al código de esa etiqueta.
