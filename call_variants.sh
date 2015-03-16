#!/usr/bin/env bash
[ $# -gt 2 ] || { echo "${0} <sample_name> <out_dir> <bam> (<bam>..)"; exit 1; } 
[ -d ${2} ] || { echo ${2} not exist; exit 1; }

function file_abs_path() {
  [ -f ${1} ] \
    && { echo $(cd $(dirname ${1}); pwd)/$(basename ${1}); }
}

sample_name=${1}
out_dir=$(cd ${2}; pwd)
shift 2

bams=()
for f in ${@}
do
  [ -f ${f} ] || { echo ${f} not found; exit 1; }
  bams+=($(file_abs_path ${f}))
done

gatk_jar="/home/ryota/workspace/gatk/gatk-3.3-0/GenomeAnalysisTK.jar"
ref_fasta="/home/ryota/workspace/ref/ucsc.hg19.fasta"
db_snp="/home/ryota/workspace/ref/dbsnp_138.hg19.vcf"

#call variants
gvcf=${out_dir}/${sample_name}.g.vcf
call_variants=(java -jar ${gatk_jar}
               -T HaplotypeCaller
               -R ${ref_fasta}
               $(for bam in ${bams[@]}; do echo "-I ${bam}"; done)
               --dbsnp ${db_snp}
               --sample_name ${sample_name}
               --emitRefConfidence GVCF
               --variant_index_type LINEAR
               --variant_index_parameter 128000
               -o ${gvcf})
${call_variants[@]} || exit 1
