#!/bin/bash

# Script for conducting Phylogeny sequence analysis
# Author: James Siqueira Pereira
# Advisors: Alex Ranieri Jerônimo Lima; Gabriela Ribeiro; Vinicius Cairus;
# Funding Institutions: FAPESP; Butantan Institute;
# Date: 03-15-2024

# Description: This script performs phylogenetic analyses on viral genomic data, encompassing sequential steps for sequence alignment, tree construction, temporal data-based refinement, ancestral reconstruction, translation, and export for subsequent interactive visualization using the auspice.us program.

# Note: This script can be adapted according to the user's needs. Its usage and distribution are subject to crediting the authors and funding institutions.


# Process command line arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -i|--sequences)
      SEQUENCES="$2"
      shift
      shift
      ;;
    -reference|--reference-sequence)
      REFERENCE_SEQUENCE="$2"
      shift
      shift
      ;;
    -j|--jobname)
      OUTPUT="$2"
      shift
      shift
      ;;
    -n|--nthreads)
      NTHREADS="$2"
      shift
      shift
      ;;
    --mem=*)
      MEM="${key#*=}"
      shift
      ;;
    -metadata|--metadata)
      METADATA="$2"
      shift
      shift
      ;;
    -config|--auspice-config)
      CONFIG="$2"
      shift
      shift
      ;;
    --root)
      ROOT="$2"
      shift
      shift
      ;;
    -m)
      MODEL="$2"
      shift
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done


# Activating Dengue analysis environment
eval "$(conda shell.bash hook)"
conda activate /storage/vital/volume1/carol/dengue/pipeline/conda_envs/augur

# Create alignment folder
mkdir ${OUTPUT}_alignment

# Step 1: nextalign

echo "Executing step:"
echo "Alignment of sequences in progress..."


augur align --sequences $SEQUENCES --reference-sequence $REFERENCE_SEQUENCE --output ${OUTPUT}_alignment/${OUTPUT}_aligned.fasta --fill-gaps --nthreads $NTHREADS
echo "executed command: augur align --sequences $SEQUENCES --reference-sequence $REFERENCE_SEQUENCE --output ${OUTPUT}_alignment/${OUTPUT}_aligned.fasta --fill-gaps --nthreads $NTHREADS"

# Creating output folder
mkdir ${OUTPUT}_tree

# Copying alignment to folder where tree will be generated
cp ${OUTPUT}_alignment/${OUTPUT}_aligned.fasta ${OUTPUT}_tree/

# Step 2: IQtree2
echo "Executing step:"
echo "Building tree using IQTree2..."

iqtree2 -s ${OUTPUT}_tree/${OUTPUT}_aligned.fasta -m $MODEL -nt $NTHREADS -bb 5000
echo "executed command: iqtree2 -s ${OUTPUT}_tree/${OUTPUT}_aligned.fasta -m $MODEL -nt $NTHREADS -bb 5000"

# Removing duplicate alignment
rm -rf ${OUTPUT}_tree/${OUTPUT}_aligned.fasta

# Renaming output file
mv ${OUTPUT}_tree/${OUTPUT}_aligned.fasta.treefile ${OUTPUT}_tree/${OUTPUT}.treefile

# Step 3: augur refine
if [ -n "$METADATA" ]; then
  echo "Executing step:"
  echo "Refining tree with TreeTime..."

  augur refine --alignment ${OUTPUT}_alignment/${OUTPUT}_aligned.fasta --tree ${OUTPUT}_tree/${OUTPUT}.treefile --metadata $METADATA --output-tree ${OUTPUT}_tree/${OUTPUT}_refinedTree.nwk --root $ROOT --output-node-data ${OUTPUT}_tree/${OUTPUT}_branch-lengths.json --timetree --coalescent const --date-confidence --stochastic-resolve --date-inference marginal --clock-filter-iqd 4
  echo "executed command: augur refine --alignment ${OUTPUT}_alignment/${OUTPUT}_aligned.fasta --tree ${OUTPUT}_tree/${OUTPUT}.treefile --metadata $METADATA --output-tree ${OUTPUT}_tree/${OUTPUT}_refinedTree.nwk --root $ROOT --output-node-data ${OUTPUT}_tree/${OUTPUT}_branch-lengths.json --timetree --coalescent const --date-confidence --stochastic-resolve --date-inference marginal --clock-filter-iqd 4"
else
  echo "Executing step:"
  echo "Refining undated tree..."

  augur refine --tree ${OUTPUT}_tree/${OUTPUT}.treefile --output-tree ${OUTPUT}_tree/${OUTPUT}_refinedTree.nwk --output-node-data ${OUTPUT}_tree/${OUTPUT}_branch-lengths.json
  echo "executed command: augur refine --tree ${OUTPUT}_tree/${OUTPUT}.treefile --output-tree ${OUTPUT}_tree/${OUTPUT}_refinedTree.nwk --output-node-data ${OUTPUT}_tree/${OUTPUT}_branch-lengths.json"
fi

# Step 4: augur ancestral
echo "Executing step:"
echo "Reconstructing ancestors..."

augur ancestral --tree ${OUTPUT}_tree/${OUTPUT}_refinedTree.nwk --alignment ${OUTPUT}_alignment/${OUTPUT}_aligned.fasta --output-node-data ${OUTPUT}_tree/${OUTPUT}_nt_muts.json --inference joint --root-sequence $REFERENCE_SEQUENCE
echo "executed command: augur ancestral --tree ${OUTPUT}_tree/${OUTPUT}_refinedTree.nwk --alignment ${OUTPUT}_alignment/${OUTPUT}_aligned.fasta --output-node-data ${OUTPUT}_tree/${OUTPUT}_nt_muts.json --inference joint --root-sequence $REFERENCE_SEQUENCE"

# Step 5: augur translate
echo "Executing step:"
echo "Defining mutations in amino acid sequences..."

augur translate --tree ${OUTPUT}_tree/${OUTPUT}_refinedTree.nwk --ancestral-sequences ${OUTPUT}_tree/${OUTPUT}_nt_muts.json --reference-sequence $REFERENCE_SEQUENCE --output-node-data ${OUTPUT}_tree/${OUTPUT}_aa_muts.json
echo "executed command: augur translate --tree ${OUTPUT}_tree/${OUTPUT}_refinedTree.nwk --ancestral-sequences ${OUTPUT}_tree/${OUTPUT}_nt_muts.json --reference-sequence $REFERENCE_SEQUENCE --output-node-data ${OUTPUT}_tree/${OUTPUT}_aa_muts.json"

# Step 6: augur export v2
if [ -n "$METADATA" ]; then
  echo "Executing step:"
  echo "Exporting tree with metadata..."

  augur export v2 --tree ${OUTPUT}_tree/${OUTPUT}_refinedTree.nwk --metadata $METADATA --node-data ${OUTPUT}_tree/${OUTPUT}_nt_muts.json ${OUTPUT}_tree/${OUTPUT}_aa_muts.json ${OUTPUT}_tree/${OUTPUT}_branch-lengths.json --output ${OUTPUT}_tree/${OUTPUT}.json --color-by-metadata serotype genotype country division location --auspice-config $CONFIG
  echo "executed command: export v2 --tree ${OUTPUT}_tree/${OUTPUT}_refinedTree.nwk --metadata $METADATA --node-data ${OUTPUT}_tree/${OUTPUT}_nt_muts.json ${OUTPUT}_tree/${OUTPUT}_aa_muts.json ${OUTPUT}_tree/${OUTPUT}_branch-lengths.json --output ${OUTPUT}_tree/${OUTPUT}.json --color-by-metadata serotype genotype country division location --auspice-config $CONFIG"
else
  echo "Executing step:"
  echo "Exporting tree without metadata..."

  augur export v2 --tree ${OUTPUT}_tree/${OUTPUT}_refinedTree.nwk --node-data ${OUTPUT}_tree/${OUTPUT}_nt_muts.json ${OUTPUT}_tree/${OUTPUT}_aa_muts.json ${OUTPUT}_tree/${OUTPUT}_branch-lengths.json --output ${OUTPUT}_tree/${OUTPUT}.json --auspice-config $CONFIG
  echo "executed command: augur export v2 --tree ${OUTPUT}_tree/${OUTPUT}_refinedTree.nwk --node-data ${OUTPUT}_tree/${OUTPUT}_nt_muts.json ${OUTPUT}_tree/${OUTPUT}_aa_muts.json ${OUTPUT}_tree/${OUTPUT}_branch-lengths.json --output ${OUTPUT}_tree/${OUTPUT}.json --auspice-config $CONFIG"
fi

conda deactivate

echo "Analysis results exported!!"

exit 0
