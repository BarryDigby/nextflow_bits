#!/usr/bin/env nextflow 

// testing logical processes for Read processing (circRNA)
// applicaple to MA5112 if they are interested



params.input = null 
params.input_type = null 
params.input_glob = null
params.outdir = null
params.timming = null
params.adapters = null


// run as:

/*
  nextflow -bg -q run QC_dev_barry.nf --outdir "./" --input "raw_data/", \
  --input_glob "*_r{1,2}.fastq.gz" --input_type "fastq" \
  --trimming "false" --adapters "/data/MSc/2020/MA5112/week1/assets/adapters.fa" \
  -with-singularity "container/week1.img"
  
  adapters must be full path
  
*/

// if trimming false, only one fastqc will run on raw, and reads should have fastq.gz ending
// if trimming true, shouls get two fastqc outputs and reads will have fq.gz ext

// Stage input dataset, accepts FQ or BAM

bam_files = params.input + params.input_glob

if(params.input_type == 'bam'){
   ch_bam = Channel.fromPath( bam_files )
                   .map{ file -> [file.baseName, file]}
   process bam_to_fq{

        input:
            tuple val(base), file(bam) from ch_bam

        output:
            tuple val(base), file('*.fastq.gz') into fastq_built

        script:
        """
        picard -Xmx8g \
        SamToFastq \
        I=$bam \
        F=${base}_R1.fastq.gz \
        F2=${base}_R2.fastq.gz \
        VALIDATION_STRINGENCY=LENIENT
        """
      }
}else if(params.input_type == 'fastq'){
         fastq_build = params.input + params.input_glob
         Channel.fromFilePairs( fastq_build )
                .set{ fastq_built }
}

// stage three channels with raw reads
(fastqc_reads, trimming_reads, raw_reads) = fastq_built.into(3)

// FASTQC on raw data. Mandatory.

process FastQC {

          publishDir "$params.outdir/FastQC/Raw", mode:'copy'

          input:
              tuple val(base), file(fastq) from fastqc_reads

          output:
              file("*.{html,zip}") into fastqc_raw

          script:
          """
          fastqc -q $fastq
          """
}

// Set up Trimming logic 

if(params.trimming == true){

        process bbduk {

        publishDir "$params.outdir/trimmed_reads", mode:'copy'

        input:
            tuple val(base), file(fastq) from trimming_reads
            path adapters from params.adapters

        output:
            tuple val(base), file('*.fq.gz') into trim_reads_ch

        script:
        """
        bbduk.sh -Xmx4g \
        in1=${fastq[0]} \
        in2=${fastq[1]} \
        out1=${base}_1.fq.gz \
        out2=${base}_2.fq.gz \
        ref=$adapters \
        minlen=30 \
        ktrim=r \
        k=12 \
        qtrim=r \
        trimq=20
        """
        }

        // trimmed reads into 2 channels
        (fastqc_trim_reads, aligner_reads) = trim_reads_ch.into(2)

        process FastQC_trim {

        publishDir "$params.outdir/FastQC/Trimmed", mode:'copy'

        input:
            tuple val(base), file(fastq) from fastqc_trim_reads

        output:
            file ("*.{html,zip}") into FastQC_trimmed

        script:
        """
        fastqc -q $fastq
        """
        }

}else if(params.trimming == false){
        aligner_reads = raw_reads
}


// Stage Aligner read channels
(circexplorer2_reads, find_circ_reads, ciriquant_reads, mapsplice_reads, uroborus_reads, circrna_finder_reads, dcc_reads, dcc_reads_mate1, dcc_reads_mate2, hisat2_reads) = aligner_reads.into(10)

dcc_reads.view()
