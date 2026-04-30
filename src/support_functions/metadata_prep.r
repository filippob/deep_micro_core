
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
         `Project ID` = repo, subject_id = goat) |>
  mutate(subject_id = paste(`Project ID`, subject_id, sep="-"))

################################################################################

################################################################################
## milk metadata (RABOLA-219): repo PRJEB72623
rabola_submission = "milk_RABOLA-aloe/filereport_read_run_PRJEB72623.tsv"
rabola_mapping = "milk_RABOLA-aloe/mapping_file.csv"

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
  mutate(subject_id = paste(`Project ID`, subject_id, sep="-"))

length(unique(rab_sub_219$subject_id))

################################################################################

################################################################################
## milk metadata (RABOLA-160): repo PRJNA1103402
rabola_submission = "milk_RABOLA-bacteriocin/SraRunTable.csv"
rabola_mapping = "milk_RABOLA-bacteriocin/mapping_file.csv"

fname = file.path(prjfolder, metadata_folder, rabola_submission)
rab_sub_160 = fread(fname)
fname = file.path(prjfolder, metadata_folder, rabola_mapping)
rab_map_160 = fread(fname)

rab_sub_160 <- rab_sub_160 |> 
  select(c(BioProject, BioSample, Cow_number, Experiment)) |>
  mutate(project = "RABOLA") |>
  rename(sample_id = BioSample, `Sample ID` = Experiment, `Project Name` = project, 
         `Project ID` = BioProject, subject_id = Cow_number) |>
  mutate(subject_id = paste(`Project ID`, subject_id, sep="-"))

length(unique(rab_sub_160$subject_id))

################################################################################

################################################################################
## rumen + hindgut metadata (FARM-INN): repo JBG8C
farminn_mapping = "cow_FARMINN/mapping_file.csv"

fname = file.path(prjfolder, metadata_folder, farminn_mapping)
farminn_map = fread(fname)

farminn_map <- farminn_map |>
  mutate(`Sample ID` = ifelse(type == "FECI", paste("H_",nid,"_S",nid,"_L001", sep = ""), 
                            paste("R_",nid,"_S",nid,"_L001", sep = "")),
         `Project Name` = "FARM-INN", `Project ID` = "JBG8C") |>
  select(nid, `Sample ID`, cow, `Project ID`, `Project Name`) |>
  rename(sample_id = nid, subject_id = cow) |>
  mutate(subject_id = paste(`Project ID`, subject_id, sep="-"), sample_id = as.character(sample_id))

################################################################################

################################################################################
## gut metadata (RABOLA): repo PRJEB77094
rabola_mapping = "gut_RABOLA/mapping_file.csv"

fname = file.path(prjfolder, metadata_folder, rabola_mapping)
rab_map = fread(fname)

rab_map <- rab_map |>
  mutate(`Project ID` = "PRJEB77094", `Project Name` = "RABOLA", `Sample ID` = paste(`Project ID`,"_",nid,"_S",nid,"_L001", sep="")) |>
  rename(subject_id = cow, sample_id = nid) |>
  select(c(sample_id, `Project ID`, `Project Name`, subject_id, `Sample ID`)) |>
  mutate(subject_id = paste(`Project ID`, subject_id, sep="-"), sample_id = as.character(sample_id))

rab_map_gut <- rab_map

################################################################################

################################################################################
## rumen metadata (RABOLA): repo PRJEB77087
rabola_submission = "rumen_RABOLA/filereport_read_run_PRJEB77087.tsv"
rabola_mapping = "rumen_RABOLA/mapping_file.csv"

fname = file.path(prjfolder, metadata_folder, rabola_submission)
rab_sub = fread(fname)
fname = file.path(prjfolder, metadata_folder, rabola_mapping)
rab_map = fread(fname)

rab_sub$sample_id = gsub("^.*/|\\..*$","",rab_sub$submitted_ftp)
rab_sub <- select(rab_sub, c(sample_id, experiment_accession, study_accession))
rab_sub$nid = gsub("_.*$","",rab_sub$sample_id)
rab_map <- select(rab_map, c(nid, cow)) |> mutate(nid = as.character(nid))

rab_sub <- rab_sub |> inner_join(rab_map, by = "nid") |>
  mutate(`Project Name` = "RABOLA") |>
  select(c(nid, experiment_accession, study_accession, cow, `Project Name`)) |>
  rename(`Sample ID` = experiment_accession, sample_id = nid, subject_id = cow, `Project ID` = study_accession) |>
  mutate(subject_id = as.character(subject_id))

rab_sub_rumen <- rab_sub

################################################################################


################################################################################
## milk metadata (MORGOAT): repo KYFH4
morgoat_mapping = "milk_MORGOAT/mapping_file.csv"

fname = file.path(prjfolder, metadata_folder, morgoat_mapping)

morgoat_map = fread(fname)
morgoat_map$repo = "KYFH4"
morgoat_map$sample_id = paste(morgoat_map$repo, "sample", morgoat_map$sample, sep = "_")

morgoat_map <- morgoat_map |> 
  rename(`Sample ID` = sample_id, sample_id = sample, subject_id = goat_id, `Project ID` = repo) |>
  mutate(subject_id = as.character(subject_id), `Project Name` = "MORGOAT") |>
  select(-c(timepoint, udder_health, Antibiotic, treatment)) |>
  mutate(sample_id = as.character(sample_id))


################################################################################

################################################################################
## pig gut metadata (LEGUPLUS): repo KR9NH
leguplus_mapping = "gut_LEGUPLUS/mapping_file.csv"

fname = file.path(prjfolder, metadata_folder, leguplus_mapping)
leguplus_map = fread(fname)
leguplus_map$repo = "KR9NH"
leguplus_map$sample_id = paste(leguplus_map$repo, "sample", leguplus_map$`sample-id`, sep = "_")

leguplus_map <- leguplus_map |> 
  rename(`Sample ID` = sample_id, sample_id = `sample-id`, subject_id = animal, `Project ID` = repo) |>
  mutate(subject_id = as.character(subject_id), `Project Name` = "LEGUPLUS") |>
  select(-c(timepoint, sex, box, treatment, experiment, group)) |>
  mutate(sample_id = as.character(sample_id))


################################################################################


## DEEP MICRO CORE: GLOBAL METADATA
metadata = fread(file.path(prjfolder, conf_file))

metadata |> filter(`Project ID` == "PRJNA1103402", Tissue == "milk") |> nrow()
sum(leguplus_map$`Sample ID` %in% metadata$`Sample ID`)


bind_rows(rab_sub_160, rab_sub_219, casco_sub, farminn_map, rab_map_gut,
          rab_sub_rumen, morgoat_map, leguplus_map) |>
  nrow()
