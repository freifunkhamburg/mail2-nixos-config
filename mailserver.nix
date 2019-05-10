{ config, pkgs, ... }:

{
  # Import some configuration as they are too long to be easily readable here
  imports = [ 
    ./dovecot.nix
    ./postfix.nix
    ./postfixadmin.nix
    ./roundcube.nix
    ./rspamd.nix
  ];
  users.groups."${config.variables.vmailGroup}" = { gid = config.variables.vmailGID; };
  users.users."${config.variables.vmailUser}" = {
    uid = config.variables.vmailUID;
    group = config.variables.vmailGroup;
    hashedPassword = "!";
  };
}
