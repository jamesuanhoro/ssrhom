
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
#>     person phase count proportion time
#> 1 rebeccah     A     4  0.6666667    1
#> 2 rebeccah     A     2  0.3333333    2
#> 3 rebeccah     A     2  0.3333333    3
#> 4 rebeccah     A     0  0.0000000    4
#> 5 rebeccah     A     2  0.3333333    5
#> 6 rebeccah     A     0  0.0000000    6
```

``` r
# all arguments below are required for a given dataset
tasky_model <- ssrhom_model_ab(
  data = tasky,
  grouping = "phase", condition = "B",
  time = "time", outcome = "count", case = "person"
)
#> Warning: There were 7 divergent transitions after warmup. See
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
#> ac -0.04    0.01 0.18 -0.38 -0.17 -0.05 0.08  0.33  1120    1
#> 
#> Samples were drawn using NUTS(diag_e) at Thu Sep  5 22:57:38 2024.
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
#> log-mean-ratio      :    log-ratio of means by case when data are never negative
#> log-odds-ratio      :    log-ratio of odds by case when data fall between 0 and 1 inclusive
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
#> 1 nap[amber]    0.891 0.0433 0.791 0.958  1.00    1798.    1778.
#> 2 nap[cara]     0.685 0.0888 0.505 0.843  1.00    1958.    1435.
#> 3 nap[rebeccah] 0.906 0.0450 0.800 0.974  1.00    1528.    1743.
```

``` r
# within subject standardized mean difference using pooled SD
ssrhom_get_effect(tasky_model, stat = "smd_p")
#> # A tibble: 3 × 8
#>   variable         mean    sd   q2.5 q97.5  rhat ess_bulk ess_tail
#>   <chr>           <dbl> <dbl>  <dbl> <dbl> <dbl>    <dbl>    <dbl>
#> 1 smd_p[amber]    1.89  0.362 1.23    2.62  1.00    1895.    1888.
#> 2 smd_p[cara]     0.762 0.394 0.0426  1.58  1.00    1949.    1587.
#> 3 smd_p[rebeccah] 2.21  0.535 1.34    3.47  1.00    1557.    1938.
```
