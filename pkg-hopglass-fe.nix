{ stdenv, lib, pkgs, python, nodejs_latest, fetchFromGitHub, fetchzip, fetchurl, conf }:
let
  nodejs = nodejs_latest;
  yarn2nix = import (fetchFromGitHub {
    rev = "3f2dbb08724bf8841609f932bfe1d61a78277232";
    owner = "moretea";
    repo = "yarn2nix";
    sha256 = "142av7dwviapsnahgj8r6779gs2zr17achzhr8b97s0hsl08dcl2";
  }) { inherit pkgs nodejs; };
in
yarn2nix.mkYarnPackage {
  name = "hopglass-frontend";
  src = fetchFromGitHub {
    rev = "fc09b591dc2b9dd867559ea008f1177d52a824dd";
    owner = "hopglass";
    repo = "hopglass";
    sha256 = "0s9x466jqn7swbd35kjiaqk2lmcy9fnykhcnb1b10a2l35q655cl";
  };
  conf = conf;
  installPhase = ''
    echo ---------------------------------------------------------------------------- installPhase
    set -x
    #yarn --offline build
    ls -l
    cp -R $src/. .
    node_modules/.bin/grunt --force
    mkdir -p $out
    set +x
  '';
  distPhase = ''
    cp -Rv build/* $out/
    cat "$conf" > $out/config.json
  '';
  allowedReferences = [ "out" ];
  yarnPreBuild = ''
    mkdir -p $HOME/.node-gyp/${nodejs.version}
    echo 9 > $HOME/.node-gyp/${nodejs.version}/installVersion
    ln -sfv ${nodejs}/include $HOME/.node-gyp/${nodejs.version}
  '';
  # work around some purity problems in nix
  #yarnLock = ./yarn.lock;
  #packageJSON = ./package.json;
}
