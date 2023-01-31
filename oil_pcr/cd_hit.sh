#!/bin/bash

WRK=/workdir/users/pd378/oil_international/sequence_processing/oil_run2.1

FASTAS=$WRK/s5_analysis/cd_hit


/programs/cd-hit-4.8.1/cd-hit -i $FASTAS/ribo_asv.fasta -o $FASTAS/ribo_hit_99.fasta -c 0.99 -g 1 -bak 1 -d 100
/programs/cd-hit-4.8.1/cd-hit -i $FASTAS/target_asv.fasta -o $FASTAS/target_hit_99.fasta -c 0.99 -g 1 -bak 1 -d 100