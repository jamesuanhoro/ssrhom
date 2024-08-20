# generic data checks ----

test_that("When not data", {
  expect_error(ssrhom_model_ab(
    grouping = "phase", condition = "B",
    time = "time", outcome = "count", case = "person",
    warmup = 250, sampling = 250, chains = 3, cores = 3
  ), paste(
    "Could not make the object passed as data into a data.frame.",
    "Please check this object to be sure it is a dataset.",
    sep = "\n"
  ))
})

test_that("When group variable is misnamed", {
  expect_error(ssrhom_model_ab(
    data = tasky,
    grouping = "phase1", condition = "B",
    time = "time", outcome = "count", case = "person",
    warmup = 250, sampling = 250, chains = 3, cores = 3
  ), paste(
    "At least one of `grouping`, `outcome`, `case` and `time` is not",
    "among the variables in the dataset.",
    sep = "\n"
  ))
})

test_that("When outcome variable is misnamed", {
  expect_error(ssrhom_model_ab(
    data = tasky,
    grouping = "phase", condition = "B",
    time = "time", outcome = "count1", case = "person",
    warmup = 250, sampling = 250, chains = 3, cores = 3
  ), paste(
    "At least one of `grouping`, `outcome`, `case` and `time` is not",
    "among the variables in the dataset.",
    sep = "\n"
  ))
})

test_that("When case variable is misnamed", {
  expect_error(ssrhom_model_ab(
    data = tasky,
    grouping = "phase", condition = "B",
    time = "time", outcome = "count", case = "person1",
    warmup = 250, sampling = 250, chains = 3, cores = 3
  ), paste(
    "At least one of `grouping`, `outcome`, `case` and `time` is not",
    "among the variables in the dataset.",
    sep = "\n"
  ))
})

test_that("When time variable is misnamed", {
  expect_error(ssrhom_model_ab(
    data = tasky,
    grouping = "phase", condition = "B",
    time = "time1", outcome = "count", case = "person",
    warmup = 250, sampling = 250, chains = 3, cores = 3
  ), paste(
    "At least one of `grouping`, `outcome`, `case` and `time` is not",
    "among the variables in the dataset.",
    sep = "\n"
  ))
})

test_that("When all data are treatment cases", {
  expect_error(ssrhom_model_ab(
    data = tasky,
    grouping = "all_treat", condition = "B",
    time = "time", outcome = "count", case = "person",
    warmup = 250, sampling = 250, chains = 3, cores = 3
  ), paste(
    "All rows in the data were in the treatment group as identified ",
    "via `condition`. Check that `condition` was set correctly.",
    sep = "\n"
  ))
})

test_that("When all data are control cases", {
  expect_error(ssrhom_model_ab(
    data = tasky,
    grouping = "all_control", condition = "B",
    time = "time", outcome = "count", case = "person",
    warmup = 250, sampling = 250, chains = 3, cores = 3
  ), paste(
    "None rows in the data were in the treatment group as identified ",
    "via `condition`. Check that `condition` was set correctly.",
    sep = "\n"
  ))
})

test_that("More than one person", {
  expect_error(ssrhom_model_ab(
    data = tasky,
    grouping = "phase", condition = "B",
    time = "time", outcome = "count", case = "one_person",
    warmup = 250, sampling = 250, chains = 3, cores = 3
  ), paste(
    "There should be data from more than one case for analysis.",
    sep = "\n"
  ))
})

test_that("All positive time", {
  expect_error(ssrhom_model_ab(
    data = tasky,
    grouping = "phase", condition = "B",
    time = "time_centered", outcome = "count", case = "person",
    warmup = 250, sampling = 250, chains = 3, cores = 3
  ), paste(
    "One or more values of `time` are not positive whole numbers.",
    sep = "\n"
  ))
})

# generic numeric checks ----

test_that("Non-numeric outcome", {
  expect_error(ssrhom_model_ab(
    data = tasky,
    grouping = "phase", condition = "B",
    time = "time", outcome = "non_numeric", case = "person",
    warmup = 250, sampling = 250, chains = 3, cores = 3
  ), paste(
    "Check that the `outcome` variable contains only numbers.",
    sep = " "
  ))
})
