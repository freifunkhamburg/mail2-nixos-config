{ pkgs, ... }:

let
  borgPassCommand = pkgs.writeScript "borgPassCommand" ''
    #!${pkgs.stdenv.shell}
    set -euo pipefail
    # Make sure everything but the password ends up on stderr
    exec 3>&1 >&2
    mkdir -p /var/lib/borgbackup
    chown root:root /var/lib/borgbackup
    chmod 700 /var/lib/borgbackup
    if [ ! -s /var/lib/borgbackup/sshkey ]; then
      ${pkgs.openssh}/bin/ssh-keygen -t rsa -b 4096 -N "" -f /var/lib/borgbackup/sshkey
    fi
    if [ ! -s /var/lib/borgbackup/repokey ]; then
      head -c 1024 /dev/urandom | base64 > /var/lib/borgbackup/repokey
      chmod 400 /var/lib/borgbackup/repokey
    fi
    # Password needs to go into fd 3 as that is the real stdout
    cat /var/lib/borgbackup/repokey >&3
    '';
in
{
  services.borgbackup.jobs.postfixadmin = {
    readWritePaths = [ "/var/lib/borgbackup" ];
    paths = "/var/lib/postfixadmin";
    exclude = [  ];
    repo = "mail2@host01.hamburg.freifunk.net:postfixadmin";
    prune.keep = {
      within = "2d";
      daily = 7;
      weekly = 2;
    };
    encryption = {
      mode = "repokey";
      passCommand = "${borgPassCommand}";
    };
    environment = {
      BORG_RSH = "${pkgs.openssh}/bin/ssh -i /var/lib/borgbackup/sshkey";
    };
    compression = "auto,lz4";
    startAt = "hourly";
    extraArgs = "--info";
    extraCreateArgs = "--stats";
  };
  services.borgbackup.jobs.maildata = {
    readWritePaths = [ "/var/lib/borgbackup" ];
    paths = "/var/vmail";
    exclude = [  ];
    repo = "mail2@host01.hamburg.freifunk.net:maildata";
    prune.keep = {
      daily = 7;
      weekly = 2;
    };
    encryption = {
      mode = "repokey";
      passCommand = "${borgPassCommand}";
    };
    environment = {
      BORG_RSH = "${pkgs.openssh}/bin/ssh -i /var/lib/borgbackup/sshkey";
    };
    compression = "auto,lz4";
    startAt = "daily";
    extraArgs = "--info";
    extraCreateArgs = "--stats";
  };
  services.borgbackup.jobs.gitolite = {
    readWritePaths = [ "/var/lib/borgbackup" ];
    paths = "/srv/gitolite";
    exclude = [  ];
    repo = "mail2@host01.hamburg.freifunk.net:gitolite";
    prune.keep = {
      daily = 7;
      weekly = 2;
    };
    encryption = {
      mode = "repokey";
      passCommand = "${borgPassCommand}";
    };
    environment = {
      BORG_RSH = "${pkgs.openssh}/bin/ssh -i /var/lib/borgbackup/sshkey";
    };
    compression = "auto,lz4";
    startAt = "daily";
    extraArgs = "--info";
    extraCreateArgs = "--stats";
  };
}
