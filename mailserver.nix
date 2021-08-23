{ config, pkgs, ... }:

let mymailserver = (import <nixpkgs> {}).pkgs.fetchgit {
    url = "https://codeberg.org/tokudan/nixos-mailserver.git";
    rev = "e99eb3c2686406611aebae271d81b6cb7715f6e7";
    sha256 = "01m1wm70fs637jps24sqyygx6lmgak4dwrd0055bf1xk564jc57j";
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
