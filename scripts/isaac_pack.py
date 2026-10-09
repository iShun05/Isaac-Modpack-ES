#!/usr/bin/env python3
"""Isaac Pack ES: packs de mods, instalación, español automático y documentación (Whisky, botella steam11).

Uso:
  isaac_pack.py estado                    qué hay instalado, qué falta por pack y novedades
  isaac_pack.py packs                     lista los packs
  isaac_pack.py aplicar qol interfaz ...  deja activos SOLO esos packs (+ base); acepta presets y perfiles guardados
  isaac_pack.py guardar NOMBRE qol ...    guarda una combinación como perfil
  isaac_pack.py sincronizar               copia a mods/ lo ya descargado por Steam (el lanzador REPENTOGON tiene SkipUpdateMods=1)
  isaac_pack.py espanol [--auto]          aplica el español (opciones, EID, mod de traducción)
  isaac_pack.py docs                      regenera docs/ (MODS, RECOMENDADOS, PACKS, suscribir.html, suscribir_todo.js)
  isaac_pack.py respaldo                  copia comprimida de la carpeta mods/ en el SanDisk
  isaac_pack.py instalar                  estado + REPENTOGON si falta + español + docs
Presets: minimo · clean · completo
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
WORKSHOP = BOTELLA / "Program Files (x86)/Steam/steamapps/workshop/content/250900"
DATOS_EID = JUEGO / "data/external item descriptions"
OPCIONES = [BOTELLA / f"users/{u}/Documents/My Games/Binding of Isaac Repentance+/options.ini" for u in ("david", "crossover")]
EXTERNOS = Path("/Volumes/SanDisk/Juegos/mods/The_Binding_of_Isaac/externos")
RESPALDOS = Path("/Volumes/SanDisk/Juegos/mods/The_Binding_of_Isaac/respaldos")
LOCAL = REPO / "mods_locales"
PERFILES = REPO / "datos/perfiles.json"
NOMBRE_SEGURO = re.compile(r"[\w .\-()\[\]'`!+&]+")  # sin barras ni rutas
IDIOMA_ES = "2"  # índice de español en options.ini (descubierto en isaac-ng.exe, ver CHANGELOG v0.1)
LOG = REPO / "auto_espanol.log"
VERSION = (REPO / "VERSION").read_text().strip() if (REPO / "VERSION").exists() else "0.2"

# id -> (nombre, qué trae). «base» siempre va activo.
PACKS = {
    "base": ("Base", "Librerías y menú de ajustes que usan los demás mods"),
    "qol": ("Calidad de vida", "Arreglos y comodidades que no cambian el equilibrio"),
    "interfaz": ("Interfaz e información", "HUD, estadísticas, enciclopedia y recordatorios"),
    "rendimiento": ("Rendimiento y estabilidad", "Menos tirones y menos cierres con muchos objetos y mods"),
    "sinergias": ("Sinergias y jugabilidad", "Sinergias nuevas, objetos extra y pequeños cambios de reglas"),
    "contenido": ("Contenido grande", "Expansiones con muchos objetos, enemigos y mecánicas"),
    "personajes": ("Personajes", "Personajes jugables nuevos"),
    "visual": ("Visual y audio", "Sprites, animaciones, música y doblaje"),
    "capricho": ("Caprichos", "Memes, cambios de aspecto y modos de caos"),
    "trucos": ("Trucos y herramientas", "Menús de trucos y atajos para probar cosas"),
}
PRESETS = {
    "minimo": ["base", "qol", "interfaz", "rendimiento"],
    "clean": ["base", "qol", "interfaz", "rendimiento", "sinergias", "visual"],
    "completo": list(PACKS),
}
VEREDICTOS = {"esencial": "⭐ Esencial", "recomendado": "✅ Recomendado", "opcional": "◻️ Opcional", "herramienta": "🛠 Herramienta", "capricho": "🎭 Capricho", "quitar": "🗑 Quitar"}


def cargar() -> dict:
    return json.loads((REPO / "datos/mods.json").read_text(encoding="utf-8"))


def log(msg: str, auto: bool = False) -> None:
    if auto:
        with LOG.open("a", encoding="utf-8") as f:
            f.write(f"{datetime.now():%F %T} {msg}\n")
    else:
        print(msg)


def juego_abierto() -> bool:
    return subprocess.run(["pgrep", "-fi", "isaac-ng"], capture_output=True).returncode == 0


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


# ---------------------------------------------------------------- estado
def estado(_args=None, auto: bool = False) -> int:
    if not MODS.exists():
        log("SanDisk no montado o botella no encontrada: conecta el disco y reintenta.", auto)
        return 1
    mods = cargar()["mods"]
    man = {m["id"]: m for m in mods}
    ins = instalados()
    log(f"Catálogo: {len(man)} mods · instalados: {len(ins)}", auto)
    for pid, (nombre, _) in PACKS.items():
        grupo = [m for m in mods if m["pack"] == pid]
        puestos = [m for m in grupo if m["id"] in ins]
        activos = [m for m in puestos if not (ins[m["id"]] / "disable.it").exists()]
        log(f"  {nombre}: {len(puestos)}/{len(grupo)} instalados · {len(activos)} activos", auto)
    nuevos = sorted(d.name for i, d in ins.items() if i not in man)
    if nuevos:
        log("MODS NUEVOS sin registrar (añádelos a datos/mods.json con su descripción en español y ejecuta `docs`):", auto)
        for n in nuevos:
            log(f"  - {n}", auto)
    for i, d in ins.items():
        if i in man and man[i]["version"]:
            t = (d / "metadata.xml").read_text(encoding="utf-8", errors="ignore")
            v = re.search(r"<version>(.*?)</version>", t)
            if v and v.group(1).strip() != man[i]["version"]:
                log(f'Versión nueva: {man[i]["nombre"]}: {man[i]["version"]} -> {v.group(1).strip()}', auto)
    por_instalar = [m for m in mods if m["id"] not in ins and m["pack"] != "descartado" and not m.get("no_suscribir")]
    if por_instalar:
        log(f"Por suscribir en Steam: {len(por_instalar)} (docs/suscribir.html o docs/suscribir_todo.js)", auto)
    for m in mods:
        if m["pack"] == "descartado" and m["id"] in ins:
            log(f'Recomendado quitar: {m["nombre"]}', auto)
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


# ---------------------------------------------------------------- packs
def valorar(seleccion: list[dict], hay_rgon: bool) -> list[tuple[str, str]]:
    """Valoración orientativa (criterio propio, sin probar en el juego): rojo / naranja / verde."""
    r: list[tuple[str, str]] = []
    grandes = [m for m in seleccion if m.get("gran")]
    if any("Epiphany" in m["nombre"] for m in grandes) and len(grandes) > 1:
        r.append(("rojo", "Epiphany reescribe medio juego: úsalo solo, sin otros mods de contenido grande."))
    if len(grandes) >= 3:
        r.append(("rojo", f"{len(grandes)} expansiones grandes a la vez ({', '.join(m['nombre'] for m in grandes)}): choques casi seguros."))
    elif len(grandes) == 2:
        r.append(("naranja", f"Dos expansiones grandes juntas ({grandes[0]['nombre']} + {grandes[1]['nombre']}): puede diluirse o chocar."))
    chars = [m for m in seleccion if m["pack"] == "personajes"]
    if len(chars) >= 4:
        r.append(("naranja", "Varios personajes y skins tocan players.xml: pueden pisarse."))
    if not hay_rgon and any(m.get("rgon") == "requiere" for m in seleccion):
        r.append(("rojo", "Hay mods que requieren REPENTOGON y no está instalado."))
    if len(seleccion) > 60:
        r.append(("naranja", f"{len(seleccion)} mods activos: el arranque será lento."))
    if not r:
        r.append(("verde", "Combinación sin avisos conocidos."))
    return r


def perfiles() -> dict:
    return json.loads(PERFILES.read_text(encoding="utf-8")) if PERFILES.exists() else {}


def resolver(nombres: list[str]) -> list[str]:
    out: list[str] = []
    perf = perfiles()
    for n in nombres:
        grupo = PRESETS.get(n) or perf.get(n) or ([n] if n in PACKS else None)
        if grupo is None:
            raise SystemExit(f"«{n}» no es un pack, preset ni perfil. Packs: {', '.join(PACKS)} · presets: {', '.join(PRESETS)} · perfiles: {', '.join(perf) or '—'}")
        out += [g for g in grupo if g not in out]
    return ["base"] + [p for p in out if p != "base"]


def listar_packs(_args=None) -> int:
    ins = instalados()
    mods = cargar()["mods"]
    for pid, (nombre, desc) in PACKS.items():
        g = [m for m in mods if m["pack"] == pid]
        print(f"{pid:10} {nombre} — {desc} ({sum(m['id'] in ins for m in g)}/{len(g)} instalados)")
    print("Presets:", " · ".join(f"{k} = {' '.join(v)}" for k, v in PRESETS.items()))
    if perfiles():
        print("Perfiles:", " · ".join(f"{k} = {' '.join(v)}" for k, v in perfiles().items()))
    return 0


def aplicar(args) -> int:
    if juego_abierto():
        print("Cierra Isaac antes de cambiar de pack.")
        return 1
    elegidos = resolver(args.packs)
    mods = cargar()["mods"]
    ins = instalados()
    seleccion = [m for m in mods if m["pack"] in elegidos]
    faltan = [m for m in seleccion if m["id"] not in ins]
    for m in mods:
        d = ins.get(m["id"])
        if not d:
            continue
        encender = m["pack"] in elegidos
        marca = d / "disable.it"
        if encender and marca.exists():
            marca.unlink()
            print(f'activado: {m["nombre"]}')
        elif not encender and not marca.exists():
            marca.touch()
            print(f'desactivado: {m["nombre"]}')
    print(f"\nPacks activos: {', '.join(PACKS[p][0] for p in elegidos)}")
    activos = [m for m in seleccion if m["id"] in ins]
    for color, txt in valorar(activos, bool(version_repentogon_instalada())):
        print({"verde": "🟢", "naranja": "🟠", "rojo": "🔴"}[color], txt)
    if faltan:
        print(f"\nFaltan por suscribir ({len(faltan)}): " + ", ".join(m["nombre"] for m in faltan))
    p = perfiles()
    p["ultimo"] = elegidos
    PERFILES.write_text(json.dumps(p, ensure_ascii=False, indent=1), encoding="utf-8")
    print("\nAbre Isaac desde Steam. Cambia de pack siempre con el juego cerrado.")
    return 0


def guardar(args) -> int:
    if args.nombre in PRESETS or args.nombre in PACKS:
        raise SystemExit("Ese nombre ya es un pack o preset: elige otro.")
    p = perfiles()
    p[args.nombre] = [x for x in resolver(args.packs) if x != "base"]
    PERFILES.write_text(json.dumps(p, ensure_ascii=False, indent=1), encoding="utf-8")
    print(f"Perfil «{args.nombre}» guardado: {' '.join(p[args.nombre])}")
    return 0


def sincronizar(_args=None) -> int:
    """Copia a mods/ los mods que Steam ya descargó en workshop/content (el juego lo haría al arrancar, pero
    el lanzador de REPENTOGON salta ese paso con SkipUpdateMods=1). Carpeta destino = <directory>_<id>, como el juego.
    Contenido grande, caprichos y trucos nuevos entran DESACTIVADOS (disable.it) para no mezclar expansiones sin querer."""
    if juego_abierto():
        print("Cierra Isaac antes de sincronizar.")
        return 1
    man = {m["id"]: m for m in cargar()["mods"]}
    ins = instalados()
    nuevos = 0
    for d in sorted(WORKSHOP.iterdir()) if WORKSHOP.exists() else []:
        meta = d / "metadata.xml"
        if d.name in ins or not meta.exists():
            continue
        t = meta.read_text(encoding="utf-8", errors="ignore")
        directorio = re.search(r"<directory>(.*?)</directory>", t, re.S)
        if not directorio:
            continue
        nombre = directorio.group(1).strip()
        # <directory> viene de un mod ajeno: solo se acepta un nombre de carpeta simple, dentro de mods/
        if not NOMBRE_SEGURO.fullmatch(nombre) or nombre in (".", ".."):
            print(f"Nombre de carpeta sospechoso en {d.name}, se omite")
            continue
        destino = (MODS / f"{nombre}_{d.name}").resolve()
        if destino.parent != MODS.resolve() or destino.exists():
            continue
        shutil.copytree(d, destino, symlinks=True)
        m = man.get(d.name)
        apagado = m is None or m.get("apagado") or m["pack"] in ("contenido", "capricho", "trucos", "descartado")
        if apagado:
            (destino / "disable.it").touch()
        nuevos += 1
        print(f'{"copiado (desactivado)" if apagado else "copiado y activo"}: {m["nombre"] if m else destino.name}')
    print(f"{nuevos} mods copiados a mods/." if nuevos else "Nada nuevo que copiar.")
    return 0


# ---------------------------------------------------------------- español
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
        man = {m["id"] for m in cargar()["mods"]}
        nuevos = sorted(d.name for i, d in instalados().items() if i not in man)
        if nuevos:
            log("Mods nuevos sin registrar/traducir: " + ", ".join(nuevos), True)
    else:
        estado()
    return 0


# ---------------------------------------------------------------- respaldo / instalar
def respaldo(_args=None) -> int:
    RESPALDOS.mkdir(parents=True, exist_ok=True)
    destino = RESPALDOS / f"mods_{datetime.now():%Y-%m-%d}"
    shutil.make_archive(str(destino), "zip", MODS)
    print(f"Respaldo creado: {destino}.zip")
    return 0


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
    sincronizar()
    espanol(argparse.Namespace(auto=False))
    docs()
    return 0


# ---------------------------------------------------------------- documentación
def _tabla(grupo: list[dict], extra: bool) -> list[str]:
    cab = "| Mod | Qué hace | Nota |" if not extra else "| Mod (nombre en Workshop) | Qué hace | Nota | Suscriptores · actualizado |"
    lineas = [cab, "|---|---|---|---|" if extra else "|---|---|---|"]
    for m in grupo:
        rg = {"requiere": " ⚙ REPENTOGON", "recomendado": " ⚙ mejor con REPENTOGON"}.get(m.get("rgon", "no"), "")
        base = f'| [{m["nombre"]}]({m["url"]}) | {m["descripcion"]}{rg} | {m["nota"]} |'
        lineas.append(base + (f' {m.get("suscriptores", 0):,} · {m.get("actualizado", "")} |'.replace(",", ".") if extra else ""))
    return lineas


def docs(_args=None) -> int:
    d = cargar()
    mods = d["mods"]
    ins = instalados() if MODS.exists() else {}
    puestos = [m for m in mods if m["id"] in ins]
    nuevos = [m for m in mods if m["id"] not in ins and m["pack"] != "descartado" and not m.get("no_suscribir")]
    cab = f'_Generado desde `datos/mods.json` · {d["juego"]} {d["version_juego"]} · REPENTOGON {d["repentogon"]} · v{VERSION}_'

    # MODS.md: instalados, por veredicto
    L = ["# Mods instalados: qué hace cada uno y qué conviene", "", cab, ""]
    for clave, titulo in VEREDICTOS.items():
        g = [m for m in puestos if m["veredicto"] == clave]
        if g:
            L += [f"## {titulo} ({len(g)})", ""] + _tabla(g, False) + [""]
    (REPO / "docs/MODS.md").write_text("\n".join(L), encoding="utf-8")

    # RECOMENDADOS.md: por instalar, por pack
    L = ["# Mods recomendados que aún no tienes", "", cab, "",
         "Datos (suscriptores y fecha) leídos de la API de Steam el 2026-10-09. Todos son de Workshop: se suscriben con un clic y Steam los mantiene al día.",
         "⚙ = usa REPENTOGON (ya lo tienes instalado). «Tier 5» = objetos de **calidad 5**: **Lazy MattPack** (ya suscrito) trae versiones muy mejoradas de objetos que ya existían (Tech 5090, Knife Bender, Multi Mush, Comically Large Spoon Bender...). [Q5] Golden Brimstone es un modo caos aparte.", ""]
    for pid, (nombre, desc) in PACKS.items():
        g = [m for m in nuevos if m["pack"] == pid]
        if g:
            L += [f"## {nombre} ({len(g)})", f"_{desc}_", ""] + _tabla(g, True) + [""]
    (REPO / "docs/RECOMENDADOS.md").write_text("\n".join(L), encoding="utf-8")

    # PACKS.md
    L = ["# Packs de mods", "", cab, "",
         "Un pack = un tema. `aplicar` deja activos solo los packs que elijas (más **Base**) y desactiva el resto con `disable.it` (reversible). Cambia de pack con el juego cerrado.", "",
         "| Pack | Qué trae | Mods (instalados / total) |", "|---|---|---|"]
    for pid, (nombre, desc) in PACKS.items():
        g = [m for m in mods if m["pack"] == pid]
        L.append(f"| **{nombre}** (`{pid}`) | {desc} | {sum(m['id'] in ins for m in g)} / {len(g)} |")
    L += ["", "## Presets", ""] + [f"- `{k}`: {', '.join(PACKS[p][0] for p in v)}" for k, v in PRESETS.items()]
    L += ["", "## Valoración de combinaciones (orientativa, sin probar en el juego)",
          "- 🔴 Epiphany con cualquier otra expansión grande · 3 o más expansiones grandes · mods que requieren REPENTOGON sin REPENTOGON.",
          "- 🟠 Dos expansiones grandes · 4 o más personajes · más de 60 mods activos.",
          "- 🟢 Cualquier otra combinación.", "",
          "Expansiones grandes: " + ", ".join(m["nombre"] for m in mods if m.get("gran")) + ".", "",
          "## Qué rinde juntar", "",
          "| Combinación | Veredicto |", "|---|---|",
          "| Base + Calidad de vida + Interfaz | 🟢 Se complementan y apenas cambian el juego: úsalo siempre. |",
          "| + Sinergias | 🟢 Cada mod toca un objeto distinto; los de Lazy MattPack añaden objetos nuevos. |",
          "| + un solo Contenido grande | 🟢 Recomendado: **Repentance Plus!** (estilo vanilla) o **Reshaken**. |",
          "| + dos Contenidos grandes | 🟠 Mejor probarlos por separado. |",
          "| Epiphany + lo demás | 🔴 Solo, sin otras expansiones. |",
          "| + Caprichos / Trucos | 🟢 Aparte: no los mezcles con partidas serias. |", ""]
    (REPO / "docs/PACKS.md").write_text("\n".join(L), encoding="utf-8")

    # suscribir.html (solo lo que falta, por pack) y suscribir_todo.js
    secciones = []
    for pid, (nombre, desc) in PACKS.items():
        g = [m for m in nuevos if m["pack"] == pid]
        if not g:
            continue
        filas = "".join(
            f'<li><a href="{m["url"]}" target="_blank" rel="noopener">{html.escape(m["nombre"])}</a>'
            f'<small>{VEREDICTOS[m["veredicto"]]}{" · ⚙ REPENTOGON" if m.get("rgon") == "requiere" else ""}</small>'
            f'<p>{html.escape(m["descripcion"])}</p></li>'
            for m in g
        )
        secciones.append(f"<h2>{html.escape(nombre)} <small>{len(g)}</small></h2><ul>{filas}</ul>")
    cuerpo = "\n".join(secciones) or "<p>No falta ningún mod por suscribir.</p>"
    (REPO / "docs/suscribir.html").write_text(
        f"""<!doctype html><html lang="es"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Mods de Isaac por instalar</title><style>
:root{{--bg:#000;--fg:#e8e8ee;--mut:#8a8a96;--ac:#a98bff;--ln:#1c1c24}}
body{{background:var(--bg);color:var(--fg);font:16px/1.5 -apple-system,system-ui,sans-serif;margin:0 auto;max-width:760px;padding:24px 16px}}
h1{{font-weight:600;font-size:1.4rem}}h2{{font-size:1.1rem;margin-top:28px}}ul{{list-style:none;padding:0}}li{{border-top:1px solid var(--ln);padding:12px 0}}
a{{color:var(--ac);text-decoration:none;font-weight:600}}small{{color:var(--mut);margin-left:8px;font-weight:400}}p{{margin:4px 0 0;color:var(--mut)}}
footer{{margin-top:24px;color:var(--mut);font-size:.85rem}}
</style><h1>Mods de Isaac por instalar · pulsa Suscribirse en cada página</h1>
<p>¿Muchos? Usa <code>docs/suscribir_todo.js</code> (instrucciones en <code>docs/DECISION_WORKSHOP.md</code>).</p>
{cuerpo}
<footer>v{VERSION} · <a href="https://www.instagram.com/_shun._05/">Instagram</a></footer></html>
""",
        encoding="utf-8",
    )
    ids = json.dumps([m["id"] for m in nuevos])
    (REPO / "docs/suscribir_todo.js").write_text(
        f"""// Suscribe tu cuenta a los {len(nuevos)} mods recomendados que faltan.
// Uso: abre steamcommunity.com con tu sesión iniciada, abre la consola del navegador y pega este archivo.
// Hace una petición POST a /sharedfiles/subscribe por mod (la misma que el botón «Suscribirse»). No toca tu contraseña.
// Para suscribirte solo a un pack, borra de la lista los ids que no quieras (nombres en docs/RECOMENDADOS.md).
(async () => {{
  const ids = {ids};
  for (const id of ids) {{
    const r = await fetch('/sharedfiles/subscribe', {{
      method: 'POST',
      headers: {{ 'Content-Type': 'application/x-www-form-urlencoded' }},
      body: new URLSearchParams({{ id, appid: '250900', sessionid: g_sessionID }}),
    }});
    console.log(id, r.status);
    await new Promise((ok) => setTimeout(ok, 800));
  }}
  console.log('Hecho. Steam descargará los mods cuando esté abierto.');
}})();
""",
        encoding="utf-8",
    )
    print(f"docs regenerados · por suscribir: {len(nuevos)}")
    return 0


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)
    sub.add_parser("estado").set_defaults(f=estado)
    sub.add_parser("packs").set_defaults(f=listar_packs)
    a = sub.add_parser("aplicar")
    a.add_argument("packs", nargs="+")
    a.set_defaults(f=aplicar)
    g = sub.add_parser("guardar")
    g.add_argument("nombre")
    g.add_argument("packs", nargs="+")
    g.set_defaults(f=guardar)
    e = sub.add_parser("espanol")
    e.add_argument("--auto", action="store_true")
    e.set_defaults(f=espanol)
    sub.add_parser("docs").set_defaults(f=docs)
    sub.add_parser("respaldo").set_defaults(f=respaldo)
    sub.add_parser("sincronizar").set_defaults(f=sincronizar)
    sub.add_parser("instalar").set_defaults(f=instalar)
    args = p.parse_args()
    return args.f(args)


if __name__ == "__main__":
    sys.exit(main())
