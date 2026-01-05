{
  description = "Minimal flake: Linux 6.1 kernel with FriendlyElec source";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "aarch64-linux"; # Target architecture
      pkgs = import nixpkgs { inherit system; };
    in
    {
      packages.${system}.nanopi6Kernel = pkgs.linuxPackagesFor (
        pkgs.linux_6_1.overrideAttrs (old: {
          version = "6.1.118-friendlyelec";
          modDirVersion = "6.1.118";

          src = pkgs.fetchFromGitHub {
            owner = "friendlyarm";
            repo = "kernel-rockchip";
            rev = "ebb487a1ce6e8970638a243b27eb95b9adc9ece1";
            sha256 = "1fp79sb1xmpp48m6g6a32036nrjpxnnjldx2ap7al40salkzgz6p";
          };

          # Optional: extra kernel config
          extraConfig = ''
            autoModules = true
            ignoreConfigErrors = true
          '';
        })
      );
    };
}
