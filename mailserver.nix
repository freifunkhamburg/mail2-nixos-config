{ config, pkgs, ... }:

let mymailserver = (import <nixpkgs> {}).pkgs.fetchgit {
    url = "https://codeberg.org/tokudan/nixos-mailserver.git";
    rev = "12562bc9fe2ba91eaf3098445e4af21a4a933596";
    sha256 = "1qs1dywrvy5cbd2yg8m04cvlf3djsfiqi684qvwx2lqvy0ngr77l";
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
