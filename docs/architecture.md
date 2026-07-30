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

`security-lab` es un componente instalable y explícito. `packages/security-lab.txt` contiene los runtimes comunes y `packages/security-lab/*.txt` separa los paquetes por alcance operativo. El cargador procesa los scopes en orden y elimina duplicados; una clasificación `required` prevalece sobre `optional`. No incluye metapaquetes de distribución.

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

Instala Google Chrome estable, utilidades generales, Zsh y tmux. Chrome se obtiene exclusivamente mediante el repositorio APT oficial de Google: la clave se descarga por TLS, se compara con la huella oficial `EB4C 1BFD 4F04 2F6D DDCC EC91 7721 F63B D38B 4796` y se limita al repositorio mediante `signed-by`. También combina una política de Firefox para instalar Wappalyzer firmado desde Mozilla Add-ons en modo `normal_installed`; conserva otras políticas, respalda el archivo previo y permite deshabilitar la extensión. Zsh carga Powerlevel10k, autosuggestions, syntax highlighting, fzf, zoxide y direnv; doble `Esc` alterna `sudo` sin habilitar correcciones automáticas agresivas. Despliega `.zshrc`, `.tmux.conf` y scripts operativos en `~/.local/bin`. No cambia la shell por defecto.

### `desktop`

Instala BSPWM, SXHKD, Polybar, Rofi, Picom, Kitty, Dunst y utilidades gráficas. Despliega configuración bajo `~/.config` y un wallpaper local. No cambia display manager ni crea una sesión en `/usr/share/xsessions` durante esta fase.

### `vmware`

Instala `open-vm-tools`, `open-vm-tools-desktop` y opcionalmente `fuse3`. La resolución dinámica y el clipboard dependen del proceso de usuario de VMware; la sincronización horaria y carpetas compartidas dependen además del hipervisor.

Servicios que deberán verificarse y, si corresponde, activarse manualmente en una instalación real:

- `open-vm-tools.service` o `vmtoolsd.service`, según el paquete de Parrot;
- integración gráfica de `open-vm-tools-desktop` dentro de la sesión X11; BSPWM inicia `vmware-user-suid-wrapper` condicionalmente y una sola vez;
- `vmware-vmblock-fuse.service`, si existe y se requieren funciones de clipboard/drag-and-drop;
- montaje de carpetas compartidas con `vmhgfs-fuse`, después de configurarlas en VMware.

Esta iteración no ejecuta `systemctl enable`, no cambia políticas de tiempo y no monta carpetas.

Algunos paquetes pueden habilitar unidades desde sus scripts de postinstalación. Se excluye Suricata del flujo automático porque su paquete habilita `suricata.service`; deberá incorporarse manualmente cuando se defina su política operativa.

### `security-lab`

Instala Node.js/npm y Python/pipx para agentes y herramientas CLI, utilidades de diagnóstico de red y un conjunto explícito de herramientas de enumeración para HTB, TryHackMe y laboratorios autorizados. El prefijo global de npm se mantiene dentro del home del usuario para evitar `sudo npm install -g`. Codex CLI, Claude Code y otras herramientas autenticadas no se instalan automáticamente.

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

Polybar incluye escritorios, CPU, memoria, red, VPN, objetivo, reloj y una tarjeta de energía. Esta última abre `power-menu.sh` mediante Rofi: permite bloquear inmediatamente con `i3lock` y exige confirmación antes de cerrar sesión, reiniciar o apagar; el instalador nunca invoca esas acciones. Los scripts `vpn-status.sh` y `target-status.sh` siempre producen salida válida aunque no exista interfaz VPN o archivo de objetivo. Picom usa XRender con `use-damage = false` para evitar tarjetas que desaparecen por fallos de repintado de ventanas transparentes en VMware. Quedan preparados módulos futuros para VMware Tools, batería e IP local.

`wallpaper-cycle.sh` administra la colección bajo `~/.local/share/backgrounds/parrot-security-lab/`, recorre subcarpetas, conserva la selección en el estado XDG y rota cada 900 segundos. El daemon se inicia una sola vez con BSPWM. La primera tarjeta de Polybar avanza con clic izquierdo y muestra un selector Rofi con clic derecho. El instalador agrega el wallpaper inicial y una selección local de 9 fondos HackerOne 1920x1080; no depende de red ni elimina imágenes incorporadas por el usuario. La colección externa está fijada al commit `beaf5596a6bfcd7eec42d8866c153c748e6734b5` y conserva licencia y atribución CC BY-NC-SA 4.0.

## Decisiones de seguridad

- solo APT con repositorios, firmas, certificados y TLS configurados por Parrot;
- sin descargas o ejecución de scripts externos;
- sin Pacman, AUR ni imports desde `legacy/`;
- sin reinicios, apagados, cambios de shell, display manager ni servicios automáticos;
- rutas derivadas del usuario real y de XDG, nunca de un nombre personal;
- entradas de paquetes y componentes validadas antes de usarse.
