import re

with open('script/mundo.gd', 'r', encoding='utf-8') as f:
    content = f.read()

# Add the function call to _resaltar_casilla_principal() at the end of _posicionar_spid_en_casilla_inicial()
# wait, it's better to call it in _ready() after _posicionar_spid_en_casilla_inicial()

call_code = "\t_posicionar_spid_en_casilla_inicial()\n\t_resaltar_casilla_principal()"
content = content.replace("\t_posicionar_spid_en_casilla_inicial()", call_code)

func_code = """
func _resaltar_casilla_principal() -> void:
	var resaltador = grid_map.get_node_or_null("ResaltadorBase")
	if resaltador == null:
		resaltador = MeshInstance3D.new()
		resaltador.name = "ResaltadorBase"
		var malla = PlaneMesh.new()
		malla.size = Vector2(1.8, 1.8)
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.2, 0.8, 0.3, 0.35)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.emission_enabled = true
		material.emission = Color(0.2, 0.8, 0.3)
		material.emission_energy_multiplier = 1.5
		malla.material = material
		resaltador.mesh = malla
		grid_map.add_child(resaltador)
	
	var centro_local = grid_map.map_to_local(CASILLA_INICIAL)
	resaltador.position = centro_local + Vector3(0, 0.02, 0)
"""

content += "\n" + func_code

with open('script/mundo.gd', 'w', encoding='utf-8') as f:
    f.write(content)
