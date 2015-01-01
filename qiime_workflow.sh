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
		directory.  Presently, there are $parameter_count such files.  Move or
		rename all but one of these files and restart the
		workflow.  Exiting...
		"
		
		exit 1
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

## Define working directory, log file, and read in variables from config file
	workdir=$(pwd)
	outdir=($1)
	config=($workdir/qiime_workflow.config)

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
	"
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

		if [[ ! -f map.txt ]]; then
		echo "		Mapping file not present (./map.txt).
		Correct this error by renaming your index file as map.txt
		and ensuring it resides within this directory
		"
		exit 1
		fi

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

## Chimera filtering step (for 16S mode only)

	if [[ $mode == "16S" ]]; then

	if [[ ! -f $outdir/split_libraries/seqs_chimera_filtered.fna ]]; then

	echo "		Beginning chimera filtering 
		(Method: usearch61)
		(Reference: $chimera_refs)
"
	echo "Beginning chimera filtering step
		(Method: usearch61)
		(Reference: $chimera_refs)" >> $log
	date >> $log

	echo "
Chimera filtering steps as issued:

identify_chimeric_seqs.py -m usearch61 -i $outdir/split_libraries/seqs.fna -r $chimera_refs -o $outdir/usearch61_chimera_checking

filter_fasta.py -f $outdir/split_libraries/seqs.fna -o $outdir/split_libraries/seqs_chimera_filtered.fna -s $outdir/usearch61_chimera_checking/chimeras.txt -n
" >> $log

	`identify_chimeric_seqs.py -m usearch61 -i $outdir/split_libraries/seqs.fna -r $chimera_refs -o $outdir/usearch61_chimera_checking`
	wait
	`filter_fasta.py -f $outdir/split_libraries/seqs.fna -o $outdir/split_libraries/seqs_chimera_filtered.fna -s $outdir/usearch61_chimera_checking/chimeras.txt -n`
	wait
	echo ""
	else

	echo "		Chimera filtered sequences detected.
		($seqs)
		Skipping chimera checking step.
	"

	fi
	fi

## Check for parameter file in working directory

	if [[ `ls parameter* | wc -w` == 1 ]]; then
		param_file=$(ls parameter*)
	fi

## Check for OTU picking output

## OTU picking command

	if [[ ! -f $outdir/uclust_otu_picking/final_otu_map.txt ]]; then

	if [[ `ls $param_file | wc -w` == 1 ]]; then

	echo "
		Picking open reference OTUs.  Passing in parameters file
		($param_file) to modify default settings
	"
	cat $param_file
	echo "
---

OTU picking command as issued:
pick_open_reference_otus.py -i $seqs -r $refs -o $outdir/uclust_otu_picking --prefilter_percent_id 0.0 -aO $otupicking_threads --suppress_align_and_tree --suppress_taxonomy_assignment -p $param_file
	" >> $log

	`pick_open_reference_otus.py -i $seqs -r $refs -o $outdir/uclust_otu_picking --prefilter_percent_id 0.0 -aO $otupicking_threads --suppress_align_and_tree --suppress_taxonomy_assignment -p $param_file`
	wait
	else

	echo "
---

OTU picking command as issued:
pick_open_reference_otus.py -i $seqs -r $refs -o $outdir/uclust_otu_picking --prefilter_percent_id 0.0 -aO $otupicking_threads --suppress_align_and_tree --suppress_taxonomy_assignment
	" >> $log
`pick_open_reference_otus.py -i $seqs -r $refs -o $outdir/uclust_otu_picking --prefilter_percent_id 0.0 -aO $otupicking_threads --suppress_align_and_tree --suppress_taxonomy_assignment`
	wait
	fi

	else

	echo "		OTU map detected.
		($outdir/uclust_otu_picking/final_otu_map.txt)
		Skipping OTU picking step.
"
	fi

## Pick rep set against raw OTU map

	if [[ ! -f $outdir/uclust_otu_picking/final_rep_set.fna ]]; then

	echo "Pick representative sequences command as issued:
pick_rep_set.py	-i $outdir/uclust_otu_picking/final_otu_map.txt -f $seqs -o $outdir/uclust_otu_picking/final_rep_set.fna
	" >> $log

`pick_rep_set.py -i $outdir/uclust_otu_picking/final_otu_map.txt -f $seqs -o $outdir/uclust_otu_picking/final_rep_set.fna`

	fi

## Check for open reference output directory

	if [[ ! -d $outdir/open_reference_output ]]; then
	mkdir $outdir/open_reference_output
	fi

## Check for rep set and raw OTU map files

	if [[ ! -f $outdir/open_reference_output/final_rep_set.fna ]]; then
	cp $outdir/uclust_otu_picking/final_rep_set.fna $outdir/open_reference_output/
	else
	echo "		Final rep set file already present.  Not copying.
	"
	fi

	if [[ ! -f $outdir/open_reference_output/final_otu_map.txt ]]; then
	cp $outdir/uclust_otu_picking/final_otu_map.txt $outdir/open_reference_output
	else
	echo "		Final OTU map already present.  Not copying.
	"
	fi

## Align sequences

#	if [[ $mode == "16S" ]]; then

#	echo "		Aligning sequences.
#	"
#	`parallel_align_seqs_pynast.py -i $outdir/open_reference_output/final_rep_set.fna -o $outdir/open_reference_output/pynast_aligned_seqs -t $alignment_template -O $alignseqs_threads`

#	fi

## Assign taxonomy (RDP)





