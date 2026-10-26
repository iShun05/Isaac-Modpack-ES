# Busca en entries.json frases (#segmentos) que aún no tienen traducción en es/*.txt
# y las guarda en un bloque nuevo chunks/seg_NN.json para traducir (es/NN.txt, una línea «índice<TAB>texto»).
import json, glob, os
from check import load
hechos = set()
n = 0
for f in sorted(glob.glob("chunks/seg_*.json")):
    num = os.path.basename(f)[4:-5]
    n = max(n, int(num) + 1)
    if os.path.exists(f"es/{num}.txt"):
        hechos.update(load(num)[0])
nuevos = []
for e in json.load(open("entries.json", encoding="utf-8")):
    for s in e["desc"].split("#"):
        if s.strip() and s not in hechos and s not in nuevos:
            nuevos.append(s)
if not nuevos:
    print("Todo traducido.")
else:
    for i in range(0, len(nuevos), 160):
        destino = f"chunks/seg_{n:02d}.json"
        json.dump(nuevos[i:i + 160], open(destino, "w", encoding="utf-8"), ensure_ascii=False, indent=0)
        print(f"{destino}: {len(nuevos[i:i + 160])} frases por traducir en es/{n:02d}.txt")
        n += 1
