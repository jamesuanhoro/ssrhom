tasky$all_treat <- "B"
tasky$all_control <- "A"
tasky$one_person <- "Jim"
tasky$time_centered <- scale(tasky$time)
tasky$non_numeric <- tasky$count
tasky$non_numeric[1] <- "a"
