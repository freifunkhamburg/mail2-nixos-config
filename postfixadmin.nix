{ config, lib, pkgs, ... }:

let
  phppoolName = "postfixadmin_pool";
  pfaGroup = config.variables.pfaGroup;
  pfaUser = config.variables.pfaUser;
  postfixadminpkg = config.variables.postfixadminpkg;
  pfadminDataDir = config.variables.pfadminDataDir;
  cacheDir = config.variables.postfixadminpkgCacheDir;
  phpfpmHostPort = config.variables.pfaPhpfpmHostPort;
in
{
  # Setup the user and group
  users.groups."${pfaGroup}" = { };
  users.users."${pfaUser}" = {
    isSystemUser = true;
    group = "${pfaGroup}";
    description = "PHP User for postfixadmin";
  };

  # Setup nginx
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  services.nginx.enable = true;
  services.nginx.virtualHosts."${config.variables.pfaDomain}" = {
    forceSSL = config.variables.useSSL;
    enableACME = config.variables.useSSL;
    root = "${postfixadminpkg}/public";
    extraConfig = ''
      charset utf-8;

      etag off;
      add_header etag "\"${builtins.substring 11 32 postfixadminpkg}\"";

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
        fastcgi_pass ${phpfpmHostPort};
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

      mkdir -p ${cacheDir}/templates_c
      chown -Rc ${pfaUser}:${pfaGroup} ${cacheDir}/templates_c
      chmod -Rc 751 ${cacheDir}/templates_c
    '';
  };
  services.phpfpm.pools."${phppoolName}" = {
    listen = phpfpmHostPort;
    user = "${pfaUser}";
    group = "${pfaGroup}";
    extraConfig = ''
      pm = dynamic
      pm.max_children = 75
      pm.min_spare_servers = 5
      pm.max_spare_servers = 20
      pm.max_requests = 10
      catch_workers_output = 1
      php_admin_value[upload_max_filesize] = 42M
      php_admin_value[post_max_size] = 42M
      php_admin_value[memory_limit] = 128M
      php_admin_value[cgi.fix_pathinfo] = 1
    '';
  };
}
