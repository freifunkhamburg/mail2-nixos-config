{ config, lib, pkgs, ... }:

let
  pfvirtual_mailbox_domains = pkgs.writeText "virtual_mailbox_domains.cf" ''
    dbpath = ${config.variables.pfadminDataDir}/postfixadmin.db
    query = SELECT domain FROM domain WHERE domain='%s' AND active = '1'
  '';
  pfvirtual_alias_maps = pkgs.writeText "virtual_alias_maps.cf" ''
    dbpath = ${config.variables.pfadminDataDir}/postfixadmin.db
    query = SELECT goto FROM alias WHERE address='%s' AND active = '1'
  '';
  pfvirtual_alias_domain_maps = pkgs.writeText "virtual_alias_domain_maps.cf" ''
    dbpath = ${config.variables.pfadminDataDir}/postfixadmin.db
    query = SELECT goto FROM alias,alias_domain WHERE alias_domain.alias_domain = '%d' and alias.address = ('%u' || '@' || alias_domain.target_domain) AND alias.active = 1 AND alias_domain.active='1'
  '';
  pfvirtual_alias_domain_catchall_maps = pkgs.writeText "virtual_alias_domain_catchall_maps.cf" ''
    dbpath = ${config.variables.pfadminDataDir}/postfixadmin.db
    query = SELECT goto FROM alias,alias_domain WHERE alias_domain.alias_domain = '%d' and alias.address = ('@' || alias_domain.target_domain) AND alias.active = 1 AND alias_domain.active='1'
  '';
  pfvirtual_mailbox_maps = pkgs.writeText "virtual_mailbox_maps.cf" ''
    dbpath = ${config.variables.pfadminDataDir}/postfixadmin.db
    query = SELECT maildir FROM mailbox WHERE username='%s' AND active = '1'
  '';
  pfvirtual_alias_domain_mailbox_maps = pkgs.writeText "virtual_alias_domain_mailbox_maps.cf" ''
    dbpath = ${config.variables.pfadminDataDir}/postfixadmin.db
    query = SELECT maildir FROM mailbox,alias_domain WHERE alias_domain.alias_domain = '%d' and mailbox.username = ('%u' || '@' || alias_domain.target_domain) AND mailbox.active = 1 AND alias_domain.active='1'
  '';
in
{
  # Configure Postfix to support SQLite
  nixpkgs.config.packageOverrides = pkgs: { postfix = pkgs.postfix.override { withSQLite = true; }; };
  # SSL/TLS specific configuration
  security = lib.mkIf config.variables.useSSL {
    # Configure the certificates...
    acme.certs."postfix.${config.variables.myFQDN}" = {
      domain = "${config.variables.myFQDN}";
      group = config.services.postfix.group;
      allowKeysForGroup = true;
      postRun = "systemctl restart postfix.service";
      # cheat by getting some settings from another certificate configured through nginx.
      user = config.security.acme.certs."${config.variables.myFQDN}".user;
      webroot = config.security.acme.certs."${config.variables.myFQDN}".webroot;
    };
  };
  systemd = lib.mkIf config.variables.useSSL {
    # Make sure at least the self-signed certs are available before trying to start postfix
    services.postfix.after = [ "acme-selfsigned-certificates.target" ];
  };

  # Setup Postfix
  networking.firewall.allowedTCPPorts = [ 25 587 ];
  services.postfix = {
    enable = true;
    enableSmtp = true;
    enableSubmission = true;
    config = {
      mydestination = "";
      myhostname = config.variables.myFQDN;
      mynetworks_style = "host";
      recipient_delimiter = "+";
      relay_domains = "";
      smtpd_milters = "unix:${config.variables.rspamdMilterSocket}";
      non_smtpd_milters = "unix:${config.variables.rspamdMilterSocket}";
      smtpd_sasl_path = config.variables.dovecotAuthSocket;
      smtpd_sasl_type = "dovecot";
      smtpd_tls_auth_only = "yes";
      smtpd_tls_chain_files = lib.mkIf config.variables.useSSL "/var/lib/acme/postfix.${config.variables.myFQDN}/full.pem";
      smtpd_tls_loglevel = "1";
      smtpd_tls_received_header = "yes";
      smtpd_tls_security_level = "may";
      smtp_tls_loglevel = "1";
      smtp_tls_security_level = "may";
      virtual_alias_maps = "proxy:sqlite:${pfvirtual_alias_maps}, proxy:sqlite:${pfvirtual_alias_domain_maps}, proxy:sqlite:${pfvirtual_alias_domain_catchall_maps}";
      virtual_mailbox_domains = "proxy:sqlite:${pfvirtual_mailbox_domains}";
      virtual_mailbox_maps = "proxy:sqlite:${pfvirtual_mailbox_maps}, proxy:sqlite:${pfvirtual_alias_domain_mailbox_maps}";
      virtual_transport = "lmtp:unix:${config.variables.dovecotLmtpSocket}";
    };
    rootAlias = config.variables.mailAdmin;
    postmasterAlias = config.variables.mailAdmin;
  };
}
