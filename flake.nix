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
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        browsers =
          (builtins.fromJSON (builtins.readFile "${pkgs.playwright-driver}/browsers.json")).browsers;
        chromium-rev = (builtins.head (builtins.filter (x: x.name == "chromium") browsers)).revision;
      in
      {

        formatter = pkgs.nixfmt-tree;
        devShells.default =
          let
            fhs = pkgs.buildFHSEnv {
              name = "dev";
              targetPkgs =
                pkgs: with pkgs; [
                  nodejs_24
                  pnpm_11
                  typescript-language-server
                  nixfmt
                  playwright-driver.browsers
                ];
              runScript = "bash";
            };
          in
          pkgs.mkShell {
            packages = [ fhs ];
            shellHook = ''
              export PLAYWRIGHT_LAUNCH_OPTIONS_EXECUTABLE_PATH="${pkgs.playwright-driver.browsers}/chromium-${chromium-rev}/chrome-linux64/chrome";
              export PLAYWRIGHT_BROWSERS_PATH=${pkgs.playwright-driver.browsers}
              export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true
              export PLAYWRIGHT_HOST_PLATFORM_OVERRIDE="ubuntu-24.04"
              exec ${fhs}/bin/dev
            '';
          };
      }
    );

}
