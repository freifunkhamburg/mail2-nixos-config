{ config, pkgs, ... }:

{
  # Import some configuration as they are too long to be easily readable here
  imports = [ 
    #./dovecot.nix
    #./postfix.nix
    #./postfixadmin.nix
    #./roundcube.nix
    #./rspamd.nix
    (import (import ./nix/sources.nix).nixos-mailserver)
  ];
  networking.domain = "hamburg.freifunk.net";
  services.mymailserver = {
    enable = true;
    logging = false;
    adminAddress = "postmaster@mail.hamburg.freifunk.net";
    mailFQDN = "mail2.hamburg.freifunk.net";
  };
}
