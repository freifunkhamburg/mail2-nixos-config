{ stdenv, lib, fetchFromGitHub, config ? null, cacheDir ? null }:

stdenv.mkDerivation rec {
  name = "postfixadmin-${version}";
  version = "3.2.2";
  rev = "${name}";

  src = fetchFromGitHub {
    inherit rev;
    owner = "postfixadmin";
    repo = "postfixadmin";
    sha256 = "0bkjdmn63yinf217fnn3wq13pc0yklmnsbrgxjv22vpync42f9vh";
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

