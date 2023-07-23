library(tidyverse)
library(ggplot2)
library(lubridate)
library(scales)

library(Lahman)
library(baseballr)

setwd('baseball/birthdays')

# this script gets all the unique years in data/birthday_box_scores, and gets complete hitting stats for those years using baseballr::mlb_stats

data_files <- list.files(
  path = 'data/birthday_box_scores/',
  pattern = '.csv',
  full.names = FALSE,
  ignore.case = FALSE
  )

all_years <- lapply(list(as.numeric(unique(substr(data_files, 8, 11)))), sort)[[1]]

for (year in all_years) {
  hitting_stats <- mlb_stats(
    stat_type = 'season',
    stat_group = 'hitting',
    player_pool = 'All',
    season = year,
    limit = 10000
  )
  fname <- paste0('data/season_data/hitting_stats_', year, '.csv')
  write_csv(hitting_stats, fname)
}
