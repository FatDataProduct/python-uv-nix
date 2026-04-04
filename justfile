default:
    @just --list

# Run the app locally with env vars
dev:
    varlock run -- python -m app

# Run via nix (fully isolated, no container)
run:
    nix run

# Run tests
test:
    python -m pytest tests/ -v

# Lint source code
lint:
    ruff check app/

# Format all code (Python + Nix)
fmt:
    nix fmt

# Run all checks (lint, format, nix evaluation)
check:
    nix flake check

# Build OCI container image
container:
    nix build .#oci-prod

# Push OCI image to registry
push registry:
    skopeo --insecure-policy copy "nix:$(nix build .#oci-prod --print-out-paths --no-link)" "docker://{{registry}}"

# Add Python dependencies and update lock
add +packages:
    uv add {{packages}}

# Remove Python dependencies
remove +packages:
    uv remove {{packages}}

# Sync venv from lockfile
sync:
    uv sync

# Regenerate lock from pyproject.toml
lock:
    uv lock

# Update all flake inputs
update:
    nix flake update

# Initialize varlock env schema from existing .env files
init-env:
    varlock init
