{ config, pkgs, ... }:

let mymailserver = (import <nixpkgs> {}).pkgs.fetchgit {
    url = "https://codeberg.org/tokudan/nixos-mailserver.git";
    rev = "d4ce9a3484d252381d44d606be3b7506bf6ae46b";
    sha256 = "0zrvic41n433xxpgkp12v1w0m9mfb0cwfda71565vpsl7yk6hciy";
  };
in

{
  # Import some configuration as they are too long to be easily readable here
  imports = [ 
    #./dovecot.nix
    #./postfix.nix
    #./postfixadmin.nix
    #./roundcube.nix
    #./rspamd.nix
    "${mymailserver}/default.nix"
  ];
  networking.domain = "hamburg.freifunk.net";
  services.mymailserver = {
    enable = true;
    logging = false;
    adminAddress = "postmaster@mail.hamburg.freifunk.net";
    mailFQDN = "mail2.hamburg.freifunk.net";
  };
}
