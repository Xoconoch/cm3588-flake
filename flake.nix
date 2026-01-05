{
  description = "FriendlyElec Nanopi6 Linux kernel v6.1.118";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "aarch64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      packages.${system}.nanopi6Kernel = pkgs.recurseIntoAttrs (
        pkgs.linuxPackagesFor (
          pkgs.buildLinux {
            inherit (pkgs) stdenv;

            version = "6.1.118-friendlyelec";
            modDirVersion = "6.1.118";

            src = pkgs.fetchFromGitHub {
              owner = "friendlyarm";
              repo = "kernel-rockchip";
              rev = "ebb487a1ce6e8970638a243b27eb95b9adc9ece1";
              hash = "sha256‑1/z3J1UaEKrOVaI3Kq3tV2ZrBhBDmWcqIvfWHpZO57o=";
            };

            kernelPatches = [

              # Optional: additional config you need
              {
                name = "nanopi6 nanopi6 defconfig";
                patch = null;
                extraConfig = ''
                  CONFIG_LOCALVERSION="-friendlyelec"
                '';
              }

            ];

            extraConfig = ''
              # additional config if needed
            '';

            # modules must be built and installed
            autoModules = true;
            ignoreConfigErrors = true;
          }
        )
      );

      nixosModules.nanopi6KernelConfig =
        { }:
        {
          boot.kernelPackages = self.packages.${system}.nanopi6Kernel;
        };
    };
}
