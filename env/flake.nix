{
  description = "pg-proba test environment Docker image: postgres + odyssey + pgbouncer + pg_doorman + client languages";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Пулер под тестом: ревизия запинена тут и в flake.lock.
    # Bump: nix flake lock --update-input pg_doorman (внутри env/build.sh-контейнера)
    pg_doorman = {
      url = "github:ozontech/pg_doorman/4a57aed2fc29dda5de0986246c21e418dd726cdf";
      flake = false;
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      perSystem =
        {
          system,
          ...
        }:
        let
          # Odyssey overlay: pinned v1.4.1, pg_config от PostgreSQL 14 (как в pg_doorman/tests/nix)
          odysseyOverlay = final: prev:
            let
              pg = prev.postgresql_14;
            in {
            odyssey = prev.odyssey.overrideAttrs (oldAttrs: rec {
              version = "master-190db18";
              src = prev.fetchFromGitHub {
                owner = "yandex";
                repo = "odyssey";
                rev = "190db188733d805e529a06353cf02baa28fd133c";
                sha256 = "sha256-9wiLr0sT3yrZqHx8UFIQkn9CYrBOQvEQpFaXRhJBk3E=";
              };
              nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [ pg prev.bison prev.flex ];
              buildInputs = [
                prev.openssl
                pg
              ];
              patches = [ ];
              cmakeFlags = [
                "-DBUILD_COMPRESSION=OFF"
                "-DCMAKE_BUILD_TYPE=Release"
              ];
              env = (oldAttrs.env or {}) // {
                NIX_CFLAGS_COMPILE = (oldAttrs.env.NIX_CFLAGS_COMPILE or "")
                  + " -Wno-error=implicit-int -Wno-error=incompatible-pointer-types -Wno-error=discarded-qualifiers -Wno-error=implicit-function-declaration -Wno-error=int-conversion";
              };
            });
          };

          # pg_doorman из запиненного git-рева (flake.lock хранит hash)
          pgDoormanOverlay = final: prev: {
            pg_doorman = prev.rustPlatform.buildRustPackage {
              pname = "pg_doorman";
              version = "master-4a57aed";
              src = inputs.pg_doorman;
              # обновить при bump ревизии — nix сам напишет правильный got: sha256-...
              cargoHash = "sha256-GNQeqC+zddDdHCLTUX8VgTbyb5lQWnnwUdhhCnxDj6g=";
              nativeBuildInputs = [ prev.pkg-config ];
              buildInputs = [ prev.openssl ];
              doCheck = false;
            };
          };

          pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [
              (import inputs.rust-overlay)
              odysseyOverlay
              pgDoormanOverlay
            ];
            config = {
              allowUnfree = true;
              allowUnsupportedSystem = true;
            };
          };

          rustToolchain = pkgs.rust-bin.stable."1.91.0".default.override {
            extensions = [
              "rust-src"
              "rust-analyzer"
            ];
          };

          pythonEnv = pkgs.python3.withPackages (ps: with ps; [
            asyncpg
            filelock
            psycopg
            psycopg2
            aiopg
            pytest
            pytest-asyncio
            pytest-timeout
            sqlalchemy
            sqlmodel
          ]);

          runtimePackages = with pkgs; [
            # PostgreSQL + пулеры под тестом
            postgresql_16
            odyssey
            pgbouncer
            pg_doorman

            # Клиентские языки (корпус дергает реальные драйверы)
            nodejs_22
            go
            pythonEnv
            dotnet-sdk_10
            (php84.withExtensions ({ enabled, all }: enabled ++ [ all.pdo_pgsql ]))
            jdk21
            maven

            # Rust-харнесс
            rustToolchain

            # Сборочные зависимости харнесса
            pkg-config
            openssl
            openssl.dev
            gcc
            gnumake
            cmake
            perl
            git

            # Системное
            gnupatch
            cacert
            coreutils
            bash
            findutils
            gnugrep
            gnused
            gawk
            gnutar
            gzip
            which
            shadow
            sudo
            linux-pam
            procps
            util-linux
            iproute2
            nettools
            curl
            wget
            less
            vim
            libiconv
            zlib
          ];

          envSetupScript = pkgs.writeShellScriptBin "setup-env" ''
            export CARGO_HOME="/root/.cargo"
            export RUSTUP_HOME="/root/.rustup"
            export GOPATH="/root/go"
            export GOMODCACHE="/root/go/pkg/mod"
            export DOTNET_CLI_HOME="/root/.dotnet"
            export DOTNET_NOLOGO=1
            export NPM_CONFIG_PREFIX="/root/.npm-global"
            export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
            export NIX_SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
            export PATH="$CARGO_HOME/bin:$GOPATH/bin:$NPM_CONFIG_PREFIX/bin:$PATH"
            mkdir -p "$CARGO_HOME" "$RUSTUP_HOME" "$GOPATH" "$DOTNET_CLI_HOME" "$NPM_CONFIG_PREFIX"
          '';

          dockerImage = pkgs.dockerTools.buildLayeredImage {
            name = "pg-proba-test-env";
            tag = "latest";

            contents = runtimePackages ++ [
              envSetupScript
              pkgs.dockerTools.caCertificates
              pkgs.dockerTools.usrBinEnv
              pkgs.dockerTools.binSh

              (pkgs.runCommand "system-setup" {} ''
                mkdir -p $out/tmp $out/etc $out/var/run/postgresql
                chmod 1777 $out/tmp
                chmod 1777 $out/var/run/postgresql

                cat > $out/etc/passwd << 'EOF'
root:x:0:0:root:/root:/bin/bash
postgres:x:999:999:PostgreSQL Server:/var/lib/postgresql:/bin/bash
EOF

                cat > $out/etc/group << 'EOF'
root:x:0:
postgres:x:999:
EOF

                mkdir -p $out/etc/sudoers.d $out/etc/pam.d
                cat > $out/etc/sudoers << 'EOF'
root ALL=(ALL:ALL) ALL
%sudo ALL=(ALL:ALL) NOPASSWD: ALL
postgres ALL=(ALL:ALL) NOPASSWD: ALL
Defaults env_keep += "PATH"
EOF
                chmod 0440 $out/etc/sudoers

                cat > $out/etc/pam.d/sudo << 'EOF'
auth       sufficient   pam_permit.so
account    sufficient   pam_permit.so
session    sufficient   pam_permit.so
EOF

                cat > $out/etc/pam.d/other << 'EOF'
auth       sufficient   pam_permit.so
account    sufficient   pam_permit.so
session    sufficient   pam_permit.so
EOF
              '')
            ];

            config = {
              Env = [
                "CARGO_HOME=/root/.cargo"
                "RUSTUP_HOME=/root/.rustup"
                "GOPATH=/root/go"
                "GOMODCACHE=/root/go/pkg/mod"
                "GOCACHE=/root/.cache/go-build"
                "DOTNET_CLI_HOME=/root/.dotnet"
                "DOTNET_NOLOGO=1"
                "NPM_CONFIG_PREFIX=/root/.npm-global"
                "JAVA_HOME=${pkgs.jdk21}"
                "M2_HOME=${pkgs.maven}"
                "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
                "NIX_SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
                "PKG_CONFIG_PATH=${pkgs.openssl.dev}/lib/pkgconfig"
                "OPENSSL_DIR=${pkgs.openssl.dev}"
                "OPENSSL_LIB_DIR=${pkgs.openssl.out}/lib"
                "OPENSSL_INCLUDE_DIR=${pkgs.openssl.dev}/include"
                "PATH=/root/.cargo/bin:/root/go/bin:/root/.npm-global/bin:${pkgs.lib.makeBinPath runtimePackages}:/bin:/usr/bin"
                "LANG=C.UTF-8"
                "LC_ALL=C.UTF-8"
              ];
              WorkingDir = "/workspace";
              Cmd = [ "/bin/bash" ];
            };

            maxLayers = 125;
          };

        in
        {
          packages = {
            default = dockerImage;
            inherit dockerImage;
          };
        };
    };
}
