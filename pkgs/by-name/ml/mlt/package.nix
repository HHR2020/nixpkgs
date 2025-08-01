{
  config,
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  which,
  ffmpeg,
  fftw,
  frei0r,
  libdv,
  libjack2,
  libsamplerate,
  libvorbis,
  libxml2,
  libX11,
  makeWrapper,
  movit,
  opencv4,
  rtaudio,
  rubberband,
  sox,
  vid-stab,
  cudaSupport ? config.cudaSupport,
  cudaPackages ? { },
  enableJackrack ? stdenv.hostPlatform.isLinux,
  glib,
  ladspa-sdk,
  ladspaPlugins,
  enablePython ? false,
  python3,
  swig,
  qt ? null,
  enableSDL2 ? true,
  SDL2,
  gitUpdater,
  libarchive,
}:

stdenv.mkDerivation rec {
  pname = "mlt";
  version = "7.30.0";

  src = fetchFromGitHub {
    owner = "mltframework";
    repo = "mlt";
    rev = "v${version}";
    hash = "sha256-z1bW+hcVeMeibC1PUS5XNpbkNB+75YLoOWZC2zuDol4=";
    # The submodule contains glaxnimate code, since MLT uses internally some functions defined in glaxnimate.
    # Since glaxnimate is not available as a library upstream, we cannot remove for now this dependency on
    # submodules until upstream exports glaxnimate as a library: https://gitlab.com/mattbas/glaxnimate/-/issues/545
    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    cmake
    pkg-config
    which
    makeWrapper
  ]
  ++ lib.optionals cudaSupport [
    cudaPackages.cuda_nvcc
  ]
  ++ lib.optionals enablePython [
    python3
    swig
  ]
  ++ lib.optionals (qt != null) [
    qt.wrapQtAppsHook
  ];

  buildInputs = [
    (opencv4.override { inherit ffmpeg; })
    ffmpeg
    fftw
    frei0r
    libdv
    libjack2
    libsamplerate
    libvorbis
    libxml2
    movit
    rtaudio
    rubberband
    sox
    vid-stab
  ]
  ++ lib.optionals cudaSupport [
    cudaPackages.cuda_cudart
  ]
  ++ lib.optionals enableJackrack [
    glib
    ladspa-sdk
    ladspaPlugins
  ]
  ++ lib.optionals (qt != null) [
    qt.qtbase
    qt.qtsvg
    (qt.qt5compat or null)
    libarchive
  ]
  ++ lib.optionals enableSDL2 [
    SDL2
    libX11
  ];

  outputs = [
    "out"
    "dev"
  ];

  cmakeFlags = [
    # RPATH of binary /nix/store/.../bin/... contains a forbidden reference to /build/
    "-DCMAKE_SKIP_BUILD_RPATH=ON"
    "-DMOD_OPENCV=ON"
  ]
  ++ lib.optionals enablePython [
    "-DSWIG_PYTHON=ON"
  ]
  ++ lib.optionals (qt != null) [
    "-DMOD_QT${lib.versions.major qt.qtbase.version}=ON"
    "-DMOD_GLAXNIMATE${if lib.versions.major qt.qtbase.version == "5" then "" else "_QT6"}=ON"
  ];

  preFixup = ''
    wrapProgram $out/bin/melt \
      --prefix FREI0R_PATH : ${frei0r}/lib/frei0r-1 \
      ${lib.optionalString enableJackrack "--prefix LADSPA_PATH : ${ladspaPlugins}/lib/ladspa"} \
      ${lib.optionalString (qt != null) "\${qtWrapperArgs[@]}"}

  '';

  postFixup = ''
    substituteInPlace "$dev"/lib/pkgconfig/mlt-framework-7.pc \
      --replace '=''${prefix}//' '=/'
  '';

  passthru = {
    inherit ffmpeg;
  };

  passthru.updateScript = gitUpdater {
    rev-prefix = "v";
  };

  meta = with lib; {
    description = "Open source multimedia framework, designed for television broadcasting";
    homepage = "https://www.mltframework.org/";
    license = with licenses; [
      lgpl21Plus
      gpl2Plus
    ];
    maintainers = [ ];
    platforms = platforms.unix;
  };
}
