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

1. Edit config.txt file, changing at least
- ${BASE_DIR} - choose location for folder containing raw files, analyses, and other data
- ${MAPPING_F_FP} - specify location of prepared mapping file
- ${MAPPING_METADATA} - specify what metadata would be used to perform group analysis
- ${PE_THREADED} - specify how many threads some scripts of the pipeline may be used
- ${WORK_DIR} - specify the name of the downstream analysis [default: downstream]

2. Run setup configuration file setup.sh, that would create necessary folders, download, extract databases, copy and prepare mapping files, configuration files etc...
	`chmod +x `
	`.setup.sh`
3. Copy prepared QIIME configuration file from specified base folder (${BASE_DIR}) to your home folder, i.e. the default location for qiime config - [see more at](http://qiime.org/install/qiime_config.html).
 `cp ${BASE_DIR}/qiime config.txt ~/.qiime_confi`g	
4. Generate submission file for preprocessing - preprocessing_from_mapping.py
  Although one could submit each job "Metagenomics_16s_preprocessing.pbs" manually for each sample ID, I encourage to use this script,
  that would take as an input mapping file, and produce .pbs script. You can either edit this document, and copy each submission line to terminal that has access to computing cluster, or to copy this file to a place where preprocessing script reside and submit it.
  
  Note!
  If there are multiple contaminant files, i.e. when multiple DNA extractions have been made leaving many extractions controls, one could use preprocessing_from_mapping.py and manually specified mapping file, where SampleID is just the id of a contaminant. Otherwise, it is easy to manually submit Metagenomics_16s_preprocessing_contaminants.pbs for each contaminating sequence. 
  
  `python preprocessing_from_mapping.py`
  
  A mapping file has to be in the same folder as this python script.
  This script resides in ${BASE_DIR}/mapping. 
5. Run preprocessing script for each of the samples separately.
	See point above. Script "preprocessing_from_mapping.py" helps in speeding this process. 
	Use:
	- "Metagenomics_16s_preprocessing.pbs" for processing valid sample sequences,
	- "Metagenomics_16s_preprocessing_contaminants.pbs" for so called "contaminants" - extraction blanks, PCR blanks, everything that could be counted as unwanted, polluting sequences. This script is the same as the first, only it stores sequences in different folder.
	
  Example job submission:
  `qsub -N jobName1 Metagenomics_16s_preprocessing.pbs sampleID1`
  `qsub -N jobName2 Metagenomics_16s_preprocessing.pbs sampleID2`
  ...
  `qsub -N jobNameN Metagenomics_16s_preprocessing.pbs sampleIDN`
  
  `qsub -N AnotherjobName1 Metagenomics_16s_preprocessing_contaminants.pbs contaminantID1`
  `qsub -N AnotherjobName2 Metagenomics_16s_preprocessing_contaminants.pbs contaminantID2`
  ...
  `qsub -N AnotherjobNameN Metagenomics_16s_preprocessing_contaminants.pbs contaminantID3`

6. Concatenate all valid (wanted), studies sequences into one file (the same for contaminant files) - concatenate.pbs
   It is easily done by simply submitting "concatenate.pbs" script. No parameter specifications are required.
   `qsub -N CAT concatenate.pbs`
7. Decontaminate valid/studied biological sequences using contaminating sequences. This step is long, and depends on available memory.
8. Run diversity analysis. This script automatically runs all necessary diversity and abundance analysis.
9. Run picrust analysis. This script automaticall runs all necessary metagenomic predictions. Not that for further analysis a STAMP software package is recommended. Output biom table in tsv format is specified, that stands as an input to STAMP software.

The last two steps could be run in parallel, while other are to be executed in a linear manner.
## V. References

- [QIIME software](http://qiime.org/index.html)
- [PICRUSt software](http://picrust.github.io/picrust/)
- [USEARCH](http://drive5.com/usearch/)
- [STAMP Analysis Software](http://kiwi.cs.dal.ca/Software/STAMP)
- [Microbiome Helper Virtual Machine](https://github.com/mlangill/microbiome_helper/wiki)
