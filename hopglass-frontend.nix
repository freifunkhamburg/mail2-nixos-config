{ config, lib, pkgs, ... }:

let
  hopglass-fe = (pkgs.callPackage ./pkg-hopglass-fe.nix {
    conf = ./hopglass-frontend.config.json;
  } );
in
{
  services.nginx.virtualHosts."map.hamburg.freifunk.net" = {
    forceSSL = true;
    enableACME = true;
    default = true;
    root = "${hopglass-fe}";
    extraConfig = ''
      access_log off;
      add_header Permissions-Policy "interest-cohort=()" always;
    '';
    locations."/" = {
        extraConfig = ''
          index index.html;
          etag off;
          add_header etag "\"${builtins.substring 11 32 hopglass-fe}\"";
          add_header Permissions-Policy "interest-cohort=()" always;
        '';
    };
  };
}
