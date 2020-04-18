{ stdenv, lib, fetchFromGitHub, config ? null, cacheDir ? null }:

stdenv.mkDerivation rec {
  name = "postfixadmin-${version}";
  version = "3.2.4";
  rev = "${name}";

  src = fetchFromGitHub {
    inherit rev;
    owner = "postfixadmin";
    repo = "postfixadmin";
    sha256 = "177rgljwq08l0z3d5fcg0x7v326di79xi9611j355zrjir78fy0j";
  };

  phases = [ "unpackPhase" "installPhase" ];

  installPhase = ''
    cp -Rp ./ $out/
    ${lib.optionalString (config != null) ''
      ln -s ${config} $out/config.local.php
    ''}
    ${lib.optionalString (cacheDir != null) ''
      ln -s ${cacheDir}/templates_c $out/templates_c
    ''}
  '';

  meta = with stdenv.lib; {
    description = "Postfix Admin";
    homepage    = http://postfixadmin.sourceforge.net/;
    license     = licenses.gpl2;
    maintainers = with maintainers; [ tokudan ];
    platforms   = platforms.all;
  };
}

