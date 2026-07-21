{
  description = "ヘッドレスブラウザちゃん";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    let
      nixosModule = { pkgs, ... }: {
        imports = [ ./nix/nixos_module.nix ];
        nixpkgs.overlays = [ (final: prev: {
          browser-tyan = self.packages.${pkgs.system}.default;
        }) ];
      };

      perSystem = flake-utils.lib.eachDefaultSystem (
        system:
        let
          pname = "browser-tyan";
          pkgs = import nixpkgs { inherit system; };
          pnpm = pkgs.pnpm_11;
          node = pkgs.nodejs_24;
          src = ./.;
          version = "v1.1";
          browsers =
            (builtins.fromJSON (builtins.readFile "${pkgs.playwright-driver}/browsers.json")).browsers;
          chromium-rev = (builtins.head (builtins.filter (x: x.name == "chromium") browsers)).revision;
        in
        {
          formatter = pkgs.nixfmt-tree;
          devShells.default = (import ./nix/dev_shell.nix) { inherit pkgs chromium-rev; };
          packages.default = (import ./nix/package.nix) {
            inherit pkgs pname version src node pnpm chromium-rev;
          };
        }
      );
    in
    perSystem // {
      nixosModules.default = nixosModule;
    };

}
