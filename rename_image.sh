#!/bin/bash

# Directorio que contiene las imágenes
images_dir="~/WallPapers"

# Contador para el valor autoincremental
counter=0

# Iterar sobre todas las imágenes en el directorio
for image in "$images_dir"/*.{jpg,jpeg,png}; do
    # Obtener la extensión del archivo
    extension="${image##*.}"
    
    # Formatear el valor autoincremental con ceros a la izquierda
    value=$(printf "%03d" "$counter")

    # Formatear el nuevo nombre de archivo
    new_name="WallPaper_$value.$extension"

    # Imprimir un mensaje antes de renombrar el archivo
    echo "Renombrando imagen $image a $new_name"

    # Renombrar el archivo
    mv "$image" "$images_dir/$new_name"

    # Incrementar el contador para la siguiente imagen
    ((counter++))
done
