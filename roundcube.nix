{ config, lib, pkgs, ... }:

let
  poolName = "roundcube_pool";

  roundcube = (pkgs.callPackage ./pkg-roundcube.nix {
    conf = pkgs.writeText "roundcube-config.inc.php" ''
      <?php
      $config = array();
      $config['db_dsnw'] = 'sqlite:///${config.variables.roundcubeDataDir}/roundcube.sqlite?mode=0600';
      $config['default_host'] = 'tls://${config.variables.myFQDN}';
      $config['smtp_server'] = 'tls://${config.variables.myFQDN}';
      $config['smtp_port'] = 587;
      $config['smtp_user'] = '%u';
      $config['smtp_pass'] = '%p';
      $config['product_name'] = 'Webmail';
      $config['des_key'] = file_get_contents("${config.variables.roundcubeDataDir}/des_key");;
      $config['cipher_method'] = 'AES-256-CBC';
      $config['plugins'] = array(
        'archive',
        'managesieve',
        'zipdownload',
        );
      $config['skin'] = 'larry';
      '';
    temp = "${config.variables.roundcubeDataDir}/temp";
    logs = "${config.variables.roundcubeDataDir}/logs";
  } );
in
{
  services.nginx.virtualHosts."${config.variables.roundcubeFQDN}" = {
    forceSSL = config.variables.useSSL;
    enableACME = config.variables.useSSL;
    root = "${roundcube}/public_html";
    extraConfig = ''
      access_log off;
      add_header Permissions-Policy "interest-cohort=()" always;
      '';
    locations."~ ^/favicon.ico/.*$" = {
      extraConfig = ''
        try_files $uri kins/larry/images/$uri;
        add_header Permissions-Policy "interest-cohort=()" always;
        '';
    };
    locations."/" = {
      extraConfig = ''
        index index.php;
        try_files $uri /public/$uri /index.php$is_args$args;
        etag off;
        add_header etag "\"${builtins.substring 11 32 roundcube}\"";
        add_header Permissions-Policy "interest-cohort=()" always;
        '';
    };
    locations."~ [^/]\.php(/|$)" = {
      extraConfig = ''
        etag off;
        add_header etag "\"${builtins.substring 11 32 roundcube}\"";
        add_header Permissions-Policy "interest-cohort=()" always;

        fastcgi_split_path_info ^(.+?\.php)(/.*)$;
        if (!-f $document_root$fastcgi_script_name) {
            return 404;
        }
    
        fastcgi_pass unix:${config.services.phpfpm.pools."${poolName}".socket};
        fastcgi_index index.php;

        fastcgi_param   QUERY_STRING            $query_string;
        fastcgi_param   REQUEST_METHOD          $request_method;
        fastcgi_param   CONTENT_TYPE            $content_type;
        fastcgi_param   CONTENT_LENGTH          $content_length;

        fastcgi_param   SCRIPT_FILENAME         $document_root$fastcgi_script_name;
        fastcgi_param   SCRIPT_NAME             $fastcgi_script_name;
        fastcgi_param   PATH_INFO               $fastcgi_path_info;
        fastcgi_param   PATH_TRANSLATED         $document_root$fastcgi_path_info;
        fastcgi_param   REQUEST_URI             $request_uri;
        fastcgi_param   DOCUMENT_URI            $document_uri;
        fastcgi_param   DOCUMENT_ROOT           $document_root;
        fastcgi_param   SERVER_PROTOCOL         $server_protocol;

        fastcgi_param   GATEWAY_INTERFACE       CGI/1.1;
        fastcgi_param   SERVER_SOFTWARE         nginx/$nginx_version;

        fastcgi_param   REMOTE_ADDR             $remote_addr;
        fastcgi_param   REMOTE_PORT             $remote_port;
        fastcgi_param   SERVER_ADDR             $server_addr;
        fastcgi_param   SERVER_PORT             $server_port;
        fastcgi_param   SERVER_NAME             $server_name;

        fastcgi_param   HTTPS                   $https;
        fastcgi_param   HTTP_PROXY              "";
      '';
    };
  };
  systemd.services.roundcube-install = {
    serviceConfig.Type = "oneshot";
    wantedBy = [ "multi-user.target" ];
    script = ''
      mkdir -p ${config.variables.roundcubeDataDir}/temp ${config.variables.roundcubeDataDir}/logs
      chown -Rc ${config.variables.roundcubeUser}:${config.variables.roundcubeGroup} ${config.variables.roundcubeDataDir}
      chmod -c 700 ${config.variables.roundcubeDataDir}
      # Regenerate the key every now and then. This invalidates all sessions, but during reboot should be good enough.
      [ -f "${config.variables.roundcubeDataDir}/des_key" ] && ${pkgs.coreutils}/bin/shred "${config.variables.roundcubeDataDir}/des_key"
      ${pkgs.coreutils}/bin/dd if=/dev/urandom bs=32 count=1 2>/dev/null | ${pkgs.coreutils}/bin/base64 > "${config.variables.roundcubeDataDir}/des_key"
      chown -c "${config.variables.roundcubeUser}":${config.variables.roundcubeGroup} "${config.variables.roundcubeDataDir}/des_key"
      chmod -c 400 "${config.variables.roundcubeDataDir}/des_key"
      if [ -s "${config.variables.roundcubeDataDir}/roundcube.sqlite" ]; then
        # Just go ahead and remove the sessions, the key to decrypt them has just been destroyed anyway.
        ${pkgs.sqlite}/bin/sqlite3 "${config.variables.roundcubeDataDir}/roundcube.sqlite" "DELETE FROM session;"
      fi
    '';
  };
  services.phpfpm.pools."${poolName}" = {
    user = "${config.variables.roundcubeUser}";
    group = "${config.variables.roundcubeUser}";
    settings = {
      "pm" = "dynamic";
      "pm.max_children" = 75;
      "pm.min_spare_servers" = 5;
      "pm.max_spare_servers" = 20;
      "pm.max_requests" = 10;
      "catch_workers_output" = 1;
      "listen.owner" = "nginx";
      "listen.group" = "nginx";
    };
  };
  users.extraUsers."${config.variables.roundcubeUser}" = { };
  users.extraGroups."${config.variables.roundcubeUser}" = { };
  users.groups."${config.variables.roundcubeGroup}" = { };
  users.users."${config.variables.roundcubeUser}" = {
    isSystemUser = true;
    group = "${config.variables.roundcubeGroup}";
    description = "PHP User for roundcube";
  };
}
