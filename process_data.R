library(tidyverse)
library(ggplot2)
library(lubridate)
library(scales)

library(Lahman)
library(baseballr)

setwd('baseball/birthdays')

player_id_map <- read_csv('player_id_map.csv')

birthdays <- People %>%
  mutate(finalGame = as_date(finalGame)) %>%
  filter(finalGame >= as_date('2000-01-01')) %>%
  left_join(
    select(player_id_map, c('BREFID', 'MLBID')),
    by = c('bbrefID' = 'BREFID')
  )

in_season_birthdays <- birthdays %>%
  filter(birthMonth >= 4 & birthMonth <= 9) %>%
  select(playerID, nameFirst, nameLast,
         birthDate, birthYear, birthMonth, birthDay,
         debut, finalGame,
         bbrefID, MLBID) %>%
  filter(!is.na(MLBID)) %>%
  mutate(debut_year = year(debut), final_year = year(finalGame))

data_files <- list.files(
  path = 'data/',
  pattern = '.csv',
  full.names = FALSE,
  ignore.case = FALSE
  )

# df1 <- read_csv(paste0('data/', data_files[1]))
# df2 <- read_csv(paste0('data/', data_files[2]))
# df3 <- read_csv(paste0('data/', data_files[3]))

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

birthday_df <- data.frame()

for (data_file in data_files) {
  raw_df <- read_csv(
    paste0('data/birthday_box_scores/', data_file),
    show_col_types = FALSE
    )
  clean_hitter_df <- raw_df %>%
    filter(group == 'hitting') %>%
    select(all_of(hitting_stats))
  birthday_df <- rbind(birthday_df, clean_hitter_df)
}

birthdays_augm <- birthday_df %>%
  left_join(in_season_birthdays,
            by = c('player_id' = 'MLBID')
            )

birthdays_augm %>%
  select(nameFirst, nameLast, player_id, hits, plate_appearances) %>%
  print(n = 10)

write_csv(birthday_df, 'data/cleaned/birthday_hitter_stats.csv')

write.csv(birthday_df, '')