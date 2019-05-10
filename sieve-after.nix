{ stdenv, dovecot_pigeonhole}:

stdenv.mkDerivation rec {
  name = "sieve-after";

  src = ./sieve-after;

  phases = [ "copyPhase" "compilePhase" ];

  copyPhase = ''
    cd $src
    mkdir $out
    cp -Rv $src/. $out/
    find $out -type d -exec chmod -c 0755 {} \;
    set +x
    '';
  compilePhase = ''
    find $out -iname '*.sieve' -print0 | xargs -t -0 -n1 ${dovecot_pigeonhole}/bin/sievec -c /dev/null
  '';
}
