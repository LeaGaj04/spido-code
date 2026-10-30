"""
Generador de tarjetas pedagogicas visuales (slides) para SpidoCode.
Utiliza exclusivamente la paleta y estilo oficial de la app (tema_global.tres):
Fondo #202833, Paneles #2B3442, Bordes #454D5A, Acento verde #8BCB91/#6FAF78,
Texto blanco #F4F6F2 y texto atenuado #CBD0D2.
Sin botones rojos ni verdes invasivos, sin referencias a 'Python' y con textos simples y directos.
"""

from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "tutorial"

FONT_PATH = ROOT / "assets" / "fonts" / "PixelifySans.ttf"

W, H = 960, 480

# ==============================================================================
# PALETA NATIVA OFICIAL DE LA APP (desde tema_global.tres)
# ==============================================================================
BG_CANVAS     = (32, 40, 51)       # #202833 - Fondo ventana y CodeArea
PANEL_BG      = (43, 52, 66)       # #2B3442 - Fondo de paneles
PANEL_BORDER  = (69, 77, 90)       # #454D5A - Borde de panel
PANEL_BEVEL   = (25, 32, 42)       # Bisel 3D inferior del panel
PANEL_SHADOW  = (17, 23, 32)       # #111720 - Sombra profunda

INSET_BG      = (32, 40, 51)       # #202833 - Inset de codigo / contenedor interno
INSET_BORDER  = (69, 77, 90)       # #454D5A - Borde de contenedor interno

GREEN_ACCENT  = (139, 203, 145)    # #8BCB91 - Verde acento oficial
GREEN_BORDER  = (111, 175, 120)    # #6FAF78 - Borde verde oficial
GREEN_BEVEL   = (55, 95, 65)       # Bisel inferior del boton

WHITE_TEXT    = (244, 246, 242)    # #F4F6F2 - Texto principal
MUTED_TEXT    = (203, 208, 210)    # #CBD0D2 - Texto secundario / descripciones
DIM_TEXT      = (140, 150, 162)    # Comentarios y numeros

TEXT_SHADOW   = (17, 23, 32)       # Sombra de texto 2px


_FONTS = {}

def get_font(size: int):
    if size not in _FONTS:
        _FONTS[size] = ImageFont.truetype(str(FONT_PATH), size)
    return _FONTS[size]


# ==============================================================================
# PRIMITIVAS GRAFICAS
# ==============================================================================

def draw_text(draw, pos, text, font, fill=WHITE_TEXT, shadow=TEXT_SHADOW, anchor=None, offset=(2, 2)):
    """Texto nítido con sombra de 2px estilo Godot."""
    x, y = pos
    if shadow:
        sx, sy = offset
        draw.text((x + sx, y + sy), text, font=font, fill=shadow, anchor=anchor)
    draw.text((x, y), text, font=font, fill=fill, anchor=anchor)


def draw_panel(draw, box, fill=PANEL_BG, border=PANEL_BORDER, bevel=PANEL_BEVEL, radius=8, bevel_h=4):
    """Panel beveled retro estilo StyleBoxFlat de Godot."""
    x1, y1, x2, y2 = box
    draw.rounded_rectangle((x1, y1 + bevel_h + 2, x2, y2 + bevel_h + 2), radius=radius, fill=PANEL_SHADOW)
    draw.rounded_rectangle((x1, y1, x2, y2 + bevel_h), radius=radius, fill=bevel)
    draw.rounded_rectangle((x1, y1, x2, y2), radius=radius, fill=fill, outline=border, width=2)


def draw_inset(draw, box, fill=INSET_BG, border=INSET_BORDER, radius=6):
    """Contenedor hundido para codigo, terminal o notas."""
    x1, y1, x2, y2 = box
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=border, width=2)


def draw_button(draw, box, text, fill=GREEN_ACCENT, border=GREEN_BORDER, bevel=GREEN_BEVEL, radius=8):
    """Boton interactivo con la paleta de tema_global.tres."""
    x1, y1, x2, y2 = box
    bevel_h = 4
    draw.rounded_rectangle((x1, y1 + bevel_h + 2, x2, y2 + bevel_h + 2), radius=radius, fill=PANEL_SHADOW)
    draw.rounded_rectangle((x1, y1, x2, y2 + bevel_h), radius=radius, fill=bevel)
    draw.rounded_rectangle((x1, y1, x2, y2), radius=radius, fill=fill, outline=border, width=2)
    
    cx, cy = (x1 + x2) // 2, (y1 + y2) // 2
    col = (18, 32, 22)
    
    play_x = cx - 85
    pts = [(play_x, cy - 8), (play_x, cy + 8), (play_x + 13, cy)]
    draw.polygon(pts, fill=col)
    
    draw.text((play_x + 24, cy), text, font=get_font(16), fill=col, anchor="lm")


def draw_chip(draw, box, text, fill=INSET_BG, border=INSET_BORDER, text_col=WHITE_TEXT, font_size=13, radius=4):
    """Chip o caja compacta con la paleta de la app."""
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=border, width=1)
    cx, cy = (box[0] + box[2]) // 2, (box[1] + box[3]) // 2
    draw_text(draw, (cx, cy), text, get_font(font_size), fill=text_col, anchor="mm")


def draw_arrow_down(draw, cx, cy, col=GREEN_ACCENT, s=2):
    """Flecha hacia abajo."""
    for y in range(-5, 2):
        draw.rectangle((cx - s, cy + y*s, cx + s - 1, cy + y*s + s - 1), fill=col)
    for i in range(4):
        draw.rectangle((cx - (3 - i)*s, cy + (1 + i)*s, cx + (3 - i)*s + s - 1, cy + (1 + i)*s + s - 1), fill=col)


def draw_arrow_right(draw, cx, cy, col=GREEN_ACCENT, s=2):
    """Flecha hacia la derecha."""
    for x in range(-5, 2):
        draw.rectangle((cx + x*s, cy - s, cx + x*s + s - 1, cy + s - 1), fill=col)
    for i in range(4):
        draw.rectangle((cx + (1 + i)*s, cy - (3 - i)*s, cx + (1 + i)*s + s - 1, cy + (3 - i)*s + s - 1), fill=col)


def create_base(badge_text: str, title_text: str):
    """Crea la cabecera del slide con la paleta de la app."""
    image = Image.new("RGB", (W, H), BG_CANVAS)
    draw = ImageDraw.Draw(image)
    
    draw_panel(draw, (20, 12, 940, 56), fill=PANEL_BG, border=PANEL_BORDER, bevel=PANEL_BEVEL, radius=8, bevel_h=3)
    
    font_b = get_font(13)
    b_box = font_b.getbbox(badge_text)
    b_w = (b_box[2] - b_box[0]) + 20
    draw.rounded_rectangle((30, 20, 30 + b_w, 48), radius=4, fill=(30, 44, 38), outline=GREEN_BORDER, width=1)
    draw_text(draw, (30 + b_w // 2, 34), badge_text, font_b, fill=GREEN_ACCENT, anchor="mm")
    
    draw_text(draw, (46 + b_w, 34), title_text, get_font(18), fill=WHITE_TEXT, anchor="lm")
    
    return image, draw


# ==============================================================================
# FASE 0: PROTOCOLO DE INDUCCION BASICA
# ==============================================================================

def slide_0_1():
    """Fase 0 - Slide 1: Consola de Comandos y Primer Codigo"""
    image, draw = create_base("FASE 0 // INDUCCION", "PASO 1: CONSOLA DE COMANDOS Y PRIMER CODIGO")
    
    # Panel Izquierdo: Terminal y Boton Ejecutar
    draw_panel(draw, (20, 68, 475, 464))
    draw_text(draw, (40, 88), "CONSOLA DE COMANDOS", get_font(16), fill=GREEN_ACCENT)
    
    # Pantalla editor con "Consola Spido"
    draw_inset(draw, (38, 114, 456, 260), fill=INSET_BG, border=INSET_BORDER)
    draw.rectangle((40, 116, 454, 144), fill=(38, 48, 62))
    draw_text(draw, (52, 130), "> Consola Spido", get_font(13), fill=MUTED_TEXT, anchor="lm")
    
    # Codigo
    draw_text(draw, (52, 172), "1", get_font(15), fill=DIM_TEXT)
    draw_text(draw, (76, 172), "spid.minar()", get_font(16), fill=WHITE_TEXT)
    draw_text(draw, (440, 172), "# Extrae el mineral", get_font(13), fill=MUTED_TEXT, anchor="rm")
    
    draw_text(draw, (52, 212), "2", get_font(15), fill=DIM_TEXT)
    draw_text(draw, (76, 212), "spid.transferir()", get_font(16), fill=WHITE_TEXT)
    draw_text(draw, (440, 212), "# Entrega a la nave", get_font(13), fill=MUTED_TEXT, anchor="rm")
    
    # Flecha y Boton Ejecutar
    draw_arrow_down(draw, 247, 274, col=GREEN_ACCENT, s=2)
    draw_text(draw, (247, 308), "Presiona Ejecutar para enviar las ordenes a Spid", get_font(13), fill=MUTED_TEXT, anchor="mm")
    draw_button(draw, (85, 330, 410, 384), "EJECUTAR CODIGO")
    
    # Atajo de teclado
    draw_inset(draw, (38, 408, 456, 446), fill=INSET_BG, border=INSET_BORDER)
    draw_text(draw, (52, 427), "Atajo rapido:", get_font(13), fill=MUTED_TEXT, anchor="lm")
    draw_chip(draw, (146, 416, 246, 438), "SHIFT + R", fill=PANEL_BG, border=PANEL_BORDER, text_col=WHITE_TEXT, font_size=12)
    draw_text(draw, (258, 427), "ejecuta al instante", get_font(13), fill=WHITE_TEXT, anchor="lm")
    
    # Panel Derecho: Reglas Basicas (Sin "Python", con margenes limpios)
    draw_panel(draw, (495, 68, 940, 464))
    draw_text(draw, (515, 88), "REGLAS BASICAS", get_font(16), fill=GREEN_ACCENT)
    
    # Regla 1: Minusculas
    draw_inset(draw, (515, 114, 920, 208))
    draw_text(draw, (530, 132), "1. Escribe todo en minusculas", get_font(15), fill=WHITE_TEXT)
    draw_text(draw, (530, 154), "Usa siempre letras minusculas para las ordenes.", get_font(13), fill=MUTED_TEXT)
    draw_chip(draw, (530, 172, 700, 198), "Usa:  spid.minar()", fill=PANEL_BG, border=GREEN_BORDER, text_col=GREEN_ACCENT, font_size=13)
    
    # Regla 2: Parentesis
    draw_inset(draw, (515, 222, 920, 316))
    draw_text(draw, (530, 240), "2. Parentesis obligatorios ()", get_font(15), fill=WHITE_TEXT)
    draw_text(draw, (530, 262), "Cada orden de Spid es una accion y requiere ().", get_font(13), fill=MUTED_TEXT)
    draw_chip(draw, (530, 280, 750, 306), "Ejemplo:  spid.transferir()", fill=PANEL_BG, border=PANEL_BORDER, text_col=WHITE_TEXT, font_size=13)
    
    # Cuadro A.D.A.
    draw_inset(draw, (515, 330, 920, 446), fill=(28, 42, 36), border=GREEN_BORDER)
    draw_text(draw, (530, 350), "CONSEJO DE A.D.A.", get_font(14), fill=GREEN_ACCENT)
    draw_text(draw, (530, 376), "En la primera mision, el mineral esta bajo Spid.", get_font(13), fill=WHITE_TEXT)
    draw_text(draw, (530, 400), "Solo necesitas ejecutar minar() y luego transferir().", get_font(13), fill=WHITE_TEXT)
    draw_text(draw, (530, 424), "La nave nodriza recibira la carga en (0, 0).", get_font(13), fill=MUTED_TEXT)
    
    return image


def slide_0_2():
    """Fase 0 - Slide 2: Direcciones y Desplazamiento del Spid"""
    image, draw = create_base("FASE 0 // INDUCCION", "PASO 2: DIRECCIONES Y DESPLAZAMIENTO DEL SPID")
    
    # Panel Izquierdo: Brujula de Navegacion
    draw_panel(draw, (20, 68, 510, 464))
    draw_text(draw, (40, 88), "DIRECCIONES DE MOVIMIENTO", get_font(16), fill=GREEN_ACCENT)
    
    cx, cy = 265, 276
    draw_inset(draw, (38, 114, 492, 446), fill=INSET_BG, border=INSET_BORDER)
    
    # Reticula radar
    draw.ellipse((cx - 105, cy - 105, cx + 105, cy + 105), outline=(48, 58, 74), width=1)
    draw.ellipse((cx - 55, cy - 55, cx + 55, cy + 55), outline=(48, 58, 74), width=1)
    draw.line((cx - 115, cy, cx + 115, cy), fill=(48, 58, 74), width=1)
    draw.line((cx, cy - 115, cx, cy + 115), fill=(48, 58, 74), width=1)
    
    # Centro: SPID
    draw.rounded_rectangle((cx - 42, cy - 20, cx + 42, cy + 20), radius=6, fill=PANEL_BG, outline=GREEN_ACCENT, width=2)
    draw_text(draw, (cx, cy), "SPID", get_font(16), fill=WHITE_TEXT, anchor="mm")
    
    # NORTE (Arriba)
    draw.line((cx, cy - 22, cx, cy - 58), fill=GREEN_ACCENT, width=2)
    draw.polygon([(cx, cy - 68), (cx - 7, cy - 58), (cx + 7, cy - 58)], fill=GREEN_ACCENT)
    draw_chip(draw, (cx - 68, cy - 106, cx + 68, cy - 74), "spid.norte()", fill=PANEL_BG, border=GREEN_BORDER, text_col=GREEN_ACCENT, font_size=14)
    
    # SUR (Abajo)
    draw.line((cx, cy + 22, cx, cy + 58), fill=GREEN_ACCENT, width=2)
    draw.polygon([(cx, cy + 68), (cx - 7, cy + 58), (cx + 7, cy + 58)], fill=GREEN_ACCENT)
    draw_chip(draw, (cx - 60, cy + 74, cx + 60, cy + 106), "spid.sur()", fill=PANEL_BG, border=GREEN_BORDER, text_col=GREEN_ACCENT, font_size=14)
    
    # OESTE (Izquierda) - Margen generoso libre de colisiones
    draw.line((cx - 44, cy, cx - 70, cy), fill=GREEN_ACCENT, width=2)
    draw.polygon([(cx - 78, cy), (cx - 68, cy - 7), (cx - 68, cy + 7)], fill=GREEN_ACCENT)
    draw_chip(draw, (cx - 212, cy - 16, cx - 88, cy + 16), "spid.oeste()", fill=PANEL_BG, border=GREEN_BORDER, text_col=GREEN_ACCENT, font_size=14)
    
    # ESTE (Derecha)
    draw.line((cx + 44, cy, cx + 70, cy), fill=GREEN_ACCENT, width=2)
    draw.polygon([(cx + 78, cy), (cx + 68, cy - 7), (cx + 68, cy + 7)], fill=GREEN_ACCENT)
    draw_chip(draw, (cx + 88, cy - 16, cx + 212, cy + 16), "spid.este()", fill=PANEL_BG, border=GREEN_BORDER, text_col=GREEN_ACCENT, font_size=14)
    
    # Panel Derecho: Reglas de Desplazamiento
    draw_panel(draw, (530, 68, 940, 464))
    draw_text(draw, (550, 88), "COMO MOVERSE POR LA GRILLA", get_font(16), fill=GREEN_ACCENT)
    
    # Regla 1
    draw_inset(draw, (550, 114, 920, 204))
    draw_text(draw, (566, 132), "• Cada orden avanza 1 casilla", get_font(15), fill=WHITE_TEXT)
    draw_text(draw, (566, 156), "Cada casilla mide 2 metros en el terreno.", get_font(13), fill=MUTED_TEXT)
    draw_text(draw, (566, 178), "Spid se detiene en el centro de la celda.", get_font(13), fill=MUTED_TEXT)
    
    # Regla 2
    draw_inset(draw, (550, 218, 920, 326))
    draw_text(draw, (566, 236), "• Puedes encadenar varias ordenes:", get_font(15), fill=WHITE_TEXT)
    
    draw.rounded_rectangle((566, 260, 904, 312), radius=4, fill=(38, 48, 62))
    draw_text(draw, (582, 274), "spid.norte()", get_font(14), fill=GREEN_ACCENT)
    draw_text(draw, (582, 294), "spid.norte()", get_font(14), fill=GREEN_ACCENT)
    draw_text(draw, (730, 284), "# Avanza 2 casillas", get_font(13), fill=MUTED_TEXT)
    
    # Regla 3: Base Nave
    draw_inset(draw, (550, 340, 920, 446), fill=(28, 42, 36), border=GREEN_BORDER)
    draw_text(draw, (566, 358), "BASE NAVE NODRIZA: EN (0, 0)", get_font(14), fill=GREEN_ACCENT)
    draw_text(draw, (566, 384), "La casilla de inicio y entrega esta en la base (0, 0).", get_font(13), fill=WHITE_TEXT)
    draw_text(draw, (566, 406), "Si avanzas al norte a buscar mineral, volveras", get_font(13), fill=WHITE_TEXT)
    draw_text(draw, (566, 426), "hacia la nave ejecutando spid.sur().", get_font(13), fill=MUTED_TEXT)
    
    return image


def slide_0_3():
    """Fase 0 - Slide 3: El Ciclo Completo de Recoleccion"""
    image, draw = create_base("FASE 0 // INDUCCION", "PASO 3: MINAR Y TRANSFERIR EL MINERAL")
    
    steps = [
        ("1", "AVANZAR", "spid.norte()", ["Avanza hacia", "el cristal."], GREEN_ACCENT),
        ("2", "MINAR", "spid.minar()", ["Extrae el", "mineral."], GREEN_ACCENT),
        ("3", "REGRESAR", "spid.sur()", ["Vuelve a la", "base (0, 0)."], GREEN_ACCENT),
        ("4", "ENTREGAR", "spid.transferir()", ["Descarga en", "la nave."], GREEN_ACCENT),
    ]
    
    w_step = 215
    for idx, (num, name, cmd, lines_desc, col) in enumerate(steps):
        x1 = 20 + idx * 235
        x2 = x1 + w_step
        draw_panel(draw, (x1, 68, x2, 282))
        
        draw.rounded_rectangle((x1 + 10, 78, x1 + 42, 110), radius=4, fill=(38, 48, 62))
        draw_text(draw, (x1 + 26, 94), num, get_font(16), fill=col, anchor="mm")
        draw_text(draw, (x1 + 50, 94), name, get_font(14), fill=WHITE_TEXT, anchor="lm")
        
        draw_chip(draw, (x1 + 12, 126, x2 - 12, 162), cmd, fill=INSET_BG, border=PANEL_BORDER, text_col=col, font_size=14)
        
        y_text = 192
        for line in lines_desc:
            draw_text(draw, ((x1 + x2) // 2, y_text), line, get_font(13), fill=MUTED_TEXT, anchor="mm")
            y_text += 22
            
        if idx < 3:
            arrow_x = x2 + 10
            arrow_y = 144
            draw_arrow_right(draw, arrow_x, arrow_y, col=GREEN_ACCENT, s=2)

    # Panel Inferior: Regla de Oro
    draw_panel(draw, (20, 302, 940, 464))
    draw_inset(draw, (36, 318, 924, 448), fill=INSET_BG, border=GREEN_BORDER)
    
    draw_chip(draw, (52, 332, 240, 360), "REGLA OBLIGATORIA", fill=PANEL_BG, border=GREEN_BORDER, text_col=GREEN_ACCENT, font_size=13)
    
    draw_text(draw, (52, 376), "Spid solo transfiere carga cuando esta parado en la CASILLA BASE (0, 0).", get_font(15), fill=WHITE_TEXT)
    draw_text(draw, (52, 402), "Si ejecutas spid.transferir() fuera de la base, el sistema de acople no alcanzara la nave.", get_font(13), fill=MUTED_TEXT)
    draw_text(draw, (52, 424), "Regla de oro: ¡Primero regresa al sur con spid.sur(), luego ejecuta spid.transferir()!", get_font(13), fill=GREEN_ACCENT)
    
    return image


# ==============================================================================
# FASE 1: SECUENCIA LINEAL (ORDEN ESTRICTO)
# ==============================================================================

def slide_1_1():
    """Fase 1 - Slide 1: Flujo Secuencial (Sin 'Python')"""
    image, draw = create_base("FASE 1 // SECUENCIA LINEAL", "PASO 1: FLUJO SECUENCIAL Y ORDEN DE EJECUCION")
    
    # Panel Izquierdo: Secuencia Paso a Paso
    draw_panel(draw, (20, 68, 480, 464))
    draw_text(draw, (40, 88), "ORDEN ESTRICTO DE EJECUCION", get_font(16), fill=GREEN_ACCENT)
    
    steps = [
        ("1", "spid.norte()", "Avanza hacia el mineral"),
        ("2", "spid.minar()", "Extrae la roca de cristal"),
        ("3", "spid.sur()", "Regresa a la base (0, 0)"),
        ("4", "spid.transferir()", "Descarga mineral a la nave"),
    ]
    
    y = 114
    for num, cmd, desc in steps:
        draw_inset(draw, (40, y, 460, y + 62))
        
        draw.rounded_rectangle((52, y + 14, 84, y + 48), radius=4, fill=(38, 48, 62))
        draw_text(draw, (68, y + 31), num, get_font(16), fill=GREEN_ACCENT, anchor="mm")
        
        draw_text(draw, (98, y + 21), cmd, get_font(15), fill=WHITE_TEXT)
        draw_text(draw, (98, y + 43), desc, get_font(13), fill=MUTED_TEXT)
        
        if int(num) < 4:
            draw_arrow_down(draw, 68, y + 69, col=GREEN_ACCENT, s=2)
        y += 76

    # Panel Derecho: Principios de Programacion (Sin 'Python')
    draw_panel(draw, (500, 68, 940, 464))
    draw_text(draw, (520, 88), "¿POR QUE EL ORDEN ES CLAVE?", get_font(16), fill=GREEN_ACCENT)
    
    # Principio 1: Sin 'Python'
    draw_inset(draw, (520, 114, 920, 208))
    draw_text(draw, (536, 132), "1. Ejecucion de arriba a abajo", get_font(15), fill=WHITE_TEXT)
    draw_text(draw, (536, 156), "Las ordenes se leen y ejecutan linea por linea.", get_font(13), fill=MUTED_TEXT)
    draw_text(draw, (536, 178), "No se salta lineas ni ejecuta dos ordenes a la vez.", get_font(13), fill=MUTED_TEXT)
    
    # Principio 2
    draw_inset(draw, (520, 222, 920, 316))
    draw_text(draw, (536, 240), "2. Relacion de Causa y Efecto", get_font(15), fill=WHITE_TEXT)
    draw_text(draw, (536, 264), "No puedes transferir lo que no has minado,", get_font(13), fill=MUTED_TEXT)
    draw_text(draw, (536, 286), "ni minar sin estar parado sobre el mineral.", get_font(13), fill=MUTED_TEXT)
    
    # Cuadro ADA
    draw_inset(draw, (520, 330, 920, 446), fill=(28, 42, 36), border=GREEN_BORDER)
    draw_text(draw, (536, 350), "CONSEJO DE A.D.A.", get_font(14), fill=GREEN_ACCENT)
    draw_text(draw, (536, 374), "Si algo falla, lee tu codigo paso a paso:", get_font(13), fill=WHITE_TEXT)
    draw_text(draw, (536, 396), "¿Donde esta Spid en cada orden?", get_font(13), fill=WHITE_TEXT)
    draw_text(draw, (536, 420), "¿Regreso a la base antes de transferir?", get_font(13), fill=GREEN_ACCENT)
    
    return image


def slide_1_2():
    """Fase 1 - Slide 2: El Corredor Lineal (1x3) - Mas simple y directo para el usuario"""
    image, draw = create_base("FASE 1 // SECUENCIA LINEAL", "PASO 2: EL CORREDOR LINEAL (1X3)")
    
    # Panel Izquierdo: Mapa del Corredor
    draw_panel(draw, (20, 68, 470, 464))
    draw_text(draw, (40, 88), "MAPA DEL SECTOR: CORREDOR 1X3", get_font(16), fill=GREEN_ACCENT)
    
    draw_inset(draw, (38, 114, 452, 446), fill=INSET_BG, border=INSET_BORDER)
    
    tiles = [
        (130, 140, 360, 204, "YACIMIENTO (Cristal)", "Casilla (0, 0, -2) // Deposito", (32, 46, 40), GREEN_ACCENT),
        (130, 236, 360, 300, "CORREDOR LINEAL", "Casilla (0, 0, -1) // Transito", (38, 48, 62), MUTED_TEXT),
        (130, 332, 360, 396, "BASE NAVE NODRIZA", "Casilla (0, 0, 0) // Transferencia", (40, 52, 68), WHITE_TEXT),
    ]
    
    for x1, y1, x2, y2, title, subt, bg, col in tiles:
        draw.rounded_rectangle((x1, y1, x2, y2), radius=6, fill=bg, outline=PANEL_BORDER, width=1)
        draw_text(draw, (x1 + 18, y1 + 16), title, get_font(14), fill=col)
        draw_text(draw, (x1 + 18, y1 + 38), subt, get_font(12), fill=DIM_TEXT)
    
    # Ruta de Ida (Norte) - Izquierda
    chip_x1, chip_x2 = 44, 116
    cx_ida = (chip_x1 + chip_x2) // 2
    for y in range(280, 356, 4):
        draw.rectangle((cx_ida - 1, y, cx_ida + 1, y + 2), fill=GREEN_ACCENT)
    for y in range(180, 248, 4):
        draw.rectangle((cx_ida - 1, y, cx_ida + 1, y + 2), fill=GREEN_ACCENT)
    draw.polygon([(cx_ida, 168), (cx_ida - 6, 180), (cx_ida + 6, 180)], fill=GREEN_ACCENT)
    draw_chip(draw, (chip_x1, 248, chip_x2, 276), "spid.norte()", fill=PANEL_BG, border=GREEN_BORDER, text_col=GREEN_ACCENT, font_size=12)
    
    # Ruta de Retorno (Sur) - Derecha
    chip_s_x1, chip_s_x2 = 374, 446
    cx_ret = (chip_s_x1 + chip_s_x2) // 2
    for y in range(184, 248, 4):
        draw.rectangle((cx_ret - 1, y, cx_ret + 1, y + 2), fill=MUTED_TEXT)
    for y in range(280, 356, 4):
        draw.rectangle((cx_ret - 1, y, cx_ret + 1, y + 2), fill=MUTED_TEXT)
    draw.polygon([(cx_ret, 368), (cx_ret - 6, 356), (cx_ret + 6, 356)], fill=MUTED_TEXT)
    draw_chip(draw, (chip_s_x1, 248, chip_s_x2, 276), "spid.sur()", fill=PANEL_BG, border=PANEL_BORDER, text_col=WHITE_TEXT, font_size=12)
    
    draw_text(draw, (245, 420), "Distancia: 1 casilla al norte desde la base", get_font(12), fill=MUTED_TEXT, anchor="mm")
    
    # Panel Derecho: Guia de Calibracion mas simple y directa
    draw_panel(draw, (490, 68, 940, 464))
    draw_text(draw, (510, 88), "RUTA PASO A PASO", get_font(16), fill=GREEN_ACCENT)
    
    simple_steps = [
        ("1. AVANZAR", "spid.norte()", "Avanza hacia el cristal."),
        ("2. EXTRAER", "spid.minar()", "Extrae el mineral del suelo."),
        ("3. REGRESAR", "spid.sur()", "Vuelve a la base (0, 0)."),
        ("4. ENTREGAR", "spid.transferir()", "Descarga en la nave nodriza."),
    ]
    
    y = 114
    for title, cmd, desc in simple_steps:
        draw_inset(draw, (510, y, 920, y + 74))
        draw_text(draw, (526, y + 16), title, get_font(14), fill=WHITE_TEXT)
        draw_chip(draw, (770, y + 10, 908, y + 34), cmd, fill=PANEL_BG, border=GREEN_BORDER, text_col=GREEN_ACCENT, font_size=13)
        draw_text(draw, (526, y + 44), desc, get_font(13), fill=MUTED_TEXT)
        y += 82
        
    return image


def slide_1_3():
    """Fase 1 - Slide 3: Prevencion de Errores Comunes (Sin menciones a Python)"""
    image, draw = create_base("FASE 1 // PREVENCION DE ERRORES", "PASO 3: ERRORES FRECUENTES Y SOLUCIONES")
    
    errors = [
        (
            "ERROR 1: MINAR EN CASILLA VACIA",
            "Ejecutar minar() antes de pararse sobre el cristal.",
            "Avanza primero con spid.norte() al yacimiento.",
            "spid.norte() y luego spid.minar()"
        ),
        (
            "ERROR 2: TRANSFERIR LEJOS DE LA NAVE",
            "Spid solo entrega carga en la CASILLA BASE (0, 0).",
            "Regresa siempre con spid.sur() antes de transferir.",
            "spid.sur() y luego spid.transferir()"
        ),
        (
            "ERROR 3: MAYUSCULAS O SIN PARENTESIS",
            "Escribir en mayusculas o no poner parentesis ().",
            "Escribe siempre en minusculas: spid.comando().",
            "spid.norte()"
        )
    ]
    
    y = 68
    for title, err_desc, sol_desc, good_code in errors:
        draw_panel(draw, (20, y, 940, y + 124))
        
        # Titulo del error
        draw_chip(draw, (36, y + 12, 340, y + 36), title, fill=INSET_BG, border=PANEL_BORDER, text_col=WHITE_TEXT, font_size=12)
        
        # Explicacion limpia sin desbordes ni menciones a Python
        draw_text(draw, (36, y + 54), f"• Problema: {err_desc}", get_font(13), fill=MUTED_TEXT)
        draw_text(draw, (36, y + 84), f"• Solucion: {sol_desc}", get_font(13), fill=WHITE_TEXT)
        
        # Bloque de orden correcta
        draw_inset(draw, (560, y + 34, 920, y + 88), fill=INSET_BG, border=GREEN_BORDER)
        draw_text(draw, (576, y + 48), "Orden correcta:", get_font(12), fill=MUTED_TEXT)
        draw_text(draw, (576, y + 68), good_code, get_font(14), fill=GREEN_ACCENT)
        
        y += 134
        
    return image


# ==============================================================================
# FASE 2: BUCLE WHILE (TRABAJO CONTINUO)
# ==============================================================================

def slide_2_1():
    """Fase 2 - Slide 1: Automatizacion y el Bucle While True"""
    image, draw = create_base("FASE 2 // BUCLE WHILE", "PASO 1: AUTOMATIZACION Y EL BUCLE WHILE TRUE")
    
    # Panel Izquierdo: Consola Spido con bucle continuo
    draw_panel(draw, (20, 68, 475, 464))
    draw_text(draw, (40, 88), "CONSOLA SPIDO // BUCLE CONTINUO", get_font(16), fill=GREEN_ACCENT)
    
    # Pantalla editor
    draw_inset(draw, (38, 114, 456, 310), fill=INSET_BG, border=INSET_BORDER)
    draw.rectangle((40, 116, 454, 144), fill=(38, 48, 62))
    draw_text(draw, (52, 130), "> Consola Spido", get_font(13), fill=MUTED_TEXT, anchor="lm")
    
    # Lineas de codigo con bucle
    draw_text(draw, (50, 168), "1", get_font(14), fill=DIM_TEXT)
    draw_text(draw, (70, 168), "while True:", get_font(15), fill=GREEN_ACCENT)
    
    draw_text(draw, (50, 198), "2", get_font(14), fill=DIM_TEXT)
    draw_text(draw, (94, 198), "spid.norte()", get_font(15), fill=WHITE_TEXT)
    draw_text(draw, (440, 198), "# 1. Avanza al mineral", get_font(12), fill=MUTED_TEXT, anchor="rm")
    
    draw_text(draw, (50, 226), "3", get_font(14), fill=DIM_TEXT)
    draw_text(draw, (94, 226), "spid.minar()", get_font(15), fill=WHITE_TEXT)
    draw_text(draw, (440, 226), "# 2. Extrae cristal", get_font(12), fill=MUTED_TEXT, anchor="rm")
    
    draw_text(draw, (50, 254), "4", get_font(14), fill=DIM_TEXT)
    draw_text(draw, (94, 254), "spid.sur()", get_font(15), fill=WHITE_TEXT)
    draw_text(draw, (440, 254), "# 3. Vuelve a la base", get_font(12), fill=MUTED_TEXT, anchor="rm")
    
    draw_text(draw, (50, 282), "5", get_font(14), fill=DIM_TEXT)
    draw_text(draw, (94, 282), "spid.transferir()", get_font(15), fill=WHITE_TEXT)
    draw_text(draw, (440, 282), "# 4. Descarga en nave", get_font(12), fill=MUTED_TEXT, anchor="rm")
    
    # Conector de ciclo / bucle en el editor
    draw_inset(draw, (38, 330, 456, 446), fill=INSET_BG, border=GREEN_BORDER)
    draw_text(draw, (52, 350), "CICLO CONTINUO AUTOMATICO:", get_font(14), fill=GREEN_ACCENT)
    draw_text(draw, (52, 376), "Al terminar la linea 5, Spid vuelve solo a la linea 2.", get_font(13), fill=WHITE_TEXT)
    draw_text(draw, (52, 400), "Repetira la rutina una y otra vez sin detenerse.", get_font(13), fill=WHITE_TEXT)
    draw_text(draw, (52, 424), "Atajo rapido: SHIFT + R ejecuta al instante.", get_font(13), fill=MUTED_TEXT)
    
    # Panel Derecho: Explicacion pedagógica
    draw_panel(draw, (495, 68, 940, 464))
    draw_text(draw, (515, 88), "¿COMO FUNCIONA EL BUCLE?", get_font(16), fill=GREEN_ACCENT)
    
    # Inset 1
    draw_inset(draw, (515, 114, 920, 208))
    draw_text(draw, (530, 132), "1. Trabajo continuo con while True:", get_font(15), fill=WHITE_TEXT)
    draw_text(draw, (530, 156), "Es una orden que repite tus instrucciones sin parar.", get_font(13), fill=MUTED_TEXT)
    draw_text(draw, (530, 178), "Spid no se detendra hasta cumplir la cuota.", get_font(13), fill=MUTED_TEXT)
    
    # Inset 2
    draw_inset(draw, (515, 222, 920, 316))
    draw_text(draw, (530, 240), "2. Regeneracion del mineral", get_font(15), fill=WHITE_TEXT)
    draw_text(draw, (530, 264), "La veta se regenera continuamente al norte.", get_font(13), fill=MUTED_TEXT)
    draw_text(draw, (530, 286), "Cada vez que Spid regresa, hay nuevo mineral listo.", get_font(13), fill=MUTED_TEXT)
    
    # Inset 3: ADA
    draw_inset(draw, (515, 330, 920, 446), fill=(28, 42, 36), border=GREEN_BORDER)
    draw_text(draw, (530, 350), "CONSEJO DE A.D.A.", get_font(14), fill=GREEN_ACCENT)
    draw_text(draw, (530, 374), "Programa a Spid para abastecer la nave nodriza.", get_font(13), fill=WHITE_TEXT)
    draw_text(draw, (530, 396), "Deja que complete al menos 2 ciclos de recoleccion.", get_font(13), fill=WHITE_TEXT)
    draw_text(draw, (530, 420), "Observa como aumenta el contador de la nave.", get_font(13), fill=GREEN_ACCENT)
    
    return image


def slide_2_2():
    """Fase 2 - Slide 2: Los Dos Puntos (:) y la Sangria (Tab)"""
    image, draw = create_base("FASE 2 // BUCLE WHILE", "PASO 2: LOS DOS PUNTOS (:) Y LA SANGRIA (TAB)")
    
    # Panel Izquierdo: Estructura visual con guia de sangria
    draw_panel(draw, (20, 68, 475, 464))
    draw_text(draw, (40, 88), "ESTRUCTURA VISUAL DEL BUCLE", get_font(16), fill=GREEN_ACCENT)
    
    draw_inset(draw, (38, 114, 456, 310), fill=INSET_BG, border=INSET_BORDER)
    
    # Encabezado del bucle
    draw_text(draw, (56, 136), "while True:", get_font(16), fill=GREEN_ACCENT)
    draw_chip(draw, (200, 128, 430, 154), "<- Dos puntos obligatorios (:)", fill=PANEL_BG, border=GREEN_BORDER, text_col=GREEN_ACCENT, font_size=12)
    
    # Linea de guia de sangria
    for y in range(166, 290, 4):
        draw.rectangle((82, y, 84, y + 2), fill=GREEN_ACCENT)
        
    draw_text(draw, (96, 172), "spid.norte()", get_font(15), fill=WHITE_TEXT)
    draw_text(draw, (96, 202), "spid.minar()", get_font(15), fill=WHITE_TEXT)
    draw_text(draw, (96, 232), "spid.sur()", get_font(15), fill=WHITE_TEXT)
    draw_text(draw, (96, 262), "spid.transferir()", get_font(15), fill=WHITE_TEXT)
    
    # Indicador de sangria
    draw_chip(draw, (270, 208, 440, 236), "<- Sangria con tecla TAB", fill=PANEL_BG, border=PANEL_BORDER, text_col=MUTED_TEXT, font_size=11)
    
    # Inset inferior
    draw_inset(draw, (38, 330, 456, 446), fill=INSET_BG, border=INSET_BORDER)
    draw_text(draw, (52, 350), "REGLA DE LA SANGRIA (ESPACIOS):", get_font(14), fill=GREEN_ACCENT)
    draw_text(draw, (52, 376), "Las ordenes con espacio a la izquierda estan", get_font(13), fill=WHITE_TEXT)
    draw_text(draw, (52, 398), "DENTRO del bucle y se repetiran continuamente.", get_font(13), fill=WHITE_TEXT)
    draw_text(draw, (52, 420), "Presiona TAB para indentar facilmente cada linea.", get_font(13), fill=MUTED_TEXT)
    
    # Panel Derecho: Reglas de Indentacion
    draw_panel(draw, (495, 68, 940, 464))
    draw_text(draw, (515, 88), "REGLAS DE IDENTACION", get_font(16), fill=GREEN_ACCENT)
    
    # Inset 1
    draw_inset(draw, (515, 114, 920, 208))
    draw_text(draw, (530, 132), "1. Los dos puntos al final (:)", get_font(15), fill=WHITE_TEXT)
    draw_text(draw, (530, 156), "La orden while True: siempre termina con dos puntos.", get_font(13), fill=MUTED_TEXT)
    draw_text(draw, (530, 178), "Indica el inicio del bloque que se va a repetir.", get_font(13), fill=MUTED_TEXT)
    
    # Inset 2
    draw_inset(draw, (515, 222, 920, 316))
    draw_text(draw, (530, 240), "2. Sangria con la tecla TAB", get_font(15), fill=WHITE_TEXT)
    draw_text(draw, (530, 264), "Presiona TAB al inicio de cada linea del bucle.", get_font(13), fill=MUTED_TEXT)
    draw_text(draw, (530, 286), "Asi el sistema sabe cuales ordenes debe repetir.", get_font(13), fill=MUTED_TEXT)
    
    # Inset 3
    draw_inset(draw, (515, 330, 920, 446), fill=(28, 42, 36), border=GREEN_BORDER)
    draw_text(draw, (530, 350), "¿QUE SE REPITE Y QUE NO?", get_font(14), fill=GREEN_ACCENT)
    draw_text(draw, (530, 374), "Solo las ordenes con sangria a la derecha se repiten.", get_font(13), fill=WHITE_TEXT)
    draw_text(draw, (530, 396), "Si una linea queda pegada al borde izquierdo,", get_font(13), fill=WHITE_TEXT)
    draw_text(draw, (530, 420), "queda fuera del bucle y no se repetira.", get_font(13), fill=MUTED_TEXT)
    
    return image


def slide_2_3():
    """Fase 2 - Slide 3: Errores Frecuentes en Bucles y Soluciones"""
    image, draw = create_base("FASE 2 // PREVENCION DE ERRORES", "PASO 3: ERRORES FRECUENTES EN BUCLES Y SOLUCIONES")
    
    errors = [
        (
            "ERROR 1: OLVIDAR LOS DOS PUNTOS (:)",
            "Escribir while True sin dos puntos al final de la linea.",
            "Agrega siempre dos puntos: while True:.",
            "while True:"
        ),
        (
            "ERROR 2: OLVIDAR LA SANGRIA (ESPACIOS)",
            "Escribir las ordenes pegadas al borde izquierdo sin espacio.",
            "Usa la tecla TAB para dar sangria a cada orden.",
            "    spid.norte()  # Con sangria TAB"
        ),
        (
            "ERROR 3: CIRCUITO INCOMPLETO (SIN RETORNO)",
            "Olvidar spid.sur() hace que Spid avance hacia el vacio.",
            "El ciclo debe volver a la base en cada vuelta.",
            "norte -> minar -> sur -> transferir"
        )
    ]
    
    y = 68
    for title, err_desc, sol_desc, good_code in errors:
        draw_panel(draw, (20, y, 940, y + 124))
        
        # Titulo del error
        draw_chip(draw, (36, y + 12, 360, y + 36), title, fill=INSET_BG, border=PANEL_BORDER, text_col=WHITE_TEXT, font_size=12)
        
        # Explicacion limpia sin desbordes
        draw_text(draw, (36, y + 54), f"• Problema: {err_desc}", get_font(13), fill=MUTED_TEXT)
        draw_text(draw, (36, y + 84), f"• Solucion: {sol_desc}", get_font(13), fill=WHITE_TEXT)
        
        # Bloque de orden correcta
        draw_inset(draw, (560, y + 34, 920, y + 88), fill=INSET_BG, border=GREEN_BORDER)
        draw_text(draw, (576, y + 48), "Correcto:", get_font(12), fill=MUTED_TEXT)
        draw_text(draw, (576, y + 68), good_code, get_font(14), fill=GREEN_ACCENT)
        
        y += 134
        
    return image


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    
    print("Renderizando tarjetas de Fase 0...")
    for idx, (fn, name) in enumerate([
        (slide_0_1, "consola"),
        (slide_0_2, "movimiento"),
        (slide_0_3, "ciclo")
    ], start=1):
        img = fn()
        out_file = OUT / f"fase0_{idx}_{name}.png"
        img.save(out_file, "PNG", optimize=True)
        print("  Generado:", out_file.name)

    print("Renderizando tarjetas de Fase 1...")
    for idx, (fn, name) in enumerate([
        (slide_1_1, "secuencia"),
        (slide_1_2, "corredor"),
        (slide_1_3, "errores")
    ], start=1):
        img = fn()
        out_file = OUT / f"fase1_{idx}_{name}.png"
        img.save(out_file, "PNG", optimize=True)
        print("  Generado:", out_file.name)

    print("Renderizando tarjetas de Fase 2...")
    for idx, (fn, name) in enumerate([
        (slide_2_1, "bucle"),
        (slide_2_2, "sangria"),
        (slide_2_3, "errores")
    ], start=1):
        img = fn()
        out_file = OUT / f"fase2_{idx}_{name}.png"
        img.save(out_file, "PNG", optimize=True)
        print("  Generado:", out_file.name)
        
    print("Todas las slides generadas exitosamente!")

