library(tidyverse)
library(ggplot2)
library(lubridate)
library(scales)

library(Lahman)
library(baseballr)

setwd('baseball/birthdays/src')

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

birthday_hits <- read_csv('../data/birthday_stats_cleaned/birthday_hitter_stats.csv')

birthday_hits$game_year <- substr(birthday_hits$game_date, 1, 4)
unique_years <- unique(birthday_hits$game_year)

birthday_boys_season_stats <- data.frame()
for (year_str in unique_years) {
  print(year_str)
  season_stats_fname <- paste0('../data/player_season_stats/hitting_stats_',
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

# look at some players

birthday_by_player <- birthday_hits %>%
  group_by(player_id, nameFirst, nameLast, birthDate) %>%
  summarize(pa = sum(plate_appearances),
            ba = sum(hits) / sum(at_bats),
            obp = (sum(hits) + sum(base_on_balls) + sum(hit_by_pitch)) / sum(plate_appearances),
            slg = sum(total_bases) / sum(at_bats),
            ops = obp + slg) %>%
  arrange(desc(pa)) %>%
  filter(pa >= 15) %>%
  arrange(desc(ops)) %>%
  print(n = 20)

bday_player_ids <- birthday_by_player$player_id

non_birthday_by_player <- birthday_boys_season_stats %>%
  filter(player_id %in% bday_player_ids) %>%
  group_by(player_id) %>%
  summarize(pa = sum(plate_appearances),
            ba = sum(hits) / sum(at_bats),
            obp = (sum(hits) + sum(base_on_balls) + sum(hit_by_pitch)) / sum(plate_appearances),
            slg = sum(total_bases) / sum(at_bats),
            ops = obp + slg) %>%
  filter(pa >= 15) %>%
  arrange(desc(ops)) %>%
  print(n = 20)

birthday_by_player <- birthday_by_player %>%
  left_join(
    non_birthday_by_player,
    by = 'player_id',
    suffix = c('_bd', '_nbd')
  ) %>%
  mutate(ops_diff = ops_bd - ops_nbd) %>%
  arrange(desc(ops_diff)) %>%
  print(n = 20)

birthday_by_player %>%
  arrange(ops_diff) %>%
  select(nameFirst, nameLast, birthDate, pa_bd, pa_nbd, ops_bd, ops_nbd, ops_diff) %>%
  print(n = 10)

birthday_hits %>%
  filter(player_id == 455104) %>%
  select(game_date, plate_appearances, hits)
  