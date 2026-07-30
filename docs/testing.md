# Estrategia de pruebas

Todas las pruebas de esta fase son estáticas o trabajan en un directorio temporal. No instalan paquetes, no escriben en `/etc`, no controlan servicios y no requieren que el host sea Parrot.

## Comandos

```bash
bash tests/syntax-check.sh
bash tests/static-analysis.sh
bash tests/smoke-test.sh
git diff --check
```

`syntax-check.sh` ejecuta `bash -n` sobre cada script activo y excluye `legacy/`, porque el código histórico se conserva sin soporte.

`static-analysis.sh` busca gestores Arch, desactivación de firmas y rutas personales en el código activo. Ejecuta ShellCheck si está instalado. Si no está disponible muestra `NO EJECUTADO`; esa parte no se declara exitosa.

`smoke-test.sh` comprueba estructura y permisos, simula Parrot/VMware, ejecuta el instalador completo con `--dry-run`, verifica que no se escriba en el home simulado y prueba backup/despliegue únicamente dentro de un temporal.

## Pruebas manuales seguras

```bash
./install.sh --help
./install.sh --components base,desktop,vmware --dry-run
./scripts/lab-update.sh --dry-run
```

En un sistema que no sea Parrot, el segundo comando debe rechazar la ejecución. El smoke test usa las inyecciones restringidas de prueba para recorrer el flujo sin depender del host.

## Matriz pendiente en VM Parrot

- Confirmar `ID=parrot` y campos reales de `/etc/os-release`.
- Validar cada nombre mediante `apt-cache show` y registrar versión disponible.
- Probar Parrot actualizado en VMware con snapshot recuperable.
- Confirmar resolución dinámica, clipboard y sincronización horaria.
- Identificar nombres reales de unidades de open-vm-tools sin habilitarlas automáticamente.
- Probar `vmhgfs-fuse` con una carpeta compartida configurada.
- Iniciar BSPWM desde el display manager ya existente, sin reemplazarlo.
- Verificar diez escritorios con uno y dos monitores virtuales.
- Probar audio Pulse/PipeWire, Polybar, Rofi, Picom, Dunst y Flameshot.
- Verificar interfaces Ethernet/Wi-Fi reales para el módulo de red.
- Probar `tun*`, `tap*` y `wg*` para estado VPN.
- Revisar fuentes disponibles; la configuración usa `monospace` para no depender de Nerd Fonts.
- Ejecutar ShellCheck en VM si no está disponible en el host de revisión.
- Ejecutar una segunda instalación y confirmar que no se crean backups ni cambios innecesarios.
- Restaurar manualmente un dotfile desde backup y documentar el procedimiento operativo.

Una prueba no se registra como superada si la herramienta o el entorno requerido no está disponible.
