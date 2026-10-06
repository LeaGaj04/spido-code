with open('escenas/archivo_ada.tscn', 'r', encoding='utf-8') as f:
    lines = f.readlines()

out_lines = []
i = 0
fundamentos_idx = -1
comandos_lines = []

while i < len(lines):
    line = lines[i]
    if line.startswith('[node name="BotonFundamentos"'):
        fundamentos_idx = len(out_lines)
    
    if line.startswith('[node name="BotonComandos"'):
        # Collect all lines for BotonComandos until HSeparator
        while i < len(lines) and not lines[i].startswith('[node name="HSeparator"'):
            comandos_lines.append(lines[i])
            i += 1
        continue
    
    out_lines.append(line)
    i += 1

# Insert comandos before fundamentos
if fundamentos_idx != -1 and comandos_lines:
    out_lines = out_lines[:fundamentos_idx] + comandos_lines + out_lines[fundamentos_idx:]

with open('escenas/archivo_ada.tscn', 'w', encoding='utf-8', newline='\n') as f:
    f.writelines(out_lines)
