# Auditoría del repositorio Entornos

Fecha de auditoría: 2026-07-30  
Rama revisada: `refactor/parrot-security-lab`  
Alcance: estado `e3ee8d9` previo a la migración a Parrot OS

## Resumen ejecutivo

El repositorio original automatiza instalaciones de Arch Linux y el despliegue de un escritorio BSPWM. No contiene soporte real para Debian ni Parrot OS. La lógica útil está mezclada con operaciones destructivas, cambios globales del sistema, paquetes de Pacman/AUR y configuraciones personales, por lo que no es seguro adaptar los scripts existentes mediante sustituciones de nombres de paquetes.

La migración propuesta conserva únicamente ideas y configuraciones pequeñas: detección de VMware, diez escritorios BSPWM, atajos SXHKD, una paleta visual discreta y módulos básicos de Polybar. El código Arch se aislará en `legacy/arch/` y quedará fuera del flujo activo. El nuevo instalador será específico para Parrot, modular, idempotente, operado con APT y seguro por defecto mediante `--dry-run`, backups y validación explícita del sistema.

## Método y límites

Se inspeccionaron todos los archivos versionados, los últimos doce commits, las variantes de instalación BSPWM y el índice y contenido textual relevante de `config.zip`. El ZIP fue abierto como archivo, sin ejecutar ni instalar su contenido. No se ejecutaron instalaciones, cambios en `/etc`, servicios, gestores de paquetes, cambios de shell, reinicios ni apagados.

El host de revisión no se usó para validar disponibilidad en repositorios Parrot. Los nombres de paquetes se basan en Debian/Parrot y quedan pendientes de una comprobación real con `apt-cache show` dentro de una VM Parrot.

## Inventario del estado original

| Grupo | Archivos | Evaluación |
| --- | --- | --- |
| Instalación Arch | `installArch.sh`, `installArchBIOS.sh`, `installArch_Legacy.sh`, `install_SistemaBaseArchLinux.sh`, `Install_EntornoArchLinux.sh` | Exclusivos de Arch; deben aislarse completos. |
| Escritorio BSPWM | `install-bspwm.sh`, `install-bspwm-quick.sh`, `install-bspwm-v3.sh` | Mezclan Pacman, AUR, dotfiles y cambios globales. Solo son reutilizables algunas ideas. |
| Desarrollo | `install_WebDev.sh` | Exclusivo de Pacman/AUR y fuera del perfil security lab inicial. |
| Utilidades | `rename_image.sh`, `scripts/batery.sh`, scripts de Wi-Fi e interfaces, `scripts/paqueteextra` | Calidad desigual; hay duplicados y operaciones privilegiadas. |
| Configuración | `config.zip`, `Atajos.txt` | ZIP monolítico con configuración útil, contenido vendorizado y rutas personales. |
| Imágenes | `Wall_OnePiece.png`, `bgLogin.jpg`, capturas PNG | El wallpaper es reutilizable; las capturas y fondo de login son documentación histórica. |
| Documentación | `Readme.md` | Describe Arch y recomienda ejecutar scripts remotos directamente. Debe reemplazarse. |

El repositorio original contiene 24 archivos fuera de `.git`. Los scripts principales suman más de 2.400 líneas y duplican instalación, configuración y manejo de servicios.

## Historial Git reciente

Los commits recientes agregan y revisan instaladores Arch y BSPWM. Cinco revisiones consecutivas afectan `install-bspwm-v3.sh`, que llegó a concentrar detección de virtualización, reparación de Pacman, instalación de paquetes, descargas, dotfiles, display manager, shell y limpieza. El último commit agrega otra copia del instalador Arch para VMware. Esto confirma un diseño incremental y monolítico, sin separación entre políticas y mecanismos.

## Revisión de `config.zip`

El ZIP contiene configuraciones para BSPWM, SXHKD, Polybar, Rofi, Picom, Kitty y Dunst, además de scripts, fuentes, Neovim, complementos Zsh y una copia completa de Powerlevel10k que incluye su directorio `.git`.

Elementos útiles:

- diez escritorios BSPWM y reglas flotantes;
- atajos de foco, intercambio, estados y escritorios en SXHKD;
- módulos Polybar de BSPWM, ventana, CPU, memoria, red, volumen y fecha;
- una paleta oscura coherente para Kitty, Picom y notificaciones;
- conceptos de estado de VPN y objetivo activo.

Elementos que no deben copiarse literalmente:

- rutas `/home/zeus`, `/home/jaagr` y referencias a `~/WallPapers`;
- interfaz fija `enp7s0` y suposición rígida de `tun0`;
- barras duplicadas, módulos i3 y nombres de monitores fijos;
- comandos de `sudo reboot`, `sudo poweroff` y suspensión desde UI;
- ejecución incondicional de `vmware-user-suid-wrapper`;
- dependencias como `ifconfig`, `pamixer`, `betterlockscreen`, `xautolock`, MPD y fuentes privadas;
- repositorios completos vendorizados de Powerlevel10k y módulos Zsh;
- scripts grandes de terceros sin procedencia ni política de actualización clara.

El ZIP dejará de ser la fuente principal. Solo se reescribirán configuraciones mínimas y legibles como archivos normales.

## Componentes reutilizables

### Bash

- Uso de `systemd-detect-virt` para reconocer VMware.
- Deducción del usuario invocante mediante `SUDO_USER`, corregida con validaciones.
- Funciones conceptuales de mensajes y pasos, reemplazadas por una biblioteca de logging.
- Separación conceptual de instalación de VMware presente en la variante v3.

No se reutilizarán funciones completas porque están acopladas a Pacman y ocultan errores.

### Escritorio

- Esquema de diez escritorios numerados.
- Teclas Super para terminal, lanzador, foco, movimiento, fullscreen, floating y cierre.
- Restauración de wallpaper con `feh`.
- Inicio de SXHKD, Polybar, Picom y Dunst desde `bspwmrc`.
- Reglas flotantes para utilidades como diálogos, gestores de archivos y herramientas gráficas.
- Colores sobrios y baja opacidad, reduciendo efectos para VMware.

### Laboratorio

- Idea de mostrar la IP de una VPN y un objetivo activo en Polybar.
- Uso de un archivo de estado por usuario para el objetivo, reemplazando rutas personales.
- Captura de pantalla mediante Flameshot como funcionalidad básica.

## Componentes descartados del flujo activo

- Pacman, `pacstrap`, `arch-chroot`, mirrors Arch y configuración de `pacman.conf`.
- AUR, `yay`, `paru` y compilación automática de paquetes externos.
- Instalación de Arch BIOS/UEFI y particionado de discos.
- AutoBspwmKali y transformaciones posteriores con `sed`.
- LightDM y cambios de display manager.
- cambios automáticos de shell para usuario o root;
- Oh My Zsh, Powerlevel10k y complementos vendorizados en esta iteración;
- instalación masiva de herramientas ofensivas;
- cambios de servicios durante la fase de revisión;
- scripts interactivos de Wi-Fi e interfaces que requieren privilegios.

Todos estos archivos históricos se conservarán en `legacy/arch/`, sin imports ni ejecución desde el instalador nuevo.

## Riesgos de seguridad

### Críticos

- `install-bspwm-v3.sh` cambia `SigLevel` a `Never`, anulando la verificación criptográfica de paquetes.
- Se eliminan cachés, locks y archivos de Pacman mediante `rm`, incluso con errores ignorados.
- Existen patrones `curl | sh` para ejecutar Oh My Zsh sin fijar versión ni verificar checksum.
- Se modifican particiones, `/etc`, sudoers, display managers, servicios y shell en scripts monolíticos.
- Algunas descargas se ejecutan o copian sin validar integridad, origen versionado ni contenido.

### Recuperables

- Copias recursivas sobre dotfiles sin backup ni comparación previa.
- Reintentos y continuaciones con `2>/dev/null || true` que ocultan paquetes o configuraciones fallidas.
- Uso inconsistente de `sudo`, incluida escritura dentro de hogares y cambios para root.
- Uso de `/tmp` con nombres previsibles y sin aislamiento.
- Variables y expansiones sin comillas en interfaces, usuarios y rutas.

### Opcionales

- Fallos de módulos visuales, wallpaper, batería, VPN u objetivo activo no deben abortar la instalación base.
- Herramientas gráficas no disponibles en una edición concreta de Parrot deben informarse y omitirse solo si están declaradas opcionales.

## URLs y cadena de suministro

El estado original descarga desde GitHub Raw, GitHub, GitHub Gist, AUR y mirrors Arch, incluyendo:

- el propio repositorio `Black-Zeus/Entornos`;
- `Justice-Reaper/AutoBspwmKali`;
- el instalador de Oh My Zsh;
- plugins de `zsh-users`;
- Nerd Fonts 2.3.3;
- `yay` y `paru` desde AUR;
- un Gist usado como fuente de wallpapers.

No hay checksums ni archivos de versiones bloqueadas. El nuevo flujo inicial no descargará dotfiles ni ejecutará scripts externos. APT conservará firmas, TLS y repositorios configurados por Parrot.

## Dependencias identificadas

### Base propuesta

`git`, `curl`, `wget`, `unzip`, `jq`, `zsh` y `tmux`. Bash, coreutils y utilidades de detección deberán verificarse antes de comenzar.

### Escritorio propuesto

`bspwm`, `sxhkd`, `polybar`, `rofi`, `picom`, `kitty`, `dunst`, `feh`, `nitrogen`, `thunar`, `flameshot`, `xclip`, `xdotool` y `pavucontrol`.

### VMware propuesto

`open-vm-tools` y `open-vm-tools-desktop`. Las carpetas compartidas dependen de FUSE y de la configuración del hipervisor; no se habilitarán servicios en esta iteración.

Todos los nombres están pendientes de validación en una VM Parrot. Los paquetes obligatorios se distinguirán de los opcionales en archivos de datos, sin ocultar errores críticos.

## Problemas de diseño

- Scripts monolíticos y orden de pasos rígido.
- Sin modo de simulación ni selección fiable de componentes.
- Sin detección estricta de distribución.
- Sin modelo de errores críticos, recuperables y opcionales.
- Sin backups transaccionales ni manifiesto de archivos desplegados.
- Configuración generada dentro de heredocs, difícil de revisar y versionar.
- Estado global y rutas personales hardcodeadas.
- Paquetes y comandos repetidos en varias variantes.
- Mezcla de instalación, ejecución de servicios y preferencias personales.
- Ausencia de pruebas estáticas y contrato de códigos de salida.

## Arquitectura propuesta

El punto de entrada `install.sh` coordinará bibliotecas pequeñas bajo `lib/`. Las listas APT vivirán en `packages/`; los archivos de usuario, en `dotfiles/`; las utilidades operativas, en `scripts/`; los assets, en `assets/`; y las validaciones, en `tests/`.

El instalador:

1. analizará argumentos sin modificar el sistema;
2. comprobará Bash, usuario, Parrot, arquitectura y dependencias;
3. detectará VMware;
4. resolverá componentes y paquetes desde archivos de datos;
5. mostrará el plan en `--dry-run`;
6. en una ejecución real autorizada, usará APT y desplegará dotfiles con backup;
7. emitirá un resumen y pendientes manuales, sin reiniciar ni cambiar shell.

Los componentes serán `base`, `desktop` y `vmware`. `security-lab.txt` será solo un borrador hasta definir herramientas concretas, proporcionales y auditables.

## Plan de migración

1. Añadir documentación, normas del repositorio y criterios de prueba.
2. Trasladar todo el código Arch y artefactos históricos a `legacy/arch/`.
3. Crear bibliotecas Bash para logging, detección, backups, APT y dotfiles.
4. Implementar `install.sh` con `--help`, `--dry-run` y `--components`.
5. Crear listas de paquetes externas y marcar validación pendiente en Parrot.
6. Normalizar dotfiles mínimos de BSPWM, SXHKD, Polybar, Rofi, Picom, Kitty, Dunst, Zsh y tmux.
7. Crear scripts seguros de VPN, objetivo, captura y actualización del laboratorio.
8. Añadir pruebas de sintaxis, estructura, seguridad, rutas, ejecutables, detección y backups simulados.
9. Ejecutar `git diff --check`, pruebas de sintaxis, análisis estático y smoke tests.
10. Probar posteriormente instalación real en una snapshot de VM Parrot, documentando versiones, paquetes ausentes, servicios VMware y comportamiento multimonitor.

## Criterio de salida de la auditoría

La auditoría se considera completa porque inventaría el repositorio original, inspecciona el ZIP sin ejecutar contenido, clasifica lo reutilizable y lo descartado, identifica riesgos y dependencias, y define una migración que no conecta el nuevo instalador con el árbol heredado.
