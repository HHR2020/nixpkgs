{
  stdenv,
  lib,
  autoreconfHook,
  fetchbzr,
  fetchpatch,
  pkg-config,
  gtk3,
  glib,
  file,
  gobject-introspection,
  json-glib,
  libsoup_3,
}:

stdenv.mkDerivation {
  pname = "timezonemap";
  version = "0.4.5.1";

  src = fetchbzr {
    url = "lp:timezonemap";
    rev = "58";
    sha256 = "sha256-wCJXwgnN+aZVerjQCm8oT3xIcwmc4ArcEoCh9pMrt+E=";
  };

  patches = [
    # Fix crashes when running in GLib 2.76
    # https://bugs.launchpad.net/ubuntu/+source/libtimezonemap/+bug/2012116
    (fetchpatch {
      url = "https://git.launchpad.net/ubuntu/+source/libtimezonemap/plain/debian/patches/timezone-map-Never-try-to-access-to-free-d-or-null-values.patch?id=88f72f724e63df061204f6818c9a1e7d8c003e29";
      sha256 = "sha256-M5eR0uaqpJOeW2Ya1Al+3ZciXukzHpnjJTMVvdO0dPE=";
    })

    # Port to libsoup3
    # https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1068679
    (fetchpatch {
      url = "https://git.launchpad.net/ubuntu/+source/libtimezonemap/plain/debian/patches/port-to-libsoup3.patch?id=b8346a99d4abece742bce73780ccf0edfa0b99f0";
      hash = "sha256-BHLVA3Vcakl9COAiSPo0OyFOUz4ejsxB22gJW/+m7NI=";
    })
  ];

  nativeBuildInputs = [
    pkg-config
    autoreconfHook
    gobject-introspection
  ];

  buildInputs = [
    gtk3
    glib
    json-glib
    libsoup_3
  ];

  configureFlags = [
    "CFLAGS=-Wno-error"
    "--sysconfdir=/etc"
    "--localstatedir=/var"
  ];

  installFlags = [
    "sysconfdir=${placeholder "out"}/etc"
    "localstatedir=\${TMPDIR}"
  ];

  preConfigure = ''
    for f in {configure,m4/libtool.m4}; do
      substituteInPlace $f\
        --replace /usr/bin/file ${file}/bin/file
    done
  '';

  postPatch = ''
    sed "s|/usr/share/libtimezonemap|$out/share/libtimezonemap|g" -i ./src/tz.h
  '';

  meta = with lib; {
    homepage = "https://launchpad.net/timezonemap";
    description = "GTK+3 Timezone Map Widget";
    license = licenses.gpl2;
    platforms = platforms.linux;
    maintainers = [ maintainers.mkg20001 ];
  };
}
