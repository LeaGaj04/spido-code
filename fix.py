import re

with open('script/archivo_ada.gd', 'r', encoding='utf-8') as f:
    content = f.read()

content = re.sub(
    r'(\n\tbtn_organizacion\.pressed\.connect\(_cambiar_categoria\.bind\(\"Organizaci[^\"\)]*\"\)\))',
    r'\g<1>\n\tbtn_comandos.pressed.connect(_cambiar_categoria.bind("Comandos"))',
    content
)

content = re.sub(
    r'(\n\tbtn_organizacion\.modulate = Color\(1\.2, 1\.2, 1\.2\) if categoria == \"Organizaci[^\"\)]*\" else Color\(0\.7, 0\.7, 0\.7\))',
    r'\g<1>\n\tbtn_comandos.modulate = Color(1.2, 1.2, 1.2) if categoria == "Comandos" else Color(0.7, 0.7, 0.7)',
    content
)

with open('script/archivo_ada.gd', 'w', encoding='utf-8') as f:
    f.write(content)
