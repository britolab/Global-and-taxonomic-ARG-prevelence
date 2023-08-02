#!/bin/bash

######
# this script is used to split the fusion PCR reads into the target sequence and 16S sequence
    # First it runs usearch to cluster otus
    # then it uses mothur to classify the OTU taxonomy
#####
# dependencies: 
    # usearch11.0.667
    # mothur
#####
# to run:
# 1) change the working directory WRK on line 16
# 2) make sure that UNIQ_READS is the directory of the output from s2_combine_split_sort_V2.sh

WRK=/workdir/users/pd378/oil_international/sequence_processing/commensal_oil_run1.0
UNIQ_READS=$WRK/s2_split_sort_unique/unique/ribo_all.fa
OTU_TAX_OUT=$WRK/s3_cluster_assign_taxonomy

mkdir $OTU_TAX_OUT

##### begin to dereplicate the combined reads ####
export PATH=/programs/usearch11.0.667:$PATH


##### cluster the OTUs ####

PARSED=$OTU_TAX_OUT/uniq_parsed_otu_tab.txt
OTUS=$OTU_TAX_OUT/uniq_clustered_otus.fa
STATS=$OTU_TAX_OUT/uniq_otu_stats.txt

usearch -cluster_otus $UNIQ_READS -otus $OTUS -relabel otu -uparseout $PARSED -minsize 1 2> $STATS

## Asign taxonomy unsing MOTHUR

cd $OTU_TAX_OUT
SILVA=/workdir/users/pd378/DataBases/MOTHUR_SILVA/silva.nr_v132.V4_oil
/programs/mothur/mothur "#classify.seqs(fasta=$OTUS,  template=$SILVA.align, taxonomy=$SILVA.tax, processors=20)"
