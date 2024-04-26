#!/bin/bash

# Script for conducting phylogenetic sequence analysis
# Author: James Siqueira Pereira
# Supervisors: Alex Ranieri Jerônimo Lima; Gabriela Ribeiro; Vinicius Cairus;
# Funding Institutions: FAPESP; Instituto Butantan;
# Date: 15-03-2024

# Description: This script performs phylogenetic analyses on viral genomic data, covering sequential steps for sequence alignment, tree construction, temporal data-based refinement, ancestral reconstruction, translation, and export for subsequent interactive visualization using the auspice.us program.

# Note: This script can be adapted according to the user's needs. Its use and distribution are subject to crediting the authors and funding institutions.

# Set default variables
CPU=$(cat /proc/cpuinfo | grep processor | wc -l); nthreads=$(($CPU/2))
SEQUENCES=""
REFERENCE_SEQUENCE=""
OUTPUT=""
NTHREADS="$nthreads"
MEM=""
METADATA=""
CONFIG=""
MODEL="TEST"
ROOT="mid_point"
CLADES=""

# Process command line arguments
# Function to handle options
process_args() {
    local key="$1"
    local value="$2"

    case $key in
        -i|--sequences)
            SEQUENCES="$value"
            ;;
        -reference|--reference-sequence)
            REFERENCE_SEQUENCE="$value"
            ;;
        -j|--jobname)
            OUTPUT="$value"
            ;;
        -n|--nthreads)
            NTHREADS="$value"
            ;;
        --mem)
            MEM="$value"
            ;;
        -metadata|--metadata)
            METADATA="$value"
            ;;
        -config|--auspice-config)
            CONFIG="$value"
            ;;
        --root)
            ROOT="$value"
            ;;
        -m)
            MODEL="$value"
            ;;
        -c|--clades)
            CLADES="$value"
            ;;
        *)
            echo "Unknown option: $key"
            exit 1
            ;;
    esac
}

# Process command line arguments
while [[ $# -gt 0 ]]; do
    process_args "$1" "$2"
    shift 2
done

# Activate dengue analysis environment
eval "$(conda shell.bash hook)"
conda activate /storage/vital/volume1/carol/dengue/pipeline/conda_envs/augur

# Create alignment folder
mkdir ${OUTPUT}_alignment

echo "Sequence alignment in progress..."
# Command 1: nextalign
echo "Executing command:"
echo "augur align --sequences $SEQUENCES --reference-sequence $REFERENCE_SEQUENCE --output ${OUTPUT}_alignment/${OUTPUT}_aligned.fasta --fill-gaps --nthreads $NTHREADS"
augur align --sequences $SEQUENCES --reference-sequence $REFERENCE_SEQUENCE --output ${OUTPUT}_alignment/${OUTPUT}_aligned.fasta --fill-gaps --nthreads $NTHREADS

echo "Tree construction using IQTree2..."

# Create output folder
mkdir ${OUTPUT}_tree

# Copy alignment to folder where the tree will be generated
cp ${OUTPUT}_alignment/${OUTPUT}_aligned.fasta ${OUTPUT}_tree/

# Command 2: IQtree2
iqtree2 -s ${OUTPUT}_tree/${OUTPUT}_aligned.fasta -m $MODEL -nt $NTHREADS -bb 5000
echo "Command executed"
echo "iqtree2 -s ${OUTPUT}_tree/${OUTPUT}_aligned.fasta -m $MODEL -nt $NTHREADS -bb 5000"

# Remove duplicate alignment
rm -rf ${OUTPUT}_tree/${OUTPUT}_aligned.fasta

# Rename output file
mv ${OUTPUT}_tree/${OUTPUT}_aligned.fasta.treefile ${OUTPUT}_tree/${OUTPUT}.treefile

# Command 3: augur refine
if [ -n "$METADATA" ]; then
  echo "Refining tree with TreeTime..."
  augur refine --alignment ${OUTPUT}_alignment/${OUTPUT}_aligned.fasta --tree ${OUTPUT}_tree/${OUTPUT}.treefile --metadata $METADATA --output-tree ${OUTPUT}_tree/${OUTPUT}_refinedTree.nwk --root $ROOT --output-node-data ${OUTPUT}_tree/${OUTPUT}_branch-lengths.json --timetree --coalescent const --date-confidence --stochastic-resolve --date-inference marginal --clock-filter-iqd 4
  echo "Command executed:"
  echo "augur refine --alignment ${OUTPUT}_alignment/${OUTPUT}_aligned.fasta --tree ${OUTPUT}_tree/${OUTPUT}.treefile --metadata $METADATA --output-tree ${OUTPUT}_tree/${OUTPUT}_refinedTree.nwk --root $ROOT --output-node-data ${OUTPUT}_tree/${OUTPUT}_branch-lengths.json --timetree --coalescent const --date-confidence --stochastic-resolve --date-inference marginal --clock-filter-iqd 4"
else
  echo "Refining undated tree..."
  augur refine --tree ${OUTPUT}_tree/${OUTPUT}.treefile --output-tree ${OUTPUT}_tree/${OUTPUT}_refinedTree.nwk --output-node-data ${OUTPUT}_tree/${OUTPUT}_branch-lengths.json
  echo "Command executed:"
  echo "augur refine --tree ${OUTPUT}_tree/${OUTPUT}.treefile --output-tree ${OUTPUT}_tree/${OUTPUT}_refinedTree.nwk --output-node-data ${OUTPUT}_tree/${OUTPUT}_branch-lengths.json"
fi

# Command 4: augur ancestral
echo "Reconstructing ancestral..."
augur ancestral --tree ${OUTPUT}_tree/${OUTPUT}_refinedTree.nwk --alignment ${OUTPUT}_alignment/${OUTPUT}_aligned.fasta --output-node-data ${OUTPUT}_tree/${OUTPUT}_nt_muts.json --inference joint --root-sequence $REFERENCE_SEQUENCE
echo "Command executed:"
echo "augur ancestral --tree ${OUTPUT}_tree/${OUTPUT}_refinedTree.nwk --alignment ${OUTPUT}_alignment/${OUTPUT}_aligned.fasta --output-node-data ${OUTPUT}_tree/${OUTPUT}_nt_muts.json --inference joint --root-sequence $REFERENCE_SEQUENCE"

# Command 5: augur translate
echo "Defining mutations in amino acid sequences..."
augur translate --tree ${OUTPUT}_tree/${OUTPUT}_refinedTree.nwk --ancestral-sequences ${OUTPUT}_tree/${OUTPUT}_nt_muts.json --reference-sequence $REFERENCE_SEQUENCE --output-node-data ${OUTPUT}_tree/${OUTPUT}_aa_muts.json
echo "Command executed:"
echo "augur translate --tree ${OUTPUT}_tree/${OUTPUT}_refinedTree.nwk --ancestral-sequences ${OUTPUT}_tree/${OUTPUT}_nt_muts.json --reference-sequence $REFERENCE_SEQUENCE --output-node-data ${OUTPUT}_tree/${OUTPUT}_aa_muts.json"

# Command 6: augur clades
echo "Defining genotype clades according to Nextstrain Dengue mutation table (https://github.com/nextstrain/dengue/blob/main/phylogenetic/config/clades_genotypes.tsv)"
augur clades --tree ${OUTPUT}_tree/${OUTPUT}_refinedTree.nwk --mutations ${OUTPUT}_tree/${OUTPUT}_aa_muts.json ${OUTPUT}_tree/${OUTPUT}_nt_muts.json ${OUTPUT}_tree/${OUTPUT}_branch-lengths.json --clade /home/james_pereira/drdengue/pipelinePhyloReconstruction/designation_files/mutations_genotypes.tsv --output-node-data ${OUTPUT}_tree/genotypes.json --membership-name clade_membership --label-name clade

# Command 7: augur clades for lineages
if [ -n "$CLADES" ]; then
  echo "Annotating lineages..."
  augur clades --tree ${OUTPUT}_tree/${OUTPUT}_refinedTree.nwk --mutations ${OUTPUT}_tree/${OUTPUT}_aa_muts.json ${OUTPUT}_tree/${OUTPUT}_nt_muts.json ${OUTPUT}_tree/${OUTPUT}_branch-lengths.json --clade ${CLADES} --output-node-data ${OUTPUT}_tree/lineages.json --membership-name lineage_membership --label-name lineages
fi

# Command 8: augur export v2
if [ -n "$METADATA" ]; then
  echo "Exporting tree with metadata..."
  augur export v2 --tree ${OUTPUT}_tree/${OUTPUT}_refinedTree.nwk --metadata $METADATA --node-data ${OUTPUT}_tree/${OUTPUT}_nt_muts.json ${OUTPUT}_tree/${OUTPUT}_aa_muts.json ${OUTPUT}_tree/${OUTPUT}_branch-lengths.json ${OUTPUT}_tree/genotypes.json ${OUTPUT}_tree/lineages.json --output ${OUTPUT}_tree/${OUTPUT}.json --color-by-metadata serotype genotype country division location --auspice-config $CONFIG
  echo "Command executed:"
  echo "augur export v2 --tree ${OUTPUT}_tree/${OUTPUT}_refinedTree.nwk --metadata $METADATA --node-data ${OUTPUT}_tree/${OUTPUT}_nt_muts.json ${OUTPUT}_tree/${OUTPUT}_aa_muts.json ${OUTPUT}_tree/${OUTPUT}_branch-lengths.json ${OUTPUT}_tree/genotypes.json ${OUTPUT}_tree/lineages.json --output ${OUTPUT}_tree/${OUTPUT}.json --color-by-metadata serotype genotype country division location --auspice-config $CONFIG"
else
  echo "Exporting tree without metadata..."
  augur export v2 --tree ${OUTPUT}_tree/${OUTPUT}_refinedTree.nwk --node-data ${OUTPUT}_tree/${OUTPUT}_nt_muts.json ${OUTPUT}_tree/${OUTPUT}_aa_muts.json ${OUTPUT}_tree/${OUTPUT}_branch-lengths.json ${OUTPUT}_tree/genotypes.json ${OUTPUT}_tree/lineages.json --output ${OUTPUT}_tree/${OUTPUT}.json --auspice-config $CONFIG
  echo "Command executed:"
  echo "augur export v2 --tree ${OUTPUT}_tree/${OUTPUT}_refinedTree.nwk --node-data ${OUTPUT}_tree/${OUTPUT}_nt_muts.json ${OUTPUT}_tree/${OUTPUT}_aa_muts.json ${OUTPUT}_tree/${OUTPUT}_branch-lengths.json ${OUTPUT}_tree/genotypes.json ${OUTPUT}_tree/lineages.json --output ${OUTPUT}_tree/${OUTPUT}.json --auspice-config $CONFIG"
fi

conda deactivate
echo "Finish!!"
exit 0
