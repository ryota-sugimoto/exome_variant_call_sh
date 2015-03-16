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
             /home/ryota/workspace/ref/Mills_and_1000G_gold_standard.indels.hg19.sites.vcf
             /home/ryota/workspace/ref/dbsnp_138.hg19.vcf)

bam=$(file_abs_path ${1})

#recal1
recal_table=${bam%bam}recal_data.table
recal1=(java -jar ${gatk_jar}
        -T BaseRecalibrator
        -R ${ref_fasta}
        -I ${bam}
        `for vcf in ${known_sites[@]};
         do
           echo -knownSites ${vcf};
         done`
         -o ${recal_table})
${recal1[@]} || exit 1

#recal2
post_recal_table=${bam%bam}post_recal_data.table
recal2=(java -jar ${gatk_jar}
        -T BaseRecalibrator
        -R ${ref_fasta}
        -I ${bam}
        `for vcf in ${known_sites[@]};
         do
           echo -knownSites ${vcf};
         done`
         -BQSR ${recal_table}
         -o ${post_recal_table})
#${recal2[@]} || exit 1

#plot
plot_pdf=${bam%bam}recal_plots.pdf
plot=(java -jar ${gatk_jar}
      -T AnalyzeCovariates
      -R ${ref_fasta}
      -before ${recal_table}
      -after ${post_recal_table}
      -plots ${plot_pdf})
#${plot[@]} || exit 1

#print reads
recal_bam=${bam%bam}recal.bam
print_reads=(java -jar ${gatk_jar}
            -T PrintReads
            -R ${ref_fasta}
            -I ${bam}
            -BQSR ${recal_table}
            -o ${recal_bam})
${print_reads[@]} || exit 1
