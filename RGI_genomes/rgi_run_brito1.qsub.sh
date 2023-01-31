#$ -S /bin/bash
#$ -N RGI
#$ -o /workdir/users/pd378/oil_international/args_prevelence/custom_card_search/rgi_analysis/rgi_process_out.txt
#$ -e /workdir/users/pd378/oil_international/args_prevelence/custom_card_search/rgi_analysis/rgi_process_err.txt
#$ -wd /workdir/users/pd378/oil_international/args_prevelence/custom_card_search/rgi_analysis #working directory
#$ -pe parenv 1
#$ -l h_vmem=25G
#$ -t 75001-112500
#$ -q long.q@cbsubrito.tc.cornell.edu


WRK=/workdir/users/pd378/oil_international/args_prevelence/custom_card_search/rgi_analysis
REF=$WRK/22-2-11_card_reference_db/card.json
FILE_LIST=/home/britolab/refdbs/genbank_bacterial_genomes_22-2-11/file_lists/ordered_diff_2.txt 
INPUT=/home/britolab/refdbs/genbank_bacterial_genomes_22-2-11/genbank_genomes
OUTPUT=$WRK/temp_rgi_output

source /home/acv46/miniconda3/bin/activate
conda activate rgi5.2.0
# load the database only needs to be done once
#rgi load --card_json $REF --local


##Make the design file
    DESIGN=$(sed -n "${SGE_TASK_ID}p" $FILE_LIST)
    NAME=`basename "$DESIGN"`
    
#initialize file names
in_file=$INPUT/${NAME}
out_file=$OUTPUT/${NAME}

#run RGI
rgi main --input_sequence $in_file --output_file $out_file --input_type contig --local --clean \
        --alignment_tool DIAMOND --num_threads 5 --split_prodigal_jobs --include_loose 
        
echo $NAME complete