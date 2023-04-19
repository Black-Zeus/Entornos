#!/bin/bash

# Listamos las interfaces disponibles
echo "Interfaces disponibles:"
interfaces=($(ip link show | awk '/^[0-9]/ {print $2}'))
for (( i=0; i<${#interfaces[@]}; i++ )); do
    echo "$i) ${interfaces[$i]}"
done

# Pedimos al usuario el número de la interfaz a operar
echo -n "Seleccione el número de la interfaz que desea operar: "
read selection

# Validamos la selección del usuario
if ! [[ "$selection" =~ ^[0-9]+$ ]]; then
    echo "La selección debe ser un número entero."
    exit 1
elif (( selection < 0 )) || (( selection >= ${#interfaces[@]} )); then
    echo "La selección debe estar dentro del rango de opciones."
    exit 1
fi

# Preguntamos al usuario si desea hacer "up" o "down" en la interfaz seleccionada
echo -n "¿Desea hacer 'up' o 'down' en ${interfaces[$selection]}? (up/down): "
read action

# Validamos la acción del usuario
if [[ "$action" != "up" ]] && [[ "$action" != "down" ]]; then
    echo "La acción debe ser 'up' o 'down'."
    exit 1
fi

# Ejecutamos la acción seleccionada en la interfaz correspondiente
sudo ip link set ${interfaces[$selection]} $action

if [[ "$action" == "up" ]]; then
    # Preguntamos si desea forzar la obtención de dirección IP mediante DHCP
    echo -n "¿Desea forzar la obtención de dirección IP mediante DHCP? (S/N): "
    read force_dhcp

    if [[ "$force_dhcp" == "S" ]] || [[ "$force_dhcp" == "s" ]]; then
        sudo dhclient ${interfaces[$selection]}
    fi
		
	echo "Buscando direccion IP para ${interfaces[$selection]}"  
	sleep 3
	ip_address=$(ip address show ${interfaces[$selection]} | awk '/inet / {print $2}')
	if ! [[ "$ip_address" == "" ]]; then
    	echo "No se puede detectar una direccion IP para la interfaz ${interfaces[$selection]}"
	else 
        echo "Se ha obtenido una dirección IP ($ip_address) en ${interfaces[$selection]} mediante DHCP."
	fi
fi

echo "La interfaz ${interfaces[$selection]} ha sido puesta en estado $action."
echo "Listado de interfaces y direcciones IP"
ip -o -4 addr show | awk '{print $2, $4}' | sed 's/\/.*//' | sed 's/://'
