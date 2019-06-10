{ pkgs, ... }:

let
  sshkeys = pkgs.fetchFromGitHub {
    owner = "freifunkhamburg";
    "repo" = "ssh-keys";
    rev = "70a8f1a4b8ddf921579986fb08b45050abeef2bc";
    sha512 = "05p3ypg5imjxiswsspiix1l783w11ddby78bwjv0dnppbz8i4ddiy8fz70vcz4q2fbb94kwnk5zm7mz53h24z3j97xq9d485nmxinpq";
  };
  getpubkeys = user: builtins.readFile "${sshkeys}/${user}.pub";
  mkuser = user: { name = user; isNormalUser = true; extraGroups = [ "wheel" ]; initialPassword = "test1234"; openssh.authorizedKeys.keys = [ (getpubkeys user) ]; };
  mkusers = users: map (mkuser) users;
in
{
  users.users = mkusers [ "tokudan" "Entil_Zha" "alexander" ];
}
