# Python + uv + Nix CI/CD

Reproducible Python project with OCI images built via nix2container.

CI/CD runs on **self-hosted NixOS runners** — no Nix installation step needed.
OCI images are pushed to **GitHub Container Registry** on every merge to `main`.

## Quick start

```bash
# From this template (GitHub "Use this template" button) or:
nix flake init -t github:FatDataProduct/python-uv-nix

nix develop   # enter devshell with all tools
just           # see available commands
```

## Commands

```bash
just dev               # run app with env vars (varlock)
just run               # run via nix (fully isolated)
just test              # pytest
just lint              # ruff check
just fmt               # format all (Python + Nix)
just check             # lint + format + nix checks
just container         # build OCI image
just push ghcr.io/o/a  # push image to registry
just add httpx         # add dependency
just remove httpx      # remove dependency
```

Standard `uv` commands work as usual: `uv add`, `uv sync`, `uv run`, etc.

## CI/CD Pipeline

| Job | Trigger | What |
|-----|---------|------|
| **Checks** | push, PR | format, flake check, `oci-prod` + `oci-nix` builds (parallel) |
| **Push GHCR** | merge to `main` | std + `-nix` теги |
| **Deploy** | merge to `main` | SSH → `kubectl --context front` (app-std) и `--context back` (app-nix) |

Раннеры: `runs-on: [nix]` (nspawn на perturabo, свои лейблы).

### Секреты GitHub Actions (деплой)

Деплой идёт по **SSH на jump-хост**, где в одном kubeconfig есть контексты **`front`** и **`back`** (мультикластер).

| Secret | Значение (пример для FatData Control) |
|--------|----------------------------------------|
| `SSH_HOST` | `89.111.170.51` — VPS «FatData Control», Ubuntu 24.04 |
| `SSH_USERNAME` | `root` (или пользователь с `kubectl` и тем же kubeconfig) |
| `SSH_PORT` | `22` |
| `SSH_PRIVATE_KEY` | приватный ключ **только** для этого деплоя (Ed25519), публичный ключ в `~/.ssh/authorized_keys` на VPS |

На сервере должны работать, например:

```bash
kubectl --context front get nodes
kubectl --context back get nodes
```

Пароль root с панели регистратора — **не** кладите в GitHub Secrets; для CI достаточно SSH-ключа. Пароль лучше сменить, если он попадал в открытый канал.

Установка секретов из CLI (пример):

```bash
gh secret set SSH_HOST -b"89.111.170.51" -R FatDataProduct/python-uv-nix
gh secret set SSH_USERNAME -b"root" -R FatDataProduct/python-uv-nix
gh secret set SSH_PORT -b"22" -R FatDataProduct/python-uv-nix
gh secret set SSH_PRIVATE_KEY < deploy_key.pem -R FatDataProduct/python-uv-nix
```

## Setup (without Nix)

| Tool | Purpose | Install |
|------|---------|---------|
| Python >=3.13 | runtime | `apt install python3` / `brew install python` |
| [uv](https://docs.astral.sh/uv/) | package manager | `curl -LsSf https://astral.sh/uv/install.sh \| sh` |
| [ruff](https://docs.astral.sh/ruff/) | linter + formatter | `uv tool install ruff` |
| [just](https://github.com/casey/just) | task runner | `cargo install just` / `brew install just` |

Nix is only required for OCI image builds (`nix build .#oci-prod`).

## Environment variables

Env vars are described in `.env.schema` ([varlock](https://varlock.dev)).

```bash
just init-env                      # create .env.schema from existing .env files
varlock run -- python -m app       # inject validated env vars
just dev                           # same thing, shorter
```

## Structure

```
flake.nix          # inputs + imports
nix/
  python.nix       # uv2nix workspace, venv, packages.default
  oci.nix          # OCI image (nix2container, 3 layers) + skopeo
  devshell.nix     # dev shell (uv, ruff, just, varlock, skopeo)
  checks.nix       # git-hooks, treefmt
app/               # Python package
pyproject.toml     # project metadata + dependencies
uv.lock            # pinned dependency versions
justfile           # short commands
.env.schema        # varlock env schema
```
