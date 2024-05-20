{ config, lib, pkgs, ... }:

let
  phppoolName = "postfixadmin_pool";
  pfaGroup = config.services.mymailserver.internal.pfaGroup;
  pfaUser = config.services.mymailserver.internal.pfaUser;
  postfixadminpkg = config.services.mymailserver.internal.postfixadminpkg;
  pfadminDataDir = config.services.mymailserver.internal.pfadminDataDir;
  cacheDir = config.services.mymailserver.internal.postfixadminpkgCacheDir;
in
{
  # Setup the user and group
  users.groups."${pfaGroup}" = { };
  users.users."${pfaUser}" = {
    isSystemUser = true;
    group = "${pfaGroup}";
    extraGroups = [ "dovecot2" ];
    description = "PHP User for postfixadmin";
  };

  # Setup nginx
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  services.nginx.enable = true;
  services.nginx.virtualHosts."${config.services.mymailserver.pfaFQDN}" = {
    http2 = false;
    forceSSL = true;
    enableACME = true;
    root = "${postfixadminpkg}/public";
    extraConfig = ''
      access_log off;
      resolver ${ lib.concatStringsSep " " ( builtins.map (v: if ((builtins.match ".*:.*" v) == []) then "[${v}]" else v) config.networking.nameservers ) };
      charset utf-8;

      etag off;
      add_header etag "\"${builtins.substring 11 32 postfixadminpkg}\"";
      add_header Permissions-Policy "interest-cohort=()" always;

      index index.php;

      location ~* \.php$ {
        # Zero-day exploit defense.
        # http://forum.nginx.org/read.php?2,88845,page=3
        # Won't work properly (404 error) if the file is not stored on this
        # server, which is entirely possible with php-fpm/php-fcgi.
        # Comment the 'try_files' line out if you set up php-fpm/php-fcgi on
        # another machine.  And then cross your fingers that you won't get hacked.
        try_files $uri =404;
        # NOTE: You should have "cgi.fix_pathinfo = 0;" in php.ini
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        # With php5-cgi alone:
        fastcgi_pass unix:${config.services.phpfpm.pools."${phppoolName}".socket};
        fastcgi_index index.php;
        fastcgi_param  GATEWAY_INTERFACE  CGI/1.1;
        fastcgi_param  SERVER_SOFTWARE    nginx;
        fastcgi_param  QUERY_STRING       $query_string;
        fastcgi_param  REQUEST_METHOD     $request_method;
        fastcgi_param  CONTENT_TYPE       $content_type;
        fastcgi_param  CONTENT_LENGTH     $content_length;
        fastcgi_param  SCRIPT_FILENAME    $document_root$fastcgi_script_name;
        fastcgi_param  SCRIPT_NAME        $fastcgi_script_name;
        fastcgi_param  REQUEST_URI        $request_uri;
        fastcgi_param  DOCUMENT_URI       $document_uri;
        fastcgi_param  DOCUMENT_ROOT      $document_root;
        fastcgi_param  SERVER_PROTOCOL    $server_protocol;
        fastcgi_param  REMOTE_ADDR        $remote_addr;
        fastcgi_param  REMOTE_PORT        $remote_port;
        fastcgi_param  SERVER_ADDR        $server_addr;
        fastcgi_param  SERVER_PORT        $server_port;
        fastcgi_param  SERVER_NAME        $server_name;
        fastcgi_param  HTTP_PROXY         "";
      }
    '';
  };
  systemd.services."postfixadmin-setup" = {
    serviceConfig.Type = "oneshot";
    wantedBy = [ "multi-user.target" ];
    script = ''
      # Setup the data directory with the database and the cache directory
      mkdir -p ${pfadminDataDir}
      chmod -c 751 ${pfadminDataDir}
      chown -c ${pfaUser}:${pfaGroup} ${pfadminDataDir}
      if ! [ -e ${pfadminDataDir}/postfixadmin.db ]; then
        touch ${pfadminDataDir}/postfixadmin.db
        chown -c ${pfaUser}:${pfaGroup} ${pfadminDataDir}/postfixadmin.db
      fi

      mkdir -p ${cacheDir}/templates_c
      chown -Rc ${pfaUser}:${pfaGroup} ${cacheDir}/templates_c
      chmod -Rc 751 ${cacheDir}/templates_c
    '';
  };
  services.phpfpm.pools."${phppoolName}" = {
    user = "${pfaUser}";
    group = "${pfaGroup}";
    settings = {
      "listen.owner" = "nginx";
      "listen.group" = "nginx";
      "user" = "${pfaUser}";
      "pm" = "dynamic";
      "pm.max_children" = "75";
      "pm.min_spare_servers" = "5";
      "pm.max_spare_servers" = "20";
      "pm.max_requests" = "10";
      "catch_workers_output" = "1";
      "php_admin_value[upload_max_filesize]" = "42M";
      "php_admin_value[post_max_size]" = "42M";
      "php_admin_value[memory_limit]" = "128M";
      "php_admin_value[cgi.fix_pathinfo]" = "1";
    };
  };
}
