library(tidyverse)
library(ggplot2)
library(lubridate)
library(scales)

library(Lahman)
library(baseballr)

setwd('baseball/birthdays/src')

calculate_k_rate <- function(pitcher_df) {
  tot_ip <- sum(pitcher_df$outs) / 3
  tot_k <- sum(pitcher_df$strike_outs)
  tot_k / tot_ip * 9
}

calculate_ra <- function(pitcher_df) {
  tot_r <- sum(pitcher_df$runs)
  tot_ip <- sum(pitcher_df$outs) / 3
  tot_r / tot_ip * 9
}

birthday_pitchers <- read_csv('../data/birthday_stats_cleaned/birthday_pitcher_stats.csv') %>%
  filter(!is.na(outs))

birthday_pitchers$game_year <- substr(birthday_pitchers$game_date, 1, 4)
birthday_pitchers$innings <- birthday_pitchers$outs / 3
unique_years <- unique(birthday_pitchers$game_year)

birthday_boys_season_stats <- data.frame()
for (year_str in unique_years) {
  print(year_str)
  season_stats_fname <- paste0('../data/player_season_stats/pitching_stats_',
                               year_str,
                               '.csv')
  season_stats_df <- read_csv(season_stats_fname)
  players_this_year <- birthday_pitchers %>%
    filter(game_year == year_str) %>%
    pull(player_id)
  birthday_boys_this_year <- season_stats_df %>%
    filter(player_id %in% players_this_year)
  birthday_boys_season_stats <- rbind(
    birthday_boys_season_stats,
    birthday_boys_this_year
  )
}

birthday_boys_season_stats <- birthday_boys_season_stats %>%
  mutate(game_year = as.character(season)) %>%
  mutate(innings = outs / 3)

birthday_boys_non_birthday <- birthday_boys_season_stats %>%
  inner_join(birthday_pitchers,
             by = c('player_id', 'game_year'),
             suffix = c('_fs', '_bd'),
             multiple = 'all'
  ) %>%
  mutate(batters_faced = batters_faced_fs - batters_faced_bd,
         outs = outs_fs - outs_bd,
         strike_outs = strike_outs_fs - strike_outs_bd,
         runs = runs_fs - runs_bd,
         base_on_balls = base_on_balls_fs - base_on_balls_bd,
  ) %>%
  mutate(innings = outs / 3)

birthday_boys_non_birthday %>%
  select(player_id, season, player_full_name, runs, innings) %>%
  print(n = 10)

# 90 pitcher birthday-games
nrow(birthday_pitchers)

# no pitcher pitched in two games on his birthday
nrow(birthday_pitchers %>% distinct(player_id, game_year))

# 71 unique pitchers
length(unique(birthday_pitchers$player_id))

birthday_ra <- calculate_ra(birthday_pitchers)
non_birthday_ra <- calculate_ra(birthday_boys_non_birthday)

birthday_runs <- sum(birthday_pitchers$runs)
birthday_innings <- sum(birthday_pitchers$innings)

bdk <- sum(birthday_pitchers$strike_outs)

nbdk <- sum(birthday_boys_non_birthday$strike_outs)

ra_result <- prop.test(
  x = c(birthday_runs, nbd_runs),
  n = c(birthday_innings, nbd_innings),
  alternative = "two.sided"
  )

strikeout_result <- prop.test(
  x = c(bdk, nbdk),
  n = c(birthday_innings, nbd_innings),
  alternative = "two.sided"
)


birthdays_stats <- c(
  calculate_ra(birthday_pitchers),
  calculate_k_rate(birthday_pitchers)
)

non_bd_stats <- c(
  calculate_ra(birthday_boys_non_birthday),
  calculate_k_rate(birthday_boys_non_birthday)
)