# SPIDOCODE — GAME

Videojuego educativo en Godot 4 / GDScript. Carpeta de origen: rover-edu-code.

## Reglas compartidas de SPIDOCODE

- SPIDOCODE es un videojuego educativo integrado con una plataforma web.
- GAME (rover-edu-code) y WEB (educode_web_work) comparten Supabase Auth y player_progress.
- Mantener los dos repositorios Git completamente independientes.
- Preservar los cambios locales existentes. Revisar git status y la branch actual antes de implementar tareas.
- No ejecutar git reset --hard, git clean ni operaciones destructivas.
- No modificar Supabase remoto ni usar credenciales secretas.
- No crear usuarios reales o de prueba sin autorización.
- No hacer push, merge ni deploy sin autorización.
- Trabajar primero en los archivos relacionados con la tarea; ampliar la inspección cuando sea necesario.
- Validar los cambios de forma apropiada para la tarea y distinguir fallos previos de regresiones. Respetar las restricciones de validación indicadas por el usuario.
- Informar brevemente los resultados, las validaciones y el estado Git final de cada repositorio involucrado.
- Coordinar y documentar en español.

## Reglas de GAME

- Conservar project.godot, escenas, recursos, autoloads y servicios.
- Mantener compatibilidad con Godot 4 y GDScript.
- Respetar Auth, MissionService y ProgressService.
- No alterar la restauración de campaña fuera de tareas autorizadas.
- No modificar la estructura de progreso ni las misiones sin revisión.
- En integraciones web, no transmitir tokens ni contraseñas en URLs.
