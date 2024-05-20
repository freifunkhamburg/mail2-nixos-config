{ config, pkgs, ... }:

{
  # Import some configuration as they are too long to be easily readable here
  imports = [ 
    ./options.nix
    ./dovecot.nix
    ./postfix.nix
    ./postfixadmin.nix
    ./roundcube.nix
    ./rspamd.nix
  ];
  users.groups."${config.services.mymailserver.internal.vmailGroup}" = { gid = config.services.mymailserver.internal.vmailGID; };
  users.users."${config.services.mymailserver.internal.vmailUser}" = {
    isSystemUser = true;
    uid = config.services.mymailserver.internal.vmailUID;
    group = config.services.mymailserver.internal.vmailGroup;
    hashedPassword = "!";
  };
}
