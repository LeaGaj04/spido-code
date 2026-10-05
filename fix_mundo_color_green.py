import re

with open('script/mundo.gd', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace(
    'material.albedo_color = Color(0.9, 0.7, 0.2, 0.25)',
    'material.albedo_color = Color(0.15, 0.45, 0.3, 0.4)'
)

content = content.replace(
    'material.emission = Color(0.9, 0.7, 0.2)',
    'material.emission = Color(0.15, 0.45, 0.3)'
)

# Keep the energy multiplier at 0.8
with open('script/mundo.gd', 'w', encoding='utf-8') as f:
    f.write(content)
