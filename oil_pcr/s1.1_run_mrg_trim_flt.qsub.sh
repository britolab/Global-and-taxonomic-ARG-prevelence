#$ -S /bin/bash
#$ -N merge_remove-primers_quality-filter
#$ -o /workdir/users/pd378/oil_international/sequence_processing/commensal_oil_run1.0/read_process_out.txt
#$ -e /workdir/users/pd378/oil_international/sequence_processing/commensal_oil_run1.0/read_process_err.txt
#$ -wd /workdir/users/pd378/oil_international/sequence_processing/commensal_oil_run1.0 #Your working directory
#$ -pe parenv 1
#$ -l h_vmem=5G
#$ -t 1-52
#$ -q long.q@cbsubrito.tc.cornell.edu

#####
# This script runs 3 programs to process the raw reads
    # First it merges the forward and reverse reads using usearch -fastq_mergepairs
    # Then it trims the primers using cutadapt
    # lastly it quality fitleres the reads with usearch -fastq_filter
#####
# dependencies: 
    # usearch11.0.667
    # cutadapt-3.4
#####
# To run:
# 1) change the workdir on line 31 to your working directory
# 2) prepare a list of samples removing the R1.fastq or R2.fastq suffix and add the path to LIST on line 35
# 3) Adjust the merge variables for your specific construct length starting on line 38. PCTID is the most important
# 4) Add the target primer sequence to the cutadapt variables starting on line 49 and adjust the cutadapt call for the number of multiplexed targets
# 5) adjusted max error for quality filtering on line 57 if desired. Currently set very low for stringent filtering

#export usearch
export PATH=/programs/usearch11.0.667:$PATH
##Set dirs
    WRK=/workdir/users/pd378/oil_international/sequence_processing/commensal_oil_run1.0
    OUT=$WRK/s1_merge_qFilter
    mkdir $OUT
    ##Path to the list of file names
    LIST=$WRK/file_lists/master_list.txt
    
####MERGE VARIABLES###
    MERGE_IN=$WRK/rawdata ## raw reads folder
    MERGE_OUT=$OUT/merged_reads ##where to put the merged reads
    MIN_MERGE=350       #cutoff for minimum merge length (15 +/- expected length)
    MAX_MERGE=470       #cutoff for maximum merge length 
    MAX_DIFFS=10       #How many difference are allowed for overlap  (10% of overlap)
    PCTID=80 

####CUTADAPT PRIMER STRIP####  set variables in call
    PSTRIP_OUT=$OUT/primers_stripped #output for the stripped reads

    # nested OIL primer sequences, additional sequences must be added to the cutadapt call
    TARGET_1_F2=TACACTTATGTATCCCTCGCCG            #cfiA
    TARGET_2_F2=GGCAATGCTCATTTCGATTCC             #cepA
    TARGET_3_F2=CGTACTGGACAAGATGGATAAGC          #cblA
    # reverse compliment of the 786R primer
    RIBO_R=ATTAGAWACCCBDGTAGTCC

####QUALITY FILTER VARIABLES####
    QFILTER_OUT=$OUT/quality_filtered
    MAX_ERROR=0.5
    
                
##Make the design file
        DESIGN=$(sed -n "${SGE_TASK_ID}p" $LIST)
        NAME=`basename "$DESIGN"`

##############RUN USEARCH MERGE PAIRS ####################
mkdir $MERGE_OUT
mkdir $MERGE_OUT/stats
FORWARD=$MERGE_IN/${NAME}_R1.fastq
REVERSE=$MERGE_IN/${NAME}_R2.fastq
M_OUT=$MERGE_OUT/${NAME}_merged.fq
M_STATS=$MERGE_OUT/stats/${NAME}.txt

usearch -fastq_mergepairs $FORWARD -reverse $REVERSE -fastq_pctid $PCTID -fastq_minmergelen $MIN_MERGE -fastq_maxmergelen $MAX_MERGE -fastq_maxdiffs $MAX_DIFFS -fastqout $M_OUT -relabel ${NAME}_ 2> $M_STATS
#usearch -fastq_mergepairs $FORWARD -reverse $REVERSE -fastq_pctid $PCTID -fastq_minmergelen $MIN_MERGE -fastq_maxmergelen $MAX_MERGE -fastqout $M_OUT -relabel $NAME 2> $M_STATS

echo $NAME merge complete

############ RUN CUTADAPT PRIMER REMOVAL #####################
mkdir $PSTRIP_OUT
mkdir $PSTRIP_OUT/stats
P_OUT=$PSTRIP_OUT/${NAME}_stripped.fq
P_STATS=$PSTRIP_OUT/stats/${NAME}.txt

export PYTHONPATH=/programs/cutadapt-3.4/lib/python3.6/site-packages:/programs/cutadapt-3.4/lib64/python3.6/site-packages
export PATH=/programs/cutadapt-3.4/bin:$PATH

cutadapt -a ^${TARGET_1_F2}...${RIBO_R}$ -a ^${TARGET_2_F2}...${RIBO_R}$ -a ^${TARGET_3_F2}...${RIBO_R}$ \
             --discard-untrimmed  -o $P_OUT $M_OUT --cores=2 > $P_STATS

echo $NAME primer strip complete

########### RUN QUALITY FILTER ###################
mkdir $QFILTER_OUT
mkdir $QFILTER_OUT/stats
Q_OUT=$QFILTER_OUT/${NAME}_filtered.fa
Q_STATS=$QFILTER_OUT/stats/${NAME}.txt

usearch -fastq_filter $P_OUT -fastq_maxee $MAX_ERROR -fastaout $Q_OUT 2> $Q_STATS

echo $NAME quality filter compete




















