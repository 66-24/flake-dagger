{
  description = "A flake that installs Dagger from source";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        version = "0.18.10"; # Remove 'v' prefix for pname/version
        src = pkgs.fetchFromGitHub {
          owner = "dagger";
          repo = "dagger";
          rev = "v${version}"; # Keep 'v' prefix for git tag
          sha256 = "sha256-MVLgdAIWuoeoRBzuow/y9pSyJSC6YWja/98l0DCGJ4k=";
        };
      in {
        packages = {
          dagger = pkgs.buildGoModule {
            pname = "dagger";
            inherit version src;

            # vendorHash = pkgs.lib.fakeHash;
            # vendorHash = "sha256-eYGsEoKcePl9nrx1Do+T5zbeqxUTJo27+/Hsr34/gBQ=";
            vendorHash = "sha256-eYGsEoKcePl9nrx1Do+T5zbeqxUTJo27+/Hsr34/gBQ=";

            subPackages = [ "cmd/dagger" ];
            doCheck = false;

            checkPhase = "";

            # Use the latest Go available in nixpkgs
            nativeBuildInputs = [ pkgs.go ];

            # Patch go.mod to use available Go version
            postPatch = ''
              substituteInPlace go.mod \
                --replace-fail "go 1.24.4" "go 1.24"

              # Set up Go environment and run go mod tidy
              export GOCACHE=$TMPDIR/go-cache
              export GOMODCACHE=$TMPDIR/go-mod
              export HOME=$TMPDIR                  

              # Update go.mod and go.sum
              # ${pkgs.go}/bin/go mod tidy
            '';

            # Add ldflags for proper versioning
            ldflags = [
              "-s"
              "-w"
              "-X github.com/dagger/dagger/engine.Version=v${version}"
            ];

            meta = with pkgs.lib; {
              description = "Dagger CLI";
              homepage = "https://dagger.io/";
              license = licenses.asl20;
              maintainers = [ ];
              mainProgram = "dagger";
            };
          };
        };

        # Use packages.default instead of defaultPackage (deprecated)
        packages.default = self.packages.${system}.dagger;

        # Add development shell
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [ self.packages.${system}.dagger go git ];
        };
      });
}
