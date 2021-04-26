{
  description = "Env-like configuration with superpowers";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-20.03";

  outputs = { self, nixpkgs }: {

    defaultPackage.x86_64-linux =
      with import nixpkgs { system = "x86_64-linux"; };
      stdenv.mkDerivation {
        name = "envy.sh";
        src = self;
        phases = [ "installPhase" ];
        installPhase = ''
          mkdir -p $out/bin
          cp $src/envy.sh $out/bin
        '';
      };

  };
}
