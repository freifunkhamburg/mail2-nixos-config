{ config, lib, pkgs, ... }:

{
  services.nginx = {
    logError = "/dev/null";
  };
}
