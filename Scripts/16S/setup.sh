#!/bin/bash
source config.txt

mkdir -p ${BASE_DIR}
mkdir -p "${BASE_DIR}/mapping"

cp MAPPING_F_FP ${BASE_DIR}/mapping/mapping.txt
cp preprocessing_from_mapping.py ${BASE_DIR}/mapping/preprocessing_from_mapping.py

cp -r ncbi_blast ${BASE_DIR}/
DB_IN_USE="gg_13_5_otus" #

echo "" > ${BASE_DIR}/qiime_config.txt
echo "blastall_fp             ${NCBI_PATH}/2.2.22/bin/blastall" >> ${BASE_DIR}/qiime_config.txt
echo "blastmat_dir            ${NCBI_PATH}/2.2.22/data/" >> ${BASE_DIR}/qiime_config.txt
echo "seconds_to_sleep        2" >> ${BASE_DIR}/qiime_config.txt
echo "pynast_template_alignment_fp    ${BASE_DIR}/databases/${DB_IN_USE}/rep_set_aligned/85_otus.fasta" >> ${BASE_DIR}/qiime_config.txt
echo "assign_taxonomy_reference_seqs_fp       ${BASE_DIR}/databases/${DB_IN_USE}/rep_set/97_otus.fasta" >> ${BASE_DIR}/qiime_config.txt
echo "pick_otus_reference_seqs_fp     ${BASE_DIR}/databases/${DB_IN_USE}/rep_set/97_otus.fasta" >> ${BASE_DIR}/qiime_config.txt
echo "assign_taxonomy_id_to_taxonomy_fp       ${BASE_DIR}/databases/${DB_IN_USE}/taxonomy/97_otu_taxonomy.txt" >> ${BASE_DIR}/qiime_config.txt


cp gold.fa ${BASE_DIR}/gold.fa #for usearch_ref - PICRUSt closed reference predictions

#for safety we use here 13_5, later qiime config settings are overwritten by qime parameters

#NCBIRC
echo "data=\"${NCBI_PATH}2.2.22/data/\“" > ${BASE_DIR}/ncbirc




echo "Downloading databases"
wget ftp://greengenes.microbio.me/greengenes_release/gg_13_5/gg_13_8_otus.tar.gz
wget ftp://greengenes.microbio.me/greengenes_release/gg_13_5/gg_13_5_otus.tar.gz

mkdir -p ${BASE_DIR}/databases
tar -xvzf gg_13_8_otus.tar.gz -C ${BASE_DIR}/databases #would create gg_13_8_otus folder
rm -f gg_13_8_otus.tar.gz
tar -xvzf gg_13_5_otus.tar.gz - C ${BASE_DIR}/databases #would creatre gg_13_5_otus folder
rm -f gg_13_5_otus.tar.gz

DB_IN_USE="gg_13_8_otus" #

cp qiime_params.txt ${BASE_DIR}/qiime_params.txt
echo "parallel_assign_taxonomy_uclust:id_to_taxonomy_fp ${BASE_DIR}/databases/${DB_IN_USE}/taxonomy/97_otu_taxonomy.txt" >> ${BASE_DIR}/qiime_params.txt
echo "assign_taxonomy:id_to_taxonomy_fp ${BASE_DIR}/databases/${DB_IN_USE}/taxonomy/97_otu_taxonomy.txt" >> ${BASE_DIR}/qiime_params.txt
echo "assign_taxonomy:reference_seqs_fp ${BASE_DIR}/databases/${DB_IN_USE}/rep_set/97_otus.fasta" >> ${BASE_DIR}/qiime_params.txt
echo "parallel_align_seqs_pynast:template_fp ${BASE_DIR}/databases/${DB_IN_USE}/rep_set_aligned/85_otus.fasta" >> ${BASE_DIR}/qiime_params.txt
echo "blastall_fp             ${NCBI_PATH}/2.2.22/bin/blastall" >> ${BASE_DIR}/qiime_params.txt
echo "blastmat_dir            ${NCBI_PATH}/2.2.22/data/" >> ${BASE_DIR}/qiime_params.txt

DB_IN_USE_picrust="gg_13_5_otus" # PICRUST requires 13_5! And doesn't work with 13_8.

cp qiime_params.txt ${BASE_DIR}/qiime_params_picrust.txt
echo "parallel_assign_taxonomy_uclust:id_to_taxonomy_fp ${BASE_DIR}/databases/${DB_IN_USE_picrust}/taxonomy/97_otu_taxonomy.txt" >> ${BASE_DIR}/qiime_params_picrust.txt
echo "assign_taxonomy:id_to_taxonomy_fp ${BASE_DIR}/databases/${DB_IN_USE_picrust}/taxonomy/97_otu_taxonomy.txt" >> ${BASE_DIR}/qiime_params_picrust.txt
echo "assign_taxonomy:reference_seqs_fp ${BASE_DIR}/databases/${DB_IN_USE_picrust}/rep_set/97_otus.fasta" >> ${BASE_DIR}/qiime_params_picrust.txt
echo "parallel_align_seqs_pynast:template_fp ${BASE_DIR}/databases/${DB_IN_USE_picrust}/rep_set_aligned/85_otus.fasta" >> ${BASE_DIR}/qiime_params_picrust.txt
echo "pick_otus:db_filepath ${BASE_DIR}/gold.fa >> ${BASE_DIR}/qiime_params_picrust.txt
"
#Since we produce two levels of COG pathways, {l3,l2} we need to have to separate parameters files
cp ${BASE_DIR}/qiime_params_picrust.txt ${BASE_DIR}/qiime_params_picrust_l3.txt
echo "summarize_taxa:md_identifier    \"KEGG_Pathways\"" >> ${BASE_DIR}/qiime_params_picrust_l3.txt
echo "summarize_taxa:absolute_abundance   True" >> ${BASE_DIR}/qiime_params_picrust_l3.txt
echo "summarize_taxa:level    3" >> ${BASE_DIR}/qiime_params_picrust_l3.txt

cp ${BASE_DIR}/qiime_params_picrust.txt ${BASE_DIR}/qiime_params_picrust_l2.txt
echo "summarize_taxa:md_identifier    \"KEGG_Pathways\"" >> ${BASE_DIR}/qiime_params_picrust_l2.txt
echo "summarize_taxa:absolute_abundance   True" >> ${BASE_DIR}/qiime_params_picrust_l2.txt
echo "summarize_taxa:level    2" >> ${BASE_DIR}/qiime_params_picrust_l2.txt


##### Then edit qiime config for picrust, and add:
### summarize_taxa:md_identifier    "KEGG_Pathways"
### summarize_taxa:absolute_abundance   True
### summarize_taxa:level    2


mkdir -p ${MERGE_DIR}
mkdir -p ${FASTQ_DIR}
mkdir -p ${CONT_DIR}
mkdir -p ${SEQUENCE_DIR} #folder of concatenated sequences
cp illuminaAdapters.fa ${BASE_DIR}/illuminaAdapters.fa

mkdir -p ${WORK_DIR}
mkdir -p ${DIV_usearch}
mkdir -p ${alpha_dir}
mkdir -p ${beta_dir}
mkdir -p ${beta_dir}distance_metrics/ #dist variable
mkdir -p ${beta_dir}PCOA/
mkdir -p ${DIV_qiime}
mkdir -p ${DIV_jack}
mkdir -p ${DIV_jack_c}
mkdir -p ${PICRUST_DIR}
mkdir -p ${PICRUST_ANALYSIS}

cp data/rdp_16s_v16.fa ${BASE_DIR}/databases/rdp_16s_v16.fa
