{ lib, config, pkgs, ... }:

let
  cfg = config.services.browser-tyan;
  pkg = cfg.package;
in

{
  options.services.browser-tyan = {
    enable = lib.mkEnableOption "browser-tyan headless browser service";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.browser-tyan;
      defaultText = lib.literalExpression "pkgs.browser-tyan";
      description = "browser-tyan package to use";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = "Port for the HTTP server to listen on";
    };

    profileDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/browser-tyan/profile";
      description = "Directory to store the browser profile data";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open the configured port in the firewall";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];

    environment.systemPackages = [ pkg ];

    systemd.services.browser-tyan = {
      description = "browser-tyan headless browser service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        ExecStart = "${pkg}/bin/browser-tyan";
        Restart = "on-failure";
        DynamicUser = true;
        StateDirectory = "browser-tyan";
        Environment = [
          "BROWSER_TYAN_PORT=${toString cfg.port}"
          "BROWSER_TYAN_PROFILE_DIR=${cfg.profileDir}"
        ];
      };
    };
  };
}
