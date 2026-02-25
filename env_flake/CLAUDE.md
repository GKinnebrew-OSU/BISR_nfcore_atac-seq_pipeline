# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Nix R/RStudio Environment

This project provides a reproducible Nix environment for R and RStudio with custom package overrides using a local overlay system to resolve version conflicts.

## Quick Start

Test the environment:
```bash
~/scratchfs/nixsa/bin/nix run
```

Test specific R functionality:
```bash
~/scratchfs/nixsa/bin/nix run . -- Rscript --version
~/scratchfs/nixsa/bin/nix run . -- Rscript test_immunarch.R
```

## Architecture

This is a Nix flake that creates an isolated R/RStudio environment using:
- **FHS Environment**: Wraps the entire R ecosystem in a Filesystem Hierarchy Standard container
- **Package Overlay System**: Uses `rPackagesOverlay` to override specific R packages with custom versions
- **SSH Tunnel Integration**: Configured for remote access via SSH tunneling

### Key Components

1. **`rPackagesOverlay`**: Defines custom R package builds with complete dependency specifications to avoid version conflicts
2. **`buildFHSEnv`**: Creates the containerized environment with proper filesystem bindings
3. **`start-rserver` script**: Configures and launches RStudio Server with authentication
4. **`pacmap.nix`**: Custom Python package for specialized analytics

## Development Commands

### Environment Testing
```bash
# Test basic environment
~/scratchfs/nixsa/bin/nix run

# Test R functionality
~/scratchfs/nixsa/bin/nix run . -- Rscript --version
~/scratchfs/nixsa/bin/nix run . -- Rscript test_immunarch.R

# Launch RStudio Server
~/scratchfs/nixsa/bin/nix run . -- start-rserver
```

### Adding R Package Overrides

**Critical**: All `propagatedBuildInputs` must reference `final.rPackages` to ensure dependency resolution uses overridden versions rather than base nixpkgs versions.

Add to `rPackagesOverlay` in `flake.nix`:
```nix
newPackage = final.rPackages.buildRPackage {
  name = "newPackage";
  version = "x.y.z";
  src = prev.fetchurl {
    url = "https://cran.r-project.org/src/contrib/newPackage_x.y.z.tar.gz";
    sha256 = "sha256-HASH";
  };
  propagatedBuildInputs = with final.rPackages; [
    dependency1 dependency2 customOverriddenDep
  ];
};
```

### Hash Generation
```bash
~/scratchfs/nixsa/bin/nix-prefetch-url https://cran.r-project.org/src/contrib/package_version.tar.gz
~/scratchfs/nixsa/bin/nix hash to-sri --type sha256 <hash>
```

## Current Package Overrides

- **duckplyr 1.1.3**: Latest CRAN version (resolves version conflict from 1.1.1 in nixpkgs)
- **immundata 0.0.5**: Updated with required dependencies (dbplyr, ggplot2, etc.)
- **immunarch 0.10.3**: Updated with extensive dependency specification (47+ packages)
- **MetaboAnalystR**: GitHub build from xia-lab with bioinformatics dependencies (currently fails compliation)

## Environment Specifications

- **R**: 4.5.1 with custom package set
- **RStudio Server**: 2025.09.1+401
- **Python**: 3.x with numpy and custom pacmap package
- **Container**: FHS environment with proper filesystem bindings for HPC systems

## Troubleshooting

### Version Conflicts
**Root cause**: Base nixpkgs packages loading before overlay packages.
**Solution**: Ensure all `propagatedBuildInputs` reference `final.rPackages` not `prev.rPackages`.

### Build Failures
```bash
# View full build logs
nix log /nix/store/failed-derivation-path

# Clean rebuild
nix build --rebuild
```

### MetaboAnalystR Issues
Known issue: `undefined symbol: match5` - missing fastmatch linkage. Currently working override includes `fastmatch` in dependencies.

### SSH Connection
RStudio Server runs on Unix socket. Connect via:
```bash
ssh -N -L 8787:$TMPDIR$SOCKET $USER@hostname
# Then access http://localhost:8787
```