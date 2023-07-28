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

birthday_boys_season_stats %>%
  select(player_id, season, player_full_name, runs, outs) %>%
  print(n = 10)

nrow(birthday_pitchers)

nrow(birthday_pitchers %>% distinct(player_id, game_year))

length(unique(birthday_pitchers$player_id))

birthdays_stats <- c(
  calculate_ra(birthday_pitchers),
  calculate_k_rate(birthday_pitchers)
)

full_season_stats <- c(
  calculate_ra(birthday_boys_season_stats),
  calculate_k_rate(birthday_boys_season_stats)
)