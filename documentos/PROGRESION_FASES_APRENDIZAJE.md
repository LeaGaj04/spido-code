# Progresión Pedagógica y Fases de Aprendizaje — Spidocode

Documento oficial de seguimiento del currículo pedagógico de Python en *Spidocode*, diseño de misiones, requisitos de mapa, sintaxis desbloqueable y estado de avance.

---

## 1. Tabla Maestra de Avance por Fases

| Fase | Concepto Python | Expansión de Mapa | Desbloqueo de Sintaxis | Misiones del Juego | Estado |
| :---: | :--- | :--- | :--- | :--- | :---: |
| **1** | **Secuencia Lineal** | 1x1 (Base) $\rightarrow$ Corredor 1x3 | Comandos básicos (`norte`, `sur`, `este`, `oeste`, `minar`, `transferir`) | `recolectar_primer_mineral`<br>`ruta_calibracion` | **100%** |
| **2** | **Bucle `while`** | Corredor 1x3 (1 mineral) | `while`, comparación numérica (`<`, `<=`, `>`, `>=`, `==`) | `trabajo_continuo` (`while True`)<br>`cuota_suministro` (`while < 10`) | **100%** |
| **3** | **Condicionales `if / else`** | Sector 2x3 (10 minerales) | `if`, `else`, sensor `spid.hay_mineral()` | `senales_inciertas` (Patrulla y Plan B)<br>`comprar_mapa_3x3` | **100%** |
| **4** | **Bucle `for`** | Sector 3x3 (20 minerales) | `for`, `in range(N)` | `ciclo_recoleccion`<br>`exploracion_3x3` | **Planificado (70%)** |
| **5** | **Parámetros y Variables** | Sector 3x3 | Argumentos numéricos `spid.norte(2)`, variables `pasos = 2` | `camino_largo`<br>`variables` | **Planificado (60%)** |
| **6** | **Listas y Colecciones** | Sector 3x3 / Terreno abierto | Listas `rutas = ["norte", "este"]`, indexación | *Por definir* | **Pendiente** |
| **7** | **Funciones (`def`)** | Sector ampliado | `def patrullar():`, `return` | *Por definir* | **Pendiente** |
| **8** | **Módulos e `import`** | Módulos de Rover | `import`, modularización de rutinas | *Por definir* | **Pendiente** |
| **9** | **Algoritmos / Endgame** | Todo el mapa | Algoritmos de ordenamiento, optimización de batería y pureza | *Por definir* | **Pendiente** |

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
* **Transición de salida:** Al completar la extracción condicional y transferencia, se desbloquea el hito de adquirir **[ SECTOR 3X3 ]** (Coste: 20 minerales).

---

### Fase 4: Bucle `for` (Estructurada - 70%)
* **Objetivo:** Aprender repetición acotada y barridos con número determinado de iteraciones usando `for ciclo in range(N):`.
* **Terreno:** Sector 3x3 (Cuadrante ampliado de 9 casillas con 3 depósitos simultáneos).
* **Desbloqueo orgánico:** Al comprar **[ SECTOR 3X3 ]**, se instala automáticamente el módulo **`for` e `in range`**.
* **Misiones:**
  1. `ciclo_recoleccion`:
     - Repetición acotada con `for ciclo in range(3):` para extraer al menos 2 minerales.
  2. `exploracion_3x3`:
     - Barrido matricial combinando `for` con `if spid.hay_mineral():` para limpiar el cuadrante.

---

### Fase 5: Parámetros y Variables (Estructurada - 60%)
* **Objetivo:** Abstracción y parametrización de instrucciones.
* **Misiones:**
  1. `camino_largo`: Uso de argumentos numéricos (`spid.norte(2)`).
  2. `variables`: Declaración y uso de variables dinámicas (`pasos = 2`, `spid.norte(pasos)`).

---

## 3. Registro de Decisiones de Diseño Aprobadas

1. **Sintaxis vinculada a expansiones de terreno (04/10/2026):**
   - En lugar de comprar sintaxis abstracta en la tienda como un ítem flotante, la sintaxis viene preinstalada con la expansión física del mapa donde tiene sentido aplicarla:
     - Sector 2x3 $\rightarrow$ Desbloquea `if` y `else`.
     - Sector 3x3 $\rightarrow$ Desbloquea `for` e `in range`.
2. **Reorganización pedagógica de bucles:**
   - Se descartó el orden antiguo donde `for` aparecía antes que `while`.
   - Se estableció: `while` continuo $\rightarrow$ `while` con cuota $\rightarrow$ `if / else` $\rightarrow$ `for in range`.
3. **Parser tolerante a sangrías leves (`code_executor.gd`):**
   - El compilador detecta el fin de un bloque `if` o `else` cuando la línea siguiente tiene una sangría menor que la del cuerpo del bloque (previniendo que espacios accidentales absorban instrucciones posteriores).
4. **Consulta de minerales en vivo:**
   - El servicio de misiones consulta directamente el contador en vivo de la nave (`interfaz.minerales_nave`) evitando desincronizaciones de caché con Supabase o partidas de invitados.

---

*Nota: Cualquier nueva regla, ajuste a las misiones o definición pedagógica futura debe registrarse directamente en este documento.*
