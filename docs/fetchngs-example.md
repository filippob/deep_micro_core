
# Collecting data from public archive using nf-core/fetchngs

## Find a project from ENA

Collect a sample project from ENA, for example [PRJEB72623](https://www.ebi.ac.uk/ena/browser/view/PRJEB72623)
then download the [TSV](https://www.ebi.ac.uk/ena/portal/api/filereport?accession=PRJEB72623&result=read_run&fields=study_accession,sample_accession,experiment_accession,run_accession,tax_id,scientific_name,experiment_title,experiment_alias,fastq_ftp,submitted_ftp,sra_ftp,bam_ftp&format=tsv&download=true&limit=0) report file: we can do it programmatically using wget:

```bash
cd data/
wget "https://www.ebi.ac.uk/ena/portal/api/filereport?accession=PRJEB72623&result=read_run&fields=run_accession&format=tsv&download=true&limit=0" -O filereport_PRJEB72623.tsv
```

You need to get rid of the header column. Moreover, if you have more than the `run_accession` 
column, get rid of the additional columns. Let's focus on first 10 samples to do this test:

```bash
cut -f1 filereport_PRJEB72623.tsv | tail -n +2 | head -n 10 > test_PRJEB72623.csv
```

The required extension of the IDs file should be `.csv` even if it has only one column, or 
nextflow will have issues to determine the file type.

## Create a configuration file

Nextflow let you to pass pipeline parameters using CLI: let's write them in a file to 
track them with code: create a json file like this and put into `config` folder:

```json
{
    "input": "data/test_PRJEB72623.csv",
    "outdir": "data/test_PRJEB72623"
}
```

The `input` and `output` parameters are the only two [parameters](https://nf-co.re/fetchngs/1.12.0/parameters/) 
required by [nf-core/ngs](https://nf-co.re/fetchngs/1.12.0). The *paths* can be defined as *relative to this
project directory*. We choose to collect the results of this pipeline in the `data` folder,
since those results are the input for other analyses. You have a copy of this file as `config/fetchngs_test.json`.
In the `config` folder, you will find a `fetchngs.config` which is another configuration file
writtein in `groovy` which try to limit resources usage while calling this pipeline.

## Get and launch the nextflow pipeline

A nextflow pipeline can be downloaded locally from git, downloaded in nextflow `assets` folder using 
[nf-core tools](https://nf-co.re/docs/nf-core-tools/pipelines/download) or using 
[nexflow pull](https://www.nextflow.io/docs/latest/cli.html#pulling-or-updating-a-project). The latest 
way consists to call [nextflow run](https://www.nextflow.io/docs/latest/cli.html#running-pipelines) 
with the pipeline: if the pipeline is not yet downloaded, will be
downloaded in the `assets` folder before being launched: it's better to specify the pipeline version
in order to be sure of which pipeline will be called. Go into project root directory then call
nextflow using the relative paths to you rconfiguration files

```bash
nextflow run nf-core/fetchngs -r 1.12.0 -profile singularity \
    -config config/fetchngs.config -params-file config/fetchngs_test.json -resume
```

The `-profile` option can enable a set of options in the same time, in this case
will use [singularity](https://sylabs.io/singularity/) container to execute stuff. 
The `-resume` option will
use *cached results* if any: it is useful to recover a pipeline, when calling 
a pipeline for the first time has no effect. 

There are other paramerers that can be specified at the runtime or in a configuration file,
for example the [process.executor](https://www.nextflow.io/docs/latest/executor.html), which can be specified in order to run the pipeline 
locally (on the same machine where nextflow is called) or an in HPC environment. To execute
this pipeline using `slurm`, for example, you can set this parameter on the configuration 
pipeline like this: 

```groovy
process.executor = 'slurm'
```

or 

```groovy
process {
    executor = 'slurm'
}
```

or by setting `$NXF_EXECUTOR` environment variable in your terminal:

```bash
NXF_EXECUTOR="slurm"
```