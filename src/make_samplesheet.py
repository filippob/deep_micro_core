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
import pandas as pd
from os import listdir, path

# %% parameters
mypath = 'data/prova/'
outfile = 'samplesheet.csv'

# %% samples
print("list of samples (folder names")
samples = listdir(mypath)


# %% fastqfiles
print("list of lists with file names per subfolder")
fastqf = [listdir(path.join(mypath,x)) for x in samples]
fastqf = [sorted(x) for x in fastqf] ## sort files within subfodler

# %% sanity check
print("N. of samples:", len(samples))
print('N. of file pairs:', len(fastqf))

# %% dataframe
if len(samples) == len(fastqf):
    df = pd.DataFrame(fastqf, columns = ['forwardReads', 'reverseReads']) 
    df['sampleID'] = samples
    df = df[['sampleID', 'forwardReads', 'reverseReads']]
else:
    print("N. of samples and n. of files do not match")

# %% add sample subfolders to path to files
df['forwardReads'] = df['sampleID'] + '/' + df['forwardReads']
df['reverseReads'] = df['sampleID'] + '/' + df['reverseReads']

# %% add path to file names
df['forwardReads'] = [path.join(mypath, x) for x in df['forwardReads']]
df['reverseReads'] = [path.join(mypath, x) for x in df['reverseReads']]

# %% write out
print("write out samplesheet file")

filename = path.abspath(path.join(mypath, '..', outfile))
print('writing to', filename)
df.to_csv(filename, sep=',', encoding='utf-8', index=False, header=True, quotechar='"')

print("DONE!")

fastqf
