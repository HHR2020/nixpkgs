{
  lib,
  buildGoModule,
  fetchFromGitHub,
  makeWrapper,
  installShellFiles,
  bash,
  openssh,
}:

buildGoModule rec {
  pname = "k3sup";
  version = "0.13.10";

  src = fetchFromGitHub {
    owner = "alexellis";
    repo = "k3sup";
    rev = version;
    sha256 = "sha256-0iYz2bxUBC+tnPZgH+QQo0ZNRktniw6gs9hWrLIjS+U=";
  };

  nativeBuildInputs = [
    makeWrapper
    installShellFiles
  ];

  vendorHash = null;

  postConfigure = ''
    substituteInPlace vendor/github.com/alexellis/go-execute/v2/exec.go \
      --replace "/bin/bash" "${bash}/bin/bash"
  '';

  env.CGO_ENABLED = 0;

  ldflags = [
    "-s"
    "-w"
    "-X github.com/alexellis/k3sup/cmd.GitCommit=ref/tags/${version}"
    "-X github.com/alexellis/k3sup/cmd.Version=${version}"
  ];

  postInstall = ''
    wrapProgram "$out/bin/k3sup" \
      --prefix PATH : ${lib.makeBinPath [ openssh ]}

    installShellCompletion --cmd k3sup \
      --bash <($out/bin/k3sup completion bash) \
      --zsh <($out/bin/k3sup completion zsh) \
      --fish <($out/bin/k3sup completion fish)
  '';

  meta = with lib; {
    homepage = "https://github.com/alexellis/k3sup";
    description = "Bootstrap Kubernetes with k3s over SSH";
    mainProgram = "k3sup";
    license = licenses.mit;
    maintainers = with maintainers; [
      welteki
      qjoly
    ];
  };
}
