
<!-- README.md is generated from README.Rmd. Please edit that file -->

# ssrhom

<!-- badges: start -->

[![R-CMD-check](https://github.com/jamesuanhoro/ssrhom/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/jamesuanhoro/ssrhom/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/jamesuanhoro/ssrhom/branch/main/graph/badge.svg)](https://app.codecov.io/gh/jamesuanhoro/ssrhom?branch=main)
[![R-universe
badge](https://jamesuanhoro.r-universe.dev/badges/ssrhom)](https://jamesuanhoro.r-universe.dev/ssrhom)
<!-- badges: end -->

The goal of ssrhom is to analyze data from single subject designs using
hierarchical ordinal regression models.

## Installation

You can install ssrhom from [R-universe](https://r-universe.dev/) with:

``` r
install.packages(
  "ssrhom",
  repos = c("https://jamesuanhoro.r-universe.dev", "https://cloud.r-project.org")
)
```

## Simple demonstration

Using the tasky dataset which comes with the package:

``` r
library(ssrhom)
head(tasky)
#>     person phase count time
#> 1 rebeccah     A     4    1
#> 2 rebeccah     A     2    2
#> 3 rebeccah     A     2    3
#> 4 rebeccah     A     0    4
#> 5 rebeccah     A     2    5
#> 6 rebeccah     A     0    6
```

``` r
# all arguments below are required for a given dataset
tasky_model <- ssrhom_model_ab(
  data = tasky,
  grouping = "phase", condition = "B",
  time = "time", outcome = "count", case = "person"
)
#> Warning: There were 25 divergent transitions after warmup. See
#> https://mc-stan.org/misc/warnings.html#divergent-transitions-after-warmup
#> to find out why this is a problem and how to eliminate them.
#> Warning: Examine the pairs() plot to diagnose sampling problems
#> Warning: Bulk Effective Samples Size (ESS) is too low, indicating posterior means and medians may be unreliable.
#> Running the chains for more iterations may help. See
#> https://mc-stan.org/misc/warnings.html#bulk-ess
```

``` r
# how much autocorrelation?
print(tasky_model$model, "ac")
#> Inference for Stan model: model_ab.
#> 3 chains, each with iter=1500; warmup=750; thin=1; 
#> post-warmup draws per chain=750, total post-warmup draws=2250.
#> 
#>     mean se_mean   sd  2.5%   25%   50%  75% 97.5% n_eff Rhat
#> ac -0.05       0 0.17 -0.37 -0.16 -0.05 0.06  0.29  1331    1
#> 
#> Samples were drawn using NUTS(diag_e) at Sun Aug 25 08:18:26 2024.
#> For each parameter, n_eff is a crude measure of effective sample size,
#> and Rhat is the potential scale reduction factor on split chains (at 
#> convergence, Rhat=1).
```

``` r
# for a list of available effect sizes:
ssrhom_list_stats()
#> mean                :    mean of each case in both phases
#> median              :    median of each case in both phases
#> mean-diff           :    mean difference between phases by case
#> median-diff         :    median difference between phases by case
#> log-mean-ratio      :    log-ratio of means by case
#> nap                 :    non-overlap of all pairs by case
#> tau                 :    A linear transformation of NAP
#> pem                 :    Proportion of treatment cases exceeding control cases by case
#> smd_c               :    Standardized mean difference using control SD as standardizer by case
#> smd_p               :    Standardized mean difference using pooled SD as standardizer by case
#> 
#> If model was called with `increase = FALSE`, then effects are reversed.
```

``` r
# non-overlap of all pairs
ssrhom_get_effect(tasky_model, stat = "nap")
#> # A tibble: 3 × 8
#>   variable       mean     sd  q2.5 q97.5  rhat ess_bulk ess_tail
#>   <chr>         <dbl>  <dbl> <dbl> <dbl> <dbl>    <dbl>    <dbl>
#> 1 nap[amber]    0.899 0.0425 0.797 0.962  1.00    1445.    2050.
#> 2 nap[cara]     0.665 0.0871 0.486 0.821  1.00    2398.    2047.
#> 3 nap[rebeccah] 0.910 0.0530 0.773 0.985  1.00    2035.    1878.
```

``` r
# within subject standardized mean difference using pooled SD
ssrhom_get_effect(tasky_model, stat = "smd_p")
#> # A tibble: 3 × 8
#>   variable         mean    sd    q2.5 q97.5  rhat ess_bulk ess_tail
#>   <chr>           <dbl> <dbl>   <dbl> <dbl> <dbl>    <dbl>    <dbl>
#> 1 smd_p[amber]    1.86  0.340  1.20    2.53  1.00    1707.    1694.
#> 2 smd_p[cara]     0.645 0.367 -0.0333  1.38  1.00    2333.    1859.
#> 3 smd_p[rebeccah] 2.15  0.578  1.10    3.44  1.00    2008.    2038.
```
