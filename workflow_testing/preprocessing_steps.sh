#!/bin/bash
set -e

## check whether user had supplied -h or --help. If yes display help 

	if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
		echo "
		This script takes an input directory and attempts to process
		contents through a qiime workflow.  The plan is for some
		standard 				

		Output will be 2 files, an index file (idx.fq) and a read
		file (rd.fq).

		Usage (order is important!!):
		Qiime_workflow.sh <input folder> <mode>

		Example:
		Qiime_workflow.sh ./ 16S

		This example will attempt to process data residing in the
		current directory through a complete qiime workflow.  If
		certain conventions are met, the workflow will skip all
		steps that have already been processed.  It will try to
		guess why some step failed and give you feedback if/when
		it crashes.

		Order of processing attempts:
		1) Checks for <input folder>/split_libraries/seqs.fna.  
		If present, moves forward to chimera filter or OTU picking.
		If absent, checks for joined fastq files (as idx.fq and 
		rd.fq).  Requires a mapping file be present (map*).
		2) If joined fastqs absent, looks for raw fastq files
		(as index1*fastq, index2*fastq, read1*fastq, read2*fastq).
		Requires a mapping file to be present (map*) and a primers
		file to be present (primers*).

		Mapping files are formatted for QIIME.  Index sequences
		contained therein must be in the CORRECT orientation.

		Primers file must be in fasta format.  Degenerate primers
		must be expressed as individual sequences as degenerate
		code is not correctly parsed.  All primer sequences must 
		be REVERSE COMPLEMENTED.

		Parameters for the steps starting at OTU picking can be
		modified by placing a qiime-formatted parameters file in
		your working directory.  The parameters file must begin
		with \"parameters\".  More than one such file in your
		working directory will cause the workflow to exit.

		Example parameters file contents (parameters_fast.txt):
		pick_otus:max_accepts	1
		pick_otus:max_rejects	8

		Requires the following dependencies to run all steps:
		1) QIIME 1.8.0 or later (qiime.org)
		2) ea-utils (https://code.google.com/p/ea-utils/)
		3) Fastx toolkit (http://hannonlab.cshl.edu/fastx_toolkit/)
		4) NGSutils (http://ngsutils.org/)
		5) Fasta-splitter.pl (http://kirill-kryukov.com/study/tools/fasta-splitter/)
		6) ITSx (http://microbiology.se/software/itsx/)
		7) Smalt (https://www.sanger.ac.uk/resources/software/smalt/)
		8) HMMer v3+ (http://hmmer.janelia.org/)
		
		Citations: 
QIIME: 
Caporaso, J., Kuczynski, J., & Stombaugh, J. (2010). QIIME allows analysis of high-throughput community sequencing data. Nature Methods, 7(5), 335–336.

ea-utils:
etc etc for now...
		"
		exit 0
	fi 

## If less than two arguments supplied, display usage 

	if [  "$#" -le 1 ]; then 

		echo "
		Usage (order is important!!):
		Qiime_workflow.sh <input folder> <mode>
		"
		exit 1
	fi

## Check that valid mode was entered

	if [[ $2 != ITS && $2 != 16S ]]; then
		echo "
		Invalid mode entered (you entered $2).
		Valid modes are 16S or ITS.

		Usage (order is important!!):
		Qiime_workflow.sh <input folder> <mode>
		"
		exit 1
	fi

	mode=($2)

## Check that no more than one parameter file is present

	parameter_count=(`ls parameter* | wc -w`)

	if [[ $parameter_count -ge 2 ]]; then

		echo "
		No more than one parameter file can reside in your working
		directory.  Presently, there are $parameter_count such files.  
		Move or rename all but one of these files and restart the
		workflow.  A parameter file is any file in your working
		directory that starts with \"parameter\".  See --help for
		more details.
		
		Exiting...
		"
		
		exit 1
	else
	param_file=(`ls parameter*`)
	fi

## Check that no more than one mapping file is present

	map_count=(`ls map* | wc -w`)

	if [[ $map_count -ge 2 && $map_count -ne 0 ]]; then

		echo "
		This workflow requires a mapping file.  No more than one 
		mapping file can reside in your working directory.  Presently,
		there are $map_count such files.  Move or rename all but one 
		of these files and restart the workflow.  A mapping file is 
		any file in your working directory that starts with \"map\".
		It should be properly formatted for QIIME processing.
		
		Exiting...
		"
		
		exit 1
	else
	map=(`ls map*`)	
	fi

## Check for required dependencies:
## command -v foo >/dev/null 2>&1 || { echo >&2 "I require foo but it's not installed.  Aborting."; exit 1; }
## 
## hash print_qiime_config.py 2>/dev/null || { echo >&2 "I require foo but it's not installed.  Aborting."; }
##
## QIIME version
#	`print_qiime_config.py | grep "QIIME library version" | cut -f 2 | read qiime_version`
#echo $qiime_version
#exit 0
## Smalt version
##smalt version | grep "Version"=smalt_version
##echo $smaltversion
##exit 0
##
## test dependency check
#if [[ `smal version` 2>/dev/null | grep "command not found" == "smal: command not found" ]]; then; echo "smal is not installed"; else "smal is in order"; fi
##
##
##

## Define working directory, log file, mapping file, and read in variables from config file
	workdir=$(pwd)
	outdir=($1)
	config=($workdir/qiime_workflow*.config)

	if [[ $mode == "16S" ]]; then
	refs=(`grep "16S_reference" $config | grep -v "#" | cut -f 2`)
	tax=(`grep "16S_taxonomy" $config | grep -v "#" | cut -f 2`)
	tree=(`grep "16S_tree" $config | grep -v "#" | cut -f 2`)
	chimera_refs=(`grep "16S_chimeras" $config | grep -v "#" | cut -f 2`)
	seqs=($outdir/split_libraries/seqs_chimera_filtered.fna)
	alignment_template=(`grep "16S_alignment_template" $config | grep -v "#" | cut -f 2`)
	alignment_lanemask=(`grep "16S_alignment_lanemask" $config | grep -v "#" | cut -f 2`)

	elif [[ $mode == "ITS" ]]; then
	refs=(`grep "ITS_reference" $config | grep -v "#" | cut -f 2`)
	tax=(`grep "ITS_taxonomy" $config | grep -v "#" | cut -f 2`)
	chimera_refs=(`grep "ITS_chimeras" $config | grep -v "#" | cut -f 2`)
	seqs=($outdir/split_libraries/seqs.fna)
	fi

	slqual=(`grep "Split_libraries_qvalue" $config | grep -v "#" | cut -f 2`)
	chimera_threads=(`grep "Threads_chimera_filter" $config | grep -v "#" | cut -f 2`)
	otupicking_threads=(`grep "Threads_pick_otus" $config | grep -v "#" | cut -f 2`)
	taxassignment_threads=(`grep "Threads_assign_taxonomy" $config | grep -v "#" | cut -f 2`)
	alignseqs_threads=(`grep "Threads_align_seqs" $config | grep -v "#" | cut -f 2`)
	min_overlap=(`grep "Min_overlap" $config | grep -v "#" | cut -f 2`)
	max_mismatch=(`grep "Max_mismatch" $config | grep -v "#" | cut -f 2`)
	mcf_threads=(`grep "Threads_mcf" $config | grep -v "#" | cut -f 2`)
	phix_index=(`grep "PhiX_index" $config | grep -v "#" | cut -f 2`)
	smalt_threads=(`grep "Threads_smalt" $config | grep -v "#" | cut -f 2`)
	multx_errors=(`grep "Multx_errors" $config | grep -v "#" | cut -f 2`)
	

## Check if output directory already exists

	if [[ -d $outdir ]]; then
		echo "
		Output directory already exists ($outdir).

		Checking for prior workflow progress...
		"
		if [[ -f $outdir/qiime_workflow.log ]]; then
			log=($outdir/qiime_workflow.log)
			echo "
---

qiime_workflow_script restarting in $mode mode" >> $log
			date >> $log
			echo "
---
			" >> $log
		fi
	else
		echo "
		Beginning qiime_workflow_script in $mode mode
		"
		mkdir $outdir
		touch $outdir/qiime_workflow.log
		log=($outdir/qiime_workflow.log)
		echo "qiime_workflow_script beginning in $mode mode" >> $log
		date >> $log
		echo "
---
		" >> $log
	fi

## Check for split_libraries outputs and inputs

	if [[ -f $outdir/split_libraries/seqs.fna ]]; then
	echo "		Split libraries output detected. 
		($outdir/split_libraries/seqs.fna)
		Skipping split_libraries_fastq.py step,
	"
	else

	echo "		Split libraries needs to be completed.
		Checking for fastq files.
	"

		if [[ ! -f idx.fq || ! -f rd.fq ]]; then
		echo "		Joined fastqs not present or not all present.
		(Looked for idx.fq and rd.fq).

		Checking for raw fastq files instead.
		"

		fastq_count=(`ls *fastq | wc -w`)

		if [[ $fastq_count -ge 3 ]]; then
		index_count=(`ls index*fastq | wc -w`)
		read_count=(`ls read*fastq | wc -w`)
		fi

		if [[ $read_count != 2 ]]; then
		echo "		More or less than 2 read files (raw fastq) are
		present.  Check your input files and try again.

		Exiting workflow.
		"
		exit 1
		fi
		

		if [[ $index_count -eq 1 ]]; then
		index1=(`ls index1*fastq`)
		index1length=$((`sed '2q;d' $index1 | egrep "\w+" | wc -m`-1))

		elif [[ $index_count -eq 2 ]]; then
		index1=(`ls index1*fastq`)
		index2=(`ls index2*fastq`)
		index1length=$((`sed '2q;d' $index1 | egrep "\w+" | wc -m`-1))
		index2length=$((`sed '2q;d' $index2 | egrep "\w+" | wc -m`-1))
		indexlength=$(($index1+$index2))

		fi

		read1=(`ls read1*fastq`)
		read2=(`ls read2*fastq`)
		primers_count=(`ls primers* 2>/dev/null | wc -w`)

		if [[ $primers_count -ne 1 ]]; then
		echo " 		Either your primers file is missing or you have
		too many files in your working directory that
		start with primers*.  See --help for more details.
		"
		exit 1
		else primers=(`ls primers*`)
		fi

		if [[ $index_count -eq 2 ]]; then
		echo "		Starting dual indexed joining workflow with
		PhiX screen.
		"
		joinmode=dual
		echo "		Stripping out any primer sequences with fastq-mcf."
		


		if [[ $min_overlap -eq 0 && $max_mismatch -eq 0 ]]; then
		`Dual_indexed_fqjoin_workflow.sh $index1 $index2 $read1 $read2 $indexlength`
		fi
		if [[ $min_overlap -eq 0 && $max_mismatch -ne 0 ]]; then
		`Dual_indexed_fqjoin_workflow.sh $index1 $index2 $read1 $read2 $indexlength -m $min_overlap`
		fi
		if [[ $min_overlap -ne 0 && $max_mismatch -eq 0 ]]; then
		`Dual_indexed_fqjoin_workflow.sh $index1 $index2 $read1 $read2 $indexlength -p $max_mismatch`
		fi
		if [[ $min_overlap -ne 0 && $max_mismatch -ne 0 ]]; then
		`Dual_indexed_fqjoin_workflow.sh $index1 $index2 $read1 $read2 $indexlength -m $min_overlap -p $max_mismatch`
		fi		

		elif [[ $index_count -eq 1 ]]; then
		echo "		Starting single indexed joining workflow with
		PhiX screen.
		"
		joinmode=single
		echo "		Stripping out any primer sequences with fastq-mcf."

		strip_primers_parallel.sh $read1 $read2 $primers $mcf_threads

		if [[ ! -f barcodes.multx.fil ]]; then
		cat $map | cut -f 1-2 | grep -v "#" > barcodes.multx.fil
		fi
		barcodes=barcodes.multx.fil

		PhiX_filtering_single_index_CL.sh fastq-mcf_out/read1.mcf.fq fastq-mcf_out/read2.mcf.fq $index1 $index1length $barcodes $multx_errors $phix_index $smalt_threads $min_overlap $max_mismatch

		wait
		fi		
		cp PhiX_screen/idx.filtered.join.fq ./
		mv idx.filtered.join.fq idx.fq
		cp PhiX_screen/rd.filtered.join.fq ./
		mv rd.filtered.join.fq rd.fq

		fi

		if [[ ! -f idx.fq ]]; then
		echo "		Index file not present (./idx.fq).
		Correct this error by renaming your index file as idx.fq
		and ensuring it resides within this directory
		"
		exit 1
		fi

		if [[ ! -f rd.fq ]]; then
		echo "		Sequence read file not present (./rd.fq).
		Correct this error by renaming your read file as rd.fq
		and ensuring it resides within this directory
		"
		exit 1
		fi

	fi
	exit 0

## split_libraries_fastq.py command
	
	if [[ $slqual == "" ]]; then 
	qual=(19)
	else
	qual=($slqual)
	fi
	if [[ `sed '2q;d' idx.fq | egrep "\w+" | wc -m` == 13  ]]; then
	barcodetype=(golay_12)
	else
	barcodetype=$((`sed '2q;d' idx.fq | egrep "\w+" | wc -m`-1))
	fi
	qvalue=$((qual+1))
	echo "		Performing split_libraries.py command (q$qvalue)"
	if [[ $barcodetype == "golay_12" ]]; then
	echo " 		12 base Golay index codes detected..."
	else
	echo "$barcodetype base indexes detected..."
	fi
	echo "Calling split_libraries_fastq.py:
split_libraries_fastq.py -i rd.fq -b idx.fq -m map.txt -o $outdir/split_libraries -q $qual --barcode_type $barcodetype" >> $log
	date >> $log

	`split_libraries_fastq.py -i rd.fq -b idx.fq -m map.txt -o $outdir/split_libraries -q $qual --barcode_type $barcodetype`	
	
	echo "
		Split libraries command completed."

	echo "
Split libraries command completed." >> $log
	date >> $log
	echo "
---
	"		
	fi
	wait

## Check for split libraries success

	if [[ ! -s $outdir/split_libraries/seqs.fna ]]; then
		echo "
		Split libraries step seems to not have identified any samples
		based on the indexing data you supplied.  You should check
		your list of indexes and try again (do they need to be reverse-
		complemented?
		"
		exit 1
	fi
	fi
