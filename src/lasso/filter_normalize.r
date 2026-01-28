## SET-UP
library("biomformat")
library("data.table")


## PARAMETERS
args = commandArgs(trailingOnly=TRUE)
if (length(args) >= 1) {

  #loading the parameters
  if (file_ext(args[1]) %in% c("r","R")) {

    source(args[1])
    # source("Analysis/hrr/config.R")
  } else {

    load(args[1])
  }

} else {
  #this is the default configuration, used for development and debug
  writeLines('Using default config')

  #this dataframe should be always present in config files, and declared
  #as follows
  config = NULL
  config = rbind(config, data.frame(
    #base_folder = '~/Documents/SMARTER/Analysis/hrr/',
    #genotypes = "Analysis/hrr/goat_thin.ped",
    repo = "/home/filippo/Documents/deep_micro_core/deep_micro_core",
    prjfolder = "/home/filippo/Documents/deep_micro_core",
    count_table = "merged_results/filtered_feature-table.biom", ## biom format file (from the ampliseq pipeline)
    analysis_folder = "Analysis/lasso",
    conf_file = "merged_results/Metadata.csv",
    suffix = "dm_microbiomes",
    min_counts_asv = 20,
    min_samples_asv = 3,
    tissue = "rumen",
    species = "",
    project = "deep_micro_core",
    # sample_column = "sample",
    force_overwrite = FALSE
  ))
}


## making normalization folder
writeLines(" - make output/analysis fodler if it doesn't exist")
if(!file.exists(file.path(config$prjfolder, config$analysis_folder))) dir.create(file.path(config$prjfolder,config$analysis_folder), showWarnings = FALSE, recursive = TRUE)

writeLines(" - read in input data")
fname = file.path(config$prjfolder, config$count_table)
print(paste("reading input file", fname))
x1 <- read_biom(fname)

print("size of input data is (rows, columns):")
biom_shape(x1)

## convert to matrix of counts
X <- as(biom_data(x1), "matrix")

sample_counts = colSums(X)
sample_asv = colSums(X != 0)
asv_counts = rowSums(X)
asv_samples = rowSums(X != 0)

print("summary of count per sample")
summary(sample_counts)
print("summary of n. of ASV with counts > 0 per sample")
summary(sample_asv)
print("summary of count per ASV")
summary(asv_counts)
print("summary of n. of samples with counts > 0 per ASV")
summary(asv_samples)

## METADATA
metadata <- fread(file.path(config$prjfolder, config$conf_file))

writeLines(" - subset data")
print(paste("Selected tissue is:", config$tissue))
print(paste("Selected species is:", config$species))

if (config$tissue != "") metadata <- filter(metadata, Tissue == config$tissue)
if (config$species != "") metadata <- filter(metadata, `Species/Substrate` == config$species)

vec = colnames(X) %in% metadata$`Sample ID`
X <- X[,vec]
nsamples = ncol(X)

print(paste("N. of samples after subsetting:", nsamples))

sample_counts = colSums(X)
sample_asv = colSums(X != 0)
asv_counts = rowSums(X)
asv_samples = rowSums(X != 0)

print("summary of count per sample after subsetting")
summary(sample_counts)
print("summary of n. of ASV with counts > 0 per sample after subsetting")
summary(sample_asv)
print("summary of count per ASV after subsetting")
summary(asv_counts)
print("summary of n. of samples with counts > 0 per ASV after subsetting")
summary(asv_samples)

## FILTERING
writeLines(" - filter count table")
print("thresholds:")
print(paste("min n. of counts per ASV", config$min_counts_asv))
print(paste("min. n. of samples with counts > 0 per ASV", config$min_samples_asv))

vec <- (asv_counts > config$min_counts_asv) & (asv_samples > config$min_samples_asv)
print(paste("n. of ASV that will be removed with the chosen thresholds:", sum(!vec)))
vex <- (sample_counts > 1) & (sample_asv > 1)
print(paste("n. of samples with zero counts (removed):", sum(!vex)))

X <- X[vec,vex]
print(paste("N. of ASV retained after filtering", nrow(X)))
print(paste("N. of samples retained after filtering", ncol(X)))

source(file.path(config$repo, "src/support_functions/phyloseq_transform.R")) ## from: https://github.com/vmikk/metagMisc/
writeLines(" - CSS normalization")

## define function for cumlative sums
cumsum <- function(x,p) {

  x <- sort(x, decreasing = TRUE)
  quantile_index = round(length(x) * p)
  return(sum(x[1:quantile_index]))
}

p = 0.75 ## quantile fraction to use in calculations
cumsums = apply(X, MARGIN = 2, function(x) cumsum(x,p))
N = median(cumsums) ## scaling factor (median of cumulative sums)

## normalising
Z <- sweep(X, MARGIN = 2, cumsums, FUN = "/")
Z = Z*N

writeLines(" - saving out filtered and normalized count matrix")
fname = file.path(config$prjfolder, config$analysis_folder, "filtered_normalized_counts.RDS")
saveRDS(object = Z, file = fname, ascii = FALSE, version = NULL, compress = TRUE, refhook = NULL)
