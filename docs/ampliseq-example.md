
# Calling ampliseq on a test dataset

## Prepare the samplesheet file

Let's start from the test data downloaded using `nf-core/fetchngs`: we should create
a new samplesheet file required by `nf-core/ampliseq` 
[--input](https://nf-co.re/ampliseq/2.11.0/parameters/#input) parameter.
The `nf-core/fetchngs` pipeline is able to create a samplesheet file to be used in 
another nextflow pipeline through the 
[--nf_core_pipeline](https://nf-co.re/fetchngs/1.12.0/parameters/#nf_core_pipeline)
parameter, but unfortunately the `nf-core/ampliseq` pipeline is not yet supported.
We can create however the required samplesheet file from the `nf-core/fecthngs` output
using `awk` to manipulate the file

```bash
awk 'BEGIN {OFS=","; print "sampleID", "forwardReads", "reverseReads"} NR > 1 {print $1, $2, $3}' FS="," OFS="," data/test_PRJEB72623/samplesheet/samplesheet.csv > data/test_PRJEB72623_samplesheet.csv
```

The `data/test_PRJEB72623_samplesheet.csv` will be the samplesheet file required by
the `nf-core/ampliseq` pipeline

## Create the parameters file

Let's create another parameter file required by nextflow:

```json
{
  "input": "data/test_PRJEB72623_samplesheet.csv",
  "FW_primer": "CCTACGGGNGGCWGCAG",
  "RV_primer": "GACTACHVGGGTATCTAATCC",
  "outdir": "results/test_PRJEB72623",
  "sample_inference": "pooled",
  "dada_ref_taxonomy": "silva=138"
}
```

We require the *forward* and *reverse* primers sequences to tell `cutadapt` how
to cleaing out the sequences: it is possible that this primer are not present in sequences,
so there's another paramter [--retain_untrimmed](https://nf-co.re/ampliseq/2.11.0/parameters/#retain_untrimmed)
which let's to recover sequences without primers (which will be discarded if primers
are not found).

Ideally we will also a metadata file where the first column
is the sample id used in the *samplesheet* file, and then other columsn that can help us
which samples can be considered in the same group or not (healty, treated, etc.). Unfortunately
we cannot retrieve this metadata information simply using the ENA project 
[PRJEB72623](https://www.ebi.ac.uk/ena/browser/view/PRJEB72623). 

## Calling the nextflow pipeline

Time to call the nextflow pipeline whit the parameters we have:

```bash
nextflow run nf-core/ampliseq -r 2.11.0 -profile singularity \
    -config config/ampliseq.config -params-file config/ampliseq_test.json -resume
```