# Entornos: Parrot Security Lab

Instalador modular para preparar una VM VMware con Parrot OS destinada a pentesting autorizado, Hack The Box, TryHackMe, security labs y desarrollo de herramientas.

Este repositorio no soporta Arch Linux, Kali Linux ni otras distribuciones. El material Arch anterior se conserva, sin mantenimiento, en `legacy/arch/` y no participa del instalador.

## Estado

Esta iteración entrega la arquitectura base, dotfiles normalizados y pruebas sin cambios de sistema. Los paquetes y la integración gráfica todavía deben validarse dentro de una VM Parrot con snapshot. Consulte [docs/testing.md](docs/testing.md).

## Uso seguro

Revise primero el plan sin aplicar cambios:

```bash
./install.sh --dry-run
./install.sh --components base,desktop,vmware,security-lab --dry-run
```

Ayuda:

```bash
./install.sh --help
```

Una ejecución real requiere un usuario normal con sudo:

```bash
./install.sh --components base,desktop,vmware,security-lab
```

Sin `--components`, el instalador selecciona los cuatro componentes anteriores para reconstruir el laboratorio completo.

El instalador rechaza sistemas no Parrot y sesiones root directas. No reinicia, no cambia la shell, no reemplaza el display manager y no habilita servicios.

## Componentes

- `base`: Google Chrome estable, Wappalyzer para Firefox, Git, utilidades CLI, `bat`, `lsd`, tmux y Zsh con Powerlevel10k, autosuggestions, syntax highlighting, fzf, zoxide, direnv y doble `Esc` para alternar `sudo`.
- `desktop`: BSPWM, SXHKD, Polybar, Rofi, Picom, Kitty, Dunst y utilidades gráficas.
- `vmware`: open-vm-tools e integración de escritorio; servicios y carpetas compartidas quedan como pasos manuales documentados.

Polybar incluye un menú de energía operado con Rofi para bloquear con `i3lock`, cerrar la sesión BSPWM, reiniciar o apagar. Las acciones de cierre y energía requieren confirmación y nunca se ejecutan durante la instalación.

Los fondos viven en `~/.local/share/backgrounds/parrot-security-lab/` y rotan cada 15 minutos. En la primera tarjeta de Polybar, el clic izquierdo avanza al siguiente y el derecho abre un selector Rofi. Las imágenes nuevas pueden copiarse a esa carpeta sin modificar el instalador. El repositorio respalda localmente una selección de 9 fondos 1920x1080 de [HackerOne Wallpapers](https://github.com/Hacker0x01/wallpapers), fijados al commit `beaf5596a6bfcd7eec42d8866c153c748e6734b5` y distribuidos bajo CC BY-NC-SA 4.0 con licencia y atribución incluidas.
- `security-lab`: Node.js/npm, Python/pipx, utilidades de red y herramientas de enumeración para laboratorios autorizados.

Las listas viven en `packages/`. `security-lab.txt` mantiene una selección explícita y auditable; no instala metapaquetes ni colecciones ofensivas masivas. Los CLI que requieren autenticación se instalan posteriormente como usuario.

## Configuración

Los dotfiles versionados incluyen diez escritorios BSPWM, navegación y movimiento por teclado, terminal Kitty, lanzador Rofi, Polybar, Picom ligero, Dunst y wallpaper local. Polybar muestra CPU, memoria, red, volumen y reloj, además de estados seguros para VPN y objetivo.

Para definir, consultar o limpiar un objetivo activo:

```bash
target 10.10.10.10 maquina
target show
target clear
```

## Validación

```bash
git diff --check
bash tests/syntax-check.sh
bash tests/static-analysis.sh
bash tests/smoke-test.sh
```

La auditoría original está en [docs/audit-report.md](docs/audit-report.md) y las decisiones de diseño en [docs/architecture.md](docs/architecture.md).

## Seguridad y autorización

Use este proyecto solo sobre sistemas propios o con autorización explícita. El instalador conserva las políticas de firmas y TLS de APT, no ejecuta scripts remotos y crea backups antes de modificar dotfiles existentes.
