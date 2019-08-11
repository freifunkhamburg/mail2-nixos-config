{ config, lib, pkgs, ... }:

{
  services.nginx = {
    logError = "/dev/null";
    appendConfig = ''
      access_log off;
    '';
  };
}
