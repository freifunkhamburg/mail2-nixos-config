{ stdenv, dovecot_pigeonhole}:

stdenv.mkDerivation rec {
  name = "sieve-report-spam-ham";

  src = ./sieve-report-spam-ham;

  phases = [ "copyPhase" "compilePhase" ];

  copyPhase = ''
    mkdir $out
    cp -Rv $src/. $out/
    find $out -type d -exec chmod -c 0755 {} \;
    set +x
    '';

  # Yeah, need a specific dovecot.conf to enable the necessary plugins...
  # taking the one used by the dovecot that actually executes the sieve scripts should
  # work as well, but passing it through isn't worth my time.
  compilePhase = ''
    dc=$(pwd)/dovecot.conf
    cat > $dc <<-EOF
      plugin {
        sieve_plugins = sieve_imapsieve sieve_extprograms
        sieve_global_extensions = +vnd.dovecot.pipe +vnd.dovecot.environment
      }
    EOF
    find $out -iname '*.sieve' -print0 | xargs -t -0 -n1 ${dovecot_pigeonhole}/bin/sievec -c $dc
  '';
}
