import re

with open('script/mundo.gd', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace(
    'resaltador.position = centro_local + Vector3(0, 0.02, 0)',
    'resaltador.position = centro_local + Vector3(0, 0.11, 0)'
)

content = content.replace(
    'material.albedo_color = Color(0.2, 0.8, 0.3, 0.35)',
    'material.albedo_color = Color(0.0, 0.8, 1.0, 0.45)' # Cyan semitransparent
)

content = content.replace(
    'material.emission = Color(0.2, 0.8, 0.3)',
    'material.emission = Color(0.0, 0.8, 1.0)' # Cyan emission
)

content = content.replace(
    'material.emission_energy_multiplier = 1.5',
    'material.emission_energy_multiplier = 3.0' # Much brighter
)

with open('script/mundo.gd', 'w', encoding='utf-8') as f:
    f.write(content)
