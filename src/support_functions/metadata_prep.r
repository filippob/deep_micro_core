
## script to add info (e.g. subject IDs) to the metadata file

library("readxl")
library("tidyverse")
library("data.table")


prjfolder = "/home/filippo/Documents/deep_micro_core"
conf_file = "merged_results/Metadata.csv"

## goat metadata (CASCO project)
casco_submission = "data/goat_CASCO/SRA_data_Summary_CASCO.csv"
casco_metadata = "data/goat_CASCO/Disegno sperimentale e campioni P-T-SQUARE-GOAT.xls"

casco_sub = fread(file.path(prjfolder, casco_submission))
casco_mapping = readxl::read_xls(file.path(prjfolder, casco_metadata), sheet = 1)

vec <- grepl(pattern = "16S", casco_sub$`Experiment Title`)
casco_sub <- casco_sub[vec,]

casco_sub$sample_id <- str_trim(gsub("^.*:","",casco_sub$`Experiment Title`), side = "both")
casco_sub <- casco_sub |>
  select(c(sample_id, `Experiment Accession`, `Experiment Title`, `Sample Accession`))

casco_sub$tissue = ifelse(grepl("Rumen", casco_sub$`Experiment Title`), "rumen", "gut")
casco_sub$goat = str_trim(gsub("^.*goat:|diet.*$","",casco_sub$`Experiment Title`))

## n. of goats per tissue
casco_sub |> group_by(tissue) |> summarise(length(unique(goat)))

fname = file.path(prjfolder, "data/goat_CASCO/CASCO_goat_metadata.csv")
fwrite(x = casco_sub, file = fname, col.names = TRUE, sep = ",")


## DEEP MICRO CORE: GLOBAL METADATA
metadata = fread(file.path(prjfolder, conf_file))

metadata |> filter(`Project ID` == "PRJNA1003434", Tissue == "feces") |> nrow()
casco_sub$`Experiment Accession` %in% metadata$`Sample ID`
