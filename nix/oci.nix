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
      nixSnapshotter = inputs.nix-snapshotter.packages.${system}.default;

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
        oci-prod = nixSnapshotter.buildImage {
          name = "app";
          resolvedByNix = false;
          copyToRoot = [ appSrc ];
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
              "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
              "TZDIR=${pkgs.tzdata}/share/zoneinfo"
            ];
          };
        };
      };
    };
}
