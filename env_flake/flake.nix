{
  description = "virtual environment with Rstudio, R, Shiny";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";


    outputs = { self, nixpkgs, flake-utils }:
    let
      # Define source fileset to only include necessary files
      sourceFiles = nixpkgs.lib.fileset.toSource {
        root = ./.;
        fileset = nixpkgs.lib.fileset.unions [
          ./flake.nix
          ./flake.lock
          ./start-rserver
          ./pacmap.nix
          ./test_immunarch.R
        ];
      };
      
      rPackagesOverlay = final: prev: {
        rPackages = prev.rPackages // rec {
          duckplyr = final.rPackages.buildRPackage {
            name = "duckplyr";
            version = "1.1.3";
            src = prev.fetchurl {
              url = "https://cran.r-project.org/src/contrib/duckplyr_1.1.3.tar.gz";
              sha256 = "sha256-DsdeccLJYC2JLkE19oZwg8KlZa02AMDoavAl9zUJ4ko=";
            };
            propagatedBuildInputs = with final.rPackages; [
              DBI R6 cli dplyr duckdb pillar rlang tibble vctrs
              collections jsonlite memoise
            ];
          };
          
          immundata = final.rPackages.buildRPackage {
            name = "immundata";
            version = "0.0.5";
            src = prev.fetchurl {
              url = "https://cran.r-project.org/src/contrib/immundata_0.0.5.tar.gz";
              sha256 = "sha256-FtgUvqJCt78sOz5xvh0pRkzNCKjYGjBLOxyjH8S8pTw=";
            };
            propagatedBuildInputs = with final.rPackages; [
              dbplyr ggplot2 duckplyr checkmate jsonlite readr
            ];
          };
          
          immunarch = final.rPackages.buildRPackage {
            name = "immunarch";
            version = "0.10.3";
            src = prev.fetchurl {
              url = "https://cran.r-project.org/src/contrib/immunarch_0.10.3.tar.gz";
              sha256 = "sha256-6AD/Wf20GOi+3MkZmsRBRZn/dklYwSTpacJ9x7QDaaI=";
            };
            propagatedBuildInputs = with final.rPackages; [
              immundata checkmate duckplyr dbplyr ggthemes Rcpp
              data_table dplyr ggplot2 magrittr plyr readr readxl
              rlang seqinr stringr tibble patchwork dtplyr pheatmap
              reshape2 circlize airr stringdist ape doParallel rlist ggsci
            ];
          };
          
          MetaboAnalystR = final.rPackages.buildRPackage {
            name = "MetaboAnalystR";
            src = prev.fetchFromGitHub {
              owner = "xia-lab";
              repo = "MetaboAnalystR";
              rev = "d6e31c67a3f9ab5442ca116bc502b4773c340717";
              sha256 = "sha256-LUcSx+f4osa+FtdS5bc2/RBSzolsD2Ze4PHz6PtM3xM=";
            };
            propagatedBuildInputs = with final.rPackages; [
              RBGL RColorBrewer RJSONIO fitdistrplus RSQLite Cairo Rcpp ggplot2 
              BiocParallel progress Rserve rlang jsonlite plyr purrr data_table 
              vctrs qs pROC caret crmn dplyr edgeR fgsea glasso gplots igraph 
              impute pcaMethods plotly scales MSnbase tibble siggenes lattice MASS
              fastmatch
            ];
          };
        };
      };
      pkgsForSystem = system:
        import nixpkgs {
          overlays = [ rPackagesOverlay ];
          inherit system;
        };

    in
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = pkgsForSystem system;
        RPkgs = with pkgs.rPackages; [
          tidyverse
          readxl
          box
          renv
          remotes
          ## Metabolomics Packages
          #xcms
          #BiocParallel #needed by xcms
          #MetaboAnalystR
          ## Genomics Packages
          GenomicRanges
          GenomicAlignments
          GenomicFeatures
          txdbmaker
          Rsamtools
          rtracklayer
          Gviz
          #ggcoverage
          ggbio
          gggenomes
          #vcfR
          # TCR Seq
          #immunarch
          ## Statistical Analysis Packages
          #umap
          #sp # for point.in.polygon
          DESeq2
          #MOFA2
          #fgsea
          #edgeR
          limma
          #tximport
          #tximeta
          #ensembldb
          #txdbmaker
          ## R utilities
          #renv
          targets
          #drake
          crew
          future
          #reticulate
          reproducible
          r_import
          tictoc
          ## Graphics
          shiny
          plotly
          ggpubr
          cowplot
          GGally
          UpSetR
          eulerr
          DT
          ComplexHeatmap
          ## Large Data Manipulation
          arrow
          duckdb
          duckplyr
          languageserver
          jsonlite
        ];
        
        myPython = (pkgs.python3.withPackages (python-pkgs: [
          python-pkgs.numpy
          (python-pkgs.callPackage "${sourceFiles}/pacmap.nix" {})
        ]));
        myR = pkgs.rWrapper.override{ packages = RPkgs;};
        myRstudioServer = pkgs.rstudioServerWrapper.override{ packages = RPkgs; };

        runscript = pkgs.writeShellScript "runscript" ''
          # Default command if no arguments provided
          if [ $# -eq 0 ]; then
            set -- start-rserver
          fi
          # Pass all arguments preserving quoting
          exec env -i USER=''$USER HOME=''$HOME NIX_SSL_CERT_FILE=''$NIX_SSL_CERT_FILE SOCKET=''$SOCKET RSERVER_START_MSG=''$RSERVER_START_MSG bash -l -- "$@"
        '';
        start_rserver = pkgs.writeScriptBin "start-rserver" (builtins.readFile "${sourceFiles}/start-rserver");

        fhs = pkgs.buildFHSEnv {
          name = "RstudioServerFHS";
          targetPkgs = pkgs: [
              # Custom Packages
              myR 
              myRstudioServer
              myPython
              start_rserver

              #Included Packages
              pkgs.bashInteractive
              pkgs.coreutils
              pkgs.sssd
              pkgs.curl
              pkgs.git
              pkgs.zip
              pkgs.file
              pkgs.which
            ]; 

          runScript="${runscript}";
          #we need this to be a dir to --bind to it later
          extraBuildCommands = "mkdir -p $out/usr/share/zoneinfo";
          extraPreBwrapCmds = ''
            SOCKET="/tmp/rstudio.sock"

            mkdir -p "/tmp/$USER"
            TMPDIR=$(mktemp -d "/tmp/$USER/rstudio-XXXX")
            mkdir -p $TMPDIR/var/lib
            mkdir -p $TMPDIR/var/run
            mkdir -p $TMPDIR/tmp

            # Create startup message and base64 encode it (will only be printed by start-rserver script)
            RSERVER_START_MSG=$(cat <<END | base64 -w 0
------------------------------------------------------------------------------------------------------------
Starting Rstudio Server
  datadir:
    $TMPDIR
  Connect:
    ssh -N -L 8787:$TMPDIR$SOCKET $USER@$(hostname)
------------------------------------------------------------------------------------------------------------
END
)

            etc_ignored+=("/etc/localtime") # We'll symlink this manually with bwrap
          '';

          extraBwrapArgs = [
            "--tmpfs /var/lib"
            "--tmpfs /var/run"
            "--bind $TMPDIR/var/lib /var/lib/rstudio-server"
            "--bind $TMPDIR/var/run /var/run/rstudio-server"
            "--bind $TMPDIR/tmp /tmp"

            "--bind /var/lib/sss/pipes/nss /var/lib/sss/pipes/nss" # so username lookup works on OSC
            "--bind /usr/share/zoneinfo /usr/share/zoneinfo" # because /etc/localtime symlinks to here on OSC
            "--symlink /usr/share/zoneinfo/America/New_York /etc/localtime" # R gets confused with /etc/localtime links to a symlink (in /.host-etc)

            "--setenv SOCKET $SOCKET"
            "--setenv RSERVER_START_MSG $RSERVER_START_MSG"
           ];
        };

      in {
        devShells.default = fhs.env;
        packages.default = fhs;
        packages.r = myR;
      }
    );
}
