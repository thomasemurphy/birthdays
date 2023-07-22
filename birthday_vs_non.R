library(tidyverse)
library(ggplot2)
library(lubridate)
library(scales)

library(Lahman)
library(baseballr)

setwd('baseball/birthdays')

calculate_obp <- function(hitter_df) {
  tot_ob <- sum(hitter_df$hits) +
    sum(hitter_df$base_on_balls) +
    sum(hitter_df$hit_by_pitch)
  tot_pa <- sum(hitter_df$plate_appearances)
  obp <- tot_ob / tot_pa
  obp
}

calculate_ba <- function(hitter_df) {
  ba <- sum(hitter_df$hits) / sum(hitter_df$at_bats)
  ba
}

calculate_slg <- function(hitter_df) {
  slg <- sum(hitter_df$total_bases) / sum(hitter_df$at_bats)
  slg
}

birthday_hits <- read_csv('data/cleaned/birthday_hitter_stats.csv')

birthday_hits$game_year <- substr(birthday_hits$game_date, 1, 4)
unique_years <- unique(birthday_hits$game_year)

birthday_boys_season_stats <- data.frame()
for (year_str in unique_years) {
  print(year_str)
  season_stats_fname <- paste0('data/season_data/hitting_stats_',
                               year_str,
                               '.csv')
  season_stats_df <- read_csv(season_stats_fname)
  players_this_year <- birthday_hits %>%
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
  select(player_id, season, player_full_name, hits, at_bats) %>%
  print(n = 10)

birthdays_slash <- c(
  calculate_ba(birthday_hits),
  calculate_obp(birthday_hits),
  calculate_slg(birthday_hits)
)

full_season_slash <- c(
  calculate_ba(birthday_boys_season_stats),
  calculate_obp(birthday_boys_season_stats),
  calculate_slg(birthday_boys_season_stats)
)