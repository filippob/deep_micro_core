# deep_micro_core
Code repository for the DeepMicroCore project: Harnessing the power of artificial intelligence to identify the core microbiome [2024-2025]

- WP1-DATA: data collection and integration
- WP2-REPRESENTATION: data preprocessing and representation
- WP3-MODEL: model building and evaluation
- WP4-INTERPRET: feature extraction and model interpretation


### First experiment

Fastq files to be downloaded using the Nextflow pipeline ([see here](https://github.com/filippob/deep_micro_core/blob/main/docs/fetchngs-example.md)) from 
[ENA](https://www.ebi.ac.uk/ena) or [NCBI](https://www.ncbi.nlm.nih.gov/sra/), with the following project IDs:

- cow milk:  **PRJEB72623** and **PRJNA1103402**
- cow rumen: **PRJEB77087**
- cow rectum/hindgut/feces: **PRJEB77094**

  
### Lasso-penalised regression

1. [filter_normalize.r](src/lasso/filter_normalize.r)
2. [train_lasso_model.r](src/lasso/train_lasso_model.r)
