{
  ...
}:
{
  perSystem =
    {
      pkgs,
      venv,
      config,
      ...
    }:
    let
      varlock = pkgs.writeShellScriptBin "varlock" ''
        VARLOCK_DIR="''${XDG_CACHE_HOME:-$HOME/.cache}/varlock"
        VARLOCK_BIN="$VARLOCK_DIR/bin/varlock"
        if [ ! -x "$VARLOCK_BIN" ]; then
          echo "Installing varlock..." >&2
          ${pkgs.curl}/bin/curl -sSfL https://varlock.dev/install.sh \
            | ${pkgs.bash}/bin/bash -s -- --dir "$VARLOCK_DIR/bin" --force-no-brew
        fi
        exec "$VARLOCK_BIN" "$@"
      '';
    in
    {
      devShells.default = pkgs.mkShell {
        packages = [
          venv
          pkgs.uv
          pkgs.ruff
          pkgs.just
          pkgs.skopeo
          varlock
        ];
        shellHook = ''
          ${config.pre-commit.installationScript}
        '';
      };
    };
}
