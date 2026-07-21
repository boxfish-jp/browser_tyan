{ pkgs, chromium-rev }:

let
  fhs = pkgs.buildFHSEnv {
    name = "dev";
    targetPkgs =
      pkgs: with pkgs; [
        pkgs.pnpm_11
        pkgs.nodejs_24
        pkgs.biome
        pkgs.typescript-language-server
        pkgs.nixfmt
        pkgs.playwright-driver.browsers
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
}
