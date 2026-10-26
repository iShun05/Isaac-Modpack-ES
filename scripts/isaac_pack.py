#!/usr/bin/env python3
"""Isaac Pack ES: packs de mods, instalación, español automático y documentación (macOS: envoltorio «Steam Windows 11» de Sikarugir).

Uso:
  isaac_pack.py estado                    qué hay instalado, qué falta por pack y novedades
  isaac_pack.py packs                     lista los packs
  isaac_pack.py aplicar qol interfaz ...  deja activos SOLO esos packs (+ base); acepta presets y perfiles guardados
  isaac_pack.py guardar NOMBRE qol ...    guarda una combinación como perfil
  isaac_pack.py sincronizar               copia a mods/ lo ya descargado por Steam (el lanzador REPENTOGON tiene SkipUpdateMods=1)
  isaac_pack.py espanol [--auto]          aplica el español (opciones, EID, mod de traducción)
  isaac_pack.py docs                      regenera docs/ (MODS, RECOMENDADOS, PACKS, suscribir.html, suscribir_todo.js)
  isaac_pack.py respaldo                  copia comprimida de la carpeta mods/ en The_Binding_of_Isaac/respaldos
  isaac_pack.py escaner on|off            activa/desactiva el escáner por mod (mide ms por fotograma de cada mod; se ve en el panel)
  isaac_pack.py preparar                  lo que se hace antes de abrir Isaac: copia mods nuevos, parches, aplica el panel y lo refresca
  isaac_pack.py parches                   crea copias corregidas de mods ajenos (Job, Angels Drop Items) sin tocar los originales
  isaac_pack.py diagnostico               lee log.txt del juego: mods que fallan en bucle, avisos repetidos y memoria Lua
  isaac_pack.py empaquetar                zip con el instalador de Windows 10/11 (dist/)
  isaac_pack.py instalar                  estado + REPENTOGON si falta + español + docs
  isaac_pack.py jugar                     prepara los mods y abre Isaac con REPENTOGON (Isaac.app de Sikarugir)
Presets: minimo · clean · completo
"""
from __future__ import annotations

import argparse
import os
import hashlib
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
# Botella de Wine con Steam: el envoltorio de Sikarugir en el disco interno (se puede cambiar con ISAAC_PACK_BOTELLA)
ENVOLTORIO = Path("/Applications/Sikarugir/Steam Windows 11.app")
LANZADOR_ISAAC = Path("/Applications/Sikarugir/Isaac.app")  # abre Steam y lanza Isaac con REPENTOGON (-applaunch 250900)
BOTELLA = Path(os.environ.get("ISAAC_PACK_BOTELLA", ENVOLTORIO / "Contents/SharedSupport/prefix/drive_c"))
JUEGO = BOTELLA / "Program Files (x86)/Steam/steamapps/common/The Binding of Isaac Rebirth"
MODS = JUEGO / "mods"
WORKSHOP = BOTELLA / "Program Files (x86)/Steam/steamapps/workshop/content/250900"
DATOS_EID = JUEGO / "data/external item descriptions"
OPCIONES = [BOTELLA / f"users/{u}/Documents/My Games/Binding of Isaac Repentance+/options.ini" for u in ("david",)]
# Carpeta hermana del repositorio dentro de mods/ (Documentos/Juegos.nosync/mods/The_Binding_of_Isaac)
CARPETA_ISAAC = REPO.parent / "The_Binding_of_Isaac"
EXTERNOS = CARPETA_ISAAC / "externos"
RESPALDOS = CARPETA_ISAAC / "respaldos"
LOCAL = REPO / "mods_locales"
PERFILES = REPO / "datos/perfiles.json"
NOMBRE_SEGURO = re.compile(r"[\w .\-()\[\]'`!+&]+")  # sin barras ni rutas
IDIOMA_ES = "4"  # SPANISH = 4 según la documentación de REPENTOGON (enums/Language.md); el 2 es japonés
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
    # «Completo» = juego base + expansiones; los caprichos y los trucos se activan a mano (cambian la experiencia).
    "completo": ["base", "qol", "interfaz", "rendimiento", "sinergias", "contenido", "personajes", "visual"],
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


def marcar(d: Path, apagar: bool) -> bool:
    """Crea/quita d/disable.it sin seguir enlaces simbólicos (un mod ajeno podría traer uno). Devuelve si cambió algo."""
    marca = d / "disable.it"
    if marca.is_symlink():
        marca.unlink()
    if apagar and not marca.exists():
        marca.touch()
        return True
    if not apagar and marca.exists():
        marca.unlink()
        return True
    return False


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
        log(f"No encuentro Isaac en la botella de Sikarugir ({BOTELLA}).", auto)
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


def _decidir(m: dict, elegidos: list[str], on: set[str], off: set[str]) -> bool:
    """¿Debe estar activo este mod? Una orden suelta (panel del juego) gana al pack; «apagado» = se activa a mano."""
    if m["id"] in on:
        return True
    if m["id"] in off:
        return False
    return m["pack"] in elegidos and not m.get("apagado")


def _aplicar(elegidos: list[str], on: set[str] | None = None, off: set[str] | None = None) -> int:
    on, off = on or set(), off or set()
    mods = cargar()["mods"]
    ins = instalados()
    seleccion = [m for m in mods if m["pack"] in elegidos]
    faltan = [m for m in seleccion if m["id"] not in ins]
    corregidos = {c["id"] for c in cargar_copias()}
    for m in mods:
        d = ins.get(m["id"])
        if not d or m["id"] in corregidos:
            continue  # un original con copia corregida queda apagado: lo gestiona parches()
        encender = _decidir(m, elegidos, on, off)
        if marcar(d, not encender):
            print(f'{"activado" if encender else "desactivado"}: {m["nombre"]}')
    print(f"\nPacks activos: {', '.join(PACKS[p][0] for p in elegidos)}")
    activos = [m for m in mods if m["id"] in ins and _decidir(m, elegidos, on, off)]
    for color, txt in valorar(activos, bool(version_repentogon_instalada())):
        print({"verde": "🟢", "naranja": "🟠", "rojo": "🔴"}[color], txt)
    if faltan:
        print(f"\nFaltan por suscribir ({len(faltan)}): " + ", ".join(m["nombre"] for m in faltan))
    p = perfiles()
    p["ultimo"] = elegidos
    PERFILES.write_text(json.dumps(p, ensure_ascii=False, indent=1), encoding="utf-8")
    return 0


def aplicar(args) -> int:
    if juego_abierto():
        print("Cierra Isaac antes de cambiar de pack.")
        return 1
    rc = _aplicar(resolver(args.packs))
    print("\nAbre Isaac con REPENTOGON. Cambia de pack siempre con el juego cerrado.")
    return rc


# ---------------------------------------------------------------- panel dentro del juego
PANEL = "isaac_pack_panel"
ESCANER = "!!!isaac_pack_scanner"


def lua_str(s: str) -> str:
    return '"' + str(s).replace("\\", "\\\\").replace('"', '\\"').replace("\r", "").replace("\n", "\\n") + '"'


def leer_pendiente() -> dict | None:
    """Selección guardada desde el panel del juego (data/isaac_pack_panel/save*.dat), si es más nueva que la última aplicada."""
    carpeta = JUEGO / "data" / PANEL
    if not carpeta.exists():
        return None
    ficheros = sorted(carpeta.glob("save*.dat"), key=lambda f: f.stat().st_mtime, reverse=True)
    if not ficheros:
        return None
    marca = REPO / "datos" / "panel_aplicado.txt"
    ultimo = float(marca.read_text()) if marca.exists() else 0.0
    f = ficheros[0]
    if f.stat().st_mtime <= ultimo:
        return None
    try:
        d = json.loads(f.read_text(encoding="utf-8"))
    except ValueError:
        return None
    d["_mtime"] = f.stat().st_mtime
    return d


def errores_ultima_sesion() -> list[dict]:
    """Errores Lua del log de la sesión anterior, agrupados por mod: nº de veces, primer mensaje y primera pila."""
    log_txt = log_juego_actual()
    if not log_txt.exists():
        return []
    lineas = log_txt.read_text(encoding="utf-8", errors="ignore").splitlines()
    res: dict[str, dict] = {}
    for i, l in enumerate(lineas):
        m = re.search(r'Error in "([^"]+)" call from "([^"]+)": (.*)', l)
        if not m:
            continue
        e = res.setdefault(m.group(2), {"mod": m.group(2), "n": 0, "msg": f'{m.group(1)}: {m.group(3)}'[:400], "pila": ""})
        e["n"] += 1
        if e["n"] == 1:
            pila = []
            for sig in lineas[i + 1 : i + 14]:
                if not sig.strip() or sig.startswith("[INFO]"):
                    break
                pila.append(sig.strip()[:160])
            e["pila"] = "\n".join(pila)
    return sorted(res.values(), key=lambda e: -e["n"])


def log_juego_actual() -> Path:
    """Devuelve el log de Repentance+ actualizado más recientemente entre los perfiles Wine."""
    logs = [opcion.parent / "log.txt" for opcion in OPCIONES]
    existentes = [log for log in logs if log.is_file()]
    return max(existentes, key=lambda log: log.stat().st_mtime) if existentes else logs[0]


def escribir_panel() -> None:
    """Genera panel_datos.lua dentro de mods/isaac_pack_panel con el estado real (packs, mods, errores)."""
    destino = MODS / PANEL
    if not destino.exists():
        return
    d = cargar()
    ins = instalados()
    orden = list(PACKS)
    mods = sorted(d["mods"], key=lambda m: (orden.index(m["pack"]) if m["pack"] in orden else 99, m["nombre"].lower()))
    activo = {m["id"]: (m["id"] in ins and not (ins[m["id"]] / "disable.it").exists()) for m in mods}
    L = [f'return {{ version = {lua_str(VERSION)}, generado = {lua_str(datetime.now().strftime("%F %H:%M"))},', "packs = {"]
    seleccion = []
    for pid, (nombre, desc) in PACKS.items():
        if pid == "base":
            continue
        g = [m for m in mods if m["pack"] == pid and m["id"] in ins]
        encendibles = [m for m in g if not m.get("apagado")]
        act = sum(activo[m["id"]] for m in g)
        total = len([m for m in mods if m["pack"] == pid])
        if encendibles and all(activo[m["id"]] for m in encendibles):
            seleccion.append(pid)
        L.append(f'{{ k = {lua_str(pid)}, n = {lua_str(nombre)}, d = {lua_str(desc)}, activos = {act}, total = {total} }},')
    L.append("},")
    L.append("presets = { " + ", ".join(f'{k} = {{ ' + ", ".join(lua_str(x) for x in v if x != "base") + " }" for k, v in PRESETS.items()) + " },")
    L.append("seleccion = { " + ", ".join(f"{k} = true" for k in seleccion) + " },")
    L.append("mods = {")
    for m in mods:
        if m["pack"] == "descartado":
            continue
        pn = PACKS.get(m["pack"], (m["pack"],))[0]
        L.append(
            f'{{ id = {lua_str(m["id"])}, n = {lua_str(m["nombre"])}, p = {lua_str(m["pack"])}, pn = {lua_str(pn)}, v = {lua_str(m["veredicto"])}, '
            f'i = {"true" if m["id"] in ins else "false"}, a = {"true" if activo[m["id"]] else "false"}, ap = {"true" if m.get("apagado") else "false"}, '
            f'rg = {lua_str(m.get("rgon", "no"))}, d = {lua_str(m["descripcion"][:200])} }},'
        )
    L.append("},")
    L.append("errores = {")
    for e in errores_ultima_sesion()[:30]:
        L.append(f'{{ mod = {lua_str(e["mod"])}, n = {e["n"]}, msg = {lua_str(e["msg"])}, pila = {lua_str(e["pila"])} }},')
    L.append("}, }")
    salida = destino / "panel_datos.lua"
    if salida.is_symlink():
        salida.unlink()  # nunca escribir a través de un enlace simbólico
    salida.write_text("\n".join(L) + "\n", encoding="utf-8")


def escribir_config_escaner(activo: bool) -> None:
    """El escáner por mod solo mide si su config.lua dice activo = true (mide cada callback: pequeño coste)."""
    destino = MODS / ESCANER
    if not destino.exists():
        return
    salida = destino / "config.lua"
    if salida.is_symlink():
        salida.unlink()
    salida.write_text(f"return {{ activo = {'true' if activo else 'false'} }}\n", encoding="utf-8")


def escaner(args) -> int:
    escribir_config_escaner(args.estado == "on")
    print(f"Escáner por mod {'ACTIVADO' if args.estado == 'on' else 'desactivado'}: se aplica al abrir Isaac. Resultados: panel (F9) → Escáner y `diagnostico`.")
    return 0


def preparar(_args=None) -> int:
    """Lo que hay que hacer justo antes de abrir Isaac: copiar mods nuevos, parches, aplicar lo elegido en el panel y refrescar el panel."""
    if not MODS.exists():
        print(f"No encuentro Isaac en la botella de Sikarugir ({BOTELLA}).")
        return 1
    if juego_abierto():
        print("Isaac está abierto: no se prepara nada.")
        return 1
    sincronizar()
    parches()
    pend = leer_pendiente()
    if pend:
        paquetes = [p for p in pend.get("packs", []) if p in PACKS]
        elegidos = ["base"] + [p for p in paquetes if p != "base"]
        print("Aplicando la selección guardada en el panel del juego…")
        _aplicar(elegidos, set(map(str, pend.get("on") or [])), set(map(str, pend.get("off") or [])))
        (REPO / "datos" / "panel_aplicado.txt").write_text(str(pend["_mtime"]))
    instalar_mod_local(False)
    if pend and "scanner" in pend:
        escribir_config_escaner(bool(pend["scanner"]))
    escribir_panel()
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
        marcar(destino, apagado)
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
        nuevo = re.sub(r"(?m)^Language=[^\r\n]*", f"Language={IDIOMA_ES}", t)
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
        log(f"No encuentro Isaac en la botella de Sikarugir ({BOTELLA}): no se hace nada.", auto)
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
    L += ["", "## Efectos y animaciones originales", "",
          "`Faster Animations` y `NGR remastered` (antes catalogado como Potato Cup; mismo ID de Workshop) quedan apagados por defecto al aplicar cualquier pack para conservar el ritmo, las explosiones y los fuegos originales. Se pueden activar manualmente desde el panel o la selección de mods.",
          "", "## Valoración de combinaciones (orientativa, sin probar en el juego)",
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


# Copias corregidas de mods de Workshop (datos/parches.json, compartido con Windows): nunca se edita el original,
# que Steam sobrescribe al actualizar. Hoy: Job 2.5 (require al iniciar) y Angels Drop Items (main.lua:325 con salas nuevas).
def cargar_copias() -> list[dict]:
    return json.loads((REPO / "datos/parches.json").read_text(encoding="utf-8"))["copias"]


def copia_corregida(cfg: dict) -> int:
    orig = instalados().get(cfg["id"])
    if not orig:
        return 0
    main = (orig / "main.lua").read_text(encoding="utf-8")
    faltan = [r["viejo"] for r in cfg["obligatorio"] if r["viejo"] not in main]
    if faltan:
        print(f"{cfg['nombre']}: el main.lua ya no contiene la línea esperada; revisa el parche a mano.")
        return 1
    destino = MODS / cfg["carpeta"]
    huella = hashlib.sha256((main + (orig / "metadata.xml").read_text(encoding="utf-8")
                             + json.dumps(cfg, sort_keys=True)).encode()).hexdigest()
    if (destino / ".origen_sha").exists() and (destino / ".origen_sha").read_text() == huella:
        marcar(orig, True)
        marcar(destino, False)
        return 0  # ya está al día con la versión actual del original
    if destino.exists():
        shutil.rmtree(destino)
    shutil.copytree(orig, destino, symlinks=True, ignore=shutil.ignore_patterns("disable.it"))
    (destino / ".origen_sha").write_text(huella)
    for r in cfg["obligatorio"] + cfg["opcional"]:
        main = main.replace(r["viejo"], r["nuevo"])
    (destino / "main.lua").write_text(main, encoding="utf-8")
    meta = (destino / "metadata.xml").read_text(encoding="utf-8")
    meta = re.sub(r"<name>.*?</name>", f"<name>{cfg['nombre']}</name>", meta, count=1)
    meta = re.sub(r"<directory>.*?</directory>", f"<directory>{cfg['carpeta']}</directory>", meta, count=1)
    meta = re.sub(r"\s*<id>.*?</id>", "", meta, count=1)
    meta = meta.replace("<visibility>Public</visibility>", "<visibility>Private</visibility>")
    meta = re.sub(r"<description>", f"<description>[{cfg['nota']}] ", meta, count=1)
    (destino / "metadata.xml").write_text(meta, encoding="utf-8")
    marcar(orig, True)  # el original se apaga: los dos a la vez registrarían lo mismo dos veces
    marcar(destino, False)
    datos = JUEGO / "data"
    if (datos / cfg["datos"]).exists() and not (datos / cfg["carpeta"]).exists():
        shutil.copytree(datos / cfg["datos"], datos / cfg["carpeta"], symlinks=True)  # conserva ajustes y progreso
    print(f"Creado mods/{cfg['carpeta']} y desactivado el original. Los cambios se ven al reiniciar Isaac.")
    return 0


def parches(_args=None) -> int:
    """Crea o actualiza las copias corregidas de datos/parches.json (Job 2.5 y Angels Drop Items)."""
    return max([copia_corregida(c) for c in cargar_copias()] or [0])


def diagnostico(_args=None) -> int:
    """Busca la causa de lag en el log del juego: errores Lua repetidos por mod y avisos que se repiten miles de veces."""
    log_txt = log_juego_actual()
    if not log_txt.exists():
        print("No encuentro log.txt: abre el juego una vez.")
        return 1
    texto = log_txt.read_text(encoding="utf-8", errors="ignore")
    lineas = texto.splitlines()
    print(f"Log analizado: {log_txt} ({len(lineas)} líneas, {log_txt.stat().st_size // 1024} KB)")
    por_mod: dict[str, int] = {}
    for m in re.finditer(r'Error in "([^"]+)" call from "([^"]+)"', texto):
        por_mod[m.group(2)] = por_mod.get(m.group(2), 0) + 1
    # formato de REPENTOGON: "MC_PRE_ENTITY_SPAWN" from "angel-drop-items" failed: ... (xN)
    for m in re.finditer(r'"(MC_\w+)" from "([^"]+)" failed[^\n]*?(?:\(x(\d+)\))?$', texto, re.M):
        por_mod[m.group(2)] = por_mod.get(m.group(2), 0) + int(m.group(3) or 1)
    graves = {k: v for k, v in por_mod.items() if v >= 50}
    for mod, n in sorted(graves.items(), key=lambda kv: -kv[1]):
        print(f"🔴 «{mod}» aparece en {n} errores del registro; revisa el mod y su compatibilidad.")
    for mod, n in por_mod.items():
        if mod not in graves:
            print(f"🟡 «{mod}» falló {n} vez/veces (no es en bucle).")
    normal = re.compile(r"\d+(\.\d+)?")
    cuenta: dict[str, int] = {}
    for l in lineas:
        if "[warn]" in l or "Warning" in l:
            k = normal.sub("N", l)[:120]
            cuenta[k] = cuenta.get(k, 0) + 1
    for k, n in sorted(cuenta.items(), key=lambda kv: -kv[1])[:3]:
        if n >= 500:
            print(f"🟠 {n} avisos acumulados en el log: {k}")
    medidas = re.findall(r"\[PackScanner\] mod=(.+?) avg_ms=([\d.]+) max_ms=([\d.]+) calls=(\d+) frames=(\d+)", texto)
    if medidas:
        ultimo_frames = medidas[-1][4]
        bloque = {m[0]: m for m in medidas if m[4] == ultimo_frames}
        print(f"Escáner por mod (último volcado, {ultimo_frames} fotogramas):")
        for nombre, avg, mx, calls, _ in sorted(bloque.values(), key=lambda m: -float(m[1]))[:8]:
            marca = "🔴" if float(avg) > 5 else "🟠" if float(avg) > 2 else "  "
            print(f"  {marca} {nombre}: {float(avg):.2f} ms/fotograma (máx. {float(mx):.1f} ms, {calls} llamadas)")
    elif log_txt.parent.exists():
        print("Escáner por mod sin datos en este log (actívalo con `isaac_pack.py escaner on` o en el panel).")
    informe = JUEGO / "data" / ESCANER / "save1.dat"
    if informe.is_file():
        try:
            rep = json.loads(informe.read_text(encoding="utf-8", errors="ignore"))
        except ValueError:
            rep = {}
        for e in rep.get("errores", [])[:10]:
            print(f"🔴 Escáner: «{e.get('mod')}» falló {e.get('n')} vez/veces en {e.get('cb')}: {e.get('msg')}")
    mem = [int(x) for x in re.findall(r"Lua mem usage: (\d+) KB", texto)]
    if mem:
        print(f"Memoria Lua: de {mem[0]} KB a {mem[-1]} KB (máx {max(mem)} KB)")
    if not graves:
        print("Sin mods con 50 o más errores en este registro.")
    return 0


def empaquetar(_args=None) -> int:
    """Crea dist/Isaac_Pack_ES_Windows_v<ver>.zip: instalador .bat + .ps1, manifiesto, mod local y lista de suscripción."""
    docs()
    dist = REPO / "dist"
    dist.mkdir(exist_ok=True)
    destino = dist / f"Isaac_Pack_ES_Windows_v{VERSION}.zip"
    leeme = (
        "ISAAC PACK ES - instalador para Windows 10/11\r\n\r\n"
        "1. Descomprime este zip ENTERO (no lo abras desde dentro del zip).\r\n"
        "2. Doble clic en Instalar_Windows.bat (abre una ventana). Si SmartScreen avisa: Mas informacion > Ejecutar de todas formas. Si la ventana no abre, usa Instalar_Windows_consola.bat.\r\n"
        "3. Elige tu pack y sigue los pasos. Se puede ejecutar varias veces.\r\n"
        "4. Pulsa JUGAR en la ventana: abre Steam si hace falta, aplica la ruta de Isaac y lo lanza con REPENTOGON.\r\n"
        "5. Dentro del juego: pulsa ~ y abre Packs ES (o F9) para cambiar los packs y los mods.\r\n\r\n"
        "Contacto: https://www.instagram.com/_shun._05/\r\n"
    )
    with zipfile.ZipFile(destino, "w", zipfile.ZIP_DEFLATED) as z:
        z.write(REPO / "Instalar_Windows.bat", "Instalar_Windows.bat")
        z.write(REPO / "Aplicar_seleccion.bat", "Aplicar_seleccion.bat")
        for nombre in ("lib.ps1", "instalar_gui.ps1", "instalar_windows.ps1"):
            z.write(REPO / "windows" / nombre, f"windows/{nombre}")
        z.write(REPO / "VERSION", "VERSION")
        z.write(REPO / "Instalar_Windows_consola.bat", "Instalar_Windows_consola.bat")
        z.write(REPO / "datos/mods.json", "datos/mods.json")
        z.write(REPO / "datos/parches.json", "datos/parches.json")
        for f in sorted((LOCAL).rglob("*")):
            if f.is_file():
                z.write(f, "mods_locales/" + str(f.relative_to(LOCAL)))
        z.writestr("LEEME.txt", leeme)
    print(f"Creado {destino} ({destino.stat().st_size // 1024} KB)")
    return 0


def jugar(_args=None) -> int:
    """Prepara los mods y abre Isaac con REPENTOGON mediante Isaac.app (Sikarugir)."""
    if not LANZADOR_ISAAC.exists():
        print(f"Falta {LANZADOR_ISAAC}: crea el acceso de Isaac en Sikarugir (ver docs/REPENTOGON_LANZADOR.md).")
        return 1
    rc = preparar()
    if rc:
        return rc
    subprocess.run(["open", str(LANZADOR_ISAAC)], check=False)
    print("Abriendo Isaac con REPENTOGON…")
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
    sub.add_parser("empaquetar").set_defaults(f=empaquetar)
    sub.add_parser("diagnostico").set_defaults(f=diagnostico)
    sub.add_parser("parches").set_defaults(f=parches)
    sub.add_parser("preparar").set_defaults(f=preparar)
    es = sub.add_parser("escaner")
    es.add_argument("estado", choices=["on", "off"])
    es.set_defaults(f=escaner)
    sub.add_parser("instalar").set_defaults(f=instalar)
    sub.add_parser("jugar").set_defaults(f=jugar)
    args = p.parse_args()
    return args.f(args)


if __name__ == "__main__":
    sys.exit(main())
