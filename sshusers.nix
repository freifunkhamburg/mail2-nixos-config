{ lib, pkgs, ... }:

# Setup users. To add a new user:
# 1. Add the name of the user to the list in the second-to-last line
# 2. Make sure that the git repo contains the key as "$USER.pub"
# 3. Make sure that the commit ("rev") contains the latest commit hash. If it correct, jump to step 7.
# 4. If you changed the commit, manipulate the sha512 entry by changing the first character from 0 to 1 or 1 to 0.
# 5. Run "nixos-rebuild build"
# 6. Wait for a message about an invalid hash and replace the hash in this file with the new one.
# 7. Run "nixos-rebuild switch"
# 8. Let the user login and change their password

let
  sshkeys = pkgs.fetchFromGitea {
    domain = "git.hamburg.ccc.de";
    owner = "freifunk";
    repo = "ssh-keys";
    rev = "6809bee81417ecbcc2f8333a234de9d41b8847cf";
    hash = "sha512-J5jg0U2KN00yvdozfwl9DQFyhhGY7n6wuOeandse+U34J+Ume0y3pOtk51EoWVEqWL41ptGZVcvJhhOWbIBmUw==";
  };
  getpubkeys = user: builtins.readFile "${sshkeys}/${user}.pub";
  mkuser = user: {
    name = user;
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    createHome = true;
    initialPassword = "test1234";
    openssh.authorizedKeys.keys = (
      lib.splitString "\n" (getpubkeys user)
      );
  };
in
{
  users.users = (lib.genAttrs [ "tokudan" "Entil_Zha" "alexander" "kantorkel" "djerun" "nico22" ] mkuser) // {
    jamonitor = { name = "jamonitor"; isNormalUser = true; extraGroups = [ "wheel" ]; openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCdIGniuakk1Li8gkpGABVBgkkUGGWYcM9qQRgcuYiKK/agidZ9KQ6YktOjakWsSPRpB2OHzr8GHaVpKMNlkAsq4W20d9RrO1+FrP96rNm/Op3X10SDNMdD5qcMq36BWxMig/8L75pbGqEZmcOi4/ZbgzaTh+lWTGG/1d2xwzi99BO0YeimDoZ+fAOqxfJAVirJVBuhqf+H9FGkD1G6zdDv+EzOnj4TT70LFNC90NoVFvus2nxVv8vY1kLLVSkNMIgZXn87A7GcmjrKUmONcfx/rgkt2VwsKS7Cj2YWz8ihiy7p5wg+oS/62BTFbKcLwwpcBaMwLiESuj1+fRgjwkwaqWcVeJAzjsAuLtGtIOWeWXCUlkyv9WoFE7he0tTB76tW5ysy3ibMmFE3duPAtn7Q3Rsu4n4UL2kKdtjVqFsW3AkTi+U7gsd17K84VoCf5Is2hNqKzjXBdCs/a57ZcrwOmMqGJZJp49XTW8EEAT/Emur0b2J4BcF4z/3oqrs/h8LIyoSjLhamT9EoODHb/6iz/xRbymCzoiu1CMRUQuqThlqe7uN5InjOyXbaWmjdN+svRik4CzQ9J+xCkuw+BzhwsPu8EKV5Yo4Uvpr6UTxXzuHN5GxrUFwD8d7VBSJPuY6DfhSNwCIPB2awUxXwFhdENM2zFWEbzGQcZ1DhUh3/5w=="
    ]; };
  };
  security.sudo.extraConfig = ''
    ## Allow the monitor user to run commands as root
    jamonitor       ALL=(ALL)       NOPASSWD: ALL
    '';
}
