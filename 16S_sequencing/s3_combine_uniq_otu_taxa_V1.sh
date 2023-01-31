#!/bin/bash

WRK=/workdir/users/pd378/oil_international/sequence_processing/16S_run1.3


QFILTER_IN=$WRK/s1_merge_qFilter/quality_filtered
UNIQUE_OUT=$WRK/s2_filter_uniques
OTU_TAX_OUT=$WRK/s3_cluster_assign_taxonomy

mkdir $UNIQUE_OUT $SPLIT_OUT/stats $UNIQUE_OUT/stats $OTU_TAX_OUT

#combine all the reads into a single fasta
NAME=00_all_combined
cat $QFILTER_IN/*_filtered.fa > $QFILTER_IN/${NAME}_filtered.fa


########### RUN FILTER UNIQUES #################
#export usearch
export PATH=/programs/usearch11.0.667:$PATH

U_OUT=$UNIQUE_OUT/${NAME}_unique.fa
U_STATS=$UNIQUE_OUT/stats/${NAME}.txt
            
usearch -fastx_uniques $QFILTER_IN/${NAME}_filtered.fa -fastaout $UNIQUE_OUT/${NAME}_uniq.fa \
            -relabel community_uniq_ -sizeout 2> $UNIQUE_OUT/stats/${NAME}_uniq.fa
#echo $NAME filter uniques complete


##### cluster the OTUs ####

PARSED=$OTU_TAX_OUT/uniq_parsed_otu_tab.txt
OTUS=$OTU_TAX_OUT/uniq_clustered_otus.fa
STATS=$OTU_TAX_OUT/uniq_otu_stats.txt

usearch -cluster_otus $U_OUT -otus $OTUS -relabel otu -uparseout $PARSED -minsize 1 2> $STATS

## Asign taxonomy unsing MOTHUR

cd $OTU_TAX_OUT
SILVA=/workdir/users/pd378/DataBases/MOTHUR_SILVA/silva.nr_v132.V4_oil
/programs/mothur/mothur "#classify.seqs(fasta=$OTUS,  template=$SILVA.align, taxonomy=$SILVA.tax, processors=20)"
