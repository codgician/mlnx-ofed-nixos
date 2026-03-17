{
  lib,
  stdenv,
  mkUnpackScript,
  mlnx-ofed-src,
  python3,
  makeWrapper,
  ...
}:

stdenv.mkDerivation {
  pname = "mlx-steering-dump";
  inherit (mlnx-ofed-src) src version;

  unpackPhase = mkUnpackScript "mlx-steering-dump";

  nativeBuildInputs = [ makeWrapper ];

  buildInputs = [ python3 ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    # Install software steering dump tools
    mkdir -p $out/share/mlx-steering-dump/sws
    cp -r sws/mlx_steering_dump_parser.py sws/src $out/share/mlx-steering-dump/sws/

    # Install hardware steering dump tools
    mkdir -p $out/share/mlx-steering-dump/hws
    cp -r hws/mlx_hw_steering_parser.py hws/src $out/share/mlx-steering-dump/hws/

    # Create wrapper scripts
    mkdir -p $out/bin
    makeWrapper ${python3}/bin/python3 $out/bin/mlx_steering_dump \
      --add-flags "$out/share/mlx-steering-dump/sws/mlx_steering_dump_parser.py"
    makeWrapper ${python3}/bin/python3 $out/bin/mlx_hw_steering_dump \
      --add-flags "$out/share/mlx-steering-dump/hws/mlx_hw_steering_parser.py"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Mellanox steering dump parser for ConnectX-5/6 debug files";
    homepage = "https://github.com/Mellanox/mlx_steering_dump";
    license = with licenses; [ gpl2Only bsd2 ];
    platforms = platforms.linux;
    maintainers = with maintainers; [ codgician ];
  };
}
