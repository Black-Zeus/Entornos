# Arquitectura de parrot-security-lab

## Alcance

El proyecto prepara exclusivamente una VM VMware con Parrot OS para pentesting autorizado, Hack The Box, TryHackMe, laboratorios, desarrollo de herramientas y futuras integraciones CLI. No es una configuración de uso diario ni una abstracción multidistribución.

Este repositorio no soporta Arch Linux, Kali Linux ni otras distribuciones.

## Estructura

```text
install.sh                 Orquestador y contrato CLI
lib/                       Detección, logging, APT, backup y despliegue
packages/                  Datos de paquetes por componente
dotfiles/                  Configuración de usuario versionada
assets/                    Recursos locales versionados
scripts/                   Utilidades operativas del laboratorio
tests/                     Validaciones sin cambios de sistema
docs/                      Diseño, auditoría y pruebas
legacy/arch/               Historia aislada; nunca forma parte del flujo
```

Se mantiene `security-lab.txt` como borrador no instalable. Esto evita introducir un cuarto componente vacío o instalar colecciones ofensivas sin una selección y validación explícitas.

## Flujo del instalador

1. Analiza `--help`, `--dry-run` y `--components`.
2. Resuelve el usuario real; rechaza una sesión root directa.
3. Inicializa el destino del log, sin crearlo en dry-run.
4. exige `ID=parrot` en `/etc/os-release` y arquitectura x86-64;
5. Detecta VMware con `systemd-detect-virt`.
6. Verifica dependencias y carga listas APT.
7. Valida paquetes con `apt-cache show` cuando está disponible.
8. En ejecución real, ejecuta `apt-get update` e instala paquetes.
9. Despliega cada dotfile solo si cambió, respaldando antes el destino.
10. Muestra resumen, incidencias y tareas manuales.

El modo interno `PARROT_INSTALLER_TESTING=1` solo funciona junto con `--dry-run`; permite inyectar un `os-release`, usuario, home y virtualización falsos para smoke tests. Nunca habilita una instalación real.

## Componentes

### `base`

Instala utilidades generales, Zsh y tmux. Despliega `.zshrc`, `.tmux.conf` y scripts operativos en `~/.local/bin`. No cambia la shell por defecto.

### `desktop`

Instala BSPWM, SXHKD, Polybar, Rofi, Picom, Kitty, Dunst y utilidades gráficas. Despliega configuración bajo `~/.config` y un wallpaper local. No cambia display manager ni crea una sesión en `/usr/share/xsessions` durante esta fase.

### `vmware`

Instala `open-vm-tools`, `open-vm-tools-desktop` y opcionalmente `fuse3`. La resolución dinámica y el clipboard dependen del proceso de usuario de VMware; la sincronización horaria y carpetas compartidas dependen además del hipervisor.

Servicios que deberán verificarse y, si corresponde, activarse manualmente en una instalación real:

- `open-vm-tools.service` o `vmtoolsd.service`, según el paquete de Parrot;
- integración gráfica de `open-vm-tools-desktop` dentro de la sesión X11;
- `vmware-vmblock-fuse.service`, si existe y se requieren funciones de clipboard/drag-and-drop;
- montaje de carpetas compartidas con `vmhgfs-fuse`, después de configurarlas en VMware.

Esta iteración no ejecuta `systemctl enable`, no cambia políticas de tiempo y no monta carpetas.

## Modelo de errores

- Crítico: plataforma incorrecta, ejecución root directa, dependencia esencial, paquete obligatorio o despliegue fallido. Aborta con código no cero.
- Recuperable: detección incompleta de virtualización o selección VMware fuera de VMware. Continúa y aparece en el resumen.
- Opcional: paquete o configuración explícitamente opcional. Continúa y aparece separado en el resumen.

Códigos públicos: `0` éxito, `2` uso inválido, `3` plataforma/usuario no soportado, `4` dependencia o paquete, `5` operación de instalación/despliegue.

## Idempotencia y backups

Las listas APT usan una sola resolución por ejecución y APT gestiona paquetes ya instalados. `deploy_file` compara fuente y destino; si son idénticos no escribe. Si difieren, copia primero el destino a `~/.local/state/parrot-security-lab/backups/<timestamp>/` preservando su ruta absoluta relativa. Los logs se guardan con permisos `0600`.

El backup protege dotfiles, no constituye rollback de paquetes APT. La restauración es manual e intencional.

## Escritorio y laboratorios

BSPWM crea diez escritorios y distribuye seis/cuatro entre los dos primeros monitores; en un monitor usa los diez. Monitores adicionales siguen siendo utilizables y quedan pendientes de una política configurable en VM. La composición usa XRender, sin blur ni animaciones.

Polybar incluye escritorios, título, CPU, memoria, red, volumen y reloj. Los scripts `vpn-status.sh` y `target-status.sh` siempre producen salida válida aunque no exista interfaz VPN o archivo de objetivo. Quedan preparados módulos futuros para VMware Tools, batería e IP local.

## Decisiones de seguridad

- solo APT con repositorios, firmas, certificados y TLS configurados por Parrot;
- sin descargas o ejecución de scripts externos;
- sin Pacman, AUR ni imports desde `legacy/`;
- sin reinicios, apagados, cambios de shell, display manager ni servicios automáticos;
- rutas derivadas del usuario real y de XDG, nunca de un nombre personal;
- entradas de paquetes y componentes validadas antes de usarse.
