with open('escenas/archivo_ada.tscn', 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_lines = []
i = 0
while i < len(lines):
    line = lines[i]
    new_lines.append(line)
    if '[node name="BotonOrganizacion" type="Button"' in line:
        # Collect lines for this node until the next node
        node_lines = [line]
        i += 1
        while i < len(lines) and not lines[i].startswith('['):
            node_lines.append(lines[i])
            new_lines.append(lines[i])
            i += 1
        
        # Now create BotonComandos by replacing names
        for n_line in node_lines:
            mod_line = n_line.replace('BotonOrganizacion', 'BotonComandos').replace('[ ORGANIZACIÓN ]', '[ COMANDOS SPID ]')
            new_lines.append(mod_line)
        continue
    i += 1

with open('escenas/archivo_ada.tscn', 'w', encoding='utf-8', newline='\n') as f:
    f.writelines(new_lines)
