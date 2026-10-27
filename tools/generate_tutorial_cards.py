from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "tutorial"
FONT_PATH = ROOT / "assets" / "fonts" / "PixelifySans.ttf"

W, H = 960, 480
BG = "#202833"
PANEL = "#454D5A"
SURFACE = "#596372"
GREEN = "#8BCB91"
GREEN_DARK = "#6FAF78"
WHITE = "#F4F6F2"
MUTED = "#CBD0D2"
SHADOW = "#111720"


def font(size: int):
    return ImageFont.truetype(str(FONT_PATH), size=size)


def text(draw, xy, value, size=20, color=WHITE, anchor="la", stroke=1):
    x, y = xy
    draw.text((x + 3, y + 3), value, font=font(size), fill=SHADOW, anchor=anchor)
    draw.text(
        (x, y), value, font=font(size), fill=color, anchor=anchor,
        stroke_width=stroke, stroke_fill=BG,
    )


def panel(draw, box, fill=PANEL, radius=18, border=SURFACE, width=4, depth=7):
    x1, y1, x2, y2 = box
    draw.rounded_rectangle((x1, y1 + depth, x2, y2 + depth), radius, fill=SHADOW)
    draw.rounded_rectangle(box, radius, fill=fill, outline=border, width=width)


def inset(draw, box, fill=BG, radius=14, border=SURFACE, width=3):
    draw.rounded_rectangle(box, radius, fill=fill, outline=border, width=width)


def button(draw, box, label):
    x1, y1, x2, y2 = box
    draw.rounded_rectangle((x1, y1 + 6, x2, y2 + 6), 14, fill=GREEN_DARK)
    draw.rounded_rectangle(box, 14, fill=GREEN, outline=GREEN_DARK, width=3)
    text(draw, ((x1 + x2) // 2, (y1 + y2) // 2), label, 21, anchor="mm", stroke=1)


def arrow(draw, start, end, color=GREEN, width=5, head=11):
    x1, y1 = start
    x2, y2 = end
    draw.line((x1, y1, x2, y2), fill=color, width=width)
    if abs(x2 - x1) >= abs(y2 - y1):
        points = [(x2, y2), (x2 - head if x2 > x1 else x2 + head, y2 - head),
                  (x2 - head if x2 > x1 else x2 + head, y2 + head)]
    else:
        points = [(x2, y2), (x2 - head, y2 - head if y2 > y1 else y2 + head),
                  (x2 + head, y2 - head if y2 > y1 else y2 + head)]
    draw.polygon(points, fill=color)


def base(title):
    image = Image.new("RGB", (W, H), BG)
    draw = ImageDraw.Draw(image)
    panel(draw, (8, 8, 952, 466), fill=PANEL, radius=20, border=SURFACE, width=4, depth=8)
    draw.rounded_rectangle((22, 20, 938, 66), 12, fill=SURFACE, outline=GREEN, width=2)
    text(draw, (42, 43), title, 24, anchor="lm", stroke=1)
    return image, draw


def slide_1():
    image, draw = base("PASO 1: ESCRIBIR Y EJECUTAR CÓDIGO")
    panel(draw, (30, 86, 466, 438), fill=SURFACE, radius=16, border=GREEN_DARK, width=3, depth=6)
    draw.rounded_rectangle((44, 100, 452, 142), 10, fill=PANEL)
    text(draw, (62, 121), "CONSOLA DE COMANDOS", 21, anchor="lm")
    inset(draw, (48, 154, 448, 420), fill=BG, radius=12, border=GREEN_DARK, width=2)
    text(draw, (72, 198), "1", 19, GREEN)
    text(draw, (112, 198), "spid.minar()", 23)
    text(draw, (72, 246), "2", 19, GREEN)
    text(draw, (112, 246), "spid.transferir()", 23)
    # Separación clara entre el último comando, la flecha y el botón.
    arrow(draw, (248, 278), (248, 306))
    button(draw, (132, 322, 364, 378), "EJECUTAR")

    panel(draw, (490, 86, 930, 438), fill=SURFACE, radius=16, border=GREEN_DARK, width=3, depth=6)
    text(draw, (520, 128), "REGLAS BÁSICAS", 23, GREEN)
    text(draw, (520, 180), "1. Escribe en minúsculas", 18)
    text(draw, (546, 211), "Usa siempre spid.accion()", 16, MUTED)
    text(draw, (520, 255), "2. Paréntesis obligatorios", 18)
    text(draw, (546, 286), "Pon () al final de cada orden.", 16, MUTED)
    inset(draw, (516, 326, 904, 414), fill=BG, radius=12, border=GREEN, width=2)
    text(draw, (536, 345), "TIP: Ejecuta también con", 15, GREEN)
    text(draw, (536, 379), "SHIFT + R", 18)
    return image


def slide_2():
    image, draw = base("PASO 2: DIRECCIONES DE MOVIMIENTO")
    panel(draw, (30, 86, 550, 438), fill=SURFACE, radius=16, border=GREEN_DARK, width=3, depth=6)
    inset(draw, (48, 104, 532, 420), fill=BG, radius=12, border=GREEN_DARK, width=2)
    inset(draw, (222, 208, 358, 278), fill=PANEL, radius=12, border=GREEN, width=3)
    text(draw, (290, 243), "SPID", 24, anchor="mm")
    # Diagrama simétrico: textos fuera del recorrido de las flechas y
    # separación constante respecto al bloque central.
    # Las cuatro direcciones usan exactamente 32 px de línea y el mismo
    # margen de 16 px entre la punta de la flecha y su etiqueta.
    text(draw, (290, 132), "spid.norte()", 20, anchor="ma")
    arrow(draw, (290, 202), (290, 170))
    arrow(draw, (290, 284), (290, 316))
    text(draw, (290, 348), "spid.sur()", 20, anchor="ma")
    arrow(draw, (222, 244), (190, 244))
    text(draw, (174, 244), "spid.oeste()", 17, anchor="rm")
    arrow(draw, (358, 244), (390, 244))
    text(draw, (406, 244), "spid.este()", 17, anchor="lm")

    panel(draw, (574, 86, 930, 438), fill=SURFACE, radius=16, border=GREEN_DARK, width=3, depth=6)
    text(draw, (604, 128), "CÓMO MOVERSE", 22, GREEN)
    text(draw, (604, 176), "• Cada orden avanza", 17)
    text(draw, (626, 204), "una casilla.", 17, MUTED)
    text(draw, (604, 240), "• Puedes encadenar", 17)
    text(draw, (626, 268), "varias órdenes:", 17, MUTED)
    inset(draw, (602, 300, 902, 378), fill=BG, radius=12, border=GREEN_DARK, width=2)
    text(draw, (624, 322), "spid.norte()", 18, GREEN)
    text(draw, (624, 352), "spid.norte()", 18, GREEN)
    text(draw, (604, 405), "La nave nodriza está al SUR.", 14, MUTED)
    # Redibujar el encabezado al final para mantenerlo siempre por encima de
    # cualquier elemento y evitar que el título quede parcialmente oculto.
    draw.rounded_rectangle((22, 20, 938, 66), 12, fill=SURFACE, outline=GREEN, width=2)
    text(draw, (42, 43), "PASO 2: DIRECCIONES DE MOVIMIENTO", 22, anchor="lm", stroke=1)
    return image


def slide_3():
    image, draw = base("PASO 3: MINAR Y TRANSFERIR")
    cards = [
        (30, 86, 304, 252, "1. AVANZAR", "spid.norte()", "Ve hacia el cristal."),
        (343, 86, 617, 252, "2. MINAR", "spid.minar()", "Extrae el mineral."),
        (656, 86, 930, 252, "3. REGRESAR", "spid.sur()", "Vuelve a la base."),
    ]
    for x1, y1, x2, y2, heading, command, desc in cards:
        panel(draw, (x1, y1, x2, y2), fill=SURFACE, radius=15, border=GREEN_DARK, width=3, depth=6)
        draw.rounded_rectangle((x1 + 12, y1 + 12, x2 - 12, y1 + 52), 9, fill=PANEL)
        text(draw, (x1 + 28, y1 + 32), heading, 18, anchor="lm")
        inset(draw, (x1 + 20, y1 + 72, x2 - 20, y1 + 120), fill=BG, radius=10, border=GREEN_DARK, width=2)
        text(draw, (x1 + 36, y1 + 96), command, 21, GREEN, anchor="lm")
        text(draw, (x1 + 24, y1 + 142), desc, 15, MUTED)

    panel(draw, (30, 276, 930, 438), fill=SURFACE, radius=16, border=GREEN_DARK, width=3, depth=6)
    draw.rounded_rectangle((44, 290, 916, 328), 9, fill=PANEL)
    text(draw, (62, 309), "PASO FINAL: DESCARGAR CON spid.transferir()", 17, anchor="lm")
    text(draw, (62, 352), "REGLA OBLIGATORIA", 16, GREEN)
    text(draw, (62, 380), "Spid solo transfiere carga en la casilla base (0, 0).", 14, MUTED)
    text(draw, (62, 412), "Regresa con spid.sur() y ejecuta spid.transferir().", 14)
    return image


for index, image in enumerate((slide_1(), slide_2(), slide_3()), start=1):
    output = OUT / f"fase0_{index}_{['consola', 'movimiento', 'ciclo'][index - 1]}.png"
    image.save(output, "PNG", optimize=True)
    print(output)
