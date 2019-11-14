{ sources ? import ./sources.nix, system ? builtins.currentSystem }:
with
  { overlay = _: pkgs:
    let
      haskellnix = pkgs.haskell-nix;
      mkPackages = ghc:
        let
          pkgSet = haskellnix.mkStackPkgSet {
            stack-pkgs = import ./stack/pkgs.nix;
            pkg-def-extras = [];
            modules = [{
                packages.ghcide.src = sources.ghcide;
                ghc.package = ghc; 
                compiler.version = pkgs.lib.mkForce ghc.version;
                nonReinstallablePkgs = ["ghc-boot" "binary" "process" "bytestring" "containers" "directory" 
                   "filepath" "hpc" "ghci" "terminfo" "time" "transformers" "unix" "text"]
                ++ pkgs.lib.optionals (ghc.version == "8.8.1") [ "contravariant" ];
            }];
          };
        in pkgSet.config.hsPkgs;
      mkHieCore = ghc:
        let packages = mkPackages ghc;
        in packages.ghcide.components.exes.ghcide;
    in { export = {
          # ghcide-ghc881 = mkHieCore pkgs.haskell-nix.compiler.ghc881;
          ghcide-ghc865 = mkHieCore pkgs.haskell-nix.compiler.ghc865;
          ghcide-ghc864 = mkHieCore pkgs.haskell-nix.compiler.ghc864;
          ghcide-ghc844 = mkHieCore pkgs.haskell-nix.compiler.ghc844;
          hie-bios = (mkPackages pkgs.haskell-nix.compiler.ghc865).hie-bios.components.exes.hie-bios;
          haskellnix = haskellnix;
         };

         devTools = {
           inherit (import sources.niv {}) niv;
           inherit (haskellnix) nix-tools;
         };
         inherit haskellnix;
      };
  };
let
  haskell-nix = import sources."haskell.nix";
in
import sources.nixpkgs
  {
    overlays = haskell-nix.overlays ++ [ overlay ];
    config = haskell-nix.config;
    inherit system;
  }
