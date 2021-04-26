{
  description = "Env-like configuration with superpowers";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-20.09";

  outputs = { self, nixpkgs }: {

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

  };
}
