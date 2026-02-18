#!/usr/bin/env bash

#module load java/21.0.2

args=(
  run nf-core/atacseq
  -r 2.1.2
  -resume
  -c osc.config # set image cache dir & OSC specific cluster options
  -c extra.config # give BEDTOOLS_GENOMECOV step extra memory & time
  -profile apptainer
  -w ./work
  --input ./sample_sheet.csv
  --outdir ./results
#  --outdir ./results.GRCh38
  --read_length 150
#  --genome GRCh37 # igenomes reference
  --igenomes_ignore true
  --fasta `readlink -m ./Homo_sapiens.GRCh38.dna_sm.primary_assembly.fa.gz` # GUNZIP step errors with null pointer if we use relative paths here
  --gtf `readlink -m ./Homo_sapiens.GRCh38.113.gtf.gz` # GUNZIP step errors with null pointer if we use relative paths here
  --save_reference
)

exec nextflow "${args[@]}"
