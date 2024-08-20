
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

You can install the development version of ssrhom like so:

``` r
remotes::install_github("jamesuanhoro/ssrhom")
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
#> Warning: There were 13 divergent transitions after warmup. See
#> https://mc-stan.org/misc/warnings.html#divergent-transitions-after-warmup
#> to find out why this is a problem and how to eliminate them.
#> Warning: Examine the pairs() plot to diagnose sampling problems
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
#> 1 nap[amber]    0.905 0.0395 0.810 0.964  1.00    2065.    1853.
#> 2 nap[cara]     0.660 0.0918 0.467 0.828  1.00    2684.    1802.
#> 3 nap[rebeccah] 0.910 0.0452 0.801 0.976  1.00    1524.    1906.
```

``` r
# within subject standardized mean difference using pooled SD
ssrhom_get_effect(tasky_model, stat = "smd_p")
#> # A tibble: 3 × 8
#>   variable         mean    sd   q2.5 q97.5  rhat ess_bulk ess_tail
#>   <chr>           <dbl> <dbl>  <dbl> <dbl> <dbl>    <dbl>    <dbl>
#> 1 smd_p[amber]    1.90  0.339  1.27   2.61  1.00    1917.    1947.
#> 2 smd_p[cara]     0.614 0.383 -0.117  1.41  1.00    2678.    1857.
#> 3 smd_p[rebeccah] 2.12  0.499  1.24   3.22  1.00    1538.    1954.
```
