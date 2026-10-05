import re

with open('script/mundo.gd', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace(
    'material.albedo_color = Color(0.0, 0.8, 1.0, 0.45)',
    'material.albedo_color = Color(0.9, 0.7, 0.2, 0.25)' # Soft gold/orange
)

content = content.replace(
    'material.emission = Color(0.0, 0.8, 1.0)',
    'material.emission = Color(0.9, 0.7, 0.2)'
)

content = content.replace(
    'material.emission_energy_multiplier = 3.0',
    'material.emission_energy_multiplier = 0.8' # Much softer
)

with open('script/mundo.gd', 'w', encoding='utf-8') as f:
    f.write(content)
