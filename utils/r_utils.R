# R Utility Functions for Mixed-Effects Models Analysis
# =========================================================
# This file contains helper functions used in R_MEMs.ipynb and R_MEMs_Supplementary.ipynb
# Source this file with: source("utils/r_utils.R")

# -------------------------
# Data Loading & Preprocessing
# -------------------------

#' Load and preprocess DFA/RMS data for individual models
#'
#' @param config Study configuration list
#' @return Preprocessed dataframe
load_individual_data <- function(config) {

  # Load data
  dfa_df <- read.csv(config$dfa_file, check.names = FALSE)

  # Map a subject-like column if 'subject' is missing (handles Study 2 'Role')
  subj_candidates <- c("subject", "Role", "role")
  hit <- intersect(subj_candidates, names(dfa_df))
  if (length(hit) && !"subject" %in% names(dfa_df)) {
    #message("Using '", hit[1], "' as subject for ", config$study_id)
    dfa_df$subject <- dfa_df[[hit[1]]]
  }

  # Base mutation (common to both studies)
  dfa_df2 <- dfa_df %>%
    mutate(
      pair = factor(pair),
      environment = factor(environment, levels = config$environments),
      environment_num = recode(environment, !!!config$spl_map) %>% as.numeric(),
      environment_cent = scale(environment_num, scale = FALSE)[, 1],
      oirs_cent = scale(oirs, center = TRUE, scale = FALSE)
    )

  # Factor subject if present
  if ("subject" %in% names(dfa_df2)) {
    dfa_df2 <- dfa_df2 %>% mutate(subject = factor(subject))
  }

  # Add condition if present (Study 1)
  if (config$has_condition && "condition" %in% names(dfa_df2)) {
    dfa_df2 <- dfa_df2 %>%
      mutate(condition = factor(condition, levels = c("sitting", "standing")))
  }

  # Collapse across window indexes
  group_vars <- c("pair", "environment", "environment_num", "environment_cent", "oirs", "oirs_cent")
  if ("subject" %in% names(dfa_df2)) group_vars <- c(group_vars, "subject")
  if (config$has_condition && "condition" %in% names(dfa_df2)) group_vars <- c(group_vars, "condition")

  dfa_df2 <- dfa_df2 %>%
    group_by(across(all_of(group_vars))) %>%
    summarise(
      mean_alpha = mean(head_mag_alpha, na.rm = TRUE),
      mean_rms = mean(head_mag_rms, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(
      mean_alpha_cent = scale(mean_alpha, scale = FALSE),
      mean_rms_cent = scale(mean_rms, scale = FALSE),
      mean_rms_log = log(mean_rms),
      study = config$study_id
    )

  return(dfa_df2)
}

#' Load and preprocess cross-correlation data for dyadic models
#'
#' @param config Study configuration list
#' @return Preprocessed dataframe
load_dyadic_data <- function(config) {
  
  # Load data
  cm_df <- read.csv(config$cc_file)
  
  # Reshape and prepare
  cm_df2 <- cm_df %>%
    rename(
      rms_corr_pair = rms_corr,
      rms_corr_z_pair = rms_corr_z,
      alpha_corr_pair = alpha_corr,
      alpha_corr_z_pair = alpha_corr_z
    ) %>%
    pivot_longer(
      cols = c(rms_corr_pair, rms_corr_z_pair,
               alpha_corr_pair, alpha_corr_z_pair,
               rms_corr_stimulus, rms_corr_z_stimulus,
               alpha_corr_stimulus, alpha_corr_z_stimulus),
      names_to = c(".value", "corr_type"),
      names_pattern = "((?:rms|alpha)_corr(?:_z)?)_(pair|stimulus)"
    )
  
  # Factor levels and centering
  cm_df2 <- cm_df2 %>%
    # Filter out rows with invalid/empty pair_type before converting to factor
    filter(!is.na(pair_type) & pair_type != "") %>%
    mutate(
      pair = factor(pair),
      environment = factor(environment, levels = config$environments),
      pair_type = factor(pair_type, levels = c("pseudo", "actual")),
      corr_type = factor(corr_type, levels = c("pair", "stimulus")),
      oirs_cent = scale(oirs, center = TRUE, scale = FALSE),
      environment_num = recode(environment, !!!config$spl_map) %>% as.numeric(),
      environment_cent = scale(environment_num, scale = FALSE)[, 1],
      study = config$study_id
    )
  
  # Add condition if present (Study 1)
  if (config$has_condition && "condition" %in% names(cm_df2)) {
    cm_df2 <- cm_df2 %>%
      mutate(condition = factor(condition, levels = c("sitting", "standing")))
  }
  
  return(cm_df2)
}

# -------------------------
# EMM Extraction & SPL Mapping
# -------------------------

#' Convert EMM predictions to SPL scale
#'
#' @param emm_df Dataframe from emmeans()
#' @param config Study configuration list
#' @param ref_data Original data (for computing mean)
#' @return EMM dataframe with environment_spl column
map_emm_to_spl <- function(emm_df, config, ref_data) {
  mean_env <- mean(ref_data$environment_num, na.rm = TRUE)
  
  emm_df %>%
    mutate(
      environment_num = environment_cent + mean_env,
      # environment_num is already in SPL scale (e.g., 53.0, 63.3, 71.7, etc.)
      # so environment_spl is just environment_num itself
      environment_spl = environment_num
    )
}

#' Summarize raw data by environment (and condition if applicable)
#'
#' @param data Raw dataframe
#' @param config Study configuration
#' @param var Variable to summarize (e.g., "mean_alpha", "mean_rms")
#' @return Summary dataframe with CI
summarize_by_environment <- function(data, config, var = "mean_alpha") {
  group_vars <- "environment"
  if (config$has_condition && "condition" %in% names(data)) {
    group_vars <- c(group_vars, "condition")
  }
  
  data %>%
    filter(!is.na(.data[[var]]) & !is.nan(.data[[var]])) %>%
    group_by(across(all_of(group_vars))) %>%
    summarise(
      n = n(),
      mean_val = mean(.data[[var]], na.rm = TRUE),
      sd_val = sd(.data[[var]], na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(
      mean_y = mean_val,
      se_y = sd_val / sqrt(n),
      lower_ci = mean_val - 1.96 * se_y,
      upper_ci = mean_val + 1.96 * se_y,
      environment_spl = config$spl_map[as.character(environment)]
    )
}
