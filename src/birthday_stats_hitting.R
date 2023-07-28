library(tidyverse)
library(ggplot2)
library(lubridate)
library(scales)

library(Lahman)
library(baseballr)

setwd('baseball/birthdays/src')

in_season_birthdays <- read_csv('../data/player_lookup/in_season_birthdays.csv')

# get the filenames in the box scores directory
data_files <- list.files(
  path = '../data/birthday_box_scores/',
  pattern = '.csv',
  full.names = FALSE,
  ignore.case = FALSE
  )

# manually found these from the columns in data_files[1]
hitting_stats <- c(
  'player_id',
  'game_pk',
  'fly_outs',
  'ground_outs',
  'runs',
  'doubles',
  'triples',
  'home_runs',
  'strike_outs',
  'base_on_balls',
  'intentional_walks',
  'hits',
  'hit_by_pitch',
  'at_bats',
  'ground_into_double_play',
  'ground_into_triple_play',
  'plate_appearances',
  'total_bases',
  'rbi',
  'left_on_base',
  'sac_bunts',
  'sac_flies'
)

# make clean birthday_df with just desired hitting stats
birthday_df <- data.frame()
for (data_file in data_files) {
  raw_df <- read_csv(
    paste0('../data/birthday_box_scores/', data_file),
    show_col_types = FALSE
    )
  game_date <- substr(data_file, 8, 17)
  clean_hitter_df <- raw_df %>%
    filter(group == 'hitting') %>%
    select(all_of(hitting_stats))
  clean_hitter_df$game_date <- game_date
  birthday_df <- rbind(birthday_df, clean_hitter_df)
}

# add bio data for convenience later
birthdays_augm <- birthday_df %>%
  left_join(in_season_birthdays,
            by = c('player_id' = 'MLBID')
            )

# save clean dataframe
write_csv(birthdays_augm, '../data/birthday_stats_cleaned/birthday_hitter_stats.csv')
