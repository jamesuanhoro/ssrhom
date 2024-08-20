n_stat <- 10

test_that("Stat list works as expected", {
  stat_list <- ssrhom_list_stats(table = FALSE)

  expect_true(length(stat_list) == n_stat)

  stat_tab_default <- capture.output(ssrhom_list_stats())
  expect_true(length(stat_tab_default) == (n_stat + 2))

  stat_txts_default <- unlist(
    lapply(stat_tab_default, function(txt) strsplit(txt, " ")[[1]][1])
  )
  expect_true(all(stat_list == stat_txts_default[seq_len(n_stat)]))

  stat_tab_not_true <- capture.output(ssrhom_list_stats(table = "FALSE"))
  expect_true(length(stat_tab_not_true) == (n_stat + 2))

  stat_txts_not_true <- unlist(
    lapply(stat_tab_not_true, function(txt) strsplit(txt, " ")[[1]][1])
  )
  expect_true(all(stat_list == stat_txts_not_true[seq_len(n_stat)]))
})
