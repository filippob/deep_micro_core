## SET-UP
library("CoreMicro")
library("biomformat")


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
    count_table = "Analysis/lasso/filtered_normalized_counts.RDS", ## biom format file (from the ampliseq pipeline)
    taxonomy_file = "merged_results/export/taxonomy/taxonomy.tsv",
    analysis_folder = "Analysis/core_microbiome",
    conf_file = "merged_results/Metadata.csv",
    suffix = "cow_microbiomes",
    min_counts_asv = 20,
    min_samples_asv = 3,
    tissue = "hindgut",
    species = "cow",
    pct_samples = 0.8, ## min % samples with the taxon
    pct_reads = 0.005, ## min relative abundance of reads for the taxon
    project = "deep_micro_core",
    # sample_column = "sample",
    force_overwrite = FALSE
  ))
}

writeLines(" - reading the data")
## READ THE DATA
writeLines(" - reading the data")
fname = file.path(config$prjfolder, config$count_table)
X <- readRDS(fname)

## READ THE TAXA
fname = file.path(config$prjfolder, config$taxonomy_file)
tax_table = fread(fname)

## READ THE METADATA
writeLines(" - reading the metadata")
fname = file.path(config$prjfolder, config$conf_file)
metadata = fread(fname)

writeLines(" - subsetting the file based on species and tissue")
print(paste("Selected tissue is:", config$tissue))
print(paste("Selected species is:", config$species))

if (config$tissue != "") metadata <- filter(metadata, Tissue == config$tissue)
if (config$species != "") metadata <- filter(metadata, `Species/Substrate` == config$species)

sample_ids = colnames(X)
otu_ids = rownames(X)

vec = (sample_ids %in% metadata$`Sample ID`)
X <- X[, vec]
X <- as_tibble(X)

X$Sample = otu_ids
X <- relocate(X, Sample)

writeLines(" - calculating the core microbiome")
core_ids <- abundance_and_occupancy_core(X, prop_rep =  config$pct_samples, prop_reads = config$pct_reads)
core_mb <- X[X$Sample %in% core_ids,]

writeLines(" - assigning taxa to the core microbiome")
core_mb <- core_mb |> inner_join(tax_table, by = c("Sample" = "Feature ID"))

core_mb <- separate(core_mb,
                    col = Taxon,
                    into = c("domain","phylum","class","order","family","genus","species","strain","score"),
                    sep = ";")

core_mb = unite(data = core_mb, col = "taxon", c(order,family, genus, species), sep = "-")
core_mb$taxon = gsub("-*$","",core_mb$taxon)

writeLines(" - writing out results")
dir.create(config$analysis_folder, showWarnings = FALSE)
fname = paste("core", config$tissue, config$species, sep = "-")
fname = paste(fname, ".csv", sep="")
fname = file.path(config$analysis_folder, fname)
fwrite(x = core_mb, file = fname, sep = ",")

print("DONE!")
