{ config, lib, pkgs, ... }:

let
  dovecotSQL = pkgs.writeText "dovecot-sql.conf" ''
    driver = sqlite
    connect = ${config.services.mymailserver.internal.pfadminDataDir}/postfixadmin.db
    password_query = SELECT username AS user, password FROM mailbox WHERE username = '%Lu' AND active='1'
    user_query = SELECT username AS user FROM mailbox WHERE username = '%Lu' AND active='1'
  '';
  dovecotConf = pkgs.writeText "dovecot.conf" ''
    ${ lib.optionalString (config.services.mymailserver.logging == false) "log_path = /dev/null" }
    sendmail_path = /run/wrappers/bin/sendmail
    default_internal_user = ${config.services.dovecot2.user}
    default_internal_group = ${config.services.dovecot2.group}
    default_vsz_limit = 1024 M
    protocols = imap lmtp sieve

    ssl = yes
    ssl_cert = </var/lib/acme/dovecot2.${config.services.mymailserver.mailFQDN}/fullchain.pem
    ssl_key = </var/lib/acme/dovecot2.${config.services.mymailserver.mailFQDN}/key.pem
    ssl_dh = <${config.security.dhparams.params.dovecot2.path}

    disable_plaintext_auth = yes
    auth_mechanisms = plain login

    userdb {
        driver = sql
        args = ${dovecotSQL}
    }
    passdb {
        driver = sql
        args = ${dovecotSQL}
    }
    mail_home = ${config.services.mymailserver.internal.vmailBaseDir}/%Lu/
    mail_location = maildir:${config.services.mymailserver.internal.vmailBaseDir}/%Lu/Maildir
    mail_uid = ${toString config.services.mymailserver.internal.vmailUID}
    mail_gid = ${toString config.services.mymailserver.internal.vmailGID}

    service auth {
      unix_listener ${config.services.mymailserver.internal.dovecotAuthSocket} {
        user = ${config.services.postfix.user}
        group = ${config.services.postfix.group}
        mode = 0600
      }
    }

    service lmtp {
      unix_listener ${config.services.mymailserver.internal.dovecotLmtpSocket} {
        user = ${config.services.postfix.user}
        group = ${config.services.postfix.group}
        mode = 0600
      }
    }

    service stats {
      unix_listener stats-reader {
        user = ${config.services.dovecot2.user}
        group = ${config.services.dovecot2.group}
        mode = 0660
      }
      unix_listener stats-writer {
        user = ${config.services.dovecot2.user}
        group = ${config.services.dovecot2.group}
        mode = 0660
      }
    }

    protocol lmtp {
      mail_plugins = sieve
    }

    protocol imap {
      mail_plugins = $mail_plugins imap_sieve
    }
    imap_idle_notify_interval = 29 mins

    namespace inbox {
      inbox = yes
      location =
      mailbox Drafts {
        special_use = \Drafts
        auto = subscribe
      }
      mailbox Junk {
        special_use = \Junk
        auto = subscribe
      }
      mailbox Sent {
        special_use = \Sent
        auto = subscribe
      }
      mailbox Trash {
        special_use = \Trash
        auto = subscribe
      }
      mailbox Archive {
        special_use = \Archive
        auto = subscribe
      }
      prefix =
    }

    plugin {
      sieve_after = ${(pkgs.callPackage ./sieve-after.nix {}) }
      sieve_plugins = sieve_imapsieve sieve_extprograms
      # From elsewhere to Spam folder
      imapsieve_mailbox1_name = Junk
      imapsieve_mailbox1_causes = COPY
      imapsieve_mailbox1_before = file:${(pkgs.callPackage ./sieve-report-spam-ham.nix {})}/report-spam.sieve
      # From Spam folder to elsewhere
      imapsieve_mailbox2_name = *
      imapsieve_mailbox2_from = Junk
      imapsieve_mailbox2_causes = COPY
      imapsieve_mailbox2_before = file:${(pkgs.callPackage ./sieve-report-spam-ham.nix {})}/report-ham.sieve
      sieve_pipe_bin_dir = ${(pkgs.callPackage ./sieve-pipe-bin-dir.nix {})}
      sieve_global_extensions = +vnd.dovecot.pipe +vnd.dovecot.environment
    }
  '';
in
{
  # Configure certificates...
  security.acme.certs."dovecot2.${config.services.mymailserver.mailFQDN}" = {
    domain = "${config.services.mymailserver.mailFQDN}";
    group = config.services.dovecot2.group;
    postRun = "systemctl restart dovecot2.service";
    # cheat by getting the webroot from another certificate configured through nginx.
    webroot = config.security.acme.certs."${config.services.mymailserver.mailFQDN}".webroot;
  };
  # Make sure at least the self-signed certs are available before trying to start dovecot
  systemd.services.dovecot2.after = [ "acme-selfsigned-certificates.target" ];
  # Allow dovecot through the firewall
  networking.firewall.allowedTCPPorts = [ 143 993 4190 ];
  services.dovecot2 = {
    enable = true;
    configFile = "${dovecotConf}";
    modules = [ pkgs.dovecot_pigeonhole ];
  };
  systemd.services."vmail-setup" = {
    serviceConfig.Type = "oneshot";
    wantedBy = [ "multi-user.target" ];
      script = ''
        mkdir -p ${config.services.mymailserver.internal.vmailBaseDir}
        chown -c ${config.services.mymailserver.internal.vmailUser}:${config.services.mymailserver.internal.vmailGroup} ${config.services.mymailserver.internal.vmailBaseDir}
        chmod -c 0700 ${config.services.mymailserver.internal.vmailBaseDir}
      '';
  };
  security.dhparams = {
    enable = true;
    stateful = true;
    params = {
      dovecot2.bits = 4096;
    };
  };
}
