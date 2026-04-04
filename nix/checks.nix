{ ... }:
{
  perSystem =
    { pkgs, venv, ... }:
    {
      pre-commit.settings.hooks = {
        ruff.enable = true;
        ruff-format.enable = true;
        nixfmt-rfc-style.enable = true;
      };

      treefmt = {
        projectRootFile = "flake.nix";
        programs = {
          nixfmt.enable = true;
          ruff-check.enable = true;
          ruff-format.enable = true;
        };
      };
    };
}
