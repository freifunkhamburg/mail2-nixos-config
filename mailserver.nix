{ config, pkgs, ... }:

let mymailserver = (import <nixpkgs> {}).pkgs.fetchgit {
    url = "https://codeberg.org/tokudan/nixos-mailserver.git";
    rev = "4ace785a05f233392b6db6c82dcdd25599cd88dc";
    sha256 = "1cwj2k2w7316jby7l7fjcclbwjfs7p7ymyslw1cfh7y8vf2a32ii";
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
