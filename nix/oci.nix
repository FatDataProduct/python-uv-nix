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

      nixSnapshotter = inputs.nix-snapshotter.packages.${system}.nix-snapshotter;

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

      nixImage = nixSnapshotter.buildImage {
        name = "app";
        resolvedByNix = true;
        copyToRoot = [ appSrc ];
        config = {
          entrypoint = [
            "${venv}/bin/python"
            "-m"
            "app"
          ];
        };
      };
    in
    {
      packages = {
        skopeo = inputs.nix2container.packages.${system}.skopeo-nix2container;

        # OCI image for GHCR (works on any node)
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

        # nix-snapshotter image for NixOS k3s nodes (per-package dedup via snix)
        nix-image = nixImage;

        # Image reference for CI/CD substitution into k8s manifests
        nix-image-ref = pkgs.writeText "nix-image-ref.txt" nixImage.image;
      };
    };
}
