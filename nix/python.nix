{
  inputs,
  ...
}:
{
  perSystem =
    { pkgs, system, ... }:
    let
      python = pkgs.python313;

      workspace = inputs.uv2nix.lib.workspace.loadWorkspace { workspaceRoot = ../.; };
      overlay = workspace.mkPyprojectOverlay { sourcePreference = "wheel"; };

      pythonBase = pkgs.callPackage inputs.pyproject-nix.build.packages { inherit python; };
      filteredSrc = pkgs.lib.fileset.toSource {
        root = ../.;
        fileset = pkgs.lib.fileset.unions [
          ../app
          ../pyproject.toml
        ];
      };

      pythonSet = pythonBase.overrideScope (
        pkgs.lib.composeManyExtensions [
          inputs.pyproject-build-systems.overlays.default
          overlay
          (_final: prev: {
            app = prev.app.overrideAttrs { src = filteredSrc; };
          })
        ]
      );

      venv = pythonSet.mkVirtualEnv "app-env" workspace.deps.default;
    in
    {
      _module.args = {
        inherit venv workspace pythonSet;
      };

      packages.default = pkgs.writeShellScriptBin "app" ''
        exec ${venv}/bin/python -m app "$@"
      '';
    };
}
