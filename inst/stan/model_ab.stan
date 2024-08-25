functions {
  matrix create_autoreg_mat (real corr, int time) {
    matrix[time, time] autoreg_mat = identity_matrix(time);

    for (i in 2:time) {
      for (j in 1:(i - 1)) {
        autoreg_mat[i, j] = pow(corr, abs(i - j));
        autoreg_mat[j, i] = autoreg_mat[i, j];
      }
    }

    return(autoreg_mat);
  }
}
data {
  int n;
  int n_case;
  int n_time;
  int<lower = 2> n_ord;
  array[n] int<lower = 1, upper = n_case> case_id;
  array[n] int<lower = 1, upper = n_ord> y_ord;
  array[n] int<lower = 1, upper = n_time> time_id;
  array[n] int treat;
  array[n_ord] int count_levs;
  vector[n_ord] y_s;
  int n_count;
  vector[n_count] count;
  int<lower = 0, upper = 1> increase;
}
transformed data {
  array[n_case, n_time] int outcome_ord = rep_array(0, n_case, n_time);
  array[n_case, n_time] int treat_arr = rep_array(0, n_case, n_time);
  array[n_case, n_time] int idx_01 = rep_array(0, n_case, n_time);
  real treat_var = mean(treat) * (1 - mean(treat));

  for (i in 1:n) {
    outcome_ord[case_id[i], time_id[i]] = y_ord[i];
    treat_arr[case_id[i], time_id[i]] = treat[i];
  }

  for (i in 1:n_case) {
    for (j in 1:n_time) {
      if (outcome_ord[i, j] >= 1 && outcome_ord[i, j] <= n_ord) {
        idx_01[i, j] = 1;
      }
    }
  }

  array[n_case] int nm_count;

  for (i in 1:n_case) {
    nm_count[i] = sum(idx_01[i, ]);
  }

  array[n_case, n_time] int true_idxs = rep_array(0, n_case, n_time);

  for (i in 1:n_case) {
    int row_idx = 0;
    for (j in 1:n_time) {
      if (idx_01[i, j] == 1) {
        row_idx += 1;
        true_idxs[i, row_idx] = j;
      }
    }
  }

  int n_cuts = n_ord - 1;
  int n_ord_gt_2 = n_ord > 2 ? 1 : 0;
  int count_others = n_ord > 2 ? sum(count_levs[2:n_cuts]) : 0;
}
parameters {
  real<lower = 0> sigma_te;
  vector<lower = 0>[2] sigma_coefs;
  real treat_eff;
  matrix[n_case, 2] coefs_base;
  real<lower = 0, upper = 1> phi_01;
  ordered[n_cuts] cutpoints;
  vector<upper = cutpoints[1]>[count_levs[1]] z_first;
  vector<lower = cutpoints[n_cuts]>[count_levs[n_ord]] z_last;
  vector<lower = 0.0, upper = 1.0>[count_others] z_inter;
  real<lower = 0> sd_ratio_sig;
  vector[n_case * 2 - 1] ln_sd_ratio;
}
model {
  cutpoints ~ student_t(3, 0, 1);
  sigma_te ~ student_t(3, 0, 1);
  treat_eff ~ normal(0, sigma_te);
  phi_01 ~ beta(2, 2);

  sigma_coefs ~ student_t(3, 0, 1);
  to_vector(coefs_base) ~ std_normal();
  sd_ratio_sig ~ student_t(3, 0, 1);
  ln_sd_ratio ~ normal(0, sd_ratio_sig);

  {
    matrix[n_case, n_time] mu;
    matrix[n_time, n_time] autoreg_mat = create_autoreg_mat(
      phi_01 * 2 - 1.0, n_time
    );
    matrix[n_case, 2] coefs;
    matrix[n_case, n_time] z;
    array[2 + n_ord_gt_2] int pos_levs = rep_array(0, 2 + n_ord_gt_2);

    coefs[, 1] = sigma_coefs[1] * coefs_base[, 1];
    coefs[, 2] = treat_eff + sigma_coefs[2] * coefs_base[, 2];

    for (i in 1:n_case) {
      vector[n_time] case_sd_vec = rep_vector(0.0, n_time);
      matrix[n_time, n_time] case_ar_mat;

      array[nm_count[i]] int row_idxs = true_idxs[i, 1:nm_count[i]];

      mu[i, ] = coefs[i, 1] + coefs[i, 2] * to_row_vector(treat_arr[i, ]);

      for (j in 1:n_time) {
        int curr_idx = outcome_ord[i, j];
        if (curr_idx == 1) {
          pos_levs[1] += 1;
          z[i, j] = z_first[pos_levs[1]];
        } else if (curr_idx > 0) {
          if (curr_idx == n_ord) {
            pos_levs[2] += 1;
            z[i, j] = z_last[pos_levs[2]];
          } else {
            real b_min_a = cutpoints[curr_idx] - cutpoints[curr_idx - 1];
            // rescale 0-1 to cutpoints scale
            pos_levs[3] += 1;
            z[i, j] = b_min_a * z_inter[pos_levs[3]] + cutpoints[curr_idx - 1];
            // jacobian adjustment
            target += log(abs(b_min_a));
          }
        }
        if (i != 1 || treat_arr[i, j] != 0) {
          case_sd_vec[j] = ln_sd_ratio[2 * i - 2 + treat_arr[i, j]];
        }
      }
      case_sd_vec = exp(case_sd_vec);

      case_ar_mat[row_idxs, row_idxs] =
        quad_form_diag(autoreg_mat[row_idxs, row_idxs],
        case_sd_vec[row_idxs]
      );

      z[i, row_idxs] ~ multi_normal_cholesky(
        mu[i, row_idxs],
        cholesky_decompose(case_ar_mat[row_idxs, row_idxs])
      );
    }
  }
}
generated quantities {
  real ac = phi_01 * 2 - 1.0;
  matrix[n_case, 2] coefs;
  matrix[n_case, 2] mean_s;
  matrix[n_case, 2] var_s;
  matrix[n_case, 2] median_s;
  vector[n_case] mean_diff;
  vector[n_case] median_diff;
  vector[n_case] log_mean_ratio;
  vector[n_case] nap;
  vector[n_case] tau;
  vector[n_case] pem;
  vector[n_case] smd_c;
  vector[n_case] smd_p;
  vector[n] y_hat;
  vector[n] y_sim;
  // vector[n] log_lik;
  array[n] int ord_sim;

  coefs[, 1] = sigma_coefs[1] * coefs_base[, 1];
  coefs[, 2] = treat_eff + sigma_coefs[2] * coefs_base[, 2];

  {
    matrix[n_case, n_time] mu;
    matrix[n_time, n_time] autoreg_mat = create_autoreg_mat(
      phi_01 * 2 - 1.0, n_time
    );
    matrix[n_ord, n_case * 2] pmf_mat = rep_matrix(0.0, n_ord, n_case * 2);
    vector[n_ord] pmf_vec;
    vector[n_cuts] p_prob;
    int mat_col_id;
    int col_id;
    vector[n_ord] cdf = rep_vector(0.0, n_ord);
    vector[n_ord] d0_vec;
    vector[n_ord] d1_vec;
    vector[n_ord] ccd1_vec;
    matrix[n_case, n_time] z;
    array[n_case, n_time] int z_int;

    for (i in 1:n_case) {
      array[nm_count[i]] int row_idxs = true_idxs[i, 1:nm_count[i]];
      vector[n_time] case_sd_vec = rep_vector(0.0, n_time);
      matrix[n_time, n_time] case_ar_mat;

      for (j in 1:n_time) {
        if (i != 1 || treat_arr[i, j] != 0) {
          case_sd_vec[j] = ln_sd_ratio[2 * i - 2 + treat_arr[i, j]];
        }
      }
      case_sd_vec = exp(case_sd_vec);

      case_ar_mat[row_idxs, row_idxs] =
        quad_form_diag(autoreg_mat[row_idxs, row_idxs],
        case_sd_vec[row_idxs]
      );

      mu[i, ] = coefs[i, 1] + coefs[i, 2] * to_row_vector(treat_arr[i, ]);

      z[i, row_idxs] = multi_normal_cholesky_rng(
        mu[i, row_idxs],
        cholesky_decompose(case_ar_mat[row_idxs, row_idxs])
      )';

      for (j in row_idxs) {
        if (z[i, j] < cutpoints[1]) {
          z_int[i, j] = 1;
        } else if (z[i, j] > cutpoints[n_cuts]) {
          z_int[i, j] = n_ord;
        } else {
          for (k in 2:n_cuts) {
            if (z[i, j] > cutpoints[k - 1] && z[i, j] < cutpoints[k]) {
              z_int[i, j] = k;
            }
          }
        }
      }
    }

    for (i in 1:n) {
      real scaler = 0;
      ord_sim[i] = z_int[case_id[i], time_id[i]];
      y_sim[i] = y_s[ord_sim[i]];
      mat_col_id = (case_id[i] - 1) * 2 + treat[i] + 1;

      if (case_id[i] != 1 || treat[i] != 0) {
        scaler = ln_sd_ratio[2 * case_id[i] - 2 + treat[i]];
      }
      scaler = exp(scaler);

      p_prob = Phi(
        (cutpoints - mu[case_id[i], time_id[i]]) /
        scaler
      );

      for (j in 1:n_cuts) {
        if (j == 1) {
          pmf_vec[j] = p_prob[j];
        } else {
          pmf_vec[j] = p_prob[j] - p_prob[j - 1];
        }
      }
      pmf_vec[n_ord] = 1 - p_prob[n_cuts];
      y_hat[i] = sum(pmf_vec .* y_s);
      // this is not correct, ignores autocorrelation
      // log_lik[i] = ordered_probit_lpmf(
      //   y_ord[i] | mu[case_id[i], time_id[i]], cutpoints
      // );
      pmf_mat[, mat_col_id] = pmf_mat[, mat_col_id] + pmf_vec;
    }

    for (i in 1:n_case) {
      real med_a = 0;
      real med_b = 0;

      for (j in 1:2) {
        col_id = (i - 1) * 2 + j;
        pmf_mat[, col_id] = pmf_mat[, col_id] / count[col_id];
        mean_s[i, j] = sum(pmf_mat[, col_id] .* y_s);
        var_s[i, j] = sum(pmf_mat[, col_id] .* square(y_s - mean_s[i, j]));
        cdf = cumulative_sum(pmf_mat[, col_id]);
        if (cdf[1] >= .5) {
          median_s[i, j] = y_s[1];
        } else {
          for (k in 2:n_ord) {
            if (cdf[k] == .5) {
              median_s[i, j] = y_s[k];
            } else if (cdf[k - 1] < .5 && cdf[k] > .5) {
              median_s[i, j] = y_s[k - 1] + (.5 - cdf[k - 1]) *
                (y_s[k] - y_s[k - 1]) / (cdf[k] - cdf[k - 1]);
            }
          }
        }
      }
      mean_diff[i] = mean_s[i, 2] - mean_s[i, 1];
      median_diff[i] = median_s[i, 2] - median_s[i, 1];
      log_mean_ratio[i] = log(mean_s[i, 2]) - log(mean_s[i, 1]);
      smd_c[i] = mean_diff[i] / sqrt(var_s[i, 1]);
      smd_p[i] = mean_diff[i] / sqrt((
        (count[col_id - 1] - 1) * var_s[i, 1] +
          (count[col_id] - 1) * var_s[i, 2]
      ) / (count[col_id - 1] + count[col_id] - 2));
      d0_vec = pmf_mat[, col_id - 1];
      d1_vec = pmf_mat[, col_id];
      ccd1_vec = 1.0 - cumulative_sum(d1_vec);
      nap[i] = sum(d0_vec .* ccd1_vec + .5 * d0_vec .* d1_vec);
      tau[i] = nap[i] * 2.0 - 1.0;

      for (k in 1:n_ord) {
        if (median_s[i, 1] == y_s[k]) {
          med_a = .5 * pmf_mat[k, col_id];
        }
        if (median_s[i, 1] < y_s[k]) {
          med_b += pmf_mat[k, col_id];
        }
      }
      pem[i] = med_a + med_b;
    }
  }

  if (increase == 0) {
    mean_diff = -mean_diff;
    median_diff = -median_diff;
    log_mean_ratio = -log_mean_ratio;
    nap = 1.0 - nap;
    tau = -tau;
    pem = 1.0 - pem;
    smd_c = -smd_c;
    smd_p = -smd_p;
  }
}
