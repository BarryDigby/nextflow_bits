#!/usr/bin/env nextflow 

// testing logical processes for nf-circ and
// testing multiple containers per script. 
// applicaple to MA5112 week 1 if they are interested

params.input = null 
params.input_type = null 
params.input_glob = null
params.outdir = null
params.timming = null
params.adapters = null


// CONFIG FILE DURING DEV:

/*
process {
beforeScript = 'module load singularity'
container = 'file:///data/bdigby/grch38/work/singularity/barryd237-circrna.img'
containerOptions = '-B /data/'
executor='slurm'
queue='MSC'
clusterOptions = '-n 1 -N 1'
withLabel: 'multiqc' {
	 container = 'barryd237/week1:test'
	}
}

singularity.enabled = true
singularity.autoMounts = true

singularity {
	cacheDir = '/data/MSc/2020/MA5112/container_cache'
}
*/


// CALL:
/*
nextflow -bg -q run QC_dev_barry.nf --outdir "./" \
--input "raw_data/" --input_glob "*_r{1,2}.fastq.gz" \
--input_type "fastq" --adapters "/data/MSc/2020/MA5112/week_1/assets/adapters.fa" \
--trimming "true"
/*


// STAGE INPUTS. 
// Accept BAM or FASTQ

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
            file ("*.{html,zip}") into fastqc_trimmed

        script:
        """
        fastqc -q $fastq
        """
        }

	process multiqc_trim {
	
	publishDir "$params.outdir/MultiQC/Trimmed", mode:'copy'

	label 'multiqc'

	input:
	file(htmls) from fastqc_trimmed.collect()

	output:
	file("Trimmed_Reads_MultiQC.html") into multiqc_trim_out

	script:
	"""
	multiqc -i "Trimmed_Reads_MultiQC" -b "nf-circ pipeline" -n "Trimmed_Reads_MultiQC.html" .
	"""
	}

}else if(params.trimming == false){
        aligner_reads = raw_reads
}


// Stage Alignment Reads (trivial naming)
(bwa_reads, STAR_reads, hisat2_reads) = aligner_reads.into(3)


// Lets view the reads. If no trim, has fastq.gz ext. If trimmed, has fq.gz ext. 
bwa_reads.view()


// MultiQC of the Raw Data, Mandatory.


process multiqc_raw {
	
	publishDir "$params.outdir/MultiQC/Raw", mode:'copy'

	label 'multiqc'

	input:
	file(htmls) from fastqc_raw.collect()

	output:
	file("Raw_Reads_MultiQC.html") into multiqc_raw_out

	script:
	"""
	multiqc -i "Raw_Reads_MultiQC" -b "nf-circ pipeline" -n "Raw_Reads_MultiQC.html" .
	"""
}
