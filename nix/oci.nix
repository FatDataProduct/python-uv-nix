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

      nixSnapshotter = inputs.nix-snapshotter.packages.${system}.default;

      appSrc = pkgs.stdenv.mkDerivation {
        name = "app-src";
        src = pkgs.lib.fileset.toSource {
          root = ../.;
          fileset = ../app;
        };
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

        # n2c image for GHCR — real layers, works on any node
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
              "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
              "TZDIR=${pkgs.tzdata}/share/zoneinfo"
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

        # nix-snapshotter image — mount-based layers, NixOS k3s nodes only
        oci-nix = nixSnapshotter.buildImage {
          name = "app-nix";
          resolvedByNix = false;
          copyToRoot = [ appSrc ];
          config = {
            entrypoint = [
              "${venv}/bin/python"
              "-m"
              "app"
            ];
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
