# Estrategia de pruebas

Todas las pruebas de esta fase son estáticas o trabajan en un directorio temporal. No instalan paquetes, no escriben en `/etc`, no controlan servicios y no requieren que el host sea Parrot.

## Comandos

```bash
bash tests/syntax-check.sh
bash tests/static-analysis.sh
bash tests/smoke-test.sh
# Solo dentro de Parrot o Debian con los repositorios objetivo configurados:
bash tests/package-candidates.sh
bash tests/package-installability.sh
git diff --check
```

`syntax-check.sh` ejecuta `bash -n` sobre cada script activo y excluye `legacy/`, porque el código histórico se conserva sin soporte.

`static-analysis.sh` busca gestores Arch, desactivación de firmas y rutas personales en el código activo. Ejecuta ShellCheck si está instalado. Si no está disponible muestra `NO EJECUTADO`; esa parte no se declara exitosa.

`smoke-test.sh` comprueba estructura y permisos, simula Parrot/VMware, ejecuta el instalador completo con `--dry-run`, verifica que no se escriba en el home simulado y prueba backup/despliegue únicamente dentro de un temporal.

## Pruebas manuales seguras

```bash
./install.sh --help
./install.sh --components base,desktop,vmware,security-lab --dry-run
./scripts/lab-update.sh --dry-run
./scripts/openssh-backports-fix.sh --dry-run
```

`lab-update.sh --check` consulta actualizaciones usando los índices locales y
no modifica el sistema. `--upgrade` requiere confirmación explícita y ejecuta
`sudo parrot-upgrade`; debe probarse solo dentro de una VM con snapshot.

`scripts/openssh-backports-fix.sh` no forma parte de `install.sh` ni de sus componentes; es una utilidad manual independiente, sin relación con OpenVPN (el componente `base` ya instala `openvpn` mediante `packages/base.txt`, un paquete sin dependencias de SSH). En Parrot, `openssh-client` puede quedar instalado desde `*-backports` mientras `openssh-server`/`openssh-sftp-server` siguen en el repositorio estable; `openssh-server` exige la misma versión exacta de `openssh-client`, por lo que `apt install openssh-server` falla por dependencias no satisfechas. El script mantiene su propio flujo APT para reparar ese caso concreto y reinstala el trío SSH desde el mismo backports que ya usa `openssh-client`.

En un sistema que no sea Parrot, el segundo comando debe rechazar la ejecución. El smoke test usa las inyecciones restringidas de prueba para recorrer el flujo sin depender del host.

## Matriz pendiente en VM Parrot

- Reevaluar `smbclient`, `enum4linux-ng`, `theharvester`, `routersploit`, `gdb-multiarch` y `plaso`; Parrot 7.3 no resuelve actualmente sus dependencias sin forzar versiones o backports.
- Confirmar que `scripts/openssh-backports-fix.sh` alinea correctamente `openssh-client`/`openssh-server`/`openssh-sftp-server` en una VM con el desajuste stable/backports.
- Instalar Suricata solo bajo autorización explícita: su paquete habilita `suricata.service` durante la postinstalación.
- Confirmar `ID=parrot` y campos reales de `/etc/os-release`.
- Validar cada nombre mediante `apt-cache show` y registrar versión disponible.
- Confirmar Node.js 18 o superior, npm con prefijo de usuario, pipx, `rg`, `fd` y ShellCheck.
- Confirmar autosuggestions, syntax highlighting, `Ctrl-R` con fzf, `z`, `zi`, direnv y doble `Esc` en una sesión Zsh interactiva.
- Confirmar que `google-chrome-stable` se instala desde `https://dl.google.com/linux/chrome/deb/` y que APT valida su firma con el keyring dedicado.
- Abrir Firefox, comprobar Wappalyzer en `about:addons` y confirmar que se instaló desde Mozilla Add-ons sin reemplazar otras políticas.
- Verificar las herramientas del componente `security-lab` sin ejecutar ataques ni escaneos contra terceros.
- Probar Parrot actualizado en VMware con snapshot recuperable.
- Confirmar resolución dinámica, clipboard y sincronización horaria.
- Confirmar que la sesión BSPWM mantiene un proceso `vmtoolsd -n vmusr` y que VMware tiene habilitado Guest Isolation para copiar/pegar.
- Identificar nombres reales de unidades de open-vm-tools sin habilitarlas automáticamente.
- Probar `vmhgfs-fuse` con una carpeta compartida configurada.
- Iniciar BSPWM desde el display manager ya existente, sin reemplazarlo.
- Verificar diez escritorios con uno y dos monitores virtuales.
- Probar audio Pulse/PipeWire, Polybar, Rofi, Picom, Dunst y Flameshot.
- Mantener Polybar visible durante varios ciclos de actualización y confirmar que ninguna tarjeta desaparece con `use-damage = false` en VMware.
- Agregar varios PNG/JPEG/WebP a la carpeta de wallpapers, probar siguiente/selector y verificar la rotación automática tras 900 segundos.
- Confirmar los 9 fondos HackerOne 1920x1080 seleccionados, `LICENSE`, `README.upstream.md` y `ATTRIBUTION.txt` tanto en `assets/` como después del despliegue.
- Probar el bloqueo con `i3lock` y confirmar por separado cierre de sesión, reinicio y apagado desde el menú Rofi.
- Verificar interfaces Ethernet/Wi-Fi reales para el módulo de red.
- Guardar un perfil HTB en `Entornos/VPN`, confirmar que Git lo ignora y probar
  selección, autorización KSSHAskPass, conexión, desconexión y apertura del log.
- Probar `tun*`, `tap*` y `wg*` para estado VPN y provocar de forma controlada
  un perfil inválido para verificar `VPN ERR` y la notificación de Dunst.
- Revisar fuentes disponibles; la configuración usa `monospace` para no depender de Nerd Fonts.
- Ejecutar ShellCheck en VM si no está disponible en el host de revisión.
- Ejecutar una segunda instalación y confirmar que no se crean backups ni cambios innecesarios.
- Restaurar manualmente un dotfile desde backup y documentar el procedimiento operativo.

Una prueba no se registra como superada si la herramienta o el entorno requerido no está disponible.
