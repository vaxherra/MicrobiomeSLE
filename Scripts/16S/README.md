# 16S rRNA Metagenomics Pipeline (v.1.0)
## I. Overview

This analysis pipeline is dedicated to the analysis of 16S datasets generated on Illumina machines, due to [unoise2](http://drive5.com/usearch/manual/cmd_unoise2.html) algorithm used.

This pipeline is intended as an SOP (Standard Operating Procedure) for analysis of 16S datasets produced on Illumina machines for the purpose of reproducibility.

Scripts are provided in .pbs format, which stands for Portable Batch System, and is just a text file that could easily be opened by any text editor. The .pbs format is used in queuing systems on computing clusters. 

## II. Software requirements
Below is a list of software packages required to run this pipeline. Beware that for example qiime is a software package comprised of many software dependencies. You would have to check what other software dependencies are required when installing a particular package. For more information follow the links provided below.

1. [Usearch v.9.2+](http://drive5.com/usearch/) 
2. [Qiime 1.9.1](http://qiime.org/install/install.html)
3. [GreenGeenes databases]()
	- [13_8](ftp://greengenes.microbio.me/greengenes_release/gg_13_5/gg_13_8_otus.tar.gz)
	- [13_5](ftp://greengenes.microbio.me/greengenes_release/gg_13_5/gg_13_5_otus.tar.gz)
4. [Picrust 1.1.0](http://picrust.github.io/picrust/install.html)


## III. Description
### III.1. Configuration files
#### III.1.1. Pipeline config
##### Script header legend
Each scripts has a header line, that is required when submitting .pbs scripts to a queuing system. Below is the legend describing each option. Scripts already have suggested/optimal parameters set for a particular purpose, so it is probably not necessary for you to change that.

-  '-V' include environment variables from current session (like your PATH, etc)
-  '-cwd' work from the current working directory from which the script was launched,otherwise the node operates from your home directory
-  -'o <filename>' filename to redirect program output to. Everything the program would normally output to standard output goes to this file. Think of this like a log file.
-  '-e <filename>': Filename to write program error output to. Everything the program would normally output to standard error goes to this file. Like a log file of error messages.
-  '-j y':   “Join yes”. Combine output and error messages into the same file specified by the –o option. I usually use this because it creates less clutter – output and error messages go to the same file, and that way I don’t have to define something with the –e option.
-  '-pe threaded <number>': Reserve N=<number> threads for a program that uses parallel processing. By default every job gets 1 thread. Programs that need more than 1 thread have to use this setting.
-  '-l mem_free=<size>G':  Request a node with <size> GB of free RAM . Specify <size> as an integer. By default the amount of allocated memory is very low.
  -  If a submitted job runs out of allocated memory, the node terminates it. It is good to request only the amount of memory you actually need to use – most R scripts will function with 2 or 3 GB RAM.
  -  Some other programs require much more memory. There shouldn’t be a need to set this higher than 60 GB.
##### config.txt
Other parameters like path of the required input filed, produced outputs are stored in one configuration file "config.txt". They are loaded by each of the scripts by 'source' command. The variable names are intended to be self-explanatory, however below is a brief description of most important variables:


- ${BASE_DIR}: a filepath to a base directory, i.e. a place where a folder ${ANALYSIS_NAME} would be created.
- ${WORK_DIR}: a folder name to be creared in ${BASE_DIR} filepath that would store all diversity analysis files, plots and figures [default: downstream].
- ${MAPPING_F_FP}: a mapping file filepath. This file is in standard qiime format (tab-delimited) for mapping, i.e. including metadata for samples used in the study, see more [here](http://qiime.org/scripts/validate_mapping_file.html). An [example mapping file](http://qiime.org/_static/Examples/File_Formats/Example_Mapping_File.txt)
- ${MERGE_DIR}: folder created in ${BASE_DIR} containing merged reads for each sample (read-pairs)
- ${FASTQ_DIR}: folder created in ${BASE_DIR} containing read-pair files for each sample, after stripping Illumina Adapters,
- ${CONT_DIR}: a folder created in ${MERGE_DIR} contaning merged reads for each contaminating sample
- ${SEQUENCE_DIR}: a folder created in ${BASE_DIR} containing concatenated sequences for all sample in the study, and a separate file for contaminating sequences in the study.
- ${MAPPING_METADATA}= is the field of mapping file that would discern between groups, i.e. having column 'Status' that has labels "Control" or "Diseased" would later take into account this parameter
- ${PE_THREADED}: when working on multiple-core system, set this value to the number of threads that could be used when performing parallelizable tasks, like OTU picking [Default 12],
- ${SINTAX_CUTOFF} - is a condifence threshold when predicting taxonomy, algorithm keeps only ranks with higher confidence. While using SINTAX on V4 reads, using a cutoff of 0.8 gives predictions with similar accuracy to RDP at 80% bootstrap cutoff [default 0.8],

Most of other folders are set-up automatically so as to create aliases for folder/file-paths. They don't have to be set up manually.
##### Aliases
Each program used in scripts has its aliases, a shortened name used to invoke a sortware. It is advised to:
- rename file (ex. "USEARCHv9.2.32 usearch92")
- add execution privileges to a file (ex. "chmod +x usearch92")
- export filepath where a particular software resides. Edit .bash_profile and add a new line: PATH="/home/user/metagenomic_soft:${PATH}"

** Aliases used **:

- usearch92
- qiime/1.9.1 (when applying module load qiime/1.9.1)
- bbmap
- trimmomatic
#### III.1.2. QIIME parameters
There are generally two types of QIIME config files, that are created automatically during the script. One applies for diversity and abundance analysis, while the other is created for PICRUSt pursposes. It is mainly done for the fact that PICRUSt works only with 13_5 GreenGenes database, while diversity analysis uses newer (13_8) version. PICRUSt configuration file is then duplicated during the script, as summarizing KEGG Pathways for different levels requires two different configuration files (KEGG Pathway lvl 2 and 3).

#### III.1.3. QIIME config

QIIME config file is produces during execution of "setup.sh". It creates a file "qiime_config.txt" in ${BASE_DIR} - user specified filepath. It later has to be copied manually to homepath, removing .txt extension, and adding a dot '.' beofre its name:

cp ${BASE_DIR}/qiime_config.txt ~/.qiime_config



### III.2. Preprocessing - ""

Preprocessing step downloads file from the container system "on the run", i.e. without storing them in a particular location, then trims Illumina Adapters used in sequencing, and stores them in an analysis folder "01_fastq". Then it merges readpairs and stores them in "02_merged_fastq" analysis folder. 

Preprocessing step has two scripts, as sample sequences and contaminating sequences (i.e. DNA extraction blanks or PCR controls) are processed differently in further steps of downstream analysis.



#### Before preprocessing
After running ./setup.sh the script will create an analysis folder, where a "mapping" subfolder has a copy of mapping file (mapping.txt) and a script "preprocessing_from_mapping.py" that would help to produce a list of jobs to submit. 

This python scripts creates another .pbs script that submitted, submits itself preprocessing .pbs scripts. Each job submission is responsible for one sample file.

This python script is flexible as to allow for manually specifying name of the mapping file, and .pbs script filename. For contaminants you would have to prepare additional mapping file, and later use "Metagenomics_16s_preprocessing_contaminants.pbs". It just has different output filepath ("${BASE_DIR}/02_merged_fastq/contaminants").

#### Running preprocessing
One could submit a job generated by python script "preprocessing_from_mapping.py", or copy each line from generated file. This script exists just for convenience, as having 100 samples would mean manually submitting each job with unique ID. 



### III.3. Abundance and diversity analysis - ""
Works with GreenGenes 13_8 database.

### III.4. Picrust metagenome predictions
Works with GreenGenes 13_5 database (Picrust requirement).


## IV. Running Code

1. Configurate config.txt
- mapping
- analysis name

2. Run setup.sh
	chmod +x .setup.sh
0. QIIME config - copy from base to home folder 
 cp ${BASE_DIR}/qiime config.txt ~/.qiime_config	
3. Generate submission file for preprocessing - preprocessing_from_mapping.py
	a. for sample sequences
	b. for contaminating sequences (preparing a contaminate mapping file may be necessary)
4. Run preprocessing.pbs / preprocessing_contaminants.pbs
5. Concatenate - concatenate.pbs
6. Decontaminate -  decontaminate
7. Run diversity analysis.pbs
8. Run picrust analysis

5.,6. could be run independently.
## V. References

