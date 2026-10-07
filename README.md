<img width="1431" height="836" alt="2" src="https://github.com/user-attachments/assets/b6b3ccbd-2195-4cfb-8b71-affba48e10bc" />

<img width="1436" height="833" alt="1" src="https://github.com/user-attachments/assets/90dd54d5-7a4c-4e72-9d96-04954db64601" />


# spidocode

<div align="center">
         
![Godot Engine](https://img.shields.io/badge/Godot_4.x-478CBF?style=for-the-badge&logo=godot-engine&logoColor=white)
![GDScript](https://img.shields.io/badge/GDScript-355570?style=for-the-badge&logo=godot-engine&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase_BaaS-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![Game Design](https://img.shields.io/badge/Game_Design-FF6B6B?style=for-the-badge)
![POO & Algorithms](https://img.shields.io/badge/Pedagogía-POO_y_Algoritmia-orange?style=for-the-badge)
![Scrum](https://img.shields.io/badge/Metodología-Scrum-blueviolet?style=for-the-badge)

</div>

---

## Problematica
La enseñanza tradicional de la programación a menudo se enfrenta a una barrera crítica: **la abstracción excesiva**. Los estudiantes principiantes experimentan altas tasas de frustración y deserción al enfrentarse a conceptos teóricos como la **Programación Orientada a Objetos (POO)** y las estructuras de control sin una retroalimentación visual e interactiva en tiempo real.

## Solución: SpidoCode
**SpidoCode** transforma el aprendizaje algorítmico en una experiencia gamificada e inmersiva. A través del control de un **Spid minero espacial en un entorno 3D**, los estudiantes aplican sintaxis real de programación para resolver misiones, recolectar recursos y sobrevivir. Cada comando escrito se refleja visual y físicamente en el motor de juego, haciendo que conceptos como objetos, métodos con parámetros, bucles y condicionales se asimilen de forma intuitiva e inmediata.

---

## Gameplay Loop y Progresión Pedagógica
El juego sigue un bucle de progresión diseñado para guiar al estudiante desde los conceptos básicos de programación secuencial hasta la automatización autónoma:

```text
Escribir Código (IDE) ──► Ejecución & Sensores (3D) ──► Minar Recursos (Spid)
         ▲                                                     │
         │                                                     ▼
Nuevas Misiones / Retos ◄── Desbloquear Sintaxis / Expansión ◄── Transferir a la Nave
```
---

# Arquitectura del Sistema
El proyecto "SpidoCode" está estructurado bajo una arquitectura modular dividida en cuatro pilares principales, garantizando un rendimiento fluido y una separación de responsabilidades clara:

Núcleo Lógico y Analizador Léxico (Parser): Es el cerebro del sistema. Se encarga de capturar el texto ingresado por el usuario, realizar el análisis léxico para validar la sintaxis de Programación Orientada a Objetos (exigiendo la notación de punto, por ejemplo: mi_spid.avanzar()) y traducir estas instrucciones en comandos procesables por el motor. Además, incorpora un sistema de seguridad algorítmica (timeout) para aislar la ejecución y evitar que bucles infinitos accidentales congelen la aplicación.

Motor Gráfico y Físicas 3D: Desarrollado nativamente en Godot Engine. Este módulo gestiona el entorno visual y las colisiones del juego. Utiliza un sistema basado en cuadrículas modulares (GridMap) para generar el terreno del asteroide y un controlador físico de cinemática (CharacterBody3D) para gestionar los desplazamientos y las interacciones del Spid minero en tiempo real.

Interfaz de Usuario (UI) y Gamificación: Actúa como el puente interactivo entre el jugador y la lógica subyacente. Incluye un Entorno de Desarrollo Integrado (IDE) in-game construido para procesar código y ofrecer resaltado de sintaxis, junto con paneles dinámicos de "Inspector POO" que reflejan visualmente el cambio de estado de los objetos. También gestiona la lógica de la tienda y el inventario del usuario.

Backend y Cloud Computing: Es la capa de infraestructura externa gestionada mediante Backend as a Service (Supabase/Firebase). Se encarga de la autenticación segura de los usuarios y utiliza bases de datos no relacionales para garantizar la persistencia asíncrona del progreso del jugador (guardando el inventario de minerales, los niveles superados y los fragmentos de código desbloqueados) sin interrumpir el flujo del juego.


---

# Tecnología Usada (Tech Stack)
Para garantizar que el proyecto mantenga un rendimiento óptimo tanto en el procesamiento lógico como en el renderizado gráfico, SpidoCode está construido utilizando herramientas especializadas y open-source:

Motor de Videojuegos: Godot Engine (v4.x - Estándar). Elegido por su arquitectura nativa orientada a objetos (nodos) y su ligereza.

Lenguaje de Scripting: GDScript. Utilizado para el desarrollo general del juego y para programar el analizador léxico (Parser) interno del jugador.

Nodos Clave: GridMap (para el entorno modular) y CharacterBody3D (para las físicas del Spid).

Interfaz y Entorno (IDE In-Game): Nodos TextEdit nativos de Godot, configurados con CodeHighlighter para ofrecer una experiencia real de resaltado de sintaxis, numeración de líneas y menús desplegables.

Backend y Persistencia (Nube): Supabase. Seleccionados como infraestructura Backend as a Service (BaaS).

Base de Datos: No relacional (estructuras JSON) para almacenar asíncronamente el progreso, inventario y sintaxis desbloqueada de los usuarios sin interrumpir el Gameplay Loop.


Control de Versiones y Despliegue: Git y GitHub para el repositorio del equipo , junto con GitHub Desktop para facilitar la integración continua. La Landing Page promocional será desplegada mediante hosting gratuito como  Vercel

---

# Mapa de Carpetas
### Para facilitar la lectura y escalabilidad del código bajo la metodología Scrum, el proyecto en Godot está estructurado de la siguiente manera:

```text
spidocode/
├── assets/                  # Recursos gráficos, fuentes y materiales
├── Fondos/                  # Texturas de ambiente y fondo espacial
├── Minerales/               # Modelos y texturas de yacimientos minerales
├── Modelados3D/             # Modelos 3D del Spid, la Nave y props
├── escenas/                 # Nodos y escenas principales de Godot (.tscn)
│   ├── mundo.tscn           # Escena principal con GridMap, iluminación y cámara
│   ├── spid.tscn           # Escena del vehículo del jugador (CharacterBody3D)
│   ├── nave.tscn            # Base de operaciones y punto de transferencia
│   ├── mineral.tscn         # Objeto recolectable con colisiones
│   ├── menu_inicio.tscn     # Pantalla principal con acceso a juego y opciones
│   ├── auth.tscn            # Pantalla de autenticación y registro con Supabase
│   ├── archivo_ada.tscn     # Panel del Códice pedagógico de POO
│   └── transmision_ada.tscn # Avatar y panel de transmisión de la IA A.D.A.
├── script/                  # Lógica del juego en GDScript
│   ├── spid.gd             # Métodos del vehículo: movimiento, minería y sensores
│   ├── mundo.gd             # Generación procedimental de minerales y expansión del mapa
│   ├── interfaz.gd          # UI in-game, gestión del IDE, inventarios y tienda
│   ├── archivo_ada.gd       # Diccionario pedagógico y lógica del Códice POO
│   ├── transmision_ada.gd   # Sistema de mensajes y feedback reactivo de A.D.A.
│   ├── lexer.gd             # Análisis léxico y tokenización de código
│   ├── auth.gd              # Controlador de login y registro de usuarios
│   └── services/            # Autoloads y servicios centrales del sistema
│       ├── code_executor.gd # Ejecutor e intérprete seguro de instrucciones
│       ├── gestor_sintaxis.gd# Control de sintaxis permitida y validación
│       ├── mission_service.gd# Máquina de estados de misiones y evaluación
│       ├── progress_service.gd# Serialización y guardado de progreso en nube
│       └── supabase.gd      # Cliente REST / BaaS de Supabase
├── documentos/              # Especificaciones de diseño y guías de jugabilidad
└── project.godot            # Archivo de configuración central del motor Godot
```

---

# Metodología y Sprints de Desarrollo
El desarrollo de SpidoCode se gestiona bajo el marco de trabajo ágil Scrum. Para garantizar un avance fluido y evitar cuellos de botella técnicos, el proyecto se estructuró dividiendo la arquitectura en áreas aisladas, trabajando en Sprints de desarrollo.

La asignación de responsabilidades y la ejecución real de los primeros Sprints se han distribuido de la siguiente manera para levantar el Producto Mínimo Viable (MVP):

Sprint Lógico y Entorno 3D: Encargado de la inicialización del repositorio base. Comprende la creación del entorno isométrico (GridMap), el desarrollo físico del Spid y el hito crítico de conectar el analizador léxico (Parser) con el modelo 3D para que el vehículo responda a las instrucciones de código. (Fase completada)

Sprint de Interfaz (UI) y Navegación: Encargado de la capa visual del usuario fuera del gameplay. Comprende el desarrollo y diseño de la interfaz de menús principales, habilitando la navegación funcional entre las pantallas de "Jugar", "Configuraciones" y "Salir". (Fase completada)

Sprint de Cloud e Infraestructura: Encargado de la arquitectura de red. Comprende la configuración y conexión exitosa del proyecto en Godot con el entorno de Supabase, preparando el terreno para la autenticación y bases de datos. (Fase completada)

Próximos Sprints (Backlog actual): El equipo se enfocará en las mecánicas de gamificación (recolección de minerales), la validación de condiciones de victoria y la persistencia asíncrona de datos en la nube (guardado de progreso).

---
