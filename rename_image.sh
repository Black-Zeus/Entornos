#!/bin/bash

# Contador para el correlativo
counter=0

# Iterar sobre todas las imágenes en la carpeta
for image in ~/Wallpapers/*.{jpg,jpeg,png}; do
    # Si el nombre de archivo es "Wall_OnePiece.png", saltar esta imagen
    if [[ $image == *"Wall_OnePiece.png" ]]; then
        continue
    fi
    
    # Obtener la extensión del archivo
    extension="${image##*.}"

    # Formatear el nombre de archivo con el correlativo
    new_name="imagenFondo_$(printf "%03d" "$counter").$extension"

    # Renombrar el archivo
    mv "$image" "~/Wallpapers/$new_name"

    # Incrementar el contador para la siguiente imagen
    ((counter++))
done
