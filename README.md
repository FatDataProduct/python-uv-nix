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
| **Check & Lint** | push, PR | `nix flake check` + `nix fmt --check` |
| **Build OCI** | push, PR | `nix build .#oci-prod` |
| **Push to GHCR** | merge to `main` | push `ghcr.io/org/repo:sha` + `:latest` |

Runs on self-hosted runners with labels `[self-hosted, nix]`.

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
