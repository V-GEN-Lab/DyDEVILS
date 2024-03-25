# denvLineages - Deciphering intra-genotype genetic diversity of Dengue virus serotypes 1 and 2: Using a semi-automatic workflow for proposing a lineage classification system

This repository contains the result of using a semi-automatic workflow for classifying Dengue virus (DENV) based on complete genome sequences. It addresses the current limitations in sub-genotype classification, offering a more granular and standardized system compared to traditional methods.

## Using Nextclade web app to assign lineages

To promote the widespread adoption of the proposed DENV lineage classification system, dedicated Nextclade datasets for [DENV-1](https://v2.clades.nextstrain.org/?dataset-url=https://github.com/alex-ranieri/denvLineages/tree/main/Nextclade_V2_data/DENV1) and [DENV-2](https://v2.clades.nextstrain.org/?dataset-url=https://github.com/alex-ranieri/denvLineages/tree/main/Nextclade_V2_data/DENV2) were constructed.

## Downloading dataset to be used with Nextclade CLI
Users can download the datasets from this repository, located in the folder `Nextclade_V2_data`, to perform offline analysis using Nextclade CLI V2.14.0.

## Future implementations

 - [ ] Apply the proposed DENV lineage classification system to DENV-3 and DENV-4. This expansion will create a comprehensive framework for DENV lineage designation encompassing all four serotypes.
 - [ ] Integration with the Viral Identification Pipeline for Emergency Response [(VIPER)](https://github.com/alex-ranieri/viper) assembly pipeline  is planned.
 - [ ] Upgrade datasets to ensure compatibility with Nextclade V3.

 ## Copyright and licence

denvLineages was developed by [CeVIVAS](https://bv.fapesp.br/en/auxilios/110575/continuous-improvement-of-vaccines-center-for-viral-surveillance-and-serological-assessment-cevivas/) bioinformatics team at the Butantan Institute:
* James Siqueira Pereira
* Vinicius Carius De Souza
* Gabriela Ribeiro
* Isabela Carvalho Brcko
* Igor Santana Ribeiro
* Iago Trezena Tavares De Lima

Suppervised by:
* Alex Ranieri J. Lima 
* Svetoslav Nanev Slavov
* Maria Carolina Quartim Barbosa Elias Sabbaga
* Sandra Coccuzzo Sampaio Vessoni 

denvLineages was developed using free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version.

denvLineages is distributed in the hope that it will be useful, but **without any warranty; without even the implied warranty of merchantability or fitness for a particular purpose**. See the GNU General Public License for more details: http://www.gnu.org/licenses/.
