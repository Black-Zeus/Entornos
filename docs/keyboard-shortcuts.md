# Atajos de teclado y controles

Este documento enumera los atajos definidos explícitamente por `parrot-security-lab`. No intenta reproducir todos los atajos predeterminados de Kitty, Rofi, Zsh, tmux ni las aplicaciones instaladas.

## Convenciones

- `Super`: tecla Windows/Meta.
- `Ctrl`, `Shift` y `Alt`: modificadores habituales.
- `Izquierda`, `Abajo`, `Arriba`, `Derecha`: teclas de dirección.
- Los atajos BSPWM se gestionan con SXHKD y solo funcionan dentro de la sesión gráfica BSPWM.

## Aplicaciones y sesión BSPWM

| Atajo | Acción |
|---|---|
| `Super + Enter` | Abrir Kitty. |
| `Super + D` | Abrir el lanzador de aplicaciones Rofi. |
| `Super + Shift + S` | Abrir Flameshot para seleccionar una captura. |
| `Super + Esc` | Recargar la configuración de SXHKD. |
| `Super + Q` | Cerrar la ventana enfocada. |
| `Super + Shift + R` | Recargar BSPWM. |

## Estado de las ventanas

| Atajo | Acción |
|---|---|
| `Super + F` | Alternar pantalla completa. |
| `Super + Shift + Espacio` | Convertir la ventana en flotante. |
| `Super + T` | Convertir la ventana en mosaico (`tiled`). |

## Navegación y movimiento

| Atajo | Acción |
|---|---|
| `Super + H` o `Super + Izquierda` | Enfocar la ventana al oeste. |
| `Super + J` o `Super + Abajo` | Enfocar la ventana al sur. |
| `Super + K` o `Super + Arriba` | Enfocar la ventana al norte. |
| `Super + L` o `Super + Derecha` | Enfocar la ventana al este. |
| `Super + Shift + H/J/K/L` | Intercambiar la ventana enfocada con la ubicada en esa dirección. |
| `Super + Shift + Flecha` | Intercambiar la ventana enfocada con la ubicada en esa dirección. |
| `Super + Ctrl + Izquierda` | Mover una ventana flotante 30 px a la izquierda. |
| `Super + Ctrl + Abajo` | Mover una ventana flotante 30 px hacia abajo. |
| `Super + Ctrl + Arriba` | Mover una ventana flotante 30 px hacia arriba. |
| `Super + Ctrl + Derecha` | Mover una ventana flotante 30 px a la derecha. |

## Escritorios

| Atajo | Acción |
|---|---|
| `Super + 1` a `Super + 9` | Cambiar al escritorio 1–9. |
| `Super + 0` | Cambiar al escritorio 10. |
| `Super + Shift + 1` a `Super + Shift + 9` | Enviar la ventana al escritorio 1–9. |
| `Super + Shift + 0` | Enviar la ventana al escritorio 10. |

## Audio

| Atajo | Acción |
|---|---|
| `Subir volumen` | Aumentar el volumen predeterminado en 5 %. |
| `Bajar volumen` | Disminuir el volumen predeterminado en 5 %. |
| `Silenciar` | Alternar silencio en la salida predeterminada. |

Las tres teclas anteriores corresponden a `XF86AudioRaiseVolume`, `XF86AudioLowerVolume` y `XF86AudioMute`. Si la VM no tiene tarjeta de sonido, no producen un cambio útil.

## Zsh y fzf

| Atajo | Acción |
|---|---|
| `Esc`, `Esc` | Anteponer `sudo` a la línea actual; si ya comienza con `sudo`, retirarlo. |
| `Ctrl + R` | Buscar interactivamente en el historial mediante fzf. |
| `Ctrl + T` | Buscar archivos con fzf e insertarlos en la línea actual. |
| `Alt + C` | Buscar un directorio con fzf y cambiar a él. |

Los atajos fzf provienen de los scripts oficiales instalados por el paquete Debian/Parrot `fzf`. Zsh utiliza modo de edición Emacs (`bindkey -e`), pero sus combinaciones predeterminadas no se enumeran aquí.

## tmux

El prefijo no se modifica; se conserva el predeterminado `Ctrl + B`.

| Atajo | Acción |
|---|---|
| `Ctrl + B`, luego `R` | Recargar `~/.tmux.conf`. |

Los demás atajos de tmux son los predeterminados y no forman parte de la configuración propia del repositorio.

## Visor de imágenes en Kitty

No es un atajo de teclado, pero forma parte de la configuración operativa de la terminal:

| Comando | Acción |
|---|---|
| `icat imagen.png` | Mostrar una imagen dentro de Kitty mediante `kitten icat`. |
| `icat directorio/` | Mostrar recursivamente las imágenes compatibles del directorio. |
| `fsicat ...` | Invocar `/usr/bin/icat`, la herramienta forense homónima de Sleuth Kit. |

El alias `icat` debe usarse dentro de Kitty. Su funcionamiento dentro de tmux depende del soporte de passthrough para el protocolo gráfico.

## Controles de Polybar

Estos controles usan el ratón, pero forman parte del mapa operativo del escritorio:

| Control | Acción |
|---|---|
| Clic izquierdo en la primera tarjeta | Cambiar al wallpaper siguiente. |
| Clic derecho en la primera tarjeta | Abrir el selector de wallpapers con Rofi. |
| Clic izquierdo en la tarjeta VPN | Seleccionar un perfil `.ovpn`; si la sesión está activa, permite desconectarla o ver el log. |
| Clic derecho en la tarjeta VPN | Abrir el log de OpenVPN en Kitty. |
| Clic en un escritorio | Cambiar a ese escritorio. |
| Rueda sobre los escritorios | Recorrer los escritorios. |
| Clic izquierdo en la tarjeta de energía | Abrir el menú para bloquear, cerrar sesión, reiniciar o apagar. |

## Fuentes de configuración

- Atajos BSPWM: `dotfiles/sxhkd/sxhkdrc`.
- Atajos Zsh/fzf: `dotfiles/zsh/zshrc`.
- Atajo tmux: `dotfiles/tmux/tmux.conf`.
- Controles de Polybar: `dotfiles/polybar/config.ini`.
