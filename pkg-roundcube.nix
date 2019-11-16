{ stdenv, lib, fetchurl, acl, librsync, ncurses, openssl, zlib, conf ? null, temp ? null, logs ? null }:

stdenv.mkDerivation rec {
  name = "roundcube-${version}";
  version = "1.4.0";
  url = "https://github.com/roundcube/roundcubemail/releases/download/${version}/roundcubemail-${version}-complete.tar.gz";

  src = fetchurl {
    inherit url;
    curlOpts = "--location";
    sha256 = "0b7gc342z0smn7q6cnznj9ncal0515ki4kkq1hlmqmyn0nna5lkb";
  };

  phases = [ "unpackPhase" "installPhase" ];

  installPhase = ''
    cp -Rp ./ $out/
    cd "$out"
    ${lib.optionalString (conf != null) "ln -s ${conf} $out/config/config.inc.php"}
    ${lib.optionalString (temp != null) "mv temp temp.dist; ln -s ${temp} $out/temp"}
    ${lib.optionalString (logs != null) "mv logs logs.dist; ln -s ${logs} $out/logs"}
  '';

  meta = with stdenv.lib; {
    description = "Roundcube";
    homepage    = https://roundcube.net/;
    license     = licenses.agpl3;
    maintainers = with maintainers; [ tokudan ];
    platforms   = platforms.all;
  };
}

