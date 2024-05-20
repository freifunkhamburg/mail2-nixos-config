{ stdenv, lib, fetchFromGitHub, config ? null, cacheDir ? null }:

stdenv.mkDerivation rec {
  name = "postfixadmin-${version}";
  version = "3.3.13";
  rev = "${name}";

  src = fetchFromGitHub {
    inherit rev;
    owner = "postfixadmin";
    repo = "postfixadmin";
    hash = "sha256-46bc34goAcRvaiyW7z0AvIcd8n61TL6vgLQ+y7nNKBQ=";
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

  meta = with lib; {
    description = "Postfix Admin";
    homepage    = http://postfixadmin.sourceforge.net/;
    license     = licenses.gpl2;
    maintainers = with maintainers; [ tokudan ];
    platforms   = platforms.all;
  };
}

