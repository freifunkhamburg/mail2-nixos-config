{ config, lib, pkgs, ... }:

let
  types = lib.types;
  mkOption = lib.mkOption;
  mkEnableOption = lib.mkEnableOption;
in
{
  options = {
    services.mymailserver = {
      enable = mkEnableOption "Enable mailserver config using dovecot, rspamd, postfix, postfixadmin and roundcube over nginx";
      logging = mkOption {
        type = types.bool;
        default = true;
        description = ''
          If set to false, redirects all logging by dovecot and postfix to /dev/null.
          '';
      };
      adminAddress = mkOption {
        type = types.str;
        description = ''
          Email address of the postmaster. Must be a valid address.
          This address will be added by default as target for the
          abuse, hostmaster, postmaster and webmaster addresses
          when setting up new domains in Postfix Admin.
          This also sets services.postfix.{postmasterAlias,rootAlias}.
          '';
      };
      mailFQDN = mkOption {
        type = types.str;
        default = config.networking.fqdn;
        description = ''
          This defines the hostname that the mailserver considers itself to be.
          It will try to automatically get an ACME certificates for dovecot and
          postfix this FQDN and postfix will use this as its own fqdn.
          Defaults to whatever networking.fqdn is set to, which requires both
          networking.{hostName,domainName} to be set.
          '';
      };
      pfaFQDN = mkOption {
        type = types.str;
        default = "pfa.${config.services.mymailserver.mailFQDN}";
        description = ''
          The domain under which the Postfix Admin tool will be reachable at through https.
          '';
      };
      pfaSetupPWHash = mkOption {
        type = with types; nullOr str;
        default = null;
        description = ''
          The PostfixAdmin setup password hash. Required to initialize PostfixAdmin.
          PostfixAdmin will tell you to set this hash in its config file after you entered
          a new password. The default value should never match any password.
          '';
      };
      roundcubeFQDN = mkOption {
        type = types.str;
        default = "${config.services.mymailserver.mailFQDN}";
        description = ''
          The domain under which roundcube will be reachable at through https.
          '';
      };
      # Variables used internally in multiple config files
      internal = {
        dovecotAuthSocket = mkOption { default = "/run/dovecot2/dovecot-auth"; };
        dovecotLmtpSocket = mkOption { default = "/run/dovecot2/dovecot-lmtp"; };
        pfadminDataDir = mkOption { default = "/var/lib/postfixadmin"; };
        postfixadminpkgCacheDir = mkOption { default = "/var/cache/postfixadmin"; };
        pfaGroup = mkOption { default = "pfadmin"; };
        pfaUser = mkOption { default = "pfadmin"; };
        roundcubeUser = mkOption { default = "roundcube"; };
        roundcubeGroup = mkOption { default = "roundcube"; };
        roundcubeDataDir = mkOption { default = "/var/lib/roundcube"; };
        rspamdMilterSocket = mkOption { default = "/run/rspamd/milter"; };
        vmailBaseDir = mkOption { default = "/var/vmail"; };
        vmailGID = mkOption { default = 10000; };
        vmailGroup = mkOption { default = "vmail"; };
        vmailUID = mkOption { default = 10000; };
        vmailUser = mkOption { default = "vmail"; };
        postfixadminpkg = mkOption { default = (pkgs.callPackage ./pkg-postfixadmin.nix {
          config = (pkgs.writeText "postfixadmin-config.local.php" ''
            <?php
            $CONF['configured'] = true;
            ${ lib.optionalString (config.services.mymailserver.pfaSetupPWHash != null) ''
              $CONF['setup_password'] = '${config.services.mymailserver.pfaSetupPWHash}';
              '' }
            $CONF['database_type'] = 'sqlite';
            $CONF['database_name'] = '${config.services.mymailserver.internal.pfadminDataDir}/postfixadmin.db';
            $CONF['password_expiration'] = 'NO';
            $CONF['encrypt'] = 'dovecot:BLF-CRYPT';
            $CONF['dovecotpw'] = "${pkgs.dovecot}/bin/doveadm pw";
            $CONF['generate_password'] = 'YES';
            $CONF['show_password'] = 'NO';
            $CONF['password_validation'] = array(
              # '/regular expression/' => '$PALANG key (optional: + parameter)',
              # '/.{5}/'                => 'password_too_short 5',      # minimum length 5 characters
              # '/([a-zA-Z].*){3}/'     => 'password_no_characters 3',  # must contain at least 3 characters
              # '/([0-9].*){2}/'        => 'password_no_digits 2',      # must contain at least 2 digits
            );
            $CONF['quota'] = 'NO';
            $CONF['fetchmail'] = 'NO';
            $CONF['recipient_delimiter'] = "+";
            $CONF['forgotten_user_password_reset'] = false;
            $CONF['forgotten_admin_password_reset'] = false;
            $CONF['aliases'] = '0';
            $CONF['mailboxes'] = '0';
            $CONF['default_aliases'] = array (
              'abuse' => '${config.services.mymailserver.adminAddress}',
              'hostmaster' => '${config.services.mymailserver.adminAddress}',
              'postmaster' => '${config.services.mymailserver.adminAddress}',
              'webmaster' => '${config.services.mymailserver.adminAddress}'
            );
            $CONF['footer_text'] = "";
            $CONF['footer_link'] = "";
            ?>
          '');
          cacheDir = config.services.mymailserver.internal.postfixadminpkgCacheDir;
        } ); };
      };
    };
  };
}
