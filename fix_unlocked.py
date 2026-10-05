with open('script/archivo_ada.gd', 'r', encoding='utf-8') as f:
    content = f.read()

# Change default category to Comandos
content = content.replace('var categoria_actual: String = "Fundamentos"', 'var categoria_actual: String = "Comandos"')
content = content.replace('var concepto_actual_id: String = "objeto"', 'var concepto_actual_id: String = "movimiento"')

# Make Comandos unlocked by default
# In _poblar_lista_conceptos:
# var esta_desbloqueado = id_clave in conocimientos_desbloqueados
content = content.replace(
    'var esta_desbloqueado = id_clave in conocimientos_desbloqueados',
    'var esta_desbloqueado = id_clave in conocimientos_desbloqueados or datos["categoria"] == "Comandos"'
)

# In _seleccionar_concepto:
# var esta_desbloqueado = id_clave in MissionService.get_unlocked_knowledge()
# and
# var desbloq = clave in MissionService.get_unlocked_knowledge()
content = content.replace(
    'var esta_desbloqueado = id_clave in MissionService.get_unlocked_knowledge()',
    'var esta_desbloqueado = id_clave in MissionService.get_unlocked_knowledge() or datos.get("categoria", "") == "Comandos"'
)

content = content.replace(
    'var desbloq = clave in MissionService.get_unlocked_knowledge()',
    'var desbloq = clave in MissionService.get_unlocked_knowledge() or CONOCIMIENTOS.get(clave, {}).get("categoria", "") == "Comandos"'
)

with open('script/archivo_ada.gd', 'w', encoding='utf-8') as f:
    f.write(content)
