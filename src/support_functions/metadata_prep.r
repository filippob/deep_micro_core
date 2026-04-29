
## script to add info (e.g. subject IDs) to the metadata file

library("readxl")
library("tidyverse")
library("data.table")

### GENERAL METADATA
prjfolder = "/home/filippo/Documents/deep_micro_core"
metadata_folder = "data/metadata/"
conf_file = "merged_results/Metadata.csv"

## TABLE OF DATASETS
# species	microbiome	n. samples	project	repository	subject ID
# cow	  milk	  219	  RABOLA	  PRJEB72623	  yes
# cow	  milk	  160	  RABOLA	  PRJNA1103402	yes
# cow	  rumen	  58	  FARMINN	  JBG8C	        yes
# cow	  gut		  56	  FARMINN	  JBG8C	        yes
# cow	  gut		  85	  RABOLA	  PRJEB77094	  yes
# cow	  rumen	  60	  RABOLA	  PRJEB77087	  yes
# goat	rumen	  28		          PRJNA1003434	yes
# goat	milk	  156	  MORGOAT	  KYFH4	        yes
# goat	gut		  29		          PRJNA1003434	yes
# pig	  gut	    100	  LEGUPLUS  KR9NH	        yes


################################################################################
## goat metadata (CASCO project): repo PRJNA1003434
casco_submission = "goat_CASCO/SRA_data_Summary_CASCO.csv"
casco_metadata = "goat_CASCO/Disegno sperimentale e campioni P-T-SQUARE-GOAT.xls"

casco_sub = fread(file.path(prjfolder, metadata_folder, casco_submission))
casco_mapping = readxl::read_xls(file.path(prjfolder, metadata_folder, casco_metadata), sheet = 1)

vec <- grepl(pattern = "16S", casco_sub$`Experiment Title`)
casco_sub <- casco_sub[vec,]

casco_sub$sample_id <- str_trim(gsub("^.*:","",casco_sub$`Experiment Title`), side = "both")
casco_sub <- casco_sub |>
  select(c(sample_id, `Experiment Accession`, `Experiment Title`, `Sample Accession`))

casco_sub$tissue = ifelse(grepl("Rumen", casco_sub$`Experiment Title`), "rumen", "gut")
casco_sub$goat = str_trim(gsub("^.*goat:|diet.*$","",casco_sub$`Experiment Title`))
casco_sub$project = "Grant-201801062101"
casco_sub$repo = "PRJNA1003434"

## n. of goats per tissue
casco_sub |> group_by(tissue) |> summarise(length(unique(goat)))

fname = file.path(prjfolder, metadata_folder, "goat_CASCO/CASCO_goat_metadata.csv")
fwrite(x = casco_sub, file = fname, col.names = TRUE, sep = ",")

casco_sub <- casco_sub |> 
  select(-c(`Experiment Title`, `Sample Accession`, tissue)) |>
  rename(`Sample ID` = `Experiment Accession`, `Project Name` = project, 
         `Project ID` = repo, subject_id = goat)

################################################################################

################################################################################
## milk metadata (RABOLA-219): repo PRJEB72623
rabola_submission = "milk_RABOLA/filereport_read_run_PRJEB72623.tsv"
rabola_mapping = "milk_RABOLA/mapping_file.csv"

fname = file.path(prjfolder, metadata_folder, rabola_submission)
rab_sub_219 = fread(fname)
fname = file.path(prjfolder, metadata_folder, rabola_mapping)
rab_map_219 = fread(fname)

rab_sub_219$sample_id = gsub("^.*/|_2.*$","",rab_sub_219$submitted_ftp)
rab_sub_219 <- rab_sub_219 |> select(c(sample_accession, sample_id, experiment_accession, study_accession))

rab_sub_219 <- rab_sub_219 |> 
  inner_join(rab_map_219, by = c("sample_id" = "sample-id")) |>
  select(c(sample_id, experiment_accession, cow, study_accession, project))

rab_sub_219 <- rab_sub_219 |> 
  rename(`Sample ID` = experiment_accession, `Project Name` = project, 
         `Project ID` = study_accession, subject_id = cow) |>
  mutate(subject_id = as.character(subject_id))

################################################################################

## DEEP MICRO CORE: GLOBAL METADATA
metadata = fread(file.path(prjfolder, conf_file))

metadata |> filter(`Project ID` == "PRJNA1003434", Tissue == "feces") |> nrow()
casco_sub$`Experiment Accession` %in% metadata$`Sample ID`
