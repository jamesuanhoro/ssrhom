#' User input checker
#' @returns Check user input
#' @inheritParams ssrhom_model_ab
#' @keywords internal
check_user_input <- function(
    data, grouping, condition, outcome, case, time) {
  dt <- generic_data_checks(
    data = data, grouping = grouping,
    condition = condition, outcome = outcome, case = case, time = time
  )
  generic_numeric_checks(dt = dt, outcome = outcome)
  dt$out <- as.numeric(dt[, outcome])

  return(dt)
}

#' Generic data checks
#' @return Data
#' @inheritParams ssrhom_model_ab
#' @keywords internal
generic_data_checks <- function(
    data, grouping, condition, outcome, case, time) {
  tryCatch(
    dt <- as.data.frame(data),
    error = function(e) {
      statement <- paste(
        "Could not make the object passed as data into a data.frame.",
        "Please check this object to be sure it is a dataset.",
        sep = "\n"
      )
      stop(statement)
    }
  )

  # variable names must be in data
  var_names <- colnames(dt)
  present_grouping <- grouping %in% var_names
  present_outcome <- outcome %in% var_names
  present_case <- case %in% var_names
  present_time <- time %in% var_names
  present_all <- present_grouping + present_outcome + present_case +
    present_time
  if (present_all < 4) {
    statement <- paste(
      "At least one of `grouping`, `outcome`, `case` and `time` is not",
      "among the variables in the dataset.",
      sep = "\n"
    )
    stop(statement)
  }

  tryCatch(
    dt <- stats::na.omit(dt[, c(grouping, outcome, case, time)]),
    error = function(e) {
      statement <- paste(
        "This is a strange one, for some reason, we cannot subset the",
        "dataset to the variables you provided even though both variables",
        "are in the dataset.",
        sep = "\n"
      )
      stop(statement)
    }
  )

  tryCatch(
    cond_char <- as.character(condition),
    error = function(e) {
      statement <- paste(
        "The value of `condition` could not be converted to text.",
        sep = "\n"
      )
      stop(statement)
    }
  )

  dt$treat <- as.integer(dt[, grouping] == cond_char)

  if (sum(dt$treat) == nrow(dt)) {
    statement <- paste(
      "All rows in the data were in the treatment group as identified ",
      "via `condition`. Check that `condition` was set correctly.",
      sep = "\n"
    )
    stop(statement)
  } else if (sum(dt$treat) == 0) {
    statement <- paste(
      "None rows in the data were in the treatment group as identified ",
      "via `condition`. Check that `condition` was set correctly.",
      sep = "\n"
    )
    stop(statement)
  }

  dt$case_label <- factor(dt[, case])
  dt$case_id <- as.integer(dt$case_label)

  if (max(dt$case_id) == 1) {
    statement <- paste(
      "There should be data from more than one case for analysis.",
      sep = "\n"
    )
    stop(statement)
  }

  tryCatch(
    sapply(dt[, time], is_positive_whole_number),
    error = function(e) {
      statement <- paste(
        "One or more values of `time` are not positive whole numbers.",
        sep = "\n"
      )
      stop(statement)
    }
  )

  dt$time_id <- dt[, time]

  return(dt)
}

#' Generic numeric checks
#' @param dt Modified form of original data
#' @return Fail if outcome is not numeric
#' @inheritParams ssrhom_model_ab
#' @keywords internal
generic_numeric_checks <- function(dt, outcome) {
  tryCatch(
    outcome_dt <- stats::na.omit(as.numeric(dt[, 2])),
    warning = function(e) {
      statement <- paste(
        "Check that the `outcome` variable contains numbers.",
        sep = " "
      )
      stop(statement)
    },
    error = function(e) {
      statement <- paste(
        "Check that the `outcome` variable contains numbers.",
        sep = " "
      )
      stop(statement)
    }
  )

  if (length(outcome_dt) != nrow(dt)) {
    statement <- paste(
      "When converting the `outcome` variable to numbers,",
      "some of the values resulted in missing data meaning that",
      "not all values were numbers.",
      sep = "\n"
    )
    stop(statement)
  }

  return(NULL)
}

#' Create Stan data list object
#' @return Data list object for Stan
#' @param dt Modified form of original data
#' @inheritParams ssrhom_model_ab
#' @keywords internal
create_dat_list <- function(dt, increase = TRUE) {
  dl <- list(
    n = nrow(dt), # number of rows of data
    n_case = max(dt$case_id), # number of cases
    case_label = levels(dt$case_label), # case labels
    n_time = max(dt$time_id), # maximum number of timepoints
    case_id = dt$case_id, # case ID variable (integers)
    time_id = dt$time_id, # time variable (can be continuous)
    y_s = unique(sort(dt$out)), # unique data points in outcome
    y_ord = as.integer(ordered(dt$out)), # outcome transformed to ranks
    treat = dt$treat # treatment phase indicator
  )
  # count of each unique values
  dl$count_levs <- as.integer(table(dl$y_ord))
  # number of unique values
  dl$n_ord <- length(dl$count_levs)

  gm_count <- stats::aggregate(
    out ~ case_id + treat, dt, length
  )
  gm_count <- gm_count[order(gm_count$case_id, gm_count$treat), ]

  dl$n_count <- nrow(gm_count) # number of case-phases
  dl$count <- gm_count$out # number of data points computed in gm_count
  dl$increase <- as.integer(!isFALSE(increase))
  return(dl)
}

#' Positive whole number tester
#' @param input Candidate percentage
#' @return Fail if not within 0 and 1
#' @keywords internal
check_tau_interval <- function(input, descriptor) {
  res <- input > 0 && input < 1
  if (!isTRUE(res)) {
    statement <- paste(
      descriptor, "is not a number between 0 and 1.",
      sep = " "
    )
    stop(statement)
  }
}

#' Whole number tester
#' @param input Candidate whole number
#' @return Fail if not whole number
#' @keywords internal
is_whole_number <- function(input) {
  res <- input %% 1 == 0
  if (!isTRUE(res)) {
    stop()
  }
}

#' Positive whole number tester
#' @param input Candidate whole number
#' @return Fail if not non-negative whole number
#' @keywords internal
is_positive_whole_number <- function(input) {
  is_whole_number(input)
  if (input <= 0) {
    stop()
  }
}

#' Function to list out effects computed by package.
#'
#' @param table If TRUE, report statistics in a table describing
#' each statistic.
#' If FALSE, simply return statistics as a list.
#' @export
ssrhom_list_stats <- function(table = TRUE) {
  stats <- c(
    "mean", "median",
    "mean-diff", "median-diff",
    "log-mean-ratio",
    "nap", "tau", "pem", "smd_c", "smd_p"
  )
  if (isFALSE(table)) {
    return(stats)
  }
  stats_exp <- c(
    "mean of each case in both phases",
    "median of each case in both phases",
    "mean difference between phases by case",
    "median difference between phases by case",
    "log-ratio of means by case",
    "non-overlap of all pairs by case",
    "A linear transformation of NAP",
    "Proportion of treatment cases exceeding control cases by case",
    "Standardized mean difference using control SD as standardizer by case",
    "Standardized mean difference using pooled SD as standardizer by case"
  )
  pad_str <- function(str) {
    str_len <- length(strsplit(str, "")[[1]])
    rem_len <- 20 - str_len
    return(paste0(str, paste0(rep(" ", rem_len), collapse = "")))
  }
  stats_pad <- sapply(stats, pad_str)
  desc_txt <- c(
    paste0(stats_pad, ":\t", stats_exp),
    "\nIf model was called with `increase = FALSE`, then effects are reversed."
  )
  return(writeLines(desc_txt))
}
