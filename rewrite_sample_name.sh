#!/usr/bin/env bash

[ $# == 2 ] || { echo "${0} <sample_name> <bam>"; exit 1; }
[ -f ${2} ] || { echo "${1} not found"; exit 1; }

function file_abs_path() {
  [ -f ${1} ] \
    && { echo $(cd $(dirname ${1}); pwd)/$(basename ${1}); }
}

picard_jar="/home/ryota/workspace/picard/picard-tools-1.128/picard.jar"
bam=$(file_abs_path ${2})

sample_name=${1}

#rewrite header
header=${bam%bam}header.sam
samtools view -H ${bam} | sed "/^@RG/{s/SM:..*/SM:${sample_name}/}" > ${header} || exit 1

new_bam=${bam%bam}rewrite.bam
rewrite_header=(java -jar ${picard_jar}
                ReplaceSamHeader
                INPUT=${bam}
                OUTPUT=${new_bam}
                HEADER=${header}
                CREATE_INDEX=true)
${rewrite_header[@]} || exit 1

rm ${header}
