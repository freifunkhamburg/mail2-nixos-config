{ config, lib, pkgs, ... }:

let
  rspamdExtraConfig = pkgs.writeText "rspamd-extra.conf" ''
    secure_ip = [::1]
    options {
      filters: "chartable,dkim,dkim_signing,spf,surbl,regexp,fuzzy_check"
    }
    milter_headers {
      extended_spam_headers = true;
    }
    classifier {
      bayes {
        autolearn = true;
      }
    }
    dkim_signing {
      path = "/var/lib/rspamd/dkim/$domain.$selector.key";
      check_pubkey = true;
    }
  '';
in
{
  #networking.firewall.allowedTCPPorts = [ 110 143 993 995 ];
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "dkim-generate" ''
      if [ $# -ne 1 ]; then
        echo Usage: dkim-generate DOMAIN >&2
        exit 1
      fi
      rspamd=${pkgs.rspamd}/bin/rspamadm
      mkdir -p /var/lib/rspamd/dkim
      $rspamd dkim_keygen -b 2048 -d "$1" -s dkim | ${pkgs.gawk}/bin/awk '/^-/ {KEY= ! KEY; print; next} KEY {print} !KEY {print > "/dev/stderr"}' >/var/lib/rspamd/dkim/"$1".dkim.key 2>/var/lib/rspamd/dkim/"$1".dkim.dns
      ls -l /var/lib/rspamd/dkim/"$1".dkim.key /var/lib/rspamd/dkim/"$1".dkim.dns
    '') ];
  services.rspamd = {
    enable = true;
    # Just shove our own configuration up rspamd's rear end with high prio as the default configuration structure is a mess
    extraConfig = ''
        .include(try=true,priority=10,duplicate=merge) "${rspamdExtraConfig}"
      '';
    workers = {
      controller = {
        enable = true;
        extraConfig = ''
          secure_ip = [::1]
        '';
        bindSockets = [
          "[::1]:11334"
          { mode = "0666"; owner = config.variables.vmailUser; socket = "/run/rspamd/worker-controller.socket"; }
        ];
      };
      rspamd_proxy = {
        enable = true;
        type = "rspamd_proxy";
        count = 5; # TODO: match with postfix limits
        extraConfig = ''
          upstream "local" {
            self_scan = yes; # Enable self-scan
          }
        '';
        bindSockets = [
          { socket = config.variables.rspamdMilterSocket; mode = "0600"; owner = config.services.postfix.user; group = config.services.rspamd.group; }
        ];
      };
    };
  };
}
