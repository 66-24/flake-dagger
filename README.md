# Dagger Nix Flake

Nix flake to build and install the Dagger CLI (`cmd/dagger`) as a reproducible binary.
This flake builds Dagger from source using Go modules.

![Agents](./dagger-agent.avif)

## What is dagger

[![What is Dagger](./dagger-logo.png)](https://dagger.io)

> Define software delivery workflows and dev environments with reusable components — including LLMs — and run them anywhere. Built by the creators of Docker. (Solomon Hyke)

## Quick Start

```bash
# gh is the github client
gh clone 66-24/flake-dagger
cd flake-dagger
nix build
./result/bin/dagger version
```

## Installation

```bash
# Install to profile (makes dagger available in PATH permanently)
nix profile install .
dagger version

# Or run directly without installing
nix run .

# Or use the build result directly
./result/bin/dagger version
```

## Using Dagger

Start the engine `dagger-engine.dev` if not already running

```bash
docker ps | grep --color -Po " dagger.*\.dev"
```

```bash
 docker run --rm \
  --name dagger-engine.dev \
  --privileged \
  -v /var/lib/dagger \
  registry.dagger.io/engine:v0.18.10
```

### Test the engine

```bash
dagger core container from --address=alpine file --path=/etc/os-release contents
```

### Installation Methods Explained

- **`nix profile install .`** - Installs Dagger to your user profile (`~/.nix-profile/`), making it permanently available in your `$PATH`. After installation, you can run `dagger` from anywhere.

- **`nix run .`** - Runs Dagger once without installing. Good for testing or occasional use.

- **`./result/bin/dagger`** - Uses the build result directly. The `result` symlink points to the built package in the Nix store.

### Managing Profile Packages

```bash
# List installed packages
nix profile list

# Remove Dagger from profile
nix profile remove dagger

# Upgrade all profile packages
nix profile upgrade
```

## Building Process

This flake builds Dagger v0.18.10 from source. The build process includes:

1. Fetching source from GitHub
2. Patching Go version compatibility
3. Building with pre-computed vendor hash
4. Skipping tests to avoid network dependencies

## Troubleshooting

### Getting the Correct Vendor Hash

The process requires two steps to get the correct vendor hash:

1. **First, enable `go mod tidy` to update dependencies:**

   ```nix
   vendorHash = pkgs.lib.fakeHash;
   
   postPatch = ''
     substituteInPlace go.mod \
       --replace-fail "go 1.24.4" "go 1.24"
     
     # Temporarily enable go mod tidy
     export GOCACHE=$TMPDIR/go-cache
     export GOMODCACHE=$TMPDIR/go-mod
     export HOME=$TMPDIR
     ${pkgs.go}/bin/go mod tidy
   '';
   ```

2. **Run `nix build` to get the correct hash** - it will fail and show the real hash

3. **Replace the fake hash and disable `go mod tidy`:**

   ```nix
   vendorHash = "sha256-RealHashFromStep2";
   
   postPatch = ''
     substituteInPlace go.mod \
       --replace-fail "go 1.24.4" "go 1.24"
     
     # Disable go mod tidy after getting correct hash
     # ${pkgs.go}/bin/go mod tidy
   '';
   ```

4. **Build again** - it should now succeed

### Common Issues

**"homeless-shelter" error**: This occurs when Go tries to access `$HOME/.cache` during build. Fixed by setting temporary directories:

```nix
export GOCACHE=$TMPDIR/go-cache
export GOMODCACHE=$TMPDIR/go-mod
export HOME=$TMPDIR
```

**Network access errors**: Tests are disabled (`checkPhase = ""`) because Nix builds are hermetic with no network access. Go tests often try to download dependencies, which fails in the sandboxed build environment.

**Go version mismatch**: The flake patches `go.mod` to use Go 1.24 instead of 1.24.4 for compatibility.

## Build Configuration

Key settings in the flake:

- `doCheck = false` - Disables Go tests
- `checkPhase = ""` - Explicitly disables check phase
- `vendorHash` - Pre-computed hash of Go dependencies
- `postPatch` - Patches Go version in go.mod

## Development

```bash
# Enter development shell
nix develop

# Build with changes
git add . && nix build
```

The `git add .` is needed because Nix tracks git state, and uncommitted changes will show a "dirty tree" warning.

## Version

Currently building Dagger v0.18.10. To update:

1. Change the `version` variable
2. Update the `sha256` hash for the new source
3. Update the `vendorHash` using the process above
