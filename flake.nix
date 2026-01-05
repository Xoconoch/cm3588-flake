{
  description = "FriendlyElec Nanopi6 Linux kernel v6.1.118";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      system = "aarch64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      packages.${system} = {
        nanopi6Kernel = pkgs.stdenv.mkDerivation {
          pname = "linux-6.1.118-friendlyelec";
          version = "6.1.118";

          src = pkgs.fetchFromGitHub {
            owner = "friendlyarm";
            repo = "kernel-rockchip";
            rev = "nanopi6-v6.1.y";
            hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
          };

          r8125Src = pkgs.fetchFromGitHub {
            owner = "friendlyarm";
            repo = "r8125";
            rev = "main";
            hash = "sha256-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=";
          };

          nativeBuildInputs = [
            pkgs.makeWrapper
            pkgs.patchelf
          ];

          buildPhase = ''
            # Go to the kernel source
            cd ''${src}

            # force nanopi6 config and build
            make ARCH=arm64 nanopi6_linux_defconfig
            make ARCH=arm64 nanopi6-images -j$(nproc)

            # modules
            mkdir -p out-modules && rm -rf out-modules/*
            make ARCH=arm64 INSTALL_MOD_PATH="$PWD/out-modules" modules -j$(nproc)
            make ARCH=arm64 INSTALL_MOD_PATH="$PWD/out-modules" modules_install INSTALL_MOD_STRIP=1

            # get the kernel version in shell
            KERNEL_VER=$(make ARCH=arm64 kernelrelease)

            # build r8125
            export ETHTOOL_LEGACY_2500baseX=y
            cp -r ''${r8125Src} r8125
            cd r8125
            make ARCH=arm64 KSRC=../ CONFIG_VENDOR_FRIENDLYARM=y CONFIG_WERROR=n -j$(nproc)
            strip --strip-unneeded r8125.ko
            mkdir -p ../out-modules/lib/modules/''${KERNEL_VER}/extra/
            cp r8125.ko ../out-modules/lib/modules/''${KERNEL_VER}/extra/
            cd ..
            unset ETHTOOL_LEGACY_2500baseX

            # depmod
            [ ! -f "$PWD/out-modules/lib/modules/''${KERNEL_VER}/modules.dep" ] && \
              depmod -b $PWD/out-modules -E Module.symvers -F System.map -w ''${KERNEL_VER}

            # ensure kernel image is in out
            mkdir -p out
            cp arch/arm64/boot/Image out/Image
          '';

          installPhase = ''
            mkdir -p $out/lib/modules
            cp -r out-modules/lib/modules/* $out/lib/modules/

            mkdir -p $out/kernel
            cp out/Image $out/kernel/Image
          '';

          meta = with pkgs.lib; {
            description = "FriendlyElec Nanopi6 Linux kernel v6.1.118";
            license = licenses.gpl3;
            platforms = [ "aarch64-linux" ];
          };
        };
      };

      nixosModules.nanopi6Kernel =
        { }:
        {
          boot.kernelPackages = self.packages.${system}.nanopi6Kernel;
        };
    };
}
