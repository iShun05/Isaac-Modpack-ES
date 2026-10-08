#!/usr/bin/env python3
"""Isaac Pack ES: estado, instalación y español automático de los mods de Isaac (Whisky, botella steam11).

Uso:
  isaac_pack.py estado     compara datos/mods.json con la carpeta mods/ y avisa de novedades
  isaac_pack.py espanol    aplica el español (opciones, EID, mod de traducción); --auto = silencioso
  isaac_pack.py docs       regenera docs/MODS.md y docs/suscribir.html desde mods.json
  isaac_pack.py instalar   estado + descarga REPENTOGON si falta + español + docs
  isaac_pack.py perfil clean|completo   desactiva (disable.it) caprichos, trucos y duplicados / lo reactiva todo
"""
from __future__ import annotations

import argparse
import html
import json
import re
import shutil
import subprocess
import sys
import urllib.request
import zipfile
from datetime import datetime
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
BOTELLA = Path("/Volumes/SanDisk/Juegos/whisky/steam11/drive_c")
JUEGO = BOTELLA / "Program Files (x86)/Steam/steamapps/common/The Binding of Isaac Rebirth"
MODS = JUEGO / "mods"
DATOS_EID = JUEGO / "data/external item descriptions"
OPCIONES = [BOTELLA / f"users/{u}/Documents/My Games/Binding of Isaac Repentance+/options.ini" for u in ("david", "crossover")]
EXTERNOS = Path("/Volumes/SanDisk/Juegos/mods/The_Binding_of_Isaac/externos")
LOCAL = REPO / "mods_locales"
IDIOMA_ES = "2"  # índice de español en options.ini (descubierto en isaac-ng.exe, ver CHANGELOG v0.1)
LOG = REPO / "auto_espanol.log"


def cargar() -> dict:
    return json.loads((REPO / "datos/mods.json").read_text(encoding="utf-8"))


def log(msg: str, auto: bool = False) -> None:
    linea = f"{datetime.now():%F %T} {msg}"
    if auto:
        with LOG.open("a", encoding="utf-8") as f:
            f.write(linea + "\n")
    else:
        print(msg)


def juego_abierto() -> bool:
    return subprocess.run(["pgrep", "-fi", "isaac-ng|steam.exe"], capture_output=True).returncode == 0


def instalados() -> dict[str, Path]:
    """Mods de Workshop instalados: id -> carpeta (el id es el sufijo _<id>)."""
    res = {}
    for d in MODS.iterdir():
        m = re.search(r"_(\d+)$", d.name)
        if d.is_dir() and m:
            res[m.group(1)] = d
    return res


def version_repentogon_instalada() -> str:
    f = JUEGO / "Repentogon/rgon_changelog.txt"
    if not f.exists():
        return ""
    m = re.search(r"v?(\d+\.\d+\.\d+\w*)", f.read_text(encoding="utf-8", errors="ignore")[:200])
    return m.group(1) if m else ""


def ultima_repentogon() -> tuple[str, str]:
    url = "https://api.github.com/repos/TeamREPENTOGON/REPENTOGON/releases/latest"
    with urllib.request.urlopen(url, timeout=20) as r:
        d = json.load(r)
    asset = next(a for a in d["assets"] if a["name"] == "REPENTOGON.zip")
    return d["tag_name"], asset["browser_download_url"]


def estado(_args=None, auto: bool = False) -> int:
    if not MODS.exists():
        log("SanDisk no montado o botella no encontrada: conecta el disco y reintenta.", auto)
        return 1
    man = {m["id"]: m for m in cargar()["mods"]}
    ins = instalados()
    faltan = [m for i, m in man.items() if i not in ins]
    nuevos = sorted(d.name for i, d in ins.items() if i not in man)
    cambiados = []
    for i, d in ins.items():
        if i in man:
            t = (d / "metadata.xml").read_text(encoding="utf-8", errors="ignore")
            v = re.search(r"<version>(.*?)</version>", t)
            if v and v.group(1).strip() != man[i]["version"]:
                cambiados.append(f'{man[i]["nombre"]}: {man[i]["version"]} -> {v.group(1).strip()}')
    quitar = [m["nombre"] for i, m in man.items() if m["veredicto"] == "quitar" and i in ins]
    log(f"Mods registrados: {len(man)} · instalados: {len(ins)}", auto)
    if faltan:
        log("Faltan por suscribir en Steam (abre docs/suscribir.html):", auto)
        for m in faltan:
            log(f'  - {m["nombre"]}  {m["url"]}', auto)
    if nuevos:
        log("MODS NUEVOS sin registrar (añádelos a datos/mods.json con su descripción en español y ejecuta `docs`):", auto)
        for n in nuevos:
            log(f"  - {n}", auto)
    for c in cambiados:
        log(f"Versión nueva: {c}", auto)
    for q in quitar:
        log(f"Recomendado quitar: {q}", auto)
    try:
        etiqueta, _ = ultima_repentogon()
        inst = version_repentogon_instalada()
        if inst and etiqueta.lstrip("v") != inst:
            log(f"REPENTOGON {inst} instalado, hay {etiqueta}: ejecuta `instalar`.", auto)
        else:
            log(f"REPENTOGON al día ({inst or 'no instalado'}).", auto)
    except Exception as e:  # sin red: no es un fallo del pack
        log(f"No se pudo consultar REPENTOGON ({e.__class__.__name__}).", auto)
    return 0


def instalar_mod_local(auto: bool) -> None:
    """Copia mods_locales/* a mods/ si cambian (no son de Workshop: sin sufijo _id)."""
    for origen in LOCAL.iterdir():
        if not origen.is_dir():
            continue
        destino = MODS / origen.name
        if destino.exists() and subprocess.run(["diff", "-rq", str(origen), str(destino)], capture_output=True).returncode == 0:
            continue
        shutil.copytree(origen, destino, dirs_exist_ok=True)
        log(f"Mod local instalado/actualizado: {origen.name}", auto)


def fijar_idioma_opciones(auto: bool) -> None:
    for f in OPCIONES:
        if not f.exists():
            continue
        t = f.read_text(encoding="utf-8")
        nuevo = re.sub(r"(?m)^Language=.*$", f"Language={IDIOMA_ES}", t)
        if nuevo != t:
            shutil.copy2(f, f.with_suffix(".ini.bak_es"))
            f.write_text(nuevo, encoding="utf-8")
            log(f"Language={IDIOMA_ES} en {f.parent.parent.parent.parent.name}", auto)


def fijar_idioma_eid(auto: bool) -> None:
    """EID guarda su ajuste en data/ (no en la carpeta de Workshop, que Steam sobrescribe)."""
    for f in DATOS_EID.glob("save*.dat") if DATOS_EID.exists() else []:
        t = f.read_text(encoding="utf-8", errors="ignore")
        nuevo = re.sub(r'"Language":"[^"]*"', '"Language":"spa"', t)
        nuevo = re.sub(r'"TranslateItemName":\d', '"TranslateItemName":2', nuevo)
        if nuevo != t:
            f.write_text(nuevo, encoding="utf-8")
            log(f"EID en español: {f.name}", auto)


def espanol(args=None, auto: bool = False) -> int:
    auto = auto or bool(args and args.auto)
    if not MODS.exists():
        log("SanDisk no montado: no se hace nada.", auto)
        return 1
    instalar_mod_local(auto)
    if juego_abierto():
        log("Isaac abierto: ajustes de idioma pendientes (se aplicarán al cerrar).", auto)
    else:
        fijar_idioma_opciones(auto)
        fijar_idioma_eid(auto)
    if auto:
        nuevos = estado_nuevos()
        if nuevos:
            log("Mods nuevos sin registrar/traducir: " + ", ".join(nuevos), True)
    else:
        estado()
    return 0


def estado_nuevos() -> list[str]:
    man = {m["id"] for m in cargar()["mods"]}
    return sorted(d.name for i, d in instalados().items() if i not in man)


def instalar(_args=None) -> int:
    rc = estado()
    if rc:
        return rc
    try:
        etiqueta, url = ultima_repentogon()
        if etiqueta.lstrip("v") != version_repentogon_instalada():
            EXTERNOS.mkdir(parents=True, exist_ok=True)
            destino = EXTERNOS / f"REPENTOGON-{etiqueta}.zip"
            if not destino.exists():
                urllib.request.urlretrieve(url, destino)
            with zipfile.ZipFile(destino) as z:
                assert z.testzip() is None
            print(f"REPENTOGON {etiqueta} descargado en {destino}.")
            print("Instálalo con el instalador oficial (repentogon.com/install) o descomprime el zip sobre la carpeta del juego.")
    except Exception as e:
        print(f"REPENTOGON: no se pudo descargar ({e}).")
    espanol(argparse.Namespace(auto=False))
    docs()
    return 0


def docs(_args=None) -> int:  # noqa: ARG001
    d = cargar()
    mods = d["mods"]
    ver = {"esencial": "⭐ Esencial", "recomendado": "✅ Recomendado", "opcional": "◻️ Opcional", "herramienta": "🛠 Herramienta (trucos)", "capricho": "🎭 Capricho", "quitar": "🗑 Quitar"}
    lineas = [
        "# Mods de Isaac: qué hace cada uno y qué conviene",
        "",
        f'_Generado desde `datos/mods.json` · {len(mods)} mods · {d["juego"]} {d["version_juego"]} · REPENTOGON {d["repentogon"]}_',
        "",
    ]
    for clave, titulo in ver.items():
        grupo = [m for m in mods if m["veredicto"] == clave]
        if not grupo:
            continue
        lineas += [f"## {titulo} ({len(grupo)})", "", "| Mod | Categoría | Qué hace | Nota |", "|---|---|---|---|"]
        for m in grupo:
            lineas.append(f'| [{m["nombre"]}]({m["url"]}) | {m["categoria"]} | {m["descripcion"]} | {m["nota"]} |')
        lineas.append("")
    (REPO / "docs/MODS.md").write_text("\n".join(lineas), encoding="utf-8")

    filas = "\n".join(
        f'<li class="{m["veredicto"]}"><a href="{m["url"]}" target="_blank" rel="noopener">{html.escape(m["nombre"])}</a>'
        f'<small>{ver[m["veredicto"]]} · {html.escape(m["categoria"])}</small><p>{html.escape(m["descripcion"])}</p></li>'
        for m in mods
        if m["veredicto"] != "quitar"
    )
    (REPO / "docs/suscribir.html").write_text(
        f"""<!doctype html><html lang="es"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Mods de Isaac</title><style>
:root{{--bg:#000;--fg:#e8e8ee;--mut:#8a8a96;--ac:#a98bff;--ln:#1c1c24}}
body{{background:var(--bg);color:var(--fg);font:16px/1.5 -apple-system,system-ui,sans-serif;margin:0 auto;max-width:760px;padding:24px 16px}}
h1{{font-weight:600;font-size:1.4rem}}ul{{list-style:none;padding:0}}li{{border-top:1px solid var(--ln);padding:12px 0}}
a{{color:var(--ac);text-decoration:none;font-weight:600}}small{{color:var(--mut);margin-left:8px}}p{{margin:4px 0 0;color:var(--mut)}}
li.capricho a,li.herramienta a{{color:var(--fg)}}footer{{margin-top:24px;color:var(--mut);font-size:.85rem}}
</style><h1>Mods de Isaac · pulsa Suscribirse en cada página de Steam</h1><ul>
{filas}
</ul><footer>v{VERSION} · <a href="https://www.instagram.com/_shun._05/">Instagram</a></footer></html>
""",
        encoding="utf-8",
    )
    print("docs/MODS.md y docs/suscribir.html regenerados.")
    return 0


def perfil(args) -> int:
    """clean: desactiva quitar+capricho+herramienta con disable.it (reversible). completo: reactiva todo salvo 'quitar'."""
    if juego_abierto():
        print("Cierra Isaac antes de cambiar de perfil.")
        return 1
    ins = instalados()
    for m in cargar()["mods"]:
        d = ins.get(m["id"])
        if not d:
            continue
        apagar = m["veredicto"] == "quitar" or (args.modo == "clean" and m["veredicto"] in ("capricho", "herramienta"))
        marca = d / "disable.it"
        if apagar and not marca.exists():
            marca.touch()
            print(f'desactivado: {m["nombre"]}')
        elif not apagar and marca.exists():
            marca.unlink()
            print(f'activado: {m["nombre"]}')
    return 0


VERSION = (REPO / "VERSION").read_text().strip() if (REPO / "VERSION").exists() else "0.1"


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)
    sub.add_parser("estado").set_defaults(f=estado)
    e = sub.add_parser("espanol")
    e.add_argument("--auto", action="store_true")
    e.set_defaults(f=espanol)
    sub.add_parser("docs").set_defaults(f=docs)
    sub.add_parser("instalar").set_defaults(f=instalar)
    pf = sub.add_parser("perfil")
    pf.add_argument("modo", choices=["clean", "completo"])
    pf.set_defaults(f=perfil)
    a = p.parse_args()
    return a.f(a)


if __name__ == "__main__":
    sys.exit(main())
