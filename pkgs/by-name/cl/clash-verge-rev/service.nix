{
  rustPlatform,
  fetchFromGitHub,
  meta,
  procps,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "clash-verge-service-ipc";
  version = "2.1.1";

  src = fetchFromGitHub {
    owner = "clash-verge-rev";
    repo = "clash-verge-service-ipc";
    # upstream uses branch
    rev = "v${finalAttrs.version}";
    hash = "sha256-qU7baSJDro7TZT21lg8cbMj26hwZ8yx1iEgeSYAK9aY=";
  };

  patches = [
    # 1. Don't SetGID because the path is managed by systemd in NixOS, and we
    #    use different IPC path for sidecar mode. We can keep RestrictSUIDSGID
    #    in systemd serviceConfig.
    # 2. Set IPC socket path
    ./patch-service-directory.patch
  ];

  cargoHash = "sha256-XN0525mmpCGkpEeKOODmuY5yLWC0kGAW29qBZjVV+os=";

  buildFeatures = [
    "standalone"
  ];

  nativeCheckInputs = [
    procps
  ];
  # build mock_binary for tests
  preCheck = ''
    cargo build --features=test
  '';
  checkFeatures = [
    "standalone"
    "test"
    "client"
  ];
  inherit meta;
})
