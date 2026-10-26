import json, re, collections
from check import load
tr = {}
for n in range(17):
    src, t = load(f"{n:02d}")
    for i, s in enumerate(src):
        tr[s] = t[i]
E = json.load(open("entries.json"))
miss = 0
out = collections.OrderedDict()
for e in E:
    parts = []
    for s in e["desc"].split("#"):
        if not s.strip():
            parts.append(s); continue
        if s not in tr:
            miss += 1; print("FALTA", repr(s)); parts.append(s); continue
        lead = s[:len(s) - len(s.lstrip())]
        parts.append(lead + tr[s].strip())
    out.setdefault(e["mod"], []).append((e["kind"], e["id"], e.get("name"), "#".join(parts)))
print("faltan", miss)
def q(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n") + '"'
NOMBRES = {"fiendfolio-reloaded_3778123093": "Fiend Folio", "revelations_2880387531": "Revelations",
  "andromeda_2722017893": "Andromeda", "job_2567634705": "Job", "mattpack_3408993906": "MattPack",
  "repentanceplus_2627014611": "Repentance+", "passive skill trees_3305869734": "Passive Skill Trees",
  "icesaac_2955792897": "Icesaac", "agatha_2928402913": "Agatha"}
L = ["-- Generado automáticamente desde los textos EID en inglés de cada mod. No editar a mano:",
     "-- regenerar con la herramienta de traducción (ver docs/TRADUCCION.md).",
     "-- { tipo, id, nombre_jugador (solo b/ch), texto_es }",
     "-- tipo: c objeto, t baratija, k carta/runa, p píldora, b birthright, ch info de personaje",
     "-- id: ⟨x:Nombre⟩ = nombre interno del mod (se resuelve en partida); ‹ruta› = variable global del mod",
     "return {"]
total = 0
for mod, rows in out.items():
    L.append(f"  -- {NOMBRES.get(mod, mod)} ({len(rows)})")
    for k, i, name, d in rows:
        nm = q(name) if (k in ("b", "ch") and name) else "nil"
        L.append(f"  {{ {q(k)}, {q(i)}, {nm}, {q(d)} }},")
        total += 1
L.append("}")
open("../../mods_locales/traduccion_es_mods/datos_es.lua", "w", encoding="utf-8").write("\n".join(L) + "\n")
print("entradas", total)
