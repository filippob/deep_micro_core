## SET-UP
library("dplyr")
library("glmnet")
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
    tuned_model = "Analysis/lasso/fine_tuned_model.RDS",
    count_table = "Analysis/lasso/filtered_normalized_counts.RDS", ## biom format file (from the ampliseq pipeline)
    analysis_folder = "Analysis/lasso",
    conf_file = "merged_results/Metadata.csv",
    suffix = "cow_microbiomes",
    project = "deep_micro_core",
    tissue = "",
    species = "cow",
    target_column = "Tissue",
    subsampling = FALSE,
    split = 0.8,
    # sample_column = "sample",
    force_overwrite = FALSE
  ))
}

## READ THE DATA
writeLines(" - reading the data")
fname = file.path(config$prjfolder, config$count_table)
X <- readRDS(fname)

## READ THE MODEL
writeLines(" - reading the fine-tuned model")
fname = file.path(config$prjfolder, config$tuned_model)
tuned_model <- readRDS(fname)

print("best models from fine-tuning")
tuned_model %>%
  collect_metrics() |>
  arrange(desc(mean)) |>
  head(10) |>
  print()

p <- tuned_model %>%
  collect_metrics() %>%
  ggplot(aes(penalty, mean, color = .metric)) +
  geom_errorbar(aes(
    ymin = mean - std_err,
    ymax = mean + std_err
  ),
  alpha = 0.5
  ) +
  geom_line(linewidth = 1.5) +
  facet_wrap(~.metric, scales = "free", nrow = 2) +
  scale_x_log10() +
  theme(legend.position = "none")

print(p)

# print(p)
fname = file.path(config$analysis_folder, "cv_results.png")
ggsave(filename = fname, plot = p, device = "png")


## transpose matrix
writeLines(" - transposing the data matrix: OTUs from rows to columns")
tX = t(X)
print(paste("N. of samples is:", nrow(tX)))
print(paste("N. of OTU/ASV is:", ncol(tX)))

rm(X)
gc()

## READ THE METADATA
writeLines(" - reading the metadata")
fname = file.path(config$prjfolder, config$conf_file)
metadata = fread(fname)

print(paste("Selected tissue is:", config$tissue))
print(paste("Selected species is:", config$species))

if (config$tissue != "") metadata <- filter(metadata, Tissue == config$tissue)
if (config$species != "") metadata <- filter(metadata, `Species/Substrate` == config$species)

sample_ids = rownames(tX)
tX <- as_tibble(tX)
tX$sampleID = sample_ids

temp <- select(metadata, c(`Sample ID`, !!config$target_column))
tX <- temp |> inner_join(tX, by = c(`Sample ID` = "sampleID"))
rm(temp)

print("##############################################")
num_classes = select(tX, !!config$target_column) |> unique() |> pull() |> length()
print(paste("THE NUMBER OF CLASSES IS:", num_classes))
print("##############################################")

#####################
## splitting the data
#####################
writeLines(" - splitting the data in training and test sets")
print(paste("The proportion of data for training is:", config$split))

dt_split <- initial_split(tX, strata = !!config$target_column, prop = config$split)
train_set <- training(dt_split)
test_set <- testing(dt_split)

print(paste("N. of training samples:", nrow(train_set)))
print(paste("N. of test samples:", nrow(test_set)))

#### SELECTED MODEL ########
writeLines(" - selecting the best model from fine-tuning")
best_model <- tuned_model %>%
  select_best(metric = "mcc")

print("best model from fine-tuning:")
print(best_model)

collect_metrics(tuned_model) |>
  filter(penalty == best_model$penalty) |>
  print()

##################################
print("#####################")
writeLines(" - FINAL MODEL")

rec <- recipe(Tissue ~ ., data = train_set) %>%
  update_role(`Sample ID`, new_role = "ID") %>%
  step_zv(all_numeric(), -all_outcomes()) %>%
  step_normalize(all_numeric(), -all_outcomes()) %>%
  step_zv(all_numeric()) %>%
  step_nzv(all_numeric()) %>%
  step_corr(all_numeric(), threshold = 0.95)

print(rec)

## mixture = 1 is LASSO!
if (num_classes > 2) {
  
  tune_spec <- multinom_reg(mode = "classification", penalty = tune(), mixture = 1) %>%
    set_engine("glmnet")
} else {
  
  tune_spec <- logistic_reg(mode = "classification", penalty = tune(), mixture = 1) %>%
    set_engine("glmnet")
}

wf <- workflow() %>%
  add_recipe(rec) %>%
  add_model(tune_spec) 


final_lasso <- finalize_workflow(
  wf,
  best_model
)

print(final_lasso)

## TEST MODEL
print("train and then evaluate on test data")
lr_res <- last_fit(
  final_lasso,
  dt_split,
  metrics = metric_set(accuracy, kap, brier_class, mcc)
)

### GET MODEL COEFFICIENTS
writeLines(" - get model coefficients")
fitted_wf <- extract_workflow(lr_res)
fitted_model <- fitted_wf |> extract_fit_parsnip()
coef_tbl <- tidy(fitted_model)
coeffs = filter(coef_tbl, estimate != 0)

fname = file.path(config$analysis_folder, "selected_variables.csv")
fwrite(x = coeffs, file = fname, sep = ",")

writeLines(" - evaluate test performance")
print("test performance of final model")
lr_res %>%
  collect_metrics() |>
  print()

print("confusion matrix")
conf_mat <- lr_res %>% collect_predictions() %>%
  group_by(.pred_class, Tissue) %>%
  summarise(N=n()) %>%
  spread(key = ".pred_class", value = N)
  
print(conf_mat)

conf_mat <- conf_mat |> gather(key = "prediction", value = "count", -Tissue)

fname = file.path(config$analysis_folder, "confusion_matrix.csv")
fwrite(x = conf_mat, file = fname, sep = ",")

######################################
## Variable Importance
######################################
writeLines(" - extracting variable importance")
library("vip")

important_variables <- final_lasso %>%
  fit(train_set) %>%
  pull_workflow_fit() %>%
  vi(lambda = best_model$penalty) %>%
  mutate(
    Importance = abs(Importance),
    Variable = fct_reorder(Variable, Importance)
  ) %>%
  filter(Importance > 0)

print("most important variables")
print(head(important_variables))

fname = file.path(config$analysis_folder, "important_variables.csv")
fwrite(x = important_variables, file = fname, sep = ",")

p <- important_variables %>%
  ggplot(aes(x = Importance, y = Variable, fill = Sign)) +
  geom_col() +
  scale_x_continuous(expand = c(0, 0)) +
  labs(y = NULL)

# print(p)
fname = file.path(config$analysis_folder, "variable_importance.png")
ggsave(filename = fname, plot = p, device = "png")

print("DONE!!")
