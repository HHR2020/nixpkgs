{
  lib,
  stdenv,
  fetchFromGitHub,
  rustPlatform,
  perl,
  pkg-config,
  curl,
  libiconv,
  openssl,
  gitMinimal,
}:

rustPlatform.buildRustPackage rec {
  pname = "cargo-crev";
  version = "0.26.4";

  src = fetchFromGitHub {
    owner = "crev-dev";
    repo = "cargo-crev";
    rev = "v${version}";
    sha256 = "sha256-tuOFanGmIRQs0whXINplfHNyKBhJ1QGF+bBVxqGX/yU=";
  };

  useFetchCargoVendor = true;
  cargoHash = "sha256-CmDTNE0nn2BxB//3vE1ao+xnzA1JBhIQdqcQNWuIKHU=";

  preCheck = ''
    export HOME=$(mktemp -d)
    git config --global user.name "Nixpkgs Test"
    git config --global user.email "nobody@example.com"
  '';

  nativeBuildInputs = [
    perl
    pkg-config
  ];

  buildInputs = [
    openssl
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    libiconv
    curl
  ];

  nativeCheckInputs = [ gitMinimal ];

  meta = with lib; {
    description = "Cryptographically verifiable code review system for the cargo (Rust) package manager";
    mainProgram = "cargo-crev";
    homepage = "https://github.com/crev-dev/cargo-crev";
    license = with licenses; [
      asl20
      mit
      mpl20
    ];
    maintainers = with maintainers; [
      b4dm4n
      matthiasbeyer
    ];
  };
}
