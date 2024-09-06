#' Analyze AB design
#'
#' @param data A dataset, ideally a data.frame.
#' @param grouping The name of the grouping variable in the dataset.
#' @param condition The level of the grouping variable that identifies the
#' treatment condition.
#' @param time The name of the time variable. This must be a series of
#' positive whole numbers signifiying the time the outcome was measured.
#' @param outcome The name of the outcome variable.
#' @param case The name of the variable that identifies different cases
#' in the dataset.
#' @param increase TRUE (Default) if increase in outcome is desirable.
#' Set FALSE if increase in outcome is undesirable.
#' @param warmup Number of iterations used to warmup the sampler, per chain.
#' @param sampling Number of iterations retained for inference, per chain.
#' @param refresh (Positive whole number) How often to print the status of
#' the sampler.
#' @param adapt_delta Number in (0,1). Increase to resolve divergent
#' transitions.
#' @param max_treedepth (Positive whole number) Increase to resolve problems
#' with maximum tree depth.
#' @param chains Number of chains to use.
#' @param cores Number of cores to use.
#' @param seed Random seed.
#' @param show_messages (Logical) If TRUE, show messages from Stan sampler,
#' if FALSE, hide messages.
#'
#' @return Object containing analysis results.
#'
#' @examples
#' \dontrun{
#' tasky_model <- ssrhom_model_ab(
#'   data = tasky,
#'   grouping = "phase", condition = "B",
#'   time = "time", outcome = "count", case = "person"
#' )
#' ssrhom_get_effect(tasky_model, stat = "nap")
#' }
#' @export
ssrhom_model_ab <- function(
    data,
    grouping = NA_character_,
    condition = NA_character_,
    time = NA_character_,
    outcome = NA_character_,
    case = NA_character_,
    increase = TRUE,
    warmup = 750,
    sampling = 750,
    refresh = max((warmup + sampling) %/% 10, 1),
    adapt_delta = .9,
    max_treedepth = 10,
    chains = 3,
    cores = min(chains, max(parallel::detectCores() - 2, 1)),
    seed = sample.int(.Machine$integer.max, 1),
    show_messages = TRUE) {
  dt <- check_user_input(
    data, grouping, condition, outcome, case, time
  )

  dl <- create_dat_list(dt, increase = increase)

  is_positive_whole_number(warmup)
  is_positive_whole_number(sampling)
  is_positive_whole_number(refresh)
  check_tau_interval(adapt_delta, "adapt_delta")
  is_positive_whole_number(max_treedepth)
  is_positive_whole_number(chains)
  is_positive_whole_number(cores)

  model <- rstan::sampling(
    stanmodels$model_ab,
    data = dl,
    iter = warmup + sampling, warmup = warmup, refresh = refresh,
    chains = chains, cores = cores,
    init = function() {
      list(
        sd_gamma = .5, sd_ln_lambda = .5,
        sigma_coefs = rep(0.5, (dl$n_case > 1) * 2), treat_eff = 0,
        coefs_base = matrix(0, (dl$n_case > 1) * dl$n_case, 2), phi_01 = .5
      )
    },
    seed = seed,
    control = list(adapt_delta = adapt_delta, max_treedepth = max_treedepth),
    show_messages = !isFALSE(show_messages)
  )

  result_object <- list(
    model = model, stan_data_list = dl
  )
  return(result_object)
}
