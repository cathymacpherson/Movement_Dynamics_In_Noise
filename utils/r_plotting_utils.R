# R Plotting Utility Functions for Mixed-Effects Models Analysis
# ================================================================
# This file contains plotting helper functions used in R_MEMs.ipynb and R_MEMs_Supplementary.ipynb
# Source this file with: source("utils/r_plotting_utils.R")
#
# Required packages: tidyverse, ggplot2, patchwork

# -------------------------
# Continuous Plotting Functions
# -------------------------

#' Create a continuous plot (environment_spl vs. outcome)
#'
#' @param summary_df Raw data summary
#' @param emm_df EMM predictions with environment_spl
#' @param config Study configuration
#' @param ylabel Y-axis label
#' @param title Plot title
#' @param colors Color scheme (named vector)
#' @param ylim Optional y-axis limits as c(min, max)
#' @param ybreaks Optional explicit y-axis breaks (tick positions)
#' @return ggplot object
plot_continuous_by_spl <- function(summary_df, emm_df, config, 
                                    ylabel = "Outcome", 
                                    title = NULL,
                                    colors = c("#003f5c", "#ffa600"),
                                    ylim = NULL,
                                    ybreaks = NULL) {
  
  # Determine if we have condition variable
  has_cond <- "condition" %in% names(summary_df)
  
  p <- ggplot()
  
  if (has_cond) {
    # Plot with condition (Study 1)
    p <- p +
      geom_errorbar(
        data = summary_df,
        aes(x = environment_spl, ymin = lower_ci, ymax = upper_ci, color = condition, group = condition),
        width = 1, linewidth = 1, alpha = 1,
        position = position_dodge(width = 2)
      ) +
      geom_point(
        data = summary_df,
        aes(x = environment_spl, y = mean_y, color = condition, group = condition),
        size = 2, alpha = 1,
        position = position_dodge(width = 2)
      ) +
      geom_ribbon(
        data = emm_df,
        aes(x = environment_spl, ymin = lower.CL, ymax = upper.CL, 
            fill = condition, group = condition),
        alpha = 0.15,
        position = position_dodge(width = 2)
      ) +
      geom_line(
        data = emm_df,
        aes(x = environment_spl, y = emmean, color = condition, group = condition),
        linewidth = 1, linetype = "dashed", alpha = 1,
        position = position_dodge(width = 2)
      ) +
      scale_fill_manual(values = colors, name = "Condition") +
      scale_color_manual(values = colors, name = "Condition")
  } else {
    # Plot without condition (Study 2)
    p <- p +
      geom_errorbar(
        data = summary_df,
        aes(x = environment_spl, ymin = lower_ci, ymax = upper_ci),
        width = 1, linewidth = 1, alpha = 1, color = colors[1]
      ) +
      geom_point(
        data = summary_df,
        aes(x = environment_spl, y = mean_y),
        size = 2, alpha = 1, color = colors[1]
      ) +
      geom_ribbon(
        data = emm_df,
        aes(x = environment_spl, ymin = lower.CL, ymax = upper.CL),
        fill = colors[1], alpha = 0.15
      ) +
      geom_line(
        data = emm_df,
        aes(x = environment_spl, y = emmean),
        color = colors[1], linewidth = 1, linetype = "dashed", alpha = 1
      )
  }
  
  # Common aesthetics
  p <- p +
    scale_x_continuous(
      breaks = seq(config$spl_range[1], config$spl_range[2], by = 5),
      labels = paste0(seq(config$spl_range[1], config$spl_range[2], by = 5)),
      limits = config$spl_range,
      expand = expansion(mult = 0)
    ) +
    scale_y_continuous(
      labels = function(x) sprintf("%.2f", x),
      limits = ylim,
      breaks = ybreaks,
      n.breaks = if (is.null(ybreaks)) 5 else NULL,
      expand = c(0, 0)
    ) +
    labs(x = "Background noise level (dB SPL)", y = ylabel) +
    theme_classic(base_size = 16) +
    theme(
      axis.text = element_text(size = 15),
      axis.title = element_text(size = 15),
      axis.title.x = element_text(margin = margin(t = 16)),
      aspect.ratio = 0.9,
      legend.position = "bottom",
      legend.title = element_text(size = 15),
      legend.text = element_text(size = 15)
    )
  
  if (!is.null(title)) {
    p <- p + ggtitle(title)
  }
  
  return(p)
}

# -------------------------
# Categorical Plotting Functions
# -------------------------

#' Create a categorical plot for pair type comparison
#'
#' @param raw_data Collapsed raw data (per pair × pair_type)
#' @param emm_df EMM estimates with CI (must have columns: pair_type, emmean, lower.CL, upper.CL)
#' @param variable_name Variable name for grouping (must include 'pair_type')
#' @param ylabel Y-axis label
#' @param ylim_min Minimum y-axis limit
#' @param ylim_max Maximum y-axis limit
#' @param output_file Optional output filename
#' @return ggplot object
plot_pair_type_categorical <- function(raw_data, emm_df, variable_name, 
                                       ylabel, ylim_min = NULL, ylim_max = NULL,
                                       output_file = NULL) {
  
  p <- ggplot() +
    # Raw data points
    geom_point(
      data = raw_data,
      aes(x = .data[[variable_name]], y = value, color = .data[[variable_name]]),
      alpha = 0.3, size = 2,
      position = position_jitter(width = 0.1, seed = 123)
    ) +
    # EMM points
    geom_point(
      data = emm_df,
      aes(x = .data[[variable_name]], y = emmean, color = .data[[variable_name]]),
      size = 4
    ) +
    # EMM error bars
    geom_errorbar(
      data = emm_df,
      aes(x = .data[[variable_name]], ymin = lower.CL, ymax = upper.CL, 
          color = .data[[variable_name]]),
      width = 0.2, linewidth = 0.8
    ) +
    scale_color_manual(
      values = c("pseudo" = "#2E86AB", "actual" = "#eeaf28ff"),
      labels = c("Pseudo", "Actual"),
      name = "Pair type",
      na.translate = FALSE
    ) +
    scale_x_discrete(drop = TRUE) +  # Drop unused factor levels from x-axis
    scale_y_continuous(
      limits = c(ylim_min, ylim_max),
      labels = function(x) sprintf("%.2f", x),
      expand = c(0, 0)
    ) +
    labs(
      x = "Pair type",
      y = ylabel
    ) +
    coord_cartesian(clip = "off") +
    theme_classic(base_size = 16) +
    theme(
      axis.text = element_text(size = 15),
      axis.title = element_text(size = 15),
      axis.title.x = element_text(margin = margin(t = 16)),
      aspect.ratio = 0.9,
      legend.position = "none"
    )
  
  # Save if filename provided
  if (!is.null(output_file)) {
    ggsave(output_file, p, width = 7, height = 6, dpi = 600)
  }
  
  return(p)
}

#' Helper function to create pair type categorical plots with data preparation
#'
#' @param dyad_data Filtered dyadic data (e.g., cm_df1_dyad)
#' @param value_var Variable to average (e.g., "alpha_corr_z" or "rms_corr_z")
#' @param emm_df EMM estimates with CI
#' @param ylabel Y-axis label
#' @param ylim_min Minimum y-axis limit
#' @param ylim_max Maximum y-axis limit
#' @param output_file Output filename
#' @return ggplot object
create_pair_type_plot <- function(dyad_data, value_var, emm_df, 
                                   ylabel, ylim_min = NULL, ylim_max = NULL,
                                   output_file) {
  
  # Collapse raw data (per pair × pair_type, averaging over condition if present)
  raw_data <- dyad_data %>%
    group_by(pair, pair_type) %>%
    summarise(value = mean(.data[[value_var]], na.rm = TRUE), .groups = "drop") %>%
    filter(!is.na(pair_type)) %>%  # Remove rows where pair_type is NA
    droplevels()  # Drop unused factor levels
  
  # Create plot using helper function
  p <- plot_pair_type_categorical(
    raw_data = raw_data,
    emm_df = emm_df,
    variable_name = "pair_type",
    ylabel = ylabel,
    ylim_min = ylim_min,
    ylim_max = ylim_max,
    output_file = NULL
  )
  
  return(p)
}

# -------------------------
# Continuous Pair Type Plots
# -------------------------

#' Helper function to create continuous pair type plots with facets
#'
#' @param dyad_data Filtered dyadic data (e.g., cm_df1_dyad)
#' @param value_var Variable to plot (e.g., "alpha_corr_z" or "rms_corr_z")
#' @param emm_df EMM predictions dataframe
#' @param study_config Study configuration list (for spl_map)
#' @param ylabel Y-axis label
#' @param has_condition Whether study has condition variable (Study 1 = TRUE, Study 2 = FALSE)
#' @param x_breaks X-axis break values (e.g., seq(45, 100, by = 10))
#' @param x_limits X-axis limits (e.g., c(45, 100))
#' @param y_limits Y-axis limits (optional)
#' @param output_file Output filename
#' @return ggplot object
create_continuous_pair_type_plot <- function(dyad_data, value_var, emm_df, 
                                              study_config, ylabel, 
                                              has_condition = TRUE,
                                              x_breaks = seq(45, 100, by = 10),
                                              x_limits = c(45, 100),
                                              y_limits = NULL,
                                              output_file = NULL) {
  
  spl_map <- study_config$spl_map
  
  # Prepare raw data summary
  if (has_condition) {
    # Study 1: group by environment, condition, pair_type
    cm_summary <- dyad_data %>%
      filter(!is.na(.data[[value_var]]), !is.na(pair_type)) %>%
      group_by(environment, condition, pair_type) %>%
      summarise(
        n = n(),
        mean_val = mean(.data[[value_var]], na.rm = TRUE),
        sd_val = sd(.data[[value_var]], na.rm = TRUE),
        .groups = "drop"
      ) %>%
      mutate(
        se_val = sd_val / sqrt(n),
        lower_ci = mean_val - 1.96 * se_val,
        upper_ci = mean_val + 1.96 * se_val,
        env_spl = spl_map[as.character(environment)],
        cond = recode(as.character(condition),
                      "sitting" = "Sitting",
                      "standing" = "Standing") %>%
               factor(levels = c("Sitting", "Standing"))
      )
    
    # Prepare EMM predictions
    emm_plot_df <- emm_df %>%
      mutate(
        cond = recode(as.character(condition),
                      "sitting" = "Sitting",
                      "standing" = "Standing") %>%
               factor(levels = c("Sitting", "Standing")),
        env_spl = environment_spl
      ) %>%
      filter(!is.na(pair_type))
    
    # Create plot with condition
    p <- ggplot() +
      geom_errorbar(
        data = cm_summary,
        aes(x = env_spl, ymin = lower_ci, ymax = upper_ci, color = cond),
        width = 1, linewidth = 0.8, alpha = 1,
        position = position_dodge(width = 2)
      ) +
      geom_point(
        data = cm_summary,
        aes(x = env_spl, y = mean_val, color = cond),
        size = 2, alpha = 1,
        position = position_dodge(width = 2)
      ) +
      geom_ribbon(
        data = emm_plot_df,
        aes(x = env_spl, ymin = lower.CL, ymax = upper.CL, fill = cond, group = cond),
        alpha = 0.15
      ) +
      geom_line(
        data = emm_plot_df,
        aes(x = env_spl, y = emmean, color = cond, group = cond),
        linewidth = 1, linetype = "dashed"
      ) +
      scale_color_manual(
        values = c("Sitting" = "#003f5c", "Standing" = "#ffa600"),
        name = "Condition"
      ) +
      scale_fill_manual(
        values = c("Sitting" = "#003f5c", "Standing" = "#ffa600"),
        name = "Condition"
      )
    
  } else {
    # Study 2: group by environment, pair_type only
    cm_summary <- dyad_data %>%
      filter(!is.na(.data[[value_var]]), !is.na(pair_type)) %>%
      group_by(environment, pair_type) %>%
      summarise(
        n = n(),
        mean_val = mean(.data[[value_var]], na.rm = TRUE),
        sd_val = sd(.data[[value_var]], na.rm = TRUE),
        .groups = "drop"
      ) %>%
      mutate(
        se_val = sd_val / sqrt(n),
        lower_ci = mean_val - 1.96 * se_val,
        upper_ci = mean_val + 1.96 * se_val,
        env_spl = spl_map[as.character(environment)]
      )
    
    # Prepare EMM predictions
    emm_plot_df <- emm_df %>%
      mutate(env_spl = environment_spl) %>%
      filter(!is.na(pair_type))
    
    # Create plot without condition
    p <- ggplot() +
      geom_errorbar(
        data = cm_summary,
        aes(x = env_spl, ymin = lower_ci, ymax = upper_ci),
        width = 1, linewidth = 0.8, alpha = 1, color = "#003f5c"
      ) +
      geom_point(
        data = cm_summary,
        aes(x = env_spl, y = mean_val),
        size = 2, alpha = 1, color = "#003f5c"
      ) +
      geom_ribbon(
        data = emm_plot_df,
        aes(x = env_spl, ymin = lower.CL, ymax = upper.CL),
        fill = "#003f5c", alpha = 0.15
      ) +
      geom_line(
        data = emm_plot_df,
        aes(x = env_spl, y = emmean),
        color = "#003f5c", linewidth = 1, linetype = "dashed"
      )
  }
  
  # Add common elements
  p <- p +
    scale_x_continuous(
      breaks = x_breaks,
      labels = x_breaks,
      limits = x_limits,
      expand = expansion(mult = 0.02)
    ) +
    facet_wrap(
      ~ pair_type,
      labeller = labeller(
        pair_type = c(actual = "Actual", pseudo = "Pseudo")
      )
    ) +
    labs(
      x = "Background noise level (dB SPL)",
      y = ylabel
    ) +
    coord_cartesian(ylim = y_limits, clip = "off") +
    theme_classic(base_size = 15) +
    theme(
      strip.background = element_blank(),
      strip.text = element_text(size = 15, face = "bold"),
      panel.spacing = unit(1.2, "lines"),
      axis.text = element_text(size = 15),
      axis.title = element_text(size = 15),
      axis.title.x = element_text(margin = margin(t = 16)),
      aspect.ratio = 0.7,
      legend.position = "bottom",
      legend.title = element_text(size = 15),
      legend.text = element_text(size = 15)
    )
  # Save (optional)
if (!is.null(output_file) && nzchar(output_file)) {
  ggsave(filename = output_file, plot = p, width = 10, height = 5, dpi = 600)
}

  return(p)
}

# -------------------------
# Combined Study Plots
# -------------------------

#' Combine two study plots side-by-side with shared legend
#'
#' @param plot1 First plot (Study 1)
#' @param plot2 Second plot (Study 2)
#' @param filename Output filename (with path)
#' @return Combined patchwork plot object
combine_study_plots <- function(plot1, plot2, filename) {
  
  # Modify plots for combined figure
  p1_mod <- plot1 + 
    ggtitle("Study 1") +
    theme(
      plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
      plot.margin = margin(5, 15, 2, 5),  # Increased right margin from 2 to 15
      legend.position = "none"
    )
  
  p2_mod <- plot2 + 
    ggtitle("Study 2") +
    labs(y = NULL) +  # Remove y-axis label from second plot
    theme(
      plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
      plot.margin = margin(5, 5, 2, 15),  # Increased left margin from 2 to 15
      legend.position = "none"
    )
  
  # Combine with shared legend
  p_combined <- (p1_mod | p2_mod) +
    plot_layout(guides = "collect") &
    theme(
      legend.position = "none"
    )
  
  # Save
  ggsave(filename, p_combined, width = 12, height = 6, dpi = 600)
  
  return(p_combined)
}

# -------------------------
# OIRS Plotting Functions
# -------------------------

#' Plot main effect of predictor on OIRs
#'
#' Generates EMM predictions directly without requiring env_mapping.
#' Plots predicted OIRs across a continuous predictor with 95% CI ribbon.
#'
#' @param model The fitted model (glmmTMB negative binomial)
#' @param data Data frame used in the model
#' @param predictor_cent Name of the centered predictor variable (string)
#' @param predictor_raw Name of the raw (uncentered) predictor variable (string)
#' @param xlabel X-axis label (can be expression() for Greek letters)
#' @param ylim_max Maximum y-axis limit
#' @param ybreaks Y-axis break step size (e.g., 2, 4, 5)
#' @param cap Optional numeric cap for raw points (visualisation only). If NULL, no cap is applied.
#' @param output_file Optional path to save the plot (default = NULL)
#' @return A ggplot object
#' @export
plot_oirs_main_effect <- function(model, data, predictor_cent, predictor_raw,
                                  xlabel, ylim_max, ybreaks = 5, xlim = NULL,
                                  cap = NULL, output_file = NULL) {

  # -------------------------
  # Safety check for cap
  # -------------------------
  if (!is.null(cap) && (!is.numeric(cap) || length(cap) != 1 || is.na(cap) || cap <= 0)) {
    stop("cap must be NULL or a single positive number.")
  }

  # Get predictor range for predictions
  pred_range <- seq(
    min(data[[predictor_cent]], na.rm = TRUE),
    max(data[[predictor_cent]], na.rm = TRUE),
    length.out = 50
  )

  # Generate EMM predictions
  at_list <- list(pred_range)
  names(at_list) <- predictor_cent

  emm_pred <- as.data.frame(emmeans(
    model,
    as.formula(paste("~", predictor_cent)),
    at = at_list,
    type = "response",
    infer = c(TRUE, TRUE)
  ))

  # Map back to raw predictor values for plotting
  pred_mapping <- data %>%
    dplyr::select(dplyr::all_of(c(predictor_cent, predictor_raw))) %>%
    dplyr::distinct() %>%
    dplyr::arrange(.data[[predictor_cent]])

  # Interpolate raw values for the EMM predictions
  emm_pred[[predictor_raw]] <- approx(
    x = pred_mapping[[predictor_cent]],
    y = pred_mapping[[predictor_raw]],
    xout = emm_pred[[predictor_cent]]
  )$y

  # -------------------------
  # Visually cap raw OIRs for plotting only
  # -------------------------
  if (is.null(cap)) {
    data_plot <- data %>%
      dplyr::mutate(oirs_plot = oirs)
  } else {
    data_plot <- data %>%
      dplyr::mutate(oirs_plot = pmin(oirs, cap))
  }

  # -------------------------
  # Y-axis breaks & labels (show ">cap" on axis when capping)
  # -------------------------
  y_breaks <- seq(0, ylim_max, by = ybreaks)
  y_labels <- as.character(y_breaks)

  if (!is.null(cap)) {
    # Ensure cap is a labelled tick (insert if missing)
    if (!any(y_breaks == cap)) {
      y_breaks <- sort(unique(c(y_breaks, cap)))
      y_labels <- as.character(y_breaks)
    }
    y_labels[y_breaks == cap] <- paste0(">", cap)
  }

  # Create plot
  p <- ggplot() +
    geom_point(
      data = data_plot,
      aes(x = .data[[predictor_raw]], y = oirs_plot),
      size = 2, alpha = 0.25, color = "#003f5c"
    ) +
    geom_ribbon(
      data = emm_pred,
      aes(x = .data[[predictor_raw]], ymin = asymp.LCL, ymax = asymp.UCL),
      fill = "#003f5c", alpha = 0.2
    ) +
    geom_line(
      data = emm_pred,
      aes(x = .data[[predictor_raw]], y = response),
      color = "#003f5c", linewidth = 1.2
    ) +
    scale_y_continuous(
      limits = c(-0.5, ylim_max),
      breaks = y_breaks,
      labels = y_labels,
      expand = expansion(mult = c(0, 0.05)),
      name = "OIR count"
    ) +
    labs(x = xlabel) +
    coord_cartesian(xlim = xlim, clip = "off") +
    theme_classic(base_size = 15) +
    theme(
      axis.text.x = element_text(angle = 0, hjust = 0.5),
      axis.title.x = element_text(margin = margin(t = 15)),
      aspect.ratio = 0.8
    )

  # Print plot for inline display in notebooks
  print(p)

  # Save if requested
  if (!is.null(output_file)) {
    ggsave(output_file, p, width = 8, height = 6, dpi = 600)
  }

  return(invisible(p))
}

#' Plot simple main effect of predictor on OIRs (no environment interaction)
#'
#' @param model Fitted glmmTMB model
#' @param data Original data used for fitting
#' @param predictor_cent Name of centered predictor variable
#' @param predictor_raw Name of raw (uncentered) predictor variable
#' @param xlabel X-axis label
#' @param ylim_max Maximum y-axis limit
#' @param ybreaks Y-axis break interval
#' @param output_file Optional output filename
#' @return ggplot object
plot_oirs_simple_main_effect <- function(model, data, predictor_cent, predictor_raw, 
                                          xlabel, ylim_max, ybreaks = 5, 
                                          output_file = NULL) {
  # Filter data
  plot_data <- data %>%
    filter(!is.na(oirs) & !is.na(.data[[predictor_raw]]))
  
  # Generate EMM predictions (main effect only)
  emm_formula <- as.formula(paste("~", predictor_cent))
  at_list <- list(seq(
    min(data[[predictor_cent]], na.rm = TRUE),
    max(data[[predictor_cent]], na.rm = TRUE),
    length.out = 100
  ))
  names(at_list) <- predictor_cent
  
  emm_df <- as.data.frame(emmeans(
    model, emm_formula,
    at = at_list,
    type = "response",
    infer = c(TRUE, TRUE)
  ))
  
  # Back-transform to raw scale
  emm_df[[predictor_raw]] <- emm_df[[predictor_cent]] + mean(data[[predictor_raw]], na.rm = TRUE)
  
  # Create plot
  p <- ggplot() +
    geom_point(
      data = plot_data,
      aes(x = .data[[predictor_raw]], y = oirs),
      size = 2, alpha = 0.25, color = "#003f5c"
    ) +
    geom_ribbon(
      data = emm_df,
      aes(x = .data[[predictor_raw]], ymin = asymp.LCL, ymax = asymp.UCL),
      fill = "#003f5c", alpha = 0.15
    ) +
    geom_line(
      data = emm_df,
      aes(x = .data[[predictor_raw]], y = response),
      color = "#003f5c", linewidth = 1.2
    ) +
    scale_x_continuous(
      labels = function(x) sprintf("%.2f", x),
      expand = c(0, 0)
    ) +
    scale_y_continuous(
      limits = c(-0.5, ylim_max),
      breaks = seq(0, ylim_max, by = ybreaks),
      expand = expansion(mult = c(0, 0.05)),
      name = "Predicted count of OIRs"
    ) +
    labs(x = xlabel, y = "Predicted count of OIRs") +
    theme_classic(base_size = 16) +
    coord_cartesian(clip = "off") +
    theme(
      axis.title.x = element_text(margin = margin(t = 16)),
      aspect.ratio = 0.8,
      legend.position = "none"
    )
  
  print(p)
  
  # Save if output file specified
  if (!is.null(output_file)) {
    ggsave(output_file, p, width = 7, height = 6, dpi = 600)
  }
  
  return(p)
}

#' Plot OIRs by continuous predictor with environment interaction
#'
#' Creates a faceted plot showing predicted OIRs across a continuous predictor
#' (e.g., complexity matching or RMS correlation), with separate lines for each
#' background noise environment. Supports both Study 1 (with condition facets)
#' and Study 2 (no condition).
#'
#' @param model Fitted glmmTMB model
#' @param data Original data used for fitting
#' @param predictor_cent Name of centered predictor variable
#' @param predictor_raw Name of raw (uncentered) predictor variable
#' @param env_mapping Data frame containing environment and environment_cent
#' @param has_condition Logical; whether the model includes condition (TRUE for Study 1)
#' @param env_cols Optional named vector of colours for environments. If NULL, defaults are chosen.
#' @param env_labels Optional named vector of labels for environments. If NULL, defaults are chosen.
#' @param xlabel X-axis label
#' @param cap Optional numeric cap for raw OIR values (visualisation only). If NULL, no capping is applied.
#' @param x_limits Optional x-axis limits as c(min, max). If NULL, ggplot chooses.
#' @param ybreaks Optional y-axis break interval. If NULL, breaks are chosen automatically.
#' @param ylim_max Optional upper y-axis limit. If NULL, limits are chosen automatically.
#' @param output_file Optional output filename
#'
#' @return ggplot object
plot_oirs_by_environment <- function(
  model, data,
  predictor_cent, predictor_raw,
  env_mapping, has_condition = TRUE,
  env_cols = NULL,
  env_labels = NULL,
  xlabel = "Predictor",
  cap = NULL,
  x_limits = NULL,
  ybreaks = NULL,
  ylim_max = NULL,
  output_file = NULL
) {

  # -------------------------
  # Safety checks
  # -------------------------
  if (!is.null(cap) && (!is.numeric(cap) || length(cap) != 1 || is.na(cap) || cap <= 0)) {
    stop("cap must be NULL or a single positive number.")
  }
  if (!is.null(x_limits) &&
      (!is.numeric(x_limits) || length(x_limits) != 2 || anyNA(x_limits) || x_limits[1] >= x_limits[2])) {
    stop("x_limits must be NULL or a numeric vector of length 2 with x_limits[1] < x_limits[2].")
  }
  if (!is.null(ybreaks) && (!is.numeric(ybreaks) || length(ybreaks) != 1 || is.na(ybreaks) || ybreaks <= 0)) {
    stop("ybreaks must be NULL or a single positive number.")
  }
  if (!is.null(ylim_max) && (!is.numeric(ylim_max) || length(ylim_max) != 1 || is.na(ylim_max) || ylim_max <= 0)) {
    stop("ylim_max must be NULL or a single positive number.")
  }

  # -----------------------------
  # 1. Get environment levels
  # -----------------------------
  env_levels <- env_mapping %>% dplyr::pull(environment_cent)

  predictor_seq <- seq(
    min(data[[predictor_cent]], na.rm = TRUE),
    max(data[[predictor_cent]], na.rm = TRUE),
    length.out = 50
  )

  at_list <- list()
  at_list[[predictor_cent]] <- predictor_seq
  at_list$environment_cent <- env_levels

  # -------------------------
  # Default environment colours & labels (if not supplied)
  # -------------------------
  if (is.null(env_cols) || is.null(env_labels)) {

    envs <- env_mapping %>%
      dplyr::arrange(environment_cent) %>%
      dplyr::pull(environment)

    default_cols <- c(
      "Library"      = "#ffa600",
      "Living"       = "#ff764a",
      "Cafe"         = "#ef5675",
      "Train"        = "#bc5090",
      "FoodCourt"    = "#7a5195",
      "NoMusicParty" = "#374c80",
      "MusicParty"   = "#003f5c"
    )

    default_labels <- c(
      "Library"      = "Library (53.0)",
      "Living"       = "Living Room (63.3)",
      "Cafe"         = "Cafe (71.7)",
      "Train"        = "Train Station (77.1)",
      "FoodCourt"    = "Food Court (79.6)",
      "NoMusicParty" = "Party (No Music, 85.0)",
      "MusicParty"   = "Party (With Music, 92.0)"
    )

    default_cols_s2 <- c(
      "Office" = "#ffa600",
      "Cafe"   = "#ef5675",
      "Food"   = "#7a5195",
      "Party"  = "#003f5c"
    )

    default_labels_s2 <- c(
      "Office" = "Office (60.0)",
      "Cafe"   = "Cafe (70.0)",
      "Food"   = "Food (80.0)",
      "Party"  = "Party (With Music, 87.5)"
    )

    if (all(envs %in% names(default_cols))) {
      env_cols   <- default_cols[envs]
      env_labels <- default_labels[envs]
    } else if (all(envs %in% names(default_cols_s2))) {
      env_cols   <- default_cols_s2[envs]
      env_labels <- default_labels_s2[envs]
    } else {
      stop("Unknown environment labels: cannot assign colours automatically.")
    }
  }

  # -----------------------------
  # 2. Generate EMM predictions
  # -----------------------------
  if (has_condition) {
    emm_formula <- reformulate(c(predictor_cent, "condition", "environment_cent"))
  } else {
    emm_formula <- reformulate(c(predictor_cent, "environment_cent"))
  }

  emm_pred <- as.data.frame(
    emmeans::emmeans(
      model,
      specs = emm_formula,
      at = at_list,
      type = "response",
      infer = c(TRUE, TRUE)
    )
  )

  # -----------------------------
  # 3. Standardise predictor column
  # -----------------------------
  names(emm_pred)[names(emm_pred) == predictor_cent] <- "xpred"

  emm_pred <- dplyr::left_join(
    emm_pred,
    env_mapping %>% dplyr::select(environment, environment_cent),
    by = "environment_cent"
  ) %>%
    dplyr::mutate(group_var = environment)

  # -------------------------
  # 4. Plot-only capping of raw OIRs
  # -------------------------
  if (is.null(cap)) {
    data_plot <- data %>% dplyr::mutate(oirs_plot = oirs)
  } else {
    data_plot <- data %>% dplyr::mutate(oirs_plot = pmin(oirs, cap))
  }

  # -------------------------
  # 5. Y-axis breaks & labels (show ">cap" on axis when capping)
  # -------------------------
  if (is.null(ybreaks)) {
    y_breaks <- waiver()
    y_labels <- waiver()
  } else {
    ymax_for_breaks <- if (is.null(ylim_max)) max(data_plot$oirs_plot, na.rm = TRUE) else ylim_max
    y_breaks <- seq(0, ymax_for_breaks, by = ybreaks)
    y_labels <- as.character(y_breaks)

    if (!is.null(cap)) {
      if (!any(y_breaks == cap)) {
        y_breaks <- sort(unique(c(y_breaks, cap)))
        y_labels <- as.character(y_breaks)
      }
      y_labels[y_breaks == cap] <- paste0(">", cap)
    }
  }

  y_limits <- if (is.null(ylim_max)) c(-0.5, NA) else c(-0.5, ylim_max)

  if (!is.null(cap) && !is.null(ylim_max) && cap > ylim_max) {
    warning("cap is greater than ylim_max, so the '>cap' tick will not be visible.")
  }

  # -------------------------
  # 6. X-axis breaks (force endpoints, e.g., -0.6)
  # -------------------------
  if (is.null(x_limits)) {
    x_scale <- scale_x_continuous(expand = expansion(mult = c(0.02, 0.02)))
  } else {
    # Explicit x-axis breaks (e.g., every 0.2)
    x_step <- 0.2

    x_breaks <- seq(
      from = x_limits[1],
      to   = x_limits[2],
      by   = x_step
    )

    # guard against floating-point artefacts
    x_breaks <- round(x_breaks, 6)

    x_scale <- scale_x_continuous(
      limits = x_limits,
      breaks = x_breaks,
      labels = x_breaks,
      expand = expansion(mult = c(0, 0.02))
    )
  }

  # -----------------------------
  # 7. Plot
  # -----------------------------
  p <- ggplot() +
    geom_point(
      data = data_plot,
      aes(x = .data[[predictor_raw]], y = oirs_plot, color = environment),
      size = 2, alpha = 0.25
    ) +
    geom_ribbon(
      data = emm_pred,
      aes(
        x = xpred,
        ymin = asymp.LCL,
        ymax = asymp.UCL,
        fill = environment,
        group = group_var
      ),
      alpha = 0.15
    ) +
    geom_line(
      data = emm_pred,
      aes(
        x = xpred,
        y = response,
        color = environment,
        group = group_var
      ),
      linewidth = 1,
      alpha = 0.9
    ) +
    scale_color_manual(
      values = env_cols,
      labels = env_labels,
      name = "Background noise (dB SPL)"
    ) +
    scale_fill_manual(
      values = env_cols,
      labels = env_labels,
      name = "Background noise (dB SPL)"
    ) +
    scale_y_continuous(
      limits = y_limits,
      breaks = y_breaks,
      labels = y_labels,
      expand = expansion(mult = c(0, 0.05)),
      name = "OIR count"
    ) +
    x_scale +
    labs(
      x = xlabel,
      color = "Background noise",
      fill  = "Background noise"
    ) +
    coord_cartesian(clip = "off") +
    theme_classic(base_size = 15) +
    theme(
      axis.text = element_text(size = 15),
      axis.title = element_text(size = 15),
      axis.text.x = element_text(angle = 0, hjust = 0.5),
      axis.title.x = element_text(margin = margin(t = 15)),
      aspect.ratio = 0.8,
      legend.position = "right",
      legend.title = element_text(size = 14),
      legend.text = element_text(size = 12, lineheight = 0.9)
    )

  if (has_condition) {
    p <- p +
      facet_wrap(
        ~ condition,
        nrow = 1,
        labeller = labeller(condition = c("sitting" = "Sitting", "standing" = "Standing"))
      ) +
      theme(
        strip.background = element_blank(),
        strip.text = element_text(size = 15, face = "bold"),
        panel.spacing = unit(1.2, "lines")
      )
  }

  if (!is.null(output_file)) {
    ggsave(output_file, p, width = 10, height = 6, dpi = 600)
  }

  invisible(p)
}
