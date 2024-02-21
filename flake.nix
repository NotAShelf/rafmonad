{
  description = "rafmonad: a annoyingly simple webserver";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = {
    self,
    nixpkgs,
  }: let
    supportedSystems = ["x86_64-linux"];
    forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);
    nixpkgsFor = forAllSystems (system:
      import nixpkgs {
        inherit system;
        overlays = [self.overlays.default];
      });
  in {
    overlays = final: _prev: {
      rafmonad = final.haskellPackages.callCabal2nix "rafmonad" ./. {};
      default = self.overlays.rafmonad;
    };

    packages = forAllSystems (system: {
      inherit (nixpkgsFor.${system}) rafmonad;
      default = nixpkgsFor.${system}.rafmonad;
    });

    checks = self.packages;

    devShell = forAllSystems (system: let
      inherit (nixpkgsFor.${system}) haskellPackages;
    in
      haskellPackages.shellFor {
        withHoogle = true;

        packages = _: [self.packages.${system}.rafmonad];
        buildInputs = with haskellPackages; [
          haskell-language-server
          ghcid
          cabal-install
        ];

        # Change the prompt to show that you are in a devShell
        shellHook = "export PS1='\\e[1;34mDEV ~ > \\e[0m'";
      });
  };
}
