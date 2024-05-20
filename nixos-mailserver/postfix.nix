{ config, lib, pkgs, ... }:

let
  submission_header_cleanup_regex = pkgs.writeText "submission_header_cleanup_regex" ''
    /^Received:.*by ${config.services.mymailserver.mailFQDN} \(Postfix/ IGNORE
  '';
  pfvirtual_mailbox_domains = pkgs.writeText "virtual_mailbox_domains.cf" ''
    dbpath = ${config.services.mymailserver.internal.pfadminDataDir}/postfixadmin.db
    query = SELECT domain FROM domain WHERE domain='%s' AND active = '1'
  '';
  pfvirtual_alias_maps = pkgs.writeText "virtual_alias_maps.cf" ''
    dbpath = ${config.services.mymailserver.internal.pfadminDataDir}/postfixadmin.db
    query = SELECT goto FROM alias WHERE address='%s' AND active = '1'
  '';
  pfvirtual_alias_domain_maps = pkgs.writeText "virtual_alias_domain_maps.cf" ''
    dbpath = ${config.services.mymailserver.internal.pfadminDataDir}/postfixadmin.db
    query = SELECT goto FROM alias,alias_domain WHERE alias_domain.alias_domain = '%d' and alias.address = ('%u' || '@' || alias_domain.target_domain) AND alias.active = 1 AND alias_domain.active='1'
  '';
  pfvirtual_alias_domain_catchall_maps = pkgs.writeText "virtual_alias_domain_catchall_maps.cf" ''
    dbpath = ${config.services.mymailserver.internal.pfadminDataDir}/postfixadmin.db
    query = SELECT goto FROM alias,alias_domain WHERE alias_domain.alias_domain = '%d' and alias.address = ('@' || alias_domain.target_domain) AND alias.active = 1 AND alias_domain.active='1'
  '';
  pfvirtual_mailbox_maps = pkgs.writeText "virtual_mailbox_maps.cf" ''
    dbpath = ${config.services.mymailserver.internal.pfadminDataDir}/postfixadmin.db
    query = SELECT maildir FROM mailbox WHERE username='%s' AND active = '1'
  '';
  pfvirtual_alias_domain_mailbox_maps = pkgs.writeText "virtual_alias_domain_mailbox_maps.cf" ''
    dbpath = ${config.services.mymailserver.internal.pfadminDataDir}/postfixadmin.db
    query = SELECT maildir FROM mailbox,alias_domain WHERE alias_domain.alias_domain = '%d' and mailbox.username = ('%u' || '@' || alias_domain.target_domain) AND mailbox.active = 1 AND alias_domain.active='1'
  '';
in
{
  # Configure Postfix to support SQLite
  nixpkgs.config.packageOverrides = pkgs: { postfix = pkgs.postfix.override { withSQLite = true; }; };
  # SSL/TLS specific configuration
  security.acme.certs."postfix.${config.services.mymailserver.mailFQDN}" = {
    domain = "${config.services.mymailserver.mailFQDN}";
    group = config.services.postfix.group;
    postRun = "systemctl restart postfix.service";
    # cheat by getting some settings from another certificate configured through nginx.
    webroot = config.security.acme.certs."${config.services.mymailserver.mailFQDN}".webroot;
  };
  # Make sure at least the self-signed certs are available before trying to start postfix
  systemd.services.postfix.after = [ "acme-selfsigned-certificates.target" ];

  # Setup Postfix
  networking.firewall.allowedTCPPorts = [ 25 465 587 ];
  services.postfix = {
    enable = true;
    enableSmtp = true;
    enableSubmission = true;
    config = {
      message_size_limit = "${toString (256 * 1024 * 1024)}";
      mydestination = "";
      myhostname = config.services.mymailserver.mailFQDN;
      mynetworks_style = "host";
      recipient_delimiter = "+";
      relay_domains = "";
      smtpd_milters = "unix:${config.services.mymailserver.internal.rspamdMilterSocket}";
      non_smtpd_milters = "unix:${config.services.mymailserver.internal.rspamdMilterSocket}";
      smtpd_sasl_path = config.services.mymailserver.internal.dovecotAuthSocket;
      smtpd_sasl_type = "dovecot";
      smtpd_tls_auth_only = "yes";
      smtpd_tls_chain_files = "/var/lib/acme/postfix.${config.services.mymailserver.mailFQDN}/full.pem";
      smtpd_tls_loglevel = "1";
      smtpd_tls_received_header = "yes";
      smtpd_tls_security_level = "may";
      smtp_tls_loglevel = "1";
      smtp_tls_security_level = "may";
      virtual_alias_maps = "proxy:sqlite:${pfvirtual_alias_maps}, proxy:sqlite:${pfvirtual_alias_domain_maps}, proxy:sqlite:${pfvirtual_alias_domain_catchall_maps}";
      virtual_mailbox_domains = "proxy:sqlite:${pfvirtual_mailbox_domains}";
      virtual_mailbox_maps = "proxy:sqlite:${pfvirtual_mailbox_maps}, proxy:sqlite:${pfvirtual_alias_domain_mailbox_maps}";
      virtual_transport = "lmtp:unix:${config.services.mymailserver.internal.dovecotLmtpSocket}";
    } // (
      if (config.services.mymailserver.logging == false) then
      {
        maillog_file = "/dev/null";
        maillog_file_prefixes = "/dev/null";
      }
      else
        {}
    );
    masterConfig.submission.args = [ "-o" "cleanup_service_name=submission_cleanup" ];
    masterConfig."submission_cleanup" = {
        command = "cleanup";
        args = [ "-o" "header_checks=regexp:${submission_header_cleanup_regex}" ];
        private = false;
        maxproc = 0;
    };
    masterConfig.submissions = {
      type = config.services.postfix.masterConfig.submission.type;
      private = config.services.postfix.masterConfig.submission.private;
      command = "smtpd";
      args = [
        "-o" "smtpd_tls_wrappermode=yes"
        "-o" "cleanup_service_name=submission_cleanup"
        "-o" "milter_macro_daemon_name=ORIGINATING"
        "-o" "smtpd_client_restrictions=permit_sasl_authenticated,reject"
        "-o" "smtpd_sasl_auth_enable=yes"
        "-o" "cleanup_service_name=submission_cleanup"
      ];
    };
    masterConfig.postlog = {
      type = "unix-dgram";
      private = false;
      maxproc = 1;
      command = "postlogd";
    };
    rootAlias = config.services.mymailserver.adminAddress;
    postmasterAlias = config.services.mymailserver.adminAddress;
  };
}
