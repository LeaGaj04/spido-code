# Progresión Pedagógica y Fases de Aprendizaje — Spidocode

Documento oficial de seguimiento del currículo pedagógico de Python en *Spidocode*, diseño de misiones, requisitos de mapa, sintaxis desbloqueable y estado de avance.

---

## 1. Tabla Maestra de Avance por Fases

| Fase | Concepto Python | Expansión de Mapa | Desbloqueo de Sintaxis | Misiones del Juego | Estado |
| :---: | :--- | :--- | :--- | :--- | :---: |
| **1** | **Secuencia Lineal** | 1x1 (Base) $\rightarrow$ Corredor 1x3 | Comandos básicos (`norte`, `sur`, `este`, `oeste`, `minar`, `transferir`) | `recolectar_primer_mineral`<br>`ruta_calibracion` | **100%** |
| **2** | **Bucle `while`** | Corredor 1x3 (1 mineral) | `while`, comparación numérica (`<`, `<=`, `>`, `>=`, `==`) | `trabajo_continuo` (`while True`)<br>`cuota_suministro` (`while < 10`) | **100%** |
| **3** | **Condicionales `if / else`** | Sector 2x3 (10 minerales) | `if`, `else`, sensor `spid.hay_mineral()` | `senales_inciertas` (Patrulla y Plan B)<br>`comprar_mapa_3x3` | **100%** |
| **4** | **Bucle `for`** | Sector 2x3 (6 casillas) | `for`, `in range(N)` | `ciclo_recoleccion` | **100%** |
| **4.5** | **El Rover Autónomo** | Sector 2x3 (Consolidación) | Integración total de control: `while True:` + `for in range` + `if` | `patrulla_autonoma` | **100%** |
| **5** | **Parámetros y Variables** | Sector 3x3 (10 minerales) | Argumentos numéricos `spid.norte(2)`, variables `vueltas = 2`, `pasos = 2` | `comprar_sector_3x3`<br>`calibracion_variables` | **100%** |
| **5.5** | **Telemetría Dinámica** | Sector 3x3 | `spid.tamano_mundo()`, expresiones aritméticas `limite - 1` | `comprar_telemetria`<br>`telemetria_dinamica` | **100%** |
| **6** | **Listas y Colecciones** | Sector 4x3 (15 minerales) | Listas `ruta = ["norte", "este"]`, `spid.mover(dir)`, iteración `for d in lista:` | `comprar_sector_4x3`<br>`patrulla_lista` | **100%** |
| **6.5** | **Barrido Autónomo con Listas** | Sector 4x3 (Consolidación) | Integración total: `while True:` + listas `[...]` + `spid.mover(d)` + sensores `if` | `barrido_listas_autonomo` | **100%** |
| **7** | **Funciones (`def`)** | Sector 4x4 (20 minerales) | Definición e invocación de funciones `def nombre():`, modularización de rutinas | `comprar_sector_4x4`<br>`rutina_funciones` | **100%** |
| **7.5** | **Funciones con Parámetros** | Sector 5x4 (25 minerales) | `def nombre(param):`, invocación `nombre(arg)`, argumentos en rutinas | `comprar_sector_5x4`<br>`funciones_parametrizadas` | **100%** |
| **8** | **Barrido por Columnas** | Sector 5x5 (30 minerales) | Algoritmo de barrido bidimensional sistemático por columnas | `comprar_sector_5x5`<br>`barrido_columnas` | **100%** |
| **8.5** | **Protocolo Maestro Spido** | Sector 5x5 (Consolidación) | Barrido en zigzag con auto-descarga cuando tolva está llena (`spid.tiene_espacio()`) | `comprar_protocolo_maestro`<br>`protocolo_maestro` | **100%** |

---

## 2. Detalle de Diseño por Fase

### Fase 1: Secuencia Lineal (100% Completada)
* **Objetivo:** Comprender que un programa es una secuencia ordenada de instrucciones que la máquina ejecuta de arriba a abajo una sola vez.
* **Terreno:** Base inicial 1x1 y compra del Corredor 1x3 (Coste: 1 mineral).
* **Misiones:**
  1. `recolectar_primer_mineral`: Primer comando `spid.minar()`.
  2. `ruta_calibracion`: Secuencia lineal exacta: `spid.norte()`, `spid.minar()`, `spid.sur()`, `spid.transferir()`.

---

### Fase 2: Bucle `while` (100% Completada)
* **Objetivo:** Aprender automatización continua y detención controlada basada en condiciones lógicas.
* **Terreno:** Corredor 1x3.
* **Misiones:**
  1. `trabajo_continuo`:
     - *Consigna:* Automatización continua usando `while True:` para repetir la rutina al menos 2 ciclos completos.
     - *Código modelo:*
       ```python
       while True:
           spid.norte()
           spid.minar()
           spid.sur()
           spid.transferir()
       ```
  2. `cuota_suministro`:
     - *Consigna:* Detención automática con condición evaluada en tiempo de ejecución (`while spid.minerales_en_nave() < 10:`).
     - *Feedback inteligente:* Si el usuario ya tiene $\ge 10$ minerales en la nave, A.D.A. le explica que la condición `< 10` evaluó a `False` desde el inicio y le sugiere una meta superior (`< 15` o `< 20`).
  3. `comprar_casillas`:
     - *Consigna:* Acumular 10 minerales en la nave y adquirir la mejora **[ +3 CASILLAS ]** para expandir a Sector 2x3.

---

### Fase 3: Condicionales `if / else` (100% Completada)
* **Objetivo:** Aprender que el entorno es dinámico e impredecible: el rover debe censar con `if` antes de actuar y tomar un camino alternativo con `else:` cuando la condición no se cumpla.
* **Terreno:** Sector 2x3 (+3 casillas, spawns de mineral aleatorios entre casillas).
* **Desbloqueo orgánico:** Al comprar la expansión **[ +3 CASILLAS ]**, se instala automáticamente en la consola el firmware de **`if` y `else`**.
* **Diseño de Misión (`senales_inciertas`):**
  - Admite y valida dos enfoques complementarios:
    - **Enfoque A (Patrulla circular continua con `if`):**
      ```python
      while spid.minerales_en_nave() < 20:
          spid.norte()
          if spid.hay_mineral():
              spid.minar()
          spid.este()
          if spid.hay_mineral():
              spid.minar()
          spid.sur()
          if spid.hay_mineral():
              spid.minar()
          spid.sur()
          if spid.hay_mineral():
              spid.minar()
          spid.oeste()
          if spid.hay_mineral():
              spid.minar()
          spid.norte()
          if spid.hay_mineral():
              spid.minar()
          spid.transferir()
      ```
    - **Enfoque B (Bifurcación obligatoria con `if / else`):**
      ```python
      spid.norte()
      if spid.hay_mineral():
          spid.minar()
      else:
          spid.este()
          spid.minar()
          spid.oeste()
      spid.sur()
      spid.transferir()
      ```
* **Transición de salida:** Al completar la extracción condicional y transferencia, se desbloquea el hito de adquirir **[ CICLO FOR ]** (Coste: 20 minerales) en Mejoras para instalar el módulo `for` e `in range` en la consola.

---

### Fase 4: Bucle `for` (100% Completada)
* **Objetivo:** Aprender repetición acotada y exacta usando `for vuelta in range(N):` en situaciones con un número predeterminado de rondas o circuitos.
* **Terreno:** Sector 2x3 (6 casillas, terreno consolidado de la Fase 3).
* **Desbloqueo orgánico:** Módulo de `for` e `in range` disponible tras dominar los condicionales en Sector 2x3.
* **Mecánica del Circuito 2x3:**
  - Tres depósitos fijos se activan en el sector: Norte `(0, -1)`, Noreste `(1, -1)` y Este `(1, 0)`.
  - El rover parte en la base `(0, 0)`, recorre el circuito perimetral de 4 pasos minando en cada depósito, y regresa a la base al cerrar cada vuelta.
  - Al completar la ronda de 3 minerales, los depósitos se regeneran automáticamente para la siguiente vuelta del bucle `for`, garantizando cero errores de minado en casilla vacía.
  - El alumno automatiza el recorrido completo con `for vuelta in range(3):` y transfiere los minerales acumulados al final.
* **Misión:**
  - `ciclo_recoleccion`: Recorrido repetitivo del circuito de 3 depósitos con `for vuelta in range(3):` y transferencia final a la nave.

---

### Fase 5: Parámetros y Variables (Estructurada - 60%)
* **Objetivo:** Abstracción y parametrización de instrucciones en distancias largas.
* **Terreno:** Sector 3x3 (Cuadrante ampliado de 9 casillas adquirido en Mejoras).
* **Misiones:**
  1. `comprar_mapa_3x3`: Expansión al cuadrante de 9 casillas (Coste: 20 minerales).
  2. `camino_largo`: Uso de argumentos numéricos para cruzar el nuevo sector (`spid.norte(2)`).
  3. `variables`: Declaración y uso de variables dinámicas (`pasos = 2`, `spid.norte(pasos)`).

---

### Fase 7: Funciones (`def`) (100% Completada)
* **Objetivo:** Modularización y reutilización de código mediante funciones propias sin parámetros.
* **Terreno:** Sector 4x4 (16 casillas, expansión centrada $X \in [-1, 2], Z \in [-3, 0]$, Coste: 20 minerales).
* **Misiones:**
  1. `comprar_sector_4x4`: Expansión física a 4 de largo y desbloqueo de `def nombre():`.
  2. `rutina_funciones`: Definición de función modular y su invocación en bucle para recolectar y transferir 4 minerales.

---

### Fase 7.5: Sector 5x4 y Funciones con Parámetros (100% Completada)
* **Objetivo:** Generalización y parametrización de rutinas usando argumentos en funciones (`def nombre(param):`).
* **Terreno:** Sector 5x4 (20 casillas, expansión en ancho $X \in [-2, 2], Z \in [-3, 0]$, base en $(0,0,0)$, Coste: 25 minerales).
* **Misiones:**
  1. `comprar_sector_5x4`: Expansión física a 5 de ancho y desbloqueo de `def nombre(param):`.
  2. `funciones_parametrizadas`: Creación de funciones configurables (ej. `def mover_y_recolectar(direccion):`) invocadas con argumentos dentro de un bucle perimetral para recolectar y transferir 5 minerales.

---

### Fase 8: Sector 5x5 y Barrido por Columnas (100% Completada)
* **Objetivo:** Abandono definitivo de la patrulla perimetral e implementación de un barrido bidimensional sistemático por columnas para limpiar el interior del mapa.
* **Terreno:** Sector 5x5 (25 casillas cuadradas completas, $X \in [-2, 2], Z \in [-4, 0]$, base en $(0,0,0)$, Coste: 30 minerales).
* **Misiones:**
  1. `comprar_sector_5x5`: Expansión física a cuadrante completo de 5 de largo y desbloqueo del protocolo de barrido bidimensional.
  2. `barrido_columnas`: Modularización del movimiento en columnas (ej. `censar_y_avanzar(direccion, pasos)`), cubriendo al menos dos columnas completas (subiendo y bajando) y transfiriendo al menos 6 minerales a la nave.

---

### Fase 8.5: Protocolo Maestro Spido (100% Completada - Endgame)
* **Objetivo:** Meta definitiva del currículo didáctico de *SpidoCode*: construcción del Rover Autónomo de Exploración Minera mediante barrido sistemático bidimensional en zigzag por todo el cuadrante con descarga autónoma.
* **Terreno:** Sector 5x5 (25 casillas cuadradas completas).
* **Misiones:**
  1. `comprar_protocolo_maestro`: Adquisición de la mejora final en Tienda (Coste: 35 minerales) para habilitar el sensor de tolva `spid.tiene_espacio()`.
  2. `protocolo_maestro`: Despliegue de automatización continua 100% desatendida combinando bucles `while True:`, `for in range`, funciones parametrizadas `def`, sensores `if spid.hay_mineral():` y control de carga con transferencia acumulativa (mínimo 8 minerales transferidos a la nave).

---

## 3. Registro de Decisiones de Diseño Aprobadas

1. **Sintaxis vinculada a expansiones de terreno (04/10/2026):**
   - En lugar de comprar sintaxis abstracta en la tienda como un ítem flotante, la sintaxis viene preinstalada con la expansión física del mapa donde tiene sentido aplicarla:
     - Sector 2x3 $\rightarrow$ Desbloquea `if` y `else`.
     - Sector 3x3 $\rightarrow$ Desbloquea parámetros y variables.
2. **Reorganización pedagógica de bucles:**
   - Se descartó el orden antiguo donde `for` aparecía antes que `while`.
   - Se estableció: `while` continuo $\rightarrow$ `while` con cuota $\rightarrow$ `if / else` $\rightarrow$ `for in range`.
3. **Parser tolerante a sangrías leves (`code_executor.gd`):**
   - El compilador detecta el fin de un bloque `if` o `else` cuando la línea siguiente tiene una sangría menor que la del cuerpo del bloque (previniendo que espacios accidentales absorban instrucciones posteriores).
4. **Consulta de minerales en vivo:**
   - El servicio de misiones consulta directamente el contador en vivo de la nave (`interfaz.minerales_nave`) evitando desincronizaciones de caché con Supabase o partidas de invitados.
5. **Ejecución completa de bucles `for` en `range(N)` (06/10/2026):**
   - Se eliminó `ciclo_recoleccion` del auto-corte prematuro tras 1 mineral transferido en `code_executor.gd`. Los bucles `for` deben ejecutar siempre la totalidad de las iteraciones fijadas por el estudiante en `range(N)` para cumplir con el requisito de minerales recolectados y transferidos.
6. **Bucle `for` en Sector 2x3 con circuito cerrado (24/10/2026):**
   - Para evitar sobrecargar al estudiante con una expansión de mapa al mismo tiempo que aprende una nueva estructura de control (`for`), la Fase 4 se consolida sobre el Sector 2x3 ya conocido. El rover ejecuta un circuito cerrado de 4 pasos (`norte` -> `este` -> `sur` -> `oeste`) con regeneración automática de depósitos, reservando la expansión al Sector 3x3 para la Fase 5 (donde se justifica plenamente el uso de parámetros como `spid.norte(2)` o `spid.norte(3)`).

---

*Nota: Cualquier nueva regla, ajuste a las misiones o definición pedagógica futura debe registrarse directamente en este documento.*
