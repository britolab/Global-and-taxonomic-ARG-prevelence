#$ -S /bin/bash
#$ -N RGI
#$ -o /workdir/users/pd378/oil_international/args_prevelence/kma_metagenomic_profiling/kma_process_out.txt
#$ -e /workdir/users/pd378/oil_international/args_prevelence/kma_metagenomic_profiling/kma_process_err.txt
#$ -wd /workdir/users/pd378/oil_international/args_prevelence/kma_metagenomic_profiling/ #working directory
#$ -pe parenv 1
#$ -l h_vmem=20G
#$ -t 9000-13289
#$ -tc 8
#$ -q long.q@cbsubrito.tc.cornell.edu


#"""
#This script is meant to run ahead of the rgi-bwt in order to download, decompress, and trim the reads without wasting resources


#This Script performs 3 jobs:
#1) Downloads all the fastq files accociated with a sample using FTP
#2) Unzips the fastq file and combines them all into a singel fastq file
#3) Removes adapter sequences using bbduk

#Files from the previous step are deleted after each consecutive step

#"""

### Define directories
WRK=/workdir/users/pd378/oil_international/args_prevelence/kma_metagenomic_profiling
LIST_FILE=$WRK/compile_accessions/accession_lists/01_low_read_samples.txt
OUT=$WRK/kma_results
DOWNLOAD=$WRK/temporary_download
DB=$WRK/kma_db/card_plus_pili_index

### initialize file to keep track of processing time
#echo -e "study_sample\tdownoad_time\ttrimming_time\tfastqc_time\tkma_time\ttotal_time\tdownloaded_reads\ttrimmed_reads" > $WRK/kma_stats_tracking.txt

### activate the conda environment
source /home/pd378/miniconda3/bin/activate
conda activate rgi_manual

### initialize the shared memory database
#kma shm -t_db $DB -shmLvl 1


### Make the design file
DESIGN=$(sed -n "${SGE_TASK_ID}p" $LIST_FILE)
NAME=`basename "$DESIGN"`

### Initialize output directories
    OUTPUT=$OUT/${NAME}_out
    if test -d "$OUTPUT"; then
        rm -r $OUTPUT
    fi
    mkdir $OUTPUT
    
    if test -f "$DOWNLOAD/cat_location/${NAME}_full.fastq"; then
        rm $DOWNLOAD/cat_location/${NAME}_full.fastq
    fi
    
### Download and combine the metagenomic reads
    START_download="$(date +%s)"
    # loop thorugh ftp links to donwload, unzip, and combine into one fastq
    while read COMBO_NAME STUDY SAMPLE ACCESSION FTP; do
        # download the file with the FTP link
        wget -c --tries=inf --retry-connrefused -P $DOWNLOAD/ftp_location/ ftp://${FTP} 2> $OUTPUT/log_wget.txt
 
        # unzip it and combine into a single file
        gunzip -c $DOWNLOAD/ftp_location/${ACCESSION}.fastq.gz >> $DOWNLOAD/cat_location/${NAME}_full.fastq
        # remove the donwloaded file to save space
        rm $DOWNLOAD/ftp_location/${ACCESSION}.fastq.gz
    done < $WRK/compile_accessions/accession_lists/${NAME}_ftp_list.txt
    END_download="$(date +%s)"
    
    
### Trim adapters using bbtools/bbduc
### Run with default paramaters but custom adapter file
    START_bbduk="$(date +%s)"
    
    BBTOOLS=/programs/bbmap-38.96
    $BBTOOLS/bbduk.sh \
        in=$DOWNLOAD/cat_location/${NAME}_full.fastq \
        out=$DOWNLOAD/trim_location/${NAME}_full.fastq \
        ref=$WRK/scripts/adapters.fasta \
        ktrim=r k=23 mink=11 hdist=1 tpe tbo 2> $OUTPUT/log_bbduk.txt
    END_bbduk="$(date +%s)"
    
   
### Count the number of reads
    downloaded_line_count=$(wc -l < "$DOWNLOAD/cat_location/${NAME}_full.fastq")
    trimmed_line_count=$(wc -l < "$DOWNLOAD/trim_location/${NAME}_full.fastq")
    
    rm $DOWNLOAD/cat_location/${NAME}_full.fastq
    
    
### Run FASTQC on the trimmed reads ### may remove later
    START_fastqc="$(date +%s)"
#    /programs/FastQC-0.11.8/fastqc $DOWNLOAD/trim_location/${NAME}_full.fastq -o $OUTPUT 2> $OUTPUT/log_fastqc.txt
    END_fastqc="$(date +%s)" 

source /home/pd378/miniconda3/bin/activate
conda activate rgi_manual
### Runn KMA alignment to detect ARGs in the metagenomes
    START_kma="$(date +%s)"
    
    kma -i $DOWNLOAD/trim_location/${NAME}_full.fastq \
    -o $OUTPUT/${NAME}_kma \
    -t_db $DB 2> $OUTPUT/log_kma.txt
    
    END_kma="$(date +%s)"


### calculate how many reads were downloaded and left over after trimming for each sample
downloaded_read_count=$(($downloaded_line_count / 4))
trimmed_read_count=$(($trimmed_line_count / 4))

### delete the downloaded metagenome to save space
rm $DOWNLOAD/trim_location/${NAME}_full.fastq

### calculate the time for downloading and trimmming each file
DOWNLOAD_DURATION=$[ ${END_download} - ${START_download} ]
BBDUK_DURATION=$[ ${END_bbduk} - ${START_bbduk} ]
FASTQC_DURATION=$[ ${END_fastqc} - ${START_fastqc} ]
KMA_DURATION=$[ ${END_kma} - ${START_kma} ]
FULL_DURATION=$[ ${END_kma} - ${START_download} ]

DOWNLOAD_MINUTE=`echo "scale=2; $DOWNLOAD_DURATION/60" | bc -l`
BBDUK_MINUTE=`echo "scale=2; $BBDUK_DURATION/60" | bc -l`
FASTQC_MINUTE=`echo "scale=2; $FASTQC_DURATION/60" | bc -l`
KMA_MINUTE=`echo "scale=2; $KMA_DURATION/60" | bc -l`
FULL_MINUTE=`echo "scale=2; $FULL_DURATION/60" | bc -l`


### compile all this infor into a tabbed file for analysis
echo -e "${NAME}\t${DOWNLOAD_MINUTE}\t${BBDUK_MINUTE}\t${FASTQC_MINUTE}\t${KMA_MINUTE}\t${FULL_MINUTE}\t${downloaded_read_count}\t${trimmed_read_count}" >> $WRK/kma_stats_tracking.txt
