#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Oct  6 08:29:46 2025

@author: filippo
"""

## script to make a file with sample names and read file names (R1 and R2) 
## this is written for the following file system structure
## project folder > sample folders > R1/R2 fastq files

# %% libraries 
import os
import re
import pandas as pd
from os import listdir, path
from os.path import isfile, join

# %% parameters
mypath = '/home/ngs/220620_M04028_0148_000000000-K74V8'
outfile = 'deep_micro_core/data/samplesheet-K74V8.csv' ## path relative to HOME
separator = "_" ## string separator for data filenames
extension = ".fastq.gz" ## data file extension
first_sample = 1 ## first sample to be used
last_sample = 50 ## last sample to be used in the sequence
sample_prefix = "sample" ## prefix -if any- to prepend to sample names (e.g. if these are only numeric and would not match the ampliseq pattern: ^[a-zA-Z][a-zA-Z0-9_]+$)

print("### PARAMETERS #######################")
print("path to data:", mypath)
print("output samplesheet:", outfile)
print("data filenames separator:", separator)
print("data file extension:", extension)
print("first sample:", first_sample)
print("last sample:", last_sample)
print("sample name prefix", sample_prefix)
print("######################################")

# %% samples
print("list of files")
fastqf = [f for f in listdir(mypath) if isfile(join(mypath, f)) if f.endswith(extension)]


# %% fastqfiles
print("set of samples")
samples = [x.split(separator)[0] for x in fastqf]
samples = set(samples)

# %% sanity check
print("N. of samples:", len(samples))
print('N. of file pairs:', len(fastqf))

# %% list of lists with paired-end files per sample
print("subsetting the list of samples")
samples = [x for x in samples if x.capitalize() != 'Undetermined']
samples = [x for x in samples if int(x) in list(range(first_sample,(last_sample+1),1))]
print('N. of samples left after subsetting:', len(samples))

files = []

for s in samples:
    pattern = r'^' + s + separator
    temp = [x for x in fastqf if re.match(pattern, x)]
    files.append(sorted(temp))

# %% make dataframe from list of lists
if len(samples) == len(files):
   df = pd.DataFrame(files, columns = ['forwardReads', 'reverseReads'])
   df['sampleID'] = samples
   df = df[['sampleID', 'forwardReads', 'reverseReads']]
else:
    print("N. of samples and n. of files do not match")


# %% add path to file names
df['forwardReads'] = [path.join(mypath, x) for x in df['forwardReads']]
df['reverseReads'] = [path.join(mypath, x) for x in df['reverseReads']]

# %% add prefix to sample name
df['sampleID'] = sample_prefix + '_' + df['sampleID'].astype(str)

# %% write out
print("write out samplesheet file")
filename = path.abspath(path.join(os.environ['HOME'], outfile))
print('writing to', filename)
df.to_csv(filename, sep=',', encoding='utf-8', index=False, header=True, quotechar='"')

print("DONE!")

