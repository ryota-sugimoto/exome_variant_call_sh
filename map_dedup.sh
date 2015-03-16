#!/usr/bin/env bash
[ $# == 4 ] || { echo "$0 <fastq_1> <fastq_2> <ref_fasta> <out_dir>"; exit 1; }
[ -f ${1} ] || { echo ${1} not found; exit 1; }
[ -f ${2} ] || { echo ${2} not found; exit 1; }
[ -f ${3} ] || { echo ${3} not found; exit 1; }
[ -d ${4} ] || { echo ${4} not found; exit 1; }

function file_abs_path() {
  [ -f ${1} ] \
    && { echo $(cd $(dirname ${1}); pwd)/$(basename ${1}); }
}

picard_jar="/home/ryota/workspace/picard/picard-tools-1.128/picard.jar"

fastq_1=$(file_abs_path ${1})
fastq_2=$(file_abs_path ${2})
ref_fasta=$(file_abs_path ${3})
out_dir=$(cd ${4}; pwd)

[ -f ${ref_fasta} ] \
  || { echo "reference fasta ${ref_fasta} not found."; exit 1; }

#bwa mem
sam=${out_dir}/$(basename ${fastq_1}.sam)
command_bwa=(bwa mem -M
             -R "@RG\tID:map_dedup\tPL:Illumina\tSM:${fastq_1}_${fastq_2}"
             ${ref_fasta}
             ${fastq_1}
             ${fastq_2})
${command_bwa[@]} > ${sam} || exit 1
echo

#sort
bam=${sam%sam}bam
command_sort=(java -jar ${picard_jar} SortSam
              INPUT=${sam}
              OUTPUT=${bam}
              SORT_ORDER=coordinate
              CREATE_INDEX=true
              VALIDATION_STRINGENCY=SILENT)
${command_sort[@]} || exit 1
echo

#mark_duplicate
dedup_bam=${bam%bam}dedup.bam
metric=${sam%sam}metric.txt
command_dedup=(java -jar ${picard_jar} MarkDuplicates
               INPUT=${bam}
               OUTPUT=${dedup_bam}
               CREATE_INDEX=true
               METRICS_FILE=${metric})
${command_dedup[@]} || exit 1

rm ${sam} ${bam} ${bam%bam}bai
