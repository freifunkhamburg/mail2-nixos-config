{ stdenv, lib, fetchFromGitHub, config ? null, cacheDir ? null }:

stdenv.mkDerivation rec {
  name = "postfixadmin-${version}";
  version = "3.3.10";
  rev = "${name}";

  src = fetchFromGitHub {
    inherit rev;
    owner = "postfixadmin";
    repo = "postfixadmin";
    sha256 = "0xck6df96r4z8k2j8x20b8h2qvmzyrfsya82s4i7hfhrxii92d3w";
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

