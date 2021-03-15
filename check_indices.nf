#!/usr/bin/env nextflow


/*
================================================================================
                          Check Index flags
================================================================================
*/


// Check Fasta fai 
if(params.fasta_fai && !params.fasta_fai.endsWith(".fai")){
  exit 1, "[nf-core/circrna] error: Fasta index file provided (${params.fasta_fai}) is not valid, Fasta index files should have the extension '.fai'."
}

// Check BWA index

if(params.bwa_index){
  
  bwa_path_files = params.bwa_index + "/*"
  Channel
	.fromPath(bwa_path_files, checkIfExists: true)
	.flatten()
	.map{ it ->
	
	if(!has_extension(it, ".ann") && !has_extension(it, ".amb") && !has_extension(it, ".bwt") && !has_extension(it, ".pac") && !has_extension(it, ".sa")){
	exit 1, "[nf-core/circrna] error: BWA index file ($it) has an incorrect extension. Are you sure they are BWA indices?"
		}
	}
}

// Check Bowtie index

if(params.bowtie_index){
  
  bowtie_path_files = params.bowtie_index + "/*"
  
  Channel
	.fromPath(bowtie_path_files, checkIfExists: true)
	.flatten().view()
	.map{ it ->
	
	if(!has_extension(it, ".ebwt")){
	exit 1, "[nf-core/circrna] error: Bowtie index file ($it) has an incorrect extension. Are you sure they are Bowtie(1) indices?"
		}
	}
}

// Check Bowtie 2 index

if(params.bowtie2_index){
  bowtie2_path_files = params.bowtie2_index + "/*"

  Channel
	.fromPath(bowtie2_path_files, checkIfExists: true)
	.flatten()
	.map{ it ->
	
	if(!has_extension(it, ".bt2")){
	exit 1, "[nf-core/circrna] error: Bowtie 2 index file ($it) has an incorrect extension. Are you sure they are Bowtie 2 indices?"
		}
	}
}


// Check HISAT2 index

if(params.hisat2_index){

  hisat2_path_files = params.hisat2_index + "/*"

  Channel
	.fromPath(hisat2_path_files, checkIfExists: true)
	.flatten()
	.map{ it ->

	if(!has_extension(it, ".ht2")){
	exit 1, "[nf-core/circrna] error: HISAT2 index file ($it) has an incorrect extension. Are you sure they are HISAT2 indices?"
		}
	}
}

// Check STAR index

if(params.star_index){

  starList = defineStarFiles()

  star_path_files = params.star_index + "/*"

  Channel
	.fromPath(star_path_files, checkIfExists: true)
	.flatten()
	.map{ it -> it.getName()}
	.collect()
	.flatten()
  	.map{ it -> 
	
	if(!starList.contains(it)){
	exit 1, "[nf-core/circrna] error: Incorrect index file ($it) is in the STAR directory provided.\n\nPlease check your STAR indices are valid:\n$starList."
		} 
	}
}
	

/*
================================================================================
                         Functions
================================================================================
*/

// Check file extension
def has_extension(it, extension) {
    it.toString().toLowerCase().endsWith(extension.toLowerCase())
}

// Define STAR index files
def defineStarFiles() {
    return [
    'chrLength.txt',
    'chrNameLength.txt',
    'chrName.txt',
    'chrStart.txt',
    'exonGeTrInfo.tab',
    'exonInfo.tab',
    'geneInfo.tab',
    'Genome',
    'genomeParameters.txt',
    'Log.out',
    'SA',
    'SAindex',
    'sjdbInfo.txt',
    'sjdbList.fromGTF.out.tab',
    'sjdbList.out.tab',
    'transcriptInfo.tab'
    ]
}


