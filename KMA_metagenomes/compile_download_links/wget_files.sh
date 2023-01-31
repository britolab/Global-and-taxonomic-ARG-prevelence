#!/bin/sh

# this is just going to pull out the needed FTP links for downloading all the metagenomes in a format that I can futher parse in python

echo -e "study_name\tsample_id\tNCBI_accession\tftp_urls" > all_urls.txt

while read STUDY SAMPLE ACCESSSION; do
 
   FTPs=$(wget -qO- "https://www.ebi.ac.uk/ena/portal/api/filereport?accession=${ACCESSSION}&result=read_run&fields=fastq_ftp" | awk '(NR>1)' | awk '{print $2}')

   echo -e "${STUDY}\t${SAMPLE}\t${ACCESSSION}\t${FTPs}" >> all_urls.txt 

done <full_accessions_list.txt