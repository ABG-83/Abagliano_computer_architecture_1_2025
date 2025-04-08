
import tkinter as tk
from tkinter import filedialog
from PIL import Image, ImageTk, ImageDraw
import numpy as np
import os

class ImageQuadrantSelector:
    def __init__(self, root):
        self.root = root
        self.root.title("Selector de Cuadrantes 4x4")
        self.canvas = tk.Canvas(root)
        self.canvas.pack()

        self.btn_cargar = tk.Button(root, text="Cargar Imagen", command=self.cargar_imagen)
        self.btn_cargar.pack()

        self.btn_guardar = tk.Button(root, text="Guardar Selección", command=self.guardar_seleccion)
        self.btn_guardar.pack()

        self.imagen = None
        self.tk_img = None
        self.img_np = None
        self.cuadrante_seleccionado = None
        self.cuadrantes = []
        self.imagen_path = None

    def cargar_imagen(self):
        path = filedialog.askopenfilename(filetypes=[("Imagen", "*.png *.jpg *.bmp")])
        if path:
            self.imagen_path = path
            self.imagen = Image.open(path).convert('L')  # Escala de grises
            self.img_np = np.array(self.imagen)
            self.mostrar_imagen()

    def mostrar_imagen(self):
        ancho, alto = self.imagen.size
        self.canvas.config(width=ancho * 2, height=alto)  # doble ancho para mostrar la imagen interpolada al lado
        self.tk_img = ImageTk.PhotoImage(self.imagen.convert("RGB"))
        self.canvas.create_image(0, 0, anchor=tk.NW, image=self.tk_img)

        self.dividir_cuadrantes(ancho, alto)
        self.canvas.bind("<Button-1>", self.seleccionar_cuadrante)

    def dividir_cuadrantes(self, ancho, alto):
        self.cuadrantes = []
        for i in range(4):
            for j in range(4):
                x0 = j * ancho // 4
                y0 = i * alto // 4
                x1 = x0 + ancho // 4
                y1 = y0 + alto // 4
                self.cuadrantes.append((x0, y0, x1, y1))
                self.canvas.create_rectangle(x0, y0, x1, y1, outline='blue')

    def seleccionar_cuadrante(self, event):
        for idx, (x0, y0, x1, y1) in enumerate(self.cuadrantes):
            if x0 <= event.x <= x1 and y0 <= event.y <= y1:
                self.cuadrante_seleccionado = idx
                self.dibujar_seleccion(x0, y0, x1, y1)
                break

    def dibujar_seleccion(self, x0, y0, x1, y1):
        self.mostrar_imagen()  # Refresca para eliminar selecciones previas
        self.canvas.create_rectangle(x0, y0, x1, y1, outline='red', width=3)

    def guardar_seleccion(self):
        if self.cuadrante_seleccionado is None or self.imagen is None:
            print("No hay cuadrante seleccionado o imagen cargada.")
            return

        x0, y0, x1, y1 = self.cuadrantes[self.cuadrante_seleccionado]
        cuadrante = self.imagen.crop((x0, y0, x1, y1))
        cuadrante = cuadrante.resize((64, 64), Image.NEAREST)

        # Nombre fijo para archivo de entrada al ensamblador
        nombre_archivo = "original_cuadrante.img"
        datos = np.array(cuadrante, dtype=np.uint8).flatten()

        with open(nombre_archivo, 'wb') as f:
            f.write(datos.tobytes())

        print(f"Cuadrante {self.cuadrante_seleccionado} guardado como {nombre_archivo}")

        # Llamar al ejecutable ensamblador
        os.system("./interpolacion_bilineal")

        # Mostrar la imagen procesada
        self.mostrar_img_generada("output.img")


    def mostrar_img_generada(self, ruta_img):
        try:
            with open(ruta_img, 'rb') as f:
                datos = f.read()
                arr = np.frombuffer(datos, dtype=np.uint8)
                if len(arr) != 128 * 128:
                    print("Tamaño incorrecto para imagen interpolada.")
                    return
                arr = arr.reshape((128, 128))
                img = Image.fromarray(arr, mode='L')
                img_rgb = img.convert("RGB")
                self.tk_img_interpolada = ImageTk.PhotoImage(img_rgb)
                self.canvas.create_image(self.imagen.width, 0, anchor=tk.NW, image=self.tk_img_interpolada)
        except FileNotFoundError:
            print(f"No se encontró la imagen generada {ruta_img}")

if __name__ == "__main__":
    root = tk.Tk()
    app = ImageQuadrantSelector(root)
    root.mainloop()
