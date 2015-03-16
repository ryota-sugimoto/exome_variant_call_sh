#!/usr/bin/env bash

[ $# == 3 ] || { echo "$0 <fastq_1> <fastq_2> <out_dir>"; exit 1; }
[ -f ${1} ] || { echo ${1} not found; exit 1; }
[ -f ${2} ] || { echo ${2} not found; exit 1; }
[ -d ${3} ] || { echo ${3} not found; exit 1; }

function file_abs_path() {
  [ -f ${1} ] \
    && { echo $(cd $(dirname ${1}); pwd)/$(basename ${1}); }
}

fastq_1=$(file_abs_path ${1})
fastq_2=$(file_abs_path ${2})
out_dir=$(cd ${3}; pwd)

ref_fasta="/home/ryota/workspace/ref/ucsc.hg19.fasta"
script_dir="/home/ryota/workspace/shizuoka_kodomo/scripts"

#mappping deduppping
map_dedup=(${script_dir}/map_dedup.sh 
           ${fastq_1}
           ${fastq_2}
           ${ref_fasta}
           ${out_dir})
${map_dedup[@]} || exit 1

#indel realign
dedup_bam=${out_dir}/$(basename ${fastq_1}).dedup.bam
indel_realign=(${script_dir}/indel_realign.sh
               ${dedup_bam})
${indel_realign[@]} || exit 1

#base recalibration
realigned_bam=${dedup_bam%bam}realigned.bam
base_recal=(${script_dir}/base_recal.sh
            ${realigned_bam})
${base_recal[@]} || exit 1

#rm ${out_dir}/$(basename ${fastq_1}.metric.txt)
#rm ${realigned_bam%bam}recal_data.table
#rm ${dedup_bam%bam}target_intervals.list 
rm ${dedup_bam} ${dedup_bam%m}i ${realigned_bam} ${realigned_bam%m}i
