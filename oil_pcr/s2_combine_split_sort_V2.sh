#!/bin/bash

######
# this script is used to split the fusion PCR reads into the target sequence and 16S sequence
    # First it concatinates the quality filtered reads from s1.1_run_mrg_trim_flt.qsub.sh into a single file
    # Then it runs cutadapt for each target to identify the fusion primer sequence and trim off the 16S sequence and sorting the sequences by target
    # cutadapt is run a final time to trim the target sequence from the 16S sequence
        # cutadapt was used becasue it will tolerate mutations and deletions that are common at the fusion junction as well as degenerate bases
    # lastly, the target and 16S reads are filtered for uniques
#####
# dependencies: 
    # usearch11.0.667
    # cutadapt-3.4
#####
# to run:
# 1) change the working directory WRK on line 26
# 2) make sure 'QFILTER_IN' on line 28 is the directory of the output from s1.1_run_mrg_trim_flt.qsub.sh
# 3) Change the TARGET variables
    # a) set the TARGET name variables for each target on line 42 (add or delete targets as necessary)
    # b) set the target fusion variables for each target on line 46 (the reverse compliment of each fusion primer)
    # c) the ribo sequence will be the 519F sequence (shoudn't have to change)
    # d) adjust the target lenths on line 55. This will be the length of the target sequence without the primers
# 4) add or delete cutadapt calls on line 61 for each target (the only difference is the target number)
# 5) cadd or delete fasx_unique calls on line 83 for the number of targets  

WRK=/workdir/users/pd378/oil_international/sequence_processing/commensal_oil_run1.0

QFILTER_IN=$WRK/s1_merge_qFilter/quality_filtered
#Q_IN=$QFILTER_OUT/${NAME}_filtered.fa
OUT=$WRK/s2_split_sort_unique
SPLIT_OUT=$OUT/split_sorted
UNIQUE_OUT=$OUT/unique
mkdir $OUT $SPLIT_OUT $UNIQUE_OUT $SPLIT_OUT/stats $UNIQUE_OUT/stats

#combine all the reads into a single fasta
NAME=000_all_combined_filtered.fa
cat $QFILTER_IN/*_filtered.fa > $OUT/${NAME}



######### USE CUTADAPT TO SPLIT THE READS ################
TARGET_1=cfiA
TARGET_2=cepA
TARGET_3=cblA
#rev compliment of the fusion primer
TARGET_1_fuse=CAATGACGCACAAACGGAAACAGCMGCCGCGGTAATWC  #cfiA
TARGET_2_fuse=GATGATGCATGTAATCGGCCACAGCMGCCGCGGTAATWC   #cepA
TARGET_3_fuse=GGATTTCACGATTACGCTTAGGGCAGCMGCCGCGGTAATWC   #cblA
#16S 519F primer
RIBO_F=CAGCMGCCGCGGTAATWC
RIBO_len=250

## additional filter by length just in case
TARGET_1_len=82 #cfiA
TARGET_2_len=92 #cepA
TARGET_3_len=91 #cblA

export PYTHONPATH=/programs/cutadapt-3.4/lib/python3.6/site-packages:/programs/cutadapt-3.4/lib64/python3.6/site-packages
export PATH=/programs/cutadapt-3.4/bin:$PATH

cutadapt -a $TARGET_1_fuse --discard-untrimmed -o $SPLIT_OUT/target_${TARGET_1}_all.fa $OUT/${NAME} --suffix _${TARGET_1} --cores=10 \
        -m $[TARGET_1_len-3] -M $[TARGET_1_len+3] > $SPLIT_OUT/stats/target_${TARGET_1}_all.txt
        
cutadapt -a $TARGET_2_fuse --discard-untrimmed -o $SPLIT_OUT/target_${TARGET_2}_all.fa $OUT/${NAME} --suffix _${TARGET_2} --cores=10 \
        -m $[TARGET_2_len-3] -M $[TARGET_2_len+3] > $SPLIT_OUT/stats/target_${TARGET_2}_all.txt
        
cutadapt -a $TARGET_3_fuse --discard-untrimmed -o $SPLIT_OUT/target_${TARGET_3}_all.fa $OUT/${NAME} --suffix _${TARGET_3} --cores=10 \
        -m $[TARGET_3_len-3] -M $[TARGET_3_len+3] > $SPLIT_OUT/stats/target_${TARGET_3}_all.txt
        
cutadapt -g $RIBO_F --discard-untrimmed -o $SPLIT_OUT/ribo_all.fa $OUT/${NAME} --suffix _ribo --cores=10 \
        -m $[RIBO_len-3] -M $[RIBO_len+3] > $SPLIT_OUT/stats/ribo_all.txt



########### RUN FILTER UNIQUES #################
#export usearch
export PATH=/programs/usearch11.0.667:$PATH


U_OUT=$UNIQUE_OUT/${NAME}_unique.fa
U_STATS=$UNIQUE_OUT/stats/${NAME}.txt

usearch -fastx_uniques $SPLIT_OUT/target_${TARGET_1}_all.fa -fastaout $UNIQUE_OUT/target_${TARGET_1}_all.fa \
            -relabel ${TARGET_1}_uniq_ -sizeout 2> $UNIQUE_OUT/stats/target_${TARGET_1}_all.txt
usearch -fastx_uniques $SPLIT_OUT/target_${TARGET_2}_all.fa -fastaout $UNIQUE_OUT/target_${TARGET_2}_all.fa \
            -relabel ${TARGET_2}_uniq_ -sizeout 2> $UNIQUE_OUT/stats/target_${TARGET_2}_all.txt
usearch -fastx_uniques $SPLIT_OUT/target_${TARGET_3}_all.fa -fastaout $UNIQUE_OUT/target_${TARGET_3}_all.fa \
            -relabel ${TARGET_3}_uniq_ -sizeout 2> $UNIQUE_OUT/stats/target_${TARGET_3}_all.txt
            
usearch -fastx_uniques $SPLIT_OUT/ribo_all.fa -fastaout $UNIQUE_OUT/ribo_all.fa \
            -relabel ribo_uniq_ -sizeout 2> $UNIQUE_OUT/stats/ribo_all.txt
#echo $NAME filter uniques complete

