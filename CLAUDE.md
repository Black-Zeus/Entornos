# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Modular Bash installer that provisions a VMware VM running Parrot OS for authorized pentesting, HTB/TryHackMe labs, and tool development. It targets **Parrot OS only** — no Arch, Kali, or other distros. Old Arch material is preserved unmaintained in `legacy/arch/`; the active installer never reads or imports it.

## Commands

Validate everything (static checks only, no system changes, works on any host):

```bash
./validate.sh
```

Individual checks:

```bash
bash tests/syntax-check.sh          # bash -n over all active scripts (excludes legacy/)
bash tests/static-analysis.sh       # forbids Arch tooling, disabled signature checks, personal paths; runs ShellCheck if present
bash tests/smoke-test.sh            # simulates Parrot/VMware via env injection, runs install.sh --dry-run end-to-end
git diff --check
```

Parrot/Debian-only checks (need real APT repos, run inside the target VM):

```bash
bash tests/package-candidates.sh
bash tests/package-installability.sh
```

Manual dry-run testing:

```bash
./install.sh --help
./install.sh --components base,desktop,vmware,security-lab --dry-run
./scripts/lab-update.sh --dry-run
```

`lab-update.sh --upgrade` es la única ruta del proyecto que actualiza la
distribución completa y usa `sudo parrot-upgrade` tras confirmación explícita.
`install.sh` solo refresca metadatos APT e instala los paquetes declarados.

There is no package manager / build step — this is a pure Bash project with flat text data files.

## Architecture

```
install.sh                 Orchestrator and CLI contract (parses args, calls lib/ functions in order)
lib/                        One file per concern: detection, logging, APT, backups, dotfile deploy
packages/                   Package lists per component, plain text
dotfiles/                   Versioned user config (bspwm, sxhkd, polybar, rofi, picom, kitty, dunst, zsh, tmux)
assets/                     Versioned local resources (e.g. wallpapers)
scripts/                    Operational scripts installed to ~/.local/bin
tests/                      Static/dry-run validations only — never touch a real system
docs/                       architecture.md (design decisions), testing.md, audit-report.md, keyboard-shortcuts.md
legacy/arch/                Historical Arch material, isolated, never touched by the installer
```

### Install flow (see `install.sh:main`)

1. Parse `--help` / `--dry-run` / `--components` (defaults to all four: `base,desktop,vmware,security-lab`).
2. Resolve the real (non-root) user; reject a direct root session.
3. Init logging (skipped in dry-run).
4. Require `ID=parrot` in `/etc/os-release` and x86-64 arch.
5. Detect VMware via `systemd-detect-virt`.
6. Verify dependencies, load APT package lists for selected components.
7. Validate package names with `apt-cache show` when available.
8. Real run only: `apt-get update` + install packages.
9. Deploy each dotfile only if changed, backing up the previous destination first.
10. Print summary: mode, user, arch, virtualization, components, recoverable/optional error counts.

`PARROT_INSTALLER_TESTING=1` (only valid together with `--dry-run`) injects a fake `os-release`, user, home, and virtualization for smoke tests — it can never trigger a real install.

### Components

- **base** — Google Chrome (official APT repo, key fingerprint pinned and verified), Firefox Wappalyzer extension (via policy, signed, `normal_installed`, backs up prior policy), Git/CLI utilities, `bat`, `lsd`, tmux, Zsh with Powerlevel10k/autosuggestions/syntax-highlighting/fzf/zoxide/direnv, double-`Esc` sudo toggle. Never changes the default shell.
- **desktop** — BSPWM, SXHKD, Polybar, Rofi, Picom (XRender, `use-damage = false` to avoid VMware repaint glitches, no blur/animations), Kitty, Dunst. Deploys to `~/.config`. Does not touch the display manager or `/usr/share/xsessions`.
- **vmware** — `open-vm-tools`(-desktop), optionally `fuse3`. Never enables services, mounts shared folders, or changes time policy — those are documented manual steps (see `docs/architecture.md`).
- **security-lab** — Node.js/npm (user-scoped npm prefix, no `sudo npm install -g`), Python/pipx, network utilities, and an explicit, auditable HTB/TryHackMe enumeration toolset. No offensive metapackages/bundles. Suricata is deliberately excluded from the automatic flow because its package enables `suricata.service` on postinst.

### Package list format (`packages/*.txt`, `packages/security-lab/*.txt`)

Lines are `required|optional <package-name>`. Loader processes scopes in order, dedupes, and `required` always wins over `optional` for a given package across scopes. `security-lab/*.txt` splits packages by operational scope (recon, network, web-fuzzing, vulnerability, active-directory, credentials, exploitation, forensics, logs) — see `lib/packages-apt.sh`.

### Error model

- **Critical** (wrong platform, direct root, missing essential dependency/package, failed deploy): abort, non-zero exit.
- **Recoverable** (e.g. VMware selected but not detected): continue, listed in summary.
- **Optional** (explicitly optional package/config): continue, listed separately in summary.

Exit codes: `0` ok, `2` usage, `3` unsupported platform/user, `4` dependency/package, `5` install/deploy operation.

### Idempotency and backups

`deploy_file` (in `lib/deploy-dotfiles.sh`) compares source and destination; identical files are not rewritten. On a real difference, the destination is copied to `~/.local/state/parrot-security-lab/backups/<timestamp>/` (preserving its absolute path) before being overwritten. Logs are written with `0600` permissions. Backups protect dotfiles only — they are not an APT package rollback.

## Security constraints (non-negotiable, enforced by `tests/static-analysis.sh`)

- APT only, using Parrot's existing repos/signatures/TLS — no external script downloads or execution.
- No Pacman/AUR, no imports from `legacy/`.
- No reboots, shutdowns, shell changes, display-manager changes, or auto-enabled services — the shutdown/reboot/lock actions in Polybar's power menu always require interactive confirmation and are never invoked by the installer itself.
- Paths are derived from the real user and XDG variables, never hardcoded personal paths.
- Package/component names are validated before use.

## Working conventions

- `set -Eeuo pipefail` at the top of every script; `lib/common.sh` provides `run_command` (dry-run aware), `require_command`, `record_recoverable`/`record_optional`, and the shared exit-code constants.
- Every `lib/*.sh` source line in `install.sh` is preceded by a `# shellcheck source=` comment — keep this in sync when adding a new lib file.
- Respect `DRY_RUN`: any state-changing action must go through `run_command` or be explicitly gated on `(( DRY_RUN ))`.
- `scripts/` files are deployed to `~/.local/bin` and must degrade gracefully (e.g. `vpn-status.sh`/`target-status.sh` must always produce valid output even absent the resource they report on).
