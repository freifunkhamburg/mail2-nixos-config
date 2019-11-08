{ config, lib, pkgs, ... }:

{
  services.gitolite = {
    enable = true;
    dataDir = "/srv/gitolite";
    user = "git";
    group = "git";
    adminPubkey = "";
  };
}
