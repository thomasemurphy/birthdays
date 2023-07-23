library(tidyverse)
library(ggplot2)
library(lubridate)
library(scales)

library(Lahman)
library(baseballr)

setwd('baseball/birthdays')

# excel file from https://www.smartfantasybaseball.com/tag/player-id/
player_id_map <- read_csv('player_id_map.csv')

# should clean this up...this is exactly what happens in the wrangler
# move this code into its own function/script during refactor
in_season_birthdays <- People %>%
  mutate(finalGame = as_date(finalGame)) %>%
  filter(finalGame >= as_date('2000-01-01')) %>%
  left_join(
    select(player_id_map, c('BREFID', 'MLBID')),
    by = c('bbrefID' = 'BREFID')
  ) %>%
  filter(birthMonth >= 4 & birthMonth <= 9) %>%
  select(playerID, nameFirst, nameLast,
         birthDate, birthYear, birthMonth, birthDay,
         debut, finalGame,
         bbrefID, MLBID) %>%
  filter(!is.na(MLBID)) %>%
  mutate(debut_year = year(debut), final_year = year(finalGame))

# get the filenames in the box scores directory
data_files <- list.files(
  path = 'data/birthday_box_scores/',
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
    paste0('data/birthday_box_scores/', data_file),
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
write_csv(birthdays_augm, 'data/cleaned/birthday_hitter_stats.csv')
