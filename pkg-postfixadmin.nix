{ stdenv, lib, fetchFromGitHub, config ? null, cacheDir ? null }:

stdenv.mkDerivation rec {
  name = "postfixadmin-${version}";
  version = "3.3.8";
  rev = "${name}";

  src = fetchFromGitHub {
    inherit rev;
    owner = "postfixadmin";
    repo = "postfixadmin";
    sha256 = "02qnan2yk74i5z8z919zc0ris4ixpqwzl93kjga6db57nki7lwx9";
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

