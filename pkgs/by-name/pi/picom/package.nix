{
  asciidoctor,
  dbus,
  docbook_xml_dtd_45,
  docbook_xsl,
  fetchFromGitHub,
  lib,
  libconfig,
  libdrm,
  libev,
  libGL,
  libepoxy,
  libX11,
  libxcb,
  libxdg_basedir,
  libXext,
  libxml2,
  libxslt,
  makeWrapper,
  meson,
  ninja,
  pcre2,
  pixman,
  pkg-config,
  stdenv,
  uthash,
  xcbutil,
  xcbutilimage,
  xcbutilrenderutil,
  xorgproto,
  xwininfo,
  withDebug ? false,
  versionCheckHook,
  nix-update-script,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "picom";
  version = "12.5";

  src = fetchFromGitHub {
    owner = "yshui";
    repo = "picom";
    rev = "v${finalAttrs.version}";
    hash = "sha256-H8IbzzrzF1c63MXbw5mqoll3H+vgcSVpijrlSDNkc+o=";
    fetchSubmodules = true;
  };

  strictDeps = true;

  nativeBuildInputs = [
    asciidoctor
    docbook_xml_dtd_45
    docbook_xsl
    makeWrapper
    meson
    ninja
    pkg-config
  ];

  buildInputs = [
    dbus
    libconfig
    libdrm
    libev
    libGL
    libepoxy
    libX11
    libxcb
    libxdg_basedir
    libXext
    libxml2
    libxslt
    pcre2
    pixman
    uthash
    xcbutil
    xcbutilimage
    xcbutilrenderutil
    xorgproto
  ];

  # Use "debugoptimized" instead of "debug" so perhaps picom works better in
  # normal usage too, not just temporary debugging.
  mesonBuildType = if withDebug then "debugoptimized" else "release";
  dontStrip = withDebug;

  mesonFlags = [
    "-Dwith_docs=true"
  ];

  installFlags = [ "PREFIX=$(out)" ];

  # In debug mode, also copy src directory to store. If you then run `gdb picom`
  # in the bin directory of picom store path, gdb finds the source files.
  postInstall = ''
    wrapProgram $out/bin/picom-trans \
      --prefix PATH : ${lib.makeBinPath [ xwininfo ]}
  ''
  + lib.optionalString withDebug ''
    cp -r ../src $out/
  '';

  nativeInstallCheckInputs = [
    versionCheckHook
  ];

  doInstallCheck = true;

  passthru = {
    updateScript = nix-update-script { };
  };

  meta = {
    description = "Fork of XCompMgr, a sample compositing manager for X servers";
    license = lib.licenses.mit;
    longDescription = ''
      A fork of XCompMgr, which is a sample compositing manager for X
      servers supporting the XFIXES, DAMAGE, RENDER, and COMPOSITE
      extensions. It enables basic eye-candy effects. This fork adds
      additional features, such as additional effects, and a fork at a
      well-defined and proper place.

      The package can be installed in debug mode as:

        picom.override { withDebug = true; }

      For gdb to find the source files, you need to run gdb in the bin directory
      of picom package in the nix store.
    '';
    homepage = "https://github.com/yshui/picom";
    mainProgram = "picom";
    maintainers = with lib.maintainers; [
      ertes
      gepbird
      thiagokokada
      twey
    ];
    platforms = lib.platforms.linux;
  };
})
