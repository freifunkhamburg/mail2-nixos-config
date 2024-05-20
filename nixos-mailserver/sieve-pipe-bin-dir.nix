{ stdenv}:

stdenv.mkDerivation rec {
  name = "sieve-pipe-bin-dir";

  src = ./sieve-pipe-bin-dir;

  phases = [ "copyPhase" "fixupPhase" ];

  copyPhase = ''
    mkdir $out
    cp -Rv $src/. $out/
    '';
}
