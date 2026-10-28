"""
Generador de tarjetas pedagógicas visuales (slides) para SpidoCode.
Renderiza tarjetas en alta calidad (960x480) con estética sci-fi limpia,
usando Consolas para código real y Segoe UI para textos legibles sin ruido visual.
"""

from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "tutorial"

# Tipografías del sistema y proyecto
FONT_PIXEL = ROOT / "assets" / "fonts" / "PixelifySans.ttf"
FONT_CODE_BOLD = Path("C:/Windows/Fonts/consolab.ttf")
FONT_CODE_REG = Path("C:/Windows/Fonts/consola.ttf")
FONT_UI_REG = Path("C:/Windows/Fonts/segoeui.ttf")
FONT_UI_BOLD = Path("C:/Windows/Fonts/segoeuib.ttf")
FONT_UI_SEMIBOLD = Path("C:/Windows/Fonts/segoeuisl.ttf")

W, H = 960, 480

# Paleta Sci-Fi refinada acorde a la UI del juego
BG_CANVAS = (24, 30, 40)          # Fondo base ventana (#181E28)
CARD_BG = (34, 43, 56)            # Superficie tarjeta (#222B38)
CARD_BORDER = (55, 68, 88)        # Borde sutil (#374458)
CARD_HEADER = (44, 55, 72)        # Cabecera de bloque (#2C3748)

INSET_BG = (17, 22, 30)           # Fondo código / terminal (#11161E)
INSET_BORDER = (42, 53, 70)       # Borde editor (#2A3546)

MINT_GREEN = (139, 203, 145)      # Verde menta neón (#8BCB91)
MINT_DARK = (70, 125, 82)         # Verde oscuro contorno
MINT_BG = (28, 50, 36)            # Chip fondo verde
MINT_HOVER = (165, 225, 172)

WHITE = (248, 250, 252)           # Texto principal (#F8FAFC)
TEXT_MUTED = (180, 192, 208)      # Texto secundario (#B4C0D0)
TEXT_DIM = (120, 134, 154)        # Números de línea / notas (#78869A)

WARN_RED = (248, 113, 113)        # Rojo alerta (#F87171)
WARN_BG = (55, 26, 30)            # Fondo error
WARN_BORDER = (140, 50, 60)

CYAN_GLOW = (96, 205, 225)        # Acento cian (#60CDE1)
CYAN_BG = (22, 45, 55)
YELLOW_ACCENT = (250, 204, 21)    # Amarillo entrega (#FACC15)


def f_title(size=22):
    return ImageFont.truetype(str(FONT_PIXEL), size)

def f_code(size=17, bold=True):
    p = str(FONT_CODE_BOLD if bold else FONT_CODE_REG)
    return ImageFont.truetype(p, size)

def f_body(size=15, bold=False):
    p = str(FONT_UI_BOLD if bold else FONT_UI_REG)
    return ImageFont.truetype(p, size)


def create_base(badge_text: str, title_text: str):
    image = Image.new("RGB", (W, H), BG_CANVAS)
    draw = ImageDraw.Draw(image)
    
    # Barra superior informativa del slide
    draw.rounded_rectangle((20, 14, 940, 54), radius=10, fill=CARD_BG, outline=CARD_BORDER, width=1)
    
    # Badge de fase / paso
    font_b = f_body(12, bold=True)
    b_box = font_b.getbbox(badge_text)
    b_w = (b_box[2] - b_box[0]) + 18
    draw.rounded_rectangle((30, 22, 30 + b_w, 46), radius=6, fill=MINT_BG, outline=MINT_DARK, width=1)
    draw.text((30 + b_w // 2, 34), badge_text, font=font_b, fill=MINT_GREEN, anchor="mm")
    
    # Título temático del slide
    draw.text((44 + b_w, 34), title_text, font=f_title(19), fill=WHITE, anchor="lm")
    
    return image, draw


def draw_card(draw, box, radius=14, fill=CARD_BG, outline=CARD_BORDER, width=1):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def draw_terminal(draw, box, lines, filename="main.py"):
    x1, y1, x2, y2 = box
    draw.rounded_rectangle(box, radius=12, fill=INSET_BG, outline=INSET_BORDER, width=1)
    # Pestaña de terminal
    tab_h = 28
    draw.rounded_rectangle((x1, y1, x2, y1 + tab_h), radius=12, fill=CARD_HEADER)
    draw.rectangle((x1, y1 + 14, x2, y1 + tab_h), fill=CARD_HEADER)
    # Dots
    draw.ellipse((x1 + 12, y1 + 9, x1 + 22, y1 + 19), fill=(239, 68, 68))
    draw.ellipse((x1 + 28, y1 + 9, x1 + 38, y1 + 19), fill=(245, 158, 11))
    draw.ellipse((x1 + 44, y1 + 9, x1 + 54, y1 + 19), fill=(34, 197, 94))
    draw.text((x1 + 68, y1 + 14), filename, font=f_code(12, False), fill=TEXT_MUTED, anchor="lm")
    
    y = y1 + tab_h + 18
    for num, code_str, comment in lines:
        draw.text((x1 + 26, y), str(num), font=f_code(15, False), fill=TEXT_DIM, anchor="rm")
        draw.text((x1 + 42, y), code_str, font=f_code(16, True), fill=WHITE, anchor="lm")
        if comment:
            draw.text((x2 - 16, y), f"# {comment}", font=f_code(13, False), fill=TEXT_MUTED, anchor="rm")
        y += 34


def draw_button(draw, box, text, icon="▶"):
    x1, y1, x2, y2 = box
    # Sombra sutil
    draw.rounded_rectangle((x1, y1 + 3, x2, y2 + 3), radius=10, fill=MINT_DARK)
    draw.rounded_rectangle(box, radius=10, fill=MINT_GREEN, outline=MINT_HOVER, width=1)
    full_text = f"{icon}  {text}"
    draw.text(((x1 + x2) // 2, (y1 + y2) // 2), full_text, font=f_body(15, bold=True), fill=(18, 30, 22), anchor="mm")


def draw_arrow_down(draw, x, y_start, y_end, color=MINT_GREEN, width=3, head_size=8):
    draw.line((x, y_start, x, y_end), fill=color, width=width)
    draw.polygon([(x, y_end + head_size), (x - head_size, y_end), (x + head_size, y_end)], fill=color)


# ==============================================================================
# FASE 0: PROTOCOLO DE INDUCCIÓN BÁSICA
# ==============================================================================

def slide_0_1():
    """Fase 0 - Slide 1: Escribir y Ejecutar Código"""
    image, draw = create_base("FASE 0 // INDUCCIÓN", "PASO 1: CONSOLA DE COMANDOS Y PRIMER CÓDIGO")
    
    # Panel Izquierdo: Editor + Botón Ejecutar
    draw_card(draw, (20, 68, 470, 464))
    draw.text((40, 92), "EDITOR DE CÓDIGO PYTHON", font=f_body(15, bold=True), fill=MINT_GREEN)
    
    lines = [
        ("1", "spid.minar()", "Extrae el mineral"),
        ("2", "spid.transferir()", "Entrega a la nave"),
    ]
    draw_terminal(draw, (40, 122, 450, 260), lines, filename="programa.py")
    
    draw_arrow_down(draw, 245, 274, 304, color=MINT_GREEN, width=3, head_size=8)
    draw.text((245, 324), "Presiona Ejecutar para enviar las órdenes a Spid", font=f_body(13, False), fill=TEXT_MUTED, anchor="mm")
    draw_button(draw, (90, 344, 400, 396), "EJECUTAR CÓDIGO", icon="▶")
    
    # Atajo de teclado en la base
    draw.rounded_rectangle((40, 414, 450, 448), radius=8, fill=INSET_BG, outline=INSET_BORDER, width=1)
    draw.text((54, 431), "Atajo de teclado:", font=f_body(13, False), fill=TEXT_MUTED, anchor="lm")
    draw.rounded_rectangle((180, 421, 255, 441), radius=4, fill=CARD_HEADER)
    draw.text((217, 431), "SHIFT + R", font=f_code(12, True), fill=WHITE, anchor="mm")
    draw.text((268, 431), "ejecuta al instante", font=f_body(13, False), fill=TEXT_MUTED, anchor="lm")
    
    # Panel Derecho: Reglas de Oro
    draw_card(draw, (490, 68, 940, 464))
    draw.text((510, 92), "REGLAS DE ORO EN PYTHON", font=f_body(15, bold=True), fill=MINT_GREEN)
    
    # Regla 1
    y = 126
    draw.rounded_rectangle((510, y, 920, y + 92), radius=10, fill=INSET_BG, outline=INSET_BORDER, width=1)
    draw.text((526, y + 16), "1. Escribe todo en minúsculas", font=f_body(15, bold=True), fill=WHITE)
    draw.text((526, y + 40), "Python distingue entre mayúsculas y minúsculas.", font=f_body(13, False), fill=TEXT_MUTED)
    draw.rounded_rectangle((526, y + 62, 650, y + 84), radius=4, fill=MINT_BG, outline=MINT_DARK, width=1)
    draw.text((588, y + 73), "spid.minar() ✔", font=f_code(12, True), fill=MINT_GREEN, anchor="mm")
    draw.rounded_rectangle((660, y + 62, 784, y + 84), radius=4, fill=WARN_BG, outline=WARN_BORDER, width=1)
    draw.text((722, y + 73), "Spid.Minar() ❌", font=f_code(12, True), fill=WARN_RED, anchor="mm")
    
    # Regla 2
    y = 232
    draw.rounded_rectangle((510, y, 920, y + 92), radius=10, fill=INSET_BG, outline=INSET_BORDER, width=1)
    draw.text((526, y + 16), "2. Paréntesis obligatorios ()", font=f_body(15, bold=True), fill=WHITE)
    draw.text((526, y + 40), "Cada método de Spid es una acción y requiere ().", font=f_body(13, False), fill=TEXT_MUTED)
    draw.rounded_rectangle((526, y + 62, 700, y + 84), radius=4, fill=(28, 40, 56))
    draw.text((613, y + 73), "Ejemplo: spid.transferir()", font=f_code(12, False), fill=CYAN_GLOW, anchor="mm")
    
    # Cuadro de ADA
    y = 338
    draw.rounded_rectangle((510, y, 920, y + 110), radius=10, fill=(28, 42, 35), outline=MINT_DARK, width=1)
    draw.text((526, y + 18), "💡 CONSEJO DE A.D.A.", font=f_body(14, bold=True), fill=MINT_GREEN)
    ada_text = (
        "En la primera misión, el mineral está justo debajo de Spid.\n"
        "Solo necesitas ejecutar minar() y luego transferir()."
    )
    draw.text((526, y + 44), ada_text, font=f_body(13, False), fill=WHITE, spacing=4)
    
    return image


def slide_0_2():
    """Fase 0 - Slide 2: Direcciones de Movimiento (Brújula HUD)"""
    image, draw = create_base("FASE 0 // INDUCCIÓN", "PASO 2: DIRECCIONES Y DESPLAZAMIENTO DEL SPID")
    
    # Panel Izquierdo: Brújula Espacial
    draw_card(draw, (20, 68, 510, 464))
    draw.text((40, 92), "BRÚJULA ESPACIAL // MANDOS DE NAVEGACIÓN", font=f_body(15, bold=True), fill=MINT_GREEN)
    
    # Contenedor HUD Brújula
    cx, cy = 265, 275
    draw.rounded_rectangle((40, 122, 490, 444), radius=12, fill=INSET_BG, outline=INSET_BORDER, width=1)
    # Círculo guía
    draw.ellipse((cx - 100, cy - 100, cx + 100, cy + 100), outline=(35, 48, 66), width=1)
    
    # Centro: SPID
    draw.rounded_rectangle((cx - 50, cy - 24, cx + 50, cy + 24), radius=8, fill=(44, 56, 75), outline=MINT_GREEN, width=2)
    draw.text((cx, cy), "SPID", font=f_title(18), fill=WHITE, anchor="mm")
    
    # NORTE (Arriba)
    draw.line((cx, cy - 26, cx, cy - 70), fill=MINT_GREEN, width=3)
    draw.polygon([(cx, cy - 78), (cx - 7, cy - 70), (cx + 7, cy - 70)], fill=MINT_GREEN)
    draw.rounded_rectangle((cx - 70, cy - 110, cx + 70, cy - 82), radius=6, fill=CARD_BG, outline=MINT_DARK, width=1)
    draw.text((cx, cy - 96), "spid.norte()", font=f_code(14, True), fill=MINT_GREEN, anchor="mm")
    
    # SUR (Abajo)
    draw.line((cx, cy + 26, cx, cy + 70), fill=MINT_GREEN, width=3)
    draw.polygon([(cx, cy + 78), (cx - 7, cy + 70), (cx + 7, cy + 70)], fill=MINT_GREEN)
    draw.rounded_rectangle((cx - 65, cy + 82, cx + 65, cy + 110), radius=6, fill=CARD_BG, outline=MINT_DARK, width=1)
    draw.text((cx, cy + 96), "spid.sur()", font=f_code(14, True), fill=MINT_GREEN, anchor="mm")
    
    # OESTE (Izquierda)
    draw.line((cx - 52, cy, cx - 96, cy), fill=MINT_GREEN, width=3)
    draw.polygon([(cx - 104, cy), (cx - 96, cy - 7), (cx - 96, cy + 7)], fill=MINT_GREEN)
    draw.rounded_rectangle((cx - 200, cy - 14, cx - 106, cy + 14), radius=6, fill=CARD_BG, outline=MINT_DARK, width=1)
    draw.text((cx - 153, cy), "spid.oeste()", font=f_code(13, True), fill=MINT_GREEN, anchor="mm")
    
    # ESTE (Derecha)
    draw.line((cx + 52, cy, cx + 96, cy), fill=MINT_GREEN, width=3)
    draw.polygon([(cx + 104, cy), (cx + 96, cy - 7), (cx + 96, cy + 7)], fill=MINT_GREEN)
    draw.rounded_rectangle((cx + 106, cy - 14, cx + 200, cy + 14), radius=6, fill=CARD_BG, outline=MINT_DARK, width=1)
    draw.text((cx + 153, cy), "spid.este()", font=f_code(13, True), fill=MINT_GREEN, anchor="mm")
    
    # Panel Derecho: Reglas de Movimiento
    draw_card(draw, (530, 68, 940, 464))
    draw.text((550, 92), "CÓMO DESPLAZARSE POR LA GRILLA", font=f_body(15, bold=True), fill=MINT_GREEN)
    
    y = 126
    draw.rounded_rectangle((550, y, 920, y + 80), radius=10, fill=INSET_BG, outline=INSET_BORDER, width=1)
    draw.text((566, y + 14), "• Cada orden avanza 1 casilla", font=f_body(15, bold=True), fill=WHITE)
    draw.text((566, y + 38), "Cada casilla mide 2 metros en el terreno 3D.\nSpid se detiene automáticamente en el centro de la celda.", font=f_body(13, False), fill=TEXT_MUTED)
    
    y = 218
    draw.rounded_rectangle((550, y, 920, y + 120), radius=10, fill=INSET_BG, outline=INSET_BORDER, width=1)
    draw.text((566, y + 14), "• Puedes encadenar pasos continuos:", font=f_body(15, bold=True), fill=WHITE)
    draw.rounded_rectangle((566, y + 42, 904, y + 104), radius=6, fill=(24, 32, 44))
    draw.text((582, y + 58), "spid.norte()", font=f_code(14, True), fill=MINT_GREEN)
    draw.text((582, y + 82), "spid.norte()", font=f_code(14, True), fill=MINT_GREEN)
    draw.text((740, y + 70), "# Avanza 2 casillas", font=f_code(12, False), fill=TEXT_MUTED)
    
    # Alerta base nave
    y = 350
    draw.rounded_rectangle((550, y, 920, y + 98), radius=10, fill=(35, 30, 45), outline=(90, 70, 110), width=1)
    draw.text((566, y + 16), "🛸 NAVE NODRIZA SIEMPRE AL SUR (0, 0)", font=f_body(14, bold=True), fill=CYAN_GLOW)
    draw.text((566, y + 40), "La casilla de inicio y transferencia está en la base (0, 0).\nSi avanzas al norte, regresarás ejecutando spid.sur().", font=f_body(13, False), fill=WHITE)
    
    return image


def slide_0_3():
    """Fase 0 - Slide 3: El Ciclo Completo de Recolección"""
    image, draw = create_base("FASE 0 // INDUCCIÓN", "PASO 3: EL CICLO COMPLETO DE MINERÍA Y TRANSFERENCIA")
    
    # 4 Pasos Horizontales / Bloques
    steps = [
        ("1", "NAVEGAR", "spid.norte()", ["Avanza hacia el", "cristal en el terreno."], MINT_GREEN),
        ("2", "EXTRAER", "spid.minar()", ["El taladro carga el", "mineral en la tolva."], CYAN_GLOW),
        ("3", "RETORNAR", "spid.sur()", ["Vuelve al sur a la", "casilla base (0, 0)."], MINT_GREEN),
        ("4", "ENTREGAR", "spid.transferir()", ["Descarga los recursos", "a la nave nodriza."], YELLOW_ACCENT),
    ]
    
    w_step = 215
    for idx, (num, name, cmd, lines_desc, col) in enumerate(steps):
        x1 = 20 + idx * 235
        x2 = x1 + w_step
        draw_card(draw, (x1, 68, x2, 280))
        
        # Header paso
        draw.rounded_rectangle((x1 + 10, 78, x1 + 42, 110), radius=6, fill=CARD_HEADER)
        draw.text((x1 + 26, 94), num, font=f_title(17), fill=col, anchor="mm")
        draw.text((x1 + 50, 94), name, font=f_body(14, bold=True), fill=WHITE, anchor="lm")
        
        # Chip de comando
        draw.rounded_rectangle((x1 + 12, 126, x2 - 12, 164), radius=6, fill=INSET_BG, outline=INSET_BORDER, width=1)
        draw.text(((x1 + x2) // 2, 145), cmd, font=f_code(13, True), fill=col, anchor="mm")
        
        # Descripción multilínea centrada con margen seguro
        y_text = 188
        for line in lines_desc:
            draw.text(((x1 + x2) // 2, y_text), line, font=f_body(12, False), fill=TEXT_MUTED, anchor="mm")
            y_text += 20
        
        # Flecha conectora gráfica poligonal (no depende de fuentes unicode)
        if idx < 3:
            arrow_x = x2 + 10
            arrow_y = 145
            draw.polygon([
                (arrow_x + 5, arrow_y),
                (arrow_x - 4, arrow_y - 6),
                (arrow_x - 4, arrow_y + 6)
            ], fill=MINT_GREEN)

    # Panel Inferior: Regla de Transferencia Obligatoria
    draw_card(draw, (20, 298, 940, 464))
    draw.rounded_rectangle((36, 314, 924, 448), radius=10, fill=INSET_BG, outline=INSET_BORDER, width=1)
    
    draw.rounded_rectangle((52, 330, 210, 356), radius=6, fill=(50, 35, 20), outline=(130, 90, 40), width=1)
    draw.text((131, 343), "REGLA OBLIGATORIA", font=f_body(12, bold=True), fill=YELLOW_ACCENT, anchor="mm")
    
    draw.text((52, 372), "La nave nodriza solo recibe recursos cuando Spid está exactamente en la CASILLA BASE (0, 0).", font=f_body(15, bold=True), fill=WHITE)
    draw.text((52, 402), "Si ejecutas spid.transferir() fuera de la base, el sistema de acople no alcanzará la nave y la entrega fallará.\nRecuerda la regla de oro: ¡Siempre regresa al sur antes de transferir!", font=f_body(13, False), fill=TEXT_MUTED)
    
    return image


# ==============================================================================
# FASE 1: SECUENCIA LINEAL (ORDEN ESTRICTO)
# ==============================================================================

def slide_1_1():
    """Fase 1 - Slide 1: Flujo Secuencial (Orden Estricto)"""
    image, draw = create_base("FASE 1 // SECUENCIA LINEAL", "FLUJO SECUENCIAL Y ORDEN DE EJECUCIÓN")
    
    # Panel Izquierdo: Secuencia Paso a Paso
    draw_card(draw, (20, 68, 480, 464))
    draw.text((40, 92), "ORDEN ESTRICTO DE EJECUCIÓN (4 PASOS)", font=f_body(15, bold=True), fill=MINT_GREEN)
    
    steps = [
        ("1", "spid.norte()", "Avanza hacia el mineral"),
        ("2", "spid.minar()", "Extrae la roca de cristal"),
        ("3", "spid.sur()", "Regresa a la base (0, 0)"),
        ("4", "spid.transferir()", "Descarga mineral a la nave"),
    ]
    
    y = 126
    for num, cmd, desc in steps:
        draw.rounded_rectangle((40, y, 460, y + 62), radius=10, fill=INSET_BG, outline=INSET_BORDER, width=1)
        # Número en badge
        draw.rounded_rectangle((52, y + 14, 84, y + 46), radius=6, fill=CARD_HEADER)
        draw.text((68, y + 30), num, font=f_title(16), fill=MINT_GREEN, anchor="mm")
        # Comando
        draw.text((98, y + 22), cmd, font=f_code(16, True), fill=WHITE)
        # Nota
        draw.text((98, y + 44), desc, font=f_body(12, False), fill=TEXT_MUTED)
        
        # Flechita vertical entre bloques
        if int(num) < 4:
            draw_arrow_down(draw, 68, y + 64, y + 74, color=MINT_GREEN, width=2, head_size=5)
        y += 76

    # Panel Derecho: Principios Pedagógicos
    draw_card(draw, (500, 68, 940, 464))
    draw.text((520, 92), "¿POR QUÉ EL ORDEN DETERMINA EL ÉXITO?", font=f_body(15, bold=True), fill=MINT_GREEN)
    
    y = 126
    draw.rounded_rectangle((520, y, 920, y + 90), radius=10, fill=INSET_BG, outline=INSET_BORDER, width=1)
    draw.text((536, y + 14), "1. Ejecución Secuencial Paso a Paso", font=f_body(15, bold=True), fill=WHITE)
    draw.text((536, y + 38), "Python procesa tu código línea a línea, exactamente de arriba a abajo.\nNo se salta líneas ni ejecuta dos órdenes al mismo tiempo.", font=f_body(13, False), fill=TEXT_MUTED)
    
    y = 228
    draw.rounded_rectangle((520, y, 920, y + 90), radius=10, fill=INSET_BG, outline=INSET_BORDER, width=1)
    draw.text((536, y + 14), "2. Consecuencia Causa - Efecto", font=f_body(15, bold=True), fill=WHITE)
    draw.text((536, y + 38), "No puedes transferir lo que aún no has minado, ni minar un yacimiento\nsi no estás parado sobre él. Cada línea depende del éxito de la anterior.", font=f_body(13, False), fill=TEXT_MUTED)
    
    # Cuadro de A.D.A.
    y = 330
    draw.rounded_rectangle((520, y, 920, y + 118), radius=10, fill=(28, 42, 35), outline=MINT_DARK, width=1)
    draw.text((536, y + 18), "💡 PROTOCOLO DE DEPURACIÓN DE A.D.A.", font=f_body(14, bold=True), fill=MINT_GREEN)
    ada_tip = (
        "Si Spid no completa la misión, no borres todo tu programa.\n"
        "Lee tu código de arriba a abajo y compáralo con el mapa:\n"
        "¿Dónde está Spid en cada línea? ¿Completó el retorno a la base?"
    )
    draw.text((536, y + 44), ada_tip, font=f_body(13, False), fill=WHITE, spacing=4)
    
    return image


def slide_1_2():
    """Fase 1 - Slide 2: El Corredor Lineal (1x3)"""
    image, draw = create_base("FASE 1 // SECUENCIA LINEAL", "EL CORREDOR LINEAL (1X3) Y CALIBRACIÓN DE RUTA")
    
    # Panel Izquierdo: Mapa Gráfico del Corredor
    draw_card(draw, (20, 68, 460, 464))
    draw.text((40, 92), "MAPA DEL SECTOR: CORREDOR 1X3", font=f_body(15, bold=True), fill=MINT_GREEN)
    
    draw.rounded_rectangle((40, 122, 440, 444), radius=12, fill=INSET_BG, outline=INSET_BORDER, width=1)
    
    # Casillas del mapa
    tiles = [
        (130, 146, 350, 206, "YACIMIENTO CRISTAL", "Casilla (0, 0, -2) // Depósito", (32, 60, 45), MINT_GREEN, "💎"),
        (130, 240, 350, 300, "CORREDOR LINEAL", "Casilla (0, 0, -1) // Tránsito", (28, 38, 52), TEXT_MUTED, "·"),
        (130, 334, 350, 394, "BASE NAVE NODRIZA", "Casilla (0, 0, 0) // Transferencia", (35, 45, 65), WHITE, "🛸"),
    ]
    
    for x1, y1, x2, y2, title, subt, bg, col, ico in tiles:
        draw.rounded_rectangle((x1, y1, x2, y2), radius=8, fill=bg, outline=(55, 75, 100), width=1)
        draw.text((x1 + 14, y1 + 12), f"{ico} {title}", font=f_body(13, bold=True), fill=col)
        draw.text((x1 + 14, y1 + 34), subt, font=f_code(11, False), fill=TEXT_DIM)
    
    # Flecha Norte (Ruta de Ida)
    draw.line((86, 364, 86, 176), fill=MINT_GREEN, width=3)
    draw.polygon([(86, 168), (80, 178), (92, 178)], fill=MINT_GREEN)
    draw.text((70, 270), "spid.norte()", font=f_code(12, True), fill=MINT_GREEN, anchor="rm")
    
    # Flecha Sur (Ruta de Retorno)
    draw.line((394, 176, 394, 364), fill=CYAN_GLOW, width=3)
    draw.polygon([(394, 372), (388, 362), (400, 362)], fill=CYAN_GLOW)
    draw.text((410, 270), "spid.sur()", font=f_code(12, True), fill=CYAN_GLOW, anchor="lm")
    
    draw.text((240, 420), "Distancia: 1 casilla al norte desde la base", font=f_body(12, False), fill=TEXT_MUTED, anchor="mm")
    
    # Panel Derecho: Guía de la Misión
    draw_card(draw, (480, 68, 940, 464))
    draw.text((500, 92), "CALIBRACIÓN DE RUTA: PASO A PASO", font=f_body(15, bold=True), fill=MINT_GREEN)
    
    steps = [
        ("1. Avanza al norte", "spid.norte()", "Spid sale de la nave y se posiciona directamente sobre el yacimiento."),
        ("2. Extrae el mineral", "spid.minar()", "El taladro se activa y guarda el cristal en la tolva del robot."),
        ("3. Regresa al sur", "spid.sur()", "Spid da marcha atrás y vuelve a la casilla base (0, 0)."),
        ("4. Transfiere la carga", "spid.transferir()", "Entrega el recurso a la nave nodriza completando la misión."),
    ]
    
    y = 126
    for title, cmd, desc in steps:
        draw.rounded_rectangle((500, y, 920, y + 72), radius=8, fill=INSET_BG, outline=INSET_BORDER, width=1)
        draw.text((516, y + 14), title, font=f_body(14, bold=True), fill=WHITE)
        draw.rounded_rectangle((670, y + 10, 810, y + 32), radius=4, fill=CARD_HEADER)
        draw.text((740, y + 21), cmd, font=f_code(12, True), fill=MINT_GREEN, anchor="mm")
        draw.text((516, y + 42), desc, font=f_body(12, False), fill=TEXT_MUTED)
        y += 82
        
    return image


def slide_1_3():
    """Fase 1 - Slide 3: Prevención de Errores Comunes"""
    image, draw = create_base("FASE 1 // PREVENCIÓN DE ERRORES", "LOS 3 ERRORES MÁS FRECUENTES Y CÓMO RESOLVERLOS")
    
    errors = [
        (
            "1. MINAR EN CASILLA VACÍA (SIN MINERAL)",
            "ERROR: Si ejecutas spid.minar() antes de pararte sobre el cristal, el taladro fallará.",
            "SOLUCIÓN: Avanza primero con spid.norte() para alcanzar el yacimiento antes de minar.",
            "spid.minar() ❌",
            "spid.norte() ➔ spid.minar() ✔"
        ),
        (
            "2. TRANSFERIR LEJOS DE LA NAVE NODRIZA",
            "ERROR: Spid solo puede transferir carga cuando está exactamente en la CASILLA BASE (0, 0).",
            "SOLUCIÓN: Regresa siempre con spid.sur() a la base antes de ejecutar spid.transferir().",
            "spid.transferir() en (0,-2) ❌",
            "spid.sur() ➔ spid.transferir() en (0,0) ✔"
        ),
        (
            "3. MAYÚSCULAS O PARÉNTESIS FALTANTES",
            "ERROR: Python es estricto: Spid no es spid, y olvidar los paréntesis () anula la orden.",
            "SOLUCIÓN: Escribe siempre los comandos en minúsculas y termina con ().",
            "Spid.norte  /  spid.norte ❌",
            "spid.norte() ✔"
        )
    ]
    
    y = 68
    for title, err_desc, sol_desc, bad_code, good_code in errors:
        draw_card(draw, (20, y, 940, y + 124))
        
        # Header error
        draw.rounded_rectangle((32, y + 12, 400, y + 36), radius=6, fill=WARN_BG, outline=WARN_BORDER, width=1)
        draw.text((44, y + 24), title, font=f_body(12, bold=True), fill=WARN_RED, anchor="lm")
        
        # Chips de código incorrecto vs correcto
        draw.rounded_rectangle((560, y + 12, 730, y + 36), radius=4, fill=(45, 25, 30))
        draw.text((645, y + 24), bad_code, font=f_code(12, True), fill=WARN_RED, anchor="mm")
        draw.rounded_rectangle((740, y + 12, 924, y + 36), radius=4, fill=MINT_BG, outline=MINT_DARK, width=1)
        draw.text((832, y + 24), good_code, font=f_code(12, True), fill=MINT_GREEN, anchor="mm")
        
        # Explicaciones
        draw.text((36, y + 54), f"• {err_desc}", font=f_body(13, False), fill=TEXT_MUTED)
        draw.text((36, y + 84), f"• {sol_desc}", font=f_body(13, bold=True), fill=WHITE)
        
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
        
    print("Todas las slides generadas exitosamente!")
