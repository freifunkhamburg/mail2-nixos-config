{ config, lib, pkgs, ... }:

let
  hopglass-fe = (pkgs.callPackage ./pkg-hopglass-fe.nix {
    conf = ./hopglass-frontend.config.json;
  } );
in
{
  services.nginx.virtualHosts."map2.hamburg.freifunk.net" = {
    forceSSL = true;
    enableACME = true;
    root = "${hopglass-fe}";
    extraConfig = ''
      access_log off;
    '';
    locations."/" = {
        extraConfig = ''
          index index.html;
          etag off;
          add_header etag "\"${builtins.substring 11 32 hopglass-fe}\"";
        '';
    };
  };
}
