{ config, lib, pkgs, ... }:

let
  dovecotSQL = pkgs.writeText "dovecot-sql.conf" ''
    driver = sqlite
    connect = ${config.variables.pfadminDataDir}/postfixadmin.db
    password_query = SELECT username AS user, password FROM mailbox WHERE username = '%Lu' AND active='1'
    user_query = SELECT username AS user FROM mailbox WHERE username = '%Lu' AND active='1'
  '';
  dovecotConfSSL = pkgs.writeText "dovecot.conf" ''
    ${lib.optionalString (config.variables.useSSL) ''
        ssl = yes
        ssl_cert = </var/lib/acme/dovecot2.${config.variables.myFQDN}/fullchain.pem
        ssl_key = </var/lib/acme/dovecot2.${config.variables.myFQDN}/key.pem
      ''
    }
  '';
  dovecotConf = pkgs.writeText "dovecot.conf" ''
    sendmail_path = /run/wrappers/bin/sendmail
    default_internal_user = dovecot2
    default_internal_group = dovecot2
    protocols = imap lmtp pop3 sieve

    # commented out due to a dovecot but in the most recent release
    #$ {lib.optionalString (config.variables.useSSL) '#'
    #    ssl = yes
    #    ssl_cert = </var/lib/acme/dovecot2.${config.variables.myFQDN}/fullchain.pem
    #    ssl_key = </var/lib/acme/dovecot2.${config.variables.myFQDN}/key.pem
    #  '#'
    #}
    !include_try /var/lib/dovecot/ssl-keys.conf

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
    mail_home = ${config.variables.vmailBaseDir}/%Lu/
    mail_location = maildir:${config.variables.vmailBaseDir}/%Lu/Maildir
    mail_uid = ${toString config.variables.vmailUID}
    mail_gid = ${toString config.variables.vmailGID}

    service auth {
      unix_listener ${config.variables.dovecotAuthSocket} {
        user = ${config.services.postfix.user}
        group = ${config.services.postfix.group}
        mode = 0600
      }
    }

    service lmtp {
      unix_listener ${config.variables.dovecotLmtpSocket} {
        user = ${config.services.postfix.user}
        group = ${config.services.postfix.group}
        mode = 0600
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
  security = lib.mkIf config.variables.useSSL {
    acme.certs."dovecot2.${config.variables.myFQDN}" = {
      email = "kontakt+blubb1@hamburg.freifunk.net";
      domain = "${config.variables.myFQDN}";
      group = config.services.dovecot2.group;
      postRun = "systemctl restart dovecot2.service";
      # cheat by getting the webroot from another certificate configured through nginx.
      webroot = config.security.acme.certs."${config.variables.myFQDN}".webroot;
    };
  };
  # Make sure at least the self-signed certs are available before trying to start postfix
  systemd.services.dovecot2.after = [ (lib.mkIf config.variables.useSSL "acme-selfsigned-certificates.target") "vmail-setup.service" ];
  # Setup dovecot
  networking.firewall.allowedTCPPorts = [ 110 143 993 995 4190 ];
  services.dovecot2 = {
    enable = true;
    configFile = "${dovecotConf}";
    modules = [ pkgs.dovecot_pigeonhole ];
  };
  systemd.services."vmail-setup" = {
    serviceConfig.Type = "oneshot";
    wantedBy = [ "multi-user.target" ];
      script = ''
        mkdir -p ${config.variables.vmailBaseDir}
        chown -c ${config.variables.vmailUser}:${config.variables.vmailGroup} ${config.variables.vmailBaseDir}
        chmod -c 0700 ${config.variables.vmailBaseDir}
        # SSL workaround for dovecot...
        mkdir -p /var/lib/dovecot
        cat ${dovecotConfSSL} > /var/lib/dovecot/ssl-keys.conf
        chown root:root /var/lib/dovecot/ssl-keys.conf
        chmod 400 /var/lib/dovecot/ssl-keys.conf
      '';
  };
}
