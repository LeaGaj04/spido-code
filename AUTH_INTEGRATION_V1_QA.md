# SpidoCode Auth Integration V1 — revisión local

## Actualización: activación del registro web (2026-10-29)

- Esta actualización sustituye el bloqueo de registro descrito en la evidencia histórica inferior. URL Preview validada manualmente por el usuario: https://educode-web-git-feat-spidocode-web-auth-educode3.vercel.app/registro.
- GAME configura WEB_SIGNUP_URL con ese destino exacto, sin credenciales ni tokens. Conserva la validación HTTPS y el manejo de errores; la apertura sigue usando OS.shell_open mediante un Callable sustituible en tests.
- Godot 4.7.2 headless: tests/test_web_signup_entry.gd PASS, exit 0. Comprueba destino exacto, éxito, error de apertura y ausencia de operaciones Supabase pendientes, sin inputs ni navegador real.
- La primera versión del doble mediante herencia falló al compilar por resolución del autoload Supabase; se corrigió utilizando carga diferida del script y sustitución del Callable. No es un fallo preexistente ni permanece en la prueba final.
- La apertura real del navegador queda pendiente de validación manual. No se probaron cuentas ni se modificaron WEB, Supabase o Vercel en esta activación. La recuperación conserva su configuración anterior.
- El usuario informó que registro web y sincronización Godot → Supabase → React pasaron una prueba manual real; esa evidencia no se reprodujo en esta ejecución.

## Evidencia histórica previa a la activación

Fecha: 2026-10-29. Sin commit, push, merge, deploy ni modificaciones de Supabase remoto.

## Preparación

- Landing: `educode_web_work`, limpia al inicio en `feat/spidocode-connected-codex`; seleccionada `feat/spidocode-web-auth` desde `origin/feat/spidocode-web-auth`, base `0cbc793` después de fetch.
- Juego: rama local `feat/web-signup-entry` desde `origin/main` actualizado, base `ef5e0b0`. No se modificó main.
- Rama previa del juego: `fix/restauracion-variables-retorno`. Tenía dos UID sin seguimiento; respaldados en `C:/Users/brand/AppData/Local/Temp/spidocode-auth-backup-20261029-162651`. Ambos coinciden por SHA256 con los archivos presentes en la nueva rama. No se perdió contenido local.

## Cambios

- Landing: `src/WebAuth.tsx`. Mínimo de contraseña solo para registro; login acepta la credencial existente sin imponer esa regla. Feedback distingue registro con sesión y confirmación pendiente. Acción posterior al registro dirige a login. Formulario anuncia estado ocupado con aria-busy.
- Juego: `script/auth.gd`. Registrarse no lee correo ni contraseña y no llama sign_up. Constante WEB_SIGNUP_URL vacía: muestra indisponibilidad sin abrir navegador. Al configurar una URL HTTPS pública previamente verificada, utiliza OS.shell_open y maneja errores, explicando el regreso manual al juego.
- Juego: `tests/test_web_signup_entry.gd`. Regresión del bloqueo sin inputs ni solicitud Supabase.
- Juego: este informe.

## Publicación y Auth

URL encontrada en `script/services/supabase.gd`: https://spidocode-web-amber.vercel.app/reset-password.
El origen y las rutas /registro, /login, /perfil y /reset-password devolvieron HTTP 404. /registro devuelve `DEPLOYMENT_NOT_FOUND`: Vercel no encuentra el deployment. No hay otra URL pública configurada en los archivos rastreados de la rama web revisada.

Por ello no existe una URL estable verificada para activar Registrarse. No se inventó un dominio ni se abrió ese enlace desde el juego.

Web y juego usan el mismo proyecto Supabase (comparación local sin imprimir credenciales). GET público /auth/v1/settings confirmó email_enabled=True, mailer_autoconfirm=False y disable_signup=False: registro habilitado y confirmación por correo requerida.

El registro reutiliza el cliente Supabase existente y el destino de confirmación configurado en servidor. No se cambió Site URL, allowlist ni plantillas; su destino final y entrega del correo no se verificaron con una cuenta real. Referencia: https://supabase.com/docs/reference/javascript/auth-signup.

Recuperación: código y escena conservados; la solicitud todavía usa el destino preexistente /reset-password, actualmente 404 público. El flujo completo de recuperación está bloqueado por publicación. La página local responde correctamente que falta sesión al abrirla sin token. No se enviaron correos de prueba.

## Evidencia QA

| Comprobación | Resultado |
| --- | --- |
| pnpm exec tsc --noEmit | PASS, exit 0 |
| pnpm run build | PASS, Vite 8.0.3, exit 0 |
| Visual /registro, /login y /perfil sin sesión | PASS, escritorio 1280 y móvil 390; campos y navegación visibles |
| Responsive registro y login | PASS, sin desborde horizontal en 390 px |
| Accesibilidad básica | PASS: labels, campos password, autocomplete, skip links, feedback con roles y foco CSS; no constituye auditoría WCAG completa |
| /docs local | PASS, Archivo A.D.A. visible |
| /reset-password local sin token | PASS, estado de enlace inválido |
| Godot test_parametros_variables.gd | PASS, 83 comprobaciones, exit 0 |
| Godot test_senales_en_vivo.gd | PASS, exit 0 |
| Godot test_web_signup_entry.gd | PASS, exit 0 |
| Godot test_restauracion_campana.gd | FAIL, exit 1: PASS=24, BUG CONFIRMADO=7, LEGADO=5, AMBIGUO=4; 163 comprobaciones |
| Publicación real /registro | FAIL, HTTP 404 DEPLOYMENT_NOT_FOUND |
| Login existente web y Godot | PENDIENTE: no se suministró cuenta/sesión para verificarlo; no se inventaron usuarios |
| Registro + recepción/confirmación de email | PENDIENTE: sin crear cuentas ni enviar correos no autorizados |
| git diff --check en ambos repositorios | PASS |

La suite de restauración señala cuatro invariantes unlocked_syntax, ID desconocido, misión actual incluida en completed_missions y dependencia de recursos previos de UI. Son casos de sistemas no modificados por esta integración; no se corrigieron ni se ocultaron. Las pruebas de campaña usan memoria y no escriben progreso remoto.

La inicialización inicial del editor en sandbox reportó errores de permisos en su configuración global; las suites se ejecutaron después con permisos normales y sus resultados se listan arriba. El servidor Vite ya estaba activo en localhost:8443; se reutilizó al detectar el puerto ocupado.

## Estado Git de entrega

Landing — `feat/spidocode-web-auth`:

```text
 M src/WebAuth.tsx
```

Juego — `feat/web-signup-entry`:

```text
 M script/auth.gd
?? tests/test_web_signup_entry.gd
?? AUTH_INTEGRATION_V1_QA.md
```

No se cambiaron escenas, guardado, progreso, claves ni el servicio Supabase. No hay retorno automático ni intercambio de tokens entre navegador y juego. La activación requiere publicación HTTPS real y verificación de /registro; después se debe completar QA con una cuenta existente y verificar confirmación/recuperación en el destino autorizado.
