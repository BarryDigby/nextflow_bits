#!/usr/bin/env nextflow

/*
  Make a few text files in your directory. 
  We are going to split them into 2 files
  mimicking bam to fastq behaviour. 
*/

params.file = "/home/barry/nf_test/*.txt"
filee = file(params.file)

// The config file is for CIRIquant

params.config = "config.yml"
Channel 
	.fromPath(params.config)
	.set{ config_file }

/*
  The key here is to explicitly state the outputs
  [ key, read1, read2]
  It does NOT behave like fromFilePairs
  [key {read1, read2}]
*/

process one{
	publishDir "~/", mode:'copy'

	input:
	file f from filee

	output:
	set key, file("${f.baseName}1.txt"), file("${f.baseName}2.txt") into out_ch
	
	script:
        key = f.baseName
	"""
	head \"${f}" -c 20 > "${f.baseName}"1.txt
	head \"${f}" -c50 > "${f.baseName}"2.txt
	"""
}

/*
  Set key x, y is now equivalent to 
  [key, x, y] from out_ch
*/

process two{
	publishDir "~/", mode:'copy'
	echo true

	input:
	set key, x, y, config from out_ch.combine(config_file)

	script:
	"""
	echo "key value =" ${key}
	echo "x value =" ${x}
	echo "y value= =" ${y}
	echo "config =" ${config}
	"""
}

