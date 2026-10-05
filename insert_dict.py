import re

with open('script/archivo_ada.gd', 'r', encoding='utf-8') as f:
    content = f.read()

new_entries = """	},
	"movimiento": {
		"nombre": "Movimiento",
		"categoria": "Comandos",
		"descripcion": "Ordena al Spid desplazarse por la cuadrícula del mapa. Recibe de forma opcional el número de casillas a avanzar como parámetro.",
		"sintaxis": "spid.norte([pasos])\nspid.sur([pasos])\nspid.este([pasos])\nspid.oeste([pasos])",
		"ejemplo": "spid.norte()   # Avanza 1 casilla\\nspid.sur(2)    # Avanza 2 casillas",
		"errores": "Chocar con los límites del mapa o ingresar parámetros no numéricos."
	},
	"acciones": {
		"nombre": "Minería y Transferencia",
		"categoria": "Comandos",
		"descripcion": "Acciones principales para interactuar con los recursos del entorno y completar las cuotas de recolección.",
		"sintaxis": "spid.minar()\nspid.transferir()",
		"ejemplo": "spid.minar()\nspid.sur()\nspid.transferir()",
		"errores": "Intentar minar cuando no hay minerales o el inventario está lleno. Intentar transferir fuera de la base."
	},
	"sensores": {
		"nombre": "Sensores del Spid",
		"categoria": "Comandos",
		"descripcion": "El Spid cuenta con sensores integrados para evaluar su entorno y estado. Devuelven un valor verdadero (True/False) o un número.",
		"sintaxis": "spid.hay_mineral()\nspid.tiene_espacio()\nspid.en_base()\nspid.minerales_en_rover()\nspid.minerales_en_nave()",
		"ejemplo": "if spid.hay_mineral():\n    spid.minar()",
		"errores": "Olvidar los paréntesis al llamar al sensor, o usar un sensor fuera de una condición o evaluación."
	}
}"""

content = content.replace('\t}\n}', new_entries)

with open('script/archivo_ada.gd', 'w', encoding='utf-8') as f:
    f.write(content)
