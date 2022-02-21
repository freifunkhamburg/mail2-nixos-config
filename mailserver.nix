{ config, pkgs, ... }:

let
  spamfilter_greenlight_map = pkgs.writeText "spamfilter_greenlight_map.cf" ''
    # Disable Milters for specific clients
    2a00:14b0:4200:3000:122::1/128    DISABLE
    212.12.48.122/32                  DISABLE
    '';
in
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
  # Special config
  services.postfix.config = {
    smtpd_milter_maps = "cidr:${spamfilter_greenlight_map}";
  };
}
