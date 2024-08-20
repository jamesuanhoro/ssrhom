n_warm <- 50
n_sampling <- 50
n_chains <- 1

expect_error(suppressWarnings(fit_mod <- ssrhom_model_ab(
  data = tasky,
  grouping = "phase", condition = "B",
  time = "time", outcome = "count", case = "person",
  warmup = n_warm, sampling = n_sampling, chains = n_chains, cores = n_chains
)), NA)

test_that("Fail on wrong interval", {
  interval_fail_message <- paste(
    "interval", "is not a number between 0 and 1.",
    sep = " "
  )

  expect_error(
    ssrhom_get_effect(fit_mod, interval = 1.45),
    interval_fail_message
  )
  expect_error(
    ssrhom_get_effect(fit_mod, interval = "e"),
    interval_fail_message
  )
})

test_that("Fail on invalid stat", {
  stat_list <- ssrhom_list_stats(table = FALSE)
  rand_stat <- function() {
    rand_len <- 1 + stats::rpois(1, exp(stats::rnorm(1, 1, .5)))
    ret <- paste0(sample(letters, rand_len), collapse = "")
    while (ret %in% stat_list) {
      ret <- paste0(sample(letters, rand_len), collapse = "")
    }
    return(ret)
  }
  stat_fail_message <- paste(
    "`stat` must be one of:",
    paste0("\"", paste0(stat_list, collapse = ", \""), "\""),
    sep = "\n"
  )

  expect_error(
    ssrhom_get_effect(fit_mod, stat = rand_stat()),
    stat_fail_message
  )
})

# stat successes ----

test_that("Describe successes", {
  stat_list <- ssrhom_list_stats(table = FALSE)
  grid <- expand.grid(
    stat = stat_list,
    return_draws = list(TRUE, FALSE, sample(letters, 1))
  )

  apply(grid, 1, function(condition) {
    stat <- as.character(condition$stat)
    return_draws <- condition$return_draws

    rand_interval <- runif(1, .2, .95)

    stat_by_phase <- stat %in% stat_list[1:2]

    if (isTRUE(return_draws)) {
      # should be data.frame not draws_summary
      output <- ssrhom_get_effect(
        fit_mod,
        stat = stat, interval = rand_interval, return_draws = return_draws
      )
      expect_true(all(c(
        any(class(output) == "data.frame"),
        !any(class(output) == "draws_summary")
      )))
      expect_true(nrow(output) == n_sampling * n_chains)
      if (isTRUE(stat_by_phase)) {
        expect_true(ncol(output) == (fit_mod$stan_data_list$n_case * 2 + 3))
      } else {
        expect_true(ncol(output) == (fit_mod$stan_data_list$n_case + 3))
      }
      col_names <- colnames(output)
      col_names <- col_names[seq_len(ncol(output) - 3)]
      expect_true(all(grepl(stat, col_names)))
    } else {
      # should be draws_summary
      suppressWarnings(output <- ssrhom_get_effect(
        fit_mod,
        stat = stat, interval = rand_interval, return_draws = return_draws
      ))
      expect_true(any(class(output) == "draws_summary"))
      if (isTRUE(stat_by_phase)) {
        expect_true(nrow(output) == (fit_mod$stan_data_list$n_case * 2))
      } else {
        expect_true(nrow(output) == fit_mod$stan_data_list$n_case)
      }
    }
  })
})
