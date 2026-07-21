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
        devShells.default =
          let
            fhs = pkgs.buildFHSEnv {
              name = "dev";
              targetPkgs =
                pkgs: with pkgs; [
                  pnpm
                  node
                  biome
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

        packages.default = pkgs.stdenv.mkDerivation (finalAttrs: {
          inherit src version pname;
          nativeBuildInputs = [
            pnpm
            node
            pkgs.pnpmConfigHook
          ];
          pnpmDeps = pkgs.fetchPnpmDeps {
            pname = "streamingkit";
            inherit version src pnpm;
            fetcherVersion = 4;
            hash = "sha256-SfiihhmAnsZxjDVckuEJ08lBCpclkQh8i5MHB+hYKh4=";
          };
          buildPhase = ''
            runHook preBuild
            pnpm install --frozen-lockfile
            pnpm run build
            runHook postBuild
          '';
          installPhase = ''
            runHook preInstall
            mkdir -p $out/lib/$pname
            cp -a . $out/lib/$pname
            mkdir -p $out/bin

            NODE_BIN="${node}/bin/node"

            cat > $out/bin/$pname <<EOF
            #!/usr/bin/env bash
            set -euo pipefail
            export PLAYWRIGHT_LAUNCH_OPTIONS_EXECUTABLE_PATH="${pkgs.playwright-driver.browsers}/chromium-${chromium-rev}/chrome-linux64/chrome";
            export PLAYWRIGHT_BROWSERS_PATH=${pkgs.playwright-driver.browsers}
            export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true
            export PLAYWRIGHT_HOST_PLATFORM_OVERRIDE="ubuntu-24.04"
            export NODE_PATH="${placeholder "out"}/lib/${pname}/node_modules"
            exec "$NODE_BIN" "${placeholder "out"}/lib/${pname}/dist/index.js" "\$@"
            EOF
            chmod +x $out/bin/$pname
            runHook postInstall
          '';
          meta = {
            description = "ヘッドレスブラウザちゃん";
            license = pkgs.lib.licenses.mit;
          };

        });
      }
    );

}
