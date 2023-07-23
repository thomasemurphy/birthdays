library(tidyverse)
library(ggplot2)
library(lubridate)
library(scales)

library(Lahman)
library(baseballr)

setwd('baseball/birthdays/src')

# see get_in_season_birthdays.R
in_season_birthdays <- read_csv('../data/player_lookup/in_season_birthdays.csv')

# get the filenames in the box scores directory
data_files <- list.files(
  path = '../data/birthday_box_scores/',
  pattern = '.csv',
  full.names = FALSE,
  ignore.case = FALSE
  )

# manually found these from the columns in data_files[1]
pitching_stats <- c(
  'innings_pitched',
  'wins',
  'losses',
  'saves',
  'save_opportunities',
  'holds',
  'blown_saves',
  'earned_runs',
  'batters_faced',
  'outs',
  'games_pitched',
  'complete_games',
  'shutouts',
  'pitches_thrown',
  'balls',
  'strikes',
  'hit_batsmen',
  'balks',
  'wild_pitches',
  'strike_outs',
  'runs',
  'base_on_balls'
)

pitching_stats_s <- c(
  'player_id',
  'batters_faced',
  'outs',
  'games_pitched',
  'balls',
  'strikes',
  'hit_batsmen',
  'balks',
  'wild_pitches',
  'strike_outs',
  'runs',
  'base_on_balls'
)

# make clean birthday_df with just desired pitching stats
birthday_df <- data.frame()
for (data_file in data_files) {
  raw_df <- read_csv(
    paste0('data/birthday_box_scores/', data_file),
    show_col_types = FALSE
    )
  if ('innings_pitched' %in% names(raw_df)) {
    game_date <- substr(data_file, 8, 17)
    clean_pitcher_df <- raw_df %>%
      filter(group == 'pitching') %>%
      select(all_of(pitching_stats_s))
    clean_pitcher_df$game_date <- game_date
    birthday_df <- rbind(birthday_df, clean_pitcher_df)
  }
}

# add bio data for convenience later
birthdays_augm <- birthday_df %>%
  left_join(in_season_birthdays,
            by = c('player_id' = 'MLBID')
            )

# save clean dataframe
write_csv(birthdays_augm, '../data/birthday_stats_cleaned/birthday_pitcher_stats.csv')
