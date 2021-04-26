{
  description = "Env-like configuration with superpowers";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-20.09";
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

  outputs = { self, nixpkgs, bats-file, bats-assert, bats-support }: rec {

    defaultPackage.x86_64-linux =
      with import nixpkgs { system = "x86_64-linux"; };
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

    checks.x86_64-linux.test = with import nixpkgs { system = "x86_64-linux"; };
      stdenv.mkDerivation {
        name = "test.sh";
        src = self;
        buildInputs = [
          defaultPackage.x86_64-linux
          bats
          bats-assert
          bats-file
          bats-support
        ];
        phases = [ "buildPhase" ];
        buildPhase = ''
          export BATS_SUPPORT="${bats-support}"
          export BATS_ASSERT="${bats-assert}"
          export BATS_FILE="${bats-file}"
          mkdir -p $out
          cd $src/tests
          bats ./test.sh
        '';
      };

  };
}
