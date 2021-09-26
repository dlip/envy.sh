{
  description = "Env-like configuration with superpowers";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.05";
    flake-utils.url = "github:numtide/flake-utils";
    bats-file = {
      url = "github:ztombol/bats-file";
      flake = false;
    };
    bats-assert = {
      url = "github:ztombol/bats-assert";
      flake = false;
    };
    bats-support = {
      url = "github:ztombol/bats-support";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, bats-file, bats-assert, bats-support }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          envy = with pkgs;
            stdenv.mkDerivation {
              name = "envy.sh";
              src = self;
              dontBuild = true;
              buildInputs = [ vault jq awscli2 ];
              nativeBuildInputs = [ makeWrapper ];
              installPhase = ''
                mkdir -p $out/bin
                cp $src/envy.sh $out/bin
              '';
              postFixup = ''
                wrapProgram $out/bin/envy.sh --prefix PATH : ${
                  lib.makeBinPath [ vault jq awscli2 ]
                }
              '';
            };
          dockerImage = pkgs.dockerTools.buildLayeredImage
            {
              name = "envy.sh";
              tag = "latest";
              config.Cmd = [ "${envy}/bin/envy.sh" ];
            };
        in
        rec {
          packages = flake-utils.lib.flattenTree {
            inherit envy;
          };
          defaultPackage = packages.envy;
          apps.envy = flake-utils.lib.mkApp { drv = packages.envy; };
          defaultApp = apps.envy;
          checks.test = with pkgs;
            stdenv.mkDerivation {
              name = "test.sh";
              src = self;
              buildInputs = [
                bats
                bats-assert
                bats-file
                bats-support
              ];
              phases = [ "buildPhase" ];
              buildPhase = ''
                export ENVY="${envy}/bin/envy.sh"
                export BATS_SUPPORT="${bats-support}"
                export BATS_ASSERT="${bats-assert}"
                export BATS_FILE="${bats-file}"
                mkdir -p $out
                cd $src/tests
                bats ./test.sh
              '';
            };
          hydraJobs = {
            inherit dockerImage;
            inherit defaultPackage;
          };
        }
      );
}
