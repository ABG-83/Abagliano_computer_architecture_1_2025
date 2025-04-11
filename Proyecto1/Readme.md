# 📁 Proyecto: Interpolación Bilineal en Lenguaje Ensamblador x86

Este proyecto implementa un sistema de procesamiento de imágenes en escala de grises que aplica **interpolación bilineal** sobre un cuadrante seleccionado por el usuario. El procesamiento es realizado **exclusivamente en lenguaje ensamblador (x86-64)**, y se complementa con una interfaz de usuario escrita en **Python**, que permite cargar imágenes, seleccionar el cuadrante, y visualizar el resultado interpolado.

---

## 🛠️ Herramientas utilizadas

| Herramienta     | Descripción |
|-----------------|-------------|
| `NASM`          | Ensamblador para x86-64 (GNU/Linux) |
| `GDB`           | Depurador para programas en bajo nivel |
| `Python 3.12`   | Lenguaje de alto nivel para la interfaz gráfica |
| `Tkinter`       | Biblioteca estándar de GUI en Python |
| `Pillow (PIL)`  | Manejo de imágenes en escala de grises |
| `NumPy`         | Manipulación de datos binarios y arreglos |
| `Linux`         | Sistema operativo base para desarrollo |
| `Git`           | Control de versiones y gestión del repositorio |

---


---

## ▶️ Instrucciones de uso

### 🔧 Requisitos previos

1. Tener instalado:
   - Python 3.10 o superior
   - NASM
   - GDB
   - Git

2. Instalar librerías de Python (si no están instaladas):
   ```bash
   pip install pillow numpy
### ⚙️ Compilar el código en ensamblador





    nasm -felf64 -o interpolacion_bilineal.o interpolacion_bilineal.asm
    ld -o interpolacion_bilineal interpolacion_bilineal.o

### 🖼️ Ejecucion de la interfaz

Si se usa la interfaz :
Solo tocar el boton de run desde el IDE de python que desee.

###
Si se utiliza la terminal ejecutar:
```bash

python3 Interfaz.py




