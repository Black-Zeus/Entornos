#!/bin/bash

# Verificamos si nmcli está instalado
if ! command -v nmcli &> /dev/null; then
    echo "No posee los paquetes necesarios, se procedera a instalar"
    sudo pacman -Sy networkmanager --needed --noconfirm
	sudo systemctl enable NetworkManager
	sudo systemctl start NetworkManager

fi

# Verificamos si la interfaz inalámbrica wlan0 está activada
if ! ip link show wlan0 &> /dev/null; then
    echo "La interfaz inalámbrica wlan0 no está disponible."
    exit 1
fi

# Verificamos si la interfaz inalámbrica wlan0 está activada
if ! ip link show wlan0 | grep "state UP" &> /dev/null; then
    echo "La interfaz inalámbrica wlan0 está desactivada. Activando..."
    sudo ip link set wlan0 up
fi

# Escaneamos las redes inalámbricas disponibles
echo "Escaneando redes disponibles..."
sudo nmcli dev wifi list > /tmp/wifi_list
network_list=$(cat wifi_list)
echo "$network_list" | awk 'BEGIN {print "Número\tRed WiFi"} {if (NR > 1) {printf NR-1 "\t"} printf $0 "\n"}'

# Solicitamos al usuario el número de la red WiFi a la que desea conectarse
echo -n "Ingrese el número de la red WiFi a la que desea conectarse: "
read network_number

network_name1=$(echo "$network_list" | awk -v num="$network_number" 'NR==num+1 {print $2}')

nmcli_pass=$(nmcli --show-secrets connection show "$network_name1" | grep -w "802-11-wireless-security.psk:" | awk '{print $2}')
if [ -n "$nmcli_pass" ]; then
    while true; do
		read -p "Ya existe una contraseña almacenada. ¿Desea emplearla? (S/N) " yn
		case $yn in
		    [Ss]* ) echo "El usuario ha confirmado que desea emplear la contraseña almacenada."; password=$(echo $nmcli_pass); break;;
		    [Nn]* ) echo "El usuario ha indicado que no desea emplear la contraseña almacenada."; password="";break;;
		    * ) echo "Por favor ingrese S o N.";;
		esac
	done
fi


if [ -z "$password" ]; then
    echo "No se ha encontrado una contraseña almacenada."
	# Solicitamos la contraseña de la red WiFi
	echo -n "Ingrese la contraseña de la red WiFi: "
	read -s password
	echo
fi


# Obtenemos el nombre de la red WiFi seleccionada
network_name=$(echo "$network_list" | awk -v num="$network_number" 'NR==num+1 {print $1}')

# Intentamos conectarnos a la red WiFi
echo "Conectando a la red WiFi $network_name1..."
sudo nmcli dev wifi connect "$network_name" password "$password"
if [ $? -eq 0 ]; then
    echo "Conectado a la red WiFi $network_name1!"
else
    echo "No se pudo conectar a la red WiFi $network_name1."
fi

# Obtener el nombre de la interfaz de red cableada
cable_interface=$(ip link show | awk '/^[0-9]/ {print $2}' | grep "^en" | sed 's/:$//')
# Verificar si la interfaz está activa
if ip link show $cable_interface | grep "state UP" &> /dev/null; then
  echo "Desconectar la interfaz de red cableada"
  sudo ip link set $cable_interface down
fi

# Obtenemos la dirección IP asignada a la interfaz inalámbrica
ip_address=$(ip addr show wlan0 | grep "inet " | awk '{print $2}' | cut -d "/" -f1)
echo "Dirección IP asignada a la interfaz inalámbrica: $ip_address"

