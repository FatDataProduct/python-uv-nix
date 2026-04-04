{
  inputs,
  ...
}:
{
  perSystem =
    {
      pkgs,
      system,
      venv,
      ...
    }:
    let
      n2c = inputs.nix2container.packages.${system}.nix2container;

      appSrc = pkgs.stdenv.mkDerivation {
        name = "app-src";
        src = pkgs.lib.cleanSource ../.;
        phases = [ "installPhase" ];
        installPhase = ''
          mkdir -p $out/app
          cp -r $src/app $out/app/app
        '';
      };
    in
    {
      packages = {
        skopeo = inputs.nix2container.packages.${system}.skopeo-nix2container;

        oci-prod = n2c.buildImage {
          name = "app";
          config = {
            Entrypoint = [
              "${venv}/bin/python"
              "-m"
              "app"
            ];
            WorkingDir = "/app";
            Env = [
              "PYTHONDONTWRITEBYTECODE=1"
              "PYTHONUNBUFFERED=1"
            ];
          };
          layers = [
            (n2c.buildLayer {
              deps = [
                pkgs.cacert
                pkgs.tzdata
              ];
            })
            (n2c.buildLayer {
              deps = [ venv ];
              maxLayers = 1;
            })
            (n2c.buildLayer { deps = [ appSrc ]; })
          ];
        };
      };
    };
}
