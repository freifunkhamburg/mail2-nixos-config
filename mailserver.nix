{ config, pkgs, ... }:

let mymailserver = (import <nixpkgs> {}).pkgs.fetchgit {
    url = "https://codeberg.org/tokudan/nixos-mailserver.git";
    rev = "15c419d488d1f4148f268d62fce0975f5a88a464";
    sha256 = "111xjmcvr7gq4406yxdj87wvi8psq3dhb7shkdsj5d4bdr9kr13q";
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
    adminAddress = "postmaster@mail.hamburg.freifunk.net";
    mailFQDN = "mail2.hamburg.freifunk.net";
  };
}
