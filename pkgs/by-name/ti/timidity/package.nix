{
  lib,
  stdenv,
  fetchurl,
  nixosTests,
  pkg-config,
  libjack2,
  ncurses,
  alsa-lib,
  buildPackages,

  ## Additional optional output modes
  enableVorbis ? false,
  libvorbis,
}:

stdenv.mkDerivation rec {
  pname = "timidity";
  version = "2.15.0";

  src = fetchurl {
    url = "mirror://sourceforge/timidity/TiMidity++-${version}.tar.bz2";
    sha256 = "1xf8n6dqzvi6nr2asags12ijbj1lwk1hgl3s27vm2szib8ww07qn";
  };

  patches = [
    ./timidity-iA-Oj.patch
    # Fixes misdetection of features by clang 16. The configure script itself is patched because
    # it is old and does not work nicely with autoreconfHook.
    ./configure-compat.patch
  ];

  postPatch = ''
    substituteInPlace configure \
      --replace-fail "\$(pkg-config" "\$(\$PKG_CONFIG"
  '';

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    libjack2
    ncurses
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    alsa-lib
  ]
  ++ lib.optionals enableVorbis [
    libvorbis
  ];

  enabledOutputModes = [
    "jack"
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    "oss"
    "alsa"
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    "darwin"
  ]
  ++ lib.optionals enableVorbis [
    "vorbis"
  ];

  configureFlags = [
    "--enable-ncurses"
    ("--enable-audio=" + builtins.concatStringsSep "," enabledOutputModes)
    "lib_cv_va_copy=yes"
    "lib_cv___va_copy=yes"
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    "--enable-alsaseq"
    "--with-default-output=alsa"
    "lib_cv_va_val_copy=yes"
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    "lib_cv_va_val_copy=no"
    "timidity_cv_ccoption_rdynamic=yes"
    # These configure tests fail because of incompatible function pointer conversions.
    "ac_cv_func_vprintf=yes"
    "ac_cv_func_popen=yes"
    "ac_cv_func_vsnprintf=yes"
    "ac_cv_func_snprintf=yes"
    "ac_cv_func_open_memstream=yes"
  ];

  makeFlags = [
    "AR=${stdenv.cc.targetPrefix}ar"
  ];

  instruments = fetchurl {
    url = "https://courses.cs.umbc.edu/pub/midia/instruments.tar.gz";
    sha256 = "0lsh9l8l5h46z0y8ybsjd4pf6c22n33jsjvapfv3rjlfnasnqw67";
  };

  preBuild = ''
    # calcnewt has to be built with the host compiler.
    ${buildPackages.stdenv.cc}/bin/cc -o timidity/calcnewt -lm timidity/calcnewt.c
    # Remove dependencies of calcnewt so it doesn't try to remake it.
    sed -i 's/^\(calcnewt\$(EXEEXT):\).*/\1/g' timidity/Makefile
  '';

  # the instruments could be compressed (?)
  postInstall = ''
    mkdir -p $out/share/timidity/;
    cp ${./timidity.cfg} $out/share/timidity/timidity.cfg
    substituteAllInPlace $out/share/timidity/timidity.cfg
    tar --strip-components=1 -xf $instruments -C $out/share/timidity/
    # All but one of the symlinks in the instruments tarball have their permissions set to 0000.
    # This causes problems on systems like Darwin that actually use symlink permissions.
    chmod -Rh u+rwX $out/share/timidity/
  '';

  passthru.tests = nixosTests.timidity;

  meta = with lib; {
    homepage = "https://sourceforge.net/projects/timidity/";
    license = licenses.gpl2Plus;
    description = "Software MIDI renderer";
    maintainers = [ maintainers.marcweber ];
    platforms = platforms.unix;
    mainProgram = "timidity";
  };
}
