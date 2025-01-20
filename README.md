
<!-- README.md is generated from README.Rmd. Please edit that file -->

# ssrhom

<!-- badges: start -->
<!-- badges: end -->

The goal of ssrhom is to analyze data from single subject designs using
hierarchical ordinal regression models.

## Installation

This process is modified for anonymization purposes.

Download the package source files from:
<https://osf.io/download/eqnsp/?view_only=6866926dc56145c38b5559d51f8fc432>

Once the source files are in your working directory, you can install the
package with:

``` r
install.packages("./ssrhom_0.0.3.9002.tar.gz", type = "source")
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
# all arguments below are required for a given dataset
tasky_model <- ssrhom_model_ab(
  data = tasky,
  grouping = "phase", condition = "B",
  time = "time", outcome = "count", case = "person"
)
#> Warning: There were 2 divergent transitions after warmup. See
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
#>     mean se_mean   sd 2.5%   25%   50%  75% 97.5% n_eff Rhat
#> ac -0.05    0.01 0.18 -0.4 -0.18 -0.05 0.08  0.31  1266 1.01
#> 
#> Samples were drawn using NUTS(diag_e) at Mon Jan 20 14:22:45 2025.
#> For each parameter, n_eff is a crude measure of effective sample size,
#> and Rhat is the potential scale reduction factor on split chains (at 
#> convergence, Rhat=1).
# for a list of available effect sizes:
ssrhom_list_stats()
#> mean                :    mean of each case in both phases
#> median              :    median of each case in both phases
#> mean-diff           :    mean difference between phases by case
#> median-diff         :    median difference between phases by case
#> lrr                 :    log-ratio of means by case when data are never negative
#> lor                 :    log-ratio of odds by case when data fall between 0 and 1 inclusive
#> nap                 :    non-overlap of all pairs by case
#> tau                 :    A linear transformation of NAP
#> pem                 :    Proportion of treatment cases exceeding control cases by case
#> smd-c               :    Standardized mean difference using control SD as standardizer by case
#> smd-p               :    Standardized mean difference using pooled SD as standardizer by case
#> 
#> If model was called with `increase = FALSE`, then effects are reversed.
# non-overlap of all pairs
ssrhom_get_effect(tasky_model, stat = "nap")
#> # A tibble: 3 × 8
#>   variable      median     sd  q2.5 q97.5  rhat ess_bulk ess_tail
#>   <chr>          <dbl>  <dbl> <dbl> <dbl> <dbl>    <dbl>    <dbl>
#> 1 nap[amber]     0.898 0.0437 0.787 0.958  1.00    2087.    1883.
#> 2 nap[cara]      0.689 0.0886 0.502 0.841  1.00    1958.    1706.
#> 3 nap[rebeccah]  0.910 0.0451 0.802 0.975  1.00    1832.    1755.
# within subject standardized mean difference using pooled SD
ssrhom_get_effect(tasky_model, stat = "smd-p")
#> # A tibble: 3 × 8
#>   variable        median    sd   q2.5 q97.5  rhat ess_bulk ess_tail
#>   <chr>            <dbl> <dbl>  <dbl> <dbl> <dbl>    <dbl>    <dbl>
#> 1 smd-p[amber]     1.89  0.356 1.23    2.64  1.00    2078.    1855.
#> 2 smd-p[cara]      0.749 0.393 0.0219  1.54  1.00    2023.    1646.
#> 3 smd-p[rebeccah]  2.11  0.537 1.33    3.41  1.00    1792.    1668.
```
