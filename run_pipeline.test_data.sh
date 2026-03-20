#!/usr/bin/env bash

#module load java/21.0.2

GENOME_DIR="/fs/project/PCON0005/genomes/Homo_sapiens.GRCh38.113"
DATA_DIR="/fs/project/PCON0005/test_data/Tsai_MuChun_atac-seq"

args=(
  run nf-core/atacseq
  -r 2.1.2
  -resume
  -c osc.config # set image cache dir & OSC specific cluster options
  -c extra.config # give BEDTOOLS_GENOMECOV step extra memory & time
  -profile apptainer
  -w ./work
  --input "${DATA_DIR}/sample_sheet.csv"
  --outdir ./results
  --aligner bwa
  # --aligner bowtie2
  --read_length 150
  --igenomes_ignore true
  --fasta "${GENOME_DIR}/Homo_sapiens.GRCh38.dna_sm.primary_assembly.fa.gz"
  --gtf "${GENOME_DIR}/Homo_sapiens.GRCh38.113.gtf.gz"
  --bwa_index "${GENOME_DIR}/index/bwa"
  # --save_reference # Not needed with *_index defined
)

exec nextflow "${args[@]}"
