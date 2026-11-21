"""Regenera assets/characters/archer/base/front_idle.png (40 px de altura lógica, Nearest)
a partir do original em source/. Uso: python3 tools/build_archer_assets.py
O original NUNCA é apagado; qualquer redução é refeita a partir dele."""
from PIL import Image
import sys
H = int(sys.argv[1]) if len(sys.argv) > 1 else 40
src = Image.open("assets/characters/archer/source/front_idle_r1f2.png").convert("RGBA")
w = max(1, round(src.width * H / src.height))
src.resize((w, H), Image.NEAREST).save("assets/characters/archer/base/front_idle.png")
print("front_idle.png", w, "x", H)