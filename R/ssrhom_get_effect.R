#' Report an effect of interest
#'
#' @param res_obj Object returned by main function
#' @param stat One of \code{"mean"}, \code{"median"},
#' \code{"mean-diff"}, \code{"median-diff"},
#' \code{"lrr"}, \code{"lor"},
#' \code{"nap"}, \code{"tau"}, \code{"pem"}, \code{"smd-c"},
#' or \code{"smd-p"}.
#' `lrr` or log rate ratio is only computed when the outcome variable is
#' non-negative or has a minimum greater than 0.
#' `lor` or log odds ratio is only computed when the outcome variable falls
#' entirely in the 0-1 interval, inclusive of both 0 and 1.
#' @param interval Some quantile interval between 0 and 1
#' @param return_draws If TRUE, do not summarize the posterior samples.
#' If FALSE, summarize the posterior samples.
#' @return Returns dataset.
#' @export
ssrhom_get_effect <- function(
    res_obj, stat = "nap", interval = .95, return_draws = FALSE) {
  stat_list <- ssrhom_list_stats(table = FALSE)
  stat_list_real <- c(
    "mean_s", "median_s",
    "mean_diff", "median_diff",
    "log_mean_ratio",
    "log_odds_ratio",
    "nap", "tau", "pem", "smd_c", "smd_p"
  )

  if (!(stat %in% stat_list)) {
    statement <- paste(
      "`stat` must be one of:",
      paste0("\"", paste0(stat_list, collapse = ", \""), "\""),
      sep = "\n"
    )
    stop(statement)
  }

  which_stat <- which(stat_list == stat)

  stat_real <- stat_list_real[which_stat]

  check_tau_interval(interval, "interval")
  lower_lim <- (1 - interval) / 2 # nolint

  warmup <- res_obj$model@sim$warmup
  total_iter <- res_obj$model@sim$iter
  samples <- total_iter - warmup

  stat_post <- as.data.frame(res_obj$model, stat_real)

  var_names <- colnames(stat_post)
  case_label <- res_obj$stan_data_list$case_label
  if (stat %in% stat_list[1:2]) {
    case_id <- as.integer(
      gsub(",", "", regmatches(var_names, regexpr("\\d+,", var_names)))
    )
    var_names_split <- strsplit(var_names, "\\d+,")
    new_var_names <- sapply(seq_len(length(var_names_split)), function(i) {
      name <- var_names_split[[i]]
      which_pos <- as.integer(gsub("\\]", "", name[2]))
      paste0(
        stat, "[", case_label[case_id[i]], ",",
        c("Control", "Treatment")[which_pos], "]"
      )
    })
  } else if (stat %in% stat_list[3:11]) {
    case_id <- as.integer(
      regmatches(var_names, regexpr("\\d+", var_names))
    )
    var_names_split <- strsplit(var_names, "\\d+")
    new_var_names <- sapply(seq_len(length(var_names_split)), function(i) {
      name <- var_names_split[[i]]
      paste0(stat, "[", case_label[case_id[i]], name[2])
    })
  }
  colnames(stat_post) <- new_var_names

  n_iter <- nrow(stat_post)
  stat_post$.chain <- (seq_len(n_iter) - 1) %/% samples + 1
  stat_post$.iteration <- (seq_len(n_iter) - 1) %% samples + 1
  stat_post$.draw <- seq_len(n_iter)

  if (isTRUE(return_draws)) {
    return(stat_post)
  }

  stat_post_draws <- posterior::as_draws(stat_post)
  result <- posterior::summarise_draws(
    stat_post_draws,
    median = stats::median,
    sd = stats::sd,
    ~ posterior::quantile2(.x, probs = c(lower_lim, 1 - lower_lim)),
    posterior::default_convergence_measures()
  )

  return(result)
}
