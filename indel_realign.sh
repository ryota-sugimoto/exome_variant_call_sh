#!/usr/bin/env bash

[ $# == 1 ] || {  echo "$0 <bam>"; exit 1; }
[ -f ${1} ] || { echo ${1} not found; exit 1; }

function file_abs_path() {
  [ -f ${1} ] \
    && { echo $(cd $(dirname ${1}); pwd)/$(basename ${1}); }
}

gatk_jar="/home/ryota/workspace/gatk/gatk-3.3-0/GenomeAnalysisTK.jar"
ref_fasta="/home/ryota/workspace/ref/ucsc.hg19.fasta"
known_sites=(/home/ryota/workspace/ref/1000G_phase1.indels.hg19.sites.vcf
             /home/ryota/workspace/ref/Mills_and_1000G_gold_standard.indels.hg19.sites.vcf)

bam=$(file_abs_path ${1})

#target
target_intervals=${bam%bam}target_intervals.list
realign_target_creater=(java -jar ${gatk_jar}
                        -T RealignerTargetCreator
                        -R ${ref_fasta}
                        -I ${bam}
                        `for vcf in ${known_sites[@]}; 
                         do
                           echo -known ${vcf};
                         done`
                        -o ${target_intervals})
${realign_target_creater[@]} || exit 1

#realign
realigned_bam=${bam%bam}realigned.bam
indel_realign=(java -jar ${gatk_jar}
               -T IndelRealigner
               -R ${ref_fasta}
               -I ${bam}
               -targetIntervals ${target_intervals}
               `for vcf in ${known_sites[@]};
                do
                  echo -known ${vcf};
                done`
               -o ${realigned_bam})
${indel_realign[@]} || exit 1
