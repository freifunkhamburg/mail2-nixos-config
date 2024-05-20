{ stdenv, lib, fetchurl, acl, conf ? null, temp ? null, logs ? null }:

stdenv.mkDerivation rec {
  name = "roundcube-${version}";
  version = "1.5.7";
  url = "https://github.com/roundcube/roundcubemail/releases/download/${version}/roundcubemail-${version}-complete.tar.gz";

  src = fetchurl {
    inherit url;
    curlOpts = "--location";
    hash = "sha256-5+2SHAsXdKO31+N12LiRY5Pyy81i6R+02Otp5uxSj9I=";
  };
  preferLocalBuild = true;

  phases = [ "unpackPhase" "installPhase" ];

  installPhase = ''
    cp -Rp ./ $out/
    cd "$out"
    ${lib.optionalString (conf != null) "ln -s ${conf} $out/config/config.inc.php"}
    ${lib.optionalString (temp != null) "mv temp temp.dist; ln -s ${temp} $out/temp"}
    ${lib.optionalString (logs != null) "mv logs logs.dist; ln -s ${logs} $out/logs"}
  '';

  meta = with lib; {
    description = "Roundcube";
    homepage    = https://roundcube.net/;
    license     = licenses.agpl3;
    maintainers = with maintainers; [ tokudan ];
    platforms   = platforms.all;
  };
}

