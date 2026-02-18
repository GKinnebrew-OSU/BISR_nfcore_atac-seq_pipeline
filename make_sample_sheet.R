library(tidyverse)
library(magrittr)

r1_files <- 
  fs::dir_ls("./data/ATAC-seq/01.RawData/", recurse = TRUE, glob = "*_1.fq.gz") %>%
  tibble(fastq_1 = .) %>%
  mutate(sample = str_extract(fastq_1, "(Infctd|Uninfctd)_rep[0-9]", group=0),
         replicate = 1)

r2_files <- 
  fs::dir_ls("./data/ATAC-seq/01.RawData/", recurse = TRUE, glob = "*_2.fq.gz") %>%
  tibble(fastq_2 = .) %>%
  mutate(sample = str_extract(fastq_2, "(Infctd|Uninfctd)_rep[0-9]", group=0),
         replicate = 1)


left_join(r1_files, r2_files) %>%
  select(sample, fastq_1, fastq_2, replicate) %>%
  write_csv("./sample_sheet.csv")
