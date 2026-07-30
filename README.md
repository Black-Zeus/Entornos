# Entornos: Parrot Security Lab

Instalador modular para preparar una VM VMware con Parrot OS destinada a pentesting autorizado, Hack The Box, TryHackMe, security labs y desarrollo de herramientas.

Este repositorio no soporta Arch Linux, Kali Linux ni otras distribuciones. El material Arch anterior se conserva, sin mantenimiento, en `legacy/arch/` y no participa del instalador.

## Estado

Esta iteración entrega la arquitectura base, dotfiles normalizados y pruebas sin cambios de sistema. Los paquetes y la integración gráfica todavía deben validarse dentro de una VM Parrot con snapshot. Consulte [docs/testing.md](docs/testing.md).

## Uso seguro

Revise primero el plan sin aplicar cambios:

```bash
./install.sh --dry-run
./install.sh --components base,desktop,vmware --dry-run
```

Ayuda:

```bash
./install.sh --help
```

Una ejecución real requiere un usuario normal con sudo:

```bash
./install.sh --components base,desktop,vmware
```

El instalador rechaza sistemas no Parrot y sesiones root directas. No reinicia, no cambia la shell, no reemplaza el display manager y no habilita servicios.

## Componentes

- `base`: Git, utilidades CLI, Zsh, tmux y scripts de laboratorio.
- `desktop`: BSPWM, SXHKD, Polybar, Rofi, Picom, Kitty, Dunst y utilidades gráficas.
- `vmware`: open-vm-tools e integración de escritorio; servicios y carpetas compartidas quedan como pasos manuales documentados.

Las listas viven en `packages/`. `security-lab.txt` es un borrador deliberadamente vacío: no se instalan colecciones ofensivas masivas.

## Configuración

Los dotfiles versionados incluyen diez escritorios BSPWM, navegación y movimiento por teclado, terminal Kitty, lanzador Rofi, Polybar, Picom ligero, Dunst y wallpaper local. Polybar muestra CPU, memoria, red, volumen y reloj, además de estados seguros para VPN y objetivo.

Para definir un objetivo activo:

```bash
mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}/parrot-security-lab"
printf '%s %s\n' '10.10.10.10' 'maquina' > "${XDG_STATE_HOME:-$HOME/.local/state}/parrot-security-lab/target"
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
