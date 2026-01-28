## SET-UP
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
    count_table = "Analysis/lasso/filtered_normalized_counts.RDS", ## biom format file (from the ampliseq pipeline)
    analysis_folder = "Analysis/lasso",
    conf_file = "merged_results/Metadata.csv",
    suffix = "cow_microbiomes",
    project = "deep_micro_core",
    target_column = "Tissue",
    subsampling = TRUE,
    split = 0.8,
    # sample_column = "sample",
    force_overwrite = FALSE
  ))
}

## READ THE DATA
writeLines(" - reading the data")
fname = file.path(config$prjfolder, config$count_table)
X <- readRDS(fname)

## convert to big matrix [TODO] Tania
# X = bigmemory::as.big.matrix(X)
# is.big.matrix(X)

## transpose matrix
writeLines(" - transposing the data matrix: OTUs from rows to columns")
tX = t(X)
print(paste("N. of samples is:", nrow(tX)))
print(paste("N. of OTU/ASV is:", ncol(tX)))

rm(X)
gc()

## random subset of columns (COMMENT/UNCOMMENT as needed)
if (config$subsampling) {

  print("subsampling columns")
  vec = sample(c(TRUE,FALSE), size = ncol(tX), replace = TRUE, prob = c(0.1,0.9))
  tX <- tX[,vec]
  print(paste("N. of OTU/ASV after subsampling is:", ncol(tX)))
}

## READ THE METADATA
writeLines(" - reading the metadata")
fname = file.path(config$repo, config$conf_file)
metadata = fread(fname)

sample_ids = rownames(tX)
tX <- as_tibble(tX)
tX$sampleID = sample_ids

temp <- select(metadata, c(`Sample ID`, !!config$target_column))
tX <- temp |> inner_join(tX, by = c(`Sample ID` = "sampleID"))
rm(temp)

## random subset of samples (COMMENT/UNCOMMENT as needed)
if (config$subsampling) {

  print("subsampling rows")
  tX <- tX |> slice_sample(prop = 0.5)
  print(paste("N. of samples after subsampling is:", nrow(tX)))
}

print("distribution of classes")
select(tX, !!config$target_column) |> pull() |> table() |> print()

#####################
## splitting the data
#####################
print("####################################################")
writeLines(" - splitting the data in training and test sets")

print(paste("The proportion of data for training is:", config$split))

dt_split <- initial_split(tX, strata = !!config$target_column, prop = config$split)
train_set <- training(dt_split)
test_set <- testing(dt_split)

print(paste("N. of training samples:", nrow(train_set)))
print(paste("N. of test samples:", nrow(test_set)))

## build a recipe for preprocessing
writeLines(" - preprocessing: remove non-informative variables, normalise numeric variables")
rec <- recipe(Tissue ~ ., data = train_set) %>%
  update_role(`Sample ID`, new_role = "ID") %>%
  step_zv(all_numeric(), -all_outcomes()) %>%
  step_normalize(all_numeric(), -all_outcomes())

print(rec)

train_prep <- rec %>%
  prep(strings_as_factors = FALSE)

print(train_prep)
temp <- juice(train_prep)

print("glimpse of training data before preprocessing")
print(train_set[1:10,4:7])

print("glimpse of training data after preprocessing")
print(temp[1:10,4:7])

rm(temp)

###############################################
## LASSO MODEL
###############################################
# lasso_spec <- multinom_reg(mode = "classification", penalty = 0.1, mixture = 1) %>%
#   set_engine("glmnet")
#
# print(lasso_spec)
#
# wf <- workflow() %>%
#   add_recipe(rec) %>%
#   add_model(lasso_spec)
#
# print(wf)
#
# lasso_fit <- wf %>%
#   fit(data = train_set)
#
# lasso_fit %>%
#   pull_workflow_fit() %>%
#   tidy()
#
# lasso_fit %>%
#   pull_workflow_fit() %>%
#   tidy() %>%
#   filter(estimate > 0 | estimate < 0)


## CROSS-VALIDATION
writeLines(" - make folds for cross-validation (hyperparameter tuning): 5 folds, 10 repeats")
dt_cv <- vfold_cv(train_set, v=5, repeats = 10, strata = !!config$target_column)

## mixture = 1 is LASSO!
tune_spec <- multinom_reg(penalty = tune(), mixture = 1) %>%
  set_engine("glmnet")

writeLines(" - select grid of values for the penaly hyperparameter Lambda")
lambda_grid <- grid_regular(penalty(), levels = 60, filter = penalty <= .15)
print(lambda_grid)

wf1 <- workflow() %>%
  add_recipe(rec) %>%
  add_model(tune_spec) ## remember: the model equation was specified in the recipe (top of this document)

doParallel::registerDoParallel()

writeLines(" - doing cross-validation for model fine-tuning (a bit pf patience here ... )")
lasso_grid <- tune_grid(
  wf1,
  resamples = dt_cv,
  grid = lambda_grid,
  metrics = metric_set(accuracy, kap, brier_class, mcc)
)

print("best models from fine-tuning")
lasso_grid %>%
  collect_metrics() |>
  arrange(desc(mean)) |>
  head(10) |>
  print()

p <- lasso_grid %>%
  collect_metrics() %>%
  ggplot(aes(penalty, mean, color = .metric)) +
  geom_errorbar(aes(
    ymin = mean - std_err,
    ymax = mean + std_err
  ),
  alpha = 0.5
  ) +
  geom_line(size = 1.5) +
  facet_wrap(~.metric, scales = "free", nrow = 2) +
  scale_x_log10() +
  theme(legend.position = "none")

# print(p)
fname = file.path(config$analysis_folder, "cv_results.png")
ggsave(filename = fname, plot = p, device = "png")

best_model <- lasso_grid %>%
  select_best(metric = "mcc")

print("best model from fine-tuning:")
print(best_model)

collect_metrics(lasso_grid) |>
  filter(penalty == best_model$penalty) |>
  print()

##################################
print("#####################")
writeLines(" - FINAL MODEL")
final_lasso <- finalize_workflow(
  wf1,
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

print("test performance of final model")
lr_res %>%
  collect_metrics() |>
  print()

print("confusion matrix")
lr_res %>% collect_predictions() %>%
  group_by(.pred_class, Tissue) %>%
  summarise(N=n()) %>%
  spread(key = ".pred_class", value = N) |>
  print()

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

p <- important_variables %>%
  ggplot(aes(x = Importance, y = Variable, fill = Sign)) +
  geom_col() +
  scale_x_continuous(expand = c(0, 0)) +
  labs(y = NULL)

# print(p)
fname = file.path(config$analysis_folder, "variable_importance.png")
ggsave(filename = fname, plot = p, device = "png")

print("DONE!!")
