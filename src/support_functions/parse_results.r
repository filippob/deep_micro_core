## SET-UP
library("ggplot2")
library("bigmemory")
library("tidyverse")
library("tidymodels")
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
    res_folder = "Analysis/lasso", ## biom format file (from the ampliseq pipeline)
    conf_file = "merged_results/Metadata.csv",
    taxonomy_file = "merged_results/export/taxonomy/taxonomy.tsv",
    suffix = "cow_microbiomes",
    project = "deep_micro_core",
    target_column = "Tissue",
    # sample_column = "sample",
    force_overwrite = FALSE
  ))
}


## READ THE RESULTS
writeLines(" - reading results")
print("confusion matrix")
fname = file.path(config$prjfolder, config$res_folder, "confusion_matrix.csv")
conf_mat <- fread(fname)

print("Rows: observations; column: predictions")
conf_mat |>
  spread(key = "prediction", value = "count")

writeLines(" - Accuracy")

N = sum(conf_mat$count, na.rm = TRUE)
accuracy = conf_mat |>
  filter(Tissue == prediction) |>
  summarise(correct = sum(count), accuracy = correct/N) |>
  pull(accuracy)

print(paste("Total accuracy:", accuracy))

writeLines(" - Cohen's kappa")
temp <- conf_mat |>
  spread(key = "prediction", value = "count") |>
  select(-Tissue)

N = sum(temp, na.rm = TRUE)
temp <- temp/N
temp[is.na(temp)] <- 0
temp

library("psych")
cohen.kappa(temp, n.obs = N)

writeLines(" - MCC")
temp <- conf_mat |>
  spread(key = "prediction", value = "count") |>
  select(-Tissue) |>
  as.matrix()

temp[is.na(temp)] <- 0
mltools::mcc(confusionM = temp)

print("#####################")
print("Important variables")

fname = file.path(config$prjfolder, config$res_folder, "important_variables.csv")
important_variables <- fread(fname)
fname = file.path(config$prjfolder, config$taxonomy_file)
taxonomy = fread(fname)

# important_variables$Variable %in% taxonomy$`Feature ID`
important_variables <- important_variables |>
  inner_join(taxonomy, by = c("Variable" = "Feature ID"))

important_variables <- separate(important_variables,
         col = Taxon,
         into = c("domain","phylum","class","order","family","genus","species","strain","score"),
         sep = ";")

important_variables = unite(data = important_variables, col = "taxon", c(order,family, genus, species), sep = "-")
important_variables$taxon = gsub("-*$","",important_variables$taxon)
important_variables = mutate(important_variables, taxon = fct_reorder(taxon, Importance))
important_variables = mutate(important_variables, Variable = fct_reorder(Variable, Importance))

p <- important_variables %>%
  ggplot(aes(x = Importance, y = Variable, fill = Sign)) +
  geom_col() +
  scale_y_discrete(labels = important_variables$taxon) +
  scale_x_continuous(expand = c(0, 0)) +
  labs(y = NULL) +
  theme(axis.text.y = element_text(size = 6)) +
  scale_fill_discrete(guide="none")


fname = file.path(config$res_folder, "variable_importance.png")
ggsave(filename = fname, plot = p, device = "png")

#######################
print("Selected coefficients from the lasso model")

fname = file.path(config$prjfolder, config$res_folder, "selected_variables.csv")
coeffs <- fread(fname)

coeffs <- coeffs |>
  inner_join(taxonomy, by = c("term" = "Feature ID"))

coeffs <- separate(coeffs,
                  col = Taxon,
                  into = c("domain","phylum","class","order","family","genus","species","strain","score"),
                  sep = ";")

coeffs = unite(data = coeffs, col = "taxon", c(order,family, genus, species), sep = "-")
coeffs$taxon = gsub("-*$","",coeffs$taxon)
coeffs = mutate(coeffs, taxon = fct_reorder(taxon, estimate))
coeffs = mutate(coeffs, Variable = fct_reorder(term, estimate))

print("DONE!")
