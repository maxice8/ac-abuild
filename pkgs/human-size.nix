{ stdenv, zig }:
stdenv.mkDerivation
{
  pname = "human-size";
  version = "master";

  src = ./human-size;

  # we don't have a source, we have an inline source-code
  #dontUnpack = true;

  nativeBuildInputs = [
    zig
  ];

  preBuild = ''
    export HOME=$TMPDIR
  '';

  installPhase = ''
    zig build install -Drelease-safe=true -Dcpu=baseline --prefix $out
  '';
}
